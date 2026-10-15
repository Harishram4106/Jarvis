import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/glass_widgets.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Your AI\nPartner in Progress',
                style: AppTypography.displaySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Think smarter.\nPlan better.\nDo more.',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              // Central Graphic Placeholder
              Center(
                child: Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primaryBlue.withValues(alpha: 0.2),
                        AppColors.background,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(100), // Creates an arc effect at top
                  ),
                  child: Center(
                    child: Icon(Icons.public, size: 100, color: AppColors.primaryBlue.withValues(alpha: 0.5)),
                  ),
                ),
              ),
              const Spacer(),
              // Paging Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDot(true),
                  const SizedBox(width: AppSpacing.sm),
                  _buildDot(false),
                  const SizedBox(width: AppSpacing.sm),
                  _buildDot(false),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              // Next Button
              SizedBox(
                width: double.infinity,
                child: GlassButton(
                  onTap: () => context.go('/home'),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Next'),
                      SizedBox(width: AppSpacing.sm),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Skip Button
              Center(
                child: TextButton(
                  onPressed: () => context.go('/home'),
                  child: Text(
                    'Skip',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.primaryBlue),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(bool isActive) {
    return Container(
      width: isActive ? 12 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryCyan : AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(4),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primaryCyan.withValues(alpha: 0.5),
                  blurRadius: 4.0,
                )
              ]
            : null,
      ),
    );
  }
}
