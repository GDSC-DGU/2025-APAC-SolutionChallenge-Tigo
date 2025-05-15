import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:tigo/core/constant/assets.dart';
import 'package:tigo/core/screen/base_screen.dart';
import 'package:tigo/presentation/view_model/tigo_plan_chat/tigo_plan_chat_view_model.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class TigoPlanChatScreen extends BaseScreen<TigoPlanChatViewModel> {
  const TigoPlanChatScreen({super.key});

  @override
  Widget buildBody(BuildContext context) {
    return _TigoPlanChatScreenBody();
  }
}

class _TigoPlanChatScreenBody extends StatefulWidget {
  @override
  State<_TigoPlanChatScreenBody> createState() =>
      _TigoPlanChatScreenBodyState();
}

class _TigoPlanChatScreenBodyState extends State<_TigoPlanChatScreenBody> {
  final TextEditingController _controller = TextEditingController();
  String? _currentVideoId;
  YoutubePlayerController? _ytController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = Get.find<TigoPlanChatViewModel>();
      if (vm.messages.isEmpty) {
        // Firestore 기반 대화방 생성 및 실시간 리스닝 시작
        await vm.startNewDialog();
        // 첫 질문(프롬프트)을 Firestore에 저장
        await vm.addMessage(
          "현재 당신의 여행 계획 중 정해진 부분을 자유롭게 입력해주세요~\nex) 5월 말에 친구 6명이랑 서울로 여행을 갈 계획이야.",
          isUser: false,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _ytController?.close();
    super.dispose();
  }

  void _sendMessage() async {
    final vm = Get.find<TigoPlanChatViewModel>();
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    // Firestore에 유저 메시지 저장
    await vm.addMessage(text, isUser: true);

    // Gemini에 user 메시지 전달 → 답변 받기
    final geminiAnswer = await vm.callGeminiApi(text);

    // Firestore에 Gemini 답변 저장
    await vm.addMessage(geminiAnswer, isUser: false);
  }

  void _requestTripPlan() async {
    final vm = Get.find<TigoPlanChatViewModel>();
    final result = await vm.requestTripPlan();
    if (result != null) {
      print('result: $result');
      // Firestore에 일정표 요약 메시지 저장(옵션)
      await vm.addMessage('[여행 일정표]\n$result', isUser: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TigoPlanChatViewModel>(
      builder:
          (vm) => Column(
            children: [
              Expanded(
                child: Obx(
                  () => ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: vm.messages.length,
                    itemBuilder: (context, idx) {
                      final msg = vm.messages[idx];
                      if (msg.videoUrl != null) {
                        final videoId =
                            Uri.parse(msg.videoUrl!).queryParameters['v'] ?? '';
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child:
                                          msg.thumbnailUrl != null
                                              ? Image.network(
                                                msg.thumbnailUrl!,
                                                width: 120,
                                                height: 80,
                                                fit: BoxFit.cover,
                                              )
                                              : Container(
                                                width: 120,
                                                height: 80,
                                                color: Colors.grey[200],
                                              ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            msg.videoTitle ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            msg.videoSummary ?? '',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 13,
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              ElevatedButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _currentVideoId = videoId;
                                                    _ytController =
                                                        YoutubePlayerController.fromVideoId(
                                                          videoId: videoId,
                                                          params: const YoutubePlayerParams(
                                                            showFullscreenButton:
                                                                true,
                                                            enableCaption:
                                                                false,
                                                          ),
                                                        );
                                                  });
                                                },
                                                child: const Text('영상 재생'),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.open_in_new,
                                                  color: Colors.blue,
                                                ),
                                                onPressed: () async {
                                                  final url = msg.videoUrl!;
                                                  if (await canLaunchUrl(
                                                    Uri.parse(url),
                                                  )) {
                                                    await launchUrl(
                                                      Uri.parse(url),
                                                    );
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_currentVideoId == videoId &&
                                  _ytController != null)
                                Container(
                                  width: MediaQuery.of(context).size.width - 32,
                                  child: AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: YoutubePlayer(
                                      controller: _ytController!,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      } else if (msg.isUser) {
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      msg.text,
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        );
                      } else if (msg.isTimetable &&
                          msg.text == '여행 일정표 요약 생성 중...') {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: const [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('여행 일정표 요약 생성 중...'),
                              ],
                            ),
                          ),
                        );
                      } else if (msg.isTimetable) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton(
                            onPressed: () {
                              final plan = vm.parseTravelPlanFromJson(msg.text);
                              // TODO: 일정표 상세 화면으로 이동
                            },
                            child: const Text('계획표 자세히 보기'),
                          ),
                        );
                      } else {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.asset(
                                  Assets.chatTigoImage,
                                  width: 36,
                                  height: 36,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      msg.text,
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: '여행 계획을 입력하세요... (엔터로 전송)',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendMessage,
                      ),
                      ElevatedButton(
                        onPressed: _requestTripPlan,
                        child: const Text('여행 계획표 생성'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isTimetable;
  final bool isLoading;
  final String? videoUrl;
  final String? videoTitle;
  final String? videoSummary;
  final String? thumbnailUrl;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.isTimetable,
    required this.isLoading,
    required this.videoUrl,
    required this.videoTitle,
    required this.videoSummary,
    required this.thumbnailUrl,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    bool safeBool(dynamic v, [bool fallback = false]) {
      if (v is bool) return v;
      if (v is int) return v != 0;
      if (v is String) return v.toLowerCase() == 'true';
      return fallback;
    }

    return ChatMessage(
      text: json['text'] ?? '',
      isUser: safeBool(json['isUser']),
      isTimetable: safeBool(json['isTimetable']),
      isLoading: safeBool(json['isLoading']),
      videoUrl: json['videoUrl'],
      videoTitle: json['videoTitle'],
      videoSummary: json['videoSummary'],
      thumbnailUrl: json['thumbnailUrl'],
    );
  }
}
