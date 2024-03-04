import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_beacon_test24/my_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'json_data_class.dart';
import 'main.dart';

class MyHomeWidget extends StatelessWidget {
  const MyHomeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    log.t('🍓🍓MyWidget1#build() BEGIN');
    final size = MediaQuery.of(context).size;
    var ret = SingleChildScrollView(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('温湿度気圧センサの現在値'),

            Obx(() {
              var deviceSet = Get.find<MyController>().deviceset.value;
              var numberOfDevices =deviceSet.getNumberOfDevices();
              return Column(
                children: List.generate(numberOfDevices, (index) {
                  // それぞれのデバイスについての情報を表示する.
                  var device = deviceSet.devices!.elementAt(index);

                  var strTemperature = '温度: --.- ℃';
                  if (device.isTheTemperatureAvailable()) {
                    strTemperature = '温度: ${device.getTemperature()} ℃';
                  }

                  var strHumidity = '湿度: -- %';
                  if (device.isTheHumidityAvailable()) {
                    strHumidity = '湿度: ${device.getHumidity()} %';
                  }

                  var strPressure = '気圧: ---.- hPa';
                  if (device.isThePressureAvailable()) {
                    strPressure = '気圧: ${device.getPressure()} hPa';
                  }

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
                      ],
                    )
                  );
                }),
              );
            }),


            Row(
              children: [
                Spacer(),
                Flexible(
                  flex: 10,
                  child: Obx(() => TextField(decoration: InputDecoration(labelText: '生のテキスト'),
                    controller: Get.find<MyController>().textedit_controller,
                    keyboardType: TextInputType.text,
                    enabled: Get.find<MyController>().f_textedit_enable.value,
                    onChanged: (text) {
                      print('text: $text');
                      Codec<String, String> stringToBase64 = utf8.fuse(base64);
                      var outtext = stringToBase64.encode(text);
                      Get.find<MyController>().output_text.value = outtext;
                    },
                  )),
                ),
              ],
            ),
            Row(
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
                Spacer(),
                Flexible(
                  flex:10,
                  child: Obx(() => Text(Get.find<MyController>().output_text.value)),
                ),
              ],
            ),

            OutlinedButton(
              onPressed: () async {
                var prefs = await SharedPreferences.getInstance();
                var text = Get.find<MyController>().textedit_controller.text;
                log.t('text: $text');
                prefs.setString('keyword', text);
              },
              child: Text('SharedPreferences Store'),
            ),
            OutlinedButton(
              onPressed: () async {
                var prefs = await SharedPreferences.getInstance();
                var text = prefs.getString('keyword') ?? '';
                log.t('text: $text');
                Get.find<MyController>().textedit_controller.text = text;
              },
              child: Text('SharedPreferences Load')),
            OutlinedButton(
              onPressed: () async {
                var directory = await getApplicationDocumentsDirectory();
                log.t('directory: $directory');
                var file = File('${directory.path}/hoge.txt');
                if (!await file.exists()) {
                  await file.create();
                } else {
                }
              },
              child: Text('Save File')
            ),
            OutlinedButton(
                onPressed: () async {
                  log.t('Button pressed.');
                  try {
                    var ret = await MyController.platform.invokeMethod('create_dummy_data',
                    '''
                    {"devices":[{"ble_addr":"01:23:45:67:89:AB","nickname":"ジャイアン"},{"ble_addr":"CD:EF:01:23:45:67","nickname":"スネオ"}]}
                    '''
                    );
                    log.t('ret: $ret');
                  } catch (e) {
                    log.t('ネイティブ呼び出しで例外が発生しました. $e');
                  }
                },
                child: Text('ダミーデータ作成 (Native)'),
            ),

            OutlinedButton(
              onPressed: () async {
                var src = '''
                    {"devices":[{"ble_addr":"01:23:45:67:89:AB","nickname":"ジャイアン"},{"ble_addr":"CD:EF:01:23:45:67","nickname":"スネオ"}]}
                    '''.trim();
                log.t('src:$src');
                Codec<String, String> stringToBase64 = utf8.fuse(base64);
                var outtext = stringToBase64.encode(src);
                log.t('エンコードされたsrc:$outtext');
                var prefs = await SharedPreferences.getInstance();
                prefs.setString('devices', outtext);
              },
              child: Text('ダミーデータ作成 (Dart)')),

            OutlinedButton(
              onPressed: () async {
                var prefs = await SharedPreferences.getInstance();
                var encdtext = prefs.getString('devices') ?? '';
                log.t('srcdtext:$encdtext');
                Codec<String, String> stringToBase64 = utf8.fuse(base64);
                var text = stringToBase64.decode(encdtext);
                log.t('text:$text');

                var x = jsonDecode(text);
                log.t('x:$x, ${x.runtimeType}');
                var y = KDeviceSet.fromJson(x);
                Get.find<MyController>().deviceset.value = y;

                log.t('y:$y, ${y.runtimeType}');
                log.t('y.devices ${y.devices}');
                log.t('y.devices.length: ${y.devices?.length}');
                y.devices?.forEach((element) {
                  log.t('element: ${element.toJson()}');
                });
              },
              child: Text('ダミーデータ読込 (Dart)')
            ),

          ],
        ),
      ),
    );
    log.t('🍓🍓MyWidget1#build() DONE');
    return ret;
  }
}

