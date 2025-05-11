import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tigo/app/config/color_system.dart';
import 'package:tigo/app/config/font_system.dart';
import 'package:tigo/presentation/view_model/root/root_view_model.dart';

class RootScreen extends GetView<RootViewModel> {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: ColorSystem.white,
      body: Center(
        child: Text(
          'Tigo Root Screen',
          style: FontSystem.H6,
        ),
      ),
    );
  }
}
