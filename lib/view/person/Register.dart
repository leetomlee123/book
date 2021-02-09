import 'package:book/common/common.dart';
import 'package:book/common/Http.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
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
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Container(
              color: Store.value<ColorModel>(context).dark
                  ? Colors.black
                  : Colors.transparent,
            ),
            Center(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.only(left: 24.0, right: 24.0),
                children: <Widget>[
                  TextFormField(
                    keyboardType: TextInputType.phone,
                    autofocus: false,
                    // style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '账号',
                      // hintStyle: TextStyle(color: Colors.white),
                      contentPadding:
                          EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
//                border: OutlineInputBorder(
//                    borderRadius: BorderRadius.circular(32.0)),
                    ),
                    onChanged: (String value) {
                      this.name = value;
                    },
                  ),
                  SizedBox(height: 8.0),
                  TextFormField(
                    autofocus: false,
                    obscureText: true,
                    // style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '密码',
                      // hintStyle: TextStyle(color: Colors.white),
                      contentPadding:
                          EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
//                border: OutlineInputBorder(
//                    borderRadius: BorderRadius.circular(32.0)),
                    ),
                    onChanged: (String value) {
                      pwd = value;
                    },
                  ),
                  SizedBox(height: 8.0),
                  TextFormField(
                    autofocus: false,
                    obscureText: true,
                    // style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '重复密码',
                      // hintStyle: TextStyle(color: Colors.white),
                      contentPadding:
                          EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
//                border: OutlineInputBorder(
//                    borderRadius: BorderRadius.circular(32.0)),
                    ),
                    onChanged: (String value) {
                      repassword = value;
                    },
                  ),
                  SizedBox(height: 8.0),
                  TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    autofocus: false,
                    // style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      // hintStyle: TextStyle(color: Colors.white),
                      hintText: '邮箱 找回密码的唯一凭证,请谨慎输入...',
                      contentPadding:
                          EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
//                border: OutlineInputBorder(
//                    borderRadius: BorderRadius.circular(32.0)),
                    ),
                    onChanged: (String value) {
                      email = value;
                    },
                  ),
                  SizedBox(height: 8.0),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: RaisedButton(
                      color: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      onPressed: () {
                        register();
                      },
                      padding: EdgeInsets.all(12),
                      child: Text('注册',style: TextStyle(color: Colors.white),),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
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
      if (!email.contains("@")) {
        BotToast.showText(text: '输入正确邮箱账号');

        return;
      }
      Response response;
      var formData =
          FormData.fromMap({"name": name, "password": pwd, "email": email});
      try {
        response = await HttpUtil(showLoading: true).http().post(
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
