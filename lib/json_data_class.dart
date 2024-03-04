
// https://javiercbk.github.io/json_to_dart/
class KDeviceSet {
  List<KDevice>? devices;

  KDeviceSet({this.devices});

  int getNumberOfDevices() {
    if (devices != null) {
      return devices!.length;
    }
    return 0;
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

  double _temperature = double.negativeInfinity;
  double _humidity = double.negativeInfinity;
  double _pressure = double.negativeInfinity;

  void setSensorData([double? temperature, double? humidity, double? pressure]) {
    if (temperature != null) {
      _temperature = temperature;
    }
    if (humidity != null) {
      _humidity = humidity;
    }
    if (pressure != null) {
      _pressure = pressure;
    }
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

  KDevice({this.bleAddr, this.nickname});

  KDevice.fromJson(Map<String, dynamic> json) {
    bleAddr = json['ble_addr'];
    nickname = json['nickname'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['ble_addr'] = bleAddr;
    data['nickname'] = nickname;
    return data;
  }
}