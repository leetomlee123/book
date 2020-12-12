import 'package:book/common/DbHelper.dart';
import 'package:book/entity/VoiceHs.dart';
import 'package:book/route/Routes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class VoiceList extends StatefulWidget {
  @override
  _VoiceListState createState() => _VoiceListState();
}

class _VoiceListState extends State<VoiceList>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  List<VocieHs> data = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    getData();
  }

  getData() async {
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
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        child: InkWell(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 15),
            // decoration: BoxDecoration(
            //     borderRadius: BorderRadius.all(Radius.circular(25.0)),
            //     border: Border.all(
            //       width: 1,
            //       // color: _colorModel.dark ? Colors.white : Colors.black,
            //     )),
          ),
          onTap: () {
            print('search');
          },
        ),
        preferredSize: Size.fromHeight(10.0),
        // preferredSize: Size.fromHeight(45.0),
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
                    Routes.navigateTo(context, Routes.voiceDetail, params: {
                      "link": data[i].key,
                      "idx": data[i].idx.toString(),
                      // "position": data[i].position
                    });
                  },
                );
              },
              itemCount: data.length,
            ),
    );
  }
}
