import 'package:book/entity/BookInfo.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/store/Store.dart';
import 'package:flutter/material.dart';

class SliverAppBarDemo extends StatefulWidget {
  BookInfo _bookInfo;
  SliverAppBarDemo(this._bookInfo);
  @override
  _SliverAppBarDemoState createState() => _SliverAppBarDemoState();
}

class _SliverAppBarDemoState extends State<SliverAppBarDemo> {
  ColorModel _colorModel;
  @override
  void initState() {
    super.initState();
    _colorModel=Store.value<ColorModel>(context);

  }
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverAppBar(
            backgroundColor: Colors.transparent,
          leading: IconButton(
            color: _colorModel.dark ? Colors.white : Colors.black,
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          elevation: 0,
          actions: <Widget>[
            GestureDetector(
              child: Center(
                child: Text(
                  '书架',
                  style: TextStyle(
                    color: _colorModel.dark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              onTap: () {
                Navigator.of(context).popUntil(ModalRoute.withName('/'));
                eventBus.fire(new NavEvent(0));
              },
            ),
            SizedBox(
              width: 20,
            )
          ],
        
          pinned: true,
          expandedHeight: 200.0,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(this.widget._bookInfo.Name),
            background: Image(image: AssetImage("images/QR_bg_3.jpg"),fit: BoxFit.cover,),
          ),
        ),
        SliverFixedExtentList(
          itemExtent: 80.0,
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              return Card(
                child: Container(
                  alignment: Alignment.center,
                  color: Colors.primaries[(index % 18)],
                  child: Text(''),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
