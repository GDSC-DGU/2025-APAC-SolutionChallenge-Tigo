import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:tigo/app/utility/log_util.dart';

import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/timezone.dart';
import 'package:tigo/app/config/app_routes.dart';
import 'package:tigo/app/utility/log_util.dart';
import 'package:tigo/data/factory/storage_factory.dart';
import 'package:tigo/data/provider/common/system_provider.dart';
import 'package:tigo/presentation/view_model/root/root_view_model.dart';

abstract class NotificationUtil {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static bool isFlutterLocalNotificationsInitialized = false;

  static const AndroidNotificationDetails
  _androidPlatformLocalChannelSpecifics = AndroidNotificationDetails(
    'tigo_local_channel_id',
    'Tigo',
    channelDescription: 'Tigo Channel',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: false,
  );

  static const AndroidNotificationDetails
  _androidPlatformRemoteChannelSpecifics = AndroidNotificationDetails(
    'tigo_remote_channel_id',
    'Tigo',
    channelDescription: 'Tigo Channel',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: false,
  );

  static const NotificationDetails _platformLocalChannelSpecifics =
  NotificationDetails(
    android: _androidPlatformLocalChannelSpecifics,
    iOS: DarwinNotificationDetails(
      badgeNumber: 1,
    ),
  );

  static const NotificationDetails _platformRemoteChannelSpecifics =
  NotificationDetails(
    android: _androidPlatformRemoteChannelSpecifics,
    iOS: DarwinNotificationDetails(
      badgeNumber: 1,
    ),
  );

  static Future<void> initialize() async {
    AndroidInitializationSettings initializationSettingsAndroid =
    const AndroidInitializationSettings('mipmap/ic_launcher');

    DarwinInitializationSettings initializationSettingsIOS =
    const DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _plugin.initialize(initializationSettings);
  }

  static Future<void> setupRemoteNotification() async {
    if (isFlutterLocalNotificationsInitialized) return;

    AndroidNotificationChannel channel = const AndroidNotificationChannel(
      'tigo_remote_channel_id', // id
      'Tigo', // title
      description: 'tigo_remote_channel_description', // description
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // iOS foreground notification 권한
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // IOS background 권한 체킹 , 요청
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // 셋팅flag 설정
    isFlutterLocalNotificationsInitialized = true;
  }

  static Future<void> setScheduleLocalNotification({
    required bool isActive,
    required int hour,
    required int minute,
  }) async {
    if (isActive) {
      await _plugin.cancel(0);
      await _plugin.zonedSchedule(
        0,
        'Tigo',
        Get.deviceLocale?.languageCode == 'ko'
            ? '오늘의 플로깅 변화는 무엇일까요?'
            : 'What is today\'s plogging change?',
        _toDateTime(hour, minute),
        _platformLocalChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } else {
      await _plugin.cancel(0);
    }
  }

  @pragma('vm:entry-point')
  static Future<void> onBackgroundHandler(RemoteMessage message) async {
    LogUtil.info('onBackgroundHandler: $message');

    if (message.data.isNotEmpty) {
      if (message.data.containsKey('mingiId')) {
        // GeoFence Logic Trigger Logic 삽입 구간
        // // First request
        // Get.find<MatchingGroupViewModel>().getMatchingStatus();
        // // Second request after 4 seconds
        // Future.delayed(const Duration(seconds: 4), () {
        //   Get.find<MatchingGroupViewModel>().getMatchingStatus();
        //   print("Second background request sent.");
        // });
      }
    }
  }

  static void showFlutterNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    // Access SystemProvider via StorageFactory
    final systemProvider = StorageFactory.systemProvider;
    // final matchingGroupVM = Get.find<MatchingGroupViewModel>();
    final rootVM = Get.find<RootViewModel>();

    if (message.data.containsKey('matchingId')) {
      print('matchingId: ${message.data['matchingId']}');
      print('matchedTeamName: ${message.data['matchedTeamName']}');

      // Update matching status
      // matchingGroupVM.setMatchingStatus(EMatchingStatus.MATCHED);
      // rootVM.matchingStatusState.value = MatchingStatusState(
      //   status: EMatchingStatus.MATCHED,
      // );

      // Fetch updated bootstrap information
      // rootVM.fetchBootstrapInformation();
      // Set matchingId
      // systemProvider.setMatchingId(message.data['matchingId']);
    }

    // Show notification if applicable
    if (notification != null && android != null) {
      _plugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        _platformRemoteChannelSpecifics,
      );
    }
  }

  static TZDateTime _toDateTime(hour, minute) {
    // Current Time
    DateTime localNow = DateTime.now();
    DateTime localWhen =
    DateTime(localNow.year, localNow.month, localNow.day, hour, minute);

    // UTC Time
    TZDateTime now = TZDateTime.from(localNow, tz.local);
    TZDateTime when = TZDateTime.from(localWhen, tz.local);

    if (when.isBefore(now)) {
      return when.add(const Duration(days: 1));
    } else {
      return when;
    }
  }
}
