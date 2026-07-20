import 'dart:convert';

import 'package:book/common/local_store.dart';

/// Pure-local account store (no network).
///
/// Stores profiles in SpUtil. Password is a salted local digest (not for
/// high-security scenarios — offline convenience only).
class LocalAccount {
  static const _usersKey = 'local_users_v1';
  static const authKey = 'auth';
  static const usernameKey = 'username';
  static const emailKey = 'email';

  /// Register a new local user. Returns error message or null on success.
  static String? register({
    required String name,
    required String password,
    required String email,
  }) {
    final n = name.trim();
    final p = password;
    final e = email.trim();
    if (n.isEmpty || p.isEmpty) return '账号和密码不能为空';
    if (p.length < 4) return '密码至少 4 位';
    if (e.isNotEmpty && !e.contains('@')) return '邮箱格式不正确';
    final users = _loadUsers();
    if (users.any((u) => u['name'] == n)) return '账号已存在';
    final salt = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    users.add({
      'name': n,
      'email': e,
      'salt': salt,
      'hash': _hash(p, salt),
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    _saveUsers(users);
    return null;
  }

  /// Login. Returns error message or null on success (writes SpUtil session).
  static String? login({required String name, required String password}) {
    final n = name.trim();
    if (n.isEmpty || password.isEmpty) return '请输入账号和密码';
    final users = _loadUsers();
    Map<String, dynamic>? found;
    for (final u in users) {
      if (u['name'] == n) {
        found = u;
        break;
      }
    }
    if (found == null) return '账号不存在，请先注册';
    final salt = found['salt']?.toString() ?? '';
    final hash = found['hash']?.toString() ?? '';
    if (_hash(password, salt) != hash) return '密码错误';
    SpUtil.putString(usernameKey, n);
    SpUtil.putString(emailKey, found['email']?.toString() ?? '');
    SpUtil.putString(
        authKey, 'local:$n:${DateTime.now().millisecondsSinceEpoch}');
    return null;
  }

  /// Change password by name + email (local recovery).
  static String? resetPassword({
    required String name,
    required String email,
    required String newPassword,
  }) {
    final n = name.trim();
    final e = email.trim();
    if (n.isEmpty || e.isEmpty || newPassword.isEmpty) {
      return '请填写完整信息';
    }
    if (newPassword.length < 4) return '密码至少 4 位';
    final users = _loadUsers();
    for (var i = 0; i < users.length; i++) {
      final u = users[i];
      if (u['name'] == n && (u['email']?.toString() ?? '') == e) {
        final salt = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
        users[i] = {
          ...u,
          'salt': salt,
          'hash': _hash(newPassword, salt),
        };
        _saveUsers(users);
        return null;
      }
    }
    return '账号与邮箱不匹配';
  }

  static void logout() {
    SpUtil.remove(authKey);
    SpUtil.remove(usernameKey);
    SpUtil.remove(emailKey);
  }

  static bool get isLoggedIn =>
      SpUtil.haveKey(authKey) && SpUtil.getString(usernameKey).isNotEmpty;

  static String get username => SpUtil.getString(usernameKey);
  static String get email => SpUtil.getString(emailKey);

  static List<Map<String, dynamic>> _loadUsers() {
    final raw = SpUtil.getString(_usersKey);
    if (raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw);
      if (list is List) {
        return list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static void _saveUsers(List<Map<String, dynamic>> users) {
    SpUtil.putString(_usersKey, jsonEncode(users));
  }

  static String _hash(String password, String salt) {
    final input = utf8.encode('$salt::$password::book_local');
    var h1 = 0xcbf29ce484222325;
    const p = 0x100000001b3;
    for (final b in input) {
      h1 ^= b;
      h1 = (h1 * p) & 0xFFFFFFFFFFFFFFFF;
    }
    var h2 = 0xcbf29ce484222325;
    for (final b in input.reversed) {
      h2 ^= b;
      h2 = (h2 * p) & 0xFFFFFFFFFFFFFFFF;
    }
    return '${h1.toRadixString(16).padLeft(16, '0')}${h2.toRadixString(16).padLeft(16, '0')}';
  }
}
