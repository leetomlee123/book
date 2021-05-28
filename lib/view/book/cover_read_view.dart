import 'dart:async';

import 'package:book/model/ReadModel.dart';
import 'package:book/store/Store.dart';
import 'package:flutter/material.dart';

// class NovelRoteView extends StatelessWidget {
//   final NovelPageProvider provider;
//   final Profile profile;
//   final SearchItem searchItem;

//   const NovelRoteView({Key key, this.profile, this.provider, this.searchItem})
//       : super(key: key);

//   static List<List<InlineSpan>> spans;

//   @override
//   Widget build(BuildContext context) {
//     spans = provider.didUpdateReadSetting(profile)
//         ? provider.updateSpans(NovelPageProvider.buildSpans(
//             context, profile, provider.searchItem, provider.paragraphs))
//         : provider.spans;

//     return NovelDragView(
//       provider: provider,
//       profile: profile,
//       child: Navigator(
//           initialRoute: '/${searchItem.durChapterIndex}',
//           onGenerateRoute: (settings) {
//             WidgetBuilder builder;
//             bool isNext = true;
//             switch (settings.name) {
//               case '/up':
//                 builder = (context) => _CoverPage(owner: this);
//                 isNext = false;
//                 break;
//               default:
//                 builder = (context) => _CoverPage(owner: this);
//                 break;
//             }
//             if (profile.novelPageSwitch == Profile.novelFade) {
//               return FadePageRoute(
//                   builder: builder, milliseconds: 350, isNext: isNext);
//             }
//             if (profile.novelPageSwitch == Profile.novelCover) {
//               return EmptyPageRoute(builder: builder);
//             }
//             return MaterialPageRoute(builder: builder);
//           }),
//     );
//   }
// }

class CoverPage extends StatefulWidget {
  const CoverPage({
    Key key,
  }) : super(key: key);
  @override
  State<StatefulWidget> createState() => _CoverPageState();
}

class _CoverPageState extends State<CoverPage>
    with SingleTickerProviderStateMixin {
  Widget lastPage;
  int lastPageIndex, lastChapterIndex, lastChangeTime;

  AnimationController _controller;
  Animation<double> _animation;

  ReadModel readModel;
  
  @override
  void initState() {
    readModel = Store.value<ReadModel>(context);
    super.initState();
  }

  @override
  void dispose() {
    _controller?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      _controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 3000),
      );
      _animation = CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      );
    }

    bool _isNext = true;
    var _last = lastPage;
    lastPage = buildPage();
    if (_isNext)
      _controller.forward(from: 0.0);
    else
      _controller.forward(from: -1.2);
    return Stack(
      children: [
        Center(
            child: Container(color:Colors.red,child: Text('11111111111111111111111111111111'))),
        SlideTransition(
          position: _animation.drive(
              Tween(begin: Offset(-1.1, 0.0), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.linear))),
          child: Center(child: Container(color:Colors.blue,child: Text('2222222222222222222222222222222222222222'))),
        ),
      ],
    );
  }

  Widget buildPage() {
    // lastPageIndex = readModel.allContent.length-1;
    // lastChapterIndex = owner.searchItem.durChapterIndex;
    return Material(
      elevation: 20,
      child: Text('11111111111111111'),
    );
  }

  int get curChapterIndex => readModel.book.index;
}
