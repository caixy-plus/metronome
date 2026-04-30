import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/metronome_provider.dart';
import '../utils/tempo_term.dart';
import '../theme/app_colors.dart';

/// BPM控制组件 - Cyber-Noir 版本（支持拖动）
class BpmDial extends StatelessWidget {
  const BpmDial({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Consumer<MetronomeProvider>(
      builder: (context, provider, _) {
        final bpmProgress = (provider.bpm - 40) / (240 - 40); // 40-240 归一化
        final tempoInfo = getTempoTermWithMeaning(provider.bpm);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 第一行：Tap + BPM弧 + 静音按钮（强制边界控制）
            LayoutBuilder(
              builder: (context, constraints) {
                // 最大可用宽度减去内边距
                final maxWidth = constraints.maxWidth;
                // 计算实际需要的宽度：64 + 12 + 150 + 12 + 64 = 302
                final neededWidth = 302.0;
                // 如果空间足够，按原样显示；否则缩放
                if (maxWidth >= neededWidth) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TapButton(
                        onTap: () {
                          provider.tap();
                          HapticFeedback.mediumImpact();
                        },
                      ),
                      const SizedBox(width: 12),
                      _DraggableBpmArc(
                        bpm: provider.bpm,
                        bpmProgress: bpmProgress,
                        isPlaying: provider.isPlaying,
                        onBpmChanged: (newBpm) {
                          provider.bpm = newBpm;
                        },
                      ),
                      const SizedBox(width: 12),
                      _SilentModeButton(
                        isSilent: provider.isSilentMode,
                        onToggle: () {
                          provider.isSilentMode = !provider.isSilentMode;
                          HapticFeedback.lightImpact();
                        },
                      ),
                    ],
                  );
                } else {
                  // 空间不足时，等比缩放整个 Row
                  final scale = maxWidth / neededWidth;
                  return Center(
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _TapButton(
                            onTap: () {
                              provider.tap();
                              HapticFeedback.mediumImpact();
                            },
                          ),
                          const SizedBox(width: 12),
                          _DraggableBpmArc(
                            bpm: provider.bpm,
                            bpmProgress: bpmProgress,
                            isPlaying: provider.isPlaying,
                            onBpmChanged: (newBpm) {
                              provider.bpm = newBpm;
                            },
                          ),
                          const SizedBox(width: 12),
                          _SilentModeButton(
                            isSilent: provider.isSilentMode,
                            onToggle: () {
                              provider.isSilentMode = !provider.isSilentMode;
                              HapticFeedback.lightImpact();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            // 速度术语显示（使用 FittedBox 防止换行）
            _TempoTermText(
              text: tempoInfo.$1,
              fontSize: 18,
              color: colors.primary,
              letterSpacing: 2,
            ),
            const SizedBox(height: 4),
            // 速度术语中文含义
            _TempoTermText(
              text: tempoInfo.$2,
              fontSize: 12,
              color: colors.textSecondary,
              letterSpacing: 1,
            ),
            const SizedBox(height: 16),
            // 加减按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 减号按钮 - 毛玻璃
                _FrostedBpmButton(
                  icon: Icons.remove,
                  onPressed: provider.bpm > 40
                      ? () => provider.bpm = provider.bpm - 1
                      : null,
                  onLongPressStart: provider.bpm > 40
                      ? () => provider.startBpmAdjust(-1)
                      : null,
                  onLongPressEnd: () => provider.stopBpmAdjust(),
                ),
                const SizedBox(width: 40),
                // 加号按钮 - 毛玻璃
                _FrostedBpmButton(
                  icon: Icons.add,
                  onPressed: provider.bpm < 240
                      ? () => provider.bpm = provider.bpm + 1
                      : null,
                  onLongPressStart: provider.bpm < 240
                      ? () => provider.startBpmAdjust(1)
                      : null,
                  onLongPressEnd: () => provider.stopBpmAdjust(),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// 跨平台安全的文本组件 - 使用 FittedBox 防止换行
class _TempoTermText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;
  final double letterSpacing;

  const _TempoTermText({
    required this.text,
    required this.fontSize,
    required this.color,
    required this.letterSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.clip,
        textScaler: TextScaler.noScaling, // 禁用系统字体缩放
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w300,
          color: color,
          letterSpacing: letterSpacing,
          height: 1.2, // 统一行高
        ),
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
        ),
      ),
    );
  }
}

/// 可拖动的 BPM 圆弧组件
class _DraggableBpmArc extends StatefulWidget {
  final int bpm;
  final double bpmProgress;
  final bool isPlaying;
  final ValueChanged<int> onBpmChanged;

  const _DraggableBpmArc({
    required this.bpm,
    required this.bpmProgress,
    required this.isPlaying,
    required this.onBpmChanged,
  });

  @override
  State<_DraggableBpmArc> createState() => _DraggableBpmArcState();
}

class _DraggableBpmArcState extends State<_DraggableBpmArc> {
  // 弧的起始角度：135度 (math.pi * 0.75)
  // 弧的范围：270度 (math.pi * 1.5)
  static const double _startAngle = math.pi * 0.75;
  static const double _sweepAngle = math.pi * 1.5;
  static const int _minBpm = 40;
  static const int _maxBpm = 240;
  static const Size _size = Size(150, 110);

  bool _isDragging = false;

  double _angleToProgress(double angle) {
    // 将角度标准化到相对于起始角度的值
    double relativeAngle = angle - _startAngle;
    // 标准化到 0 到 2π 之间
    while (relativeAngle < 0) {
      relativeAngle += math.pi * 2;
    }
    while (relativeAngle > math.pi * 2) {
      relativeAngle -= math.pi * 2;
    }
    return (relativeAngle / _sweepAngle).clamp(0.0, 1.0);
  }

  int _progressToBpm(double progress) {
    return (_minBpm + (progress * (_maxBpm - _minBpm))).round();
  }

  void _updateBpmFromPosition(Offset localPosition) {
    final center = Offset(_size.width / 2, _size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    double angle = math.atan2(dy, dx);
    double progress = _angleToProgress(angle);
    int newBpm = _progressToBpm(progress);

    if (newBpm != widget.bpm) {
      widget.onBpmChanged(newBpm);
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SizedBox(
      width: _size.width,
      height: _size.height,
      child: GestureDetector(
        onPanStart: (details) {
          _isDragging = true;
          _updateBpmFromPosition(details.localPosition);
        },
        onPanUpdate: (details) {
          if (_isDragging) {
            _updateBpmFromPosition(details.localPosition);
          }
        },
        onPanEnd: (details) {
          _isDragging = false;
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 进度弧
            CustomPaint(
              size: _size,
              painter: _BpmArcPainter(
                progress: widget.bpmProgress,
                isPlaying: widget.isPlaying,
                colors: colors,
              ),
            ),
            // 拖动热点（更大的透明区域方便拖动）
            CustomPaint(
              size: _size,
              painter: _BpmDragHotspotPainter(
                progress: widget.bpmProgress,
                bpm: widget.bpm,
                colors: colors,
              ),
            ),
            // BPM 数字 - 使用 FittedBox 防止溢出
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${widget.bpm}',
                    maxLines: 1,
                    softWrap: false,
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w200,
                      color: colors.primary,
                      letterSpacing: 2,
                      height: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'BPM',
                    maxLines: 1,
                    softWrap: false,
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                      letterSpacing: 3,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 拖动热点画家 - 绘制可拖动的圆点
class _BpmDragHotspotPainter extends CustomPainter {
  final double progress;
  final int bpm;
  final AppColors colors;

  _BpmDragHotspotPainter({required this.progress, required this.bpm, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final angle = math.pi * 0.75 + math.pi * 1.5 * progress;

    final point = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );

    // 绘制大透明热点区域（方便拖动）
    final hotspotPaint = Paint()
      ..color = colors.primary.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(point, 16, hotspotPaint);

    // 绘制实心圆点
    final dotPaint = Paint()
      ..color = colors.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(point, 8, dotPaint);

    // 绘制高光
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(point.dx - 2, point.dy - 2), 3, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _BpmDragHotspotPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.bpm != bpm || oldDelegate.colors != colors;
  }
}

/// BPM 进度弧画家
class _BpmArcPainter extends CustomPainter {
  final double progress;
  final bool isPlaying;
  final AppColors colors;

  _BpmArcPainter({required this.progress, required this.isPlaying, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // 背景弧
    final bgPaint = Paint()
      ..color = colors.surface
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75, // 从 135 度开始
      math.pi * 1.5,  // 270 度范围
      false,
      bgPaint,
    );

    // 前景弧 (发光效果)
    if (progress > 0) {
      final fgPaint = Paint()
        ..shader = SweepGradient(
          startAngle: math.pi * 0.75,
          endAngle: math.pi * 0.75 + math.pi * 1.5 * progress,
          colors: [
            colors.primary,
            isPlaying ? colors.primary : colors.primary,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi * 0.75,
        math.pi * 1.5 * progress,
        false,
        fgPaint,
      );

      // 末端发光点
      if (progress > 0.01) {
        final angle = math.pi * 0.75 + math.pi * 1.5 * progress;
        final glowPoint = Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        );
        final glowPaint = Paint()
          ..color = colors.primary
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(glowPoint, 4, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BpmArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isPlaying != isPlaying || oldDelegate.colors != colors;
  }
}

/// 毛玻璃 BPM 按钮
class _FrostedBpmButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;

  const _FrostedBpmButton({
    required this.icon,
    this.onPressed,
    this.onLongPressStart,
    this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isEnabled = onPressed != null;

    return GestureDetector(
      onTap: onPressed,
      onLongPressStart: (_) => onLongPressStart?.call(),
      onLongPressEnd: (_) => onLongPressEnd?.call(),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEnabled
                  ? colors.surface.withValues(alpha: 0.6)
                  : colors.background.withValues(alpha: 0.4),
              border: Border.all(
                color: isEnabled
                    ? colors.primary.withValues(alpha: 0.3)
                    : colors.border,
                width: 1.5,
              ),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              size: 28,
              color: isEnabled
                  ? colors.primary
                  : colors.textDisabled,
            ),
          ),
        ),
      ),
    );
  }
}

/// Tap Tempo 按钮 - 发光效果
class _TapButton extends StatefulWidget {
  final VoidCallback onTap;

  const _TapButton({required this.onTap});

  @override
  State<_TapButton> createState() => _TapButtonState();
}

class _TapButtonState extends State<_TapButton> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onTap();
    _glowController.forward().then((_) => _glowController.reverse());
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.surface.withValues(alpha: 0.6),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: _glowAnimation.value),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.3 * _glowAnimation.value),
                      blurRadius: 12 * _glowAnimation.value,
                      spreadRadius: 2 * _glowAnimation.value,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'TAP',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 静音模式切换按钮
class _SilentModeButton extends StatelessWidget {
  final bool isSilent;
  final VoidCallback onToggle;

  const _SilentModeButton({
    required this.isSilent,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return GestureDetector(
      onTap: onToggle,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSilent
                  ? colors.primary.withValues(alpha: 0.2)
                  : colors.surface.withValues(alpha: 0.6),
              border: Border.all(
                color: isSilent
                    ? colors.primary
                    : colors.primary.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: isSilent
                  ? [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.5),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              isSilent ? Icons.volume_off : Icons.volume_up,
              size: 28,
              color: isSilent ? colors.primary : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
