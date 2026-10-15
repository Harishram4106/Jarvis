import 'dart:convert';

import 'package:battery_plus/battery_plus.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

import 'web_search.dart';

/// A capability the model can invoke.
///
/// Adding one is three fields and a function — no registration step, just
/// append it to [buildTools].
class Tool {
  final String name;
  final String description;

  /// JSON Schema for the arguments, as the OpenAI-compatible API expects.
  final Map<String, dynamic> parameters;

  final Future<String> Function(Map<String, dynamic> args) run;

  const Tool({
    required this.name,
    required this.description,
    required this.parameters,
    required this.run,
  });

  Map<String, dynamic> toJson() => {
        'type': 'function',
        'function': {
          'name': name,
          'description': description,
          'parameters': parameters,
        },
      };

  static Map<String, dynamic> get noArgs =>
      {'type': 'object', 'properties': <String, dynamic>{}};
}

/// Runs a named tool, turning any failure into a message the model can read
/// and recover from — a thrown exception would abort the whole reply.
Future<String> runTool(List<Tool> tools, String name, Map<String, dynamic> args) async {
  for (final t in tools) {
    if (t.name == name) {
      try {
        return await t.run(args);
      } catch (e) {
        return 'Tool "$name" failed: $e';
      }
    }
  }
  return 'No tool named "$name" exists.';
}

/// Platform channel for Android intents (timer, alarm, open app).
const _intents = MethodChannel('com.jarvis/intents');

/// Common app names → Android package names.
// Static map, add entries as users request them.
const _appPackages = <String, String>{
  'youtube': 'com.google.android.youtube',
  'chrome': 'com.android.chrome',
  'gmail': 'com.google.android.gm',
  'maps': 'com.google.android.apps.maps',
  'google maps': 'com.google.android.apps.maps',
  'camera': 'com.android.camera',
  'photos': 'com.google.android.apps.photos',
  'google photos': 'com.google.android.apps.photos',
  'calculator': 'com.google.android.calculator',
  'calendar': 'com.google.android.calendar',
  'clock': 'com.google.android.deskclock',
  'settings': 'com.android.settings',
  'phone': 'com.android.dialer',
  'messages': 'com.google.android.apps.messaging',
  'contacts': 'com.android.contacts',
  'whatsapp': 'com.whatsapp',
  'instagram': 'com.instagram.android',
  'telegram': 'org.telegram.messenger',
  'spotify': 'com.spotify.music',
  'twitter': 'com.twitter.android',
  'x': 'com.twitter.android',
  'reddit': 'com.reddit.frontpage',
  'netflix': 'com.netflix.mediaclient',
  'files': 'com.google.android.apps.nbu.files',
  'play store': 'com.android.vending',
};

/// Events on [day] from the device calendar, or throws with a reason the UI
/// can show. Shared by the `manage_calendar` tool and the Calendar screen so
/// both read the same source.
Future<List<Event>> deviceEventsForDay(DateTime day) async {
  final plugin = DeviceCalendarPlugin();

  var permission = await plugin.hasPermissions();
  if (permission.isSuccess && !(permission.data ?? false)) {
    permission = await plugin.requestPermissions();
    if (!(permission.data ?? false)) {
      throw Exception('Calendar permission denied.');
    }
  }

  final calendars = await plugin.retrieveCalendars();
  if (!calendars.isSuccess ||
      calendars.data == null ||
      calendars.data!.isEmpty) {
    throw Exception('No calendars found on device.');
  }

  tz.initializeTimeZones();
  try {
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
  } catch (_) {}

  final start = tz.TZDateTime(tz.local, day.year, day.month, day.day);
  final end = start.add(const Duration(days: 1));

  // Every calendar, not just the default — a read-only work calendar still
  // belongs on the user's day.
  final events = <Event>[];
  for (final calendar in calendars.data!) {
    final result = await plugin.retrieveEvents(
      calendar.id,
      RetrieveEventsParams(startDate: start, endDate: end),
    );
    if (result.isSuccess && result.data != null) events.addAll(result.data!);
  }
  events.sort((a, b) => (a.start?.millisecondsSinceEpoch ?? 0)
      .compareTo(b.start?.millisecondsSinceEpoch ?? 0));
  return events;
}

