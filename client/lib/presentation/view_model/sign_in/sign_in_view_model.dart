import 'package:get/get.dart';
import 'package:tigo/data/provider/user/user_provider.dart';
import 'package:tigo/domain/entity/user_brief_state.dart';
import 'package:tigo/core/wrapper/state_wrapper.dart';

class SignInViewModel extends GetxController {
  final UserProvider _userProvider = Get.find();

  RxBool isLoading = false.obs;
  Rxn<UserBriefState> user = Rxn<UserBriefState>();
  RxnString error = RxnString();

  Future<void> signInWithGoogle() async {
    isLoading.value = true;
    final result = await _userProvider.signInWithGoogle();
    isLoading.value = false;
    if (result.success && result.data != null) {
      user.value = result.data;
      error.value = null;
    } else {
      error.value = result.message ?? "로그인 실패";
    }
  }
}
