import 'package:get/get.dart';
import 'package:tigo/presentation/view_model/tigo_plan_chat/tigo_plan_chat_view_model.dart';

class TigoPlanChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TigoPlanChatViewModel>(() => TigoPlanChatViewModel());
  }
}
