import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tigo/core/screen/base_screen.dart';
import 'package:tigo/presentation/view_model/plan_list/plan_list_view_model.dart';
import 'package:tigo/app/config/font_system.dart';
import 'package:tigo/presentation/view/tigo_plan_completed_screen/quick_plan_test_screen.dart';
import 'package:tigo/presentation/view_model/home/home_view_model.dart';

class PlanListScreen extends BaseScreen<PlanListViewModel> {
  const PlanListScreen({super.key});

  @override
  Widget buildBody(BuildContext context) {
    final vm = Get.find<PlanListViewModel>();
    final userId = Get.find<HomeViewModel>().userBriefState.id;

    // 최초 진입 시 플랜 불러오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (vm.plans.isEmpty) {
        vm.fetchPlans(userId);
      }
    });

    return Obx(
      () =>
          vm.plans.isEmpty
              ? const Center(child: Text('플랜이 없습니다.', style: FontSystem.H1))
              : SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  itemCount: vm.plans.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, idx) {
                    final plan = vm.plans[idx];
                    return GestureDetector(
                      onTap: () {
                        // planId만 넘겨서 상세로 이동 (QuickPlanTestScreen에서 Firestore 조회)
                        Get.to(() => QuickPlanTestScreen(planId: plan.planId));
                      },
                      child: Container(
                        width: 220,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            if (plan.planThumbnailImage.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  plan.planThumbnailImage,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    plan.planName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${plan.days}일 • ${plan.mainSpots.join(", ")}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
