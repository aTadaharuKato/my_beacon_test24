import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'json_data_class.dart';
import 'main.dart';

/*
class MyDevice {
  String deviceId; // Bluetooth Address.
  String nickname; //

  MyDevice(this.deviceId, this.nickname);

  MyDevice.fromJson(Map<String, dynamic> json)
      : deviceId = json['device_id'] as String,
        nickname = json['nickname'] as String;

  Map<String, dynamic> toJson() => {
    'device_Id': deviceId,
    'nickname': nickname,
  };
}


class MyData {
  double temperature;
  int humidity;
  double pressure;
  String device;

  MyData(this.temperature, this.humidity, this.pressure, this.device);

  MyData.fromJson(Map<String, dynamic> json)
      : temperature = json['temperature'] as double,
        humidity = json['humidity'] as int,
        pressure = json['pressure'] as double,
        device = json['device'];

  Map<String, dynamic> toJson() => {
    'temperature': temperature,
    'humidity': humidity,
    'pressure': pressure,
    'device': device,
  };
}
 */

class MyController extends GetxController {
  static const platform = MethodChannel('samples.flutter.dev/battery');
  static const channel = EventChannel('samples.flutter.dev/counter');
  StreamSubscription? _streamSubscription;

  var regionStatus = "不明".obs;
  //var data = MyData(0.0, 0, 0.0, "---").obs;
  var selectedIndex = 0.obs;

  var appVer = "";
  var appName = "";
  var packageName = "";
  var buildNumber = "";

  var fBeaconScanning = false.obs;

  var myTextFieldController = TextEditingController();
  var fMyTextFieldEnable = true.obs;
  var myEncodedText = "".obs;
  var myDeviceSet = KDeviceSet().obs;

  var myDialogTextFieldController = TextEditingController();

  /// myDeviceSet を不揮発メモリに保存します.
  void storeDeviceSetToNVM() async {
    log.t('🍓MyController#storeDeviceSetToNVM() BEGIN');
    final String jsonText = jsonEncode(myDeviceSet.toJson());
    log.t('🍓jsonText: $jsonText');

    Codec<String, String> stringToBase64 = utf8.fuse(base64);
    var encodedText = stringToBase64.encode(jsonText);
    log.t('🍓base64エンコードした encodedText:$encodedText');
    var prefs = await SharedPreferences.getInstance();
    prefs.setString('devices', encodedText);

    log.t('🍓MyController#storeDeviceSetToNVM() DONE');
  }

  @override
  void onInit() async {
    log.t('🍓MyController#onInit() BEGIN');
    super.onInit();
    _myEventReceiverEnable();
    await getPackageInfo();
    log.t('🍓MyController#onInit() DONE');
  }

  @override
  void onClose() {
    log.t('🍓MyController#onClose() BEGIN');
    super.onClose();
    _myEventReceiverDisable();
    log.t('🍓MyController#onClose() DONE');
  }


  Future<void> getPackageInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appVer = packageInfo.version;
    appName = packageInfo.appName;
    packageName = packageInfo.packageName;
    buildNumber = packageInfo.buildNumber;
  }

  /// ネイティブからのイベントを受け取りを開始します.
  void _myEventReceiverEnable() {
    // Streamからデータを都度受け取れる
    _streamSubscription = channel.receiveBroadcastStream().listen((dynamic event) async {
        log.t('🍓myEventReceiverEnable, event is : ${event.runtimeType}, event: $event');
        var apiname = event['api'];
        if (apiname == "notify_sensor_data") {
          var data = event['data'];

          try {
            String? deviceAddr = data['device'];
            log.t('🍓deviceAddr: $deviceAddr');

            if (deviceAddr != null) {
              var validDevices = myDeviceSet.value.getValidDevices();
              for (var device in validDevices) {
                if (device.bleAddr == deviceAddr) {
                  log.t('🍓match Device Found!');
                  double? temperature = data['temperature'];
                  double? humidity = data['humidity'];
                  double? pressure = data['pressure'];
                  if (device.setSensorData(temperature, humidity, pressure)) {
                    update();
                  }
                  break;
                }
              }
            }
          } catch (e) {
            log.e('Exception Occurred, e:$e');
          }


        } else {
          log.t('🚩予期しないネイティブイベントの通知を受けました.');
        }
      },
      onError: (dynamic error) {
        log.e('🚩myEventReceiverEnable, error: $error');
      },
      cancelOnError: true,
    );
  }

  /// ネイティブからのイベントの受け取りを終了します.
  void _myEventReceiverDisable() {
    if (_streamSubscription != null) {
      _streamSubscription?.cancel();
      _streamSubscription = null;
    }
  }

  var fHomePageReady = false.obs;
  var msg = ''.obs;

  void initialTask() async {
    log.t('🍓 MyController#initialTask() BEGIN');
    await Future.delayed(const Duration(seconds: 3));
    msg.value = 'You have a nice dog.';

    try {
      // SharedPreference から，'devices' をキーに文字列を encodedText に読み込む.
      var prefs = await SharedPreferences.getInstance();
      var encodedText = prefs.getString('devices') ?? '';
      log.t('🍓SharedPreference から読み込んだ devices のデコード前のテキスト:$encodedText');

      // encodedText を Base64 デコードして，テキストにする. (JSON 文字列となるはず)
      Codec<String, String> stringToBase64 = utf8.fuse(base64);
      var jsonText = stringToBase64.decode(encodedText);
      log.t('🍓base64エンコードした文字列 (json文字列):$jsonText');

      // Json デコードして，KDeviceSet インスタンスを生成する.
      // 保存していたデータが不正ならば，デコードで例外が発生することがありえる.
      var deviceSetMap = jsonDecode(jsonText);
      log.t('🍓deviceSetMap:$deviceSetMap, ${deviceSetMap.runtimeType}');
      var newDeviceSet = KDeviceSet.fromJson(deviceSetMap);
      Get.find<MyController>().myDeviceSet.value = newDeviceSet;

      log.t('🍓newDeviceSet:$newDeviceSet, ${newDeviceSet.runtimeType}');
      log.t('🍓newDeviceSet.devices ${newDeviceSet.devices}');
      log.t('🍓newDeviceSet.devices.length: ${newDeviceSet.devices?.length}');
      newDeviceSet.devices?.forEach((element) {
        log.t('🍓element: ${element.toJson()}');
      });
    } catch (error) {
      log.t('🚩error:$error');
    }

    log.t('🍓number of devices: ${myDeviceSet.value.getNumberOfDevices()}');

    fHomePageReady.value = true;
    log.t('🍓 MyController#initialTask() DONE');
  }
}