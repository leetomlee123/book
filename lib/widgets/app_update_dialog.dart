import 'dart:async';

import 'package:book/common/app_colors.dart';
import 'package:book/entity/app_release.dart';
import 'package:book/service/app_update_service.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';

/// Material 3 update dialog displaying release notes, download progress and action buttons.
class AppUpdateDialog extends StatefulWidget {
  final AppRelease release;
  final String currentVersion;

  const AppUpdateDialog({
    super.key,
    required this.release,
    required this.currentVersion,
  });

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  bool _isDownloading = false;
  int _downloadProgress = 0;
  String _statusText = '准备下载…';
  StreamSubscription<OtaEvent>? _otaSubscription;

  @override
  void dispose() {
    _otaSubscription?.cancel();
    super.dispose();
  }

  void _startOtaDownload() {
    final apkUrl = widget.release.downloadUrl;
    if (!apkUrl.toLowerCase().endsWith('.apk')) {
      // Direct asset not an APK — fallback to browser
      AppUpdateService.instance.openInBrowser(apkUrl);
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
      _statusText = '正在下载更新包 (0%)…';
    });

    try {
      _otaSubscription = AppUpdateService.instance
          .startOtaDownload(apkUrl)
          .listen((OtaEvent event) {
        switch (event.status) {
          case OtaStatus.DOWNLOADING:
            final p = int.tryParse(event.value ?? '0') ?? _downloadProgress;
            if (mounted) {
              setState(() {
                _downloadProgress = p;
                _statusText = '正在下载更新包 ($p%)…';
              });
            }
            break;
          case OtaStatus.INSTALLING:
            if (mounted) {
              setState(() {
                _downloadProgress = 100;
                _statusText = '下载完成，正在打开安装程序…';
              });
            }
            break;
          case OtaStatus.ALREADY_RUNNING_ERROR:
          case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
          case OtaStatus.INTERNAL_ERROR:
          case OtaStatus.DOWNLOAD_ERROR:
          case OtaStatus.CHECKSUM_ERROR:
            BotToast.showText(text: '应用内下载受限，已为您打开浏览器下载');
            AppUpdateService.instance.openInBrowser(apkUrl);
            if (mounted) {
              Navigator.of(context).pop();
            }
            break;
          default:
            break;
        }
      }, onError: (dynamic error) {
        BotToast.showText(text: '下载失败，正在切换浏览器下载');
        AppUpdateService.instance.openInBrowser(apkUrl);
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } catch (e) {
      BotToast.showText(text: '启动更新失败，正在切换浏览器下载');
      AppUpdateService.instance.openInBrowser(apkUrl);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = AppColors.brand;
    final surfaceColor = isDark ? const Color(0xFF242424) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2329);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF646A73);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: surfaceColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Icon + Title + Version Tag
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.rocket_launch_rounded,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '发现新版本',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.currentVersion} → ${widget.release.tagName}',
                        style: TextStyle(
                          fontSize: 13,
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Release Notes / Changelog
            Text(
              '更新日志：',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Text(
                  widget.release.changelog.isNotEmpty
                      ? widget.release.changelog
                      : '本次更新包含性能提升与体验优化。',
                  style: TextStyle(
                    fontSize: 13,
                    color: subTextColor,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Progress bar or action buttons
            if (_isDownloading) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _downloadProgress / 100.0,
                      backgroundColor: primaryColor.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _statusText,
                        style: TextStyle(fontSize: 12, color: subTextColor),
                      ),
                      Text(
                        '$_downloadProgress%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(
                          color: isDark
                              ? Colors.white24
                              : const Color(0xFFD0D3D6),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        '稍后再说',
                        style: TextStyle(color: subTextColor, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _startOtaDownload,
                      child: const Text(
                        '立即更新',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
