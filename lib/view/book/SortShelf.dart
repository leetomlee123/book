import 'package:book/model/ShelfModel.dart';
import 'package:book/store/Store.dart';
import 'package:book/widgets/BooksWidget.dart';
import 'package:book/widgets/ConfirmDialog.dart';
import 'package:flutter/material.dart';

class SortShelf extends StatefulWidget {
  @override
  _SortShelfState createState() => _SortShelfState();
}

class _SortShelfState extends State<SortShelf> {
  ShelfModel _shelfModel;

  @override
  void initState() {
    super.initState();
    _shelfModel = Store.value(context);
  }

  @override
  Widget build(BuildContext context) {
    return Store.connect<ShelfModel>(
        builder: (context, ShelfModel shelfModel, child) {
      return Scaffold(
          appBar: AppBar(
            title: Text(
              "书架整理",
            ),
            elevation: 0,
            centerTitle: true,
            leadingWidth: 80,
            leading: TextButton(
              child: Text(
                shelfModel.pickAllFlag ? '全不选' : '全选',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                shelfModel.pickAll();
              },
            ),
            actions: [
              TextButton(
                child: Text('完成', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            ],
          ),
          body: BooksWidget("sort"),
          bottomNavigationBar: ButtonBar(
            alignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton(
                child: Container(
                  child: Text(
                    '删除',
                    style: TextStyle(
                        color: shelfModel.hasPick() ? Colors.red : Colors.grey),
                  ),
                  // width: (Screen.width - 10) / 2,
                ),
                onPressed: shelfModel.hasPick()
                    ? () async {
                        var _alertDialog = ConfirmDialog(
                          "确定要删除所选书籍吗?",
                          () {
                            // 展示 SnackBar
                            Navigator.of(context).pop(true);
                          },
                          () {
                            Navigator.of(context).pop(false);
                          },
                        );
                        var isDismiss = await showDialog(
                            context: context,
                            builder: (context) {
                              return _alertDialog;
                            });
                        if (isDismiss) {
                          shelfModel.removePicks();
                        }
                      }
                    : null,
              ),
            ],
          ));
    });
  }

  @override
  void dispose() {
    _shelfModel.initPicks();
    super.dispose();
  }
}
