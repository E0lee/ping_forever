import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Global.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class Notitest {
  static Future<void> initializeService() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      await Permission.ignoreBatteryOptimizations.request();

      final bool grantedNotificationPermission =
          await androidImplementation?.requestNotificationsPermission() ??
          false;

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        "user_channel_123", // id
        '候診通知服務', // title
        description: '保持通知開啟，您將得到最快速的通知服務', // description
        importance: Importance.low, // importance must be at low or higher level
      );
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    } else {
      final DarwinInitializationSettings initializationSettingsDarwin =
          new DarwinInitializationSettings();

      final InitializationSettings initializationSettings =
          InitializationSettings(iOS: initializationSettingsDarwin);
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );
    }
  }

  static Future<bool> requestPermissions() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool("IN_NOTI_ON") != null && !prefs.getBool("IN_NOTI_ON")!)
      return false;

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      final bool grantedNotificationPermission =
          await androidImplementation?.requestNotificationsPermission() ??
          false;

      if (!grantedNotificationPermission) {
        await showDialog<void>(
          context: navigatorKey.currentState!.overlay!.context,
          builder:
              (BuildContext context) => AlertDialog(
                title: Text("您未開啟通知"),
                content: Text("App將無法及時提醒，是否需要開啟？"),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      openAppSettings();
                      SystemNavigator.pop();
                    },
                    child: const Text('開啟'),
                  ),
                  TextButton(
                    onPressed: () {
                      prefs.setBool("IN_NOTI_ON", false);
                      Navigator.of(context).pop();
                    },
                    child: const Text('取消'),
                  ),
                ],
              ),
        );
      } else {
        prefs.setBool("IN_NOTI_ON", true);
        return true;
        //開啟pop up得到最即時的消息
      }
    } else if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      final NotificationsEnabledOptions? isEnabled =
          await flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.checkPermissions();

      if (isEnabled == null || !isEnabled.isEnabled) {
        await showDialog<void>(
          context: navigatorKey.currentState!.overlay!.context,
          builder:
              (BuildContext context) => AlertDialog(
                title: Text("您未開啟通知"),
                content: Text("App將無法及時提醒，是否需要開啟？"),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      openAppSettings();
                      Navigator.of(context).pop();
                    },
                    child: const Text('開啟'),
                  ),
                  TextButton(
                    onPressed: () async {
                      prefs.setBool("IN_NOTI_ON", false);
                      Navigator.of(context).pop();
                    },
                    child: const Text('取消'),
                  ),
                ],
              ),
        );
      } else {
        prefs.setBool("IN_NOTI_ON", true);
        return true;
      }
    }
    return false;
  }

  static Future<void> showNotification(
    int id,
    String title,
    String body, {
    required String payload,
  }) async {
    if (Platform.isAndroid) {
      String notificationChannelId = "user_channel_$id";
      flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        payload: payload,
        NotificationDetails(
          android: AndroidNotificationDetails(
            notificationChannelId, //不能帶變數 問號？
            'MY FOREGROUND SERVICE',
            icon: '@mipmap/ic_launcher',
            // ongoing: true,
            // importance: Importance.max,
            // priority: Priority.high,
            // category: AndroidNotificationCategory.alarm,
          ),
        ),
      );
    } else {
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(threadIdentifier: 'thread_id');
      flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        payload: payload,
        NotificationDetails(iOS: iOSPlatformChannelSpecifics),
      );
    }
  }
}

@pragma('vm:entry-point')
void onDidReceiveNotificationResponse(
  //案通知會跑到這來
  NotificationResponse details,
) async {
  print("onDidReceiveNotificationResponse");

  final String? payload = details.payload;
  if (details.payload != null) {
    print('notification payload: $payload');
  }
  // await Navigator.push(
  //   context,
  //   MaterialPageRoute<void>(builder: (context) => SecondScreen(payload)),
  // );
}

@pragma('vm:entry-point') //app被殺的處理
void notificationTapBackground(NotificationResponse notificationResponse) {
  // handle action
  print("notificationTapBackground");
  final String? payload = notificationResponse.payload;
  print('背景通知被點擊，payload: $payload');
}
