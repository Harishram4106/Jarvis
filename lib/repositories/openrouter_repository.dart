import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/conversation.dart';
import 'repository_interfaces.dart';
import 'tools.dart';

/// Streams replies from an open model via OpenRouter.
///
/// OpenRouter speaks the OpenAI-compatible `/chat/completions` format, so this
/// talks to the REST endpoint directly over `dart:io` — no HTTP package needed.
class OpenRouterAiRepository implements AiRepository {
  OpenRouterAiRepository({
    required this.apiKey,
    this.model = defaultModel,
    List<String> Function()? memories,
    this.customSystemPrompt = '',
    this.tools = const [],
  }) : _memories = memories ?? _none;

  final String apiKey;
  final String model;

  /// User-configured custom instructions prepended to the system prompt.
  final String customSystemPrompt;

  /// Read lazily at send time. A snapshot would force the provider to watch
  /// the memory list, and rebuilding the repository mid-send disposes the
  /// notifier that is using it.
  final List<String> Function() _memories;
  static List<String> _none() => const [];

  List<String> get memories => _memories();

  /// Capabilities offered to the model. Empty means a plain chat request.
  final List<Tool> tools;

  /// A runaway model must not loop forever; each round is a paid-for-free
  /// request against a rate-limited quota.
  static const maxToolRounds = 4;

  /// Changeable in Settings, which only ever offers free models.
  /// Measured on free tier: the 550B ultra took ~30s for a short reply, this
  /// one ~1.4s with clean output (no leaked reasoning preamble). Latency, not
  /// size, is what a phone assistant needs.
  static const defaultModel = 'google/gemma-4-26b-a4b-it:free';

  static const _endpoint = 'https://openrouter.ai/api/v1/chat/completions';
  static const _modelsEndpoint = 'https://openrouter.ai/api/v1/models';

