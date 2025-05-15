import 'package:get/get.dart';
import 'package:tigo/app/config/app_routes.dart';
import 'package:tigo/app/middleware/login_middleware.dart';
import 'package:tigo/presentation/view/plan_list/plan_list_screen.dart';
import 'package:tigo/presentation/view/tigo_plan_chat/tigo_plan_chat_screen.dart';
import 'package:tigo/presentation/view/root/root_screen.dart';
import 'package:tigo/presentation/view/sign_in/sign_in_screen.dart';
import 'package:tigo/presentation/view/tigo_plan_completed_screen/tigo_plan_completed_screen.dart';
import 'package:tigo/presentation/view_model/plan_list/plan_list_binding.dart';
import 'package:tigo/presentation/view_model/tigo_plan_chat/tigo_plan_chat_binding.dart';
import 'package:tigo/presentation/view_model/sign_in/sign_in_binding.dart';
import 'package:tigo/presentation/view_model/tigo_plan_completed/tigo_plan_completed_binding.dart';

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
   //   middlewares: [LoginMiddleware()],
    ),
    GetPage(
      name: AppRoutes.TIGO_PLAN_CHAT,
      page: () => const TigoPlanChatScreen(),
      binding: TigoPlanChatBinding(),
    ),
    GetPage(
      name: AppRoutes.TIGO_PLAN_COMPLETED,
      page: () => const TigoPlanCompletedScreen(),
      binding: TigoPlanCompletedBinding(),
    ),
    GetPage(
      name: AppRoutes.PLAN_LIST,
      page: () => const PlanListScreen(),
      binding: PlanListBinding(),
    ),
  ];
}
