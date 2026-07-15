import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

class CssAnalyzer {
  static Document parse(String content) => html_parser.parse(content);

  static List<Element> getElements(Document doc, String selector) {
    if (selector.isEmpty) return const [];
    try {
      // Support Jsoup-ish "tag.class:eq(0)" lightly: strip :eq(n)
      final sel = selector.replaceAll(RegExp(r':eq\(\d+\)'), '');
      return doc.querySelectorAll(sel);
    } catch (_) {
      return const [];
    }
  }

  static List<Element> getElementsFrom(Element root, String selector) {
    if (selector.isEmpty) return [root];
    try {
      final sel = selector.replaceAll(RegExp(r':eq\(\d+\)'), '');
      return root.querySelectorAll(sel);
    } catch (_) {
      return const [];
    }
  }

  static String getString(Element el, String selector, String attr) {
    Element target = el;
    if (selector.isNotEmpty) {
      try {
        final sel = selector.replaceAll(RegExp(r':eq\(\d+\)'), '');
        final found = el.querySelector(sel);
        if (found != null) target = found;
        else return '';
      } catch (_) {
        return '';
      }
    }
    return _attr(target, attr);
  }

  static String _attr(Element el, String attr) {
    switch (attr) {
      case '':
      case 'text':
      case 'textNodes':
      case 'ownText':
        return el.text;
      case 'html':
        return el.innerHtml;
      case 'href':
      case 'src':
      case 'value':
      case 'alt':
      case 'title':
      case 'id':
      case 'class':
      case 'content':
        return el.attributes[attr] ?? '';
      default:
        return el.attributes[attr] ?? el.text;
    }
  }
}
