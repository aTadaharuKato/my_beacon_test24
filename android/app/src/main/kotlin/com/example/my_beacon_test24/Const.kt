package com.example.my_beacon_test24

import android.util.Base64

class Const {
    companion object {
        const val TAG = "Otou"
        const val MY_METHOD_CHAMMEL = "samples.flutter.dev/battery"
        const val MY_EVENT_CHANNEL = "samples.flutter.dev/counter"


        const val MY_FGSVC_NOTIFY_CHANNEL_ID = "MY_FGSVC_NOTIFY"
        const val MY_FGSVC_NOTIFY_CHANNEL_NAME = "フォアグラウンドサービス通知"
        const val MY_FGSVC_NOTIFY_CHANNEL_DESC = "フォアグラウンドサービスを動かすために必要な通知です"
        const val MY_FGSVC_NOTIFY_MESSAGE = "ビーコンをスキャンしています"

        const val MY_REGION_NOTIFY_CHANNEL_ID = "MY_REGION_NOTIFY"
        const val MY_REGION_NOTIFY_CHANNEL_NAME = "ビーコン通知"
        const val MY_REGION_NOTIFY_CHANNEL_DESC = "リージョンに変化があった場合の通知です"
        const val MY_REGION_NOTIFY_MESSAGE = "リージョンに変化がありました"



        // 前回通知して，次に通知する，最短の間隔.
        const val MIN_NOTIFY_INTERVAL_MILLIS = 10000

        fun base64Encode(src: String): String {
            val srcBytes = src.toByteArray(Charsets.UTF_8)
            return Base64.encodeToString(srcBytes, Base64.DEFAULT)
        }
        fun base64Decode(src: String): String {
            val dstBytes = Base64.decode(src, Base64.DEFAULT)
            return String(dstBytes, Charsets.UTF_8)
        }

    }
}