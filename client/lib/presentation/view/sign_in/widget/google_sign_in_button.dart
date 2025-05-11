import 'package:bounce_tapper/bounce_tapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tigo/app/config/app_color.dart';
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
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFF6F6F9),
          foregroundColor: AppColor.of.gray6,
          textStyle: FontSystem.H3,
          padding: EdgeInsets.zero,
        ),
        onPressed: () async {
          await viewModel.signInWithGoogle();
          if (viewModel.user.value != null) {
            Get.offAllNamed('/home');
          }
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text('Sign in with Google'),
              ),
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
    );
  }
}