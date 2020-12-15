import 'package:book/common/DbHelper.dart';
import 'package:book/entity/VoiceHs.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class VoiceList extends StatefulWidget {
  @override
  _VoiceListState createState() => _VoiceListState();
}

class _VoiceListState extends State<VoiceList> {
  List<VocieHs> data = [];

  @override
  void initState() {
    super.initState();
    getData();
  }

  getData() async {
    print("nice done");
    // List<String> keys = [];
    data = await DbHelper().voices();
    // for (VocieHs x in temp) {
    //   if (!keys.contains(x.key)) {
    //     data.add(x);
    //     keys.add(x.key);
    //   }
    // }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    ColorModel _colorModel = Store.value<ColorModel>(context);
    return Scaffold(
      // backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "听书记录",
          style: TextStyle(
            color: _colorModel.dark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: data.isEmpty
          ? Container()
          : ListView.builder(
              itemBuilder: (context, i) {
                String cover = data[i].cover;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: cover.isEmpty
                        ? AssetImage("images/bg.png")
                        : CachedNetworkImageProvider(cover),
                  ),
                  title: Text(data[i].title),
                  // dense: true,
                  subtitle: Text(data[i].author ?? ''),
                  trailing: Text(data[i].chapter),
                  // trailing: Text(DateUtil.formatDateMs(data[i].position,
                  //         format: "mm:ss") ??
                  //     '' ),
                  onTap: () {
                    Routes.navigateTo(context, Routes.voiceDetail,
                        params: {
                          "link": data[i].key,
                          "idx": data[i].idx.toString(),
                        },
                        replace: true);
                  },
                );
              },
              itemCount: data.length,
            ),
    );
  }
}
