import 'dart:async';

import 'package:book/common/app_colors.dart';
import 'package:book/event/event.dart';
import 'package:book/view/book/book_shelf.dart';
import 'package:book/view/book/explore_page.dart';
import 'package:book/view/person/Me.dart';
import 'package:flutter/material.dart';

/// App root shell: 书架 / 发现 / 我 (WeChat Reading–like bottom tabs).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  StreamSubscription<NavEvent>? _navSub;

  @override
  void initState() {
    super.initState();
    _navSub = eventBus.on<NavEvent>().listen((e) {
      final i = e.idx.clamp(0, 2);
      if (mounted && i != _index) {
        setState(() => _index = i);
      }
    });
  }

  @override
  void dispose() {
    _navSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          BookShelf(),
          const ExplorePage(),
          Me(embedded: true),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: dark ? AppColors.surfaceDark : AppColors.surface,
          border: Border(
            top: BorderSide(
              color: dark ? AppColors.dividerDark : AppColors.divider,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: AppDimens.bottomNavHeight,
            child: BottomNavigationBar(
              currentIndex: _index,
              onTap: (i) => setState(() => _index = i),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu_book_outlined),
                  activeIcon: Icon(Icons.menu_book),
                  label: '书架',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.explore_outlined),
                  activeIcon: Icon(Icons.explore),
                  label: '发现',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: '我',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