List<Tool> buildTools({required WebSearch search}) => [
      Tool(
        name: 'web_search',
        description:
            'Search the web for current information. Use this whenever the '
            'answer depends on recent events, prices, releases, or anything '
            'that may have changed since training.',
        parameters: {
          'type': 'object',
          'properties': {
            'query': {
              'type': 'string',
              'description': 'What to search for.',
            },
          },
          'required': ['query'],
        },
        run: (args) async {
          final query = (args['query'] ?? '').toString().trim();
          if (query.isEmpty) return 'No query given.';
          final results = await search.search(query);
          if (results.isEmpty) {
            return 'No results found for "$query". Do not invent sources.';
          }
          return searchContext(query, results);
        },
      ),
      Tool(
        name: 'current_datetime',
        description:
            "The user's current local date and time. Use this for anything "
            'involving today, tomorrow, deadlines, or elapsed time — you do '
            'not otherwise know what day it is.',
        parameters: Tool.noArgs,
        run: (_) async => DateTime.now().toString(),
      ),
      Tool(
        name: 'read_clipboard',
        description:
            "Read the text currently on the user's clipboard. Use when they "
            'refer to something they copied.',
        parameters: Tool.noArgs,
        run: (_) async {
          final data = await Clipboard.getData(Clipboard.kTextPlain);
          final text = data?.text?.trim() ?? '';
          return text.isEmpty ? 'The clipboard is empty.' : text;
        },
      ),
      Tool(
        name: 'set_timer',
        description:
            'Set a timer or alarm on the phone. For a countdown timer, '
            'provide "seconds". For a specific-time alarm, provide "hour" '
            'and "minute" (24-hour). Always provide "label".',
        parameters: {
          'type': 'object',
          'properties': {
            'seconds': {
              'type': 'integer',
              'description': 'Countdown duration in seconds (for timers).',
            },
            'hour': {
              'type': 'integer',
              'description': 'Hour in 24-hour format (for alarms).',
            },
            'minute': {
              'type': 'integer',
              'description': 'Minute (for alarms).',
            },
            'label': {
              'type': 'string',
              'description': 'A short label for the timer or alarm.',
            },
          },
          'required': ['label'],
        },
        run: (args) async {
          final label = (args['label'] ?? 'Timer').toString();
          if (args.containsKey('hour')) {
            return (await _intents.invokeMethod<String>('setAlarm', {
              'hour': (args['hour'] as num).toInt(),
              'minute': ((args['minute'] ?? 0) as num).toInt(),
              'label': label,
            }))!;
          }
          final seconds = ((args['seconds'] ?? 60) as num).toInt();
          return (await _intents.invokeMethod<String>('setTimer', {
            'seconds': seconds,
            'label': label,
          }))!;
        },
      ),
      Tool(
        name: 'open_app',
        description:
            "Open an app on the user's phone. Use when they ask to open, "
            'launch, or switch to an app.',
        parameters: {
          'type': 'object',
          'properties': {
            'app_name': {
              'type': 'string',
              'description':
                  'The common name of the app (e.g. "YouTube", "WhatsApp", '
                  '"Calculator", "Camera", "Settings").',
            },
          },
          'required': ['app_name'],
        },
        run: (args) async {
          final name = (args['app_name'] ?? '').toString().toLowerCase().trim();
          if (name.isEmpty) return 'No app name given.';
          final pkg = _appPackages[name];
          if (pkg == null) {
            return 'I don\'t know the package for "$name". '
                'Known apps: ${_appPackages.keys.join(", ")}.';
          }
          return (await _intents.invokeMethod<String>('openApp', {
            'package': pkg,
          }))!;
        },
      ),
      Tool(
        name: 'check_battery',
        description:
            'Check the current battery level and charging status of the device.',
        parameters: Tool.noArgs,
        run: (_) async {
          final battery = Battery();
          final level = await battery.batteryLevel;
          final state = await battery.batteryState;
          return 'Battery level is $level%. State: ${state.name}.';
        },
      ),
      Tool(
        name: 'send_sms',
        description: 'Send an SMS message to a phone number. Requires user action to send.',
        parameters: {
          'type': 'object',
          'properties': {
            'phone_number': {
              'type': 'string',
              'description': 'The phone number to send the SMS to.',
            },
            'message': {
              'type': 'string',
              'description': 'The text message to send.',
            },
          },
          'required': ['phone_number', 'message'],
        },
        run: (args) async {
          final number = (args['phone_number'] ?? '').toString();
          final message = (args['message'] ?? '').toString();
          if (number.isEmpty) return 'No phone number provided.';
          final uri = Uri(scheme: 'sms', path: number, queryParameters: {'body': message});
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
            return 'Opened SMS app with message to $number.';
          } else {
            return 'Could not launch SMS app.';
          }
        },
      ),
      Tool(
        name: 'make_call',
        description: 'Initiate a phone call to a given number. Requires user action to dial.',
        parameters: {
          'type': 'object',
          'properties': {
            'phone_number': {
              'type': 'string',
              'description': 'The phone number to call.',
            },
          },
          'required': ['phone_number'],
        },
        run: (args) async {
          final number = (args['phone_number'] ?? '').toString();
          if (number.isEmpty) return 'No phone number provided.';
          final uri = Uri(scheme: 'tel', path: number);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
            return 'Opened dialer for $number.';
          } else {
            return 'Could not launch dialer.';
          }
        },
      ),
      Tool(
        name: 'manage_calendar',
        description: 'Add an event to the device calendar or list today\'s events. To list, pass action="list". To add, pass action="add" along with title, description, start_time, and duration_minutes.',
        parameters: {
          'type': 'object',
          'properties': {
            'action': {
              'type': 'string',
              'description': 'Either "list" or "add".',
            },
            'title': {
              'type': 'string',
              'description': 'Title of the event (required for "add").',
            },
            'description': {
              'type': 'string',
              'description': 'Description of the event (optional).',
            },
            'start_time': {
              'type': 'string',
              'description': 'ISO8601 string of the event start time (required for "add").',
            },
            'duration_minutes': {
              'type': 'integer',
              'description': 'Duration in minutes (required for "add").',
            },
          },
          'required': ['action'],
        },
        run: (args) async {
          final action = (args['action'] ?? '').toString();
          final calendarPlugin = DeviceCalendarPlugin();
          
          var permissionsGranted = await calendarPlugin.hasPermissions();
          if (permissionsGranted.isSuccess && !(permissionsGranted.data ?? false)) {
            permissionsGranted = await calendarPlugin.requestPermissions();
            if (!(permissionsGranted.data ?? false)) {
              return 'Calendar permission denied by user.';
            }
          }
          
          final calendarsResult = await calendarPlugin.retrieveCalendars();
          if (!calendarsResult.isSuccess || calendarsResult.data == null || calendarsResult.data!.isEmpty) {
            return 'No calendars found on device.';
          }
          
          final defaultCalendar = calendarsResult.data!.firstWhere(
            (c) => c.isReadOnly == false, 
            orElse: () => calendarsResult.data!.first
          );
          final calendarId = defaultCalendar.id;
          
          tz.initializeTimeZones();
          try {
            final currentTimeZone = await FlutterTimezone.getLocalTimezone();
            tz.setLocalLocation(tz.getLocation(currentTimeZone.identifier));
          } catch (_) {}
          
          if (action == 'list') {
             final events = await deviceEventsForDay(DateTime.now());
             if (events.isEmpty) return 'No events found for today.';
             final eventList = events.map((e) => '- ${e.title} at ${e.start?.toString()}').join('\n');
             return 'Today\'s events:\n$eventList';
          } else if (action == 'add') {
             final title = (args['title'] ?? '').toString();
             final description = (args['description'] ?? '').toString();
             final startTimeStr = (args['start_time'] ?? '').toString();
             final durationMinutes = ((args['duration_minutes'] ?? 60) as num).toInt();
             
             if (title.isEmpty || startTimeStr.isEmpty) {
               return 'Title and start_time are required to add an event.';
             }
             
             try {
               final start = DateTime.parse(startTimeStr);
               final end = start.add(Duration(minutes: durationMinutes));
               
               final tzStart = tz.TZDateTime.from(start, tz.local);
               final tzEnd = tz.TZDateTime.from(end, tz.local);
               
               final eventToCreate = Event(
                 calendarId,
                 title: title,
                 description: description,
                 start: tzStart,
                 end: tzEnd,
               );
               
               final result = await calendarPlugin.createOrUpdateEvent(eventToCreate);
               if (result?.isSuccess == true) {
                 return 'Successfully added event "$title" to calendar.';
               } else {
                 return 'Failed to add event: ${result?.errors.map((e) => e.errorMessage).join(", ")}';
               }
             } catch (e) {
               return 'Failed to add event. Error: $e';
             }
          }
          return 'Invalid action. Use "list" or "add".';
        }
      ),
    ];

/// A tool call assembled from streaming deltas.
///
/// The API sends `arguments` as JSON split across many chunks, and only the
/// first chunk carries `id` and `name` — so calls have to be accumulated by
/// index rather than read from any single delta.
class PendingCall {
  String id = '';
  String name = '';
  final StringBuffer arguments = StringBuffer();

  Map<String, dynamic> get args {
    final raw = arguments.toString();
    if (raw.trim().isEmpty) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {}; // a truncated call is better run with no args than dropped
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': 'function',
        'function': {'name': name, 'arguments': arguments.toString()},
      };
}

/// Folds one delta's `tool_calls` into the calls accumulated so far.
void accumulateToolCalls(Map<int, PendingCall> into, List<dynamic> deltas) {
  for (final raw in deltas) {
    if (raw is! Map) continue;
    final index = (raw['index'] as num?)?.toInt() ?? 0;
    final call = into.putIfAbsent(index, PendingCall.new);

    if (raw['id'] != null) call.id = raw['id'].toString();
    final fn = raw['function'];
    if (fn is Map) {
      if (fn['name'] != null) call.name = fn['name'].toString();
      if (fn['arguments'] != null) call.arguments.write(fn['arguments']);
    }
  }
}
