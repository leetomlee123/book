

import 'package:book/common/common.dart';
import 'package:book/entity/ParseContentConfig.dart';
import 'package:flustars/flustars.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;

import 'Http.dart';

class ParseHtml {
  List<ParseContentConfig> configs = [];
  ParseHtml() {
    if (configs.isEmpty) {
      configs = SpUtil.getObjectList(Common.parse_html_config)
          .map((e) => ParseContentConfig.fromJson(e))
          .toList();
    }
  }

  Future<String> content(String url) async {
    var c = "";
    var html = await HttpUtil.instance.dio.get(url);

    Element content;
    configs.forEach((element) {
      if (url.contains(element.domain)) {
        content = parse(html.data, encoding: element.encode)
            .getElementById(element.documentId);
      }
    });
    if (content == null) {
      content = parse(html.data).getElementById("content");
    }

    content.nodes.forEach((element) {
      var text = element.text.trim();
      if (text.isNotEmpty) {
        c += "\t\t\t\t\t\t\t\t" + text + "\n";
      }
    });
    return c;
  }

}
