import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tigo/app/config/app_routes.dart';
import 'package:tigo/app/config/color_system.dart';
import 'package:tigo/app/config/font_system.dart';
import 'package:tigo/presentation/widget/button/rounded_rectangle_text_button.dart';

class SignInDialog extends StatelessWidget {
  const SignInDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        decoration: BoxDecoration(
          color: ColorSystem.white,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'sign_in_required',
              style: FontSystem.H4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            SizedBox(
              child: Row(
                children: [
                  Expanded(
                    child: RoundedRectangleTextButton(
                      text: 'cancel'.tr,
                      textStyle: FontSystem.H5,
                      height: 50,
                      backgroundColor: ColorSystem.white,
                      foregroundColor: ColorSystem.neutral,
                      borderSide: BorderSide(color: ColorSystem.neutral),
                      onPressed: () {
                        Get.back();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RoundedRectangleTextButton(
                      text: 'sign_in'.tr,
                      textStyle: FontSystem.H5,
                      height: 50,
                      backgroundColor: ColorSystem.secondary,
                      foregroundColor: ColorSystem.white,
                      onPressed: () {
                        Get.back();
                        Get.toNamed(AppRoutes.SIGN_IN);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
