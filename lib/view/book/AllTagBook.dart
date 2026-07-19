import 'package:book/common/PicWidget.dart';
import 'package:book/entity/GBook.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AllTagBook extends ConsumerWidget {
  final String title;
  final List<GBook> bks;

  const AllTagBook(this.title, this.bks, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(colorModelProvider);
    Widget img(GBook gbk) {
      return Column(
        children: <Widget>[
          GestureDetector(
            child: PicWidget(
              gbk.cover,
            ),
            onTap: () async {
              Routes.navigateTo(context, Routes.search, params: {
                "type": "book",
                "name": gbk.name,
              });
            },
          ),
          Text(
            gbk.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          title,
          style: TextStyle(
            color: data.dark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        children: <Widget>[
          GridView(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(5.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 1.0,
                crossAxisSpacing: 10.0,
                childAspectRatio: 0.6),
            children: bks.map((item) => img(item)).toList(),
          )
        ],
      ),
    );
  }
}
