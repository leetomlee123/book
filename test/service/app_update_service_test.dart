import 'package:book/entity/app_release.dart';
import 'package:book/service/app_update_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppRelease Model', () {
    test('fromJson parses release fields and selects arm64 APK asset', () {
      final json = {
        'tag_name': 'v1.2.3+45',
        'name': '爱看书 1.2.3 正式版',
        'body': '1. 新增功能\n2. 修复已知问题',
        'html_url': 'https://github.com/leetomlee123/book/releases/tag/v1.2.3+45',
        'published_at': '2026-08-31T08:00:00Z',
        'prerelease': false,
        'assets': [
          {
            'name': 'aikanshu-1.2.3+45-all.apk',
            'browser_download_url':
                'https://github.com/leetomlee123/book/releases/download/v1.2.3+45/aikanshu-1.2.3+45-all.apk',
            'size': 25000000,
          },
          {
            'name': 'aikanshu-1.2.3+45-arm64-v8a.apk',
            'browser_download_url':
                'https://github.com/leetomlee123/book/releases/download/v1.2.3+45/aikanshu-1.2.3+45-arm64-v8a.apk',
            'size': 18000000,
          },
        ],
      };

      final release = AppRelease.fromJson(json);

      expect(release.tagName, 'v1.2.3+45');
      expect(release.versionName, '1.2.3');
      expect(release.buildNumber, 45);
      expect(release.title, '爱看书 1.2.3 正式版');
      expect(release.changelog, contains('1. 新增功能'));
      expect(
        release.downloadUrl,
        'https://github.com/leetomlee123/book/releases/download/v1.2.3+45/aikanshu-1.2.3+45-arm64-v8a.apk',
      );
      expect(release.apkSize, 18000000);
      expect(release.publishedAt?.year, 2026);
    });

    test('fromJson falls back to htmlUrl when assets list is empty', () {
      final json = {
        'tag_name': 'v2.0.0',
        'html_url': 'https://github.com/leetomlee123/book/releases/tag/v2.0.0',
        'assets': [],
      };

      final release = AppRelease.fromJson(json);
      expect(release.downloadUrl,
          'https://github.com/leetomlee123/book/releases/tag/v2.0.0');
    });
  });

  group('AppUpdateService.isNewerVersion', () {
    test('standard major/minor/patch comparison', () {
      expect(
        AppUpdateService.isNewerVersion(
          localVersion: '1.0.0',
          localBuildNumber: 1,
          remoteTag: 'v1.0.1',
        ),
        isTrue,
      );

      expect(
        AppUpdateService.isNewerVersion(
          localVersion: '1.0.0',
          localBuildNumber: 1,
          remoteTag: 'v1.1.0',
        ),
        isTrue,
      );

      expect(
        AppUpdateService.isNewerVersion(
          localVersion: '1.0.0',
          localBuildNumber: 1,
          remoteTag: 'v2.0.0',
        ),
        isTrue,
      );

      expect(
        AppUpdateService.isNewerVersion(
          localVersion: '1.2.0',
          localBuildNumber: 1,
          remoteTag: 'v1.1.9',
        ),
        isFalse,
      );

      expect(
        AppUpdateService.isNewerVersion(
          localVersion: '1.0.0',
          localBuildNumber: 1,
          remoteTag: 'v1.0.0',
        ),
        isFalse,
      );
    });

    test('build number comparison when version string is identical', () {
      expect(
        AppUpdateService.isNewerVersion(
          localVersion: '1.0.0',
          localBuildNumber: 1,
          remoteTag: 'v1.0.0+2',
        ),
        isTrue,
      );

      expect(
        AppUpdateService.isNewerVersion(
          localVersion: '1.0.0',
          localBuildNumber: 3,
          remoteTag: 'v1.0.0+2',
        ),
        isFalse,
      );

      expect(
        AppUpdateService.isNewerVersion(
          localVersion: '1.0.0+1',
          localBuildNumber: 1,
          remoteTag: 'v1.0.0+1',
        ),
        isFalse,
      );
    });
  });
}
