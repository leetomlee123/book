import 'package:book/entity/Book.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/gestures.dart';

EventBus eventBus = new EventBus();

class AddEvent {}

class PageControllerGo {
  final int go;
  final Offset localDetail;
  PageControllerGo(this.go,this.localDetail);
}

class UpdateBookProcess {
  final int cur;
  final int index;
  UpdateBookProcess(this.cur, this.index);
}

class DownLoadNotify {
  String url;
  double v;
  DownLoadNotify(this.url,this.v);
}

class OpenEvent {
  String name;

  OpenEvent(this.name);
}

class ZEvent {
  int off;

  ZEvent(this.off);
}

class ScrollEvent {
  int off;

  ScrollEvent(this.off);
}

class PlayEvent {
  String name;

  PlayEvent(this.name);
}

class OpenChapters {
  String name;

  OpenChapters(this.name);
}

class OpenBottom {
  String name;

  OpenBottom(this.name);
}

class CleanEvent {
  int x;
  CleanEvent(this.x);
}

class NavEvent {
  int idx;

  NavEvent(this.idx);
}

class PageEvent {
  int page;

  PageEvent(this.page);
}

class SyncShelfEvent {
  String msg;

  SyncShelfEvent(this.msg);
}

class ChapterEvent {
  int chapterId;

  ChapterEvent(this.chapterId);
}

class BooksEvent {
  List<Book> books;

  BooksEvent(this.books);
}

class ReadRefresh {
  var em;

  ReadRefresh(this.em);
}
