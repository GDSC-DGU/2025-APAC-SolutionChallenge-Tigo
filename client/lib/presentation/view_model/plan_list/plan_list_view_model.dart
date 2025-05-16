import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tigo/presentation/view_model/home/home_view_model.dart';

class PlanListViewModel extends GetxController {
  final RxList<PlanSummary> plans = <PlanSummary>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isError = false.obs;
  final String userId = Get.find<HomeViewModel>().userBriefState.id;

  @override
  void onInit() {
    super.onInit();
    print('userId: $userId');
    fetchPlans(userId);
  }

  Future<void> fetchPlans(String userId) async {
    print('fetchPlans: $userId');
    isLoading.value = true;
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('plans')
              .orderBy('createdAt', descending: true)
              .get();

      print('Fetched ${snapshot.docs.length} plans for user: $userId');

      plans.assignAll(
        snapshot.docs.map((doc) => PlanSummary.fromJson(doc.data())),
      );
    } finally {
      isLoading.value = false;
    }
  }
}

class PlanSummary {
  final String planId;
  final String planName;
  final String planThumbnailImage;
  final String dialogId;
  final int days;
  final List<dynamic> mainSpots;
  final DateTime createdAt;

  PlanSummary({
    required this.planId,
    required this.planName,
    required this.planThumbnailImage,
    required this.dialogId,
    required this.days,
    required this.mainSpots,
    required this.createdAt,
  });

  factory PlanSummary.fromJson(Map<String, dynamic> json) {
    return PlanSummary(
      planId: json['planId'],
      planName: json['planName'],
      planThumbnailImage: json['planThumbnailImage'],
      dialogId: json['dialogId'] ?? '',
      days: json['days'] ?? 0,
      mainSpots: json['mainSpots'] ?? [],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
