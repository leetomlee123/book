import 'package:book/store/Store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TextTwo extends ConsumerWidget {
  final String text;
  final int? maxLines;
  final double? fontSize;

  TextTwo(this.text, {this.maxLines, this.fontSize});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(colorModelProvider);
    return Text(
      text,
      maxLines: maxLines,
      style: TextStyle(
        color: model.dark ? Colors.white : Color(0x9A000000),
        fontSize: fontSize,
      ),
    );
  }
}
