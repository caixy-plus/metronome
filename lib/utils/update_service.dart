import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// GitHub releases API 返回的 release 信息

/// GitHub releases API 返回的 release 信息
class GithubRelease {
  final String tagName;
  final String body;
  final String htmlUrl;

  GithubRelease({
    required this.tagName,
    required this.body,
    required this.htmlUrl,
  });

  factory GithubRelease.fromJson(Map<String, dynamic> json) {
    return GithubRelease(
      tagName: json['tag_name'] as String,
      body: json['body'] as String? ?? '',
      htmlUrl: json['html_url'] as String,
    );
  }
}

/// 更新检测服务
class UpdateService {
  static const String _owner = 'caixy-plus';
  static const String _repo = 'metronome';

  /// 检查是否有新版本
  /// 返回 null 表示检测失败，返回 GithubRelease 表示有新版本
  Future<GithubRelease?> checkUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      debugPrint('[UpdateService] 当前版本: $currentVersion');

      final response = await http.get(
        Uri.parse(
          'https://api.github.com/repos/$_owner/$_repo/releases/latest',
        ),
        headers: {'Accept': 'application/vnd.github+json'},
      );

      if (response.statusCode != 200) {
        debugPrint('[UpdateService] API 请求失败: ${response.statusCode}');
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final latestRelease = GithubRelease.fromJson(json);
      final latestVersion = latestRelease.tagName.replaceFirst('v', '');

      debugPrint('[UpdateService] 最新版本: $latestVersion');

      if (_compareVersions(currentVersion, latestVersion) < 0) {
        return latestRelease;
      }

      return null;
    } catch (e) {
      debugPrint('[UpdateService] 检测更新失败: $e');
      return null;
    }
  }

  /// 版本号比较
  /// 返回负数表示 current < latest，正数表示 current > latest，0 表示相等
  int _compareVersions(String current, String latest) {
    final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final c = i < currentParts.length ? currentParts[i] : 0;
      final l = i < latestParts.length ? latestParts[i] : 0;
      if (c != l) return c.compareTo(l);
    }
    return 0;
  }
}
