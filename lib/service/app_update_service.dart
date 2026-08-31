import 'dart:async';

import 'package:book/common/app_log.dart';
import 'package:book/entity/app_release.dart';
import 'package:book/widgets/app_update_dialog.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service for checking and executing app updates via GitHub Releases.
class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  static const String defaultRepo = 'leetomlee123/book';
  static const String defaultApiUrl =
      'https://api.github.com/repos/$defaultRepo/releases/latest';

  PackageInfo? _cachedPackageInfo;

  /// Get current local package info via package_info_plus.
  Future<PackageInfo> getPackageInfo() async {
    final cached = _cachedPackageInfo;
    if (cached != null) return cached;
    try {
      final info = await PackageInfo.fromPlatform();
      _cachedPackageInfo = info;
      return info;
    } catch (e) {
      AppLog.w('Update', 'PackageInfo.fromPlatform failed: $e');
      return PackageInfo(
        appName: '爱看书',
        packageName: 'com.opensource.ikanshu',
        version: '1.0.0',
        buildNumber: '1',
      );
    }
  }

  /// Fetch latest release from GitHub API.
  Future<AppRelease?> fetchLatestRelease({
    String apiUrl = defaultApiUrl,
  }) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'aikanshu-reader-app',
        },
      ),
    );

    try {
      final response = await dio.get<Map<String, dynamic>>(apiUrl);
      if (response.statusCode == 200 && response.data != null) {
        return AppRelease.fromJson(response.data!);
      }
    } catch (e) {
      AppLog.w('Update', 'fetchLatestRelease failed', error: e);
    }
    return null;
  }

  /// Compare local version with remote release tag.
  /// Returns `true` if remote version is strictly newer.
  static bool isNewerVersion({
    required String localVersion,
    required int localBuildNumber,
    required String remoteTag,
  }) {
    var remote = remoteTag.trim();
    if (remote.startsWith('v') || remote.startsWith('V')) {
      remote = remote.substring(1);
    }

    int? remoteBuildNumber;
    final plusIdx = remote.indexOf('+');
    if (plusIdx != -1) {
      remoteBuildNumber = int.tryParse(remote.substring(plusIdx + 1));
      remote = remote.substring(0, plusIdx);
    }

    var local = localVersion.trim();
    if (local.startsWith('v') || local.startsWith('V')) {
      local = local.substring(1);
    }
    final localPlusIdx = local.indexOf('+');
    if (localPlusIdx != -1) {
      local = local.substring(0, localPlusIdx);
    }

    final localParts = _parseSemVer(local);
    final remoteParts = _parseSemVer(remote);

    for (var i = 0; i < 3; i++) {
      if (remoteParts[i] > localParts[i]) return true;
      if (remoteParts[i] < localParts[i]) return false;
    }

    // Version numbers are equal — compare build numbers if remote has one
    if (remoteBuildNumber != null && remoteBuildNumber > localBuildNumber) {
      return true;
    }

    return false;
  }

  static List<int> _parseSemVer(String ver) {
    final parts = ver.split('.');
    final major = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 0) : 0;
    final minor = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final patch = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;
    return [major, minor, patch];
  }

  /// Start OTA APK download & installation stream.
  Stream<OtaEvent> startOtaDownload(String downloadUrl) {
    return OtaUpdate().execute(
      downloadUrl,
      destinationFilename: 'aikanshu_update.apk',
    );
  }

  /// Open external browser / GitHub release page.
  Future<bool> openInBrowser(String url) async {
    try {
      final uri = Uri.parse(url);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      AppLog.e('Update', 'openInBrowser failed url=$url', error: e);
      return false;
    }
  }

  /// Check update with UI feedback (dialog / toast).
  Future<void> checkUpdate(
    BuildContext context, {
    bool showToastIfLatest = true,
    bool background = false,
  }) async {
    CancelFunc? cancelLoading;
    if (!background) {
      cancelLoading = BotToast.showLoading();
    }

    try {
      final packageInfo = await getPackageInfo();
      final release = await fetchLatestRelease();

      cancelLoading?.call();

      if (release == null) {
        if (!background) {
          BotToast.showText(text: '检查更新失败，请检查网络或稍后重试');
        }
        return;
      }

      final localVer = packageInfo.version;
      final localBuild = int.tryParse(packageInfo.buildNumber) ?? 1;

      final hasUpdate = isNewerVersion(
        localVersion: localVer,
        localBuildNumber: localBuild,
        remoteTag: release.tagName,
      );

      if (hasUpdate) {
        if (context.mounted) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (dialogCtx) => AppUpdateDialog(
              release: release,
              currentVersion: '$localVer+$localBuild',
            ),
          );
        }
      } else {
        if (showToastIfLatest && !background) {
          BotToast.showText(text: '当前已是最新版本 (v$localVer)');
        }
      }
    } catch (e, st) {
      cancelLoading?.call();
      AppLog.e('Update', 'checkUpdate error', error: e, stackTrace: st);
      if (!background) {
        BotToast.showText(text: '检查更新异常，请前往 GitHub 查看最新版本');
      }
    }
  }
}
