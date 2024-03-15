package com.katomyapp.my_beacon_test24

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager.PERMISSION_GRANTED
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import androidx.preference.PreferenceManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock

class MainActivity: FlutterActivity(), MyNativeMsgSender {
    companion object {
    }

    var eventSink : EventChannel.EventSink?  = null
    private var fDestroyed = false

    private lateinit var mBluetoothAdapter: BluetoothAdapter;

    override fun onCreate(savedInstanceState: Bundle?) {
        Log.i(Const.TAG, "🍙MainActivity#onCreate() BEGIN")
        super.onCreate(savedInstanceState)
        HappyPathManager.curContext = this

        val bluetoothManager = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        mBluetoothAdapter = bluetoothManager.adapter

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

    private var resultMap = emptyMap<String, java.io.Serializable>()
    private val lockForPhase = ReentrantLock()
    enum class NativePhaseT(val id: Int) {
        IDLE(0x0000),
        PHASE_REQUESTING_BLE_SCAN_AND_CONNECT(0xB000),
        PHASE_REQUESTING_BLUETOOTH_ENABLE(0xB001),
        PHASE_REQUESTING_SETTING(0xB002),

        PHASE_REQUESTING_LOCATION_COARSE_AND_FINE(0xA001),
        PHASE_REQUESTING_NOTIFICATION(0xB001),
    }
    private var phase : NativePhaseT = NativePhaseT.IDLE
    private var methodChannelResult: MethodChannel.Result? = null

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        Log.i(Const.TAG, "🍙MainActivity#onRequestPermissionsResult(requestCode:$requestCode)")
        var fAllGranted = true
        for (i in permissions.indices) {
            Log.i(Const.TAG, "🍙[$i] ${permissions[i]}, ${if (grantResults[i] == PERMISSION_GRANTED) "GRANTED" else "DENIED"}")
            if (grantResults[i] != PERMISSION_GRANTED) {
                fAllGranted = false
            }
        }
        lockForPhase.withLock {
            if (requestCode == Const.MY_REQUEST_BLE_SCAN_AND_CONNECT) {
                if (phase == NativePhaseT.PHASE_REQUESTING_BLE_SCAN_AND_CONNECT) {
                    phase = NativePhaseT.IDLE
                    runOnUiThread {
                        methodChannelResult?.success(fAllGranted)
                        methodChannelResult = null
                    }
                }
            } else if (requestCode == Const.MY_REQUEST_SEQ_LOCATION_COARSE_AND_FINE) {
                if (phase == NativePhaseT.PHASE_REQUESTING_LOCATION_COARSE_AND_FINE) {
                    phase = NativePhaseT.IDLE
                    runOnUiThread {
                        methodChannelResult?.success(fAllGranted)
                        methodChannelResult = null
                    }
                }
            } else if (requestCode == Const.MY_REQUEST_NOTIFICATION) {
                if (phase == NativePhaseT.PHASE_REQUESTING_NOTIFICATION) {
                    phase = NativePhaseT.IDLE
                    if (fAllGranted) {
                        fAllGranted = !isChannelBlocked()
                    }
                    runOnUiThread {
                        methodChannelResult?.success(fAllGranted)
                        methodChannelResult = null
                    }
                }
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        Log.i(Const.TAG, "🍙MainActivity#onActivityResult() BEGIN")
        if (requestCode == Const.REQUEST_ENABLEBLUETOOTH) {
            Log.i(Const.TAG, "🍙resultCode:$resultCode")
            lockForPhase.withLock {
                if (phase == NativePhaseT.PHASE_REQUESTING_BLUETOOTH_ENABLE) {
                    phase = NativePhaseT.IDLE
                    val flag = (resultCode == RESULT_OK)
                    runOnUiThread {
                        methodChannelResult?.success(flag)
                        methodChannelResult = null
                    }
                }
            }
        } else if (requestCode == Const.MYREQUEST_LOCATION) {
            Log.i(Const.TAG, "🍙resultCode:$resultCode")
            lockForPhase.withLock {
                if (phase == NativePhaseT.PHASE_REQUESTING_SETTING) {
                    phase = NativePhaseT.IDLE
                    runOnUiThread {
                        methodChannelResult?.success(false)
                        methodChannelResult = null
                    }
                }
            }
        }
        Log.i(Const.TAG, "🍙MainActivity#onActivityResult() DONE")
    }

    private fun isChannelBlocked(): Boolean{
        val manager = getSystemService(NotificationManager::class.java)
        val channelId1: String = Const.MY_FGSVC_NOTIFY_CHANNEL_ID
        val channelId2: String = Const.MY_REGION_NOTIFY_CHANNEL_ID

        Log.i(Const.TAG, "channelId1:$channelId1, channelId2:$channelId2")
        val channel1 = manager.getNotificationChannel(channelId1)
        val channel2 = manager.getNotificationChannel(channelId2)
        val fIsBlocked = (channel1.importance == NotificationManager.IMPORTANCE_NONE)
                      || (channel2.importance == NotificationManager.IMPORTANCE_NONE)
        return fIsBlocked
    }

    var fReqStartScanBeacon = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        Log.i(Const.TAG, "🍙MainActivity#configureFlutterEngine() BEGIN")
        super.configureFlutterEngine(flutterEngine)
        val preferences = PreferenceManager.getDefaultSharedPreferences(this)
        fReqStartScanBeacon = HappyPathManager.prepare(this, preferences)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, Const.MY_METHOD_CHAMMEL).setMethodCallHandler { call, result ->
            Log.i(Const.TAG, "🍙ネイティブメソッド呼出ハンドラ, method=${call.method} BEGIN")
            try {
                when (call.method) {

                    "req_setting" -> {
                        lockForPhase.withLock {
                            phase = NativePhaseT.PHASE_REQUESTING_SETTING
                            methodChannelResult = result
                        }
                        // 位置情報の設定画面
                        //val enableLocIntent = Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS)
                        // アプリ情報の設定画面
                        val enableLocIntent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                        val uri = Uri.fromParts("package", packageName, null)
                        enableLocIntent.data = uri
                        startActivityForResult(enableLocIntent, Const.MYREQUEST_LOCATION);
                    }

                    "req_loc_permissions" -> {
                        val permissionOfCoarseLocation = checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION)
                        val permissionOfFineLocation = checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION)
                        Log.i(Const.TAG, "🍙Coarse Location: permission=$permissionOfCoarseLocation");
                        Log.i(Const.TAG, "🍙Fine Location: permission=$permissionOfFineLocation");
                        if ((permissionOfCoarseLocation == PERMISSION_GRANTED) && (permissionOfFineLocation == PERMISSION_GRANTED)) {
                            result.success(true)
                        } else {
                            lockForPhase.withLock {
                                phase = NativePhaseT.PHASE_REQUESTING_LOCATION_COARSE_AND_FINE
                                methodChannelResult = result
                            }
                            requestPermissions(
                                arrayOf(
                                    Manifest.permission.ACCESS_COARSE_LOCATION,
                                    Manifest.permission.ACCESS_FINE_LOCATION,
                                ), Const.MY_REQUEST_SEQ_LOCATION_COARSE_AND_FINE
                            )
                        }
                    }

                    "req_notify_permissions" -> {
                        if (Build.VERSION.SDK_INT < 33) {
                            result.success(true)
                        } else {
                            val permissionOfNotification = checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)
                            Log.i(Const.TAG, "Notification: permission=$permissionOfNotification")
                            if (permissionOfNotification == PERMISSION_GRANTED) {
                                val isOk = !isChannelBlocked()
                                result.success(isOk)
                            } else {
                                lockForPhase.withLock {
                                    phase = NativePhaseT.PHASE_REQUESTING_NOTIFICATION
                                    methodChannelResult = result
                                }
                                requestPermissions(
                                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                                    Const.MY_REQUEST_NOTIFICATION)
                            }
                        }
                    }

                    "req_bluetooth_enable" -> {
                        if (mBluetoothAdapter.isEnabled) {
                            result.success(true)
                        } else if (checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) != PERMISSION_GRANTED) {
                            // Bluetooth を ON にする権限がない.
                            result.success(false)
                        } else {
                            lockForPhase.withLock {
                                phase = NativePhaseT.PHASE_REQUESTING_BLUETOOTH_ENABLE
                                methodChannelResult = result
                            }
                            val enableBtIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
                            startActivityForResult(enableBtIntent, Const.REQUEST_ENABLEBLUETOOTH)
                        }
                    }

