import 'package:get/get.dart';
import 'package:tigo/presentation/view_model/home/home_view_model.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeViewModel>(() => HomeViewModel());
  }
}