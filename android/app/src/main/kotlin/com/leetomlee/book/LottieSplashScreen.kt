package com.leetomlee.book

import android.app.Activity
import android.content.Context
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import com.airbnb.lottie.LottieAnimationView
import com.airbnb.lottie.LottieDrawable
import io.flutter.embedding.android.SplashScreen
import kotlin.random.Random

/**
 * A Splash Screen based lottie animation
 * it will pause 1s,then enter the main page
 */
class LottieSplashScreen : SplashScreen{

    private val lottieRawIds = arrayOf(
            R.raw.lottie
    )

    override fun createSplashView(context: Context, savedInstanceState: Bundle?): View? {
        val lottieView = LottieAnimationView(context)
        lottieView.apply {
            repeatMode = LottieDrawable.RESTART
            repeatCount = LottieDrawable.INFINITE
            setAnimation(lottieRawIds[Random(System.currentTimeMillis()).nextInt(0,lottieRawIds.size)])
        }.playAnimation()
        (context as Activity).window.setBackgroundDrawable(ColorDrawable(Color.WHITE))

        val layoutParamsLottie = FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT,ViewGroup.LayoutParams.WRAP_CONTENT)
                .apply {
                    gravity = Gravity.CENTER
                }
        val rootView = FrameLayout(context)
        rootView.apply {
            layoutParams = FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT,ViewGroup.LayoutParams.MATCH_PARENT)
            setBackgroundColor(Color.WHITE)
            addView(lottieView,layoutParamsLottie)
        }
        return rootView
    }

    override fun transitionToFlutter(onTransitionComplete: Runnable) {
        Handler(Looper.getMainLooper()).postDelayed(onTransitionComplete,700)
    }
}