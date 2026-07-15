/// Legado-compatible book source (subset used by M1 engine).
class BookSource {
  String bookSourceUrl;
  String bookSourceName;
  String bookSourceGroup;
  int bookSourceType;
  bool enabled;
  bool enabledExplore;
  String header;
  String searchUrl;
  String exploreUrl;
  int customOrder;
  int weight;
  int lastUpdateTime;
  int respondTime;
  SearchRule ruleSearch;
  BookInfoRule ruleBookInfo;
  TocRule ruleToc;
  ContentRule ruleContent;
  String rawJson;

  BookSource({
    this.bookSourceUrl = '',
    this.bookSourceName = '',
    this.bookSourceGroup = '',
    this.bookSourceType = 0,
    this.enabled = true,
    this.enabledExplore = false,
    this.header = '',
    this.searchUrl = '',
    this.exploreUrl = '',
    this.customOrder = 0,
    this.weight = 0,
    this.lastUpdateTime = 0,
    this.respondTime = 0,
    SearchRule? ruleSearch,
    BookInfoRule? ruleBookInfo,
    TocRule? ruleToc,
    ContentRule? ruleContent,
    this.rawJson = '',
  })  : ruleSearch = ruleSearch ?? SearchRule(),
        ruleBookInfo = ruleBookInfo ?? BookInfoRule(),
        ruleToc = ruleToc ?? TocRule(),
        ruleContent = ruleContent ?? ContentRule();

  factory BookSource.fromLegadoJson(Map<String, dynamic> json) {
    Map<String, dynamic> asMap(dynamic v) {
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return Map<String, dynamic>.from(v);
      return <String, dynamic>{};
    }

    bool asBool(dynamic v, {bool def = true}) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final s = v.toLowerCase();
        if (s == 'true' || s == '1') return true;
        if (s == 'false' || s == '0') return false;
      }
      return def;
    }

    int asInt(dynamic v, {int def = 0}) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? def;
      return def;
    }

    return BookSource(
      bookSourceUrl: (json['bookSourceUrl'] ?? '').toString(),
      bookSourceName: (json['bookSourceName'] ?? '').toString(),
      bookSourceGroup: (json['bookSourceGroup'] ?? '').toString(),
      bookSourceType: asInt(json['bookSourceType']),
      enabled: asBool(json['enabled'], def: true),
      enabledExplore: asBool(json['enabledExplore'], def: false),
      header: (json['header'] ?? '').toString(),
      searchUrl: (json['searchUrl'] ?? '').toString(),
      exploreUrl: (json['exploreUrl'] ?? '').toString(),
      customOrder: asInt(json['customOrder']),
      weight: asInt(json['weight']),
      lastUpdateTime: asInt(json['lastUpdateTime']),
      respondTime: asInt(json['respondTime']),
      ruleSearch: SearchRule.fromJson(asMap(json['ruleSearch'])),
      ruleBookInfo: BookInfoRule.fromJson(asMap(json['ruleBookInfo'])),
      ruleToc: TocRule.fromJson(asMap(json['ruleToc'])),
      ruleContent: ContentRule.fromJson(asMap(json['ruleContent'])),
      rawJson: '',
    );
  }

  Map<String, dynamic> toLegadoJson() {
    return {
      'bookSourceUrl': bookSourceUrl,
      'bookSourceName': bookSourceName,
      'bookSourceGroup': bookSourceGroup,
      'bookSourceType': bookSourceType,
      'enabled': enabled,
      'enabledExplore': enabledExplore,
      'header': header,
      'searchUrl': searchUrl,
      'exploreUrl': exploreUrl,
      'customOrder': customOrder,
      'weight': weight,
      'lastUpdateTime': lastUpdateTime,
      'respondTime': respondTime,
      'ruleSearch': ruleSearch.toJson(),
      'ruleBookInfo': ruleBookInfo.toJson(),
      'ruleToc': ruleToc.toJson(),
      'ruleContent': ruleContent.toJson(),
    };
  }

  BookSource copyWith({
    String? bookSourceUrl,
    String? bookSourceName,
    String? bookSourceGroup,
    int? bookSourceType,
    bool? enabled,
    bool? enabledExplore,
    String? header,
    String? searchUrl,
    String? exploreUrl,
    int? customOrder,
    int? weight,
    int? lastUpdateTime,
    int? respondTime,
    SearchRule? ruleSearch,
    BookInfoRule? ruleBookInfo,
    TocRule? ruleToc,
    ContentRule? ruleContent,
    String? rawJson,
  }) {
    return BookSource(
      bookSourceUrl: bookSourceUrl ?? this.bookSourceUrl,
      bookSourceName: bookSourceName ?? this.bookSourceName,
      bookSourceGroup: bookSourceGroup ?? this.bookSourceGroup,
      bookSourceType: bookSourceType ?? this.bookSourceType,
      enabled: enabled ?? this.enabled,
      enabledExplore: enabledExplore ?? this.enabledExplore,
      header: header ?? this.header,
      searchUrl: searchUrl ?? this.searchUrl,
      exploreUrl: exploreUrl ?? this.exploreUrl,
      customOrder: customOrder ?? this.customOrder,
      weight: weight ?? this.weight,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      respondTime: respondTime ?? this.respondTime,
      ruleSearch: ruleSearch ?? this.ruleSearch,
      ruleBookInfo: ruleBookInfo ?? this.ruleBookInfo,
      ruleToc: ruleToc ?? this.ruleToc,
      ruleContent: ruleContent ?? this.ruleContent,
      rawJson: rawJson ?? this.rawJson,
    );
  }
}

