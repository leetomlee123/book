/// GitHub Release metadata for in-app updates.
class AppRelease {
  final String tagName;
  final String title;
  final String changelog;
  final String htmlUrl;
  final String downloadUrl;
  final int? apkSize;
  final DateTime? publishedAt;
  final bool isPrerelease;

  const AppRelease({
    required this.tagName,
    required this.title,
    required this.changelog,
    required this.htmlUrl,
    required this.downloadUrl,
    this.apkSize,
    this.publishedAt,
    this.isPrerelease = false,
  });

  /// Normalized version string (e.g. '1.0.1' from 'v1.0.1' or 'v1.0.1+2').
  String get versionName {
    var tag = tagName.trim();
    if (tag.startsWith('v') || tag.startsWith('V')) {
      tag = tag.substring(1);
    }
    final plusIdx = tag.indexOf('+');
    if (plusIdx != -1) {
      return tag.substring(0, plusIdx);
    }
    return tag;
  }

  /// Build number if encoded in tag (e.g. '2' from 'v1.0.1+2').
  int? get buildNumber {
    final plusIdx = tagName.indexOf('+');
    if (plusIdx != -1) {
      return int.tryParse(tagName.substring(plusIdx + 1));
    }
    return null;
  }

  factory AppRelease.fromJson(Map<String, dynamic> json) {
    final tagName = json['tag_name'] as String? ?? '';
    final name = json['name'] as String? ?? tagName;
    final body = json['body'] as String? ?? '暂无详细更新日志';
    final htmlUrl = json['html_url'] as String? ??
        'https://github.com/leetomlee123/book/releases';
    final isPrerelease = json['prerelease'] as bool? ?? false;

    DateTime? publishedAt;
    if (json['published_at'] != null) {
      publishedAt = DateTime.tryParse(json['published_at'].toString());
    }

    String downloadUrl = htmlUrl;
    int? apkSize;

    final assets = json['assets'] as List<dynamic>?;
    if (assets != null && assets.isNotEmpty) {
      // 1. Prefer arm64 split APK: aikanshu-*-arm64-v8a.apk or app-arm64-v8a-release.apk
      Map<String, dynamic>? chosenAsset;
      for (final a in assets) {
        if (a is Map<String, dynamic>) {
          final assetName = (a['name'] as String? ?? '').toLowerCase();
          if (assetName.endsWith('.apk') &&
              (assetName.contains('arm64') || assetName.contains('v8a'))) {
            chosenAsset = a;
            break;
          }
        }
      }

      // 2. Fallback to any .apk asset
      if (chosenAsset == null) {
        for (final a in assets) {
          if (a is Map<String, dynamic>) {
            final assetName = (a['name'] as String? ?? '').toLowerCase();
            if (assetName.endsWith('.apk')) {
              chosenAsset = a;
              break;
            }
          }
        }
      }

      if (chosenAsset != null) {
        final browserDownloadUrl =
            chosenAsset['browser_download_url'] as String?;
        if (browserDownloadUrl != null && browserDownloadUrl.isNotEmpty) {
          downloadUrl = browserDownloadUrl;
        }
        apkSize = chosenAsset['size'] as int?;
      }
    }

    return AppRelease(
      tagName: tagName,
      title: name.isNotEmpty ? name : tagName,
      changelog: body.trim(),
      htmlUrl: htmlUrl,
      downloadUrl: downloadUrl,
      apkSize: apkSize,
      publishedAt: publishedAt,
      isPrerelease: isPrerelease,
    );
  }
}
