import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/metronome_provider.dart';
import '../theme/app_colors.dart';

/// 节拍类型选择器 - 律动轮 (Rhythm Wheel)
/// 使用 FixedExtentScrollPhysics 确保磁吸归位
class BeatTypeSelector extends StatelessWidget {
  const BeatTypeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Consumer<MetronomeProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 分子滚轮 (Beats Per Measure)
              _RhythmWheel(
                value: provider.beatsPerMeasure,
                minValue: 1,
                maxValue: 16,
                onChanged: (v) => provider.beatsPerMeasure = v,
              ),

              // 发光金色分隔线
              _GlowingDivider(),

              // 分母滚轮 (Beat Unit)
              _BeatUnitWheel(
                value: provider.beatUnit,
                onChanged: (v) => provider.beatUnit = v,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 斜杠分隔符
class _GlowingDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SizedBox(
      width: 20,
      height: 80,
      child: Center(
        child: Text(
          '/',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w200,
            color: colors.primary,
          ),
        ),
      ),
    );
  }
}

/// 律动轮组件 - 分子选择 (1-16)
class _RhythmWheel extends StatefulWidget {
  final int value;
  final int minValue;
  final int maxValue;
  final ValueChanged<int> onChanged;

  const _RhythmWheel({
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.onChanged,
  });

  @override
  State<_RhythmWheel> createState() => _RhythmWheelState();
}

class _RhythmWheelState extends State<_RhythmWheel> {
  late FixedExtentScrollController _controller;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.value - widget.minValue;
    _controller = FixedExtentScrollController(initialItem: _previousIndex);
  }

  @override
  void didUpdateWidget(covariant _RhythmWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当外部值变化时，同步滚动位置
    if (widget.value != oldWidget.value) {
      final newIndex = widget.value - widget.minValue;
      if (newIndex != _controller.selectedItem) {
        _controller.animateToItem(
          newIndex,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return RepaintBoundary(
      child: SizedBox(
        width: 56,
        height: 80,
        child: ListWheelScrollView.useDelegate(
          controller: _controller,
          itemExtent: 32,
          diameterRatio: 1.5,
          perspective: 0.005,
          // 关键：使用 FixedExtentScrollPhysics 确保磁吸归位
          physics: const FixedExtentScrollPhysics(),
          magnification: 1.15,
          squeeze: 1.0,
          onSelectedItemChanged: (index) {
            if (index != _previousIndex) {
              _previousIndex = index;
              HapticFeedback.lightImpact();
              widget.onChanged(index + widget.minValue);
            }
          },
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: widget.maxValue - widget.minValue + 1,
            builder: (context, index) {
              final value = index + widget.minValue;
              final isSelected = value == widget.value;
              return _WheelItem(
                value: value,
                isSelected: isSelected,
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 分母滚轮 - 预设值 [1, 2, 4, 8, 16]
class _BeatUnitWheel extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _BeatUnitWheel({
    required this.value,
    required this.onChanged,
  });

  @override
  State<_BeatUnitWheel> createState() => _BeatUnitWheelState();
}

class _BeatUnitWheelState extends State<_BeatUnitWheel> {
  static const List<int> _values = [1, 2, 4, 8, 16];
  late FixedExtentScrollController _controller;
  int _previousIndex = 1; // 默认选中 2 (index=1)

  int get _initialIndex {
    final index = _values.indexOf(widget.value);
    return index >= 0 ? index : 1;
  }

  @override
  void initState() {
    super.initState();
    _previousIndex = _initialIndex;
    _controller = FixedExtentScrollController(initialItem: _initialIndex);
  }

  @override
  void didUpdateWidget(covariant _BeatUnitWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIndex = _values.indexOf(widget.value);
    if (widget.value != oldWidget.value && newIndex != _controller.selectedItem) {
      _controller.animateToItem(
        newIndex >= 0 ? newIndex : 1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return RepaintBoundary(
      child: SizedBox(
        width: 56,
        height: 80,
        child: ListWheelScrollView.useDelegate(
          controller: _controller,
          itemExtent: 32,
          diameterRatio: 1.5,
          perspective: 0.005,
          // 关键：使用 FixedExtentScrollPhysics 确保磁吸归位
          physics: const FixedExtentScrollPhysics(),
          magnification: 1.15,
          squeeze: 1.0,
          onSelectedItemChanged: (index) {
            if (index != _previousIndex) {
              _previousIndex = index;
              HapticFeedback.lightImpact();
              widget.onChanged(_values[index]);
            }
          },
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: _values.length,
            builder: (context, index) {
              final value = _values[index];
              final isSelected = value == widget.value;
              return _WheelItem(
                value: value,
                isSelected: isSelected,
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 滚轮单项 - 带选中高亮效果
class _WheelItem extends StatelessWidget {
  final int value;
  final bool isSelected;

  const _WheelItem({
    required this.value,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isSelected
            ? colors.primary.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(
                color: colors.primary.withValues(alpha: 0.4),
                width: 1,
              )
            : null,
      ),
      child: Center(
        child: Text(
          '$value',
          style: TextStyle(
            fontSize: isSelected ? 22 : 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
            color: isSelected
                ? colors.primary
                : colors.primary.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
