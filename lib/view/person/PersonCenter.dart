import 'package:book/common/common.dart';
import 'package:book/common/util.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class PersonCenter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return new _PersonCenter();
  }
}

class _PersonCenter extends State<PersonCenter> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(padding: const EdgeInsets.only(), children: <Widget>[
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
      ]),
    );
  }
}

