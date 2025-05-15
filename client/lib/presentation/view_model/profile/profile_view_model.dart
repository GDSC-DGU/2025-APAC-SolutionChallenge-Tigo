import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:tigo/app/config/app_routes.dart';
import 'package:tigo/app/utility/security_util.dart';
import 'package:tigo/data/factory/storage_factory.dart';
import 'package:tigo/domain/entity/user_brief_state.dart';
import 'package:tigo/domain/repository/user_repository.dart';

class ProfileViewModel extends GetxController {
  /* ------------------------------------------------------ */
  /* -------------------- DI Fields ----------------------- */
  /* ------------------------------------------------------ */
  late final UserRepository _userRepository;

  /* ------------------------------------------------------ */
  /* ----------------- Private Fields --------------------- */
  /* ------------------------------------------------------ */
  late final Rx<UserBriefState> _userBriefState;
  late final RxBool _isSignIn;

  /* ------------------------------------------------------ */
  /* ----------------- Public Fields ---------------------- */
  /* ------------------------------------------------------ */
  UserBriefState get userBriefState => _userBriefState.value;
  bool get isSignIn => _isSignIn.value;

  @override
  void onInit() async {
    super.onInit();
    // Dependency Injection
    _userRepository = Get.find<UserRepository>();

    // Private Fields
    _userBriefState = _userRepository.readUserBriefState().obs;
    _isSignIn = true.obs;
  }

  @override
  void onReady() {
    // TODO: implement onReady
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
    _userBriefState.close();
  }

  Future<bool> signOut() async {
    await _userRepository.updateUserInformation(isSignIn: false);

    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      return false;
    }
    await StorageFactory.systemProvider.setLogin(false);
    print('로그아웃 후 isLogin: ${StorageFactory.systemProvider.isLogin}');

    _isSignIn.value = false;

    Get.offAllNamed(AppRoutes.SIGN_IN);
    return true;
  }

  void informProfileViewModel() {
    Get.find<ProfileViewModel>().fetchUserBriefState();
  }

  void fetchUserBriefState() async {
    UserBriefState temp = _userRepository.readUserBriefState();

    if (SecurityUtil.isSignin) {
      _userBriefState.value = _userBriefState.value.copyWith(
        id: temp.id,
        email: temp.email,
        nickname: temp.nickname,
        photoUrl: temp.photoUrl,
      );
    } else {
      _userBriefState.value = _userBriefState.value.copyWith(
        id: '',
        email: '',
        nickname: '',
        photoUrl: '',
      );
    }
  }
}
