import 'package:book/common/common.dart';
import 'package:book/common/net.dart';
import 'package:book/route/Routes.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ForgetPass extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new _ForgetPassState();
  }
}

class _ForgetPassState extends State<ForgetPass> {
  String account;
  String newpwd;
  String email;
  String repetpwd;
  var _scaffoldkey = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.only(left: 24.0, right: 24.0),
            children: <Widget>[
              TextFormField(
                keyboardType: TextInputType.phone,
                autofocus: false,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '账号',
                  hintStyle: TextStyle(color: Colors.white),
                  contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
//                border: OutlineInputBorder(
//                    borderRadius: BorderRadius.circular(32.0)),
                ),
                onChanged: (String value) {
                  this.account = value;
                },
              ),
              SizedBox(height: 8.0),
              TextFormField(
                autofocus: false,
                style: TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: '邮箱',
                  hintStyle: TextStyle(color: Colors.white),
                  contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
//                border: OutlineInputBorder(
//                    borderRadius: BorderRadius.circular(32.0)),
                ),
                onChanged: (String value) {
                  email = value;
                },
              ),
              SizedBox(height: 8.0),
              TextFormField(
                autofocus: false,
                obscureText: true,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '输入新密码',
                  hintStyle: TextStyle(color: Colors.white),
                  contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
//                border: OutlineInputBorder(
//                    borderRadius: BorderRadius.circular(32.0)),
                ),
                onChanged: (String value) {
                  newpwd = value;
                },
              ),
              SizedBox(height: 8.0),
              TextFormField(
                obscureText: true,
                autofocus: false,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '重复新密码',
                  hintStyle: TextStyle(color: Colors.white),
                  contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
//                border: OutlineInputBorder(
//                    borderRadius: BorderRadius.circular(32.0)),
                ),
                onChanged: (String value) {
                  repetpwd = value;
                },
              ),
              SizedBox(height: 8.0),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: RaisedButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  onPressed: () {
                    register();
                  },
                  padding: EdgeInsets.all(12),
                  color: Colors.grey,
                  child: Text('修改密码', style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  register() async {
    if (newpwd != repetpwd) {
      BotToast.showText(text: "两次密码不一致,请修改");

      return;
    }
    if (newpwd.isNotEmpty &&
        repetpwd.isNotEmpty &&
        account.isNotEmpty &&
        email.isNotEmpty) {
      Response response = await Util(context).http().patch(
          Common.modifypassword,
          data: {"name": account, "password": newpwd, "email": email});

      var data = response.data;
      if (data['code'] == 40001) {
        BotToast.showText(text: data['msg']);
      } else {
        BotToast.showText(text: "修改密码成功");
        await Future.delayed(Duration(seconds: 1));
        Routes.navigateTo(context, Routes.login);
      }
    } else {
      _scaffoldkey.currentState
          .showSnackBar(new SnackBar(content: Text('检查输入项不可为空')));
    }
  }
}
