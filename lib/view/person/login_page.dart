import 'package:book/common/screen.dart';
import 'package:book/common/local_account.dart';
import 'package:book/route/routes.dart';
import 'package:book/store/providers.dart';
import 'package:book/widgets/text_two.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Login extends ConsumerStatefulWidget {
  const Login({super.key});

  @override
  ConsumerState<Login> createState() => _LoginState();
}

class _LoginState extends ConsumerState<Login> {
  String username = '';
  String pwd = "";

  Future<void> login(BuildContext context) async {
    FocusScope.of(context).requestFocus(FocusNode());
    final err = LocalAccount.login(name: username, password: pwd);
    if (err != null) {
      BotToast.showText(text: err);
      return;
    }
    BotToast.showText(text: '登录成功（本地账号）');
    var s = ref.read(shelfModelProvider);
    s.refreshShelf();
    Navigator.of(context).popUntil(ModalRoute.withName('/'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text("登录"),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: Screen.topSafeHeight + 5,
                ),
                CircleAvatar(
                  radius: 60,
                  backgroundImage: const AssetImage("images/login.jpg"),
                  backgroundColor: Colors.white,
                ),
                SizedBox(height: 10),
                Center(child: Text('即刻追书')),
                SizedBox(height: 6),
                Text(
                  '本地账号 · 无需服务器',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                SizedBox(height: 10),
                TextFormField(
                  autofocus: false,
                  decoration: InputDecoration(
                      hintText: '账号',
                      contentPadding:
                          EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                      prefixIcon: Icon(Icons.person)),
                  onChanged: (String value) {
                    username = value;
                  },
                ),
                SizedBox(height: 15),
                TextFormField(
                  autofocus: false,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock),
                    hintText: '密码',
                    contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                  ),
                  onChanged: (String value) {
                    pwd = value;
                  },
                ),
                SizedBox(height: 30),
                GestureDetector(
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
                SizedBox(height: 20),
                TextTwo(
                  "账号仅保存在本机",
                  fontSize: 12,
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    TextButton(
                      child: Text('忘记密码'),
                      onPressed: () {
                        Routes.navigateTo(context, Routes.modifyPassword);
                      },
                    ),
                    SizedBox(width: 30),
                    TextButton(
                      child: Text('注册'),
                      onPressed: () {
                        Routes.navigateTo(context, Routes.register);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
  }
}
