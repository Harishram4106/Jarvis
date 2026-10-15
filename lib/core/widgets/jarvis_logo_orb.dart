import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/theme.dart';

class JarvisLogoOrb extends StatefulWidget {
  final double size;
  final bool animate;

  const JarvisLogoOrb({
    super.key,
    this.size = 200,
    this.animate = true,
  });

  @override
  State<JarvisLogoOrb> createState() => _JarvisLogoOrbState();
}

class _JarvisLogoOrbState extends State<JarvisLogoOrb> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant JarvisLogoOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _LogoOrbPainter(rotation: _controller.value * 2 * math.pi),
          );
        },
      ),
    );
  }
}

class _LogoOrbPainter extends CustomPainter {
  final double rotation;
  _LogoOrbPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Ambient Background Glow
    final ambientPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primaryCyan.withValues(alpha: 0.15),
          AppColors.background.withValues(alpha: 0.0),
        ],
        stops: const [0.1, 0.8],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..blendMode = BlendMode.screen;
    canvas.drawCircle(center, radius, ambientPaint);

    // 2. The segmented outer ring
    final outerRingRadius = radius * 0.75;
    final segmentPaint = Paint()
      ..color = AppColors.primaryBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.0);

    final glowSegmentPaint = Paint()
      ..color = AppColors.primaryCyan.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

    final int numSegments = 8;
    final double sweepAngle = (2 * math.pi) / numSegments * 0.7; // 70% fill, 30% gap
    final double gapAngle = (2 * math.pi) / numSegments * 0.3;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    for (int i = 0; i < numSegments; i++) {
      final startAngle = i * (sweepAngle + gapAngle);
      final rect = Rect.fromCircle(center: center, radius: outerRingRadius);
      canvas.drawArc(rect, startAngle, sweepAngle, false, glowSegmentPaint);
      canvas.drawArc(rect, startAngle, sweepAngle, false, segmentPaint);
    }
    
    // Inner thin ring
    final innerThinRingPaint = Paint()
      ..color = AppColors.primaryCyan.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius * 0.55, innerThinRingPaint);

    canvas.restore();

    // 3. Inner solid ring
    final innerRingRadius = radius * 0.35;
    final innerRingPaint = Paint()
      ..color = AppColors.primaryBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.0);
      
    final innerGlowPaint = Paint()
      ..color = AppColors.primaryCyan.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);

    canvas.drawCircle(center, innerRingRadius, innerGlowPaint);
    canvas.drawCircle(center, innerRingRadius, innerRingPaint);

    // 4. Center Dot
    final dotRadius = radius * 0.12;
    final dotPaint = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.0);
    final dotGlow = Paint()
      ..color = AppColors.primaryCyan
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

    canvas.drawCircle(center, dotRadius, dotGlow);
    canvas.drawCircle(center, dotRadius, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _LogoOrbPainter oldDelegate) {
    return oldDelegate.rotation != rotation;
  }
}
