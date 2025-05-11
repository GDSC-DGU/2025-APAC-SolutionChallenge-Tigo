import 'package:get/get.dart';
import 'package:tigo/presentation/view_model/home/home_binding.dart';
import 'package:tigo/presentation/view_model/live_chatbot/live_chatbot_binding.dart';
import 'package:tigo/presentation/view_model/profile/profile_binding.dart';
import 'package:tigo/presentation/view_model/root/root_view_model.dart';

class RootBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RootViewModel>(() => RootViewModel());
    LiveChatbotBinding().dependencies();
    HomeBinding().dependencies();
    ProfileBinding().dependencies();
  }
}
