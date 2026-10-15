import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/glass_widgets.dart';
import '../../../../models/app_models.dart';
import '../../../../services/providers.dart';

class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  SavedItemType? _filter; // null = all
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SavedItem> _filtered(List<SavedItem> items) {
    var result = items;
    if (_filter != null) {
      result = result.where((i) => i.type == _filter).toList();
    }
    final q = _searchController.text.toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((i) => i.title.toLowerCase().contains(q)).toList();
    }
    return result;
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 14) return '1 week ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return DateFormat('MMM d').format(dt);
  }

  IconData _typeIcon(SavedItemType type) => switch (type) {
        SavedItemType.chat => Icons.chat_bubble_outline_rounded,
        SavedItemType.note => Icons.description_outlined,
        SavedItemType.prompt => Icons.auto_awesome_outlined,
      };

  Future<void> _showMenu(SavedItem item) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: ListTile(
          leading: const Icon(Icons.bookmark_remove_rounded,
              color: AppColors.error),
          title: Text('Remove from Saved',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.error)),
          onTap: () => Navigator.pop(ctx, 'remove'),
        ),
      ),
    );
    if (action != 'remove') return;

    if (item.conversationId != null) {
      // It's a starred conversation — unstar it.
      await ref
          .read(conversationRepositoryProvider)
          .saveConversation(item.conversationId!, false);
    } else {
      // Standalone note.
      await ref.read(savedRepositoryProvider).removeSavedItem(item.id);
    }
    ref.invalidate(savedItemsProvider);
    ref.invalidate(conversationsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final savedAsync = ref.watch(savedItemsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.base, AppSpacing.lg, AppSpacing.base, 0),
              child: Row(
                children: [
                  Text('Saved', style: AppTypography.displaySmall),
                  const Spacer(),
                  GlassButton(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    borderRadius: AppRadius.md,
                    onTap: () => setState(() {
                      _showSearch = !_showSearch;
                      if (!_showSearch) _searchController.clear();
                    }),
                    child: Icon(
                      _showSearch
                          ? Icons.close_rounded
                          : Icons.search_rounded,
                      color: AppColors.textSecondary,
                      size: AppIconSize.md,
                    ),
                  ),
                ],
              ),
            ),

            if (_showSearch) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.base, AppSpacing.sm, AppSpacing.base, 0),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Search saved items...',
                    hintStyle: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textTertiary),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.textTertiary, size: AppIconSize.sm),
                    filled: true,
                    fillColor: AppColors.surface.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.base),

            // Tab row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: Row(
                children: [
                  _SavedTab(
                    label: 'History',
                    isSelected: false,
                    onTap: () => context.go('/history'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _SavedTab(
                    label: 'Saved',
                    isSelected: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.base),

            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(
                    label: 'Chats',
                    selected: _filter == SavedItemType.chat,
                    onTap: () => setState(() => _filter = SavedItemType.chat),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(
                    label: 'Notes',
                    selected: _filter == SavedItemType.note,
                    onTap: () => setState(() => _filter = SavedItemType.note),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(
                    label: 'Prompts',
                    selected: _filter == SavedItemType.prompt,
                    onTap: () => setState(() => _filter = SavedItemType.prompt),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.base),

            // Items
            Expanded(
              child: savedAsync.when(
                data: (items) {
                  final filtered = _filtered(items);
                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.bookmark_border_rounded,
                            size: 48,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: AppSpacing.base),
                          Text('Nothing saved yet', style: AppTypography.titleMedium),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Save conversations and notes here',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.xxs),
                    itemBuilder: (context, i) {
                      final item = filtered[i];
                      final convId = item.conversationId;
                      return _SavedItem(
                        item: item,
                        icon: _typeIcon(item.type),
                        dateLabel: _formatDate(item.savedAt),
                        onTap: convId == null
                            ? null
                            : () => context.go('/chat?id=$convId'),
                        onMenu: () => _showMenu(item),
                      ).animate().fadeIn(
                            duration: 300.ms,
                            delay: Duration(milliseconds: i * 40),
                          );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBlue,
                    strokeWidth: 2,
                  ),
                ),
                error: (e, _) => Center(
                  child: Text('Error loading saved items',
                      style: AppTypography.bodySmall),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SavedTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDuration.base,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryBlue.withValues(alpha: 0.4)
                : AppColors.borderSubtle,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDuration.base,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryBlue.withValues(alpha: 0.12)
              : AppColors.surface.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: selected
                ? AppColors.primaryBlue.withValues(alpha: 0.4)
                : AppColors.borderSubtle,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: selected ? AppColors.primaryBlue : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _SavedItem extends StatefulWidget {
  final SavedItem item;
  final IconData icon;
  final String dateLabel;

  /// Null when the item has no conversation to open.
  final VoidCallback? onTap;
  final VoidCallback onMenu;

  const _SavedItem({
    required this.item,
    required this.icon,
    required this.dateLabel,
    required this.onMenu,
    this.onTap,
  });

  @override
  State<_SavedItem> createState() => _SavedItemState();
}

class _SavedItemState extends State<_SavedItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:
          widget.onTap == null ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: AppDuration.fast,
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: _pressed
              ? AppColors.surfaceHighlight
              : AppColors.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderSubtle, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                widget.icon,
                size: AppIconSize.sm,
                color: AppColors.primaryBlue.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.title,
                    style: AppTypography.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Saved ${widget.dateLabel}',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: widget.onMenu,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs, vertical: AppSpacing.sm),
                child: Icon(
                  Icons.more_horiz_rounded,
                  size: AppIconSize.sm,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
