import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/theme.dart';
import 'premium_background.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Let PremiumBackground show through
      extendBody: true,
      // extendBody keeps content visible (blurred) behind the glass nav, while
      // Scaffold adds the nav's height to the body's MediaQuery padding so
      // SafeArea children (e.g. the chat composer) aren't hidden underneath it.
      bottomNavigationBar: _JarvisBottomNav(navigationShell: navigationShell),
      body: PremiumBackground(child: navigationShell),
    );
  }
}

class _JarvisBottomNav extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _JarvisBottomNav({required this.navigationShell});

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter.grouped(
        filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.navBackground.withValues(alpha: 0.5),
            border: Border(
              top: BorderSide(
                color: AppColors.borderSubtle.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavButton(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                    isActive: navigationShell.currentIndex == 0,
                    onTap: () => _onTap(context, 0),
                  ),
                  _NavButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    activeIcon: Icons.chat_bubble_rounded,
                    label: 'Chat',
                    isActive: navigationShell.currentIndex == 1,
                    onTap: () => _onTap(context, 1),
                  ),
                  _NavButton(
                    icon: Icons.explore_outlined,
                    activeIcon: Icons.explore_rounded,
                    label: 'Explore',
                    isActive: navigationShell.currentIndex == 2,
                    onTap: () => _onTap(context, 2),
                  ),
                  _NavButton(
                    icon: Icons.grid_view_outlined,
                    activeIcon: Icons.grid_view_rounded,
                    label: 'Tools',
                    isActive: navigationShell.currentIndex == 3,
                    onTap: () => _onTap(context, 3),
                  ),
                  _NavButton(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profile',
                    isActive: navigationShell.currentIndex == 4,
                    onTap: () => _onTap(context, 4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primaryCyan : AppColors.textSecondary;
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppDuration.fast,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: color,
              size: AppIconSize.md,
              shadows: isActive 
                ? [BoxShadow(color: AppColors.primaryCyan.withValues(alpha: 0.5), blurRadius: 10)]
                : null,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
