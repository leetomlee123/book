import 'package:book/common/local_store.dart';
import 'package:flutter/material.dart';

class LoadingDialog extends Dialog {
  const LoadingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = SpUtil.getBool("dark");
    return Center(
      child: CircularProgressIndicator(
        strokeWidth: 2.0,
        valueColor:
            AlwaysStoppedAnimation(dark ? Colors.white : Colors.black),
      ),
    );
  }
}
