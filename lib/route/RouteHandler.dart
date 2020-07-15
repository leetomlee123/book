import 'dart:convert' as convert;

import 'package:book/entity/BookInfo.dart';
import 'package:book/entity/GBook.dart';
import 'package:book/main.dart';
import 'package:book/view/AllTagBook.dart';
import 'package:book/view/BookDetail.dart';
import 'package:book/view/FontSet.dart';
import 'package:book/view/Forgetpass.dart';
import 'package:book/view/LookVideo.dart';
import 'package:book/view/PersonCenter.dart';
import 'package:book/view/ReadBook.dart';
import 'package:book/view/Register.dart';
import 'package:book/view/Search.dart';
import 'package:book/view/TagVideo.dart';
import 'package:book/view/VideoDetail.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';

// 根目录
var rootHandler =
    Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
  return MainPage();
});

// 设置页 - 示例：不传参数
var searchHandler =
    Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
  String type = (params['type'][0]);
  String name = (params['name'][0]);
  return Search(type,name);
});
var loginHandler =
    Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
  return Login();
});
var registerHandler =
    Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
  return Register();
});
var modifyPasswordHandler =
    Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
  return ForgetPass();
});
var fontSetHandler =
    Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
  return FontSet();
});

var allTagBookHandler =
    Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
  String title = (params['title'][0]);
  List list = convert.jsonDecode(params["bks"][0]);
  List<GBook> list2 = list.map((f) => GBook.fromJson(f)).toList();
  return AllTagBook(title, list2);
});
var vDetailHandler =
    Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
  String gbook = (params['gbook'][0]);

  return VideoDetail(GBook.fromJson(convert.jsonDecode(gbook)));
});
var lookVideoHandler =
    Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
  String id = (params['id'][0]);
  String cover = (params['cover'][0]);
  String name = (params['name'][0]);
  List mcids = convert.jsonDecode(params['mcids'][0]);

  return LookVideo(id, mcids, cover, name);
});
var tagVideoHandler =
    Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
  String category = (params['category'][0]);
  String name = (params['name'][0]);

  return TagVideo(category, name);
});

//// 网页加载 - 示例：传多个字符串参数
//var webViewHandler =
//    Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
//  // params内容为  {title: [我是标题哈哈哈], url: [https://www.baidu.com/]}
//  String title = params['title']?.first;
//  String url = params['url']?.first;
//  return WebViewUrlPage(
//    title: title,
//    url: url,
//  );
//});

// 示例：传多个model参数
var readHandler =
    Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
//  print('params: $params');
//  String model = params['userInfoModel']?.first;
//  print('model: $model');
//  // model: {name: yuanzhiying, age: 30, height: 1.78, weight: 74.0}
//  Map<String, dynamic> jsonMap = convert.jsonDecode(model);
//  print('jsonMap: $jsonMap');
//  UserInfoModel _model = UserInfoModel.fromJson(jsonMap);

  BookInfo _bookInfo = BookInfo.fromJson(convert.jsonDecode(params['read'][0]));

  return ReadBook(_bookInfo);
});
var detailHandler =
    Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
  BookInfo _bookInfo =
      BookInfo.fromJson(convert.jsonDecode(params['detail'][0]));

  return BookDetail(_bookInfo);
});
