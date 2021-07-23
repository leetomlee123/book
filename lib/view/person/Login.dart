import 'package:book/common/Http.dart';
import 'package:book/common/Screen.dart';
import 'package:book/common/common.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:book/widgets/text_two.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String username = '';
  bool isLogin = false;
  String pwd = "";

  githubLogin() async {
    BotToast.showText(text: "not support yet");
  }

  googleLogin() async {
    BotToast.showText(text: "not support yet");
    // try {
    //   GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();
    //   BotToast.showText(text: googleSignInAccount.toString());

    // } catch (error) {
    //   print(error);
    // }
  }

  login(BuildContext context) async {
    FocusScope.of(context).requestFocus(FocusNode());
    var formData = FormData.fromMap({"name": username, "password": pwd});
    Response response = await HttpUtil.instance.dio
        .post(Common.login, data: formData);
    var data = response.data;
    if (data['code'] != 201) {
      BotToast.showText(text: data['msg']);
    } else {
      //收起键盘
      SpUtil.putString('email', data['data']['email']);
      SpUtil.putString('username', username);
      SpUtil.putString("auth", data['data']['token']);

      // eventBus.fire(SyncShelfEvent(""));
      var s = Store.value<ShelfModel>(context);
      s.refreshShelf();
      //书架同步
      var shelf2 = s.shelf;
      if (shelf2.length > 0) {
        for (var value in shelf2) {
          if (SpUtil.haveKey("auth")) {
            HttpUtil.instance.dio.get(Common.bookAction + '/${value.Id}/add');
          }
        }
      }
      // Routes.navigateTo(context, Routes.root);
      //
      Navigator.of(context).popUntil(ModalRoute.withName('/'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          child: Column(
            key: UniqueKey(),
            children: <Widget>[
              SizedBox(
                height: Screen.topSafeHeight + 80,
              ),
              CircleAvatar(
                radius: 60,
                backgroundImage: AssetImage("images/login.jpg"),
                backgroundColor: Colors.white,
              ),
              SizedBox(
                height: 10,
              ),
              Center(child: Text('即刻追书')),
              SizedBox(
                height: 40,
              ),
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
              SizedBox(
                height: 15,
              ),
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
              SizedBox(
                height: 30,
              ),
              GestureDetector(
                child: Container(
                  width: 320.0,
                  height: 44.0,
                  alignment: FractionalOffset.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.all(const Radius.circular(22.0)),
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
              SizedBox(
                height: 20,
              ),
              TextTwo(
                "其他账号登录",
                fontSize: 12,
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    child: CircleAvatar(
                      backgroundImage: AssetImage("images/google-logo.jpg"),
                      backgroundColor: Colors.white,
                    ),
                    onTap: () => googleLogin(),
                  ),
                  GestureDetector(
                    child: CircleAvatar(
                      backgroundImage: AssetImage("images/github.png"),
                      backgroundColor: Colors.white,
                    ),
                    onTap: () => githubLogin(),
                  ),
                ],
              ),
              Row(
                key: UniqueKey(),
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
                  SizedBox(
                    width: 30,
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
          padding: EdgeInsets.symmetric(horizontal: 20),
        ));
  }
}
