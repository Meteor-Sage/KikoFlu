package com.meteor.kikoeruflutter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity() {
    private var floatingLyricPlugin: FloatingLyricPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 注册悬浮歌词插件
        floatingLyricPlugin = FloatingLyricPlugin(this)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            FloatingLyricPlugin.CHANNEL
        ).setMethodCallHandler(floatingLyricPlugin)
    }

    override fun onDestroy() {
        // 清理悬浮窗资源
        floatingLyricPlugin?.cleanup()
        super.onDestroy()
    }
}
