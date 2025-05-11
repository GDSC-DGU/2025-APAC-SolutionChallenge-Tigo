import 'package:flutter/material.dart';
import 'package:tigo/core/screen/base_screen.dart';
import 'package:tigo/presentation/view_model/profile/profile_view_model.dart';
import 'package:tigo/app/config/font_system.dart';

class ProfileScreen extends BaseScreen<ProfileViewModel> {
  const ProfileScreen({super.key});

  @override
  Widget buildBody(BuildContext context) {
    return const Center(child: Text('My Screen', style: FontSystem.H1));
  }
}
