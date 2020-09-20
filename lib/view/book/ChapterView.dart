import 'package:book/model/ColorModel.dart';
import 'package:book/model/ReadModel.dart';
import 'package:book/store/Store.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ChapterView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _ChapterViewItem();
  }
}

class _ChapterViewItem extends State<ChapterView> {
  ScrollController _scrollController = new ScrollController();

  double ITEM_HEIGH = 50.0;

  bool up = false;
  int curIndex = 0;
  bool showToTopBtn = false; //是否显示“返回到顶部”按钮

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _scrollController.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    var widgetsBinding = WidgetsBinding.instance;
    widgetsBinding.addPostFrameCallback((callback) {
      scrollTo();
    });
    //监听滚动事件，打印滚动位置
    _scrollController.addListener(() {
      if (_scrollController.offset < ITEM_HEIGH * 8 && showToTopBtn) {
        setState(() {
          showToTopBtn = false;
        });
      } else if (_scrollController.offset >= 1000 && showToTopBtn == false) {
        setState(() {
          showToTopBtn = true;
        });
      }
    });
  }

//滚动到当前阅读位置
  scrollTo() async {
    if (_scrollController.hasClients) {
      curIndex = Store.value<ReadModel>(context).bookTag.cur - 8;
      await _scrollController.animateTo(
          (Store.value<ReadModel>(context).bookTag.cur - 8) * ITEM_HEIGH,
          duration: Duration(microseconds: 1),
          curve: Curves.ease);
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    return Store.connect<ReadModel>(builder: (context, ReadModel data, child) {
      var value = Store.value<ColorModel>(context);
      return Theme(
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              data.bookTag.bookName ?? '',
              style: TextStyle(fontSize: 16.0),
            ),
            centerTitle: true,
            automaticallyImplyLeading: false,
            elevation: 0,
          ),
          body: Scrollbar(
            child: ListView.builder(
              controller: _scrollController,
              itemExtent: ITEM_HEIGH,
              itemBuilder: (context, index) {
                var title = data.chapters[index].name;
                var has = data.chapters[index].hasContent;
                return ListTile(
                  title: Text(
                    title,
                    style: TextStyle(fontSize: 13),
                  ),
                  trailing: Text(
                    has == 2 ? "已缓存" : "",
                    style: TextStyle(fontSize: 8),
                  ),
                  selected: index == data.bookTag.cur,
                  onTap: () async {
                    Navigator.of(context).pop();
                    //不是卷目录
                    Future.delayed(Duration(microseconds: 500));
                    data.bookTag.cur = index;
                    await Future.delayed(Duration(microseconds: 1000));
                    data.intiPageContent(index, true);
                  },
                );
              },
              itemCount: data.chapters.length,
            ),
          ),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              FloatingActionButton(
                  backgroundColor:
                      value.dark ? Colors.white : value.theme.primaryColor,
                  onPressed: refresh,
                  child: Icon(Icons.refresh)),
              SizedBox(
                height: 10.0,
              ),
              FloatingActionButton(
                  backgroundColor:
                      value.dark ? Colors.white : value.theme.primaryColor,
                  onPressed: topOrBottom,
                  child: Icon(
                    showToTopBtn ? Icons.arrow_upward : Icons.arrow_downward,
                  ))
            ],
          ),
        ),
        data: value.theme,
      );
    });
  }

  topOrBottom() async {
    if (_scrollController.hasClients) {
      int temp = showToTopBtn
          ? 1
          : Store.value<ReadModel>(context).chapters.length - 8;
      await _scrollController.animateTo(temp * ITEM_HEIGH,
          duration: Duration(microseconds: 1), curve: Curves.ease);
    }
  }

  Future<void> refresh() async {
    Store.value<ReadModel>(context).reloadChapters();
    if (_scrollController.hasClients) {
      int temp =  Store.value<ReadModel>(context).chapters.length - 8;
      await _scrollController.animateTo(temp * ITEM_HEIGH,
          duration: Duration(microseconds: 1), curve: Curves.ease);
    }
  }
}


