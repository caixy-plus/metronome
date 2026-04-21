import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/update_service.dart';

/// 显示更新对话框
Future<void> showUpdateDialog(BuildContext context, GithubRelease release) async {
  final version = release.tagName.replaceFirst('v', '');
  final releaseNotes = release.body.trim();

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.system_update, color: Color(0xFF00F0FF), size: 24),
          SizedBox(width: 8),
          Text(
            '发现新版本',
            style: TextStyle(color: Color(0xFF00F0FF), fontSize: 18),
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
            const Text(
              '更新内容:',
              style: TextStyle(color: Color(0xFF00F0FF), fontSize: 13),
            ),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Text(
                  releaseNotes,
                  style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13, height: 1.5),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('稍后', style: TextStyle(color: Color(0xFF888888))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00F0FF),
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
    ),
  );
}

/// 打开 GitHub release 页面
Future<void> _openReleasePage(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
