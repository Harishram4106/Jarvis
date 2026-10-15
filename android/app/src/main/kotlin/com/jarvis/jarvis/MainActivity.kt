package com.jarvis.jarvis

import android.content.Intent
import android.provider.AlarmClock
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "com.jarvis/intents"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setTimer" -> {
                        val seconds = call.argument<Int>("seconds") ?: 0
                        val label = call.argument<String>("label") ?: "Timer"
                        val intent = Intent(AlarmClock.ACTION_SET_TIMER).apply {
                            putExtra(AlarmClock.EXTRA_LENGTH, seconds)
                            putExtra(AlarmClock.EXTRA_MESSAGE, label)
                            putExtra(AlarmClock.EXTRA_SKIP_UI, false)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        try {
                            startActivity(intent)
                            result.success("Timer set for $seconds seconds: $label")
                        } catch (e: Exception) {
                            result.success("Could not set timer: ${e.message}")
                        }
                    }
                    "setAlarm" -> {
                        val hour = call.argument<Int>("hour") ?: 0
                        val minute = call.argument<Int>("minute") ?: 0
                        val label = call.argument<String>("label") ?: "Alarm"
                        val intent = Intent(AlarmClock.ACTION_SET_ALARM).apply {
                            putExtra(AlarmClock.EXTRA_HOUR, hour)
                            putExtra(AlarmClock.EXTRA_MINUTES, minute)
                            putExtra(AlarmClock.EXTRA_MESSAGE, label)
                            putExtra(AlarmClock.EXTRA_SKIP_UI, false)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        try {
                            startActivity(intent)
                            result.success("Alarm set for %02d:%02d: $label".format(hour, minute))
                        } catch (e: Exception) {
                            result.success("Could not set alarm: ${e.message}")
                        }
                    }
                    "openApp" -> {
                        val packageName = call.argument<String>("package") ?: ""
                        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
                        if (launchIntent != null) {
                            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(launchIntent)
                            result.success("Opened $packageName")
                        } else {
                            result.success("App not found: $packageName")
                        }
                    }
                    "shareText" -> {
                        val text = call.argument<String>("text") ?: ""
                        val subject = call.argument<String>("subject") ?: ""
                        val intent = Intent(Intent.ACTION_SEND).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TEXT, text)
                            if (subject.isNotEmpty()) putExtra(Intent.EXTRA_SUBJECT, subject)
                        }
                        try {
                            startActivity(Intent.createChooser(intent, "Share conversation"))
                            result.success("ok")
                        } catch (e: Exception) {
                            result.success("Could not share: ${e.message}")
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
