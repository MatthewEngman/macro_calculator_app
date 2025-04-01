package com.example.macro_calculator

import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Install the splash screen but let Flutter control its removal
        installSplashScreen()
        super.onCreate(savedInstanceState)
    }
}
