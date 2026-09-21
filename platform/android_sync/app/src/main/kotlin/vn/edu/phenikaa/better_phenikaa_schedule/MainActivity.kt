package vn.edu.phenikaa.better_phenikaa_schedule

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DAILY_SYNC_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "enable" -> {
                    DailySyncScheduler.enable(applicationContext)
                    result.success(null)
                }
                "disable" -> {
                    DailySyncScheduler.disable(applicationContext)
                    result.success(null)
                }
                "status" -> result.success(
                    DailySyncScheduler.status(applicationContext),
                )
                else -> result.notImplemented()
            }
        }
    }

    private companion object {
        const val DAILY_SYNC_CHANNEL = "better_phenikaa/daily_sync"
    }
}