  /// Every model OpenRouter currently serves at zero cost, largest context
  /// first. Fetched live so the list can't go stale, and filtered on price
  /// rather than on a name convention — a model is free or it isn't.
  static Future<List<FreeModel>> freeModels() async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(_modelsEndpoint));
      final response = await request.close();
      if (response.statusCode != 200) {
        throw const AiException('Could not load the model list.');
      }
      final body = await response.transform(utf8.decoder).join();
      return parseFreeModels((jsonDecode(body) as Map)['data'] as List);
    } on SocketException {
      throw const AiException('No connection. Could not load models.');
    } finally {
      client.close();
    }
  }

  /// Offline check that an id is a zero-cost model. No paid model on
  /// OpenRouter carries the ':free' suffix, so this is a safe last line of
  /// defence when the live price list isn't to hand.
  static bool isFree(String id) =>
      id.endsWith(':free') || id == 'openrouter/free';

  /// Pure half of [freeModels] — anything not priced at exactly zero is
  /// dropped, so a paid model can never reach the picker.
  static List<FreeModel> parseFreeModels(List<dynamic> data) {
    final free = <FreeModel>[];
    for (final entry in data.cast<Map<String, dynamic>>()) {
      final pricing = entry['pricing'] as Map?;
      final promptCost = double.tryParse('${pricing?["prompt"]}') ?? 1;
      final outputCost = double.tryParse('${pricing?["completion"]}') ?? 1;
      if (promptCost != 0 || outputCost != 0) continue;
      // Keep the picker in step with the send-time guard below.
      if (!isFree(entry['id'] as String)) continue;

      // Text-only output. Some free models (Google's Lyria) emit text
      // alongside audio — they are music generators, not chat models.
      final outputs =
          (entry['architecture'] as Map?)?['output_modalities'] as List?;
      if (outputs != null && outputs.any((o) => o != 'text')) continue;

      free.add(FreeModel(
        id: entry['id'] as String,
        name: (entry['name'] as String?) ?? entry['id'] as String,
        contextLength: (entry['context_length'] as num?)?.toInt() ?? 0,
      ));
    }
    free.sort((a, b) => b.contextLength.compareTo(a.contextLength));
    return free;
  }

  static const _system =
      'You are JARVIS, a personal assistant on the user\'s phone. '
      'Answer directly and concisely — you are being read on a small screen. '
      'Skip preamble and filler. Use short paragraphs, and markdown only when '
      'it genuinely helps (lists, code). If you do not know something, say so.';

  /// Visible for testing: memories must actually reach the model.
  String systemPrompt() {
    final parts = [_system];
    if (customSystemPrompt.isNotEmpty) {
      parts.add('User instructions: $customSystemPrompt');
    }
    if (memories.isNotEmpty) {
      parts.add(
        'Things the user has told you to remember. Use them when relevant; '
        'do not recite them unprompted:\n'
        '${memories.map((m) => '- $m').join('\n')}',
      );
    }
    return parts.join('\n\n');
  }

  @override
  Stream<String> send(List<ChatMessage> history, {String? context}) async* {
    if (history.isEmpty) return;

    // Nothing in the app can select a paid model, but this is a money path:
    // refuse locally rather than trust that.
    if (!isFree(model)) {
      throw AiException('Refusing to send: "$model" is not a free model.');
    }

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt()},
      if (context != null && context.isNotEmpty)
        {'role': 'system', 'content': context},
      for (final m in history)
        {
          'role': m.role == MessageRole.user ? 'user' : 'assistant',
          'content': m.content,
        },
    ];

    for (var round = 0; round <= maxToolRounds; round++) {
      final calls = <int, PendingCall>{};
      final said = StringBuffer();

      await for (final chunk in _round(messages, calls)) {
        said.write(chunk);
        yield chunk;
      }

      if (calls.isEmpty) return; // the model answered

      if (round == maxToolRounds) {
        yield '\n\n(Stopped after $maxToolRounds tool calls.)';
        return;
      }

      // Record what the model asked for, then hand back each result.
      messages.add({
        'role': 'assistant',
        'content': said.toString(),
        'tool_calls': [for (final c in calls.values) c.toJson()],
      });
      for (final c in calls.values) {
        messages.add({
          'role': 'tool',
          'tool_call_id': c.id,
          'content': await runTool(tools, c.name, c.args),
        });
      }
    }
  }

  /// One request/response round. Yields text as it arrives and fills [calls]
  /// with any tool the model asked for.
  Stream<String> _round(
    List<Map<String, dynamic>> messages,
    Map<int, PendingCall> calls,
  ) async* {
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse(_endpoint));
      request.headers
        ..set('content-type', 'application/json')
        ..set('authorization', 'Bearer $apiKey')
        // OpenRouter uses these for attribution on its dashboard.
        ..set('http-referer', 'https://github.com/jarvis-app')
        ..set('x-title', 'JARVIS');

      request.add(utf8.encode(jsonEncode({
        'model': model,
        'stream': true,
        // No max_tokens: open models have wildly different output caps, and
        // naming one risks a 400 on whichever model you switch to.
        'messages': messages,
        if (tools.isNotEmpty) 'tools': [for (final t in tools) t.toJson()],
      })));

      final response = await request.close();

      if (response.statusCode != 200) {
        final body = await response.transform(utf8.decoder).join();
        throw AiException(_errorFor(response.statusCode, body));
      }

      final lines = response
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .timeout(const Duration(seconds: 45));

      await for (final line in lines) {
        // OpenRouter sends ": OPENROUTER PROCESSING" comments as keep-alives.
        if (!line.startsWith('data: ')) continue;

        final payload = line.substring(6);
        if (payload == '[DONE]') break;

        final Map<String, dynamic> event;
        try {
          event = jsonDecode(payload) as Map<String, dynamic>;
        } catch (_) {
          continue; // partial frame
        }

        // Errors can arrive mid-stream with a 200 status.
        final error = event['error'];
        if (error != null) {
          throw AiException(
            (error as Map)['message']?.toString() ?? 'The response failed.',
          );
        }

        final choices = event['choices'] as List?;
        if (choices == null || choices.isEmpty) continue;
        final delta = (choices.first as Map)['delta'] as Map?;

        final content = delta?['content'];
        if (content is String && content.isNotEmpty) yield content;

        final toolCalls = delta?['tool_calls'];
        if (toolCalls is List) accumulateToolCalls(calls, toolCalls);
      }
    } on TimeoutException {
      throw AiException(
        '"$model" stopped responding. Try another model in Settings.',
      );
    } on SocketException {
      throw const AiException(
          'No connection. Check your network and try again.');
    } on HttpException {
      throw const AiException('The connection dropped mid-reply.');
    } finally {
      client.close();
    }
  }

  String _errorFor(int status, String body) {
    String? detail;
    try {
      detail =
          ((jsonDecode(body) as Map)['error'] as Map?)?['message']?.toString();
    } catch (_) {
      /* fall through to the generic message */
    }

    return switch (status) {
      400 => detail ?? 'That request was rejected.',
      401 => 'API key rejected. Check it in Settings.',
      402 => 'Out of OpenRouter credits.',
      404 => 'Model "$model" not found. Check the model id in Settings.',
      429 => 'Rate limited. Wait a moment and try again.',
      >= 500 => detail ?? 'The provider is having trouble. Try again shortly.',
      _ => detail ?? 'Request failed ($status).',
    };
  }
}

/// A zero-cost model offered by OpenRouter.
class FreeModel {
  final String id;
  final String name;
  final int contextLength;

  const FreeModel({
    required this.id,
    required this.name,
    required this.contextLength,
  });

  /// "1.0M" / "262K" / "65K"
  String get contextLabel => contextLength >= 1000000
      ? '${(contextLength / 1000000).toStringAsFixed(1)}M'
      : '${(contextLength / 1000).round()}K';
}
