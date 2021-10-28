import 'package:book/common/Http.dart';
import 'package:book/common/common.dart';
import 'package:book/route/Routes.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ForgetPass extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new _ForgetPassState();
  }
}

class _ForgetPassState extends State<ForgetPass> {
  String account='';
  String newpwd='';
  String email='';
  String repetpwd='';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("忘记密码"),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: Column(
            children: <Widget>[
              TextFormField(
                keyboardType: TextInputType.phone,
                autofocus: false,
                decoration: InputDecoration(
                    hintText: '账号',
                    contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                    prefixIcon: Icon(Icons.person)),
                onChanged: (String value) {
                  this.account = value;
                },
              ),
              SizedBox(height: 8.0),
              TextFormField(
                autofocus: false,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                    hintText: '邮箱',
                    contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                    prefixIcon: Icon(Icons.email)),
                onChanged: (String value) {
                  email = value;
                },
              ),
              SizedBox(height: 8.0),
              TextFormField(
                autofocus: false,
                obscureText: true,
                decoration: InputDecoration(
                    hintText: '输入新密码',
                    contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                    prefixIcon: Icon(Icons.lock)),
                onChanged: (String value) {
                  newpwd = value;
                },
              ),
              SizedBox(height: 8.0),
              TextFormField(
                obscureText: true,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: '重复新密码',
                  contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                  prefixIcon: Icon(Icons.repeat)
                ),
                onChanged: (String value) {
                  repetpwd = value;
                },
              ),
              SizedBox(height: 8.0),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child:                 GestureDetector(
                  child: Container(
                    width: 320.0,
                    height: 44.0,
                    alignment: FractionalOffset.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius:
                          BorderRadius.all(const Radius.circular(22.0)),
                    ),
                    child: Text(
                      "重置密码",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.0,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  onTap: () =>register(),
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
      Response response = await HttpUtil.instance.dio.patch(
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('检查输入项不可为空')));
    }
  }
}
