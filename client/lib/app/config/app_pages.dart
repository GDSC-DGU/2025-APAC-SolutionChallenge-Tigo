import 'package:get/get.dart';
import 'package:tigo/app/config/app_routes.dart';
import 'package:tigo/app/middleware/login_middleware.dart';
import 'package:tigo/presentation/view/root/root_screen.dart';
import 'package:tigo/presentation/view/sign_in/sign_in_screen.dart';
import 'package:tigo/presentation/view_model/sign_in/sign_in_binding.dart';

import '../../presentation/view_model/root/root_binding.dart';

abstract class AppPages {
  static List<GetPage> data = [
    GetPage(
      name: AppRoutes.SIGN_IN,
      page: () => const SignInScreen(),
      binding: SignInBinding(),
    ),
    GetPage(
      name: AppRoutes.ROOT,
      page: () => const RootScreen(),
      bindings: [RootBinding()],
      middlewares: [LoginMiddleware()],
    ),
  ];
}
