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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Plans with Tigo',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),

        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Obx(() {
        if (vm.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (vm.plans.isEmpty) {
          return const Center(child: Text('플랜이 없습니다.', style: FontSystem.H1));
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          itemCount: vm.plans.length,
          separatorBuilder:
              (_, __) => const SizedBox(height: 28), // 카드 간 간격 넉넉하게
          itemBuilder: (context, idx) {
            final plan = vm.plans[idx];

            // 유효하지 않은 플랜 필터링
            final isInvalid =
                plan.planName == '알 수 없음 0일 여행' ||
                plan.planName.trim().isEmpty ||
                plan.days == 0 ||
                plan.planThumbnailImage == null ||
                plan.planThumbnailImage.toString().trim().isEmpty;

            if (isInvalid) {
              // 아무것도 렌더링하지 않음
              return const SizedBox.shrink();
            }
            return GestureDetector(
              onTap: () {
                Get.to(() => QuickPlanTestScreen(planId: plan.planId));
              },
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // 배경 이미지
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        plan.planThumbnailImage,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // 그라데이션 오버레이 (위쪽은 투명, 아래쪽은 검정)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: double.infinity,
                        height: 160,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black54],
                          ),
                        ),
                      ),
                    ),

                    // 텍스트 (왼쪽 아래)
                    Positioned(
                      left: 20,
                      bottom: 22,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.planName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              shadows: [
                                Shadow(color: Colors.black54, blurRadius: 4),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${plan.days}일', // 또는 날짜 범위
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              shadows: [
                                Shadow(color: Colors.black54, blurRadius: 4),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // (선택) 오른쪽 위에 아이콘
                    Positioned(
                      right: 18,
                      top: 18,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
