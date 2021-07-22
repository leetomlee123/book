// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:book/common/Http.dart';

Future<void> main() async {
  var msg = '''
  {
  "方正新楷体": "https://oss-asq-download.11222.cn/font/package/FZXKTK.TTF",
  "方正稚艺": "http://oss-asq-download.11222.cn/font/package/FZZHYK.TTF",
  "方正魏碑": "http://oss-asq-download.11222.cn/font/package/FZWBK.TTF",
  "方正苏新诗柳楷": "https://oss-asq-download.11222.cn/font/package/FZSXSLKJW.TTF",
  "方正宋刻本秀楷体": "https://oss-asq-download.11222.cn/font/package/FZSKBXKK.TTF",
  "方正卡通": "http://oss-asq-download.11222.cn/font/package/FZKATK.TTF"
}
  ''';

  List msg1 = await parseJson(msg);

  msg1.forEach((element) {
    print(element);
  });

//  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
//    // Build our app and trigger a frame.
//    await tester.pumpWidget(MyApp());
//
//    // Verify that our counter starts at 0.
//    expect(find.text('0'), findsOneWidget);
//    expect(find.text('1'), findsNothing);
//
//    // Tap the '+' icon and trigger a frame.
//    await tester.tap(find.byIcon(Icons.add));
//    await tester.pump();
//
//    // Verify that our counter has incremented.
//    expect(find.text('0'), findsNothing);
//    expect(find.text('1'), findsOneWidget);
//  });
}
