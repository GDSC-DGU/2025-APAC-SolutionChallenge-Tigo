import 'package:tigo/core/wrapper/state_wrapper.dart';
import 'package:tigo/data/model/setting/alarm_state.dart';
import 'package:tigo/domain/entity/user_brief_state.dart';

abstract class UserRepository {
  /* ------------------------------------------------------------ */
  /* --------------------------- Read --------------------------- */
  /* ------------------------------------------------------------ */
  UserBriefState readUserBriefState();
  NotificationState readNotificationState();
  /* ------------------------------------------------------------ */
  /* -------------------------- Update -------------------------- */
  /* ------------------------------------------------------------ */
  Future<void> updateUserNotificationSetting({
    bool? isActive,
    int? hour,
    int? minute,
  });
  Future<void> updateUserInformation({
    required bool isSignIn,
  });

}