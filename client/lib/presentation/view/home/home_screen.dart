import 'package:flutter/material.dart';
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
            height: 360,
            child: Image.asset(
              Assets.homeGradientBackgroundImage,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          // Gradient Overlay
          Positioned(
            top: 420,
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
            top: 300,
            left: 24,
            right: 24,
            child: Row(
              children: [
                Expanded(
                  child: TempPlanCard(
                    icon: Icons.language,
                    title: 'My Trips',
                    date: '2025.05.06',
                    iconColor: const Color(0xFFF99500),
                    bgColor: const Color(0xFFFFF0E0),
                    onTap: () {},
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: TempPlanCard(
                    icon: Icons.list_alt,
                    title: 'For Conversation',
                    date: '2025.05.06',
                    iconColor: const Color(0xFF4A90E2),
                    bgColor: const Color(0xFFE7F2FF),
                    onTap: () {
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => const ChatScreen(),
                      //   ),
                      // );
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
                const CircleAvatar(radius: 24),
                const SizedBox(height: 8),
                const Text(
                  'Hi, scott',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Plans with Tigo',
                  style: TextStyle(fontSize: 16, color: Colors.white),
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
                        color: Colors.grey,
                        size: 28,
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
                          color: Colors.grey,
                          size: 28,
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
