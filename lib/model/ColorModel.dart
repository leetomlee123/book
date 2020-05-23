import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ColorModel with ChangeNotifier {
  bool dark = false;

  List<Color> skins = Colors.accents;

  int idx = SpUtil.getInt('skin');
  ThemeData _theme;

  ThemeData get theme {
    if (SpUtil.haveKey("dark")) {
      dark = SpUtil.getBool("dark");
    }
    _theme = dark
        ? ThemeData.dark().copyWith(
            textTheme: TextTheme(body1: TextStyle(color: Color(0xFFB8B8B8))))
        : ThemeData.light().copyWith(primaryColor: skins[idx]);
    return _theme;
  }

  getSkins(w, h) {
    List<Widget> wds = [];
    for (var i = 0; i < skins.length; i++) {
      wds.add(GestureDetector(
        child: Container(
          width: w,
          height: h,
          child: Stack(
            children: <Widget>[
              Container(
                color: skins[i],
              ),
              i == idx
                  ? Align(
                      alignment: Alignment.topRight,
                      child: ImageIcon(
                        AssetImage('images/pick.png'),
                        color: Colors.white,
                      ),
                    )
                  : Container()
            ],
          ),
        ),
        onTap: () {
          idx = i;
          notifyListeners();
          SpUtil.putInt('skin', idx);
        },
      ));
    }
    return wds;
  }

  switchModel() {
    if (dark) {
      _theme = ThemeData.dark();
    } else {
      _theme = ThemeData.light().copyWith(primaryColor: skins[idx]);
    }
    dark = !dark;
    SpUtil.putBool("dark", dark);
    notifyListeners();
  }
}
