import 'package:flutter/material.dart';
import 'package:tigo/core/screen/base_screen.dart';
import 'package:tigo/presentation/view_model/live_chatbot/live_chatbot_view_model.dart';
import 'package:tigo/presentation/widget/appbar/text_default_app_bar.dart';
import 'package:tigo/app/config/font_system.dart';

class LiveChatbotScreen extends BaseScreen<LiveChatbotViewModel> {
  const LiveChatbotScreen({super.key});

  @override
  Widget buildBody(BuildContext context) {
    return const Center(
      child: Text('Live Chatbot Screen', style: FontSystem.H1),
    );
  }
}
