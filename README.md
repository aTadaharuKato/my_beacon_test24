# my_beacon_test24

アプリ名「環境センサ X Viewer」

温湿度気圧センサビーコン APZ-110 から，温度，湿度，気圧値を読み取り表示するアプリ。

Google Play で，内部テストで公開までした。

ただし，あくまでアプリ公開の練習用であり，一般公開までもっていくつもりはない。

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Release Build

### 準備

key.properties, key.jks を作業ツリーにコピーしてください。

|file|copy destination location|
|---------|-------------|
|key.properties|	my_beacon_test24/android|
|key.jks|	my_beacon_test24/android/app|


### 動作確認用 apk の作成
```
flutter build apk --build-name=1.0.0 --build-number=3
```

### リリース用の appbundle 作成
```
flutter build appbundle --release --build-name=1.0.0 --build-number=3 --obfuscate --split-debug-info=build/app/outputs/obfuscate/android
```

### apk のインストール
```
C:\Users\katot\GITHUBapp\my_beacon_test24>adb devices -l
* daemon not running; starting now at tcp:5037
* daemon started successfully
List of devices attached
359971910538783        device product:SH-RM19s model:SH_RM19s device:Nee transport_id:1


C:\Users\katot\GITHUBapp\my_beacon_test24>adb -s 359971910538783 install build\app\outputs\flutter-apk\app-release.apk
Performing Streamed Install
Success

C:\Users\katot\GITHUBapp\my_beacon_test24>
```