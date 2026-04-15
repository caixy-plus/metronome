import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/sound_type.dart';
import '../providers/metronome_provider.dart';
import '../widgets/bpm_dial.dart';
import '../widgets/beat_type_selector.dart';
import '../widgets/beat_indicator.dart';

/// 节拍器主页面 - Cyber-Noir 设计
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _webAudioUnlocked = false;

  /// Web 平台解锁音频
  Future<void> _unlockWebAudio(BuildContext context) async {
    if (!kIsWeb) {
      setState(() => _webAudioUnlocked = true);
      return;
    }

    // Web 平台：必须在用户交互事件中初始化音频
    final provider = context.read<MetronomeProvider>();
    await provider.initAudioForWeb();
    setState(() => _webAudioUnlocked = true);
    if (context.mounted) {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Web 平台且未解锁音频时，显示解锁提示
    if (kIsWeb && !_webAudioUnlocked) {
      return _WebAudioUnlockScreen(onUnlock: () => _unlockWebAudio(context));
    }

    return _MetronomeHome();
  }
}

/// Web 音频解锁界面
class _WebAudioUnlockScreen extends StatelessWidget {
  final VoidCallback onUnlock;

  const _WebAudioUnlockScreen({required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: GestureDetector(
        onTap: onUnlock,
        child: Stack(
          children: [
            // 背景效果
            CustomPaint(painter: _CyberNoirBackgroundPainter()),
            // 遮罩
            Container(color: const Color(0xFF0D0D0D).withValues(alpha: 0.7)),
            // 解锁提示
            Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.touch_app,
                      color: Color(0xFF00F0FF),
                      size: 80,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'TAP TO START',
                      style: TextStyle(
                        color: Color(0xFF00F0FF),
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
                        color: const Color(0xFF888888),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '（Web 浏览器自动播放策略限制）',
                      style: TextStyle(
                        color: const Color(0xFF555555),
                        fontSize: 12,
                      ),
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

/// 空的主界面（原有的 HomeScreen 内容）
class _MetronomeHome extends StatelessWidget {
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _HelpDialog(),
    );
  }

  /// 显示设置底部抽屉
  void _showSettingsSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _SettingsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.settings,
            color: Color(0xFF00F0FF),
          ),
          onPressed: () => _showSettingsSheet(context),
        ),
        title: const Text(
          'METRONOME',
          style: TextStyle(
            color: Color(0xFF00F0FF),
            fontWeight: FontWeight.w300,
            letterSpacing: 8,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.help_outline,
              color: Color(0xFF00F0FF),
            ),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 600;
            final height = isDesktop
                ? constraints.maxHeight.clamp(500.0, 700.0)
                : constraints.maxHeight;

            return SizedBox(
              height: height,
              child: Stack(
                children: [
                  // 背景渐变光晕
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CyberNoirBackgroundPainter(),
                    ),
                  ),
                  // 主内容 - 移除滚动，使用自适应布局
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: const [
                        BeatIndicator(),
                        SizedBox(height: 8),
                        BeatTypeSelector(),
                        SizedBox(height: 4),
                        BpmDial(),
                        _PlayButton(),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Cyber-Noir 背景画家 - 深邃磨砂黑 + 光晕效果
class _CyberNoirBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 深邃黑色背景
    final bgPaint = Paint()
      ..color = const Color(0xFF0D0D0D)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 顶部青色光晕
    final topGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -1.5),
        radius: 1.2,
        colors: [
          const Color(0xFF00F0FF).withValues(alpha: 0.15),
          const Color(0xFF00F0FF).withValues(alpha: 0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, topGlow);

    // 底部紫色光晕
    final bottomGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 1.5),
        radius: 1.2,
        colors: [
          const Color(0xFF8B00FF).withValues(alpha: 0.1),
          const Color(0xFF8B00FF).withValues(alpha: 0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bottomGlow);

    // 网格线
    final gridPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Cyber-Noir 播放按钮 - 毛玻璃 + 水波纹
class _PlayButton extends StatefulWidget {
  const _PlayButton();

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton>
    with SingleTickerProviderStateMixin {
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

  void _onTap() {
    // Handled in onTap directly
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MetronomeProvider>(
      builder: (context, provider, _) {
        final isPlaying = provider.isPlaying;

        // 控制水波纹动画
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
                // 水波纹
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
                // 按钮主体 - 毛玻璃效果
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
                          color: isPlaying
                              ? const Color(0xFF00F0FF)
                              : const Color(0xFF333333),
                          width: 2,
                        ),
                        boxShadow: isPlaying
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF00F0FF)
                                      .withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 44,
                        color: isPlaying
                            ? const Color(0xFF00F0FF)
                            : const Color(0xFF888888),
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

/// 帮助对话框 - Cyber-Noir 风格
class _HelpDialog extends StatefulWidget {
  const _HelpDialog();

  @override
  State<_HelpDialog> createState() => _HelpDialogState();
}

class _HelpDialogState extends State<_HelpDialog> {
  String _helpContent = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHelpContent();
  }

  Future<void> _loadHelpContent() async {
    try {
      final content = await rootBundle.loadString('assets/help_zh.md');
      if (mounted) {
        setState(() {
          _helpContent = content;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _helpContent = '无法加载帮助文档';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题
                const Row(
                  children: [
                    Icon(
                      Icons.help_outline,
                      color: Color(0xFF00F0FF),
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      '使用帮助',
                      style: TextStyle(
                        color: Color(0xFF00F0FF),
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: Color(0xFF333333)),
                const SizedBox(height: 16),
                // 内容
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00F0FF),
                          ),
                        )
                      : SingleChildScrollView(
                          child: _HelpContentBuilder(content: _helpContent),
                        ),
                ),
                const SizedBox(height: 16),
                // 关闭按钮
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    '关闭',
                    style: TextStyle(
                      color: Color(0xFF00F0FF),
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 解析并渲染帮助文档内容
class _HelpContentBuilder extends StatelessWidget {
  final String content;

  const _HelpContentBuilder({required this.content});

  @override
  Widget build(BuildContext context) {
    final sections = _parseContent(content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((section) {
        if (section.startsWith('## ')) {
          // 二级标题
          return Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              section.substring(3),
              style: const TextStyle(
                color: Color(0xFF00F0FF),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        } else if (section.startsWith('### ')) {
          // 三级标题
          return Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Row(
              children: [
                const Icon(Icons.star, color: Color(0xFF00F0FF), size: 16),
                const SizedBox(width: 8),
                Text(
                  section.substring(4),
                  style: const TextStyle(
                    color: Color(0xFF00F0FF),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        } else if (section.startsWith('| ')) {
          // 表格行 - 简化处理
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              section.replaceAll('|', '  ').trim(),
              style: const TextStyle(
                color: Color(0xFFCCCCCC),
                fontSize: 12,
              ),
            ),
          );
        } else if (section.trim().isEmpty) {
          return const SizedBox(height: 8);
        } else {
          // 普通文本
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              section,
              style: const TextStyle(
                color: Color(0xFFCCCCCC),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          );
        }
      }).toList(),
    );
  }

  List<String> _parseContent(String content) {
    // 简单的 markdown 解析 - 按行分割
    return content.split('\n');
  }
}

/// 设置底部抽屉 - 毛玻璃 + 圆角设计
class _SettingsBottomSheet extends StatelessWidget {
  const _SettingsBottomSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部把手
          _buildHandleBar(),
          // 标题
          _buildHeader(),
          const Divider(color: Color(0xFF333333), height: 1),
          // 音效选择器
          const _SoundTypeSelector(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHandleBar() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFF444444),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: const [
          Icon(Icons.music_note, color: Color(0xFF00F0FF), size: 24),
          SizedBox(width: 12),
          Text(
            '音效选择',
            style: TextStyle(
              color: Color(0xFF00F0FF),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// 音效选择器 - 横向滚动 + 即时试听
class _SoundTypeSelector extends StatelessWidget {
  const _SoundTypeSelector();

  @override
  Widget build(BuildContext context) {
    return Consumer<MetronomeProvider>(
      builder: (context, provider, _) {
        return SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: SoundType.values.length,
            itemBuilder: (context, index) {
              final type = SoundType.values[index];
              final isSelected = provider.soundType == type;
              return _SoundTypeCard(
                type: type,
                isSelected: isSelected,
                onTap: () {
                  HapticFeedback.selectionClick();
                  provider.soundType = type;
                },
              );
            },
          ),
        );
      },
    );
  }
}

/// 音效卡片
class _SoundTypeCard extends StatelessWidget {
  final SoundType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _SoundTypeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  IconData _getIcon() {
    switch (type) {
      case SoundType.mechanical:
        return Icons.precision_manufacturing;
      case SoundType.electronic:
        return Icons.speaker;
      case SoundType.drumMachine:
        return Icons.album;
      case SoundType.woodblock:
        return Icons.piano;
      case SoundType.voiceCount:
        return Icons.record_voice_over;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00F0FF).withValues(alpha: 0.15)
              : const Color(0xFF252525),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00F0FF)
                : const Color(0xFF333333),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFF00F0FF).withValues(alpha: 0.2)
                    : const Color(0xFF2A2A2A),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF00F0FF)
                      : const Color(0xFF444444),
                  width: 1.5,
                ),
              ),
              child: Icon(
                _getIcon(),
                color: isSelected
                    ? const Color(0xFF00F0FF)
                    : const Color(0xFF888888),
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              type.displayName,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF00F0FF)
                    : const Color(0xFFCCCCCC),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
