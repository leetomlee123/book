import 'package:book/model/ShelfModel.dart';
import 'package:book/store/Store.dart';
import 'package:book/widgets/BooksWidget.dart';
import 'package:book/widgets/ConfirmDialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SortShelf extends ConsumerStatefulWidget {
  @override
  ConsumerState<SortShelf> createState() => _SortShelfState();
}

class _SortShelfState extends ConsumerState<SortShelf> {
  late ShelfModel _shelfModel;

  @override
  void initState() {
    super.initState();
    _shelfModel = ref.read(shelfModelProvider);
  }

  @override
  Widget build(BuildContext context) {
    final shelfModel = ref.watch(shelfModelProvider);
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
            ),
            onPressed: () {
              shelfModel.pickAll();
            },
          ),
          actions: [
            TextButton(
              child: const Text('完成'),
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
  }

  @override
  void dispose() {
    _shelfModel.initPicks();
    super.dispose();
  }
}
