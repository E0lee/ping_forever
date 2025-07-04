import 'dart:async';
import 'dart:ui';

import 'package:dart_ping/dart_ping.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

@pragma('vm:entry-point')
class BGtest {
  static String _targetIp = '8.8.8.8';

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        // this will be executed when app is in foreground or background in separated isolate
        onStart: onStart,

        // auto start service
        autoStart: true,
        isForegroundMode: true,
        autoStartOnBoot: true,
        notificationChannelId:
            "user_channel_123", // this must match with notification channel you created above.
        initialNotificationTitle: '熱點維穩服務開啟',
        initialNotificationContent: '請勿清除背景程式',
        foregroundServiceNotificationId: 12,
        foregroundServiceTypes: [AndroidForegroundType.dataSync],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  static void setTargetIp(String ip) {
    _targetIp = ip;
    print("設定目標IP: $_targetIp");
  }

  static String getTargetIp() {
    return _targetIp;
  }

  static void startBackgroundService() {
    final service = FlutterBackgroundService();

    service.startService();
    Timer(Duration(seconds: 1), () {
      service.invoke("setIp", {"ip": _targetIp});
      print("發送IP到背景服務: $_targetIp");
    });
  }

  static void stopBackgroundService() {
    final service = FlutterBackgroundService();
    service.invoke("stop");
  }
}

@pragma('vm:entry-point') //要留
Future<bool> onIosBackground(ServiceInstance service) async {
  print("BGTest onIosBackground");
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  return true;
}

@pragma('vm:entry-point')
String generateChannelId(int userId) {
  // Ensure the ID only contains valid characters
  // Avoid spaces, question marks, or other special characters
  return "user_channel_$userId"; // Example: "user_channel_42"
}

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  print("BGTest onStart");
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();
  String currentIp = '8.8.8.8';

  service.on("stop").listen((event) {
    service.stopSelf();
    print("background process is now stopped");
  });

  service.on("start").listen((event) {});

  service.on("setIp").listen((event) {
    currentIp = event!["ip"];
    print("背景服務收到新IP: $currentIp");
  });

  // bring to foreground
  Timer.periodic(const Duration(seconds: 5), (timer) async {
    print("Timer.periodic " + currentIp);

    final ping = Ping(currentIp, count: 1).stream.first;

    // 更新前台通知
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "網路監控運行中",
        content: "監控 $currentIp",
      );

      // 確認仍是前台服務
      if (!await service.isForegroundService()) {
        service.setAsForegroundService();
        print("重新設定為前台服務");
      }
    }

    return;
    if ((service is AndroidServiceInstance &&
            await service.isForegroundService()) ||
        service is IOSServiceInstance) {}
    return;
    // print("AndroidServiceInstance");
    if (service is AndroidServiceInstance) {
      // print("isForegroundService");
    } else {
      // print("DarwinServiceInstance");

      //通知分組用
      /* const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(threadIdentifier: 'thread_id');
      flutterLocalNotificationsPlugin.show(
        1,
        'IOS TITLE',
        'body ${DateTime.now()}',
        payload: "item ios",
        NotificationDetails(iOS: iOSPlatformChannelSpecifics),
      );*/
    }
  });
}
