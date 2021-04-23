import 'package:book/model/ReadModel.dart';
import 'package:book/store/Store.dart';
import 'package:flutter/material.dart';

class BookScrollView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Store.connect<ReadModel>(builder: (context, ReadModel model, child) {
      return Expanded(
          child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
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
      ));
    });
  }
}
