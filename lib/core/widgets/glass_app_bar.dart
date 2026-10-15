import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/theme.dart';

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final double blurSigma;

  const GlassAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.blurSigma = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter.grouped(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.5),
            border: Border(
              bottom: BorderSide(
                color: AppColors.borderSubtle.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
          ),
          child: AppBar(
            title: title,
            actions: actions,
            leading: leading,
            automaticallyImplyLeading: automaticallyImplyLeading,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
