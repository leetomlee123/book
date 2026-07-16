import 'dart:collection';

import 'package:flutter/foundation.dart';

/// Lightweight app logger: levels + tags + in-memory ring buffer.
///
/// - Console: [debugPrint] in debug/profile; silent in release unless [enabledInRelease].
/// - Buffer: last [maxEntries] lines, viewable via [AppLog.entries] / log viewer UI.
///
/// Usage:
/// ```dart
/// AppLog.i('Read', 'open book ${book.Id}');
/// AppLog.e('Source', 'toc failed', error: e, stackTrace: st);
/// ```
class AppLog {
  AppLog._();

  /// Keep recent logs for in-app viewer / copy.
  static int maxEntries = 500;

  /// Also emit to console in release builds (default off).
  static bool enabledInRelease = false;

  static final ListQueue<_LogEntry> _buffer = ListQueue<_LogEntry>();
  static final List<void Function(_LogEntry)> _listeners = [];

  static bool get _consoleEnabled =>
      !kReleaseMode || enabledInRelease;

  // ---- public API ----------------------------------------------------------

  static void d(String tag, String msg) =>
      _log(LogLevel.debug, tag, msg);

  static void i(String tag, String msg) =>
      _log(LogLevel.info, tag, msg);

  static void w(String tag, String msg, {Object? error}) =>
      _log(LogLevel.warn, tag, msg, error: error);

  static void e(
    String tag,
    String msg, {
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _log(LogLevel.error, tag, msg, error: error, stackTrace: stackTrace);

  /// Snapshot of buffered entries (oldest first).
  static List<String> get entries =>
      _buffer.map((e) => e.format()).toList(growable: false);

  static String dump() => entries.join('\n');

  static void clear() {
    _buffer.clear();
  }

  /// Subscribe to new log lines (e.g. live log viewer). Returns unsubscribe.
  static VoidCallback addListener(void Function(String line) onLine) {
    void wrap(_LogEntry e) => onLine(e.format());
    _listeners.add(wrap);
    return () => _listeners.remove(wrap);
  }

  // ---- internals -----------------------------------------------------------

  static void _log(
    LogLevel level,
    String tag,
    String msg, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final entry = _LogEntry(
      time: DateTime.now(),
      level: level,
      tag: tag,
      message: msg,
      error: error?.toString(),
      stackTrace: stackTrace?.toString(),
    );

    _buffer.addLast(entry);
    while (_buffer.length > maxEntries) {
      _buffer.removeFirst();
    }

    for (final l in List<void Function(_LogEntry)>.from(_listeners)) {
      try {
        l(entry);
      } catch (_) {}
    }

    if (!_consoleEnabled) return;

    final line = entry.format();
    // debugPrint throttles long lines; fine for normal logs.
    debugPrint(line);
    if (error != null) {
      debugPrint('  error: $error');
    }
    if (stackTrace != null && level == LogLevel.error) {
      debugPrint('$stackTrace');
    }
  }
}

enum LogLevel { debug, info, warn, error }

extension LogLevelX on LogLevel {
  String get label {
    switch (this) {
      case LogLevel.debug:
        return 'D';
      case LogLevel.info:
        return 'I';
      case LogLevel.warn:
        return 'W';
      case LogLevel.error:
        return 'E';
    }
  }
}

class _LogEntry {
  final DateTime time;
  final LogLevel level;
  final String tag;
  final String message;
  final String? error;
  final String? stackTrace;

  _LogEntry({
    required this.time,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
  });

  String format() {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    final ms = time.millisecond.toString().padLeft(3, '0');
    final err = (error == null || error!.isEmpty) ? '' : ' | $error';
    return '$h:$m:$s.$ms ${level.label}/$tag: $message$err';
  }
}
