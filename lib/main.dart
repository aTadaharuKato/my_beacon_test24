import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

import 'my_controller.dart';

final Log = Logger(printer: SimplePrinter(colors: true, printTime: true));

void main() {
  // 違いがわからないけど，とりあえず呼んでおく.
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Log.t('🍓🍓MyApp#build() BEGIN');

    Get.put(MyController());

    var ret = GetMaterialApp(
      title: 'My Beacon Test \'24',
      theme: ThemeData(
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      initialRoute: '/',
        getPages: [
          GetPage(name: '/',          page: () => MyHomePage()),          // メイン画面
        ]
    );
    Log.t('🍓🍓MyApp#build() DONE');
    return ret;
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    Log.t('🍓🍓MyHomePage#build() BEGIN');
    var ret = Scaffold(
      appBar: AppBar(
        title: Text('My Beacon Test \'24'),
      ),
      body: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Obx(() => Text('領域内／外: ${Get.find<MyController>().regionStatus.value}')),
                OutlinedButton(
                  onPressed: () async {
                    try {
                      var ret = await MyController.platform.invokeMethod('start_beacon_scan');
                      Log.t('ret: $ret');
                    } catch (e) {
                      Log.t('ネイティブ呼び出しで例外が発生しました. $e');
                    }
                  },
                  child: Text('ビーコンスキャン開始')
                ),
                OutlinedButton(
                  onPressed: () async {
                    try {
                      var ret = await MyController.platform.invokeMethod('stop_beacon_scan');
                      Log.t('ret: $ret');
                    } catch (e) {
                      Log.t('ネイティブ呼び出しで例外が発生しました. $e');
                    }
                  },
                  child: Text('ビーコンスキャン停止')
                ),
              ],
            ),
          ),
      ),
    );
    Log.t('🍓🍓MyHomePage#build() DONE');
    return ret;
  }

}
