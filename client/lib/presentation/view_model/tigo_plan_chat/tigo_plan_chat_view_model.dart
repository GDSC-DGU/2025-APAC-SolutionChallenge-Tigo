import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:tigo/app/config/app_routes.dart';
import 'package:tigo/presentation/view/tigo_plan_completed_screen/quick_plan_test_screen.dart';

class TigoPlanChatViewModel extends GetxController {
  // 여행 챗봇 메시지 리스트
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isLoading = false.obs;

  String get geminiApiKey => dotenv.get('GEMINI_API_KEY');
  String get youtubeApiKey => dotenv.get('YOUTUBE_API_KEY');
  String get projectId => dotenv.get('PROJECT_ID');
  TigoPlanChatViewModel() {
    print('[DEBUG] GEMINI_API_KEY: $geminiApiKey');
    print('[DEBUG] PROJECT_ID: $projectId');
    // print('[DEBUG] YOUTUBE_API_KEY: $youtubeApiKey');
  }

  // 유저 메시지 추가
  void addUserMessage(String text) {
    messages.add(ChatMessage(text: text, isUser: true));
    // 최근 5개마다 트리거
    if (messages.length % 5 == 0) {
      sendRecentMessagesToServer();
    }
  }

  void sendRecentMessagesToServer() {
    final filtered = messages.where((m) => m.text != '여행 계획표 생성 실패').toList();
    final recent =
        filtered.length > 5 ? filtered.sublist(filtered.length - 5) : filtered;
    // 서버로 전송
    requestTripPlanWithDialog(recent);
  }

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
  // 일정표 생성 요청 (dialog[] 전체를 서버로 전송)
  Future<String?> requestTripPlan() async {
    final url = Uri.parse(
      'http://127.0.0.1:5001/${projectId}/us-central1/tripPlan',
    );
    final userId = 'test1'; // 테스트용 userId
    final body = jsonEncode({'userId': userId});
    print('[DEBUG] 서버로 보내는 userId: $userId');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Get.toNamed(AppRoutes.TIGO_PLAN_COMPLETED);
      final planList = safeParsePlanList(data['result']);

      Get.to(() => QuickPlanTestScreen(planList: planList));
      // Navigator.push(
      //   context
      //   MaterialPageRoute(
      //     builder: (_) => QuickPlanTestScreen(planList: data['result']),
      //   ),
      // );
      return data['result'];
    } else {
      messages.add(ChatMessage(text: '여행 계획표 생성 실패', isUser: false));
      return null;
    }
  }

  Future<void> sendToGeminiWithDialog(List<Map<String, dynamic>> dialog) async {
    try {
      final url = Uri.parse(
        'http://127.0.0.1:5001/${projectId}/us-central1/tripPlan',
      );
      final userId = 'test'; // 테스트용 userId
      final body = jsonEncode({'userId': userId});
      print('[DEBUG] Gemini API 호출(userId): $userId');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['result'] ?? '응답 없음';
        messages.add(ChatMessage(text: text, isUser: false));
      } else {
        print(
          '[Gemini API 오류] status: ${response.statusCode}, body: ${response.body}',
        );
        messages.add(
          ChatMessage(text: 'Gemini API 오류: ${response.body}', isUser: false),
        );
      }
    } catch (e, stack) {
      print('[Gemini API 예외] $e\n$stack');
      messages.add(ChatMessage(text: 'Gemini API 예외 발생: $e', isUser: false));
    }
  }

  // 최초 system 프롬프트만 서버에 저장하고 Gemini 첫 질문 받아오기
  Future<String?> startTravelChat() async {
    final prompt = await rootBundle.loadString(
      'assets/prompts/travel_recommend_prompt.md',
    );
    final systemPrompt = '$prompt\n\n모든 답변은 반드시 한글로, 질문-답변식으로 정보를 수집해줘.';
    // 서버에 systemPrompt 저장
    await requestTripPlanWithDialog([
      ChatMessage(text: systemPrompt, isUser: true),
    ]);
    // 서버에서 Gemini 호출 → 첫 assistant 메시지 받아오기
    final url = Uri.parse(
      'http://127.0.0.1:5001/${projectId}/us-central1/tripPlan',
    );
    final userId = 'test';
    final body = jsonEncode({'userId': userId});
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['result'];
    } else {
      return null;
    }
  }

  // 유저 입력과 직전 assistant 메시지를 1cycle로 서버에 저장만 (Gemini 호출 X)
  Future<void> saveUserAndAssistantCycle(String userInput) async {
    final userId = 'test';
    final url = Uri.parse(
      'http://127.0.0.1:5001/${projectId}/us-central1/saveDialog',
    );
    // 직전 assistant 메시지 찾기
    final lastAssistant = messages.reversed.firstWhere(
      (m) => !m.isUser,
      orElse: () => null as ChatMessage,
    );
    final List<ChatMessage> cycle = [];
    if (lastAssistant != null) {
      cycle.add(ChatMessage(text: lastAssistant.text, isUser: false));
    }
    cycle.add(ChatMessage(text: userInput, isUser: true));
    final dialog =
        cycle
            .map(
              (m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.text,
              },
            )
            .toList();
    final body = jsonEncode({'userId': userId, 'dialog': dialog});
    try {
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      print('[DEBUG] saveDialog(1cycle) 호출 완료####');
    } catch (e) {
      print('[ERROR] saveDialog(1cycle) 호출 실패: $e');
    }
  }

  // 일반 대화(이후 system 프롬프트 없이 user/model만)
  Future<void> continueTravelChat(String userInput) async {
    final dialog = [
      ...messages.map(
        (m) => {
          'role': m.isUser ? 'user' : 'model',
          'parts': [
            {'text': m.text},
          ],
        },
      ),
      {
        'role': 'user',
        'parts': [
          {'text': userInput},
        ],
      },
    ];
    await sendToGeminiWithDialog(dialog);
  }

  // 최근 N개 메시지를 서버에 임시 저장 (응답은 무시)
  Future<void> requestTripPlanWithDialog(List<ChatMessage> recent) async {
    // 테스트용 userId
    final userId = 'test';
    final url = Uri.parse(
      'http://127.0.0.1:5001/${projectId}/us-central1/saveDialog',
    );
    final dialog =
        recent
            .map(
              (m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.text,
              },
            )
            .toList();
    final body = jsonEncode({'userId': userId, 'dialog': dialog});
    try {
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      // 응답은 무시 (성공 여부만 로그)
      print('[DEBUG] saveDialog 호출 완료');
    } catch (e) {
      print('[ERROR] saveDialog 호출 실패: $e');
    }
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
    final userId = 'test';
    final url = Uri.parse(
      'http://127.0.0.1:5001/$projectId/us-central1/saveDialog',
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
