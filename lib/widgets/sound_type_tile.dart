import 'package:flutter/material.dart';
import '../models/sound_type.dart';

enum SoundTypeTileStyle {
  /// 横向滚动卡片样式 (home_screen)
  horizontalCard,
  /// 垂直列表项样式 (settings_screen)
  verticalItem,
}

/// 共享的音效类型磁贴组件
class SoundTypeTile extends StatelessWidget {
  final SoundType type;
  final bool isSelected;
  final VoidCallback onTap;
  final SoundTypeTileStyle style;

  const SoundTypeTile({
    super.key,
    required this.type,
    required this.isSelected,
    required this.onTap,
    this.style = SoundTypeTileStyle.horizontalCard,
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
    return style == SoundTypeTileStyle.horizontalCard
        ? _buildHorizontalCard()
        : _buildVerticalItem();
  }

  /// 横向滚动卡片样式 (home_screen)
  Widget _buildHorizontalCard() {
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
            color: isSelected ? const Color(0xFF00F0FF) : const Color(0xFF333333),
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
                  color: isSelected ? const Color(0xFF00F0FF) : const Color(0xFF444444),
                  width: 1.5,
                ),
              ),
              child: Icon(
                _getIcon(),
                color: isSelected ? const Color(0xFF00F0FF) : const Color(0xFF888888),
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              type.displayName,
              style: TextStyle(
                color: isSelected ? const Color(0xFF00F0FF) : const Color(0xFFCCCCCC),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 垂直列表项样式 (settings_screen)
  Widget _buildVerticalItem() {
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
                  color: isSelected ? const Color(0xFF00F0FF) : const Color(0xFF444444),
                  width: 1.5,
                ),
              ),
              child: Icon(
                _getIcon(),
                color: isSelected ? const Color(0xFF00F0FF) : const Color(0xFF888888),
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
                      color: isSelected ? const Color(0xFF00F0FF) : const Color(0xFFEEEEEE),
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
