import 'package:extended_image/extended_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PicWidget extends StatelessWidget {
  final String url;
  final double height;
  final double width;
  final BoxFit fit;
  final bool roll;
  final double radius;

  const PicWidget(
    this.url, {super.key, 
    this.height = 115,
    this.width = 97,
    this.fit = BoxFit.cover,
    this.roll = false,
    this.radius = 0,
  });

  Widget get _placeholder => Image.asset(
        'images/nocover.jpg',
        width: width,
        height: height,
        fit: BoxFit.cover,
      );

  /// Normalize cover URLs: trim, protocol-relative, common placeholders → empty.
  static String normalizeUrl(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return '';
    if (s.startsWith('//')) s = 'https:$s';
    // HTML-escaped ampersands
    s = s.replaceAll('&amp;', '&');
    final lower = s.toLowerCase();
    if (lower.contains('loading.jpg') ||
        lower.contains('loading.png') ||
        lower.contains('placeholder') ||
        lower.contains('default_cover') ||
        lower.endsWith('/nocover.jpg') ||
        lower.endsWith('/nopic.gif')) {
      return '';
    }
    if (!(s.startsWith('http://') || s.startsWith('https://'))) {
      return '';
    }
    return s;
  }

  Map<String, String> _headersFor(String src) {
    final host = Uri.tryParse(src)?.host ?? '';
    // Many novel CDNs check UA / Accept; some want a same-site referer.
    final referer = host.isEmpty
        ? 'https://www.google.com/'
        : 'https://$host/';
    return {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
      'Referer': referer,
    };
  }

  /// True when [error] is a benign cover download/decode failure.
  static bool isBenignCoverError(Object? error) {
    if (error == null) return false;
    final s = error.toString();
    return s.contains('Failed to load') ||
        s.contains('Invalid image data') ||
        s.contains('ImageDecoder') ||
        s.contains('unimplemented') ||
        s.contains('HttpException') ||
        s.contains('SocketException') ||
        s.contains('HandshakeException') ||
        s.contains('ClientException') ||
        s.contains('NetworkImageLoadException');
  }

  @override
  Widget build(BuildContext context) {
    final src = normalizeUrl(url);
    Widget child;
    if (src.isEmpty) {
      child = _placeholder;
    } else {
      final cacheW =
          (width * MediaQuery.devicePixelRatioOf(context)).round();
      child = ExtendedImage.network(
        src,
        width: width,
        height: height,
        fit: fit,
        cache: true,
        // Cover CDNs often return broken/unsupported WebP — don't spam console.
        printError: false,
        clearMemoryCacheWhenDispose: false,
        clearMemoryCacheIfFailed: true,
        retries: 1,
        timeRetry: const Duration(milliseconds: 500),
        headers: _headersFor(src),
        cacheWidth: cacheW > 0 ? cacheW : null,
        loadStateChanged: (state) {
          switch (state.extendedImageLoadState) {
            case LoadState.loading:
              return _placeholder;
            case LoadState.failed:
              // Quiet failure: keep placeholder; optional one-line debug only.
              assert(() {
                final err = state.lastException;
                if (err != null && kDebugMode) {
                  final first = err.toString().split('\n').first;
                  debugPrint('[Cover] fail $src → $first');
                }
                return true;
              }());
              return _placeholder;
            case LoadState.completed:
              return null; // use default decoded image
          }
        },
      );
    }

    if (radius > 0) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      );
    }
    return SizedBox(width: width, height: height, child: child);
  }
}
