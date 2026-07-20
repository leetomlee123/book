import 'package:book/store/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Skin extends ConsumerWidget {
  const Skin({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(colorModelProvider);
    return Theme(
      data: data.theme,
      child: Scaffold(
        appBar: AppBar(
          title: Text("主题切换"),
          centerTitle: true,
        ),
        body: GridView.count(
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 30.0,
          padding: EdgeInsets.all(10.0),
          crossAxisCount: 2,
          childAspectRatio: 2.0,
          children: data.getSkins(),
        ),
      ),
    );
  }
}
