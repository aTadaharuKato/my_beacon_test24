package com.example.my_beacon_test24

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.altbeacon.beacon.BeaconManager
import org.altbeacon.beacon.BeaconParser
import org.altbeacon.beacon.MonitorNotifier
import org.altbeacon.beacon.Region

class MainActivity: FlutterActivity(), MonitorNotifier {
    companion object {
        const val TAG = "Otou"
        const val MY_METHOD_CHAMMEL = "samples.flutter.dev/battery"
        const val MY_EVENT_CHANNEL = "samples.flutter.dev/counter"

    }
    var eventSink : EventChannel.EventSink?  = null
    private lateinit var mBluetoothAdapter: BluetoothAdapter
    private var myBeaconRegionList = ArrayList<Region>()

    override fun onCreate(savedInstanceState: Bundle?) {
        Log.i(TAG, "MainActivity#onCreate() BEGIN")
        super.onCreate(savedInstanceState)
        Log.i(TAG, "MainActivity#onCreate() DONE")
    }

    override fun onStart() {
        Log.i(TAG, "MainActivity#onStart() BEGIN, this:$this")
        super.onStart()
        Log.i(TAG, "MainActivity#onStart() DONE")
    }
    override fun onResume() {
        Log.i(TAG, "MainActivity#onResume() BEGIN, this:$this")
        super.onResume()
        Log.i(TAG, "MainActivity#onResume() DONE")
    }
    override fun onPause() {
        Log.i(TAG, "MainActivity#onPause() BEGIN, this:$this")
        super.onPause()
        Log.i(TAG, "MainActivity#onPause() DONE")
    }
    override fun onStop() {
        Log.i(TAG, "MainActivity#onStop() BEGIN, this:$this")
        super.onStop()
        Log.i(TAG, "MainActivity#onStop() DONE")
    }

