import 'package:flutter/material.dart';
import 'package:tigo/app/config/color_system.dart';
import 'package:tigo/app/config/font_system.dart';

abstract class BaseFillButton extends StatelessWidget {
  const BaseFillButton({
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
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        // Size
        minimumSize: Size(width, height),
        fixedSize: Size(width, height),

        // Color
        backgroundColor: backgroundColor,
        foregroundColor: ColorSystem.white,

        disabledBackgroundColor: ColorSystem.neutral.shade300,

        // Border
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(12),
          ),
        ),
      ),
      child: Center(
        child: Text(
          content,
          style: FontSystem.H4.copyWith(
            color: onPressed != null ? ColorSystem.white : ColorSystem.neutral,
            height: 1.0,
          ),
        ),
      ),
    );
  }

  @protected
  Color get backgroundColor => throw UnimplementedError();
}
