import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/theme.dart';

enum OrbState { idle, listening, processing, speaking }

/// The iconic Nexa/Jarvis glowing orb perfectly pinpointed to match the video.
class JarvisOrb extends StatefulWidget {
  final double size;
  final OrbState state;

  // Keep these for backward compatibility
  final bool pulsing;
  final bool reacting;

  const JarvisOrb({
    super.key,
    this.size = 120,
    this.state = OrbState.idle,
    this.pulsing = true,
    this.reacting = false,
  });

  @override
  State<JarvisOrb> createState() => _JarvisOrbState();
}

class _JarvisOrbState extends State<JarvisOrb> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _rotateCtrl;
  late AnimationController _fastReactCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _fastReactCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _checkReaction();
  }

  @override
  void didUpdateWidget(covariant JarvisOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state || widget.reacting != oldWidget.reacting) {
      _checkReaction();
    }
  }

  void _checkReaction() {
    final isListeningOrSpeaking = widget.state == OrbState.listening || widget.state == OrbState.speaking || widget.reacting;
    if (isListeningOrSpeaking) {
      if (!_fastReactCtrl.isAnimating) {
        _fastReactCtrl.repeat(reverse: true);
      }
    } else {
      _fastReactCtrl.stop();
      _fastReactCtrl.animateTo(0, duration: const Duration(milliseconds: 600), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    _fastReactCtrl.dispose();
    super.dispose();
  }

  OrbState get _currentState {
    if (widget.state != OrbState.idle) return widget.state;
    if (widget.reacting) return OrbState.listening;
    return OrbState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final state = _currentState;

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _rotateCtrl, _fastReactCtrl]),
      builder: (context, _) {
        final pulse = _pulseCtrl.value;
        final rotate = _rotateCtrl.value;
        final react = _fastReactCtrl.value;

        final isListening = state == OrbState.listening;
        final isProcessing = state == OrbState.processing;
        final isSpeaking = state == OrbState.speaking;

        // Dynamic multipliers based on state
        final pulseMux = isSpeaking ? react : pulse;
        final glowIntensity = isSpeaking ? 1.0 + (react * 0.5) : (isListening ? 0.8 : 0.5 + (pulse * 0.3));

        return RepaintBoundary(
          child: SizedBox(
            width: s * 3.0, // Wider for ribbons
            height: s * 2.5,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // 1. Background Particles
                CustomPaint(
                  size: Size(s * 3.0, s * 2.5),
                  painter: _ParticlePainter(phase: rotate),
                ),

                // 2. Thick Glowing Ribbons (Always present, reacts to speaking)
                CustomPaint(
                  size: Size(s * 3.0, s * 2.5),
                  painter: _RibbonPainter(
                    phase: rotate,
                    pulse: pulseMux,
                    intensity: isSpeaking ? 1.5 : (isListening ? 1.2 : 1.0),
                  ),
                ),

                // 3. Razor thin outer concentric rings (Idle/Listening)
                if (!isProcessing)
                  CustomPaint(
                    size: Size(s * 1.8, s * 1.8),
                    painter: _ConcentricRingsPainter(
                      opacity: 0.3 + (isSpeaking ? react * 0.3 : pulse * 0.1),
                    ),
                  ),

                // 4. Processing Comet Trails
                if (isProcessing)
                  _build3DRings(s, rotate),

                // 5. Audio Visualizer Spikes (Listening)
                if (isListening)
                  CustomPaint(
                    size: Size(s * 1.6, s * 1.6),
                    painter: _VisualizerSpikePainter(
                      react: react,
                      phase: rotate,
                    ),
                  ),

                // 6. Perfect Black Hole Core
                Container(
                  width: s * 0.8,
                  height: s * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                    boxShadow: [
                      // Intense inner cyan glow
                      BoxShadow(
                        color: AppColors.primaryCyan.withValues(alpha: 0.8 * glowIntensity),
                        blurRadius: 16 * glowIntensity,
                        spreadRadius: 2 * glowIntensity,
                      ),
                      // Deep outer blue glow
                      BoxShadow(
                        color: const Color(0xFF2962FF).withValues(alpha: 0.5 * glowIntensity),
                        blurRadius: 48 * glowIntensity,
                        spreadRadius: 8 * glowIntensity,
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.primaryCyan.withValues(alpha: 0.9),
                      width: 2.0 + (isSpeaking ? react * 2.0 : 0.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _build3DRings(double s, double rotate) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(math.pi / 2.5)
            ..rotateZ(rotate * 2 * math.pi),
          alignment: Alignment.center,
          child: CustomPaint(
            size: Size(s * 1.5, s * 1.5),
            painter: _Sweep3DRingPainter(color: AppColors.primaryCyan, width: 3.0),
          ),
        ),
        Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(math.pi / 3)
            ..rotateX(math.pi / 6)
            ..rotateZ(-rotate * 3 * math.pi),
          alignment: Alignment.center,
          child: CustomPaint(
            size: Size(s * 1.3, s * 1.3),
            painter: _Sweep3DRingPainter(color: AppColors.accentViolet, width: 4.0),
          ),
        ),
        Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(-math.pi / 4)
            ..rotateX(-math.pi / 8)
            ..rotateZ(rotate * 4 * math.pi),
          alignment: Alignment.center,
          child: CustomPaint(
            size: Size(s * 1.15, s * 1.15),
            painter: _Sweep3DRingPainter(color: const Color(0xFF2962FF), width: 2.5),
          ),
        ),
      ],
    );
  }
}

class _RibbonPainter extends CustomPainter {
  final double phase;
  final double pulse;
  final double intensity;

  _RibbonPainter({required this.phase, required this.pulse, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final width = size.width;
    final maxAmplitude = size.height * 0.25 * intensity;

    // Glowing thick ribbon
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0 + (pulse * 4.0)
      ..color = const Color(0xFF2962FF).withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16.0);

    // Sharp bright core ribbon
    final corePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 + (pulse * 1.0)
      ..color = AppColors.primaryCyan.withValues(alpha: 0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.0);
      
    // Secondary weaving ribbon
    final secondaryPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = AppColors.accentViolet.withValues(alpha: 0.7);

    final path1 = Path();
    final path2 = Path();

    for (double x = 0; x <= width; x += 2) {
      final nx = x / width;
      // Hanning window to taper the ends
      final window = 0.5 * (1 - math.cos(2 * math.pi * nx));
      
      final y1 = center.dy + math.sin((nx * 2.5 + phase) * 2 * math.pi) * maxAmplitude * window;
      final y2 = center.dy + math.cos((nx * 3.0 - phase * 1.2) * 2 * math.pi) * (maxAmplitude * 0.7) * window;

      if (x == 0) {
        path1.moveTo(x, y1);
        path2.moveTo(x, y2);
      } else {
        path1.lineTo(x, y1);
        path2.lineTo(x, y2);
      }
    }

    canvas.drawPath(path1, glowPaint);
    canvas.drawPath(path1, corePaint);
    canvas.drawPath(path2, secondaryPaint);
  }

  @override
  bool shouldRepaint(_RibbonPainter old) => old.phase != phase || old.pulse != pulse || old.intensity != intensity;
}

class _ParticlePainter extends CustomPainter {
  final double phase;
  _ParticlePainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryCyan.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    final random = math.Random(42); // Deterministic seed for stable particles
    
    for (int i = 0; i < 30; i++) {
      final xOffset = random.nextDouble();
      final yOffset = random.nextDouble();
      final speed = 0.5 + random.nextDouble();
      
      // Drift upwards and wrap around
      var x = size.width * xOffset + (math.sin(phase * math.pi * 2 * speed) * 20);
      var y = size.height * yOffset - (phase * size.height * speed);
      
      y = y % size.height;
      if (y < 0) y += size.height;

      // Twinkle effect
      final twinkle = (math.sin(phase * math.pi * 10 * speed + i) + 1) / 2;
      paint.color = AppColors.primaryCyan.withValues(alpha: 0.1 + (0.5 * twinkle));
      
      canvas.drawCircle(Offset(x, y), 1.0 + (random.nextDouble() * 2), paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.phase != phase;
}

class _ConcentricRingsPainter extends CustomPainter {
  final double opacity;
  _ConcentricRingsPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = AppColors.primaryCyan.withValues(alpha: opacity);

    canvas.drawCircle(center, size.width * 0.40, paint);
    
    paint.color = const Color(0xFF2962FF).withValues(alpha: opacity * 0.6);
    canvas.drawCircle(center, size.width * 0.50, paint);
  }

  @override
  bool shouldRepaint(_ConcentricRingsPainter old) => old.opacity != opacity;
}

class _VisualizerSpikePainter extends CustomPainter {
  final double react;
  final double phase;

  _VisualizerSpikePainter({required this.react, required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.28; 
    final maxSpike = size.width * 0.15; 

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.primaryCyan.withValues(alpha: 0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1.0);
      
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = const Color(0xFF2962FF).withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);

    final path = Path();
    const segments = 120; // Enough for sharp spikes
    
    for (int i = 0; i <= segments; i++) {
      final angle = (i / segments) * 2 * math.pi;
      
      // High frequency teeth
      final teeth = math.pow((math.sin(angle * 40 + phase * 10) + 1) / 2, 4).toDouble();
      
      // Modulate teeth with react value (only spike when reacting)
      final spikeVal = teeth * maxSpike * react;
      
      final r = baseRadius + spikeVal;
      
      final px = center.dx + r * math.cos(angle);
      final py = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_VisualizerSpikePainter old) => old.react != react || old.phase != phase;
}

class _Sweep3DRingPainter extends CustomPainter {
  final Color color;
  final double width;

  _Sweep3DRingPainter({required this.color, required this.width});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Comet trail sweep gradient
    final gradient = SweepGradient(
      colors: [
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 0.1),
        color.withValues(alpha: 0.5),
        color,
      ],
      stops: const [0.0, 0.5, 0.9, 1.0],
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..shader = gradient.createShader(rect)
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * 3
      ..shader = gradient.createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0)
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, math.pi * 2 * 0.9, false, glowPaint);
    canvas.drawArc(rect, 0, math.pi * 2 * 0.9, false, paint);
  }

  @override
  bool shouldRepaint(_Sweep3DRingPainter old) => old.color != color || old.width != width;
}
