import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tigo/app/config/app_routes.dart';
import 'package:tigo/data/factory/storage_factory.dart';

class LoginMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    bool isNotLogin = !StorageFactory.systemProvider.isLogin;

    if (isNotLogin) {
      return const RouteSettings(name: AppRoutes.SIGN_IN);
    }

    return null;
  }
}
