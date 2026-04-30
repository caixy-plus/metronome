import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/metronome_provider.dart';
import '../theme/app_colors.dart';

/// 节拍指示器 - 固定高度换行版本
/// 圆点大小固定，行数根据拍数自动增加（最多2行）
class BeatIndicator extends StatelessWidget {
  const BeatIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return RepaintBoundary(
      child: Consumer<MetronomeProvider>(
        builder: (context, provider, _) {
          final totalBeats = provider.beatsPerMeasure;
          final currentPlayingBeat = provider.isPlaying ? provider.currentPlayingBeat : -1;

          // 固定圆点大小
          const dotSize = 26.0;
          const dotSpacing = 6.0;
          const fixedHeight = 72.0;

          // 根据拍数计算每行能显示多少个
          // 屏幕宽度约 360dp，减去 padding 和边距，预估每行容量
          const containerWidth = 300.0;
          final itemsPerRow = ((containerWidth - dotSize) / (dotSize + dotSpacing)).floor().clamp(4, 16);
          final rows = (totalBeats / itemsPerRow).ceil().clamp(1, 2);

          return SizedBox(
            height: fixedHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(rows, (rowIndex) {
                final startIndex = rowIndex * itemsPerRow;
                final endIndex = (startIndex + itemsPerRow).clamp(0, totalBeats);
                final rowBeats = endIndex - startIndex;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(rowBeats, (colIndex) {
                      final index = startIndex + colIndex;
                      final isActive = index == currentPlayingBeat;
                      final isAccent = index == 0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: dotSpacing / 2),
                        child: _BeatDot(
                          isActive: isActive,
                          isAccent: isAccent,
                          index: index + 1,
                          size: dotSize,
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}

class _BeatDot extends StatelessWidget {
  final bool isActive;
  final bool isAccent;
  final int index;
  final double size;

  const _BeatDot({
    required this.isActive,
    required this.isAccent,
    required this.index,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final activeColor = isAccent
        ? colors.accent
        : colors.primary;
    final inactiveColor = isAccent
        ? colors.accent.withValues(alpha: 0.2)
        : colors.primary.withValues(alpha: 0.15);
    final borderColor = isAccent
        ? colors.accent.withValues(alpha: 0.5)
        : colors.primary.withValues(alpha: 0.3);

    const textSize = 11.0;

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: AnimatedScale(
          scale: isActive ? 1.0 : 0.85,
          duration: const Duration(milliseconds: 50),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 50),
            width: size * 0.85,
            height: size * 0.85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? activeColor : inactiveColor,
              border: Border.all(
                color: isActive ? activeColor : borderColor,
                width: 2,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.8),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.2),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  fontSize: textSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
