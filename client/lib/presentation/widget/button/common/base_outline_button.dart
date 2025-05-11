import 'package:flutter/material.dart';
import 'package:tigo/app/config/color_system.dart';
import 'package:tigo/app/config/font_system.dart';

abstract class BaseOutlineButton extends StatelessWidget {
  const BaseOutlineButton({
    super.key,
    required this.width,
    required this.height,
    required this.content,
    required this.onPressed,
  });

  final double width;
  final double height;
  final String content;
  final Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        // Size
        minimumSize: Size(width, height),
        fixedSize: Size(width, height),

        // Color
        backgroundColor: ColorSystem.white,
        foregroundColor: ColorSystem.black.withOpacity(0.5),

        // Shape
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),

        // Border
        side: BorderSide(
          color: onPressed != null ? borderColor : ColorSystem.neutral.shade300,
          width: 1,
        ),

        disabledBackgroundColor: ColorSystem.neutral.shade300,
      ),
      child: Center(
        child: Text(
          content,
          style: FontSystem.H4.copyWith(
            color: onPressed != null ? ColorSystem.black : ColorSystem.neutral,
            height: 1.0,
          ),
        ),
      ),
    );
  }

  @protected
  Color get borderColor => throw UnimplementedError();
}
