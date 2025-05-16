import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tigo/app/bindings/init_binding.dart';
import 'package:tigo/app/config/app_config.dart';
import 'package:tigo/app/config/app_dependency.dart';
import 'package:tigo/app/config/app_pages.dart';
import 'package:tigo/app/config/app_routes.dart';
import 'package:tigo/app/config/color_system.dart';
import 'package:tigo/app/config/app_theme.dart';
import 'package:tigo/app/config/app_color.dart';
// import 'package:tigo/app/config/app_size.dart'; // AppSize가 있다면 import
// import 'package:flutter_easyloading/flutter_easyloading.dart'; // EasyLoading 사용 시 import
// import 'package:fluttertoast/fluttertoast.dart'; // FToastBuilder 사용 시 import
// import 'package:tigo/widget/m_layout_constraint_layout.dart'; // MLayoutConstraintLayout 사용 시 import

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    return GetMaterialApp(
      // App Title
      title: AppConfig.APP_TITLE,

      // Localization
      locale: Get.deviceLocale,
      fallbackLocale: const Locale('ko', 'KR'),

      // Theme
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,

      builder: (context, child) {
        AppColor.init(context);
        return child!;
      },

      debugShowCheckedModeBanner: false,

      // Initial Route
      initialRoute: AppRoutes.ROOT,
      initialBinding: InitBinding(),

      // Routes
      getPages: AppPages.data,
    );
  }
}
