import 'package:book/common/PicWidget.dart';
import 'package:book/common/app_colors.dart';
import 'package:book/entity/Book.dart';
import 'package:book/store/Store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HasUpdateIconImg extends ConsumerWidget {
  final double width;
  final double height;
  final String type;
  final int idx;

  const HasUpdateIconImg(this.width, this.height, this.type, this.idx, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shelf = ref.watch(shelfModelProvider);
    if (shelf.shelf.isEmpty || idx >= shelf.shelf.length) {
      return SizedBox(width: width, height: height);
    }
    final Book book = shelf.shelf.elementAt(idx);
    final hasUpdate = book.hasUpdate == 1;
    final sorting = type == 'sort';
    final picked = sorting && shelf.picks(idx);

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: PicWidget(book.coverUrl, height: height, width: width),
          ),
          // 更新角标
          if (hasUpdate)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: const BoxDecoration(
                  color: AppColors.updateBadge,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
                child: const Text(
                  '更新',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          // 整理模式勾选
          if (sorting)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: picked ? AppColors.brand : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: picked ? AppColors.brand : Colors.white70,
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: picked
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
