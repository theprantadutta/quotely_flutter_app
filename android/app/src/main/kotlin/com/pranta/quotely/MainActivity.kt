package com.pranta.quotely

import android.content.pm.ActivityInfo
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // The explicit edge-to-edge opt-in, for EVERY Android version. Android
        // 15 forces it on apps targeting SDK 35+, but on 14 and below the app
        // only gets it if we ask. Play Console checks for exactly this call -
        // setDecorFitsSystemWindows(false) does the same job but is not what
        // the scanner recognises, which is what raised "Edge-to-edge may not
        // display for all users" against release 17.
        //
        // androidx.core variant rather than androidx.activity.enableEdgeToEdge()
        // because the latter is an extension on ComponentActivity, and
        // FlutterActivity inherits from plain Activity. core 1.16+ added this
        // Window-based overload for exactly that case.
        //
        // Unlike snake_classic this does NOT hide the status bar: Quotely is a
        // normal app with AppBars, so both system bars stay visible and the
        // content simply draws beneath them.
        WindowCompat.enableEdgeToEdge(window)

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
