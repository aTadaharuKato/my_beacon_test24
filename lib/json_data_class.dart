
import 'main.dart';

// https://javiercbk.github.io/json_to_dart/ で作成したものを元にしている.
class KDeviceSet {
  List<KDevice>? devices;

  KDeviceSet({this.devices});

  /// index で指定するデバイスを devices リストから削除します.
  bool removeDevice(int index) {
    log.t('🍇KDeviceSet#removeDevice(index:$index) BEGIN');
    bool fModified = false;
    if (devices != null) {
      var numberOfDevices = devices!.length;
      // 入れ替え用の空リストを作成.
      List<KDevice> newList = [];

      // e.g. numberOfDevices = 5, index = 2
      // - prev: 0, 1, 2, 3, 4
      // - post: 0, 1, 3, 4

      if (index > 0) {
        newList += devices!.sublist(0, index);
      }
      if (index < (numberOfDevices - 1)) {
        newList += devices!.sublist(index + 1, numberOfDevices);
      }
      devices = newList;
      fModified = true;
    }
    log.t('🍇KDeviceSet#removeDevice(index:$index) DONE');
    return fModified;
  }

  /// 登録されているデバイス数（表示をしないものを含む）を取得する.
  int getNumberOfDevices() {
    if (devices != null) {
      return devices!.length;
    }
    return 0;
  }

  /// 有効な（すなわち，設定画面で，表示にチェックした）デバイスのリストを取得します.
  List<KDevice> getValidDevices() {
    log.t('🍇KDeviceSet#getValidDevices() BEGIN');
    List<KDevice> newList = [];
    if (devices != null) {
      devices?.forEach((element) {
        if (element.fShow != null) {
          if (element.fShow != false) {
            newList.add(element);
          }
        }
      });
    }
    log.t('🍇KDeviceSet#getValidDevices() DONE');
    return newList;
  }

  KDeviceSet.fromJson(Map<String, dynamic> json) {
    if (json['devices'] != null) {
      devices = <KDevice>[];
      json['devices'].forEach((v) {
        devices!.add(KDevice.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (devices != null) {
      data['devices'] = devices!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}


class KDevice {
  String? bleAddr;
  String? nickname;
  bool? fShow;

  double _temperature = double.negativeInfinity;
  double _humidity = double.negativeInfinity;
  double _pressure = double.negativeInfinity;

  bool setSensorData([double? temperature, double? humidity, double? pressure]) {
    bool fModified = false;
    if (temperature != null) {
      if (_temperature != temperature) {
        fModified = true;
        _temperature = temperature;
      }
    }
    if (humidity != null) {
      if (_humidity != humidity) {
        fModified = true;
        _humidity = humidity;
      }
    }
    if (pressure != null) {
      if (_pressure != pressure) {
        fModified = true;
        _pressure = pressure;
      }
    }
    return fModified;
  }

  bool isTheTemperatureAvailable() {
    return (_temperature != double.negativeInfinity);
  }

  String getTemperature() {
    if (isTheTemperatureAvailable()) {
      return _temperature.toStringAsFixed(1);
    } else {
      return "不明";
    }
  }

  bool isTheHumidityAvailable() {
    return (_humidity != double.negativeInfinity);
  }

  String getHumidity() {
    if (isTheHumidityAvailable()) {
      return _humidity.toStringAsFixed(0);
    } else {
      return "不明";
    }
  }

  bool isThePressureAvailable() {
    return (_pressure != double.negativeInfinity);
  }

  String getPressure() {
    if (isThePressureAvailable()) {
      return _pressure.toStringAsFixed(1);
    } else {
      return "不明";
    }
  }

  KDevice({this.bleAddr, this.nickname, this.fShow});

  KDevice.fromJson(Map<String, dynamic> json) {
    bleAddr = json['ble_addr'];
    nickname = json['nickname'];
    fShow = json['show_flag'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['ble_addr'] = bleAddr;
    data['nickname'] = nickname;
    data['show_flag'] = (fShow == null) ? false : fShow;
    return data;
  }
}