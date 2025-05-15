import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:tigo/app/config/app_routes.dart';
import 'package:tigo/presentation/view/tigo_plan_completed_screen/quick_plan_test_screen.dart';
import 'package:tigo/presentation/view_model/home/home_view_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

class TigoPlanChatViewModel extends GetxController {
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isEnableGreyBarrier = false.obs;
  String? currentDialogId;
  StreamSubscription? _messagesSub;

  String get userId => Get.find<HomeViewModel>().userBriefState.id;
  String get projectId => dotenv.get('PROJECT_ID');

  // 대화방 생성
  Future<void> startNewDialog() async {

    print('userId in startDialog: $userId');
    final dialogsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('dialogs');
    final dialogDoc = await dialogsRef.add({
      'createdAt': DateTime.now().toIso8601String(),
    });
    currentDialogId = dialogDoc.id;
    print('[DEBUG] 대화방 생성: $currentDialogId');
    listenToMessages(currentDialogId!);
  }

  // 메시지 저장
  Future<void> addMessage(String text, {bool isUser = true}) async {
    if (currentDialogId == null) await startNewDialog();
    final messagesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('dialogs')
        .doc(currentDialogId)
        .collection('messages');
    final docRef = await messagesRef.add({
      'text': text,
      'isUser': isUser,
      'createdAt': DateTime.now().toIso8601String(),
    });
    print(
      '[DEBUG] 메시지 저장: dialogId=$currentDialogId, messageId=${docRef.id}, text=$text, isUser=$isUser',
    );
  }

  // 실시간 리스닝 (대화방 메시지)
  void listenToMessages(String dialogId) {
    _messagesSub?.cancel();
    final messagesStream =
        FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('dialogs')
            .doc(dialogId)
            .collection('messages')
            .orderBy('createdAt')
            .snapshots();
    _messagesSub = messagesStream.listen((snapshot) {
      final msgs =
          snapshot.docs.map((doc) => ChatMessage.fromJson(doc.data())).toList();
      print('[DEBUG] 실시간 메시지 수신: ${msgs.length}개');
      messages.assignAll(msgs);
    });
  }

  // 플랜 생성
  Future<void> requestTripPlan() async {
    // 1. 로딩 스크린으로 이동 (요청과 로직은 해당 화면이 담당)
    // Get.offAllNamed(AppRoutes.TIGO_PLAN_CREATING, arguments: userId);
    print('userId in request TripPlan: ${userId}');
    Get.toNamed(AppRoutes.TIGO_PLAN_CREATING, arguments: {'userId': userId});

  }
  // Future<List<Map<String, dynamic>>> requestTripPlan() async {
  //   // Firestore에 dialogs 문서가 실제로 있는지 확인
  //   final dialogDoc =
  //       await FirebaseFirestore.instance
  //           .collection('users')
  //           .doc(userId)
  //           .collection('dialogs')
  //           .doc(currentDialogId)
  //           .get();
  //   if (!dialogDoc.exists) {
  //     await startNewDialog();
  //     return [];
  //   }
  //
  //   // 1. 로딩 스크린으로 이동
  //   Get.offAllNamed(AppRoutes.TIGO_PLAN_CREATING, arguments: userId);
  //
  //   final url = Uri.parse('${apiBaseUrl}/tripPlan');
  //   final body = jsonEncode({'userId': userId, 'dialogId': currentDialogId});
  //   final response = await http.post(
  //     url,
  //     headers: {'Content-Type': 'application/json'},
  //     body: body,
  //   );
  //
  //   if (response.statusCode == 200) {
  //     final data = jsonDecode(response.body);
  //     final planList = safeParsePlanList(data['schedules']);
  //     // 2. 플랜 결과 화면으로 이동
  //     Get.offAll(() => QuickPlanTestScreen(planList: planList));
  //     return planList;
  //   } else {
  //     messages.add(ChatMessage(text: '여행 계획표 생성 실패', isUser: false));
  //     // 실패 시에도 로딩 화면에서 벗어나고 싶으면 아래처럼 처리
  //     Get.offAllNamed('/errorScreen'); // 또는 적절한 에러 처리
  //     return [];
  //   }
  // }

  @override
  void onClose() {
    _messagesSub?.cancel();
    super.onClose();
  }

  String get geminiApiKey => dotenv.get('GEMINI_API_KEY');
  String get youtubeApiKey => dotenv.get('YOUTUBE_API_KEY');
  String get apiBaseUrl => dotenv.get('API_BASE_URL');

  // 유튜브 영상 추천 메시지 추가
  void addYoutubeMessages(List<YoutubeSummary> videos) {
    if (videos.isEmpty) {
      messages.add(ChatMessage(text: '적합한 유튜브 영상을 찾지 못했습니다.', isUser: false));
    } else {
      for (final v in videos.take(2)) {
        messages.add(
          ChatMessage(
            text: v.title,
            isUser: false,
            videoUrl: v.videoUrl,
            videoTitle: v.title,
            videoSummary: v.summary,
            thumbnailUrl: v.thumbnailUrl,
          ),
        );
      }
    }
  }

