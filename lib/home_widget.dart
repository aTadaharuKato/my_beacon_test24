import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_beacon_test24/my_controller.dart';

import 'main.dart';

class MyHomeWidget extends StatelessWidget {
  const MyHomeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    log.t('🍓MyWidget1#build() BEGIN');
    //final size = MediaQuery.of(context).size;
    var ret = SingleChildScrollView(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('センサのスキャン状態', style: TextStyle(fontSize: 18)),
            Row(
              children: [
                const Spacer(),
                Flexible(
                  flex: 19,
                  child: Row(
                    children: [
                      // 切り替えスイッチ「センサのスキャン状態」
                      Obx(() => Switch(
                        value: Get.find<MyController>().fBeaconScanning.value,
                        onChanged: (v) async {
                          log.t('🍓ビーコンスキャンスイッチが変更されました, v:$v');
                          if (Get.find<MyController>().fBeaconScanning.value != v) {
                            try {
                              //int? ret;
                              if (v) {
                                // スキャンを開始する.
                                Get.find<MyController>().permissionFlow1(
                                  () async {
                                    // 成功時の処理
                                    var ret = await MyController.platform.invokeMethod('start_beacon_scan');
                                    log.t('🍓 ネイティブメソッド start_beacon_scan の戻り値, ret: $ret');
                                    Get.find<MyController>().fBeaconScanning.value = true;
                                  },
                                  null
                                );
                              } else {
                                var ret = await MyController.platform.invokeMethod('stop_beacon_scan');
                                log.t('🍓 ネイティブメソッド stop_beacon_scan の戻り値, ret: $ret');
                                Get.find<MyController>().fBeaconScanning.value = false;
                              }

                            } catch (e) {
                              log.t('🍓ネイティブ呼び出しで例外が発生しました. $e');
                            }
                          }
                        },
                      )),
                      Obx(() => Text(Get.find<MyController>().fBeaconScanning.value ? 'ON' : 'OFF')
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            const Text('センサの現在値', style: TextStyle(fontSize: 18)),

            GetBuilder<MyController>(builder: (controller) {
              log.t('🍎🍎🍎🍎 MyHomeWidget#builder()');
              var deviceSet = controller.myDeviceSet;
              var validDeviceList = deviceSet.getValidDevices();
              var validNumberOfDevices = validDeviceList.length;

              return Column(
                children: List.generate(validNumberOfDevices, (index) {
                  // それぞれのデバイスについての情報を表示する.
                  //var device = deviceSet.devices!.elementAt(index);
                  var device = validDeviceList.elementAt(index);

                  var fDataValid = false;

                  var strTemperature = '温度: --.- ℃';
                  if (device.isTheTemperatureAvailable()) {
                    strTemperature = '温度: ${device.getTemperature()} ℃';
                    fDataValid = true;
                  }

                  var strHumidity = '湿度: -- %';
                  if (device.isTheHumidityAvailable()) {
                    strHumidity = '湿度: ${device.getHumidity()} %';
                    fDataValid = true;
                  }

                  var strPressure = '気圧: ---.- hPa';
                  if (device.isThePressureAvailable()) {
                    strPressure = '気圧: ${device.getPressure()} hPa';
                    fDataValid = true;
                  }

                  var strDate = '日時: -/- --:--:--';
                  if (fDataValid) {
                    strDate = '日時: ${device.getDate()}';
                  }
                  log.t('sensor, [$strDate]');
                  //var strDate = DateFormat('MM/dd HH:mm:ss').format(device.);

                  return Card(
                      child: Column(
                        children: [
                          ListTile(
                            title: Text('センサ名: ${device.nickname}'),
                            subtitle: Text('BDADDR: ${device.bleAddr}'),
                          ),
                          Text(strTemperature),
                          Text(strHumidity),
                          Text(strPressure),
                          Text(strDate),
                        ],
                      )
                  );
                }),
              );

            }),


            /*
            // -----------------------------------------------------------------------------------------
            // テスト用のテキストフィールドの定義.
            Row(
              children: [
                const Spacer(),
                Flexible(
                  flex: 10,
                  child: Obx(() => TextField(decoration: const InputDecoration(labelText: '生のテキスト'),
                    controller: Get.find<MyController>().myTextFieldController,
                    keyboardType: TextInputType.text,
                    enabled: Get.find<MyController>().fMyTextFieldEnable.value,
                    onChanged: (text) {
                      log.t('🍓テキストフィールドが変更されました. text: $text');
                      Codec<String, String> stringToBase64 = utf8.fuse(base64);
                      var encodedText = stringToBase64.encode(text);
                      Get.find<MyController>().myEncodedText.value = encodedText;
                    },
                  )),
                ),
              ],
            ),

            // テキストフィールドに入力された文字を base64 エンコードした文字列を表示する.
            const Row(
              children: [
                Spacer(),
                Flexible(
                  flex:20,
                  child: Text('Base64 でエンコードされたテキスト'),
                ),
              ],
            ),
            Row(
              children: [
                const Spacer(),
                Flexible(
                  flex:10,
                  child: Obx(() => Text(Get.find<MyController>().myEncodedText.value)),
                ),
              ],
            ),

            // テキストフィールドの文字列を，SharedPreferences に，キーワード: keyword で保存.
            OutlinedButton(
              onPressed: () async {
                var prefs = await SharedPreferences.getInstance();
                var text = Get.find<MyController>().myTextFieldController.text;
                log.t('🍓テキストを SharedPreferences に保存します. text: $text');
                prefs.setString('keyword', text);
              },
              child: const Text('SharedPreferences 保存'),
            ),

            // SharedPreferences からキーワード: keyword で読み込み，テキストフィールドに設定します.
            OutlinedButton(
              onPressed: () async {
                var prefs = await SharedPreferences.getInstance();
                var text = prefs.getString('keyword') ?? '';
                log.t('🍓text: $text');
                Get.find<MyController>().myTextFieldController.text = text;
              },
              child: const Text('SharedPreferences 読込')),

            // SharedPreferences に，デバイスを定義したダミーデータを登録します.
            OutlinedButton(
              onPressed: () async {
                var text = '''
                    {"devices":[{"ble_addr":"00:1C:4D:40:64:69","nickname":"ジャイアン"},{"ble_addr":"CD:EF:01:23:45:67","nickname":"スネオ"},{"ble_addr":"11:22:33:44:55:66","nickname":"のび太","show_flag":true}]}
                    '''.trim();
                log.t('🍓ダミーデータの Json テキスト, text:$text');
                Codec<String, String> stringToBase64 = utf8.fuse(base64);
                var encodedText = stringToBase64.encode(text);
                log.t('🍓base64エンコードした encodedText:$encodedText');
                var prefs = await SharedPreferences.getInstance();
                prefs.setString('devices', encodedText);
              },
              child: const Text('ダミーデータ作成')),

            OutlinedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final encodedText = prefs.getString('devices') ?? '';
                log.t('🍓SharedPreferences から読み込んだ devices のエンコードされたテキスト, encodedText:$encodedText');
                final Codec<String, String> stringToBase64 = utf8.fuse(base64);
                final text = stringToBase64.decode(encodedText);
                log.t('🍓base64デコードした Json テキスト, text:$text');

                final jsonMap = jsonDecode(text);
                log.t('🍓Json デコードした テキスト, jsonMap:$jsonMap');
                final newDeviceSet = KDeviceSet.fromJson(jsonMap);
                Get.find<MyController>().myDeviceSet = newDeviceSet;

                log.t('🍓newDeviceSet:$newDeviceSet');
                log.t('🍓newDeviceSet.devices ${newDeviceSet.devices}');
                log.t('🍓newDeviceSet.devices.length: ${newDeviceSet.devices?.length}');
                var num = 0;
                newDeviceSet.devices?.forEach((element) {
                  log.t('🍓[$num] element: ${element.toJson()}');
                  num++;
                });
              },
              child: const Text('ダミーデータ読込')
            ),
             */

          ],
        ),
      ),
    );
    log.t('🍓MyWidget1#build() DONE');
    return ret;
  }
}

