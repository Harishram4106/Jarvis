import 'package:flutter/material.dart';
import 'glass_widgets.dart';
import '../theme/theme.dart';

class JarvisCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool isGlow;
  final double? width;
  final double? height;

  const JarvisCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.isGlow = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final card = GlassContainer(
      width: width,
      height: height,
      padding: padding,
      isGlow: isGlow,
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          splashColor: AppColors.primaryBlue.withValues(alpha: 0.1),
          highlightColor: AppColors.primaryBlue.withValues(alpha: 0.05),
          child: card,
        ),
      );
    }

    return card;
  }
}
