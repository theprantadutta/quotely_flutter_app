package com.pranta.quotely

import android.content.pm.ActivityInfo
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Phones stay portrait; tablets (sw600dp+) rotate freely. Set before
        // super.onCreate so the launch theme never draws in a wrong orientation.
        requestedOrientation =
            if (resources.configuration.smallestScreenWidthDp >= 600)
                ActivityInfo.SCREEN_ORIENTATION_FULL_USER
            else
                ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
        super.onCreate(savedInstanceState)
    }
}
