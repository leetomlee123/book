import 'package:book/common/DbHelper.dart';
import 'package:book/common/PicWidget.dart';
import 'package:book/entity/MRecords.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:flutter/material.dart';

class MovieRecord extends StatefulWidget {
  @override
  _MovieRecordState createState() => _MovieRecordState();
}

class _MovieRecordState extends State<MovieRecord> {
  List<Widget> wds = [];

  @override
  void initState() {
    init();
    super.initState();
  }

   init() async {
    List<MRecords> mrds = await DbHelper().getMovies();

    for (var i = mrds.length - 1; i >= 0; i--) {
      MRecords value = mrds[i];
      wds.add(GestureDetector(
        child: ListTile(
          leading: PicWidget(
            value.cover,
          ),
          title: Text(
            value.name,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(value.cname),
        ),
        onTap: () {
          Routes.navigateTo(context, Routes.lookVideo, params: {
            "id": value.cid,
            "mcids": value.mcids ?? [],
            "cover": value.cover,
            "name": value.name
          });
        },
      ));
      wds.add(Divider());
    }
    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    var dark=Store.value<ColorModel>(context).dark;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('观看记录',style: TextStyle(color: dark?Colors.white:Colors.black),),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: wds.isEmpty
          ? Center(
              child: Container(
                child: Text("暂无观看记录"),
              ),
            )
          : ListView(
              children: wds,
            ),
    );
  }
}
