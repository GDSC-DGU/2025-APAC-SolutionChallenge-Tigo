import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class PlanLoadingScreen extends StatefulWidget {
  const PlanLoadingScreen({super.key});

  @override
  State<PlanLoadingScreen> createState() => _PlanLoadingScreenState();
}

class _PlanLoadingScreenState extends State<PlanLoadingScreen> {
  late RiveAnimationController _controller;
  String statusText = "Generating Plan...";

  @override
  void initState() {
    super.initState();
    // 초기 Blink 애니메이션
    _controller = SimpleAnimation('Blink');

    // 5초 후 wing 애니메이션으로 전환
    Future.delayed(const Duration(seconds: 5), () {
      setState(() {
        _controller = OneShotAnimation(
          'wing',
          autoplay: true,
          onStop: () {
            Navigator.pushReplacementNamed(context, '/nextPage'); // ← 수정 필요
          },
        );
        statusText = "Plan Completed!";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
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
