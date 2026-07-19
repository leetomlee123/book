import 'package:book/store/Store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchAiItem extends ConsumerWidget {
  final double height;
  final Function function;

  const SearchAiItem(
      {super.key, required this.height, required this.function});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchModel = ref.watch(searchModelProvider);
    return Material(
      child: ListView.builder(
          padding: EdgeInsets.zero,
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
  }
}
