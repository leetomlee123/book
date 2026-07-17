import 'dart:convert';

import 'package:book/common/DbHelper.dart';
import 'package:book/common/PicWidget.dart';
import 'package:book/common/Screen.dart';
import 'package:book/common/app_colors.dart';
import 'package:book/common/local_store.dart';
import 'package:book/entity/Book.dart';
import 'package:book/entity/BookInfo.dart';
import 'package:book/event/event.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/book/SourceSwitchSheet.dart';
import 'package:book/widgets/text_ellipsis.dart';
import 'package:book/widgets/text_two.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookDetail extends ConsumerStatefulWidget {
  final BookInfo _bookInfo;

  BookDetail(this._bookInfo);

  @override
  ConsumerState<BookDetail> createState() => _BookDetailState();
}

class _BookDetailState extends ConsumerState<BookDetail> {
  late Book book;
  int maxLines = 3;
  bool ellipsis = true;

  @override
  void initState() {
    book = this.widget._bookInfo.toBook();
    super.initState();
  }

  Widget _bookHead() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimens.coverRadius),
              boxShadow: AppShadows.cover,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.coverRadius),
              child: PicWidget(
                book.Img,
                height: 130,
                width: 95,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  book.Name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text('作者: ${book.Author}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 4),
                Text('类型: ${book.CName}',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 12, color: Colors.white70)),
                if (book.originName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('书源: ${book.originName}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
                if (this.widget._bookInfo.BookStatus.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('状态: ${this.widget._bookInfo.BookStatus}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookDesc() {
    return TextEllipsis(this.widget._bookInfo.Desc.trim());
  }

  Widget _bookMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '目录',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          ListTile(
            leading: Container(
              width: 70,
              child: Row(
                children: <Widget>[
                  Icon(Icons.access_time),
                  SizedBox(
                    width: 5,
                  ),
                  TextTwo(
                    '最新',
                  )
                ],
              ),
            ),
            title: TextTwo(
              this.widget._bookInfo.LastChapter,
              fontSize: 14,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sameAuthorBooks() {
    return Offstage(
      offstage: this.widget._bookInfo.SameAuthorBooks.isEmpty,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '作者还写过',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            ListView.builder(
              padding: const EdgeInsets.only(),
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, i) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 115,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        PicWidget(
                          this.widget._bookInfo.SameAuthorBooks[i].Img,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  this.widget._bookInfo.SameAuthorBooks[i].Name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  this
                                      .widget
                                      ._bookInfo
                                      .SameAuthorBooks[i]
                                      .Author,
                                  style: TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                    this
                                        .widget
                                        ._bookInfo
                                        .SameAuthorBooks[i]
                                        .LastChapter,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    // Same-author list is no longer backed by server detail.
                  },
                );
              },
              itemCount: this.widget._bookInfo.SameAuthorBooks.length,
              cacheExtent: 200,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBottom() {
    final model = ref.watch(shelfModelProvider);
    final dark = SpUtil.getBool("dark");
    final inShelf = model.inShelf(this.widget._bookInfo.Id);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: BoxDecoration(
          color: dark ? AppColors.surfaceDark : AppColors.surface,
          boxShadow: AppShadows.softBar,
        ),
        padding: EdgeInsets.fromLTRB(
            16, 10, 16, Screen.bottomSafeHeight + 10),
        child: Row(
          children: [
            TextButton(
              onPressed: () {
                SpUtil.putString(book.Id, "");
                model.modifyShelf(book);
              },
              child: Text(inShelf ? "移出书架" : "加入书架"),
            ),
            TextButton(
              onPressed: () {
                final readModel = ref.read(readModelProvider);
                readModel.book = book;
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => SourceSwitchSheet(readModel: readModel),
                );
              },
              child: const Text("换源"),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: AppDimens.ctaHeight,
                child: ElevatedButton(
                  onPressed: () async {
                    Book? b = await DbHelper.instance.getBook(book.Id);
                    Routes.navigateTo(
                      context,
                      Routes.read,
                      params: {
                        'read': jsonEncode(b ?? book),
                      },
                    );
                  },
                  child: Text(SpUtil.haveKey(book.Id) ? "继续阅读" : "立即阅读"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                elevation: 0,
                backgroundColor: AppColors.brand,
                iconTheme: const IconThemeData(color: Colors.white),
                actions: <Widget>[
                  GestureDetector(
                    child: const Center(
                      child: Text(
                        '书架',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).popUntil(ModalRoute.withName('/'));
                      eventBus.fire(NavEvent(0));
                    },
                  ),
                  const SizedBox(width: 20)
                ],
                expandedHeight: 230.0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF1AAD19),
                          Color(0xFF148A13),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(top: Screen.topSafeHeight + 45),
                      child: _bookHead(),
                    ),
                  ),
                ),
              ),
              SliverList(
                  delegate: SliverChildListDelegate([
                _bookDesc(),
                Divider(
                  endIndent: 12,
                  indent: 12,
                ),
                _bookMenu(),
                Divider(
                  endIndent: 12,
                  indent: 12,
                ),
                _sameAuthorBooks(),
              ])),
            ],
          ),
          _buildBottom()
        ],
      ),
    );
  }
}
