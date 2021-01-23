import 'package:flutter/material.dart';

class CommonWidgetTabBar extends StatefulWidget {
  @override
  _CommonWidgetTabBarState createState() => _CommonWidgetTabBarState();
}

class _CommonWidgetTabBarState extends State<CommonWidgetTabBar> {
  int tabIndex = 0; // 当前选中索引
  @override
  Widget build(BuildContext context) {
    return TabBar(
      onTap: (index) {
        // 每当TabBar 切换更新索引
        setState(() {
          tabIndex = index;
        });
      },
      isScrollable: true,
      // 是否滚动
      unselectedLabelColor: Colors.black54,
      //未选中颜色
      labelColor: Colors.blue,
      //选中颜色
      // labelStyle: TextStyle(fontSize: 20.0),
      // unselectedLabelStyle: TextStyle(fontSize: 16.0),
      tabs: [
        Tab(
            child: Text(
          '男生',
          style: TextStyle(fontSize: tabIndex == 0 ? 20 : 16),
        )),
        Tab(
            child: Text(
          '女生',
          style: TextStyle(fontSize: tabIndex == 0 ? 20 : 16),
        )),
      ],
    );
  }
}
