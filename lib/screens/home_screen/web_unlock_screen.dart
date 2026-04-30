import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Web 音频解锁界面
class WebUnlockScreen extends StatelessWidget {
  final VoidCallback onUnlock;

  const WebUnlockScreen({super.key, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      backgroundColor: colors.background,
      body: GestureDetector(
        onTap: onUnlock,
        child: Stack(
          children: [
            CustomPaint(painter: CyberNoirBackgroundPainter(colors: colors), size: MediaQuery.of(context).size),
            Container(color: colors.background.withValues(alpha: 0.7)),
            Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.3),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app, color: colors.primary, size: 80),
                    const SizedBox(height: 24),
                    Text(
                      'TAP TO START',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '点击屏幕任意位置\n以启用节拍音效',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '（Web 浏览器自动播放策略限制）',
                      style: TextStyle(color: colors.textDisabled, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cyber-Noir 背景画家 - 深邃磨砂黑 + 光晕效果
class CyberNoirBackgroundPainter extends CustomPainter {
  final AppColors colors;

  CyberNoirBackgroundPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = colors.background..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final topGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -1.5),
        radius: 1.2,
        colors: [
          colors.primary.withValues(alpha: 0.15),
          colors.primary.withValues(alpha: 0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, topGlow);

    final bottomGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 1.5),
        radius: 1.2,
        colors: [
          colors.primary.withValues(alpha: 0.1),
          colors.primary.withValues(alpha: 0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bottomGlow);

    final gridPaint = Paint()
      ..color = colors.surface
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const gridSize = 40.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CyberNoirBackgroundPainter oldDelegate) {
    return oldDelegate.colors != colors;
  }
}
