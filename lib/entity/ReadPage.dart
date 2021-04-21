import 'package:book/common/text_composition.dart';

class ReadPage {
  int get pageOffsets => textComposition?.pageCount ?? 1;
  TextComposition textComposition;
  String chapterContent;

  String chapterName;

  //滚动翻页 长度
  double height;

  // pre:-1 cur:0 next:1
  int position;
}
