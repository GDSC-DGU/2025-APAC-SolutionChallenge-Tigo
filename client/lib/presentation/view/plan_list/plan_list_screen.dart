


import 'package:flutter/material.dart';
import 'package:tigo/core/screen/base_screen.dart';
import 'package:tigo/presentation/view_model/plan_list/plan_list_view_model.dart';
import 'package:tigo/presentation/view_model/profile/profile_view_model.dart';
import 'package:tigo/app/config/font_system.dart';

class PlanListScreen extends BaseScreen<PlanListViewModel> {
  const PlanListScreen({super.key});

  @override
  Widget buildBody(BuildContext context) {
    return const Center(child: Text('Plan List Screen', style: FontSystem.H1));
  }
}
