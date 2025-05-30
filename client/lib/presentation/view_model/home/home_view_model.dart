import 'package:get/get.dart';
import 'package:tigo/app/utility/security_util.dart';
import 'package:tigo/domain/entity/user_brief_state.dart';
import 'package:tigo/domain/repository/user_repository.dart';

class HomeViewModel extends GetxController {
  /* ------------------------------------------------------ */
  /* -------------------- DI Fields ----------------------- */
  /* ------------------------------------------------------ */
  late final UserRepository _userRepository;

  /* ------------------------------------------------------ */
  /* ----------------- Private Fields --------------------- */
  /* ------------------------------------------------------ */
  late final Rx<UserBriefState> _userBriefState;

  /* ------------------------------------------------------ */
  /* ----------------- Public Fields ---------------------- */
  /* ------------------------------------------------------ */
  UserBriefState get userBriefState => _userBriefState.value;

  void onInit() async {
    super.onInit();

    // Dependency Injection
    _userRepository = Get.find<UserRepository>();

    // Private Fields
    _userBriefState = _userRepository.readUserBriefState().obs;
  }

  @override
  void onReady() {
    // TODO: implement onReady
    super.onReady();

    // fetchUserBriefState();
  }

  void fetchUserBriefState() async {
    UserBriefState temp = _userRepository.readUserBriefState();

    print('SecurityUtil.isSignin: ${SecurityUtil.isSignin}');

    if (SecurityUtil.isSignin) {
      print('here?');
      _userBriefState.value = _userBriefState.value.copyWith(
        id: temp.id,
        email: temp.email,
        nickname: temp.nickname,
        photoUrl: temp.photoUrl,
      );
      return;
    } else {
      print('here again?');
      _userBriefState.value = _userBriefState.value.copyWith(
        id: "GUEST",
        nickname: "GUEST",
        email: "GUEST",
        photoUrl: "GUEST",
      );
    }
  }
}
