package com.example.my_beacon_test24

import io.flutter.embedding.android.FlutterActivity
import org.altbeacon.beacon.MonitorNotifier
import org.altbeacon.beacon.Region

class MainActivity: FlutterActivity(), MonitorNotifier {
    companion object {

    }

    override fun didEnterRegion(region: Region?) {
        TODO("Not yet implemented")
    }

    override fun didExitRegion(region: Region?) {
        TODO("Not yet implemented")
    }

    override fun didDetermineStateForRegion(state: Int, region: Region?) {
        TODO("Not yet implemented")
    }
}
