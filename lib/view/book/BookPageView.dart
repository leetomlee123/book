import 'package:book/model/ReadModel.dart';
import 'package:book/store/Store.dart';
import 'package:flutter/material.dart';

class BookPageView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Store.connect<ReadModel>(builder: (context, ReadModel model, child) {
 
      return PageView.builder(
        controller: model.pageController,
        physics: PageScrollPhysics(),
        itemBuilder: (BuildContext context, int position) {
          return model.allContent[position];
        },
        //条目个数
        itemCount: model?.allContent?.length ?? 0,
        onPageChanged: (page) => model.changeChapter(page),
      );
    });
  }
}
