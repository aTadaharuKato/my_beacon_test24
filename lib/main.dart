import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

import 'home_widget.dart';
import 'setting_widget.dart';
import 'my_controller.dart';

final log = Logger(printer: SimplePrinter(colors: true, printTime: true));

void main() {
  // 違いがわからないけど，とりあえず呼んでおく.
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    log.t('🍓MyApp#build() BEGIN');

    Get.put(MyController());

    var ret = GetMaterialApp(
      title: 'My Beacon Test \'24',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          color: Colors.blue,
          titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          color: Colors.indigo,
          titleTextStyle: TextStyle(
              color: Colors.white60,
              fontSize: 18,
              fontWeight: FontWeight.bold
          ),
        ),
      ),
      initialRoute: '/',
        getPages: [
          GetPage(name: '/',          page: () => MyHomePage()),          // メイン画面
        ]
    );
    log.t('🍓MyApp#build() DONE');
    return ret;
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({super.key});

  final _routes = [
    const MyHomeWidget(),
    const MySettingWidget(),
    const MyWidget3(),
  ];

  @override
  Widget build(BuildContext context) {
    log.t('🍓MyHomePage#build() BEGIN');

    Get.find<MyController>().initialTask();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      log.t("🍓 PostFrameCallback, $timeStamp");
    });


    var ret = Scaffold(
      appBar: AppBar(
        title: const Text('My Beacon Test \'24'),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            SizedBox(
              height: 80,
              child: DrawerHeader(
                decoration: const BoxDecoration(color: Colors.blue),
                child: Row(
                  children: [
                    Image.asset('assets/MyIcon5s.png'),
                    const SizedBox(width: 10),
                    const Text('My Beacon Test\'24'),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('ホーム'),
              onTap: () {
                log.t('⛄ホームがタップされました.');
                Navigator.of(context).pop(); // ドロワーを閉じる.
                if (Get.find<MyController>().selectedIndex.value != 0) {
                  Get.find<MyController>().selectedIndex.value = 0;
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('設定'),
              onTap: () {
                 log.t('⛄設定がタップされました.');
                 Navigator.of(context).pop(); // ドロワーを閉じる.
                 if (Get.find<MyController>().selectedIndex.value != 1) {
                   Get.find<MyController>().selectedIndex.value = 1;
                 }
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('ヘルプ'),
              onTap: () {
                log.t('⛄ヘルプがタップされました.');
                Navigator.of(context).pop(); // ドロワーを閉じる.
                if (Get.find<MyController>().selectedIndex.value != 2) {
                  Get.find<MyController>().selectedIndex.value = 2;
                }
              },
            ),
          ],
        ),
      ),
      //body: Obx(() => _routes.elementAt(Get.find<MyController>().selectedIndex.value)),

      body: Obx(() {
        if (Get.find<MyController>().fHomePageReady.value == false) {
          return const SafeArea(
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 10,
              ),
            ),
          );
        } else {
          return _routes.elementAt(Get.find<MyController>().selectedIndex.value);
        }
      }),
    );
    log.t('🍓MyHomePage#build() DONE');
    return ret;
  }
}






class MyWidget3 extends StatelessWidget {
  const MyWidget3({super.key});

  @override
  Widget build(BuildContext context) {
    log.t('🍓MyWidget3#build() BEGIN');
    final size = MediaQuery.of(context).size;
    var ret = SingleChildScrollView(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: size.height / 4),
            SizedBox(
              height: 100,
              child: Image.asset('assets/MyIcon5s.png'),
            ),
            Text(Get.find<MyController>().appName, style: const TextStyle(fontSize: 20)),
            Text('バージョン ${Get.find<MyController>().appVer} (${Get.find<MyController>().buildNumber})'),
            const Text('© 2024 Tadaharu Kato'),
          ],
        ),
      ),
    );
    log.t('🍓MyWidget3#build() DONE');
    return ret;
  }
}




/*
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
                OutlinedButton(
                    onPressed: () async {
                      try {
                        var ret = await MyController.platform.invokeMethod('test_notification');
                        Log.t('ret: $ret');
                      } catch (e) {
                        Log.t('ネイティブ呼び出しで例外が発生しました. $e');
                      }
                    },
                    child: Text('通知テスト')
                ),

                Card(
                  child: Column(
                    children: [
                      Obx(() {
                        var d = Get.find<MyController>().data.value;
                        var s = '温度: ${d.temperature.toStringAsFixed(1)} ℃\n湿度: ${d.humidity} %\n気圧: ${d.pressure.toStringAsFixed(1)} hPa';
                        return ListTile(
                          title: Text('${Get.find<MyController>().data.value.device}'),
                          subtitle: Text(s),
                        );
                      }),
                    ],
                  ),
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


 */