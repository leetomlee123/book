import 'dart:convert' as convert;

import 'package:book/entity/Book.dart';
import 'package:book/entity/BookInfo.dart';
import 'package:book/entity/GBook.dart';
import 'package:book/view/book/AllTagBook.dart';
import 'package:book/view/book/BookDetail.dart';
import 'package:book/view/book/BookShelf.dart';
import 'package:book/view/book/ChapterView.dart';
import 'package:book/view/book/ReadBook.dart';
import 'package:book/view/book/Search.dart';
import 'package:book/view/book/SortShelf.dart';
import 'package:book/view/person/Forgetpass.dart';
import 'package:book/view/person/Login.dart';
import 'package:book/view/person/Register.dart';
import 'package:book/view/system/FontSet.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';

// 根目录
var rootHandler =
    Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
  return BookShelf();
});
// 根目录

// 设置页 - 示例：不传参数
var searchHandler =
    Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
  String type = (params['type'][0]);
  String name = (params['name'][0]);
  return Search(type, name);
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

var sortShelfHandler =
    Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
  return SortShelf();
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
  Book _bookInfo = Book.fromJson(convert.jsonDecode(params['read'][0]));
  return ReadBook(_bookInfo);
});
var chaptersHandler =
    Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
  return ChapterView();
});

var detailHandler =
    Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
  BookInfo _bookInfo =
      BookInfo.fromJson(convert.jsonDecode(params['detail'][0]));

  return BookDetail(_bookInfo);
});
