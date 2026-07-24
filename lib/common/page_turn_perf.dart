import 'package:flutter/foundation.dart';

/// Unified page-turn performance probe.
///
/// Filter logcat / console with: **`PageTurnPerf`**
///
/// Covers cover / simulation / static animation draws, picture cache
/// hit/miss, commit, warm, and manager lifecycle so rapid-tap jank can
/// be attributed without grepping multiple prefixes.
///
/// Enabled in **debug and profile** builds only (never release).
class PageTurnPerf {
  PageTurnPerf._();

  static const String prefix = 'PageTurnPerf';

  /// Hard switch — false disables every probe immediately.
  static bool enabled = !kReleaseMode;

  /// Log every cache hit (noisy at 60fps — off by default).
  static bool verboseHits = false;

  /// Only emit sampled frame draws slower than this (µs).
  static const int slowDrawUs = 800;

  /// Sample every Nth draw frame when under [slowDrawUs].
  static const int drawSampleEvery = 12;

  /// Always log picture record slower than this (ms).
  static const int slowPaintMs = 4;

  static int _seq = 0;
  static int _drawSample = 0;

  /// Monotonic-ish turn id for correlating start → commit → warm.
  static int nextTurnId() => ++_seq;

  static void log(String event, [String detail = '']) {
    if (!enabled) return;
    if (detail.isEmpty) {
      debugPrint('[$prefix] $event');
    } else {
      debugPrint('[$prefix] $event $detail');
    }
  }

  /// Log only when [ms] / [us] looks expensive.
  static void logSlow(
    String event, {
    int? ms,
    int? us,
    String detail = '',
    int slowMs = slowPaintMs,
    int slowUs = slowDrawUs,
  }) {
    if (!enabled) return;
    final expensive = (ms != null && ms >= slowMs) ||
        (us != null && us >= slowUs);
    if (!expensive) return;
    final timing = ms != null
        ? 'ms=$ms'
        : us != null
            ? 'us=$us'
            : '';
    log(event, [timing, detail].where((s) => s.isNotEmpty).join(' '));
  }

  /// Time a sync block; always logs if [always], else only when slow.
  static T timeSync<T>(
    String event,
    T Function() body, {
    String detail = '',
    bool always = false,
    int slowMs = slowPaintMs,
  }) {
    if (!enabled) return body();
    final sw = Stopwatch()..start();
    try {
      return body();
    } finally {
      sw.stop();
      final ms = sw.elapsedMilliseconds;
      final us = sw.elapsedMicroseconds;
      if (always || ms >= slowMs || us >= slowDrawUs) {
        final timing = ms > 0 ? 'ms=$ms' : 'us=$us';
        log(event, [timing, detail].where((s) => s.isNotEmpty).join(' '));
      }
    }
  }

  /// Sampled frame draw timing (cover / sim / static).
  ///
  /// Always logs when slower than [slowDrawUs]; otherwise every
  /// [drawSampleEvery] frames so continuous drag stays readable.
  static void frameDraw(
    String mode, {
    required int us,
    required bool animating,
    required bool dragging,
    String extra = '',
  }) {
    if (!enabled) return;
    final n = ++_drawSample;
    final slow = us >= slowDrawUs;
    if (!slow && (n % drawSampleEvery) != 0) return;
    final tag = slow ? 'draw.$mode.SLOW' : 'draw.$mode';
    log(
      tag,
      'us=$us anim=$animating drag=$dragging'
      '${extra.isEmpty ? '' : ' $extra'}',
    );
  }

  static String modeName(int type) {
    switch (type) {
      case 0:
        return 'static';
      case 1:
        return 'simulation';
      case 2:
        return 'cover';
      case 3:
        return 'scroll';
      default:
        return 'mode$type';
    }
  }
}
