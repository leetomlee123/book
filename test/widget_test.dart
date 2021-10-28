// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:book/entity/chapter.pb.dart';

void main() async {
  File file = new File("E:\\a\\book\\test\\proto3");
  ChaptersProto cps = ChaptersProto.fromBuffer(file.readAsBytesSync());
  cps.chaptersProto.forEach((element) {
  });
  // Chapters chapters = new Chapters.fromBuffer(file.readAsBytesSync());
  // chapters.chapters.forEach((element) {
  // });
}
