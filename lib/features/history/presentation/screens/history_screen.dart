import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../../../../models/conversation.dart';
import '../../../../services/providers.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _dayLabel(DateTime dt) {
    final days = DateTime.now().difference(dt).inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days < 7) return '$days days ago';
    return DateFormat('MMM d').format(dt);
  }

  /// Newest first, grouped under a day heading — insertion order of the map
  /// carries the ordering, so no separate sort of the groups is needed.
  Map<String, List<Conversation>> _grouped(List<Conversation> all) {
    final query = _searchController.text.toLowerCase();
    final matching = query.isEmpty
        ? all
        : all
            .where((c) =>
                c.title.toLowerCase().contains(query) ||
                c.lastMessagePreview.toLowerCase().contains(query))
            .toList();

    final sorted = [...matching]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final groups = <String, List<Conversation>>{};
    for (final c in sorted) {
      groups.putIfAbsent(_dayLabel(c.updatedAt), () => []).add(c);
    }
    return groups;
  }

  Future<void> _delete(Conversation c) async {
    await ref.read(conversationRepositoryProvider).deleteConversation(c.id);
    ref.invalidate(conversationsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(conversationsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(conversationsProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search History...',
                  prefixIcon: Icon(Icons.search, color: AppColors.textTertiary),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: conversations.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => _Empty(
                  icon: Icons.error_outline,
                  message: 'Could not load history.\n$e',
                ),
                data: (all) {
                  final groups = _grouped(all);
                  if (groups.isEmpty) {
                    return _Empty(
                      icon: Icons.history,
                      message: all.isEmpty
                          ? 'No conversations yet.\nStart a chat and it will show up here.'
                          : 'Nothing matches that search.',
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      for (final entry in groups.entries) ...[
                        Text(
                          entry.key,
                          style: AppTypography.labelLarge
                              .copyWith(color: AppColors.textTertiary),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        for (final c in entry.value)
                          _HistoryListItem(
                            conversation: c,
                            time: DateFormat('h:mm a').format(c.updatedAt),
                            onTap: () => context.go('/chat?id=${c.id}'),
                            onDelete: () => _delete(c),
                          ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String message;

  const _Empty({required this.icon, required this.message});

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
              message,
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

class _HistoryListItem extends StatelessWidget {
  final Conversation conversation;
  final String time;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryListItem({
    required this.conversation,
    required this.time,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceHighlight,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: const Icon(Icons.chat_bubble_outline,
            color: AppColors.textSecondary, size: 20),
      ),
      title: Text(
        conversation.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.bodyMedium,
      ),
      subtitle: Text(
        '$time · ${conversation.lastMessagePreview}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: AppColors.textTertiary),
        onPressed: onDelete,
      ),
      onTap: onTap,
    );
  }
}
