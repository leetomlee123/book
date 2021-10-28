import 'package:book/common/Http.dart';
import 'package:book/common/common.dart';
import 'package:book/route/Routes.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class Register extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _RegisterState();
  }
}

class _RegisterState extends State<Register> {
  String name;
  String pwd;
  String email;
  String repassword;

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
              TextFormField(
                keyboardType: TextInputType.phone,
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
                validator: (v)=>checkEmail(v),
                decoration: InputDecoration(
                    hintText: '邮箱 找回密码的唯一凭证,请谨慎输入...',
                    contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                    prefixIcon: Icon(Icons.email)),
                onChanged: (String value) {
                  email = value;
                },
              ),
              SizedBox(height: 8.0),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: GestureDetector(
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
                      "注 册",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.0,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  onTap: () => register(),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  String checkEmail(String input) {
    bool flag = false;

    String regexEmail = "^\\w+([-+.]\\w+)*@\\w+([-.]\\w+)*\\.\\w+([-.]\\w+)*\$";

    if (RegExp(regexEmail).hasMatch(input)) {
      flag = true;
    }
    return flag ? null : "邮箱地址不合法";
  }

  register() async {
    if (pwd.isNotEmpty &&
        repassword.isNotEmpty &&
        name.isNotEmpty &&
        email.isNotEmpty) {
      if (pwd != repassword) {
        BotToast.showText(text: '两次密码不一致');
        return;
      }

      String regexEmail =
          "^\\w+([-+.]\\w+)*@\\w+([-.]\\w+)*\\.\\w+([-.]\\w+)*\$";

      if (RegExp(regexEmail).hasMatch(email)) {
        BotToast.showText(text: '输入正确邮箱账号');

        return;
      }
      Response response;
      var formData =
          FormData.fromMap({"name": name, "password": pwd, "email": email});
      try {
        response = await HttpUtil.instance.dio.post(
          Common.register,
          data: formData,
        );
        var data = response.data;
        if (data["code"] == 200) {
          BotToast.showText(text: data['msg']);

          Routes.navigateTo(context, Routes.login);
        } else {
          BotToast.showText(text: data['msg']);
        }
      } catch (e) {
        BotToast.showText(text: "注册异常,请重试...");
      }
    } else {
      BotToast.showText(text: "检查输入项不可为空");
    }
  }
}
