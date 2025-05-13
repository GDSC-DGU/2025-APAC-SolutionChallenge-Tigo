import 'package:get/get.dart';
import 'package:tigo/data/provider/user/user_local_provider.dart';
import 'package:tigo/data/provider/user/user_local_provider_impl.dart';
import 'package:tigo/data/provider/user/user_remote_provider.dart';
import 'package:tigo/data/provider/user/user_remote_provider_impl.dart';
import 'package:tigo/data/repository/user/user_repository_impl.dart';
import 'package:tigo/domain/repository/user_repository.dart';

class AppDependency extends Bindings {
  @override
  void dependencies() {
    // Add your mediator dependencies here

    // Add your provider dependencies here

    // Add your repository dependencies here
    Get.lazyPut<UserRepository>(() => UserRepositoryImpl());
  }
}
