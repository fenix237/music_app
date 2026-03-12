package com.example.music_app  // Adaptez à votre package

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.ryanheise.audioservice.AudioServiceActivity  

class MainActivity: AudioServiceActivity() {  
  @Override
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine) 
  }
}
