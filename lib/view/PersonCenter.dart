import 'package:book/common/common.dart';
import 'package:book/common/toast.dart';
import 'package:book/common/util.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';

class PersonCenter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return new _PersonCenter();
  }
}

class _PersonCenter extends State<PersonCenter>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    final personbody =
        ListView(padding: const EdgeInsets.only(), children: <Widget>[
      UserAccountsDrawerHeader(
//      margin: EdgeInsets.zero,
        accountName: Text(
          SpUtil.getString('username'),
        ),
        accountEmail: Text(
          SpUtil.haveKey('email') ? SpUtil.getString('email') : '点击头像登陆/注册',
        ),
        currentAccountPicture: GestureDetector(
          child: CircleAvatar(
            backgroundImage: AssetImage("images/fu.png"),
          ),
          onTap: () {
            if (!SpUtil.haveKey('email')) {
              Routes.navigateTo(context, Routes.login);
            }
          },
        ),
      ),
    ]);

    return Scaffold(
      body: personbody,
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}

class Login extends StatelessWidget {
  String username = '';
  bool isLogin = false;
  String pwd;

  @override
  Widget build(BuildContext context) {
    login() async {
      FocusScope.of(context).requestFocus(FocusNode());
      var formData = FormData.fromMap({"name": username, "password": pwd});
      Response response =
          await Util(context).http().post(Common.login, data: formData);
      var data = response.data;
      if (data['code'] != 201) {
        Toast.show(data['msg']);
      } else {
        //收起键盘
//        SpUtil.putString('email', data['data']['email']);
//        SpUtil.putString('pwd', pwd);
        SpUtil.putString('username', username);
        SpUtil.putBool('login', true);
        SpUtil.putString("auth", data['data']['token']);
        eventBus.fire(new SyncShelfEvent(""));

        //书架同步
        var shelf2 = Store.value<ShelfModel>(context).shelf;
        if (shelf2.length > 0) {
          for (var value in shelf2) {
            if (SpUtil.haveKey("auth")) {
              Util(null).http().get(Common.bookAction + '/${value.Id}/add');
            }
          }
        }
        Navigator.of(context).popUntil(ModalRoute.withName('/'));
        eventBus.fire(new NavEvent(0));
      }
    }

    final email = TextFormField(
      autofocus: false,
      decoration: InputDecoration(
        hintText: '账号',
        contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
//        border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
      ),
      onChanged: (String value) {
        this.username = value;
      },
    );

    final password = TextFormField(
      autofocus: false,
      obscureText: true,
      decoration: InputDecoration(
        hintText: '密码',
        contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
//        border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
      ),
      onChanged: (String value) {
        this.pwd = value;
      },
    );

    final loginButton = Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: RaisedButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        onPressed: () {
          login();
//          Navigator.of(context).pushNamed(HomePage.tag);
        },
        padding: EdgeInsets.all(12),
        child: Text('登陆'),
      ),
    );

    final forgotLabel = FlatButton(
      child: Text(
        '忘记密码',
      ),
      onPressed: () {
        Routes.navigateTo(context, Routes.modifyPassword);
      },
    );
    final loginUpLabel = FlatButton(
      child: Text(
        '注册',
      ),
      onPressed: () {
        Routes.navigateTo(context, Routes.register);
      },
    );
    final loginBody = Center(
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.only(left: 24.0, right: 24.0),
        children: <Widget>[
          SizedBox(height: 48.0),
          email,
          SizedBox(height: 8.0),
          password,
          loginButton,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              forgotLabel,
              loginUpLabel,
            ],
          ),
        ],
      ),
    );
    // TODO: implement build

    return Theme(
      child: Material(
        child: Container(
          child: loginBody,
        ),
      ),
      data: Store.value<ColorModel>(context).theme,
    );
  }
}
