import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../models/sound_type.dart';
import '../providers/metronome_provider.dart';
import '../utils/update_service.dart';
import '../widgets/sound_type_tile.dart';
import '../widgets/update_dialog.dart';

/// 设置页面 - 音效选择
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00F0FF)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '设置',
          style: TextStyle(
            color: Color(0xFF00F0FF),
            fontWeight: FontWeight.w300,
            letterSpacing: 4,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _SectionTitle(icon: Icons.music_note, title: '音效选择'),
              SizedBox(height: 16),
              _SoundTypeSelector(),
              SizedBox(height: 32),
              _SectionTitle(icon: Icons.info_outline, title: '音效介绍'),
              SizedBox(height: 16),
              _SoundTypeInfo(),
              SizedBox(height: 32),
              _SectionTitle(icon: Icons.info, title: '关于'),
              SizedBox(height: 16),
              _AboutSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00F0FF), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF00F0FF),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _SoundTypeSelector extends StatelessWidget {
  const _SoundTypeSelector();

  @override
  Widget build(BuildContext context) {
    return Consumer<MetronomeProvider>(
      builder: (context, provider, _) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF333333).withValues(alpha: 0.5), width: 1),
          ),
          child: Column(
            children: SoundType.values.map((type) {
              final isSelected = provider.soundType == type;
              return SoundTypeTile(
                type: type,
                isSelected: isSelected,
                style: SoundTypeTileStyle.verticalItem,
                onTap: () => provider.soundType = type,
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _SoundTypeInfo extends StatelessWidget {
  const _SoundTypeInfo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333).withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _InfoRow(title: '机械音', desc: '清脆短促，古典音乐练习首选，穿透力强'),
          SizedBox(height: 12),
          _InfoRow(title: '电子音', desc: '80年代风格，高噪音环境适用，易产生听觉疲劳'),
          SizedBox(height: 12),
          _InfoRow(title: '鼓机音', desc: '现代动感，流行/摇滚节奏练习'),
          SizedBox(height: 12),
          _InfoRow(title: '木鱼音', desc: '最高穿透力，管弦乐团嘈杂环境首选'),
          SizedBox(height: 12),
          _InfoRow(title: '人声倒数', desc: '直观友好，适合舞蹈和复杂拍子练习'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String desc;

  const _InfoRow({required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(color: Color(0xFF00F0FF), fontSize: 14)),
        Text(
          '$title: ',
          style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 13, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(desc, style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13)),
        ),
      ],
    );
  }
}

class _AboutSection extends StatefulWidget {
  const _AboutSection();

  @override
  State<_AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<_AboutSection> {
  bool _isChecking = false;

  Future<void> _checkForUpdates() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    final updateService = UpdateService();
    final result = await updateService.checkUpdate();

    if (!mounted) return;
    setState(() => _isChecking = false);

    if (result case UpdateAvailable(:final release)) {
      await showUpdateDialog(context, release);
    } else if (result is UpToDate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已是最新版本'),
          backgroundColor: Color(0xFF1A1A1A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('检查失败，请稍后重试'),
          backgroundColor: Color(0xFF1A1A1A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333).withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.music_note, color: Color(0xFF00F0FF), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Metronome',
                style: TextStyle(
                  color: Color(0xFF00F0FF),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              FutureBuilder<String>(
                future: PackageInfo.fromPlatform().then((p) => 'v${p.version}+${p.buildNumber}'),
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data ?? '...',
                    style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isChecking ? null : _checkForUpdates,
              icon: _isChecking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00F0FF)),
                    )
                  : const Icon(Icons.system_update, size: 18, color: Color(0xFF00F0FF)),
              label: Text(
                _isChecking ? '检测中...' : '检查新版本',
                style: const TextStyle(color: Color(0xFF00F0FF)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF00F0FF)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
