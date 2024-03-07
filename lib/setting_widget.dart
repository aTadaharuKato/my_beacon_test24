import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_beacon_test24/my_controller.dart';

import 'json_data_class.dart';
import 'main.dart';

/// 設定画面，ドロワーで「設定」を選択したときに表示するウィジェット.
class MySettingWidget extends StatelessWidget {
  const MySettingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    log.t('🍓MySettingWidget#build() BEGIN');
    var ret = SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('デバイス一覧', style: Theme.of(context).textTheme.titleLarge),

            // 表でデバイス一覧を表示する.
            GetBuilder<MyController>(builder: (controller) {
              log.t('🍎🍎🍎🍎 MySettingWidget#GetBuilder()');
              KDeviceSet deviceSet = controller.myDeviceSet;

              if (deviceSet.getNumberOfDevices() == 0) {
                log.t('🍓登録デバイスがありません!');
                return Container(
                  width: double.infinity,
                  margin: EdgeInsets.all(8),
                  color: Colors.indigo.shade100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('登録デバイスがありません',style: Theme.of(context).textTheme.titleMedium),
                      Text('デバイスを検索して，登録しましょう.'),
                    ],
                  )
                );
              }

              return Table(
                border: TableBorder.all(),
                columnWidths: const <int, TableColumnWidth> {
                  0: FlexColumnWidth(1.0), 1: FlexColumnWidth(0.4), 2: FlexColumnWidth(1.0),
                },

                children: List.generate(deviceSet.getNumberOfDevices() + 1, (index) {

                  if (index == 0) {
                    // 表の見出し行.
                    return TableRow(
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade100,
                      ),
                      children: [
                        TableCell(
                          child: Center(child: Text('センサ名', style: Theme.of(context).textTheme.bodyLarge)),
                        ),
                        TableCell(
                          child: Center(child: Text('表示', style: Theme.of(context).textTheme.bodyLarge)),
                        ),
                        TableCell(
                          child: Center(child: Text('操作', style: Theme.of(context).textTheme.bodyLarge))
                        ),
                      ],
                    );

                  } else {
                    // デバイス情報の表示.
                    var elem = deviceSet.devices?.elementAt(index - 1);
                    if (elem == null) {
                      throw Exception('unexpected table index!');
                    }
                    return TableRow(
                      children: [
                        // 「センサ名」のカラム
                        TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Column(
                            children: [
                              Text('${elem.nickname}', style: Theme.of(context).textTheme.titleMedium),
                              Text('${elem.bleAddr}', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),

                        // 「表示」のカラム
                        TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Checkbox(
                            value: elem.fShow ?? false,
                            onChanged: (flag) {
                              log.t('🍓「表示」チェックボックスが変更されました. flag: $flag');
                              elem.fShow = flag;
                              var targetDevice = controller.myDeviceSet.devices?.elementAt(index - 1);
                              targetDevice?.fShow = flag;
                              controller.update();
                              controller.storeDeviceSetToNVM();
                            },
                          ),
                        ),

                        // 操作のカラム
                        Column(
                          children: [
                            // 削除ボタン.
                            OutlinedButton.icon(
                              onPressed: () {
                                final deviceIndex = index - 1;
                                log.t('🍓deviceIndex:$deviceIndex の項目を削除します!');
                                if (deviceSet.removeDevice(deviceIndex)) {
                                  controller.update();
                                  controller.storeDeviceSetToNVM();
                                }
                              },
                              icon: const Icon(Icons.delete),
                              label: const Text('削除')
                            ),

                            // 「上へ移動」ボタン (1 行は表示しない)
                            if (index > 1) OutlinedButton.icon(
                              onPressed: () {
                                final deviceIndex = index - 1;
                                log.t('🍓deviceIndex:$deviceIndex の項目を上へ移動します!');

                                if (deviceSet.devices != null) {
                                  List<KDevice> curList = deviceSet.devices!;
                                  var numberOfDevices = curList.length;
                                  // e.g. numberOfDevices = 5, index = 2
                                  // - prev: 0, 1, 2, 3, 4
                                  // - post: 0, 2, 1, 3, 4

                                  // e.g. numberOfDevices = 5, index = 4
                                  // - prev: 0, 1, 2, 3, 4
                                  // - post: 0, 1, 2, 4, 3

                                  // 入れ替え用の空リストを作成.
                                  List<KDevice> newList = [];

                                  // index - 1 より前に要素があるならばコピー.
                                  if (deviceIndex > 1) {
                                    newList += curList.sublist(0, deviceIndex - 1);
                                  }

                                  // index - 1, index を入れ替えてコピー.
                                  newList.add(curList.elementAt(deviceIndex));
                                  newList.add(curList.elementAt(deviceIndex - 1));

                                  // index より後にも，要素があるならばコピー
                                  if (numberOfDevices > (deviceIndex + 1)) {
                                    newList += curList.sublist(deviceIndex + 1, numberOfDevices);
                                  }
                                  deviceSet.devices = newList;
                                  controller.update();
                                  controller.storeDeviceSetToNVM();
                                }
                              },
                              icon: const Icon(Icons.arrow_circle_up),
                              label: const Text('上へ移動')
                            ),

                            // 「名称の変更」ボタン
                            OutlinedButton.icon(
                              onPressed: () {
                                // 元のニックネームを，ダイアログのテキストフィールドに設定する.
                                controller.myDialogTextFieldController.text = elem.nickname ?? "";
                                // 「ニックネーム変更」ダイアログを表示する.
                                Get.dialog(
                                  barrierDismissible: false, // ダイアログ領域外をタップしたときに，ダイアログを閉じないようにする.
                                  PopScope(
                                    canPop: false,
                                    child: AlertDialog(
                                      title: const Text('ニックネーム変更'),
                                      content: TextField(
                                        decoration: const InputDecoration(labelText: '新しいニックネーム'),
                                        controller: controller.myDialogTextFieldController,
                                        keyboardType: TextInputType.text,
                                        //onChanged: (text) {
                                        //  log.t('🍓text: $text');
                                        //},
                                      ),
                                      actions: [
                                        // 「キャンセル」ボタン.
                                        OutlinedButton(
                                            onPressed: () {
                                              Get.back();
                                            },
                                            child: const Text('キャンセル')
                                        ),
                                        // 「OK」ボタン.
                                        OutlinedButton(
                                          onPressed: () {
                                            final newText = controller.myDialogTextFieldController.text;
                                            log.t('🍓編集されたテキストは,「$newText」です.');
                                            if (newText == elem.nickname) {
                                              log.t('🍓これは，以前のニックネームと同じです.');
                                            } else {
                                              // この時点で elem はコピーみたいで，以下の記述では，新しいニックネームが反映されない.
                                              //elem.nickname = newText;
                                              //log.t('elem.nickname: ${elem.nickname}');

                                              final targetDevice = controller.myDeviceSet.devices?.elementAt(index - 1);
                                              log.t('🍓targetDevice?.nickname: ${targetDevice?.nickname}');
                                              targetDevice?.nickname = newText;
                                            }
                                            Get.back();
                                            controller.update();
                                            controller.storeDeviceSetToNVM();
                                          },
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    )
                                  ),
                                );
                              },
                              icon: const Icon(Icons.drive_file_rename_outline),
                              label: const Text('名称の変更'),
                            ),
                          ],
                        ),
                      ]
                    );
                  }
                }),
              );
            }),

            OutlinedButton.icon(
              onPressed: () {
                log.t('🍓「デバイスを検索する.」ボタンの onPressed() BEGIN');
                Get.dialog(
                  barrierDismissible: false, // ダイアログ領域外をタップしたときに，ダイアログを閉じないようにする.
                  PopScope(
                    canPop: false,
                    child: AlertDialog(
                      title: const Text('デバイスを検索しています.'),
                      content: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              strokeWidth: 10,
                            ),
                          ]
                      ),
                      actions: [
                        // 「キャンセル」ボタン.
                        OutlinedButton(
                            onPressed: () {
                              Get.back();
                              Get.find<MyController>().fDeviceSearching = false;
                            },
                            child: const Text('キャンセル')
                        ),
                      ]
                    ),
                  ),
                );
                Get.find<MyController>().fDeviceSearching = true;
                log.t('🍓「デバイスを検索する.」ボタンの onPressed() DONE');
              },
              icon: const Icon(Icons.add),
              label: const Text('デバイスを検索する.'),
            ),
          ],
        ),
      ),
    );
    log.t('🍓MySettingWidget#build() DONE');
    return ret;
  }
}

