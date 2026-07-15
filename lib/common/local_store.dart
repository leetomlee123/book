import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drop-in replacements for the flustars APIs used by this project.
class SpUtil {
  static SharedPreferences? _prefs;

  static Future<SpUtil> getInstance() async {
    _prefs ??= await SharedPreferences.getInstance();
    return SpUtil();
  }

  static SharedPreferences get _p {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError('SpUtil.getInstance() must be called before use');
    }
    return prefs;
  }

  static bool haveKey(String key) => _p.containsKey(key);

  static bool containsKey(String key) => _p.containsKey(key);

  static Set<String> getKeys() => _p.getKeys();

  static Future<bool> remove(String key) => _p.remove(key);

  static bool getBool(String key, {bool defValue = false}) =>
      _p.getBool(key) ?? defValue;

  static Future<bool> putBool(String key, bool value) => _p.setBool(key, value);

  static int getInt(String key, {int defValue = 0}) =>
      _p.getInt(key) ?? defValue;

  static Future<bool> putInt(String key, int value) => _p.setInt(key, value);

  static double getDouble(String key, {double defValue = 0.0}) =>
      _p.getDouble(key) ?? defValue;

  static Future<bool> putDouble(String key, double value) =>
      _p.setDouble(key, value);

  static String getString(String key, {String defValue = ''}) =>
      _p.getString(key) ?? defValue;

  static Future<bool> putString(String key, String value) =>
      _p.setString(key, value);

  static List<String> getStringList(String key,
          {List<String>? defValue}) =>
      _p.getStringList(key) ?? defValue ?? <String>[];

  static Future<bool> putStringList(String key, List<String> value) =>
      _p.setStringList(key, value);

  static Future<bool> putObject(String key, Object? value) {
    if (value == null) return _p.remove(key);
    return _p.setString(key, jsonEncode(value));
  }

  static Map<String, dynamic>? getObject(String key) {
    final raw = _p.getString(key);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return null;
  }

  /// flustars-compatible: invokes [f] with the decoded map when present.
  static T? getObj<T>(String key, T Function(Map v) f) {
    final obj = getObject(key);
    if (obj == null) return null;
    return f(obj);
  }

  static Future<bool> putObjectList(String key, List<dynamic>? list) {
    if (list == null) return _p.remove(key);
    final encoded = list.map((e) {
      if (e is Map || e is List || e is String || e is num || e is bool) {
        return e;
      }
      // Prefer toJson() when available on entity objects.
      try {
        // ignore: avoid_dynamic_calls
        return (e as dynamic).toJson();
      } catch (_) {
        return e;
      }
    }).toList();
    return _p.setString(key, jsonEncode(encoded));
  }

  static List<Map<String, dynamic>>? getObjectList(String key) {
    final raw = _p.getString(key);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! List) return null;
    return decoded.map((e) {
      if (e is Map<String, dynamic>) return e;
      if (e is Map) return Map<String, dynamic>.from(e);
      return <String, dynamic>{};
    }).toList();
  }
}

class DirectoryUtil {
  static Future<DirectoryUtil> getInstance() async {
    // Warm path_provider; callers historically only awaited init.
    await getApplicationDocumentsDirectory();
    return DirectoryUtil();
  }
}

class DateFormats {
  static const String full = 'yyyy-MM-dd HH:mm:ss';
  static const String y_mo_d = 'yyyy-MM-dd';
  static const String h_m = 'HH:mm';
}

class DateUtil {
  static int getNowDateMs() => DateTime.now().millisecondsSinceEpoch;

  static String getNowDateStr() =>
      formatDate(DateTime.now(), format: DateFormats.full);

  static String formatDate(DateTime date, {String? format}) {
    return DateFormat(format ?? DateFormats.full).format(date);
  }
}

class NumUtil {
  static num multiply(num a, num b) => a * b;

  static num? getNumByValueDouble(double? value, int fractionDigits) {
    if (value == null) return null;
    return num.parse(value.toStringAsFixed(fractionDigits));
  }
}