  // Gemini 일정표 로딩 메시지
  void addTimetableLoading() {
    messages.add(
      ChatMessage(
        text: '여행 일정표 요약 생성 중...',
        isUser: false,
        isTimetable: true,
        isLoading: true,
      ),
    );
  }

  // Gemini 일정표 결과 메시지 교체
  void replaceTimetable(String timetable) {
    final idx = messages.indexWhere((m) => m.isLoading && m.isTimetable);
    if (idx != -1) {
      messages[idx] = ChatMessage(
        text: timetable,
        isUser: false,
        isTimetable: true,
      );
    }
  }

  // 유튜브 영상 추천
  Future<List<YoutubeSummary>> recommendYoutubeVideosLLM(String query) async {
    try {
      final url = Uri.parse(
        'https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=5&q=${Uri.encodeComponent(query)}&key=$youtubeApiKey',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List<dynamic>?;
        if (items == null) return [];
        return items.map<YoutubeSummary>((item) {
          final snippet = item['snippet'];
          final videoId = item['id']?['videoId'] ?? '';
          return YoutubeSummary(
            title: snippet['title'] ?? '',
            summary: snippet['description']?.toString().substring(0, 80) ?? '',
            thumbnailUrl: snippet['thumbnails']?['high']?['url'] ?? '',
            videoUrl: 'https://www.youtube.com/watch?v=$videoId',
          );
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Gemini API로 여행 일정표 요청
  Future<void> sendTravelPlanRequest(
    String userInput,
    List<YoutubeSummary> videos,
  ) async {
    isLoading.value = true;
    try {
      final response = await callGeminiApiWithVideos(videos, userInput);
      messages.add(
        ChatMessage(text: response, isUser: false, isTimetable: true),
      );
    } catch (e) {
      messages.add(ChatMessage(text: '일정표 생성 실패: $e', isUser: false));
    } finally {
      isLoading.value = false;
    }
  }

  // Gemini API 호출 (여행 일정표 생성)
  Future<String> callGeminiApiWithVideos(
    List<YoutubeSummary> videos,
    String userInput,
  ) async {
    final city = extractCityFromUserInput(userInput);
    final videoListText = videos
        .asMap()
        .entries
        .map(
          (e) =>
              '${e.key + 1}. 제목: ${e.value.title}, 설명: ${e.value.summary}, 썸네일: ${e.value.thumbnailUrl}, 링크: ${e.value.videoUrl}',
        )
        .join('\n');
    final prompt = '''
아래 유튜브 브이로그 영상들의 제목과 설명을 참고해서
"$city 여행 1박 2일 추천 일정표"를 만들어줘.
- 각 Day별(예: Day 1, Day 2)로 나누고,
- 각 일정(오전/오후/저녁 등)에 방문할 장소, 맛집, 관광지 등만 간단히 한 줄로 정리해줘.
- 각 일정 옆에 관련된 유튜브 영상 제목과 링크를 함께 붙여줘.
- 전체를 아래 JSON 형식으로 반환해줘.
{
  "timetable": [ ... ]
}
아래는 참고할 유튜브 영상 리스트야:
$videoListText
''';
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$geminiApiKey',
    );
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt},
            ],
          },
        ],
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (text == null) throw Exception('Gemini 응답 파싱 실패');
      return text;
    } else {
      throw Exception('Gemini API 호출 실패: ${response.body}');
    }
  }

  // 유저 입력에서 도시명 추출 (간단 예시)
  String extractCityFromUserInput(String userInput) {
    final cities = ['서울', '부산', '제주', '강릉', '여수', '경주', '인천', '대전', '대구', '광주'];
    for (final city in cities) {
      if (userInput.contains(city)) return city;
    }
    return '한국';
  }

  // 일정표 JSON 파싱
  TravelPlan parseTravelPlanFromJson(String jsonStr) {
    final data = jsonDecode(cleanJson(jsonStr));
    final timetable = data['timetable'];
    if (timetable == null || timetable is! List) {
      throw Exception('일정표 파싱에 실패했습니다. 응답 구조를 확인하세요.');
    }
    final dates = timetable.map((e) => e['day'] as String? ?? '').toList();
    final schedulesByDay =
        timetable.map<List<ScheduleItem>>((day) {
          final schedule = day['schedule'];
          if (schedule == null || schedule is! List) return [];
          return schedule.map<ScheduleItem>((item) {
            return ScheduleItem(
              place: item['place'] ?? '',
              category: item['category'],
              description: item['reason'],
              thumbnailUrl: item['thumbnailUrl'],
            );
          }).toList();
        }).toList();
    return TravelPlan(
      city: data['city'] ?? '',
      dates: List<String>.from(dates),
      selectedDayIndex: 0,
      schedulesByDay: List<List<ScheduleItem>>.from(schedulesByDay),
    );
  }

  String cleanJson(String raw) {
    return raw
        .replaceAll(RegExp(r'```json'), '')
        .replaceAll(RegExp(r'```'), '')
        .trim();
  }

  Future<String> callGeminiApi(String userInput) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$geminiApiKey',
    );
    final prompt = userInput; // 필요시 프롬프트 가공
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt},
            ],
          },
        ],
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (text == null) throw Exception('Gemini 응답 파싱 실패');
      return text;
    } else {
      throw Exception('Gemini API 호출 실패: ${response.body}');
    }
  }

  // Gemini API 호출용 프롬프트 생성 함수
  Future<String> buildGeminiPromptWithHistory(
    List<ChatMessage> messages,
  ) async {
    // 1. 프롬프트 파일 읽기
    final prompt = await rootBundle.loadString(
      'assets/prompts/travel_recommend_prompt.md',
    );

    // 2. Firestore에서 불러온 messages를 role별로 변환
    final history = messages
        .map((m) {
          final role = m.isUser ? 'user' : 'assistant';
          return '$role: [33m${m.text}[0m';
        })
        .join('\n');

    print('==== [Gemini 프롬프트] travel_recommend_prompt.md ====');
    print(prompt);
    print('==== [Gemini 대화 히스토리] ====');
    print(history);

    // 3. 최종 프롬프트 조합
    final fullPrompt = '$prompt\n\n[대화 내역]\n$history\n';
    print('==== [Gemini 최종 프롬프트] ====');
    print(fullPrompt);
    return fullPrompt;
  }

  // Gemini API 호출 시 사용 예시
  Future<String> callGeminiWithHistory(
    List<ChatMessage> messages,
    String userInput,
  ) async {
    // 만약 messages 마지막이 이미 userInput이면, 중복 추가하지 않음
    List<ChatMessage> history = List.from(messages);
    if (history.isEmpty ||
        history.last.text != userInput ||
        !history.last.isUser) {
      history.add(ChatMessage(text: userInput, isUser: true));
    }

    print('==== [Gemini 호출] userInput ====');
    print(userInput);
    print('==== [Gemini 호출] history.length: ${history.length} ====');
    for (var i = 0; i < history.length; i++) {
      print(
        '  [${i + 1}] ${history[i].isUser ? 'user' : 'assistant'}: ${history[i].text}',
      );
    }

    final fullPrompt = await buildGeminiPromptWithHistory(history);

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$geminiApiKey',
    );
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": fullPrompt},
            ],
          },
        ],
      }),
    );

    print('==== [Gemini API 응답 status] ${response.statusCode} ====');
    print('==== [Gemini API 응답 body] ====');
    print(response.body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];

      if (text == null) throw Exception('Gemini 응답 파싱 실패');
      print('==== [Gemini 최종 응답 텍스트] ====');
      print(text);
      return text;
    } else {
      throw Exception('Gemini API 호출 실패: ${response.body}');
    }
  }
}

