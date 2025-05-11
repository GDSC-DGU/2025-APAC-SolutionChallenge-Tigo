import 'package:get/get.dart';
import 'package:tigo/data/provider/user/user_provider.dart';
import 'package:tigo/data/provider/user/user_provider_impl.dart';

class AppDependency extends Bindings {
  @override
  void dependencies() {
    // Add your mediator dependencies here

    // Add your provider dependencies here
    Get.lazyPut<UserProvider>(() => UserProviderImpl());

    // Add your repository dependencies here
  }
}
