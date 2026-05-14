package com.mobilerelay.mobile_relay

import android.os.Build
import android.telephony.SmsManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val SMS_CHANNEL = "com.mobilerelay.app/sms"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sendSms" -> {
                        val phone = call.argument<String>("phone")
                        val message = call.argument<String>("message")

                        if (phone.isNullOrBlank() || message.isNullOrBlank()) {
                            result.error("INVALID_ARGS", "phone and message are required", null)
                            return@setMethodCallHandler
                        }

                        try {
                            val smsManager: SmsManager =
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                    applicationContext.getSystemService(SmsManager::class.java)
                                } else {
                                    @Suppress("DEPRECATION")
                                    SmsManager.getDefault()
                                }

                            // Automatically split into multipart if message exceeds 160 chars
                            val parts = smsManager.divideMessage(message)
                            if (parts.size == 1) {
                                smsManager.sendTextMessage(phone, null, message, null, null)
                            } else {
                                smsManager.sendMultipartTextMessage(phone, null, parts, null, null)
                            }

                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SMS_FAILED", e.message ?: "Unknown error", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