// 채팅 메시지 모델
class ChatMessage {
  final String text;
  final bool isUser;
  final bool isTimetable;
  final bool isLoading;
  final String? videoUrl;
  final String? videoTitle;
  final String? videoSummary;
  final String? thumbnailUrl;
  ChatMessage({
    required this.text,
    required this.isUser,
    this.isTimetable = false,
    this.isLoading = false,
    this.videoUrl,
    this.videoTitle,
    this.videoSummary,
    this.thumbnailUrl,
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

// 유튜브 요약 모델 (예시)
class YoutubeSummary {
  final String title;
  final String summary;
  final String thumbnailUrl;
  final String videoUrl;
  YoutubeSummary({
    required this.title,
    required this.summary,
    required this.thumbnailUrl,
    required this.videoUrl,
  });
}

// 여행 일정표 모델
class TravelPlan {
  final String city;
  final List<String> dates;
  final int selectedDayIndex;
  final List<List<ScheduleItem>> schedulesByDay;
  TravelPlan({
    required this.city,
    required this.dates,
    required this.selectedDayIndex,
    required this.schedulesByDay,
  });
  List<ScheduleItem> get selectedDay => schedulesByDay[selectedDayIndex];
}

class ScheduleItem {
  final String place;
  final String? category;
  final String? description;
  final String? thumbnailUrl;
  final double? lat;
  final double? lng;
  ScheduleItem({
    required this.place,
    this.category,
    this.description,
    this.thumbnailUrl,
    this.lat,
    this.lng,
  });
}

// result가 무엇이든 안전하게 List<Map<String, dynamic>>로 변환
List<Map<String, dynamic>> safeParsePlanList(dynamic result) {
  if (result == null) return [];
  if (result is List) {
    // 이미 List라면 각 요소를 Map으로 변환
    return result.map((e) => Map<String, dynamic>.from(e)).toList();
  }
  if (result is String) {
    try {
      final decoded = jsonDecode(result);
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      // 파싱 실패
      return [];
    }
  }
  // 그 외 타입은 빈 리스트 반환
  return [];
}
