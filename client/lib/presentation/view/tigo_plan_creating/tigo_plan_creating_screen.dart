import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rive/rive.dart';
import 'package:tigo/app/config/app_routes.dart';
import 'package:tigo/presentation/view/tigo_plan_completed_screen/quick_plan_test_screen.dart';
import 'package:tigo/presentation/view_model/tigo_plan_chat/tigo_plan_chat_view_model.dart';

class TigoPlanCreatingScreen extends StatefulWidget {
  final String? userId;

  const TigoPlanCreatingScreen({super.key, this.userId});

  @override
  State<TigoPlanCreatingScreen> createState() => _TigoPlanCreatingScreenState();
}

class _TigoPlanCreatingScreenState extends State<TigoPlanCreatingScreen> {
  late final TigoPlanChatViewModel _vm;
  late RiveAnimationController _controller;
  String statusText = "Generating Plan...";
  String? userId;

  @override
  void initState() {
    super.initState();
    _vm = Get.find<TigoPlanChatViewModel>();

    // arguments에서 userId 추출
    final args = Get.arguments as Map<String, dynamic>?;
    userId = args?['userId'];
    print('userId in creating screen: $userId');

    // 초기 애니메이션: Blink (looping)
    _controller = SimpleAnimation('Blink');

    // 애니메이션 로딩 시작 → 200 응답 후 전환 처리
    _fetchPlan();
  }

  Future<void> _fetchPlan() async {
    final url = Uri.parse('${_vm.apiBaseUrl}/tripPlan');
    final body = jsonEncode({
      'userId': userId,
      'dialogId': _vm.currentDialogId,
    });
    try {
      print('currentDialogId: ${_vm.currentDialogId}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      print('response.statusCode: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('response.body: $data');
        final planList = safeParsePlanList(data['schedules']);
        print('planList: $planList');
        setState(() {
          statusText = "Plan Completed!";
          _controller = OneShotAnimation(
            'wing',
            autoplay: true,
            onStop: () {
              // 1초(1000ms) 후에 화면 이동
              Future.delayed(const Duration(seconds: 3), () {
                Get.toNamed(
                  AppRoutes.QUICK_PLAN_TEST,
                  arguments: {'planList': planList, 'userId': userId},
                );
              });
            },
          );
        });

        // // ✅ 상태 텍스트 변경 및 wing 애니메이션 실행 (1회)
        // setState(() {
        //
        // });
      } else {
        _vm.messages.add(ChatMessage(text: '여행 계획표 생성 실패', isUser: false));
        Get.offAllNamed('/errorScreen');
      }
    } catch (e) {
      _vm.messages.add(ChatMessage(text: '요청 중 오류 발생: $e', isUser: false));
      Get.offAllNamed('/errorScreen');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('userId: $userId');
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 160,
              width: 160,
              child: RiveAnimation.asset(
                'assets/animations/walk.riv',
                controllers: [_controller],
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                statusText,
                key: ValueKey(statusText),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
