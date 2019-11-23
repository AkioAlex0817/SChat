package com.hmsoft.schat

import android.os.Bundle
import android.view.WindowManager

import io.flutter.app.FlutterActivity
import io.flutter.plugins.GeneratedPluginRegistrant
import android.view.WindowManager.LayoutParams

class MainActivity: FlutterActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    GeneratedPluginRegistrant.registerWith(this)
    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
  }
}
