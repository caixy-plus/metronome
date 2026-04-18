import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/metronome_provider.dart';

/// Cyber-Noir 播放按钮 - 毛玻璃 + 水波纹
class PlayButton extends StatefulWidget {
  const PlayButton({super.key});

  @override
  State<PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<PlayButton> with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _rippleAnimation = Tween<double>(begin: 1.0, end: 1.8).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MetronomeProvider>(
      builder: (context, provider, _) {
        final isPlaying = provider.isPlaying;

        if (isPlaying && !_rippleController.isAnimating) {
          _rippleController.repeat();
        } else if (!isPlaying && _rippleController.isAnimating) {
          _rippleController.stop();
          _rippleController.reset();
        }

        return GestureDetector(
          onTap: () {
            if (isPlaying) {
              _rippleController.stop();
              _rippleController.reset();
            }
            provider.togglePlayPause();
          },
          child: SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isPlaying)
                  AnimatedBuilder(
                    animation: _rippleAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 80 * _rippleAnimation.value,
                        height: 80 * _rippleAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF00F0FF)
                                .withValues(alpha: 1.0 - _rippleAnimation.value + 1.0),
                            width: 2,
                          ),
                        ),
                      );
                    },
                  ),
                ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isPlaying
                            ? const Color(0xFF00F0FF).withValues(alpha: 0.2)
                            : const Color(0xFF1A1A1A).withValues(alpha: 0.8),
                        border: Border.all(
                          color: isPlaying ? const Color(0xFF00F0FF) : const Color(0xFF333333),
                          width: 2,
                        ),
                        boxShadow: isPlaying
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF00F0FF).withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 44,
                        color: isPlaying ? const Color(0xFF00F0FF) : const Color(0xFF888888),
                      ),
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
}
