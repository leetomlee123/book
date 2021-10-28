// import 'dart:io';
//
// import 'package:firebase_admob/firebase_admob.dart';
// import 'package:flutter/material.dart';
//
// const String testDevice = 'YOUR_DEVICE_ID';
//
// class Ad extends StatefulWidget {
//   @override
//   _AdState createState() => _AdState();
// }
//
// class _AdState extends State<Ad> {
//   static const MobileAdTargetingInfo targetingInfo = MobileAdTargetingInfo(
//     testDevices: testDevice != null ? <String>[testDevice] : null,
//     keywords: <String>['foo', 'bar'],
//     contentUrl: 'http://foo.com/bar.html',
//     childDirected: true,
//     nonPersonalizedAds: true,
//   );
//
//   BannerAd _bannerAd;
//   NativeAd _nativeAd;
//   InterstitialAd _interstitialAd;
//   int _coins = 0;
//
//   BannerAd createBannerAd() {
//     return BannerAd(
//       adUnitId: BannerAd.testAdUnitId,
//       size: AdSize.banner,
//       targetingInfo: targetingInfo,
//       listener: (MobileAdEvent event) {
//       },
//     );
//   }
//
//   InterstitialAd createInterstitialAd() {
//     return InterstitialAd(
//       adUnitId: InterstitialAd.testAdUnitId,
//       targetingInfo: targetingInfo,
//       listener: (MobileAdEvent event) {
//       },
//     );
//   }
//
//   NativeAd createNativeAd() {
//     return NativeAd(
//       adUnitId: NativeAd.testAdUnitId,
//       factoryId: 'adFactoryExample',
//       targetingInfo: targetingInfo,
//       listener: (MobileAdEvent event) {
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: const Text('AdMob Plugin example app'),
//         ),
//         body: SingleChildScrollView(
//           child: Center(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               mainAxisSize: MainAxisSize.min,
//               children: <Widget>[
//                 RaisedButton(
//                     child: const Text('SHOW BANNER'),
//                     onPressed: () {
//                       _bannerAd ??= createBannerAd();
//                       _bannerAd
//                         ..load()
//                         ..show();
//                     }),
//                 RaisedButton(
//                     child: const Text('SHOW BANNER WITH OFFSET'),
//                     onPressed: () {
//                       _bannerAd ??= createBannerAd();
//                       _bannerAd
//                         ..load()
//                         ..show(horizontalCenterOffset: -50, anchorOffset: 100);
//                     }),
//                 RaisedButton(
//                     child: const Text('REMOVE BANNER'),
//                     onPressed: () {
//                       _bannerAd?.dispose();
//                       _bannerAd = null;
//                     }),
//                 RaisedButton(
//                   child: const Text('LOAD INTERSTITIAL'),
//                   onPressed: () {
//                     _interstitialAd?.dispose();
//                     _interstitialAd = createInterstitialAd()..load();
//                   },
//                 ),
//                 RaisedButton(
//                   child: const Text('SHOW INTERSTITIAL'),
//                   onPressed: () {
//                     _interstitialAd?.show();
//                   },
//                 ),
//                 RaisedButton(
//                   child: const Text('SHOW NATIVE'),
//                   onPressed: () {
//                     _nativeAd ??= createNativeAd();
//                     _nativeAd
//                       ..load()
//                       ..show(
//                         anchorType: Platform.isAndroid
//                             ? AnchorType.bottom
//                             : AnchorType.top,
//                       );
//                   },
//                 ),
//                 RaisedButton(
//                   child: const Text('REMOVE NATIVE'),
//                   onPressed: () {
//                     _nativeAd?.dispose();
//                     _nativeAd = null;
//                   },
//                 ),
//                 RaisedButton(
//                   child: const Text('LOAD REWARDED VIDEO'),
//                   onPressed: () {
//                     RewardedVideoAd.instance.load(
//                         adUnitId: RewardedVideoAd.testAdUnitId,
//                         targetingInfo: targetingInfo);
//                   },
//                 ),
//                 RaisedButton(
//                   child: const Text('SHOW REWARDED VIDEO'),
//                   onPressed: () {
//                     RewardedVideoAd.instance.show();
//                   },
//                 ),
//                 Text("You have $_coins coins."),
//               ].map((Widget button) {
//                 return Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 16.0),
//                   child: button,
//                 );
//               }).toList(),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   @override
//   void initState() {
//     FirebaseAdMob.instance.initialize(appId: FirebaseAdMob.testAppId);
//     _bannerAd = createBannerAd()..load();
//     RewardedVideoAd.instance.listener =
//         (RewardedVideoAdEvent event, {String rewardType, int rewardAmount}) {
//       if (event == RewardedVideoAdEvent.rewarded) {
//         setState(() {
//           _coins += rewardAmount;
//         });
//       }
//     };
//     super.initState();
//   }
//
//   @override
//   void dispose() {
//     _bannerAd?.dispose();
//     _nativeAd?.dispose();
//     _interstitialAd?.dispose();
//     super.dispose();
//   }
// }
