import 'package:book/common/PicWidget.dart';
import 'package:book/common/common.dart';
import 'package:book/common/util.dart';
import 'package:book/entity/BookInfo.dart';
import 'package:book/entity/GBook.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/store/Store.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';

import 'BookDetail.dart';

class GoodBook extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return StateGoodBook();
  }
}

class StateGoodBook extends State<GoodBook>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  TabController controller;
  var tabs = <Tab>[];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    tabs = <Tab>[
      Tab(
        text: "男生",
      ),
      Tab(
        text: "女生",
      ),
    ];

    //initialIndex初始选中第几个
    controller =
        TabController(initialIndex: 0, length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // TODO: implement build
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
          appBar: AppBar(
            title: TabBar(
              indicatorColor: Theme.of(context).primaryColor,
              indicatorSize: TabBarIndicatorSize.label,
              controller: controller,
              tabs: tabs,
            ),
            centerTitle: true,
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
          body: TabBarView(
            controller: controller,
            children:
                tabs.map((f) => TabItem(f.text == "男生" ? "1" : "2")).toList(),
          )),
    );
  }

  @override
// TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}

class TabItem extends StatefulWidget {
  String type;

  TabItem(this.type);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return StateTabItem();
  }
}

class StateTabItem extends State<TabItem>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  List<List<GBook>> values = [];
  List<String> keys = [];
  ColorModel value;

  @override
  void initState() {


    // TODO: implement initState
    super.initState();
    getData();
  }

  Widget item(String title, List<GBook> bks) {
    return Container(
      child: ListView(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: <Widget>[
          SizedBox(
            height: 5.0,
          ),
          Row(
            children: <Widget>[
              Padding(
                child: Container(
                  width: 4,
                  height: 20,
                  color: value.dark ? value.theme.textTheme.body1.color : value.theme.primaryColor,
                ),
                padding: EdgeInsets.only(left: 5.0, right: 3.0),
              ),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: Container(),
              ),
              GestureDetector(
                child: Row(
                  children: <Widget>[
                    Text(
                      "更多",
                      style: TextStyle(color: Colors.grey),
                    ),
                    Icon(
                      Icons.keyboard_arrow_right,
                      color: Colors.grey,
                    )
                  ],
                ),
                onTap: () {

                  Navigator.pushAndRemoveUntil(
                    context,
                    new MaterialPageRoute(builder: (context) => FullGoodBook(title, bks)),
                        (route) => route == null,
                  );


                },
              )
            ],
          ),
          GridView(
            shrinkWrap: true,
            physics: new NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(5.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 1.0,
                crossAxisSpacing: 10.0,
                childAspectRatio: 0.6),
            children: bks.sublist(0, 8).map((item) => img(item)).toList(),
          )
        ],
      ),
    );
  }

  Widget img(GBook gbk) {
    return Container(
      child: Column(
        children: <Widget>[
          GestureDetector(
            child: PicWidget(
              gbk.cover,
              fitOk: true,
            ),
            onTap: () async {
              String url = Common.detail + '/${gbk.id}';
              Response future = await Util(context).http().get(url);
              var d = future.data['data'];
              BookInfo bookInfo = BookInfo.fromJson(d);

              Navigator.pushAndRemoveUntil(
                context,
                new MaterialPageRoute(builder: (context) => new BookDetail(bookInfo)),
                    (route) => route == null,
              );

            },
          ),
          Text(
            gbk.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        ],
      ),
    );
  }

  getData() async {
    Map d;
    var key = Common.toplist + this.widget.type;
    var haveKey = SpUtil.haveKey(key);
    if (haveKey) {
      d = SpUtil.getObject(key);
      formatData(d);
    }
    String url = Common.rank + "/${this.widget.type}";
    Response future = await Util(haveKey ? null : context).http().get(url);
    d = future.data['data'];
    if (d != null) {
      SpUtil.putObject(key, d);
    }
    formatData(d);
  }

  void formatData(Map d) {
    var iterator2 = d.keys.iterator;
    while (iterator2.moveNext()) {
      keys.add(iterator2.current.toString());
    }
    var iterator3 = d.values.iterator;
    while (iterator3.moveNext()) {
      List temp = iterator3.current;
      values.add(temp.map((f) => GBook.fromJson(f)).toList());
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    value = Store.value<ColorModel>(context);
    super.build(context);
    return Scaffold(
      body: values.length == 0
          ? Container()
          : ListView.builder(
              itemCount: keys.length,
              itemBuilder: (BuildContext context, int index) {
                return item(keys[index], values[index]);
              },
            ),
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}

class FullGoodBook extends StatelessWidget {
  String title;
  List<GBook> bks;

  FullGoodBook(this.title, this.bks);

  @override
  Widget build(BuildContext context) {
    Widget img(GBook gbk) {
      return Container(
        child: Column(
          children: <Widget>[
            GestureDetector(
              child: PicWidget(
                gbk.cover,
                fitOk: true,
              ),
              onTap: () async {
                String url = Common.detail + '/${gbk.id}';
                Response future = await Util(context).http().get(url);
                var d = future.data['data'];
                BookInfo bookInfo = BookInfo.fromJson(d);
                Navigator.pushAndRemoveUntil(
                  context,
                  new MaterialPageRoute(builder: (context) => new BookDetail(bookInfo)),
                      (route) => route == null,
                );
              },
            ),
            Text(
              gbk.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          ],
        ),
      );
    }

    // TODO: implement build
    return Store.connect<ColorModel>(
        builder: (context, ColorModel data, child) => Theme(
              data: data.theme,
              child: Scaffold(
                  appBar: AppBar(
                    title: Text(title),
                    centerTitle: true,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                  ),
                  body: ListView(
                    children: <Widget>[
                      GridView(
                        shrinkWrap: true,
                        physics: new NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.all(5.0),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 1.0,
                            crossAxisSpacing: 10.0,
                            childAspectRatio: 0.6),
                        children: bks.map((item) => img(item)).toList(),
                      )
                    ],
                  )),
            ));
  }
}
