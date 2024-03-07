import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_beacon_test24/my_controller.dart';

import 'json_data_class.dart';
import 'main.dart';

/// ドロワーで「設定」を選択したときに表示するウィジェット.
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
              log.t('🍎🍎🍎🍎 MySettingWidget');
              KDeviceSet deviceSet = controller.myDeviceSet.value;
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
                          child: Center(
                            child: Text('センサ名', style: Theme.of(context).textTheme.bodyLarge),
                          ),
                        ),
                        TableCell(
                          child: Center(
                            child: Text('表示', style: Theme.of(context).textTheme.bodyLarge),
                          ),
                        ),
                        TableCell(
                          child: Center(
                            child: Text('操作', style: Theme.of(context).textTheme.bodyLarge),
                          )
                        ),
                      ],
                    );
                  } else {

                    // デバイス情報の表示.
                    var elem = deviceSet.devices?.elementAt(index - 1);
                    if (elem != null) {
                      return TableRow(
                          children: [
                            TableCell(
                              verticalAlignment: TableCellVerticalAlignment.middle,
                              child: Column(
                                children: [
                                  Text('${elem.nickname}', style: Theme.of(context).textTheme.titleMedium),
                                  Text('${elem.bleAddr}', style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ),

                            TableCell(
                              verticalAlignment: TableCellVerticalAlignment.middle,
                              child: Checkbox(
                                value: elem.fShow ?? false,
                                onChanged: (flag) {
                                  log.t('flag: $flag');
                                  elem.fShow = flag;

                                  var xelem = controller.myDeviceSet.value.devices?.elementAt(index - 1);
                                  xelem?.fShow = flag;

                                  controller.update();
                                  controller.storeDeviceSetToNVM();
                                },
                              ),
                            ),


                            Column(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.delete),
                                  label: const Text('削除')
                                ),

                                if (index > 1) OutlinedButton.icon(
                                    onPressed: () {
                                      var elemindex = index - 1;
                                      log.t('elemindex:$elemindex の項目を上へ移動します!');

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
                                        if (elemindex > 1) {
                                          newList += curList.sublist(0, elemindex - 1);
                                        }

                                        // index - 1, index を入れ替えてコピー.
                                        newList.add(curList.elementAt(elemindex));
                                        newList.add(curList.elementAt(elemindex - 1));

                                        // index より後にも，要素があるならばコピー
                                        if (numberOfDevices > (elemindex + 1)) {
                                          newList += curList.sublist(elemindex + 1, numberOfDevices);
                                        }
                                        deviceSet.devices = newList;
                                        controller.update();

                                        controller.storeDeviceSetToNVM();
                                      }
                                    },
                                    icon: const Icon(Icons.arrow_circle_up),
                                    label: Text('上へ移動')
                                ),

                                OutlinedButton.icon(
                                  onPressed: () {
                                    controller.myDialogTextFieldController.text = elem.nickname ?? "";
                                    Get.dialog(
                                      AlertDialog(
                                        title: Text('ニックネーム変更'),
                                        //content: Text('CONTENT'),
                                        content: TextField(
                                          decoration: InputDecoration(labelText: '新しいニックネーム'),
                                          controller: controller.myDialogTextFieldController,
                                          keyboardType: TextInputType.text,
                                          onChanged: (text) {
                                            log.t('text: $text');
                                          },
                                        ),
                                        actions: [
                                          OutlinedButton(
                                            onPressed: () {
                                              Get.back();
                                            },
                                            child: Text('キャンセル')
                                          ),
                                          OutlinedButton(
                                            onPressed: () {
                                              var newText = controller.myDialogTextFieldController.text;
                                              log.t('編集されたテキストは,「$newText」です.');
                                              if (newText == elem.nickname) {
                                                log.t('これは，以前のニックネームと同じです.');
                                              } else {
                                                // この時点で elem はコピーみたいで，以下の記述では，新しいニックネームが反映されない.
                                                //elem.nickname = newText;
                                                //log.t('elem.nickname: ${elem.nickname}');

                                                var xelem = controller.myDeviceSet.value.devices?.elementAt(index - 1);
                                                log.t('xelem?.nickname: ${xelem?.nickname}');
                                                xelem?.nickname = newText;
                                              }
                                              Get.back();
                                              controller.update();
                                              controller.storeDeviceSetToNVM();
                                            },
                                            child: Text('OK'),
                                          ),
                                        ],
                                      )
                                    );
                                  },
                                  icon: const Icon(Icons.drive_file_rename_outline),
                                  label: Text('名称の変更'),
                                ),
                              ],
                            ),
                          ]
                      );
                    } else {
                      throw Exception('unexpected table index!');
                    }
                  }


                }),
              );
            }),
          ],
        ),
      ),
    );
    log.t('🍓MySettingWidget#build() DONE');
    return ret;
  }
}



class TextEditingDialog extends StatelessWidget {
  const TextEditingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    log.t('🍓TextEditingDialog#build() BEGIN');
    final size = MediaQuery.of(context).size;
    var ret = SingleChildScrollView(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(onPressed: () {
              Get.back();
            }, child: Text('OK'))
          ],
        ),
      ),
    );
    log.t('🍓TextEditingDialog#build() DONE');
    return ret;
  }
}
