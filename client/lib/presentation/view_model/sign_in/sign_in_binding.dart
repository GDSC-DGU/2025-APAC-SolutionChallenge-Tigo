import 'package:get/get.dart';
import 'package:tigo/data/repository/user/user_repository_impl.dart';
import 'package:tigo/presentation/view_model/sign_in/sign_in_view_model.dart';

class SignInBinding extends Bindings {
  @override
  void dependencies() {
   Get.lazyPut<SignInViewModel>(() => SignInViewModel());
  }
}