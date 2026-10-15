import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/jarvis_orb.dart';
import '../../../../services/providers.dart';

class VoiceScreen extends ConsumerStatefulWidget {
  const VoiceScreen({super.key});

  @override
  ConsumerState<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends ConsumerState<VoiceScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    // Opening the screen is the request to talk; asks for mic on first use.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(voiceProvider.notifier).startListening(),
    );
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  void _close() {
    ref.read(voiceProvider.notifier).cancel();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final voice = ref.watch(voiceProvider);
    final notifier = ref.read(voiceProvider.notifier);
    final status = switch (voice) {
      VoiceState.idle => 'Tap the mic to speak',
      VoiceState.listening => 'Listening...',
      VoiceState.processing => 'Thinking...',
      VoiceState.speaking => 'Speaking...',
      VoiceState.unavailable => 'Microphone unavailable',
    };
    final orbState = switch (voice) {
      VoiceState.listening => OrbState.listening,
      VoiceState.processing => OrbState.processing,
      VoiceState.speaking => OrbState.speaking,
      _ => OrbState.idle,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Glow
          Positioned.fill(
            child: Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryCyan.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _close();
                        },
                      ),
                      Text('JARVIS', style: AppTypography.brandSmall.copyWith(color: AppColors.textPrimary)),
                      // Balances the close button so the title stays centred.
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Orb & Wave
                _VoiceVisualizer(waveCtrl: _waveCtrl, orbState: orbState),
                
                const SizedBox(height: AppSpacing.xxl),
                
                // Status Text
                Text(status, style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w500)),

                const SizedBox(height: AppSpacing.md),

                // What the recogniser has heard so far.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Text(
                    notifier.heard,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textTertiary),
                  ),
                ),
                
                const Spacer(),
                
                // Bottom Controls
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Mute Button
                      _ControlButton(
                        icon: voice == VoiceState.listening
                            ? Icons.mic_off_outlined
                            : Icons.mic_none,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          voice == VoiceState.listening
                              ? notifier.stopListening()
                              : notifier.startListening();
                        },
                      ),
                      
                      const SizedBox(width: AppSpacing.xl),
                      
                      // Stop Button (Center)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          voice == VoiceState.idle
                              ? notifier.startListening()
                              : notifier.pause();
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryBlue.withValues(alpha: 0.2),
                            border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.5), width: 2),
                          ),
                          child: Center(
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: AppColors.primaryCyan,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: AppSpacing.xl),
                      
                      // Keyboard Button
                      _ControlButton(
                        icon: Icons.keyboard_outlined,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _close();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceVisualizer extends StatelessWidget {
  final AnimationController waveCtrl;
  final OrbState orbState;

  const _VoiceVisualizer({required this.waveCtrl, required this.orbState});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated rings
          AnimatedBuilder(
            animation: waveCtrl,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: List.generate(3, (i) {
                  final delay = i * 0.33;
                  final t = (waveCtrl.value + delay) % 1.0;
                  final scale = 1.0 + t * 0.5;
                  final opacity = (1.0 - t) * 0.3;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryCyan.withValues(alpha: opacity),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),

          // Orb
          Hero(
            tag: 'jarvis_orb',
            child: JarvisOrb(size: 140, state: orbState),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ControlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceHighlight,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 24),
      ),
    );
  }
}
