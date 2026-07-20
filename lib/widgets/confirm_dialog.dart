import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  final Function sureFunction;
  final Function cancelFunction;
  final String _confirmContent;
  const ConfirmDialog(this._confirmContent, this.sureFunction, this.cancelFunction, {super.key});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Text(_confirmContent),
      actions: <Widget>[
        TextButton(onPressed: () => sureFunction(), child: Text('确定')),
        TextButton(onPressed: () => cancelFunction(), child: Text('取消')),
      ],
    );
  }
}
