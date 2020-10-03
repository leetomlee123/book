import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  Function sureFunction;
  Function cancelFunction;
  String _confirmContent;
  ConfirmDialog(this._confirmContent, this.sureFunction, this.cancelFunction);
  @override
  Widget build(BuildContext context) {
    
    return AlertDialog(
      content: Text(_confirmContent),
      actions: <Widget>[
        FlatButton(onPressed: sureFunction, child: Text('确定')),
        FlatButton(onPressed: cancelFunction, child: Text('取消')),
      ],
    );
  }
}
