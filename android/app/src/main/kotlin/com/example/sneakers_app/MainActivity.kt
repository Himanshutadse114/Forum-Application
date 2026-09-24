package com.example.sneakers_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "app.channel.shared.data"
    private var sharedText: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Read shared URL from the launching intent (app was opened via Share)
        handleIntent(intent)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSharedText" -> {
                        result.success(sharedText)
                        sharedText = null // clear after reading so it doesn't re-trigger
                    }
                    "getApkPath" -> {
                        val packageName = call.argument<String>("packageName")
                        if (packageName != null) {
                            try {
                                val appInfo = packageManager.getApplicationInfo(packageName, 0)
                                result.success(appInfo.publicSourceDir)
                            } catch (e: Exception) {
                                result.error("UNAVAILABLE", "Could not get APK path: ${e.message}", null)
                            }
                        } else {
                            result.error("BAD_ARGUMENT", "Package name is null", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // Register BroadcastReceiver dynamically to detect new app installs
        val packageFilter = IntentFilter().apply {
            addAction(Intent.ACTION_PACKAGE_ADDED)
            addDataScheme("package")
        }

        val packageReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (intent.action == Intent.ACTION_PACKAGE_ADDED) {
                    val packageName = intent.data?.schemeSpecificPart
                    if (packageName != null) {
                        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                            .invokeMethod("packageAdded", packageName)
                    }
                }
            }
        }
        registerReceiver(packageReceiver, packageFilter)
    }

    // Called when app is already running and user shares to it again
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)

        // Notify Flutter of the new shared URL via MethodChannel
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, CHANNEL).invokeMethod("sharedTextReceived", sharedText)
        }
    }

    private fun handleIntent(intent: Intent?) {
        if (intent?.action == Intent.ACTION_SEND && intent.type == "text/plain") {
            sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
        } else if (intent?.action == Intent.ACTION_VIEW) {
            sharedText = intent.dataString
        }
    }
}
