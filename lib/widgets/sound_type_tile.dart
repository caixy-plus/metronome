import 'package:flutter/material.dart';
import '../models/sound_type.dart';
import '../theme/app_colors.dart';

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
    final colors = Theme.of(context).extension<AppColors>()!;
    return style == SoundTypeTileStyle.horizontalCard
        ? _buildHorizontalCard(colors)
        : _buildVerticalItem(colors);
  }

  /// 横向滚动卡片样式 (home_screen)
  Widget _buildHorizontalCard(AppColors colors) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.15)
              : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.3),
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
                    ? colors.primary.withValues(alpha: 0.2)
                    : colors.surfaceVariant,
                border: Border.all(
                  color: isSelected ? colors.primary : colors.textDisabled,
                  width: 1.5,
                ),
              ),
              child: Icon(
                _getIcon(),
                color: isSelected ? colors.primary : colors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              type.displayName,
              style: TextStyle(
                color: isSelected ? colors.primary : colors.textPrimary,
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
  Widget _buildVerticalItem(AppColors colors) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: colors.border.withValues(alpha: 0.3),
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
                    ? colors.primary.withValues(alpha: 0.2)
                    : colors.surfaceVariant,
                border: Border.all(
                  color: isSelected ? colors.primary : colors.textDisabled,
                  width: 1.5,
                ),
              ),
              child: Icon(
                _getIcon(),
                color: isSelected ? colors.primary : colors.textSecondary,
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
                      color: isSelected ? colors.primary : colors.textPrimary,
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    type.description,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: colors.primary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
