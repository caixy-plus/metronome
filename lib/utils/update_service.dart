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

/// 更新检测结果（强类型：不再用 null 混合表示多种状态）
sealed class UpdateCheckResult {
  const UpdateCheckResult();
}

class UpdateAvailable extends UpdateCheckResult {
  final GithubRelease release;
  final String latestVersion;
  final String currentVersion;
  const UpdateAvailable({
    required this.release,
    required this.latestVersion,
    required this.currentVersion,
  });
}

class UpToDate extends UpdateCheckResult {
  final String latestVersion;
  final String currentVersion;
  const UpToDate({required this.latestVersion, required this.currentVersion});
}

class UpdateCheckFailed extends UpdateCheckResult {
  final String message;
  final int? statusCode;
  const UpdateCheckFailed(this.message, {this.statusCode});
}

/// 更新检测服务
class UpdateService {
  static const String _owner = 'caixy-plus';
  static const String _repo = 'metronome';

  /// 检查是否有新版本
  Future<UpdateCheckResult> checkUpdate() async {
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
        return UpdateCheckFailed(
          'API 请求失败',
          statusCode: response.statusCode,
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final latestRelease = GithubRelease.fromJson(json);
      final latestVersion = _normalizeVersion(latestRelease.tagName);

      debugPrint('[UpdateService] 最新版本: $latestVersion');

      if (_compareVersions(_normalizeVersion(currentVersion), latestVersion) < 0) {
        return UpdateAvailable(
          release: latestRelease,
          latestVersion: latestVersion,
          currentVersion: currentVersion,
        );
      }

      return UpToDate(latestVersion: latestVersion, currentVersion: currentVersion);
    } catch (e) {
      debugPrint('[UpdateService] 检测更新失败: $e');
      return UpdateCheckFailed('检测更新失败: $e');
    }
  }

  /// 规范化版本号（支持 v 前缀、忽略 +build）
  String _normalizeVersion(String raw) {
    var s = raw.trim();
    if (s.startsWith('v') || s.startsWith('V')) {
      s = s.substring(1);
    }
    // ignore build metadata
    final plusIdx = s.indexOf('+');
    if (plusIdx >= 0) {
      s = s.substring(0, plusIdx);
    }
    return s;
  }

  /// 版本号比较（弱 SemVer）
  /// 返回负数表示 a < b，正数表示 a > b，0 表示相等
  int _compareVersions(String a, String b) {
    final na = _normalizeVersion(a);
    final nb = _normalizeVersion(b);

    final coreA = na.split('-').first;
    final coreB = nb.split('-').first;
    final preA = na.contains('-') ? na.substring(na.indexOf('-') + 1) : null;
    final preB = nb.contains('-') ? nb.substring(nb.indexOf('-') + 1) : null;

    final aParts = coreA.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final bParts = coreB.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (int i = 0; i < 3; i++) {
      final ai = i < aParts.length ? aParts[i] : 0;
      final bi = i < bParts.length ? bParts[i] : 0;
      if (ai != bi) return ai.compareTo(bi);
    }

    // Core equal, handle pre-release: pre < stable
    if (preA == null && preB == null) return 0;
    if (preA == null && preB != null) return 1;
    if (preA != null && preB == null) return -1;

    final ta = _tokenizePre(preA!);
    final tb = _tokenizePre(preB!);
    final n = ta.length > tb.length ? ta.length : tb.length;
    for (int i = 0; i < n; i++) {
      final va = i < ta.length ? ta[i] : null;
      final vb = i < tb.length ? tb[i] : null;
      if (va == null && vb == null) return 0;
      if (va == null) return -1;
      if (vb == null) return 1;

      final ia = int.tryParse(va);
      final ib = int.tryParse(vb);
      if (ia != null && ib != null) {
        if (ia != ib) return ia.compareTo(ib);
      } else if (ia != null && ib == null) {
        // numeric identifiers have lower precedence than non-numeric? (SemVer says numeric < non-numeric)
        return -1;
      } else if (ia == null && ib != null) {
        return 1;
      } else {
        final c = va.compareTo(vb);
        if (c != 0) return c;
      }
    }
    return 0;
  }

  List<String> _tokenizePre(String pre) {
    return pre.split(RegExp(r'[\.\-]')).where((e) => e.isNotEmpty).toList();
  }
}
