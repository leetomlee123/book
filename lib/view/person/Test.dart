import 'package:book/model/ColorModel.dart';
import 'package:book/store/Store.dart';
import 'package:flutter/material.dart';

class MyPageView extends StatefulWidget {
  @override
  _MyPageViewState createState() => _MyPageViewState();
}

class _MyPageViewState extends State<MyPageView> {
  List<String> items = <String>['1', '2', '3', '4', '5'];

  void _reverse() {
    Store.value<ColorModel>(context).switchModel();
//    setState(() {
//      items = items.reversed.toList();
//    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView.builder(
//          controller: readModel.pageController,
          physics: AlwaysScrollableScrollPhysics(),
          itemBuilder: (BuildContext context, int index) {
            return KeepAlive(data: items[index]);
          },
          //条目个数
          itemCount: items.length,
//          onPageChanged: (idx) => readModel.changeChapter(idx),),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FlatButton(
              onPressed: () => _reverse(),
              child: Text('Reverse items'),
            ),
          ],
        ),
      ),
    );
  }
}

class KeepAlive extends StatefulWidget {
  const KeepAlive({Key key, this.data}) : super(key: key);

  final String data;

  @override
  _KeepAliveState createState() => _KeepAliveState();
}

class _KeepAliveState extends State<KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Center(
      child: Text(widget.data),
    );
  }
}
