class ReadPage {
  List<String> pageOffsets;

  String chapterContent;

  String chapterName;

  //滚动翻页 长度
  double height;

  // pre:-1 cur:0 next:1
  int position;

  int get pageCount {
    return pageOffsets.length;
  }
}
