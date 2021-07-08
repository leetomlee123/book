import 'package:book/model/SearchModel.dart';
import 'package:book/store/Store.dart';
import 'package:flutter/material.dart';

class SearchAiItem extends StatelessWidget {
  final double height;
  final Function function;

  const SearchAiItem({Key key, this.height, this.function}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Store.connect<SearchModel>(
        builder: (context, SearchModel searchModel, child) {
      return Material(
        child: ListView.builder(
            padding: EdgeInsets.zero,
            cacheExtent: height,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Icon(Icons.search),
                title: Text(searchModel.bksAi[index].name),
                subtitle: Text(searchModel.bksAi[index].author),
                onTap: () => function(searchModel.bksAi[index].id),
              );
            },
            itemCount: searchModel.bksAi.length),
      );
    });
  }
}
