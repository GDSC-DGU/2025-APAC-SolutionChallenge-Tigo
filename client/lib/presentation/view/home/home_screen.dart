import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tigo/app/config/app_routes.dart';
import 'package:tigo/core/constant/assets.dart';
import 'package:tigo/core/screen/base_screen.dart';
import 'package:tigo/presentation/view/home/widget/place_detail_modal.dart';
import 'package:tigo/presentation/view/home/widget/plan_card.dart';
import 'package:tigo/presentation/view/home/widget/tigo_pick_today_section.dart';
import 'package:tigo/presentation/view_model/home/home_view_model.dart';

class HomeScreen extends BaseScreen<HomeViewModel> {
  const HomeScreen({super.key});
  @override
  Widget buildBody(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: Stack(
        children: [
          // Background Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4DAEFF), Color(0xFFEFF5FB)],
                ),
              ),
              child: CustomPaint(painter: _HighlightPainter()),
            ),
          ),
          // Gradient Overlay
          Positioned(
            top: 363,
            left: 0,
            right: 0,
            bottom: 0,
            child: TigoPickTodaySection(
              onInfoTap: () {
                showDialog(
                  context: context,
                  builder: (_) => const PlaceDetailModal(),
                );
              },
            ),
          ),
          Positioned(
            top: 240,
            left: 24,
            right: 24,
            child: Row(
              children: [
                Expanded(
                  child: TempPlanCard(
                    iconAssetPath: 'assets/images/for_list.png',
                    title: 'For list',
                    date: 'Open your travel list',
                    bgColor: Color(0xFFFFF0E0),
                    onTap: () {
                      Get.toNamed(AppRoutes.PLAN_LIST);
                    },
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: TempPlanCard(
                    iconAssetPath: 'assets/images/for_conversation.png',
                    title: ' For Conversation',
                    date: ' Plan a trip with TIGO',
                    bgColor: const Color(0xFFE7F2FF),
                    onTap: () {
                      Get.toNamed(AppRoutes.TIGO_PLAN_CHAT);
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 72,
            left: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 실제 viewModel.userBriefState.photoUrl 사용
                // CircleAvatar(
                //   radius: 24,
                //   backgroundImage: CachedNetworkImageProvider(
                //     viewModel.userBriefState.photoUrl ?? '',
                //   ),
                // ),
                const SizedBox(height: 8),
                Text(
                  'Hi, ${viewModel.userBriefState.nickname}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'How about Plans with Tigo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 96,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const Icon(
                        Icons.video_call,
                        color: Color(0xFFEEEEEE),
                        size: 20,
                      ),
                      const SizedBox(width: 40),
                      GestureDetector(
                        onTap: () {
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => const MyPageScreen(),
                          //   ),
                          // );
                        },
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFFEEEEEE),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: -36,
                  child: Container(
                    height: 72,
                    width: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFB2D9FF), Color(0xFFE7EBFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.home,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0.8, -0.6),
            radius: 1.4,
            colors: [
              Colors.white.withOpacity(0.6),
              Colors.white.withOpacity(0.0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.9, size.height * 0.15),
              radius: size.width * 1.3,
            ),
          );

    canvas.save();

    canvas.translate(size.width * 0.8, size.height * 0.15);
    canvas.rotate(-0.05);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(1, 0),
        width: size.width * 1.7,
        height: size.height * 1.8,
      ),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
