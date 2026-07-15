import 'package:book/common/local_account.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

class ForgetPass extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ForgetPassState();
  }
}

class _ForgetPassState extends State<ForgetPass> {
  String name = '';
  String email = '';
  String password = '';
  String repassword = '';

  void _submit() {
    FocusScope.of(context).requestFocus(FocusNode());
    if (password != repassword) {
      BotToast.showText(text: '两次密码不一致');
      return;
    }
    final err = LocalAccount.resetPassword(
      name: name,
      email: email,
      newPassword: password,
    );
    if (err != null) {
      BotToast.showText(text: err);
      return;
    }
    BotToast.showText(text: '密码已重置，请登录');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("重置密码"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Column(
          children: <Widget>[
            Text(
              '通过注册时填写的邮箱在本机重置密码',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 12),
            TextFormField(
              autofocus: false,
              decoration: InputDecoration(
                  hintText: '账号',
                  contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                  prefixIcon: Icon(Icons.person)),
              onChanged: (v) => name = v,
            ),
            SizedBox(height: 8.0),
            TextFormField(
              keyboardType: TextInputType.emailAddress,
              autofocus: false,
              decoration: InputDecoration(
                  hintText: '注册邮箱',
                  contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                  prefixIcon: Icon(Icons.email)),
              onChanged: (v) => email = v,
            ),
            SizedBox(height: 8.0),
            TextFormField(
              obscureText: true,
              autofocus: false,
              decoration: InputDecoration(
                  hintText: '新密码',
                  contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                  prefixIcon: Icon(Icons.lock)),
              onChanged: (v) => password = v,
            ),
            SizedBox(height: 8.0),
            TextFormField(
              obscureText: true,
              autofocus: false,
              decoration: InputDecoration(
                  hintText: '重复新密码',
                  contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                  prefixIcon: Icon(Icons.repeat)),
              onChanged: (v) => repassword = v,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              child: Text('重置密码'),
            ),
          ],
        ),
      ),
    );
  }
}
