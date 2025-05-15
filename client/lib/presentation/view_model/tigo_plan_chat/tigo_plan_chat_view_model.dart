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
  String? currentDialogId;
  StreamSubscription? _messagesSub;

  String get userId => Get.find<HomeViewModel>().userBriefState.id;
  String get projectId => dotenv.get('PROJECT_ID');

  // 대화방 생성
  Future<void> startNewDialog() async {
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
  Future<List<Map<String, dynamic>>> requestTripPlan() async {
    if (currentDialogId == null) throw Exception('대화방이 없습니다.');
    final url = Uri.parse(
      'http://127.0.0.1:5001/$projectId/us-central1/tripPlan',
    );
    final body = jsonEncode({'userId': userId});
    print('[DEBUG] 플랜 생성 요청: userId=$userId, dialogId=$currentDialogId');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    print(
      '[DEBUG] 플랜 생성 응답: status=${response.statusCode}, body=${response.body}',
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final planList = safeParsePlanList(data['schedules']);
      print('[DEBUG] 받은 일정 데이터: $planList');
      Get.to(() => QuickPlanTestScreen(planList: planList));
      return planList;
    } else {
      messages.add(ChatMessage(text: '여행 계획표 생성 실패', isUser: false));
      return [];
    }
  }

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

  Future<void> saveLastCycleToServer() async {
    final url = Uri.parse(
      'http://127.0.0.1:5001/$projectId/us-central1/createDialog',
    );
    if (messages.length < 2) return;
    final lastUser = messages.lastWhere(
      (m) => m.isUser,
      orElse: () => null as ChatMessage,
    );
    final lastAssistant = messages.reversed.firstWhere(
      (m) => !m.isUser,
      orElse: () => null as ChatMessage,
    );
    if (lastUser == null || lastAssistant == null) return;
    final dialog = [
      {'role': 'assistant', 'content': lastAssistant.text},
      {'role': 'user', 'content': lastUser.text},
    ];
    final body = jsonEncode({'userId': userId, 'dialog': dialog});
    try {
      print('DEBUG] 서버에 저장되는 유저 id : $userId');
      print("[DEBUG] 서버에 저장되는 대화 내용: $dialog");
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      print('[DEBUG] saveDialog(1cycle) 호출 완료@@@@@@');
    } catch (e) {
      print('[ERROR] saveDialog(1cycle) 호출 실패: $e');
    }
  }

  Future<void> addMessageToDialog(String dialogId, ChatMessage message) async {
    final messagesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('dialogs')
        .doc(dialogId)
        .collection('messages');
    await messagesRef.add({
      'text': message.text,
      'isUser': message.isUser,
      'createdAt': DateTime.now().toIso8601String(),
      // 필요시 추가 필드
    });
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
