package kz.ust.ust_mobile_app

import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Кабинеттегі «N MB бос орын бар» үшін
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kz.ust/storage")
            .setMethodCallHandler { call, result ->
                if (call.method == "freeBytes") {
                    result.success(StatFs(filesDir.path).availableBytes)
                } else {
                    result.notImplemented()
                }
            }
    }
}
