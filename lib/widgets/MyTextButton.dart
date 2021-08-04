import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';

class MyTextButton extends StatelessWidget {
  final Function call;
  final Widget child;
  final Size size;
  const MyTextButton({Key key, this.call, this.child, this.size}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
        style: ButtonStyle(
            fixedSize: MaterialStateProperty.all(size),
            backgroundColor: MaterialStateProperty.resolveWith(
              (states) {
                return SpUtil.getBool("dark")
                    ? Colors.white10
                    : Colors.grey.shade50;
              },
            ),
            alignment: Alignment.centerLeft),
        clipBehavior: Clip.hardEdge,
        onPressed: () => call,
        child: child);
  }
}
