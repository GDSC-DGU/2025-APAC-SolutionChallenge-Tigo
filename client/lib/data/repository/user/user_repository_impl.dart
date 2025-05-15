import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:tigo/data/factory/local_storage_factory.dart';
import 'package:tigo/data/provider/user/user_local_provider.dart';
import 'package:tigo/data/provider/user/user_remote_provider.dart';
import 'package:tigo/domain/entity/user_brief_state.dart';
import 'package:tigo/data/model/setting/alarm_state.dart';
import 'package:tigo/domain/repository/user_repository.dart';
import 'package:tigo/data/factory/remote_storage_factory.dart';
import 'package:get/get.dart';

class UserRepositoryImpl extends GetxService implements UserRepository {
  late final UserLocalProvider _localProvider;
  late final UserRemoteProvider _remoteProvider;

  @override
  void onInit() {
    super.onInit();
    _localProvider = LocalStorageFactory.userLocalProvider;
    _remoteProvider = RemoteStorageFactory.userRemoteProvider;
  }

  @override
  UserBriefState readUserBriefState() {
    return UserBriefState(
      id: _localProvider.getId(),
      email: _localProvider.getEmail(),
      nickname: _localProvider.getNickname(),
      photoUrl: _localProvider.getPhotoUrl(),
    );
  }

  @override
  NotificationState readNotificationState() {
    return NotificationState(
      isActive: _localProvider.getNotificationActive(),
      hour: _localProvider.getNotificationHour(),
      minute: _localProvider.getNotificationMinute(),
    );
  }

  @override
  Future<void> updateUserNotificationSetting({
    bool? isActive,
    int? hour,
    int? minute,
  }) async {
    if (isActive != null) {
      await _localProvider.setNotificationActive(isActive);
      await _remoteProvider.setNotificationActive(isActive);
    }
    if (hour != null) {
      await _localProvider.setNotificationHour(hour);
    }
    if (minute != null) {
      await _localProvider.setNotificationMinute(minute);
    }
  }

  @override
  Future<void> updateUserInformation({required bool isSignIn}) async {
    if (!isSignIn) {
      print('debug: updateUserInformation: GUEST');
      // 로그아웃 시 GUEST로 초기화
      await _localProvider.setId("GUEST");
      await _localProvider.setNickname("GUEST");
      await _localProvider.setEmail("");
      await _localProvider.setPhotoUrl("");
      return;
    }

    // Remote Update(Trigger Gap Handling)
    int maxRetries = 5;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        // await _remoteProvider.setDeviceToken(
        //   await FirebaseMessaging.instance.getToken() ?? "",
        // );
        // await _remoteProvider.setDeviceLanguage(
        //   Get.deviceLocale?.languageCode == "ko" ? "ko" : "en",
        // );


        break;
      } catch (e) {
        retryCount++;

        if (retryCount == maxRetries) {
          rethrow;
        }

        await Future.delayed(const Duration(seconds: 1));
      }
    }

    // Remote -> Local Update
    // System Information
    await _localProvider.setId((await _remoteProvider.getId()).substring(0, 5));
    await _localProvider.setNickname(await _remoteProvider.getNickname());
    await _localProvider.setEmail(await _remoteProvider.getEmail());
    await _localProvider.setPhotoUrl(await _remoteProvider.getPhotoUrl());
  }
}
