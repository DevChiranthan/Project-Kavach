// MainActivity.kt

package com.chiranthan.project_kavach_app

// --- UPDATE: Add this import ---
import androidx.multidex.MultiDexApplication
// -----------------------------

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

// --- UPDATE: The class declaration should look like this ---
class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }
}

// --- UPDATE: Add this Application class ---
class MainApplication : MultiDexApplication() {
    override fun onCreate() {
        super.onCreate()
    }
}