                    "req_ble_permissions" -> {
                        val permissionOfBleScan    = if (Build.VERSION.SDK_INT <= 30) PERMISSION_GRANTED
                                                     else checkSelfPermission(Manifest.permission.BLUETOOTH_SCAN)
                        val permissionOfBleConnect = if (Build.VERSION.SDK_INT <= 30) PERMISSION_GRANTED
                                                     else checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT)
                        Log.i(Const.TAG, "🍙BLUETOOTH_SCAN: permission=$permissionOfBleScan");
                        Log.i(Const.TAG, "🍙BLUETOOTH_CONNECT: permission=$permissionOfBleConnect");
                        if ((permissionOfBleScan == PERMISSION_GRANTED) && (permissionOfBleConnect == PERMISSION_GRANTED)) {
                            result.success(true)
                        } else {
                            lockForPhase.withLock {
                                phase = NativePhaseT.PHASE_REQUESTING_BLE_SCAN_AND_CONNECT
                                methodChannelResult = result
                            }
                            if (Build.VERSION.SDK_INT >= 31) {
                                requestPermissions(
                                    arrayOf(
                                        Manifest.permission.BLUETOOTH_SCAN,
                                        Manifest.permission.BLUETOOTH_CONNECT,
                                    ), Const.MY_REQUEST_BLE_SCAN_AND_CONNECT
                                )
                            }
                        }
                    }

                    "check_permissions" -> {
                        var fPermissionBluetooth = false
                        val permissionOfBleScan    = if (Build.VERSION.SDK_INT <= 30) PERMISSION_GRANTED
                        else checkSelfPermission(Manifest.permission.BLUETOOTH_SCAN)
                        val permissionOfBleConnect = if (Build.VERSION.SDK_INT <= 30) PERMISSION_GRANTED
                        else checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT)
                        Log.i(Const.TAG, "🍙BLUETOOTH_SCAN: permission=$permissionOfBleScan");
                        Log.i(Const.TAG, "🍙BLUETOOTH_CONNECT: permission=$permissionOfBleConnect");
                        if ((permissionOfBleScan == PERMISSION_GRANTED) && (permissionOfBleConnect == PERMISSION_GRANTED)) {
                            fPermissionBluetooth = true
                        }
                        //
                        val fBluetoothPower = mBluetoothAdapter.isEnabled
                        //
                        var fPermissionNotify = true
                        if (Build.VERSION.SDK_INT >= 33) {
                            val permissionOfNotification = checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)
                            Log.i(Const.TAG, "Notification: permission=$permissionOfNotification")
                            if (permissionOfNotification != PERMISSION_GRANTED) {
                                fPermissionNotify = false
                            } else {
                                fPermissionNotify = !isChannelBlocked()
                            }
                        }
                        //
                        var fPermissionLocation = false
                        val permissionOfCoarseLocation = checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION)
                        val permissionOfFineLocation = checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION)
                        Log.i(Const.TAG, "🍙Coarse Location: permission=$permissionOfCoarseLocation");
                        Log.i(Const.TAG, "🍙Fine Location: permission=$permissionOfFineLocation");
                        if ((permissionOfCoarseLocation == PERMISSION_GRANTED) && (permissionOfFineLocation == PERMISSION_GRANTED)) {
                            fPermissionLocation = true
                        }
                        result.success(mapOf(
                            "bluetooth_permission" to fPermissionBluetooth,
                            "bluetooth_power" to fBluetoothPower,
                            "notification_permission" to fPermissionNotify,
                            "location_permission" to fPermissionLocation,
                            )
                        )
                    }

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
                Log.i(Const.TAG, "🍙ネイティブメソッド呼出ハンドラ, method=${call.method} DONE")
            }
        }





        EventChannel(flutterEngine.dartExecutor.binaryMessenger, Const.MY_EVENT_CHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                Log.i(Const.TAG, "🍙streamHandler#onListen() BEGIN")
                eventSink = events

                //val notifyDevices = mapOf("api" to "notify_devices")

                if (fReqStartScanBeacon) {
                    fReqStartScanBeacon = false
                    HappyPathManager.iBeaconScanStart();

                } else if (HappyPathManager.fBeaconMonitoring) {
                    sendNativeMessage(mapOf(
                        "api" to "notify_scan_status",
                        "status" to true,
                    ));
                }

                //val myMap = mapOf ("api" to "Hello, World!")
                //runOnUiThread {
                //    eventSink?.success(myMap)
                //}
                Log.i(Const.TAG, "🍙streamHandler#onListen() DONE")
            }

            override fun onCancel(arguments: Any?) {
                Log.i(Const.TAG, "🍙streamHandler#onCancel() BEGIN")
                Log.i(Const.TAG, "🍙streamHandler#onCancel() DONE")
            }
        })
        Log.i(Const.TAG, "🍙MainActivity#configureFlutterEngine() DONE")
    }

    private fun getMyRegionNotificationChannel() : NotificationChannel {
        val manager = getSystemService(NotificationManager::class.java)
        var channel = manager.getNotificationChannel(Const.MY_REGION_NOTIFY_CHANNEL_ID)
        if (channel == null) {
            Log.i(Const.TAG, "🍙通知チャンネルを登録します")
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
            Log.i(Const.TAG, "🍙通知チャンネルを登録します")
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
        if (!fDestroyed) {
            Log.i(Const.TAG, "🍙MainActivity#sendNativeMessage($arg) BEGIN")
            runOnUiThread {
                eventSink?.success(arg)
            }
        } else {
            Log.i(Const.TAG, "🍙MainActivity#sendNativeMessage($arg) BEGIN, <But already destroyed>")
        }
        Log.i(Const.TAG, "🍙MainActivity#sendNativeMessage($arg) DONE")
    }
}
