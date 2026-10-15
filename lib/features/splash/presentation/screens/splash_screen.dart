import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/jarvis_logo_orb.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate initial loading/auth check
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/onboarding');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const JarvisLogoOrb(size: 200),
            const SizedBox(height: AppSpacing.xxxl),
            Text(
              'J A R V I S',
              style: AppTypography.displaySmall.copyWith(
                letterSpacing: 8.0,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'A MORE CAPABLE YOU,\nEVERY DAY',
              textAlign: TextAlign.center,
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textTertiary,
                letterSpacing: 2.0,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 100), // Push it up slightly from optical center
            // Optional subtle loading indicator if needed
            Container(
              width: 40,
              height: 2,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.background, AppColors.primaryCyan, AppColors.background],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            )
          ],
        ),
      ),
    );
  }
}
