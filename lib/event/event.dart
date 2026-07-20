import 'package:event_bus/event_bus.dart';

/// App-wide event bus for loose cross-widget signals.
final EventBus eventBus = EventBus();

/// Shelf in-memory progress sync (not persisted here — DB write is ReadModel).
class UpdateBookProcess {
  final String bookId;
  final int cur;
  final int index;
  final String chapterName;
  UpdateBookProcess(this.bookId, this.cur, this.index, {this.chapterName = ''});
}

/// Switch MainShell bottom tab.
class NavEvent {
  final int idx;
  NavEvent(this.idx);
}

/// Open full-screen chapter catalog from reader chrome.
class OpenChapters {
  final String name;
  OpenChapters(this.name);
}
