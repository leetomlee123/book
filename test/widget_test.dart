// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:book/common/Http.dart';
import 'package:book/entity/ParseContentConfig.dart';

Future<void> main() async {
  String msg = '''
     [
  {
    "domain": "biquwx",
    "encode": "UTF-8",
    "documentId": "content"
  },
  {
    "domain": "iqb5",
    "encode": "gbk",
    "documentId": "contents"
  },
  {
    "domain": "shizongzui",
    "encode": "",
    "documentId": "BookText"
  }
]
     ''';

  List msg1 = await parseJson(msg);

  List<ParseContentConfig> configs =
      msg1.map((e) => ParseContentConfig.fromJson(e)).toList();

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
