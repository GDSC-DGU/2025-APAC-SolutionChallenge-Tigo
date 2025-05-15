import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:tigo/app/config/app_routes.dart';
import 'package:tigo/app/utility/security_util.dart';
import 'package:tigo/core/screen/base_screen.dart';
import 'package:tigo/presentation/view/home/home_screen.dart';
import 'package:tigo/presentation/view/live_chatbot/live_chatbot_screen.dart';
import 'package:tigo/presentation/view/profile/profile_screen.dart';
import 'package:tigo/presentation/view/root/widget/custom_bottom_navigation_bar/custom_bottom_navigation_bar.dart';
import 'package:tigo/presentation/view_model/root/root_view_model.dart';
import 'package:tigo/presentation/widget/dialog/sign_in_dialog.dart';
import 'package:tigo/core/constant/assets.dart';

class RootScreen extends BaseScreen<RootViewModel> {
  const RootScreen({super.key});

  @override
  Widget buildBody(BuildContext context) {
    return Obx(
          () => IndexedStack(
        index: viewModel.selectedIndex,
        children: const [
          LiveChatbotScreen(),
          HomeScreen(),
          ProfileScreen(),
        ],
      ),
    );
  }

  @override
  Widget? get buildFloatingActionButton => GestureDetector(
    onTap: () {
      if (viewModel.selectedIndex != 1) {
        viewModel.changeIndex(1);
      }
    },
    child: Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF5CA9FF), Color(0xFFD1C2FF)],
          begin: Alignment.bottomRight,
          end: Alignment.topRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: SvgPicture.asset(
          Assets.homeIcon,
          width: 25,
          height: 25,
          color: Colors.white,
        ),
      ),
    ),
  );

  @override
  FloatingActionButtonLocation? get floatingActionButtonLocation =>
      FloatingActionButtonLocation.centerDocked;

  @override
  bool get extendBodyBehindAppBar => true;

  @override
  Widget? buildBottomNavigationBar(BuildContext context) =>
      const CustomBottomNavigationBar();
}
