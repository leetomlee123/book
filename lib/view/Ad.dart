//import 'package:flutter/material.dart';
//import 'package:flutter_native_admob/flutter_native_admob.dart';
//import 'package:flutter_native_admob/native_admob_controller.dart';
//
//class Ad extends StatefulWidget {
//  @override
//  _AdState createState() => _AdState();
//}
//
//class _AdState extends State<Ad> {
//  static const _adUnitID = "ca-app-pub-6006602100377888/5830679164";
//
//  final _controller = NativeAdmobController();
//
//  @override
//  Widget build(BuildContext context) {
//    return MaterialApp(
//      home: Scaffold(
//        appBar: AppBar(
//          title: const Text('Plugin example app'),
//        ),
//        body: ListView(
//          children: <Widget>[
//            Container(
//              margin: EdgeInsets.only(bottom: 20.0),
//              height: 200.0,
//              color: Colors.green,
//            ),
//            Container(
//              margin: EdgeInsets.only(bottom: 20.0),
//              height: 200.0,
//              color: Colors.green,
//            ),
//            Container(
//              margin: EdgeInsets.only(bottom: 20.0),
//              height: 200.0,
//              color: Colors.green,
//            ),
//            Container(
//              height: 330,
//              padding: EdgeInsets.all(10),
//              margin: EdgeInsets.only(bottom: 20.0),
//              child: NativeAdmob(
//                adUnitID: _adUnitID,
//                controller: _controller,
//              ),
//            ),
//            Container(
//              margin: EdgeInsets.only(bottom: 20.0),
//              height: 200.0,
//              color: Colors.green,
//            ),
//            Container(
//              margin: EdgeInsets.only(bottom: 20.0),
//              height: 200.0,
//              color: Colors.green,
//            ),
//            Container(
//              margin: EdgeInsets.only(bottom: 20.0),
//              height: 200.0,
//              color: Colors.green,
//            ),
//            Container(
//              height: 330,
//              padding: EdgeInsets.all(10),
//              margin: EdgeInsets.only(bottom: 20.0),
//              child: NativeAdmob(
//                adUnitID: _adUnitID,
//                controller: _controller,
//              ),
//            ),
//          ],
//        ),
//      ),
//    );
//  }
//}
