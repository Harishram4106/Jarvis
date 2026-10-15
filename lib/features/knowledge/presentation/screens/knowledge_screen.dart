import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../../../../repositories/memory_store.dart';
import '../../../../services/providers.dart';

/// What JARVIS remembers about the user — the facts sent with every message.
/// Backed by [MemoryStore]; anything the user says "remember ..." to lands here.
class KnowledgeScreen extends ConsumerStatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  ConsumerState<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends ConsumerState<KnowledgeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final controller = TextEditingController();
    final fact = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remember this'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: 'e.g. I prefer concise answers',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (fact == null || fact.isEmpty) return;
    final facts = await ref.read(memoryStoreProvider).add(fact);
    ref.read(memoriesProvider.notifier).state = facts;
  }

  /// Index within the unfiltered list, so a search doesn't delete the wrong row.
  Future<void> _remove(String fact) async {
    final index = ref.read(memoriesProvider).indexOf(fact);
    if (index < 0) return;
    final facts = await ref.read(memoryStoreProvider).removeAt(index);
    ref.read(memoriesProvider.notifier).state = facts;
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Forget everything?'),
        content: const Text(
            'JARVIS will lose every fact it has remembered about you.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Forget all'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final facts = await ref.read(memoryStoreProvider).clear();
    ref.read(memoriesProvider.notifier).state = facts;
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(memoriesProvider);
    final query = _searchController.text.toLowerCase();
    final facts = query.isEmpty
        ? all
        : all.where((f) => f.toLowerCase().contains(query)).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: const Text('Knowledge Base'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: all.isEmpty ? null : _clear,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: AppColors.background),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search what JARVIS knows...',
                  prefixIcon: Icon(Icons.search, color: AppColors.textTertiary),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${all.length} of ${MemoryStore.maxFacts} facts remembered',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textTertiary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: facts.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.psychology_outlined,
                                size: 48, color: AppColors.textTertiary),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              all.isEmpty
                                  ? 'Nothing remembered yet.\nSay "remember ..." in a chat, or add a fact here.'
                                  : 'Nothing matches that search.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyMedium
                                  .copyWith(color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: facts.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.xs),
                      itemBuilder: (context, i) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHighlight,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: AppColors.borderSubtle),
                          ),
                          child: const Icon(Icons.lightbulb_outline,
                              color: AppColors.primaryCyan, size: 20),
                        ),
                        title: Text(facts[i],
                            style: AppTypography.bodyMedium),
                        trailing: IconButton(
                          icon: const Icon(Icons.close,
                              color: AppColors.textTertiary),
                          onPressed: () => _remove(facts[i]),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
