import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/jarvis_card.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../../../../repositories/tools.dart';

/// Events for one day, straight off the device calendar. Family-keyed on the
/// day so switching dates in the strip re-fetches rather than caching one day.
final _dayEventsProvider =
    FutureProvider.family<List<Event>, DateTime>((ref, day) async {
  return deviceEventsForDay(day);
});

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selected = _dateOnly(DateTime.now());

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// The week around today, Monday first.
  List<DateTime> get _week {
    final today = _dateOnly(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return [for (var i = 0; i < 7; i++) monday.add(Duration(days: i))];
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(_dayEventsProvider(_selected));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(_dayEventsProvider(_selected)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: const BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final day in _week)
                    _DateItem(
                      day: DateFormat('E').format(day)[0],
                      date: '${day.day}',
                      isSelected: day == _selected,
                      onTap: () => setState(() => _selected = day),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  DateFormat('EEEE, MMMM d').format(_selected),
                  style: AppTypography.titleMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            Expanded(
              child: events.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _Message(
                  icon: Icons.lock_outline,
                  // Permission denial and "no calendars" both land here.
                  text: '$e'.replaceFirst('Exception: ', ''),
                ),
                data: (list) => list.isEmpty
                    ? const _Message(
                        icon: Icons.event_available_outlined,
                        text: 'Nothing scheduled.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg),
                        itemCount: list.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, i) => _EventCard(list[i]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Message({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;

  const _EventCard(this.event);

  @override
  Widget build(BuildContext context) {
    final start = event.start;
    final end = event.end;
    final time = event.allDay == true || start == null
        ? 'All day'
        : '${DateFormat('h:mm a').format(start)}'
            '${end == null ? '' : ' – ${DateFormat('h:mm a').format(end)}'}';

    return JarvisCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryCyan,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title ?? 'Untitled',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyLarge,
                ),
                Text(
                  time,
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateItem extends StatelessWidget {
  final String day;
  final String date;
  final bool isSelected;
  final VoidCallback onTap;

  const _DateItem({
    required this.day,
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Text(
            day,
            style: AppTypography.caption
                .copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.primaryBlue : Colors.transparent,
            ),
            child: Center(
              child: Text(
                date,
                style: AppTypography.bodyMedium.copyWith(
                  color: isSelected
                      ? AppColors.background
                      : AppColors.textPrimary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