class SearchRule {
  String bookList;
  String name;
  String author;
  String kind;
  String wordCount;
  String lastChapter;
  String intro;
  String coverUrl;
  String bookUrl;
  String checkKeyWord;

  SearchRule({
    this.bookList = '',
    this.name = '',
    this.author = '',
    this.kind = '',
    this.wordCount = '',
    this.lastChapter = '',
    this.intro = '',
    this.coverUrl = '',
    this.bookUrl = '',
    this.checkKeyWord = '',
  });

  factory SearchRule.fromJson(Map<String, dynamic> json) => SearchRule(
        bookList: (json['bookList'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        author: (json['author'] ?? '').toString(),
        kind: (json['kind'] ?? '').toString(),
        wordCount: (json['wordCount'] ?? '').toString(),
        lastChapter: (json['lastChapter'] ?? '').toString(),
        intro: (json['intro'] ?? '').toString(),
        coverUrl: (json['coverUrl'] ?? '').toString(),
        bookUrl: (json['bookUrl'] ?? '').toString(),
        checkKeyWord: (json['checkKeyWord'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'bookList': bookList,
        'name': name,
        'author': author,
        'kind': kind,
        'wordCount': wordCount,
        'lastChapter': lastChapter,
        'intro': intro,
        'coverUrl': coverUrl,
        'bookUrl': bookUrl,
        'checkKeyWord': checkKeyWord,
      };
}

class BookInfoRule {
  String init;
  String name;
  String author;
  String kind;
  String wordCount;
  String lastChapter;
  String intro;
  String coverUrl;
  String tocUrl;
  String canReName;

  BookInfoRule({
    this.init = '',
    this.name = '',
    this.author = '',
    this.kind = '',
    this.wordCount = '',
    this.lastChapter = '',
    this.intro = '',
    this.coverUrl = '',
    this.tocUrl = '',
    this.canReName = '',
  });

  factory BookInfoRule.fromJson(Map<String, dynamic> json) => BookInfoRule(
        init: (json['init'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        author: (json['author'] ?? '').toString(),
        kind: (json['kind'] ?? '').toString(),
        wordCount: (json['wordCount'] ?? '').toString(),
        lastChapter: (json['lastChapter'] ?? '').toString(),
        intro: (json['intro'] ?? '').toString(),
        coverUrl: (json['coverUrl'] ?? '').toString(),
        tocUrl: (json['tocUrl'] ?? '').toString(),
        canReName: (json['canReName'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'init': init,
        'name': name,
        'author': author,
        'kind': kind,
        'wordCount': wordCount,
        'lastChapter': lastChapter,
        'intro': intro,
        'coverUrl': coverUrl,
        'tocUrl': tocUrl,
        'canReName': canReName,
      };
}

class TocRule {
  String chapterList;
  String chapterName;
  String chapterUrl;
  String isVolume;
  String updateTime;
  String nextTocUrl;

  TocRule({
    this.chapterList = '',
    this.chapterName = '',
    this.chapterUrl = '',
    this.isVolume = '',
    this.updateTime = '',
    this.nextTocUrl = '',
  });

  factory TocRule.fromJson(Map<String, dynamic> json) => TocRule(
        chapterList: (json['chapterList'] ?? '').toString(),
        chapterName: (json['chapterName'] ?? '').toString(),
        chapterUrl: (json['chapterUrl'] ?? '').toString(),
        isVolume: (json['isVolume'] ?? '').toString(),
        updateTime: (json['updateTime'] ?? '').toString(),
        nextTocUrl: (json['nextTocUrl'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'chapterList': chapterList,
        'chapterName': chapterName,
        'chapterUrl': chapterUrl,
        'isVolume': isVolume,
        'updateTime': updateTime,
        'nextTocUrl': nextTocUrl,
      };
}

class ContentRule {
  String content;
  String nextContentUrl;
  String sourceRegex;
  String replaceRegex;
  String imageStyle;

  ContentRule({
    this.content = '',
    this.nextContentUrl = '',
    this.sourceRegex = '',
    this.replaceRegex = '',
    this.imageStyle = '',
  });

  factory ContentRule.fromJson(Map<String, dynamic> json) => ContentRule(
        content: (json['content'] ?? '').toString(),
        nextContentUrl: (json['nextContentUrl'] ?? '').toString(),
        sourceRegex: (json['sourceRegex'] ?? '').toString(),
        replaceRegex: (json['replaceRegex'] ?? '').toString(),
        imageStyle: (json['imageStyle'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'content': content,
        'nextContentUrl': nextContentUrl,
        'sourceRegex': sourceRegex,
        'replaceRegex': replaceRegex,
        'imageStyle': imageStyle,
      };
}
