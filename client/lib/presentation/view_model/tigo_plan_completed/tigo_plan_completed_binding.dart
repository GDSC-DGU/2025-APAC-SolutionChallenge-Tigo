import 'package:get/get.dart';
import 'package:tigo/presentation/view_model/tigo_plan_completed/tigo_plan_completed_view_model.dart';

class TigoPlanCompletedBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TigoPlanCompletedViewModel>(
      () => TigoPlanCompletedViewModel(planId: Get.arguments['planId']),
    );
  }
}
