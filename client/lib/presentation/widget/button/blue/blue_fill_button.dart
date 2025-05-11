import 'package:flutter/material.dart';
import 'package:tigo/app/config/color_system.dart';
import 'package:tigo/presentation/widget/button/common/base_fill_button.dart';

class BlueFillButton extends BaseFillButton {
  const BlueFillButton({
    super.key,
    required super.width,
    required super.height,
    required super.content,
    required super.onPressed,
  });

  @override
  Color get backgroundColor => ColorSystem.blue.shade400;
}
