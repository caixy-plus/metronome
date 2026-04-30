import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/update_service.dart';
import '../theme/app_colors.dart';

/// 显示更新对话框
Future<void> showUpdateDialog(BuildContext context, GithubRelease release) async {
  final version = release.tagName.replaceFirst('v', '');
  final releaseNotes = release.body.trim();

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final colors = Theme.of(context).extension<AppColors>()!;
      return AlertDialog(
        backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.system_update, color: colors.primary, size: 24),
          SizedBox(width: 8),
          Text(
            '发现新版本',
            style: TextStyle(color: colors.primary, fontSize: 18),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '最新版本: $version',
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          const SizedBox(height: 12),
          if (releaseNotes.isNotEmpty) ...[
            Text(
              '更新内容:',
              style: TextStyle(color: colors.primary, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Text(
                  releaseNotes,
                  style: TextStyle(color: colors.textPrimary, fontSize: 13, height: 1.5),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('稍后', style: TextStyle(color: colors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            _openReleasePage(release.htmlUrl);
          },
          child: const Text('前往下载'),
        ),
      ],
    );
  },
  );
}

/// 打开 GitHub release 页面
Future<void> _openReleasePage(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
