import 'package:book/common/local_account.dart';
import 'package:book/route/Routes.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

class Register extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _RegisterState();
  }
}

class _RegisterState extends State<Register> {
  String name = '';
  String pwd = '';
  String email = '';
  String repassword = '';

  String? checkEmail(String v) {
    if (v.isEmpty) return null;
    return v.contains('@') ? null : '邮箱格式不正确';
  }

  void _submit() {
    FocusScope.of(context).requestFocus(FocusNode());
    if (pwd != repassword) {
      BotToast.showText(text: '两次密码不一致');
      return;
    }
    final err =
        LocalAccount.register(name: name, password: pwd, email: email);
    if (err != null) {
      BotToast.showText(text: err);
      return;
    }
    // auto login
    LocalAccount.login(name: name, password: pwd);
    BotToast.showText(text: '注册成功');
    Navigator.of(context).popUntil(ModalRoute.withName('/'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("注册"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Center(
          child: Column(
            children: <Widget>[
              Text(
                '本地注册，数据仅保存在本机',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              SizedBox(height: 12),
              TextFormField(
                keyboardType: TextInputType.text,
                autofocus: false,
                decoration: InputDecoration(
                    hintText: '账号',
                    contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                    prefixIcon: Icon(Icons.person)),
                onChanged: (String value) {
                  this.name = value;
                },
              ),
              SizedBox(height: 8.0),
              TextFormField(
                autofocus: false,
                obscureText: true,
                decoration: InputDecoration(
                    hintText: '密码',
                    contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                    prefixIcon: Icon(Icons.lock)),
                onChanged: (String value) {
                  pwd = value;
                },
              ),
              SizedBox(height: 8.0),
              TextFormField(
                autofocus: false,
                obscureText: true,
                decoration: InputDecoration(
                    hintText: '重复密码',
                    contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                    prefixIcon: Icon(Icons.repeat)),
                onChanged: (String value) {
                  repassword = value;
                },
              ),
              SizedBox(height: 8.0),
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                autofocus: false,
                decoration: InputDecoration(
                    hintText: '邮箱（本地找回密码用，可选）',
                    contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                    prefixIcon: Icon(Icons.email)),
                onChanged: (String value) {
                  email = value;
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: Text('注册'),
              ),
              TextButton(
                onPressed: () {
                  Routes.navigateTo(context, Routes.login, replace: true);
                },
                child: Text('已有账号？去登录'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
