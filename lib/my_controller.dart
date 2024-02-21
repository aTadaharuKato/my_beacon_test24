import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'main.dart';

class MyController extends GetxController {
  static const platform = MethodChannel('samples.flutter.dev/battery');
  static const channel = EventChannel('samples.flutter.dev/counter');
  StreamSubscription? _streamSubscription;

  var regionStatus = "不明".obs;


  @override
  void onInit() {
    Log.t('🍓🍓MyController#onInit() BEGIN');
    super.onInit();
    _myEventReceiverEnable();
    Log.t('🍓🍓MyController#onInit() DONE');
  }

  @override
  void onClose() {
    Log.t('🍓🍓MyController#onClose() BEGIN');
    super.onClose();
    _myEventReceiverDisable();
    Log.t('🍓🍓MyController#onClose() DONE');
  }




  /**
   * ネイティブからのイベントを受け取りを開始します.
   */
  void _myEventReceiverEnable() {
    // Streamからデータを都度受け取れる
    _streamSubscription = channel.receiveBroadcastStream().listen((dynamic event) async {
        Log.t('🍓🍓myEventReceiverEnable, event is : ${event.runtimeType}, event: $event');
        var apiname = event['api'];
        var result = event['result'];
        Log.t('🚩予期しないネイティブイベントの通知を受けました.');
      },
      onError: (dynamic error) {
        print('🚩myEventReceiverEnable, error: $error');
      },
      cancelOnError: true,
    );
  }

  /**
   * ネイティブからのイベントの受け取りを終了します.
   */
  void _myEventReceiverDisable() {
    if (_streamSubscription != null) {
      _streamSubscription?.cancel();
      _streamSubscription = null;
    }
  }


}