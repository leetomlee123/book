import 'package:book/common/local_store.dart';
import 'package:flutter/material.dart';

class MyTextButton extends StatelessWidget {
  final Function? call;
  final Widget child;
  final Size? size;
  const MyTextButton(
      {super.key, this.call, required this.child, this.size});

  @override
  Widget build(BuildContext context) {
    return TextButton(
        style: ButtonStyle(
            fixedSize: size == null ? null : WidgetStateProperty.all(size),
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) {
                return SpUtil.getBool("dark")
                    ? Colors.white10
                    : Colors.grey.shade50;
              },
            ),
            alignment: Alignment.centerLeft),
        clipBehavior: Clip.hardEdge,
        onPressed: () => call?.call(),
        child: child);
  }
}
