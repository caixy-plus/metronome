import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';

/// 帮助对话框 - Cyber-Noir 风格
class HelpDialog extends StatefulWidget {
  const HelpDialog({super.key});

  @override
  State<HelpDialog> createState() => _HelpDialogState();
}

class _HelpDialogState extends State<HelpDialog> {
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
    final colors = Theme.of(context).extension<AppColors>()!;
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
              color: colors.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.help_outline, color: colors.primary, size: 24),
                    SizedBox(width: 12),
                    Text(
                      '使用帮助',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(color: colors.border),
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator(color: colors.primary))
                      : SingleChildScrollView(child: HelpContentBuilder(content: _helpContent)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('关闭', style: TextStyle(color: colors.primary, fontSize: 16)),
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
class HelpContentBuilder extends StatelessWidget {
  final String content;

  const HelpContentBuilder({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final sections = _parseContent(content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((section) {
        if (section.startsWith('## ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              section.substring(3),
              style: TextStyle(color: colors.primary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          );
        } else if (section.startsWith('### ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Row(
              children: [
                Icon(Icons.star, color: colors.primary, size: 16),
                const SizedBox(width: 8),
                Text(
                  section.substring(4),
                  style: TextStyle(color: colors.primary, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        } else if (section.startsWith('| ')) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              section.replaceAll('|', '  ').trim(),
              style: TextStyle(color: colors.textPrimary, fontSize: 12),
            ),
          );
        } else if (section.trim().isEmpty) {
          return const SizedBox(height: 8);
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              section,
              style: TextStyle(color: colors.textPrimary, fontSize: 13, height: 1.5),
            ),
          );
        }
      }).toList(),
    );
  }

  List<String> _parseContent(String content) => content.split('\n');
}
