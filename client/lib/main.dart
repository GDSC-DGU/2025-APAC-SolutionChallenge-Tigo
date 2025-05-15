import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tigo/app/bindings/init_binding.dart';
import 'package:tigo/app/env/common/environment_factory.dart';
import 'package:tigo/app/utility/notification_util.dart';
import 'package:tigo/data/factory/local_storage_factory.dart';
import 'package:tigo/data/factory/remote_storage_factory.dart';
import 'package:tigo/data/factory/storage_factory.dart';
import 'package:tigo/data/provider/user/user_local_provider.dart';
import 'package:tigo/data/provider/user/user_remote_provider.dart';
import 'package:tigo/firebase_options.dart';
import 'package:tigo/main_app.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';

void main() async {
  await onInitSystem();
  await onReadySystem();

  InitBinding().dependencies();
  runApp(const MainApp());
}

Future<void> requestPermissions() async {
  final permissions = [
    Permission.camera,
    Permission.microphone,
    Permission.location,
    Permission.locationAlways,
    Permission.locationWhenInUse,
    Permission.storage, // Android
    Permission.photos, // iOS
    Permission.mediaLibrary, // iOS
  ];

  for (final permission in permissions) {
    await permission.request();
  }
}

Future<void> onInitSystem() async {
  // Widget Binding
  WidgetsFlutterBinding.ensureInitialized();

  // permission
  await requestPermissions();

  // Environment
  await dotenv.load(fileName: "assets/config/.env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // DateTime Formatting
  await initializeDateFormatting();
  tz.initializeTimeZones();

  // Environment
  await EnvironmentFactory.onInit();

  // Storage & Database
  await StorageFactory.onInit();
  await LocalStorageFactory.onInit();
  await RemoteStorageFactory.onInit();
}

Future<void> onReadySystem() async {
  UserLocalProvider localProvider = LocalStorageFactory.userLocalProvider;
  UserRemoteProvider remoteProvider = RemoteStorageFactory.userRemoteProvider;
  // Storage & Database
  await StorageFactory.onReady();

  // If new download app, remove tokens
  // When token exists, isFirstRun is false
  bool isFirstRun = StorageFactory.systemProvider.getFirstRun();

  if (isFirstRun) {
    if (FirebaseAuth.instance.currentUser != null) {
      await remoteProvider.setDeviceToken("");
      await FirebaseAuth.instance.signOut();
    }

    await localProvider.onReady();

    // await NotificationUtil.setScheduleLocalNotification(
    //   isActive: localProvider.getNotificationActive(),
    //   hour: localProvider.getNotificationHour(),
    //   minute: localProvider.getNotificationMinute(),
    // );
  }
}
