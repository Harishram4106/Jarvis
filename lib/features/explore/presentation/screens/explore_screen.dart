import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/jarvis_card.dart';
import '../../../../core/widgets/glass_app_bar.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: const Text('Explore'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search topics, tools, ideas...',
                  prefixIcon: Icon(Icons.search, color: AppColors.textTertiary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  _FilterChip(label: 'All', isSelected: true),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(label: 'Productivity'),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(label: 'Learning'),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(label: 'Tech'),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(label: 'Career'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _ExploreListItem(
                    icon: Icons.hub_outlined,
                    title: 'Learn something new',
                    prompt: 'Teach me something new today. Ask me what I already know first.',
                    subtitle: 'Curated learning paths',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ExploreListItem(
                    icon: Icons.check_circle_outline,
                    title: 'Productivity',
                    prompt: 'Suggest a productivity technique I could try this week, and how to start.',
                    subtitle: 'Tools and techniques',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ExploreListItem(
                    icon: Icons.devices_outlined,
                    title: 'Technology',
                    prompt: 'What happened in technology recently that is worth my attention?',
                    subtitle: 'Stay updated',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ExploreListItem(
                    icon: Icons.lightbulb_outline,
                    title: 'Creativity',
                    prompt: 'Give me a creative idea to work on, and the first step to take.',
                    subtitle: 'Ideas and inspiration',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ExploreListItem(
                    icon: Icons.work_outline,
                    title: 'Career',
                    prompt: 'What skill should I build next for my career? Ask about my goals first.',
                    subtitle: 'Skills for the future',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ExploreListItem(
                    icon: Icons.spa_outlined,
                    title: 'Wellness',
                    prompt: 'Suggest one small change I could make this week for my wellbeing.',
                    subtitle: 'A healthier you',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _FilterChip({required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryBlue : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: isSelected ? AppColors.primaryBlue : AppColors.borderSubtle,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.labelMedium.copyWith(
          color: isSelected ? AppColors.background : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _ExploreListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  /// Each topic is just an opening message to the assistant.
  final String prompt;

  const _ExploreListItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.prompt,
  });

  @override
  Widget build(BuildContext context) {
    return JarvisCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => context.go('/chat?q=${Uri.encodeQueryComponent(prompt)}'),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: AppColors.primaryCyan, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
