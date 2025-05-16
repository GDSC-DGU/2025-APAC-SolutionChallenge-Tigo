import 'package:bounce_tapper/bounce_tapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tigo/app/config/app_color.dart';
import 'package:tigo/app/config/app_pages.dart';
import 'package:tigo/app/config/app_routes.dart';
import 'package:tigo/app/config/color_system.dart';
import 'package:tigo/app/config/font_system.dart';
import 'package:tigo/core/constant/assets.dart';
import 'package:tigo/core/screen/base_widget.dart';
import 'package:tigo/presentation/view_model/sign_in/sign_in_view_model.dart';
import 'package:get/get.dart';

class GoogleSignInButton extends BaseWidget<SignInViewModel> {
  const GoogleSignInButton({super.key});

  @override
  SignInViewModel get viewModel => controller;

  @override
  Widget buildView(BuildContext context) {
    return BounceTapper(
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08), // 연한 그림자
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          borderRadius: BorderRadius.circular(12), // 버튼과 동일하게
        ),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColor().gray1,
            foregroundColor: AppColor.of.gray6,
            textStyle: FontSystem.H3,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _onPressSignInButton,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(child: Text('Sign in with Google')),
              ),
              Positioned(
                left: 24,
                top: 0,
                bottom: 0,
                child: SvgPicture.asset(
                  Assets.iconsGoogleLogo,
                  width: 24,
                  height: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.black.withOpacity(0.7),
      colorText: Colors.white,
    );
  }

  void _onPressSignInButton() {
    viewModel.signInWithGoogle().then((value) {
      if (value) {
        Get.offAllNamed(AppRoutes.ROOT);
        _showSnackBar('Login Success', 'You can use the AI trip service Tigo!');
      } else {
        _showSnackBar('Login Failed', 'Please try again later');
      }
    });
  }
}
