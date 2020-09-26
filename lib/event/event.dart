import 'package:book/entity/Book.dart';
import 'package:event_bus/event_bus.dart';

EventBus eventBus = new EventBus();

class AddEvent {}

class OpenEvent {
  String name;

  OpenEvent(this.name);
}

class OpenChapters {
  String name;

  OpenChapters(this.name);
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
