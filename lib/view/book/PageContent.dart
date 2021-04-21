import 'package:book/common/Screen.dart';
import 'package:book/common/text_composition.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/ReadModel.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/book/Menu.dart';
import 'package:book/view/system/BatteryView.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';

class PageContentView extends StatelessWidget {
  final List<String> bgImg = [
    "QR_bg_1.jpg",
    "QR_bg_2.jpg",
    "QR_bg_3.jpg",
    "QR_bg_5.jpg",
    "QR_bg_7.png",
    "QR_bg_8.png",
    "QR_bg_4.jpg",
  ];
  final TextComposition textComposition;

  PageContentView({this.textComposition, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ColorModel colorModel = Store.value<ColorModel>(context);
    return Store.connect<ReadModel>(builder: (context, ReadModel model, child) {
      return Stack(
        children: <Widget>[
          //背景
          Positioned(
              left: 0,
              top: 0,
              right: 0,
              bottom: 0,
              child: Image.asset(
                  Store.value<ColorModel>(context).dark
                      ? 'images/QR_bg_4.jpg'
                      : "images/${bgImg[model?.bgIdx ?? 0]}",
                  fit: BoxFit.cover)),
          //内容
          GestureDetector(
            child: model.isPage
                ? NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification notification) {
                      if (notification.depth == 0 &&
                          notification is ScrollEndNotification) {
                        final PageMetrics metrics = notification.metrics;
                        final int currentPage = metrics.page.round();
                        model.changeChapter(currentPage);
                      }
                      return false;
                    },
                    child: PageView.builder(
                      controller: model.pageController,
                      physics: AlwaysScrollableScrollPhysics(),
                      itemBuilder: (BuildContext context, int position) {
                        return model.allContent[position];
                      },
                      //条目个数
                      itemCount: model.allContent.length,
                    ),
                  )
                : Container(
                    width: Screen.width,
                    height: Screen.height,
                    child: Column(
                      children: [
                        SizedBox(
                          height: model.topSafeHeight,
                        ),
                        Container(
                          height: 30,
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.only(left: 20),
                          child: Text(
                            model.readPages[model.cursor].chapterName,
                            style: TextStyle(
                              fontSize: 12 / Screen.textScaleFactor,
                              color: colorModel.dark
                                  ? Color(0x8FFFFFFF)
                                  : Colors.black54,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                            width: Screen.width,
                            height: model.contentH,
                            child: NotificationListener<ScrollNotification>(
                              onNotification:
                                  (ScrollNotification notification) {
                                if (notification.depth == 0 &&
                                    notification is ScrollEndNotification) {
                                  model.notifyOffset();
                                }
                                return false;
                              },
                              child: SingleChildScrollView(
                                child: Column(
                                  children: model.allContent,
                                ),
                                controller: model.listController,
                              ),
                            )
                            // child: ListView.builder(
                            //   itemCount: model.readPages.length,
                            //   itemBuilder: (BuildContext context, int index) {
                            //     return model.allContent[index];
                            //   },
                            //   controller: model.listController,
                            //   cacheExtent:
                            //       model.readPages[model.cursor].height,
                            // ),
                            ),
                        Store.connect<ReadModel>(
                            builder: (context, ReadModel _readModel, child) {
                          return Container(
                            height: 30,
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: <Widget>[
                                BatteryView(
                                  electricQuantity: _readModel.electricQuantity,
                                ),
                                SizedBox(
                                  width: 4,
                                ),
                                Text(
                                  '${DateUtil.formatDate(DateTime.now(), format: DateFormats.h_m)}',
                                  style: TextStyle(
                                    fontSize: 12 / Screen.textScaleFactor,
                                    color: colorModel.dark
                                        ? Color(0x8FFFFFFF)
                                        : Colors.black54,
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  '${_readModel.percent.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 12 / Screen.textScaleFactor,
                                    color: colorModel.dark
                                        ? Color(0x8FFFFFFF)
                                        : Colors.black54,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                // Expanded(child: Container()),
                              ],
                            ),
                          );
                        }),
                      ],
                    )),
            onTapDown: (TapDownDetails details) =>
                model.tapPage(context, details),
          ),
          //菜单
          Offstage(offstage: !model.showMenu, child: Menu()),
        ],
      );
    });
  }
}
