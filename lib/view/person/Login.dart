import 'dart:developer';

import 'package:book/common/Http.dart';
import 'package:book/common/Screen.dart';
import 'package:book/common/common.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';

class Login extends StatelessWidget {
  String username = '';
  bool isLogin = false;
  String pwd;

  login(BuildContext context) async {
    FocusScope.of(context).requestFocus(FocusNode());
    var formData = FormData.fromMap({"name": username, "password": pwd});
    Response response = await HttpUtil(showLoading: true)
        .http()
        .post(Common.login, data: formData);
    var data = response.data;
    if (data['code'] != 201) {
      BotToast.showText(text: data['msg']);
    } else {
      //收起键盘
      SpUtil.putString('email', data['data']['email']);
      // SpUtil.putString('vip', data['data']['vip']);
//        SpUtil.putString('pwd', pwd);
      SpUtil.putString('username', username);
      // SpUtil.putBool('login', true);
      SpUtil.putString("auth", data['data']['token']);
      eventBus.fire(SyncShelfEvent(""));

      //书架同步
      var shelf2 = Store.value<ShelfModel>(context).shelf;
      if (shelf2.length > 0) {
        for (var value in shelf2) {
          if (SpUtil.haveKey("auth")) {
            HttpUtil().http().get(Common.bookAction + '/${value.Id}/add');
          }
        }
      }
      // Routes.navigateTo(context, Routes.root);
      //
      Navigator.of(context).popUntil(ModalRoute.withName('/'));
      // eventBus.fire(new NavEvent(0));
    }
  }

  @override
  Widget build(BuildContext context) {
    double vp = (Screen.height / 5).toDouble();
    return Scaffold(
        body: Container(
      padding: EdgeInsets.only(top: vp),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: <Widget>[
              CircleAvatar(backgroundImage: AssetImage("images/github.png"),backgroundColor: Colors.white,),
              SizedBox(height: 60.0),
              TextFormField(
                autofocus: false,
                // style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  // hintStyle: TextStyle(color: Colors.white),
                  hintText: '账号',
                  contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
//        border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
                ),
                onChanged: (String value) {
                  this.username = value;
                },
              ),
              SizedBox(height: 8.0),
              TextFormField(
                autofocus: false,
                obscureText: true,
                // style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  // hintStyle: TextStyle(color: Colors.white),
                  hintText: '密码',
                  contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
//        border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
                ),
                onChanged: (String value) {
                  this.pwd = value;
                },
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: GestureDetector(
                  child: Container(
                    width: 320.0,
                    height: 44.0,
                    alignment: FractionalOffset.center,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(247, 0, 106, 1.0),
                      borderRadius:
                          BorderRadius.all(const Radius.circular(22.0)),
                    ),
                    child: Text(
                      "登 陆",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.0,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  onTap: () => login(context),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  TextButton(
                    child: Text(
                      '忘记密码',
                      // style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () {
                      Routes.navigateTo(context, Routes.modifyPassword);
                    },
                  ),
                  TextButton(
                    child: Text(
                      '注册',
                      // style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () {
                      Routes.navigateTo(context, Routes.register);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
