import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sound_type.dart';
import '../providers/metronome_provider.dart';

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
            children: [
              // 音效设置标题
              const _SectionTitle(
                icon: Icons.music_note,
                title: '音效选择',
              ),
              const SizedBox(height: 16),
              // 音效类型列表
              const _SoundTypeSelector(),
              const SizedBox(height: 32),
              // 音效介绍
              const _SectionTitle(
                icon: Icons.info_outline,
                title: '音效介绍',
              ),
              const SizedBox(height: 16),
              const _SoundTypeInfo(),
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
            border: Border.all(
              color: const Color(0xFF333333).withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Column(
            children: SoundType.values.map((type) {
              final isSelected = provider.soundType == type;
              return _SoundTypeItem(
                type: type,
                isSelected: isSelected,
                onTap: () {
                  provider.soundType = type;
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _SoundTypeItem extends StatelessWidget {
  final SoundType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _SoundTypeItem({
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00F0FF).withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFF333333).withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
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
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.displayName,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF00F0FF)
                          : const Color(0xFFEEEEEE),
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    type.description,
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF00F0FF),
                size: 22,
              ),
          ],
        ),
      ),
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
        border: Border.all(
          color: const Color(0xFF333333).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _InfoRow(
            title: '机械音',
            desc: '清脆短促，古典音乐练习首选，穿透力强',
          ),
          SizedBox(height: 12),
          _InfoRow(
            title: '电子音',
            desc: '80年代风格，高噪音环境适用，易产生听觉疲劳',
          ),
          SizedBox(height: 12),
          _InfoRow(
            title: '鼓机音',
            desc: '现代动感，流行/摇滚节奏练习',
          ),
          SizedBox(height: 12),
          _InfoRow(
            title: '木鱼音',
            desc: '最高穿透力，管弦乐团嘈杂环境首选',
          ),
          SizedBox(height: 12),
          _InfoRow(
            title: '人声倒数',
            desc: '直观友好，适合舞蹈和复杂拍子练习',
          ),
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
        const Text(
          '• ',
          style: TextStyle(
            color: Color(0xFF00F0FF),
            fontSize: 14,
          ),
        ),
        Text(
          '$title: ',
          style: const TextStyle(
            color: Color(0xFF00F0FF),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            desc,
            style: const TextStyle(
              color: Color(0xFFCCCCCC),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
