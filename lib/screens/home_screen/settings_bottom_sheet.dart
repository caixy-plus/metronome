import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../../models/sound_type.dart';
import '../../providers/metronome_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/update_service.dart';
import '../../widgets/sound_type_tile.dart';
import '../../widgets/update_dialog.dart';
import '../../theme/app_colors.dart';

/// 设置底部抽屉 - 毛玻璃 + 圆角设计
class SettingsBottomSheet extends StatefulWidget {
  const SettingsBottomSheet({super.key});

  @override
  State<SettingsBottomSheet> createState() => _SettingsBottomSheetState();
}

class _SettingsBottomSheetState extends State<SettingsBottomSheet> {
  double _extent = 0.35;
  bool _isCheckingUpdate = false;

  Future<String> _loadAppVersionText() async {
    final info = await PackageInfo.fromPlatform();
    return 'v${info.version}+${info.buildNumber}';
  }

  Future<void> _checkUpdate() async {
    if (_isCheckingUpdate) return;
    setState(() => _isCheckingUpdate = true);
    try {
      final result = await UpdateService().checkUpdate();
      if (!mounted) return;

      if (result case UpdateAvailable(:final release)) {
        await showUpdateDialog(context, release);
      } else if (result is UpToDate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已是最新版本'),
            backgroundColor: Theme.of(context).extension<AppColors>()!.surface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('检查失败，请稍后重试'),
            backgroundColor: Theme.of(context).extension<AppColors>()!.surface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingUpdate = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (n) {
        setState(() => _extent = n.extent);
        return false;
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.35,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) {
          final showMore = _extent >= 0.55;
          final moreOpacity = (( _extent - 0.50) / 0.20).clamp(0.0, 1.0);

          return Container(
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(color: colors.primary.withValues(alpha: 0.2), width: 1),
            ),
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(child: _buildHandleBar(colors)),
                SliverToBoxAdapter(child: _buildHeader(colors)),
                SliverToBoxAdapter(child: Divider(color: colors.border, height: 1)),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                const SliverToBoxAdapter(child: _SoundTypeSelector()),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                const SliverToBoxAdapter(child: _ThemeSelector()),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        '上拉 更多设置',
                        style: TextStyle(color: colors.textSecondary, fontSize: 12),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: showMore ? moreOpacity : 0.0,
                    child: IgnorePointer(
                      ignoring: !showMore,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: _MoreSettingsSection(
                          isCheckingUpdate: _isCheckingUpdate,
                          appVersionTextFuture: _loadAppVersionText(),
                          onCheckUpdate: _checkUpdate,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHandleBar(AppColors colors) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: colors.textDisabled,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(Icons.music_note, color: colors.primary, size: 24),
          SizedBox(width: 12),
          Text(
            '音效选择',
            style: TextStyle(
              color: colors.primary,
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
              return SoundTypeTile(
                type: type,
                isSelected: isSelected,
                style: SoundTypeTileStyle.horizontalCard,
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

class _MoreSettingsSection extends StatelessWidget {
  final bool isCheckingUpdate;
  final Future<String> appVersionTextFuture;
  final VoidCallback onCheckUpdate;

  const _MoreSettingsSection({
    required this.isCheckingUpdate,
    required this.appVersionTextFuture,
    required this.onCheckUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.12), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: colors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                '更多设置',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            label: '应用版本',
            colors: colors,
            value: FutureBuilder<String>(
              future: appVersionTextFuture,
              builder: (context, snapshot) {
                return Text(
                  snapshot.data ?? '...',
                  style: TextStyle(color: colors.textPrimary, fontSize: 13),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isCheckingUpdate ? null : onCheckUpdate,
              icon: isCheckingUpdate
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
                    )
                  : Icon(Icons.system_update, size: 18, color: colors.primary),
              label: Text(
                isCheckingUpdate ? '检测中...' : '检查新版本',
                style: TextStyle(color: colors.primary),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({required String label, required Widget value, required AppColors colors}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(color: colors.textSecondary, fontSize: 13),
        ),
        const Spacer(),
        value,
      ],
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final themeProvider = context.watch<ThemeProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.palette, color: colors.primary, size: 18),
            SizedBox(width: 8),
            Text(
              '主题',
              style: TextStyle(
                color: colors.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border.withValues(alpha: 0.5), width: 1),
          ),
          padding: EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: 100,
                child: _ThemeOption(
                  label: '明亮',
                  icon: Icons.wb_sunny,
                  isSelected: themeProvider.themeMode == ThemeMode.light,
                  onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                ),
              ),
              SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: _ThemeOption(
                  label: '暗色',
                  icon: Icons.nights_stay,
                  isSelected: themeProvider.themeMode == ThemeMode.dark,
                  onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                ),
              ),
              SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: _ThemeOption(
                  label: '自动',
                  icon: Icons.brightness_auto,
                  isSelected: themeProvider.themeMode == ThemeMode.system,
                  onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 10),
        backgroundColor: isSelected ? colors.primary.withValues(alpha: 0.15) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? colors.primary : colors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? colors.primary : colors.textSecondary, size: 20),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? colors.primary : colors.textPrimary,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
