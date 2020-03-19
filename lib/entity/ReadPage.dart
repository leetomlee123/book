class ReadPage {


  List<int> pageOffsets;

  String chapterContent;

  String chapterName;

  String stringAtPageIndex(int index) {
    return this.chapterContent.substring(
        index - 1 == -1 ? 0 : pageOffsets[index - 1], pageOffsets[index]);
  }

  int get pageCount {
    return pageOffsets.length;
  }
}
