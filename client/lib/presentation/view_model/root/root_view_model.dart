import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:tigo/app/utility/notification_util.dart';
import 'package:tigo/core/wrapper/state_wrapper.dart';
import 'package:tigo/domain/entity/user_brief_state.dart';
import 'package:tigo/domain/repository/user_repository.dart';

class RootViewModel extends GetxController {
  /* ------------------------------------------------------ */
  /* ----------------- Static Fields ---------------------- */
  /* ------------------------------------------------------ */
  static const duration = Duration(milliseconds: 200);

  /* ------------------------------------------------------ */
  /* -------------------- DI Fields ----------------------- */
  /* ------------------------------------------------------ */
  // late final ReadUserStateUsecase _readUserBriefUsecase;

  /* ------------------------------------------------------ */
  /* ----------------- Private Fields --------------------- */
  /* ------------------------------------------------------ */
  late Rx<DateTime> _currentAt;
  late final RxInt _selectedIndex;
  late final Rx<UserBriefState> _userBriefState;

  /* ------------------------------------------------------ */
  /* ----------------- Public Fields ---------------------- */
  /* ------------------------------------------------------ */
  DateTime get currentAt => _currentAt.value;
  int get selectedIndex => _selectedIndex.value;

  UserBriefState get userBriefState => _userBriefState.value;

  @override
  void onInit() async {
    super.onInit();

    // Dependency Injection

    _selectedIndex = 1.obs;
    _userBriefState = UserBriefState.initial().obs;

    // FCM Setting
    FirebaseMessaging.onMessage.listen(
      NotificationUtil.showFlutterNotification,
    );
    FirebaseMessaging.onBackgroundMessage(NotificationUtil.onBackgroundHandler);

    // Private Fields
    _currentAt = DateTime.now().obs;
    _selectedIndex = 2.obs;
  }

  void changeIndex(int index) async {
    _selectedIndex.value = index;
    _currentAt.value = DateTime.now();
  }

  @override
  void onReady() async {
    super.onReady();
  }
}
