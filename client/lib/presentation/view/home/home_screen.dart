import 'package:flutter/material.dart';
import 'package:tigo/core/constant/assets.dart';
import 'package:tigo/core/screen/base_screen.dart';
import 'package:tigo/presentation/view_model/home/home_view_model.dart';

class HomeScreen extends BaseScreen<HomeViewModel> {
  const HomeScreen({super.key});

  @override
  Widget buildBody(BuildContext context) {
    return Scaffold(
  backgroundColor: Colors.white,
  body: Stack(
    children: [
      // 1. 상단 그라데이션 배경
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: 260,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5CA9FF), Color(0xFFD1C2FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
        ),
      ),
      // 2. 메인 컨텐츠
      Positioned.fill(
        child: Column(
          children: [
            const SizedBox(height: 60), // 상태바+여백
            // 인사
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Hi, scott", style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Plans with Tigo", style: TextStyle(fontSize: 18, color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 카드 Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Tigo's Pick Today
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Tigo's Pick Today", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("About this place?", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 픽 이미지
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Image.asset('assets/images/paris.png', width: double.infinity, height: 140, fit: BoxFit.cover),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Image.asset('assets/images/fr_flag.png', width: 32),
                    ),
                    Center(
                      child: Image.asset('assets/images/tigo_bird.png', width: 60),
                    ),
                  ],
                ),
              ),
            ),
            // ...아래 여백 등
          ],
        ),
      ),
      ],
  ),
    );
  }
}
