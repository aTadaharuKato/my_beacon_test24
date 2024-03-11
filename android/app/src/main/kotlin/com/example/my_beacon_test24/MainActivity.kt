package com.katomyapp.my_beacon_test24

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.preference.PreferenceManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity(), MyNativeMsgSender {
    companion object {
    }

    var eventSink : EventChannel.EventSink?  = null
    private var fDestroyed = false

    override fun onCreate(savedInstanceState: Bundle?) {
        Log.i(Const.TAG, "🍙MainActivity#onCreate() BEGIN")
        super.onCreate(savedInstanceState)
        HappyPathManager.curContext = this

        // 通知チャンネルの準備.
        getMyForegroundServiceNotificationChannel();
        getMyRegionNotificationChannel();

        Log.i(Const.TAG, "🍙MainActivity#onCreate() DONE")
    }

    override fun onStart() {
        Log.i(Const.TAG, "🍙MainActivity#onStart() BEGIN, this:$this")
        super.onStart()
        Log.i(Const.TAG, "🍙MainActivity#onStart() DONE")
    }
    override fun onResume() {
        Log.i(Const.TAG, "🍙MainActivity#onResume() BEGIN, this:$this")
        super.onResume()
        Log.i(Const.TAG, "🍙MainActivity#onResume() DONE")
    }
    override fun onPause() {
        Log.i(Const.TAG, "🍙MainActivity#onPause() BEGIN, this:$this")
        super.onPause()
        Log.i(Const.TAG, "🍙MainActivity#onPause() DONE")
    }
    override fun onStop() {
        Log.i(Const.TAG, "🍙MainActivity#onStop() BEGIN, this:$this")
        super.onStop()
        Log.i(Const.TAG, "🍙MainActivity#onStop() DONE")
    }

    override fun onDestroy() {
        Log.i(Const.TAG, "🍙MainActivity#onDestroy() BEGIN, this:$this")
        super.onDestroy()
        fDestroyed = true
        Log.i(Const.TAG, "🍙MainActivity#onDestroy() DONE")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        Log.i(Const.TAG, "🍙MainActivity#configureFlutterEngine() BEGIN")
        super.configureFlutterEngine(flutterEngine)
        val preferences = PreferenceManager.getDefaultSharedPreferences(this)
        HappyPathManager.prepare(this, preferences)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, Const.MY_METHOD_CHAMMEL).setMethodCallHandler { call, result ->
            Log.i(Const.TAG, "🍙ネイティブメソッド呼出ハンドラ, method=${call.method} BEGIN")
            try {
                when (call.method) {
                    /*
                    "create_dummy_data" -> {
                        val jsonstr = call.arguments<String>()
                        Log.i(Const.TAG, "🍙jsonstr:$jsonstr");
                        jsonstr?.also {jsonstr ->
                            preferences.edit().also { edit ->
                                edit.putString("devices", Const.base64Encode(jsonstr))
                                edit.apply()
                            }
                        }
                        result.success(12345)
                    }
                     */
                    "start_beacon_scan" -> {
                        HappyPathManager.iBeaconScanStart();
                        result.success(56789)
                    }

                    "stop_beacon_scan" -> {
                        HappyPathManager.iBeaconScanStop();
                        result.success(12345)
                    }

                    // ネイティブからの，ローカル通知のテストコード.
                    // MTG step3 の検討用.
                    "test_notification" -> {
                        val manager = getSystemService(NotificationManager::class.java)
                        val channelId = Const.MY_REGION_NOTIFY_CHANNEL_ID
                        val builder = Notification.Builder(context, channelId)
                        builder.setSmallIcon(R.drawable.ic_stat_name)
                        builder.setContentTitle(Const.MY_REGION_NOTIFY_MESSAGE)
                        val intent = Intent(context, MainActivity::class.java)
                        val pendingIntent = PendingIntent.getActivity(context, 0, intent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                        builder.setContentIntent(pendingIntent)
                        manager.notify(123, builder.build())

                        result.success(99999)
                    }

                    else -> {
                        result.notImplemented()
                    }
                }
            } finally {
                Log.i(Const.TAG, "ネイティブメソッド呼出ハンドラ, method=${call.method} DONE")
            }
        }


        EventChannel(flutterEngine.dartExecutor.binaryMessenger, Const.MY_EVENT_CHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                Log.i(Const.TAG, "streamHandler#onListen() BEGIN")
                eventSink = events

                //val notifyDevices = mapOf("api" to "notify_devices")

                val myMap = mapOf ("api" to "Hello, World!")
                runOnUiThread {
                    eventSink?.success(myMap)
                }
                Log.i(Const.TAG, "streamHandler#onListen() DONE")
            }

            override fun onCancel(arguments: Any?) {
                Log.i(Const.TAG, "streamHandler#onCancel() BEGIN")
                Log.i(Const.TAG, "streamHandler#onCancel() DONE")
            }
        })
        Log.i(Const.TAG, "MainActivity#configureFlutterEngine() DONE")
    }

    private fun getMyRegionNotificationChannel() : NotificationChannel {
        val manager = getSystemService(NotificationManager::class.java)
        var channel = manager.getNotificationChannel(Const.MY_REGION_NOTIFY_CHANNEL_ID)
        if (channel == null) {
            Log.i(Const.TAG, "通知チャンネルを登録します")
            channel = NotificationChannel(
                Const.MY_REGION_NOTIFY_CHANNEL_ID,
                Const.MY_REGION_NOTIFY_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            )
            channel.description = Const.MY_REGION_NOTIFY_MESSAGE
            // Register the channel with the system; you can't change the importance
            // or other notification behaviors after this
            val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
        return channel
    }


    private fun getMyForegroundServiceNotificationChannel() : NotificationChannel {
        val manager = getSystemService(NotificationManager::class.java)
        var channel = manager.getNotificationChannel(Const.MY_FGSVC_NOTIFY_CHANNEL_ID)
        if (channel == null) {
            Log.i(Const.TAG, "通知チャンネルを登録します")
            channel = NotificationChannel(
                Const.MY_FGSVC_NOTIFY_CHANNEL_ID,
                Const.MY_FGSVC_NOTIFY_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            )
            channel.description = Const.MY_FGSVC_NOTIFY_CHANNEL_DESC
            // Register the channel with the system; you can't change the importance
            // or other notification behaviors after this
            val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
        return channel
    }


    /**
     * Flutter 側にメッセージを送ります.
     */
    override fun sendNativeMessage(arg: Any?) {
        Log.i(Const.TAG, "MainActivity#sendNativeMessage($arg) BEGIN")
        if (!fDestroyed) {
            runOnUiThread {
                eventSink?.success(arg)
            }
        }
        Log.i(Const.TAG, "MainActivity#sendNativeMessage($arg) DONE")
    }
}
