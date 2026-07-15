import 'dart:convert';
import 'dart:typed_data';

import 'package:fast_gbk/fast_gbk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gbk roundtrip decode', () {
    // "你好" in GBK
    final bytes = gbk.encode('你好世界');
    final text = gbk.decode(bytes);
    expect(text, '你好世界');
  });

  test('utf8 still works via standard codec', () {
    final bytes = utf8.encode('hello');
    expect(utf8.decode(bytes), 'hello');
  });
}
