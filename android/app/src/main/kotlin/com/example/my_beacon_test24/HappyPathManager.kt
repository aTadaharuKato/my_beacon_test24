package com.example.my_beacon_test24

import android.app.Notification
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import com.example.my_beacon_test24.KDevice
import com.google.gson.GsonBuilder
import com.google.gson.annotations.SerializedName
import org.altbeacon.beacon.Beacon
import org.altbeacon.beacon.BeaconManager
import org.altbeacon.beacon.BeaconParser
import org.altbeacon.beacon.Identifier
import org.altbeacon.beacon.MonitorNotifier
import org.altbeacon.beacon.RangeNotifier
import org.altbeacon.beacon.Region
import java.util.UUID

data class KDevice (
    @SerializedName("ble_addr")
    val bleAddr: String,

    @SerializedName("nickname")
    val nickname: String,
)

data class KDevices (
    @SerializedName("devices")
    val devices: List<KDevice>,
)

object HappyPathManager : MonitorNotifier, RangeNotifier {

    private var curPreferences: SharedPreferences? = null
    private var fBeaconMonitoring = false
    private var fStarted = false
    private var myBeaconRegionList = listOf(
        //Region("region-all", null, null, null),
        Region("APZ-110", Identifier.parse("C722DB4C-5D91-1801-BEB5-001C4DE7B3FD"), null, null),
    )
    var curContext: Any? = null

    var sensors = KDevices(emptyList<KDevice>())

    var lasNotifyTick = 0L

    init {
        Log.i(Const.TAG, "HappyPathManager#init BEGIN")
        Log.i(Const.TAG, "HappyPathManager#init DONE")
    }

    fun prepare(context: Context, preferences: SharedPreferences) : Boolean {
        Log.i(Const.TAG, "HappyPathManager#prepare($preferences) BEGIN")
        curPreferences = preferences
        var fSavedBeaconMonitoring = false
        if (!fStarted) {
            fStarted = true
            val all = preferences.all
            Log.i(Const.TAG, "Preference/不揮発性メモリに格納された変数:$all")
            fSavedBeaconMonitoring = (all["fBeaconMonitoring"] as Boolean?) ?: false

            val myJson = GsonBuilder().setDateFormat("yyyy-MM-dd'T'HH:mm:ssXXX").create()

            try {
                (all["devices"] as String?)?.also {devicesJsonStr ->
                    val v = myJson.fromJson(Const.base64Decode(devicesJsonStr), KDevices::class.java)
                    Log.i(Const.TAG, "v:$v")
                    sensors = v
                }
            } catch (e: Exception) {
                Log.i(Const.TAG, "例外がおきました!!")
                Log.i(Const.TAG, e.stackTraceToString())
            }

            // 登録デバイスの一覧をログ表示.
            sensors.devices.forEach { device ->
                val x = myJson.toJson(device)
                Log.i(Const.TAG, "x:$x")
            }
        }
        Log.i(Const.TAG, "HappyPathManager#prepare($preferences) DONE")
        return fSavedBeaconMonitoring
    }

    fun fBeaconMonitoringChange(flag: Boolean) {
        Log.i(Const.TAG, "HappyPathManager#fBeaconMonitoringChange($flag) BEGIN")
        if (fBeaconMonitoring != flag) {
            Log.i(Const.TAG, "[NVM] fBeaconMonitoring <- $flag")
            curPreferences?.edit().also { edit ->
                edit?.putBoolean("fBeaconMonitoring", flag)
                edit?.apply()
            }
            fBeaconMonitoring = flag
        }
        Log.i(Const.TAG, "HappyPathManager#fBeaconMonitoringChange($flag) DONE")
    }


