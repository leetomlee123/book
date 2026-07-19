import 'package:book/common/app_log.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Firebase Analytics + Crashlytics bootstrap for Android.
///
/// Safe on hosts without Google Play services / missing config: init failures
/// are logged and the rest of the app continues.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool _ready = false;

  static bool get isReady => _ready;

  static FirebaseAnalytics? _analytics;

  static FirebaseAnalytics? get analytics => _ready ? _analytics : null;

  /// Navigator observer for automatic screen_view reporting (Fluro routes).
  static List<NavigatorObserver> get navigatorObservers {
    final a = analytics;
    if (a == null) return const [];
    return [FirebaseAnalyticsObserver(analytics: a)];
  }

  /// Initialize Firebase and enable Crashlytics collection.
  /// Call once after [WidgetsFlutterBinding.ensureInitialized].
  static Future<void> init() async {
    if (_ready) return;
    try {
      await Firebase.initializeApp();
      _analytics = FirebaseAnalytics.instance;

      // Keep Crashlytics quiet in debug/profile so local dev isn't noisy.
      final collect = kReleaseMode;
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(collect);

      // Non-fatal Flutter framework errors.
      final prevFlutter = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (collect) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(details);
        }
        if (prevFlutter != null) {
          prevFlutter(details);
        } else {
          FlutterError.presentError(details);
        }
      };

      // Uncaught async / isolate errors.
      final prevPlatform = PlatformDispatcher.instance.onError;
      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        if (collect) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        }
        if (prevPlatform != null) return prevPlatform(error, stack);
        return false;
      };

      _ready = true;
      AppLog.i('Firebase', 'initialized collect=$collect');
      await logEvent('app_open');
    } catch (e, st) {
      // Missing google-services / no Play services / unsupported platform.
      AppLog.w('Firebase', 'init failed — analytics/crashlytics disabled',
          error: e);
      assert(() {
        debugPrint('Firebase init failed: $e\n$st');
        return true;
      }());
      _ready = false;
    }
  }

  /// Custom event (no-op if Firebase is not ready).
  static Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    final a = analytics;
    if (a == null) return;
    try {
      await a.logEvent(name: name, parameters: parameters);
    } catch (e) {
      AppLog.w('Firebase', 'logEvent($name) failed', error: e);
    }
  }

  /// Non-fatal exception for Crashlytics (also buffers via [AppLog.e]).
  static Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    AppLog.e('Firebase', reason ?? 'recordError',
        error: error, stackTrace: stack);
    if (!_ready || !kReleaseMode) return;
    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        reason: reason,
        fatal: fatal,
      );
    } catch (_) {}
  }

  static Future<void> setUserId(String? id) async {
    if (!_ready) return;
    try {
      await _analytics?.setUserId(id: id);
      await FirebaseCrashlytics.instance.setUserIdentifier(id ?? '');
    } catch (_) {}
  }
}
