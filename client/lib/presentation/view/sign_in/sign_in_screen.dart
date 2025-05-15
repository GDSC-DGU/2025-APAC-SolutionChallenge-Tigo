import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tigo/core/screen/base_screen.dart';
import 'package:tigo/presentation/view/sign_in/widget/google_sign_in_button.dart';
import 'package:tigo/presentation/view_model/sign_in/sign_in_view_model.dart';
import 'package:tigo/core/constant/assets.dart';
import 'package:tigo/presentation/view_model/sign_in/widget/overlay_grey_barrier.dart';

class SignInScreen extends BaseScreen<SignInViewModel> {
  const SignInScreen({super.key});

  SignInViewModel get viewModel => controller;

  @override
  Widget buildBody(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(Assets.splashImage),
                fit: BoxFit.cover,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 500),
                  GoogleSignInButton(),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          // 오버레이 그레이 배리어 + 로딩 인디케이터
          OverlayGreyBarrier(),
          Obx(
            () =>
                viewModel.isEnableGreyBarrier
                    ? Center(child: CircularProgressIndicator())
                    : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
