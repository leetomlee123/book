import 'dart:convert';

import 'package:book/common/Http.dart';
import 'package:book/common/ReadSetting.dart';
import 'package:book/common/Screen.dart';
import 'package:book/common/common.dart';
import 'package:book/entity/BookInfo.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/ReadModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/system/MenuConfig.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Menu extends StatefulWidget {
  @override
  _MenuState createState() => _MenuState();
}

enum Type { SLIDE, MORE_SETTING, DOWNLOAD }

class _MenuState extends State<Menu> {
  Type type = Type.SLIDE;
  ReadModel _readModel;
  ColorModel _colorModel;

  double settingH = 320;

  @override
  void initState() {
    super.initState();
    _readModel = Store.value<ReadModel>(context);
    _colorModel = Store.value<ColorModel>(context);
  }

  Widget head() {
    return Container(
      color: _colorModel.dark ? Colors.black : Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 15.0),
      child: Row(
        children: [
          Text(
            '${_readModel?.book?.Name ?? ""}',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 22),
          ),
          // Spacer(),
          Expanded(
            child: Container(),
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _readModel.reloadCurrentPage();
            },
          ),
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () async {
              _readModel.saveData();
              _readModel.clear();
              String url = Common.detail + '/${_readModel.book.Id}';
              Response future =
                  await HttpUtil(showLoading: true).http().get(url);
              var d = future.data['data'];
              BookInfo bookInfo = BookInfo.fromJson(d);

              Routes.navigateTo(context, Routes.detail,
                  params: {"detail": jsonEncode(bookInfo)});
            },
          )
        ],
      ),
    );
  }

  Widget midTransparent() {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.transparent,
          width: double.infinity,
        ),
        onTap: () {
          type = Type.SLIDE;
          _readModel.toggleShowMenu();
          // if (_readModel.font) {
          //   _readModel.reCalcPages();
          // }
        },
      ),
    );
  }

  Widget chapterSlide() {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
        child: Row(
          children: <Widget>[
            GestureDetector(
              child: Container(child: Text('上一章')),
              onTap: () async {
                if ((_readModel.book.cur - 1) < 0) {
                  BotToast.showText(text: '已经是第一章');
                  return;
                }
                _readModel.book.cur -= 1;
                await _readModel.initPageContent(_readModel.book.cur, true);
                BotToast.showText(text: _readModel.curPage.chapterName);
              },
            ),
            Expanded(
              child: Container(
                child: Slider(
                  // activeColor: Colors.white,
                  // inactiveColor: Colors.white70,
                  value: _readModel.book.cur.toDouble(),
                  max: (_readModel.chapters.length - 1).toDouble(),
                  min: 0.0,
                  onChanged: (newValue) {
                    int temp = newValue.round();
                    _readModel.book.cur = temp;

                    _readModel.initPageContent(_readModel.book.cur, true);
                  },
                  label: '${_readModel.chapters[_readModel.book.cur].name} ',
                  semanticFormatterCallback: (newValue) {
                    return '${newValue.round()} dollars';
                  },
                ),
              ),
            ),
            GestureDetector(
              child: Container(child: Text('下一章')),
              onTap: () async {
                if ((_readModel.book.cur + 1) >= _readModel.chapters.length) {
                  BotToast.showText(text: "已经是最后一章");
                  return;
                }
                _readModel.book.cur += 1;

                await _readModel.initPageContent(_readModel.book.cur, true);
                BotToast.showText(text: _readModel.curPage.chapterName);
              },
            ),
          ],
        ));
  }

  Widget operate(Widget child, func) {
    return Container(
      decoration:
          BoxDecoration(color: _colorModel.dark ? Colors.black : Colors.white),
      height: 40,
      width: Screen.width / 4,
      padding: EdgeInsets.only(top: 18, bottom: 15),
      child: GestureDetector(
        onTap: func,
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(25.0)),
              border: Border.all(
                width: 1,
                color: _colorModel.dark ? Colors.white : Colors.black,
              )),
          alignment: Alignment(0, 0),
          child: child,
        ),
      ),
    );
  }

  Widget downloadWidget() {
    return Container(
      decoration: BoxDecoration(
        color: _colorModel.dark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
      ),
      height: 70,
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                      color: _colorModel.dark ? Colors.black : Colors.white),
                  height: 40,
                  width: (Screen.width - 40) / 2,
                  margin: EdgeInsets.only(top: 15, bottom: 15),
                  child: GestureDetector(
                    onTap: () {
                      BotToast.showText(text: '从当前章节开始下载...');

                      _readModel.downloadAll(_readModel.book.cur);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(20.0)),
                          border: Border.all(
                            width: 1,
                            color:
                                _colorModel.dark ? Colors.white : Colors.black,
                          )),
                      alignment: Alignment(0, 0),
                      child: Text(
                        '从当前章节缓存',
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 20,
                ),
                Container(
                  decoration: BoxDecoration(
                      color: _colorModel.dark ? Colors.black : Colors.white),
                  height: 40,
                  width: (Screen.width - 40) / 2,
                  margin: EdgeInsets.only(top: 15, bottom: 15),
                  child: GestureDetector(
                    onTap: () {
                      BotToast.showText(text: '开始全本下载...');

                      _readModel.downloadAll(0);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(25.0)),
                          border: Border.all(
                            width: 1,
                            color:
                                _colorModel.dark ? Colors.white : Colors.black,
                          )),
                      alignment: Alignment(0, 0),
                      child: Text(
                        '全本缓存',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      padding: EdgeInsets.only(left: 15.0),
    );
  }

  Widget moreSetting() {
    return Container(
      decoration: BoxDecoration(
        color: _colorModel.dark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
      ),
      height: settingH,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextButton(
              onPressed: () {
                Routes.navigateTo(context, Routes.fontSet);
              },
              child: Text('字体')),
          MenuConfig(
            () {
              ReadSetting.calcFontSize(-1);
              _readModel.modifyFont();
            },
            () {
              ReadSetting.calcFontSize(1);
              _readModel.modifyFont();
            },
            (v) {
              ReadSetting.setFontSize(v);
              _readModel.modifyFont();
            },
            ReadSetting.getFontSize(),
            "字号",
            min: 10,
            max: 40,
          ),

          Row(
            children: [
              Text("行距", style: TextStyle(fontSize: 13.0)),
              IconButton(
                onPressed: () {
                  ReadSetting.subLineHeight();
                  _readModel.modifyFont();
                },
                icon: Icon(Icons.remove),
              ),
              Slider.adaptive(
                value: ReadSetting.getLineHeight(),
                onChanged: (v) {
                  ReadSetting.setLineHeight(v);
                  _readModel.modifyFont();
                },
                min: .1,
                max: 4.0,
              ),
              IconButton(
                onPressed: () {
                  ReadSetting.addLineHeight();
                  _readModel.modifyFont();
                },
                icon: Icon(Icons.add),
              ),
              Text('${ReadSetting.getLineHeight().toStringAsFixed(1)}')
            ],
          ),

          // Row(
          //   children: [
          //     Text("词距", style: TextStyle(fontSize: 13.0)),
          //     IconButton(
          //       onPressed: () {
          //         ReadSetting.subLatterSpace();
          //         _readModel.modifyFont();
          //       },
          //       icon: Icon(Icons.remove),
          //     ),
          //     Slider.adaptive(
          //       value: ReadSetting.getLatterSpace(),
          //       onChanged: (v) {
          //         ReadSetting.setLatterSpace(v);
          //         _readModel.modifyFont();
          //       },
          //       min: -5,
          //       max: 20.0,
          //     ),
          //     IconButton(
          //       onPressed: () {
          //         ReadSetting.addLatterSpace();
          //         _readModel.modifyFont();
          //       },
          //       icon: Icon(Icons.add),
          //     ),
          //     Text('${ReadSetting.getLatterSpace().toStringAsFixed(1)}')
          //   ],
          // ),

          Row(
            children: [
              Text("段距", style: TextStyle(fontSize: 13.0)),
              IconButton(
                onPressed: () {
                  ReadSetting.subParagraph();
                  _readModel.modifyFont();
                },
                icon: Icon(Icons.remove),
              ),
              Slider.adaptive(
                value: ReadSetting.getParagraph(),
                onChanged: (v) {
                  ReadSetting.setParagraph(v);
                  _readModel.modifyFont();
                },
                min: .1,
                max: 2.0,
              ),
              IconButton(
                onPressed: () {
                  ReadSetting.addParagraph();
                  _readModel.modifyFont();
                },
                icon: Icon(Icons.add),
              ),
              Text('${ReadSetting.getParagraph().toStringAsFixed(1)}')
            ],
          ),

          Expanded(
              child: ListView(
            children: bgThemes(),
            scrollDirection: Axis.horizontal,
          )),
          // Expanded(
          //   child: flipType(),
          // ),
          SwitchListTile(
            contentPadding: EdgeInsets.only(left: 15),
            value: _readModel.leftClickNext,
            onChanged: (value) {
              _readModel.switchClickNextPage();
            },
            title: Text(
              '左侧点击下一页',
              style: TextStyle(
                  fontSize: 13,
                  color: _colorModel.dark ? Colors.white : Colors.black),
            ),
            selected: _readModel.leftClickNext,
          ),
        ],
      ),
      padding: EdgeInsets.only(left: 15.0),
    );
  }

  Widget flipType() {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: <Widget>[
        Container(
          child: Center(
            child: Text('翻页', style: TextStyle(fontSize: 13.0)),
          ),
          height: 40,
          width: 40,
        ),
        SizedBox(
          width: 10,
        ),
        operate(Text("上下"), () {
          // _readModel.switchFlipType(FlipType.LIST_VIEW);
        }),
        SizedBox(
          width: 10,
        ),
        operate(Text("平滑"), () {
          // _readModel.switchFlipType(FlipType.PAGE_VIEW_SMOOTH);
        }),
      ],
    );
  }

  Widget bottomHead() {
    switch (type) {
      case Type.MORE_SETTING:
        return moreSetting();
        break;
      case Type.DOWNLOAD:
        return downloadWidget();
        break;
      default:
        return chapterSlide();
    }
  }

  Widget bottom() {
    return Container(
      decoration: BoxDecoration(
        color: _colorModel.dark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
      ),
      // height: 140,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[bottomHead(), buildBottomMenus()],
      ),
    );
  }

  Widget reloadCurChapterWidget() {
    return GestureDetector(
      child: Container(
        width: 50,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: Colors.grey, borderRadius: BorderRadius.circular(25)),
        child: Icon(
          Icons.refresh,
          color: Colors.white,
        ),
      ),
      onTap: () {
        _readModel.reloadCurrentPage();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          child: Container(
            child: Column(
              children: <Widget>[
                // Container(
                //   color: _colorModel.dark ? Colors.black : Colors.white,
                //   height: Screen.topSafeHeight,
                // ),
                midTransparent(),
                bottom(),
              ],
            ),
          ),
          onTap: () {
            _readModel.toggleShowMenu();
          },
        ),
        // head(),
        Positioned(
          child: reloadCurChapterWidget(),
          bottom: settingH + 100,
          right: 20,
        ),
      ],
    );
  }

  buildBottomMenus() {
    return Theme(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          buildBottomItem('目录', Icons.menu),
          GestureDetector(
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: ScreenUtil.getScreenW(context) / 4,
                padding: EdgeInsets.symmetric(vertical: 7),
                child: Column(
                  children: <Widget>[
                    ImageIcon(
                      _colorModel.dark
                          ? AssetImage("images/sun.png")
                          : AssetImage("images/moon.png"),
                      // color: Colors.white,
                    ),
                    SizedBox(height: 5),
                    Text(_colorModel.dark ? '日间' : '夜间',
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              onTap: () async {
                Store.value<ColorModel>(context).switchModel();
                await _readModel.colorModelSwitch();
              }),
          buildBottomItem('缓存', Icons.cloud_download),
          buildBottomItem('设置', Icons.settings),
        ],
      ),
      data: _colorModel.theme,
    );
  }

  buildBottomItem(String title, IconData iconData) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: ScreenUtil.getScreenW(context) / 4,
        padding: EdgeInsets.symmetric(vertical: 7),
        child: Column(
          children: <Widget>[
            Icon(
              iconData,
              // color: Colors.white,
            ),
            SizedBox(height: 5),
            Text(title, style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
      onTap: () {
        switch (title) {
          case '目录':
            {
              eventBus.fire(OpenChapters("dd"));
              // Routes.navigateTo(context, Routes.chapters,replace: true);
              _readModel.toggleShowMenu();
            }
            break;
          case '缓存':
            {
              setState(() {
                if (type == Type.DOWNLOAD) {
                  type = Type.SLIDE;
                } else {
                  type = Type.DOWNLOAD;
                }
              });
            }
            break;
          case '设置':
            {
              setState(() {
                if (type == Type.MORE_SETTING) {
                  type = Type.SLIDE;
                } else {
                  type = Type.MORE_SETTING;
                }
              });
            }
            break;
        }
      },
    );
  }

  List<Widget> bgThemes() {
    List<Widget> wds = [];
    wds.add(
      Center(
        child: Text(
          '背景',
          style: TextStyle(fontSize: 13.0),
        ),
      ),
    );
    wds.add(RawMaterialButton(
      constraints: BoxConstraints(minWidth: 60.0, minHeight: 50.0),
      onPressed: () async {
        final PickedFile pickedFile =
            await ImagePicker().getImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          String path = pickedFile.path;

          SpUtil.putString(ReadSetting.bgsKey, path);

          var cv = Store.value<ColorModel>(context);
          if (cv.dark) {
            cv.switchModel();
          }
          await _readModel.colorModelSwitch();
          _readModel.switchBgColor(6);
        }
      },
      child: Container(
        margin: EdgeInsets.only(top: 5.0, bottom: 5.0),
        width: 45.0,
        height: 45.0,
        child: Center(child: Text('自')),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(25.0)),
            border: Border.all(
              width: 1.5,
              color: Color(!_colorModel.dark ? 0x4D000000 : 0xFBFFFFFF),
            )),
      ),
    ));
    for (int i = 0; i < ReadSetting.bgImg.length; i++) {
      var f = "images/${ReadSetting.bgImg[i]}";
      wds.add(RawMaterialButton(
        onPressed: () async {
          var cv = Store.value<ColorModel>(context);
          if (cv.dark) {
            cv.switchModel();
          }
          await _readModel.colorModelSwitch();
          _readModel.switchBgColor(i);
        },
        constraints: BoxConstraints(minWidth: 60.0, minHeight: 50.0),
        child: Container(
            margin: EdgeInsets.only(top: 5.0, bottom: 5.0),
            width: 45.0,
            height: 45.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(25.0)),
              border: Border.all(
                  width: 1.5,
                  color: _readModel.bgIdx == i
                      ? _colorModel.theme.primaryColor
                      : Colors.white10),
              image: DecorationImage(
                image: AssetImage(f),
                fit: BoxFit.cover,
              ),
            )),
      ));
    }
    wds.add(SizedBox(
      height: 8,
    ));
    return wds;
  }
}