    fun iBeaconScanStart() {
        Log.i(Const.TAG, "HappyPathManager#iBeaconScanStart() BEGIN")

        lasNotifyTick = 0

        (curContext as? Context)?.also { context ->

            val beaconManager = BeaconManager.getInstanceForApplication(context)
            beaconManager.beaconParsers.also { beaconParsers ->
                beaconParsers.clear()
                beaconParsers.add(BeaconParser().setBeaconLayout("m:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24"))
            }
            BeaconManager.setDebug(false)

            if (!beaconManager.isAnyConsumerBound) {

                val builder = Notification.Builder(context, Const.MY_FGSVC_NOTIFY_CHANNEL_ID)
                builder.setSmallIcon(R.drawable.ic_stat_name)
                builder.setContentTitle("ビーコンをスキャンしています.")

                val intent = Intent(context, MainActivity::class.java)

                val pendingIntent = PendingIntent.getActivity(context, 0, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                builder.setContentIntent(pendingIntent)
                beaconManager.enableForegroundServiceScanning(builder.build(), 456)

                // 上記のフォアグラウンド スキャン サービスを有効にするには、JobScheduler ベースの
                // スキャン (Android 8 以降で使用) を無効にし、
                // 高速なバックグラウンド スキャン サイクルを設定する必要があります。
                beaconManager.setEnableScheduledScanJobs(false)

                Log.i(Const.TAG, "Foreground Scan Period: ${beaconManager.foregroundScanPeriod}")
                Log.i(Const.TAG, "Foreground Between Scan Period: ${beaconManager.foregroundBetweenScanPeriod}")
                Log.i(Const.TAG, "Background Scan Period: ${beaconManager.backgroundScanPeriod}")
                Log.i(Const.TAG, "Background Between Scan Period: ${beaconManager.backgroundBetweenScanPeriod}")
                Log.i(Const.TAG, "RegionExitPeriod: ${BeaconManager.getRegionExitPeriod()}")

                // 測距/監視クライアントがフォアグラウンドにない場合に、各 Bluetooth LE スキャンサイクル間で
                // スキャンしない時間をミリ秒単位で設定します。
                beaconManager.backgroundBetweenScanPeriod = 5000

                // ビーコンを探す各 Bluetooth LE スキャン サイクルの期間をミリ秒単位で設定します。
                //この関数は、bind を呼び出す前、またはバックグラウンド/フォアグラウンドを切り替えるときに期間を設定するために使用されます。
                //すでに実行中のスキャン (次のサイクルの開始時) に影響を与えるには、updateScanPeriods を呼び出します。
                beaconManager.backgroundScanPeriod = 10000

                beaconManager.foregroundBetweenScanPeriod = 0
                beaconManager.foregroundScanPeriod = 3000

                BeaconManager.setRegionExitPeriod(4*1000) //未検知になって4秒でExitと判定
                // ---
                Log.i(Const.TAG, "MainActivity#onCreate() アプリでバックグラウンド監視を設定します.")
                beaconManager.addMonitorNotifier(this)
                beaconManager.addRangeNotifier(this)


                // このアプリの最後の実行で *異なる* リージョンを監視していた場合、それらは記憶されます。
                // この場合、ここでそれらを無効にする必要があります。
                beaconManager.monitoredRegions.forEach {
                    Log.i(Const.TAG, "MainActivity#onCreate() stopMonitoring($it)")
                    beaconManager.stopMonitoring(it)
                    beaconManager.stopRangingBeacons(it)
                }

                Log.i(Const.TAG, "Foreground Scan Period: ${beaconManager.foregroundScanPeriod}")
                Log.i(Const.TAG, "Foreground Between Scan Period: ${beaconManager.foregroundBetweenScanPeriod}")
                Log.i(Const.TAG, "Background Scan Period: ${beaconManager.backgroundScanPeriod}")
                Log.i(Const.TAG, "Background Between Scan Period: ${beaconManager.backgroundBetweenScanPeriod}")
                Log.i(Const.TAG, "RegionExitPeriod: ${BeaconManager.getRegionExitPeriod()}")

                // BeaconService がビーコンのリージョンを検出するか、検出を停止するたびに呼び出す必要があるクラスを指定します。
                // 複数の MonitorNotifier オブジェクトの登録を許可します。
                // removeMonitoreNotifier を使用して通知機能を登録解除します。
                myBeaconRegionList.forEach { targetRegion ->
                    beaconManager.startMonitoring(targetRegion)
                    beaconManager.startRangingBeacons(targetRegion)
                }
                fBeaconMonitoringChange(true)
            }
        }
        Log.i(Const.TAG, "HappyPathManager#iBeaconScanStart() DONE")
    }

    fun iBeaconScanStop() {
        Log.i(Const.TAG, "HappyPathManager#iBeaconScanStop() BEGIN");
        (curContext as? Context)?.also { context ->
            val beaconManager = BeaconManager.getInstanceForApplication(context)
            Log.i(Const.TAG, "beaconManager.isAnyConsumerBound: ${beaconManager.isAnyConsumerBound} BEFORE")
            if (beaconManager.isAnyConsumerBound) {
                myBeaconRegionList.forEach { region ->
                    beaconManager.stopMonitoring(region)
                    beaconManager.stopRangingBeacons(region)
                }
            }
            Log.i(Const.TAG, "beaconManager.isAnyConsumerBound: ${beaconManager.isAnyConsumerBound} AFTER")
        }
        fBeaconMonitoringChange(false)
        Log.i(Const.TAG, "HappyPathManager#iBeaconScanStop() DONE");
    }

    override fun didEnterRegion(region: Region?) {
        Log.i(Const.TAG, "HappyPathManager#didEnterRegion() - 領域に入りました. $region")
        /*
        region?.also { region ->
            Log.i(Const.TAG, "bluetoothAddress:${region.bluetoothAddress}, id1:${region.id1}, id2:${region.id2}, id3:${region.id3}")
        }*/
    }

    override fun didExitRegion(region: Region?) {
        Log.i(Const.TAG, "HappyPathManager#didExitRegion() - 領域を出ました. $region")
    }

    override fun didDetermineStateForRegion(state: Int, region: Region?) {
        Log.i(Const.TAG, "HappyPathManager#didDetermineStateForRegion(state:$state, region:$region)")
    }

    override fun didRangeBeaconsInRegion(beacons: MutableCollection<Beacon>?, region: Region?) {
        Log.i(Const.TAG, "HappyPathManager#didRangeBeaconsInRegion(beacons:$beacons, region:$region)")

        var curtick = System.currentTimeMillis()
        var elapsed = curtick - lasNotifyTick
        if (elapsed < Const.MIN_NOTIFY_INTERVAL_MILLIS) {
            Log.i(Const.TAG, "elapsed $elapsed mills, skip this data")
        }

        beacons?.forEach {beacon ->
            Log.i(Const.TAG, "beacon:$beacon")

            Log.i(Const.TAG, "bluetoothAddress:${beacon.bluetoothAddress}, id1:${beacon.id1}, id2:${beacon.id2}, id3:${beacon.id3}, ")
            val svc = beacon.id1.toUuid()
            val ex1 = UUID.fromString("C722DB4C-5D91-1801-BEB5-001C4DE7B3FD")
            if (svc == ex1) {
                // 温湿度気圧センサ APZ-110 の場合，
                val major = beacon.id2.toInt();
                val minor = beacon.id3.toInt();
                Log.i(Const.TAG, "major:$major, (0x${HexDump.IntToHexString(major)}), minor:$minor, (0x${HexDump.IntToHexString(minor)})")

                val u = (major shr 4) and 0x3FF
                val v = ((major shl 3) or (minor shr 13)) and 0x7F
                val w = minor and 0x1FFF

                val Rt = 0.1 * u.toDouble() - 30.0
                val Rh = v
                val Rp = 0.1 * w.toDouble() + 300.0
                //Log.i(Const.TAG, "温度: $Rt [℃], 湿度: $Rh [%], 気圧: $Rp [hPa]")

                var s = String.format("温度: %.1f [℃], 湿度: %d [%%], 気圧: %.1f [hPa])", Rt, Rh, Rp)
                Log.i(Const.TAG, s)
                (curContext as? MyNativeMsgSender)?.sendNativeMessage(mapOf(
                    "api" to "notify_sensor_data",
                    "data" to mapOf(
                        "temperature" to Rt,
                        "humidity" to Rh,
                        "pressure" to Rp,
                        "device" to beacon.bluetoothAddress,
                    ),
                ))
                lasNotifyTick = curtick
            }
        }
    }

}