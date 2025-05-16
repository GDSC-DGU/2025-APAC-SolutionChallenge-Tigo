import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:tigo/app/config/app_routes.dart';
import 'package:tigo/core/constant/assets.dart';
import 'package:tigo/core/screen/base_screen.dart';
import 'package:tigo/presentation/view_model/tigo_plan_chat/tigo_plan_chat_view_model.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:rive/rive.dart' as rive;
import 'dart:async';
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

  rive.SimpleAnimation? _riveController;

  void setRiveAnimation(String animationName) {
    if (_riveController?.animationName != animationName) {
      setState(() {
        _riveController = rive.SimpleAnimation(animationName);
      });
    }
  }

  String animatedText = "";
  int currentTypingIndex = 0;
  Timer? typingTimer;
  bool isTyping = false;

  void startTyping(String fullText) {
    typingTimer?.cancel();
    setState(() {
      animatedText = "";
      currentTypingIndex = 0;
      isTyping = true;
    });

    typingTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (currentTypingIndex < fullText.length) {
        setState(() {
          animatedText += fullText[currentTypingIndex];
          currentTypingIndex++;
        });
      } else {
        timer.cancel();
        setState(() {
          isTyping = false;
        });
      }
    });
  }

  // promptPath를 arguments에서 받아오기
  String get _promptPath {
    final args = Get.arguments;
    if (args is Map && args['promptPath'] is String) {
      return args['promptPath'] as String;
    }
    return 'assets/prompts/travel_recommend_prompt.md';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = Get.find<TigoPlanChatViewModel>();
      if (vm.messages.isEmpty) {
        // Firestore 기반 대화방 생성 및 실시간 리스닝 시작
        await vm.startNewDialog();
        // 첫 질문(프롬프트)을 Firestore에 저장
        String firstMessage;
        if (_promptPath.contains('free_question_prompt.md')) {
          firstMessage =
              "Do you want to develop your existing plan further? Or would you like to create something new? Just ask me anything!";
        } else {
          firstMessage =
              "Please freely enter any parts of your travel plan that are already decided.\nex) I'm planning to travel to Seoul with 6 friends at the end of May.";
        }
        await vm.addMessage(firstMessage, isUser: false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _ytController?.close();
    // 채팅창 벗어날 때 메시지 초기화
    final vm = Get.find<TigoPlanChatViewModel>();
    vm.messages.clear();
    super.dispose();
  }

  int userQuestionCount = 0;

  void _sendMessage() async {
    final vm = Get.find<TigoPlanChatViewModel>();
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    setState(() {
      userQuestionCount++;
    });

    // Firestore에 유저 메시지 저장
    await vm.addMessage(text, isUser: true);

    // Gemini 답변 받아오기 (promptPath 적용)
    final geminiAnswer = await vm.callGeminiWithHistory(
      vm.messages,
      text,
      promptPath: _promptPath,
    );

    // 1. 답변을 바로 messages에 추가 (isTypingMessage: true로 구분)
    final typingMsg = ChatMessage(text: "", isUser: false);
    setState(() {
      animatedText = "";
      currentTypingIndex = 0;
      isTyping = true;
      vm.messages.add(typingMsg); // 임시 메시지 추가
    });

    // 2. 타이핑 애니메이션 시작
    typingTimer?.cancel();
    typingTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (currentTypingIndex < geminiAnswer.length) {
        setState(() {
          animatedText += geminiAnswer[currentTypingIndex];
          currentTypingIndex++;
          // 현재 타이핑 중인 메시지의 text를 업데이트
          vm.messages[vm.messages.length - 1] = ChatMessage(
            text: animatedText,
            isUser: false,
          );
        });
      } else {
        timer.cancel();
        setState(() {
          isTyping = false;
          // 마지막 메시지를 최종 답변으로 교체
          vm.messages[vm.messages.length - 1] = ChatMessage(
            text: geminiAnswer,
            isUser: false,
          );
        });
        // 3. Firestore에 Gemini 답변 저장
        vm.addMessage(geminiAnswer, isUser: false);
      }
    });
  }

  void _playYoutube(String videoUrl) {
    final videoId = Uri.parse(videoUrl).queryParameters['v'] ?? '';
    if (videoId.isEmpty) return;
    setState(() {
      _currentVideoId = videoId;
      _ytController?.close();
      _ytController = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        params: const YoutubePlayerParams(
          showFullscreenButton: true,
          enableCaption: false,
        ),
      );
    });
  }

  Widget _buildVideoCard(ChatMessage msg) {
    final videoId =
        msg.videoUrl != null
            ? Uri.parse(msg.videoUrl!).queryParameters['v'] ?? ''
            : '';
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            onPressed: () => _playYoutube(msg.videoUrl!),
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
                              if (await canLaunchUrl(Uri.parse(url))) {
                                await launchUrl(Uri.parse(url));
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
          if (_currentVideoId == videoId && _ytController != null)
            Container(
              width: MediaQuery.of(context).size.width - 32,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: YoutubePlayer(controller: _ytController!),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TigoPlanChatViewModel>(
      builder: (vm) {
        return Scaffold(
          backgroundColor: const Color(0xFF80BFFF),
          body: Column(
            children: [
              const SizedBox(height: 50), // 상태바 여백
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      // 🔹 상단 헤더
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (_promptPath.contains(
                                      'free_question_prompt.md',
                                    )) {
                                      Get.offAllNamed(AppRoutes.ROOT);
                                    } else {
                                      Navigator.pop(context);
                                    }
                                  },
                                  child: const Icon(
                                    Icons.arrow_back_ios,
                                    size: 20,
                                  ),
                                ),
                                const Expanded(
                                  child: Center(
                                    child: Text(
                                      'Ask me anything',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),

                                if (!_promptPath.contains(
                                  'free_question_prompt.md',
                                ))
                                  Container(
                                    height: 30,
                                    width: 30,
                                    decoration: BoxDecoration(
                                      color:
                                          userQuestionCount >= 0
                                              ? const Color(0xFF80BFFF)
                                              : Colors.grey,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: IconButton(
                                      onPressed:
                                          userQuestionCount >= 0
                                              ? vm.requestTripPlan
                                              : null,
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                      ),
                                      iconSize: 15,
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.75,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: LinearProgressIndicator(
                                    value: (userQuestionCount / 5).clamp(
                                      0.0,
                                      1.0,
                                    ),
                                    minHeight: 6,
                                    backgroundColor: Colors.grey[300],
                                    color: const Color(0xFF80BFFF),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFE0E0E0),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            Obx(
                              () => ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  100,
                                ),
                                itemCount: vm.messages.length,
                                itemBuilder: (context, idx) {
                                  final msg = vm.messages[idx];
                                  if (msg.videoUrl != null) {
                                    final videoId =
                                        Uri.parse(
                                          msg.videoUrl!,
                                        ).queryParameters['v'] ??
                                        '';
                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
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
                                                            color:
                                                                Colors
                                                                    .grey[200],
                                                          ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        msg.videoTitle ?? '',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                        maxLines: 2,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        msg.videoSummary ?? '',
                                                        style: const TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 13,
                                                        ),
                                                        maxLines: 3,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          ElevatedButton(
                                                            onPressed: () {
                                                              setState(() {
                                                                _currentVideoId =
                                                                    videoId;
                                                                _ytController = YoutubePlayerController.fromVideoId(
                                                                  videoId:
                                                                      videoId,
                                                                  params: const YoutubePlayerParams(
                                                                    showFullscreenButton:
                                                                        true,
                                                                    enableCaption:
                                                                        false,
                                                                  ),
                                                                );
                                                              });
                                                            },
                                                            child: const Text(
                                                              '영상 재생',
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          IconButton(
                                                            icon: const Icon(
                                                              Icons.open_in_new,
                                                              color:
                                                                  Colors.blue,
                                                            ),
                                                            onPressed: () async {
                                                              final url =
                                                                  msg.videoUrl!;
                                                              if (await canLaunchUrl(
                                                                Uri.parse(url),
                                                              )) {
                                                                await launchUrl(
                                                                  Uri.parse(
                                                                    url,
                                                                  ),
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
                                            SizedBox(
                                              width:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.width -
                                                  32,
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
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Flexible(
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFF4FAFF,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  msg.text,
                                                  style: const TextStyle(
                                                    color: Color(0xFF0D5ECF),
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
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF5F5F7),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Row(
                                          children: [
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
                                          final plan = vm
                                              .parseTravelPlanFromJson(
                                                msg.text,
                                              );
                                          // TODO: 일정표 상세 화면으로 이동
                                        },
                                        child: const Text('계획표 자세히 보기'),
                                      ),
                                    );
                                  } else {
                                    return Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              width: 45,
                                              height: 60,
                                              child: rive.RiveAnimation.asset(
                                                'assets/animations/walk.riv',
                                                fit: BoxFit.cover,
                                                controllers: [
                                                  rive.SimpleAnimation('Blink'),
                                                ],
                                              ),
                                            ),

                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFF5F5F7,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  (msg.isUser ||
                                                          msg !=
                                                              vm
                                                                  .messages
                                                                  .last ||
                                                          !isTyping)
                                                      ? msg.text
                                                      : animatedText,
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
                          ],
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _controller,
                                          decoration: const InputDecoration(
                                            hintText: "Let's make a plan…..",
                                            border: InputBorder.none,
                                            filled: true,
                                            fillColor: Colors.white,
                                            isCollapsed: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: 14,
                                                ),
                                          ),
                                          onSubmitted: (_) => _sendMessage(),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: _sendMessage,
                                        icon: const Icon(Icons.send),
                                        color: const Color(0xFFB5AFFF),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                height: 48,
                                width: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF80BFFF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  onPressed: vm.requestTripPlan,

                                  icon: const Icon(
                                    Icons.mic,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
