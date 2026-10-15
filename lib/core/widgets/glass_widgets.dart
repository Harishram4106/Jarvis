import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// A true glassmorphism container utilizing BackdropFilter
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double blurSigma;
  final bool useBlur;
  final bool isGlow;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = AppRadius.md,
    this.padding = EdgeInsets.zero,
    this.backgroundColor,
    this.borderColor,
    this.blurSigma = 24.0, // High blur for premium frosted glass
    // Off by default: every blurred container is its own saveLayer, so a list
    // or a long chat paid one backdrop filter per item. Over the near-black
    // background the blur was invisible anyway. The app bar and nav keep their
    // own BackdropFilter, which is where content actually scrolls behind.
    // Pass useBlur: true for a surface that sits over real content.
    this.useBlur = false,
    this.isGlow = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // A subtle linear gradient adds a "glare" effect to the glass
    final glassGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        backgroundColor ?? AppColors.surface.withValues(alpha: 0.3),
        backgroundColor ?? AppColors.surface.withValues(alpha: 0.1),
      ],
      stops: const [0.1, 1.0],
    );

    Widget container = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: glassGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isGlow 
              ? AppColors.primaryCyan.withValues(alpha: 0.5)
              : (borderColor ?? AppColors.borderSubtle.withValues(alpha: 0.3)),
          width: 0.5, // Thin, premium border
        ),
        boxShadow: isGlow
            ? [
                BoxShadow(
                  color: AppColors.primaryCyan.withValues(alpha: 0.15),
                  blurRadius: 20.0,
                  spreadRadius: 2.0,
                )
              ]
            : [],
      ),
      child: child,
    );

    if (!useBlur) return container;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter.grouped(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: container,
      ),
    );
  }
}

/// A reusable glassmorphism button
class GlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isDestructive;

  const GlassButton({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = AppRadius.full,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    this.isDestructive = false,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: AppDuration.fast,
        curve: Curves.easeOutCubic,
        child: GlassContainer(
          borderRadius: widget.borderRadius,
          padding: widget.padding,
          blurSigma: 24.0,
          backgroundColor: widget.isDestructive
              ? AppColors.error.withValues(alpha: _isPressed ? 0.3 : 0.15)
              : AppColors.surface.withValues(alpha: _isPressed ? 0.4 : 0.25),
          borderColor: widget.isDestructive
              ? AppColors.error.withValues(alpha: 0.4)
              : AppColors.borderSubtle.withValues(alpha: 0.4),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Specialized input field with glass aesthetic
class GlassInput extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final Widget? prefix;
  final List<Widget>? suffixWidgets;
  final VoidCallback? onSubmit;
  final FocusNode? focusNode;
  final int maxLines;
  final TextInputAction textInputAction;

  const GlassInput({
    super.key,
    required this.controller,
    required this.hintText,
    this.prefix,
    this.suffixWidgets,
    this.onSubmit,
    this.focusNode,
    this.maxLines = 1,
    this.textInputAction = TextInputAction.send,
  });

  @override
  State<GlassInput> createState() => _GlassInputState();
}

class _GlassInputState extends State<GlassInput> {
  late FocusNode _focus;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focus = widget.focusNode ?? FocusNode();
    _focus.addListener(() {
      setState(() => _isFocused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isFocused ? 1.02 : 1.0,
      duration: AppDuration.base,
      curve: Curves.easeOutCubic,
      child: GlassContainer(
        borderRadius: AppRadius.xxl,
        blurSigma: 24.0,
        backgroundColor: AppColors.surface.withValues(alpha: _isFocused ? 0.4 : 0.25),
        borderColor: _isFocused
            ? AppColors.primaryBlue.withValues(alpha: 0.5)
            : AppColors.borderSubtle.withValues(alpha: 0.4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (widget.prefix != null) widget.prefix!,
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 48,
                  maxHeight: 150,
                ),
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  maxLines: null,
                  minLines: 1,
                  textInputAction: widget.textInputAction,
                  onSubmitted: (_) => widget.onSubmit?.call(),
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textTertiary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.suffixWidgets != null) ...widget.suffixWidgets!,
          ],
        ),
      ),
    );
  }
}

/// A perfectly circular, heavily frosted glass button
class GlassCircleButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const GlassCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  State<GlassCircleButton> createState() => _GlassCircleButtonState();
}

class _GlassCircleButtonState extends State<GlassCircleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: AppDuration.fast,
        curve: Curves.easeOutCubic,
        child: GlassContainer(
          borderRadius: 100, // perfect circle
          blurSigma: 32.0,
          padding: const EdgeInsets.all(12),
          backgroundColor: AppColors.surface.withValues(alpha: _isPressed ? 0.4 : 0.15),
          borderColor: AppColors.borderSubtle.withValues(alpha: 0.3),
          child: Icon(
            widget.icon,
            size: 20,
            color: widget.iconColor ?? AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
