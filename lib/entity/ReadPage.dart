class ReadPage {


  List<String> pageOffsets;

  String chapterContent;

  String chapterName;

  double height;

//  String stringAtPageIndex(int index) {
//    return this.chapterContent.substring(
//        index - 1 == -1 ? 0 : pageOffsets[index - 1], pageOffsets[index]);
//  }

  int get pageCount {
    return pageOffsets.length;
  }
}
