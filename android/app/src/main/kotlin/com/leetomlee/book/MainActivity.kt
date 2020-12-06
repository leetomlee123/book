package com.leetomlee.book

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.SplashScreen
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    override fun provideSplashScreen(): SplashScreen? {
        return LottieSplashScreen()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
    }

}

