import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'json_data_class.dart';
import 'main.dart';

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
  var fDeviceSearching = false;

  var myTextFieldController = TextEditingController();
  var fMyTextFieldEnable = true.obs;
  var myEncodedText = "".obs;

  var myDeviceSet = KDeviceSet();

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

              var fIsDialogOpen = Get.isDialogOpen ?? false;
              // デバイス検索中の場合.
              if (fDeviceSearching && fIsDialogOpen) {
                var fKnownDevice = false;
                if (myDeviceSet.devices != null) {
                  for (var device in myDeviceSet.devices!) {
                    if (device.bleAddr == deviceAddr) {
                      fKnownDevice = true;
                      break;
                    }
                  }
                }
                if (fKnownDevice == false) {
                  log.t('🍓新しいデバイスが見つかりましたよ!');
                  log.t('${Get.isDialogOpen}');
                  Get.back();
                  fDeviceSearching = false;
                  Get.dialog(
                    barrierDismissible: false, // ダイアログ領域外をタップしたときに，ダイアログを閉じないようにする.
                    PopScope(
                      canPop: false,
                      child: AlertDialog(
                        title: const Text('新しいデバイスが見つかりました!'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('BDADDR: $deviceAddr'),
                            const Text('このデバイスを登録しますか？'),
                          ],
                        ),
                        actions: [
                          OutlinedButton(
                              onPressed: () {
                                Get.back();
                                KDevice newDevice = KDevice(bleAddr: deviceAddr, nickname: '無視するデバイス', fShow: false);
                                //myDeviceSet.devices?.add(newDevice);
                                myDeviceSet.addDevice(newDevice);
                                update();
                              },
                              child: const Text('無視')
                          ),
                          OutlinedButton(
                              onPressed: () {
                                Get.back();
                                KDevice newDevice = KDevice(bleAddr: deviceAddr, nickname: '新しいデバイス', fShow: true);
                                //myDeviceSet.devices?.add(newDevice);
                                myDeviceSet.addDevice(newDevice);
                                update();
                              },
                              child: const Text('登録')
                          ),
                        ],
                      ),
                    ),
                  );
                }
              }

              // 通知された BD アドレスが，有効なデバイスのものと一致するならば，センサデータを更新する.
              var validDevices = myDeviceSet.getValidDevices();
              for (var device in validDevices) {
                if (device.bleAddr == deviceAddr) {
                  log.t('🍓match Device Found!');
                  double? temperature = data['temperature'];
                  double? humidity = data['humidity'];
                  double? pressure = data['pressure'];
                  if (device.setSensorData(temperature, humidity, pressure, DateTime.now())) {
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
      myDeviceSet = newDeviceSet;

      log.t('🍓newDeviceSet:$newDeviceSet, ${newDeviceSet.runtimeType}');
      log.t('🍓newDeviceSet.devices ${newDeviceSet.devices}');
      log.t('🍓newDeviceSet.devices.length: ${newDeviceSet.devices?.length}');
      newDeviceSet.devices?.forEach((element) {
        log.t('🍓element: ${element.toJson()}');
      });
    } catch (error) {
      log.t('🚩error:$error');
    }

    log.t('🍓number of devices: ${myDeviceSet.getNumberOfDevices()}');

    fHomePageReady.value = true;
    log.t('🍓 MyController#initialTask() DONE');
  }


  void mySimpleDialogShow(String title, String msg, VoidCallback? closedCB) {
    Get.dialog(
        barrierDismissible: false, // ダイアログ領域外をタップしたときに，ダイアログを閉じないようにする.
        PopScope(
            canPop: false,
            child: AlertDialog(
                title: Text(title),
                content: Text(msg),
                actions: [
                  // 「キャンセル」ボタン.
                  OutlinedButton(
                      onPressed: closedCB,
                      child: const Text('OK')
                  ),
                ]
            )
        )
    );
  }


  void permissionFlow1(VoidCallback? successCB, VoidCallback? failedCB) async {
    log.t('🍓MyController#permissionFlow1() BEGIN');
    try {
      // ネイティブメソッド "check_permission" を呼び出す
      // すべて true ならば，リクエストフローは成功で終了。
      Map ret = await platform.invokeMethod('check_permissions');
      bool fBluetoothPermission = ret['bluetooth_permission'] ?? false;
      bool fBluetoothPower = ret['bluetooth_power'] ?? false;
      bool fNotificationPermission = ret['notification_permission'] ?? false;
      bool fLocationPermission = ret['location_permission'] ?? false;
      log.t('🍓fBluetoothPermission: $fBluetoothPermission');
      log.t('🍓fBluetoothPower: $fBluetoothPower');
      log.t('🍓fNotificationPermission: $fNotificationPermission');
      log.t('🍓fLocationPermission: $fLocationPermission');
      if (fBluetoothPermission && fBluetoothPower && fNotificationPermission && fLocationPermission) {
        // リクエストフローは成功で終了。
        if (successCB != null) {
          successCB();
        }
        return;
      }
      // 1.
      // ・bluetooth_permission が true の場合，「2.」へ
      // ・「本アプリはiBeacon検出のため，Bluetoothを使用します。\n付近のデバイスの検出，接続，相対位置の特定を，本アプリに許可してください。」のダイアログ表示
      // ・ネイティブメソッド "req_ble_permissions" を呼び出す。
      // ・「2.」へ
      if (fBluetoothPermission) {
        _permissionFlow2(ret, successCB, failedCB);
      } else {
        mySimpleDialogShow(
          'お願い',
          '本アプリはiBeacon検出のため，Bluetoothを使用します。\n付近のデバイスの検出，接続，相対位置の特定を，本アプリに許可してください。',
          () async {
            Get.back();
            var ret1 = await platform.invokeMethod('req_ble_permissions');
            log.t('🍓ネイティブメソッド req_ble_permissions の戻り値: $ret1');
            _permissionFlow2(ret, successCB, failedCB);
          }
        );
      }
    } catch (e) {
      log.t('🍓ネイティブ呼び出しで例外が発生しました. $e');
      if (failedCB != null) {
        failedCB();
      }
    }
    log.t('🍓MyController#permissionFlow1() DONE');
  }

  // 2.
  // ・bluetooth_power が true の場合，「3.」へ
  // ・ネイティブメソッド "req_bluetooth_enable" を呼び出す。
  // ・「3.」へ
  void _permissionFlow2(Map map, VoidCallback? successCB, VoidCallback? failedCB) async {
    log.t('🍓MyController#_permissionFlow2() BEGIN');
    try {
      bool fBluetoothPower = map['bluetooth_power'] ?? false;
      log.t('🍓fBluetoothPower: $fBluetoothPower');
      if (!fBluetoothPower) {
        var ret2 = await platform.invokeMethod('req_bluetooth_enable');
        log.t('🍓ネイティブメソッド req_bluetooth_enable の戻り値: $ret2');
      }
      _permissionFlow3(map, successCB, failedCB);
    } catch (e) {
      log.t('🍓ネイティブ呼び出しで例外が発生しました. $e');
      if (failedCB != null) {
        failedCB();
      }
    }
    log.t('🍓MyController#_permissionFlow2() DONE');
  }

  // 3.
  // ・location_permission が true の場合，「4.」へ
  // ・「本アプリは iBeacon を検出するため，位置情報の権限が必要です。\nこのデバイスの正確な位置情報へのアクセスを，本アプリに許可してください。」のダイアログ表示
  // ・ネイティブメソッド "req_loc_permissions" を呼び出す。
  // ・「4.」へ
  void _permissionFlow3(Map map, VoidCallback? successCB, VoidCallback? failedCB) async {
    log.t('🍓MyController#_permissionFlow3() BEGIN');
    try {
      bool fLocationPermission = map['location_permission'] ?? false;
      log.t('🍓fLocationPermission: $fLocationPermission');
      if (fLocationPermission) {
        _permissionFlow4(map, successCB, failedCB);
      } else {
        mySimpleDialogShow(
          'お願い',
          '本アプリは iBeacon を検出するため，位置情報の権限が必要です。\nこのデバイスの正確な位置情報へのアクセスを，本アプリに許可してください。',
          () async {
            Get.back();
            var ret3 = await platform.invokeMethod('req_loc_permissions');
            log.t('🍓ネイティブメソッド req_loc_permissions の戻り値: $ret3');
            _permissionFlow4(map, successCB, failedCB);
          }
        );
      }
    } catch (e) {
      log.t('🍓ネイティブ呼び出しで例外が発生しました. $e');
      if (failedCB != null) {
        failedCB();
      }
    }
    log.t('🍓MyController#_permissionFlow3() DONE');
  }


  // 4.
  // ・req_notify_permissions が true の場合，「5.」へ
  // ・「本アプリは iBeacon を監視するため，フォアグラウンドサービスを使用します。通知の送信の権限はそのために必要です。通知の送信の権限を，本アプリに許可してください。」のダイアログ表示
  // ・ネイティブメソッド "req_notify_permissions" を呼び出す。
  // ・「5.」へ
  void _permissionFlow4(Map map, VoidCallback? successCB, VoidCallback? failedCB) async {
    log.t('🍓MyController#_permissionFlow4() BEGIN');
    try {
      bool fNotificationPermission = map['notification_permission'] ?? false;
      log.t('🍓fNotificationPermission: $fNotificationPermission');
      if (fNotificationPermission) {
        _permissionFlow5(successCB, failedCB);
      } else {
        mySimpleDialogShow(
          'お願い',
          '本アプリは iBeacon を監視するため，フォアグラウンドサービスを使用します。\nそのために通知の送信の権限が必要です。\n通知の送信の権限を，本アプリに許可してください。',
          () async {
            Get.back();
            var ret4 = await platform.invokeMethod('req_notify_permissions');
            log.t('🍓ネイティブメソッド req_notify_permissions の戻り値: $ret4');
            _permissionFlow5(successCB, failedCB);
          }
        );
      }
    } catch (e) {
      log.t('🍓ネイティブ呼び出しで例外が発生しました. $e');
      if (failedCB != null) {
        failedCB();
      }
    }
    log.t('🍓MyController#_permissionFlow4() DONE');
  }

  // 5.
  // ・再度，ネイティブメソッド "check_permission" を呼び出す
  // ・すべて true ならば，リクエストフローは成功で終了。
  // ・そうでないならば，以下のダイアログを表示する。
  //   センサをスキャンするために，以下の権限が不足しています。これらの権限を許可してください。
  //     付近のデバイス (Bluetooth)
  //     Bluetooth が OFF になっている
  //     位置情報
  //     通知
  // ・ダイアログが閉じられたら，ネイティブメソッド "req_setting" を呼び出す。
  void _permissionFlow5(VoidCallback? successCB, VoidCallback? failedCB) async {
    log.t('🍓MyController#_permissionFlow5() BEGIN');
    try {
      Map ret = await platform.invokeMethod('check_permissions');
      log.t('🍓ネイティブメソッド check_permissions の戻り値: $ret');
      bool fBluetoothPermission = ret['bluetooth_permission'] ?? false;
      bool fBluetoothPower = ret['bluetooth_power'] ?? false;
      bool fNotificationPermission = ret['notification_permission'] ?? false;
      bool fLocationPermission = ret['location_permission'] ?? false;
      log.t('🍓fBluetoothPermission: $fBluetoothPermission');
      log.t('🍓fBluetoothPower: $fBluetoothPower');
      log.t('🍓fNotificationPermission: $fNotificationPermission');
      log.t('🍓fLocationPermission: $fLocationPermission');
      if (fBluetoothPermission && fBluetoothPower && fNotificationPermission && fLocationPermission) {
        // リクエストフローは成功で終了。
        if (successCB != null) {
          successCB();
        }
        return;
      }
      var msg = 'センサをスキャンするために，以下の権限が不足しています。これらの権限を許可してください。';
      if (!fBluetoothPermission) {
        msg += '\n•付近のデバイス (Bluetooth)';
      }
      if (!fBluetoothPower) {
        msg += '\n•Bluetooth が OFF になっている';
      }
      if (!fLocationPermission) {
        msg += '\n•位置情報';
      }
      if (!fNotificationPermission) {
        msg += '\n•通知';
      }
      mySimpleDialogShow(
          'お願い', msg,
          () async {
            Get.back();
            var ret5 = await platform.invokeMethod('req_setting');
            log.t('🍓ネイティブメソッド req_notify_permissions の戻り値: $ret5');
            _permissionFlow6(successCB, failedCB);
          }
      );
    } catch (e) {
      log.t('🍓ネイティブ呼び出しで例外が発生しました. $e');
      if (failedCB != null) {
        failedCB();
      }
    }
    log.t('🍓MyController#_permissionFlow5() DONE');
  }


  // ・また再度，ネイティブメソッド "check_permission" を呼び出す
  // ・すべて true ならば，リクエストフローは成功で終了。
  // ・false があるならば，以下のダイアログを表示して，失敗を確定する。
  // ・以下の権限が不足しているため，センサのスキャンを開始できませんでした。
  //     付近のデバイス (Bluetooth)
  //     Bluetooth が OFF になっている
  //     位置情報
  //     通知
  void _permissionFlow6(VoidCallback? successCB, VoidCallback? failedCB) async {
    log.t('🍓MyController#permissionFlow6() BEGIN');
    try {
      Map ret = await platform.invokeMethod('check_permissions');
      log.t('🍓ネイティブメソッド check_permissions の戻り値: $ret');
      bool fBluetoothPermission = ret['bluetooth_permission'] ?? false;
      bool fBluetoothPower = ret['bluetooth_power'] ?? false;
      bool fNotificationPermission = ret['notification_permission'] ?? false;
      bool fLocationPermission = ret['location_permission'] ?? false;
      log.t('🍓fBluetoothPermission: $fBluetoothPermission');
      log.t('🍓fBluetoothPower: $fBluetoothPower');
      log.t('🍓fNotificationPermission: $fNotificationPermission');
      log.t('🍓fLocationPermission: $fLocationPermission');
      if (fBluetoothPermission && fBluetoothPower && fNotificationPermission && fLocationPermission) {
        // リクエストフローは成功で終了。
        if (successCB != null) {
          successCB();
        }
        return;
      }
      var msg = '以下の権限が不足しているため，センサのスキャンを開始できませんでした。 ';
      if (!fBluetoothPermission) {
        msg += '\n•付近のデバイス (Bluetooth)';
      }
      if (!fBluetoothPower) {
        msg += '\n•Bluetooth が OFF になっている';
      }
      if (!fLocationPermission) {
        msg += '\n•位置情報';
      }
      if (!fNotificationPermission) {
        msg += '\n•通知';
      }
      mySimpleDialogShow(
        'お願い', msg,
        () async {
          Get.back();
          if (failedCB != null) {
            failedCB();
          }
        }
      );
    } catch (e) {
      log.t('🍓ネイティブ呼び出しで例外が発生しました. $e');
      if (failedCB != null) {
        failedCB();
      }
    }
    log.t('🍓MyController#permissionFlow6() DONE');
  }
}