    override fun onDestroy() {
        Log.i(TAG, "MainActivity#onDestroy() BEGIN, this:$this")
        super.onDestroy()
        Log.i(TAG, "MainActivity#onDestroy() DONE")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        Log.i(TAG, "MainActivity#configureFlutterEngine() BEGIN")
        super.configureFlutterEngine(flutterEngine)
        val bluetoothManager = getSystemService(BLUETOOTH_SERVICE) as BluetoothManager
        mBluetoothAdapter = bluetoothManager.adapter

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MY_METHOD_CHAMMEL).setMethodCallHandler { call, result ->
            Log.i(TAG, "ネイティブメソッド呼出ハンドラ, method=${call.method} BEGIN")
            try {
                when (call.method) {
                    "start_beacon_scan" -> {
                        iBeaconScanStart();
                        result.success(56789)
                    }
                    "stop_beacon_scan" -> {
                        iBeaconScanStop();
                        result.success(12345)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            } finally {
                Log.i(TAG, "ネイティブメソッド呼出ハンドラ, method=${call.method} DONE")
            }
        }


        EventChannel(flutterEngine.dartExecutor.binaryMessenger, MY_EVENT_CHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                Log.i(TAG, "streamHandler#onListen() BEGIN")
                eventSink = events

                val myMap = mapOf ("api" to "Hello, World!")
                runOnUiThread {
                    eventSink?.success(myMap)
                }
                Log.i(TAG, "streamHandler#onListen() DONE")
            }

            override fun onCancel(arguments: Any?) {
                Log.i(TAG, "streamHandler#onCancel() BEGIN")
                Log.i(TAG, "streamHandler#onCancel() DONE")
            }
        })
        Log.i(TAG, "MainActivity#configureFlutterEngine() DONE")
    }



    private fun iBeaconScanStop() {
        Log.i(TAG, "MainActivity#iBeaconScanStop() BEGIN");
        val beaconManager = BeaconManager.getInstanceForApplication(this)
        Log.i(TAG, "beaconManager.isAnyConsumerBound: ${beaconManager.isAnyConsumerBound} BEFORE")
        if (beaconManager.isAnyConsumerBound) {
            myBeaconRegionList.forEach { region ->
                beaconManager.stopMonitoring(region)
            }
        }
        Log.i(TAG, "beaconManager.isAnyConsumerBound: ${beaconManager.isAnyConsumerBound} AFTER")
        Log.i(TAG, "MainActivity#iBeaconScanStop() DONE");
    }

    private fun iBeaconScanStart() {
        Log.i(TAG, "MainActivity#iBeaconScanStart() BEGIN")
        val beaconManager = BeaconManager.getInstanceForApplication(this)
        beaconManager.beaconParsers.also { beaconParsers ->
            beaconParsers.clear()
            beaconParsers.add(BeaconParser().setBeaconLayout("m:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24"))
        }
        BeaconManager.setDebug(false)

        if (!beaconManager.isAnyConsumerBound) {
            myBeaconRegionList.clear()
            val region = Region("region-all", null, null, null)
            myBeaconRegionList.add(region)

            val channelId = "My Notification Channel ID"
            val channel = NotificationChannel(channelId, "My Notification Name", NotificationManager.IMPORTANCE_HIGH)
            channel.description = "My Notification Channel Description"

            val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)

            val builder = Notification.Builder(this, channelId)
            builder.setSmallIcon(R.drawable.ic_stat_name)
            builder.setContentTitle("ビーコンをスキャンしています.")
            val intent = Intent(this, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(this, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            builder.setContentIntent(pendingIntent)
            beaconManager.enableForegroundServiceScanning(builder.build(), 456)

            // 上記のフォアグラウンド スキャン サービスを有効にするには、JobScheduler ベースの
            // スキャン (Android 8 以降で使用) を無効にし、
            // 高速なバックグラウンド スキャン サイクルを設定する必要があります。
            beaconManager.setEnableScheduledScanJobs(false)

            Log.i(TAG, "Foreground Scan Period: ${beaconManager.foregroundScanPeriod}")
            Log.i(TAG, "Foreground Between Scan Period: ${beaconManager.foregroundBetweenScanPeriod}")
            Log.i(TAG, "Background Scan Period: ${beaconManager.backgroundScanPeriod}")
            Log.i(TAG, "Background Between Scan Period: ${beaconManager.backgroundBetweenScanPeriod}")
            Log.i(TAG, "RegionExitPeriod: ${BeaconManager.getRegionExitPeriod()}")

            // 測距/監視クライアントがフォアグラウンドにない場合に、各 Bluetooth LE スキャンサイクル間で
            // スキャンしない時間をミリ秒単位で設定します。
            //setBackgroundBetweenScanPeriod(0)
            beaconManager.backgroundBetweenScanPeriod = 5000
            //setBackgroundBetweenScanPeriod(1000 * 60)

            // ビーコンを探す各 Bluetooth LE スキャン サイクルの期間をミリ秒単位で設定します。
            //この関数は、bind を呼び出す前、またはバックグラウンド/フォアグラウンドを切り替えるときに期間を設定するために使用されます。
            //すでに実行中のスキャン (次のサイクルの開始時) に影響を与えるには、updateScanPeriods を呼び出します。
            beaconManager.backgroundScanPeriod = 10000
            //setBackgroundScanPeriod(3000)

            beaconManager.foregroundBetweenScanPeriod = 0
            beaconManager.foregroundScanPeriod = 3000
            //setForegroundScanPeriod(3000)

            //BeaconManager.setRegionExitPeriod(2*1000) //未検知になって2秒でExitと判定
            BeaconManager.setRegionExitPeriod(4*1000) //未検知になって3秒でExitと判定
            // ---
            Log.i(TAG, "MainActivity#onCreate() アプリでバックグラウンド監視を設定します.")
            beaconManager.addMonitorNotifier(this)

            // このアプリの最後の実行で *異なる* リージョンを監視していた場合、それらは記憶されます。
            // この場合、ここでそれらを無効にする必要があります。
            beaconManager.monitoredRegions.forEach {
                Log.i(TAG, "MainActivity#onCreate() stopMonitoring($it)")
                beaconManager.stopMonitoring(it)
            }

            Log.i(TAG, "Foreground Scan Period: ${beaconManager.foregroundScanPeriod}")
            Log.i(TAG, "Foreground Between Scan Period: ${beaconManager.foregroundBetweenScanPeriod}")
            Log.i(TAG, "Background Scan Period: ${beaconManager.backgroundScanPeriod}")
            Log.i(TAG, "Background Between Scan Period: ${beaconManager.backgroundBetweenScanPeriod}")
            Log.i(TAG, "RegionExitPeriod: ${BeaconManager.getRegionExitPeriod()}")

            // BeaconService がビーコンのリージョンを検出するか、検出を停止するたびに呼び出す必要があるクラスを指定します。
            // 複数の MonitorNotifier オブジェクトの登録を許可します。
            // removeMonitoreNotifier を使用して通知機能を登録解除します。
            //Log.i(TAG, "MainActivity#onCreate() startMonitoring($WILDCARD_REGION)")
            //beaconManager.startMonitoring(WILDCARD_REGION)
            myBeaconRegionList.forEach { targetRegion ->
                beaconManager.startMonitoring(targetRegion)
            }
        }
        Log.i(TAG, "MainActivity#iBeaconScanStart() DONE")
    }



    override fun didEnterRegion(region: Region?) {
        Log.i(TAG, "MainActivity#didEnterRegion() - 領域に入りました. $region")
    }

    override fun didExitRegion(region: Region?) {
        Log.i(TAG, "MainActivity#didExitRegion() - 領域を出ました. $region")
    }

    override fun didDetermineStateForRegion(state: Int, region: Region?) {
        Log.i(TAG, "MainActivity#didDetermineStateForRegion(state:$state, region:$region)")
    }

}
