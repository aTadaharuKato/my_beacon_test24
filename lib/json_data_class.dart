
// https://javiercbk.github.io/json_to_dart/
import 'main.dart';

class KDeviceSet {
  List<KDevice>? devices;
  List<KDevice> _validDevices = [];

  KDeviceSet({this.devices});



  int getNumberOfDevices() {
    if (devices != null) {
      return devices!.length;
    }
    return 0;
  }

  /***
   * 有効な（すなわち，設定画面で，表示にチェックした）デバイスのリストを取得します.
   */
  List<KDevice> getValidDevices() {
    log.t('🍇KDeviceSet#getValidDevices() BEGIN');
    List<KDevice> newList = [];
    var numDevices = 0;
    if (devices != null) {
      devices?.forEach((element) {
        if (element.fShow != null) {
          if (element.fShow != false) {
            numDevices++;
            newList.add(element);
          }
        }
      });
    }
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
    final Map<String, dynamic> data = Map<String, dynamic>();
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
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['ble_addr'] = bleAddr;
    data['nickname'] = nickname;
    data['show_flag'] = (fShow == null) ? false : fShow;
    return data;
  }
}