import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tigo/core/screen/base_widget.dart';
import 'package:tigo/presentation/view_model/sign_in/sign_in_view_model.dart';

/// Gery Scale Barrier
class OverlayGreyBarrier extends BaseWidget<SignInViewModel> {
  const OverlayGreyBarrier({super.key});

  @override
  Widget buildView(BuildContext context) {
    return Obx(
      () => IgnorePointer(
        ignoring: !viewModel.isEnableGreyBarrier,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          color:
              viewModel.isEnableGreyBarrier
                  ? Colors.black.withOpacity(0.5)
                  : Colors.transparent,
        ),
      ),
    );
  }
}
