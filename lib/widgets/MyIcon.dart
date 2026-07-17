import 'package:flutter/material.dart';

class MyIcon extends StatelessWidget {
  final VoidCallback onTap;
  final double size;
  final IconData icon;
  MyIcon(this.icon, this.onTap, {this.size = 25.0});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: size),
      onPressed: onTap,
    );
  }
}
