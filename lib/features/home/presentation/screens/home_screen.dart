import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/jarvis_logo_orb.dart';
import '../../../../core/widgets/jarvis_card.dart';
import '../../../../services/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning,'
        : hour < 17
            ? 'Good Afternoon,'
            : 'Good Evening,';
    // First name only — the greeting reads wrong with a full name.
    final name = (profile?.name ?? '').trim().split(' ').first;
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.history, color: AppColors.textPrimary),
                    onPressed: () => context.push('/history'),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/profile'),
                    child: CircleAvatar(
                      backgroundColor: AppColors.surfaceHighlight,
                      child: Text(
                        initial,
                        style: AppTypography.labelLarge.copyWith(color: AppColors.primaryCyan),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Greeting
              Text(greeting, style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary)),
              Text(name, style: AppTypography.displaySmall.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.sm),
              Text('Ready when you are.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary)),
              
              const Spacer(),
              
              // Center Orb
              const Center(child: JarvisLogoOrb(size: 180)),
              
              const Spacer(),

              // Grid
              Row(
                children: [
                  Expanded(
                    child: _HomeGridItem(
                      icon: Icons.chat_bubble_outline,
                      title: 'Chat',
                      subtitle: 'Ask anything',
                      onTap: () => context.go('/chat'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _HomeGridItem(
                      icon: Icons.explore_outlined,
                      title: 'Explore',
                      subtitle: 'Get things done',
                      onTap: () => context.go('/explore'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _HomeGridItem(
                      icon: Icons.grid_view,
                      title: 'Tools',
                      subtitle: 'Learn & discover',
                      onTap: () => context.go('/tools'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _HomeGridItem(
                      icon: Icons.calendar_today_outlined,
                      title: 'Calendar',
                      subtitle: 'Plan your day',
                      onTap: () => context.push('/calendar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeGridItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HomeGridItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return JarvisCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryCyan, size: 28),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xxs),
          Text(subtitle, style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}
