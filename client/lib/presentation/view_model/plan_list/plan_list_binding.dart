import 'package:get/get.dart';
import 'package:tigo/presentation/view_model/plan_list/plan_list_view_model.dart';

class PlanListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlanListViewModel>(() => PlanListViewModel());
  }
}