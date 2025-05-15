import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tigo/presentation/view/live_chatbot/LiveMediaManager.dart';
import 'package:tigo/presentation/view/live_chatbot/PCMProcessor.dart';
import 'package:camera/camera.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// 앱 상태 관리용 enum
enum AppStatus { disconnected, connecting, connected, speaking }

// Gemini 응답 메시지 파싱 클래스
class GeminiLiveResponseMessage {
  String data = "";
  String type = "";
  bool? endOfTurn;

  GeminiLiveResponseMessage(dynamic rawData) {
    // rawData는 Map<String, dynamic> 또는 JSON String
    Map<String, dynamic> dataMap =
        rawData is String ? jsonDecode(rawData) : rawData;
    endOfTurn = dataMap['serverContent']?['turnComplete'];
    final parts = dataMap['serverContent']?['modelTurn']?['parts'];
    if (dataMap['setupComplete'] == true) {
      type = "SETUP COMPLETE";
    } else if (parts != null && parts.isNotEmpty && parts[0]['text'] != null) {
      data = parts[0]['text'];
      type = "TEXT";
    } else if (parts != null &&
        parts.isNotEmpty &&
        parts[0]['inlineData'] != null) {
      data = parts[0]['inlineData']['data'];
      type = "AUDIO";
    }
  }
}

// Gemini Live API WebSocket 관리 클래스
class GeminiLiveAPI {
  final String proxyUrl;
  String projectId;
  final String model;
  final String apiHost;
  late String modelUri;
  List<String> responseModalities = ["AUDIO"];
  String systemInstructions = "";
  late String serviceUrl;
  WebSocketChannel? _ws;
  StreamSubscription? _wsSub;

  // 콜백
  void Function(GeminiLiveResponseMessage message)? onReceiveResponse;
  void Function()? onConnectionStarted;
  void Function(String message)? onErrorMessage;

  GeminiLiveAPI({
    required this.proxyUrl,
    required this.projectId,
    required this.model,
    required this.apiHost,
  }) {
    modelUri =
        "projects/$projectId/locations/us-central1/publishers/google/models/$model";
    serviceUrl =
        "wss://$apiHost/ws/google.cloud.aiplatform.v1beta1.LlmBidiService/BidiGenerateContent";
  }

  void setProjectId(String newProjectId) {
    projectId = newProjectId;
    modelUri =
        "projects/$projectId/locations/us-central1/publishers/google/models/$model";
  }

  Future<void> connect() async {
    await setupWebSocketToService();
  }

  Future<void> disconnect() async {
    await _wsSub?.cancel();
    _ws?.sink.close();
    _ws = null;
    _wsSub = null;
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_ws != null) {
      print('[GeminiLiveAPI] 메시지 전송: ${jsonEncode(message)}');
      _ws!.sink.add(jsonEncode(message));
    }
  }

  void _onReceiveMessage(dynamic messageEvent) {
    try {
      print('[GeminiLiveAPI] 메시지 수신: $messageEvent');
      final messageData =
          messageEvent is String ? jsonDecode(messageEvent) : messageEvent;
      final message = GeminiLiveResponseMessage(messageData);
      onReceiveResponse?.call(message);
    } catch (e) {
      print('[GeminiLiveAPI] 메시지 파싱 오류: $e');
      onErrorMessage?.call('메시지 파싱 오류: $e');
    }
  }

  Future<void> setupWebSocketToService() async {
    try {
      print('[GeminiLiveAPI] WebSocket 연결 시도: $proxyUrl');
      _ws = WebSocketChannel.connect(Uri.parse(proxyUrl));
      _wsSub = _ws!.stream.listen(
        _onReceiveMessage,
        onError: (e) {
          print('[GeminiLiveAPI] WebSocket 오류: $e');
          onErrorMessage?.call('WebSocket 오류: $e');
        },
        onDone: () {
          print('[GeminiLiveAPI] WebSocket 연결 종료');
          onErrorMessage?.call('WebSocket 연결 종료');
        },
      );
      // 연결 후 초기 메시지 전송
      print('[GeminiLiveAPI] 초기 설정 메시지 전송');
      sendInitialSetupMessages();
      onConnectionStarted?.call();
    } catch (e) {
      print('[GeminiLiveAPI] WebSocket 연결 실패: $e');
      onErrorMessage?.call('WebSocket 연결 실패: $e');
    }
  }

  void sendInitialSetupMessages() {
    final sessionSetupMessage = {
      'setup': {
        'model': modelUri,
        'generation_config': {'response_modalities': responseModalities},
        'system_instruction': {
          'parts': [
            {'text': systemInstructions},
          ],
        },
      },
    };
    sendMessage(sessionSetupMessage);
  }

  void sendTextMessage(String text) {
    final textMessage = {
      'client_content': {
        'turns': [
          {
            'role': 'user',
            'parts': [
              {'text': text},
            ],
          },
        ],
        'turn_complete': true,
      },
    };
    print('[GeminiLiveAPI] 텍스트 메시지 전송: $text');
    sendMessage(textMessage);
  }

  void sendRealtimeInputMessage(String data, String mimeType) {
    final message = {
      'realtime_input': {
        'media_chunks': [
          {'mime_type': mimeType, 'data': data},
        ],
      },
    };
    sendMessage(message);
  }

  void sendAudioMessage(String base64PCM) {
    print('[GeminiLiveAPI] 오디오 메시지 전송');
    sendRealtimeInputMessage(base64PCM, 'audio/pcm');
  }

  void sendImageMessage(String base64Image, {String mimeType = 'image/jpeg'}) {
    print('[GeminiLiveAPI] 이미지 메시지 전송');
    sendRealtimeInputMessage(base64Image, mimeType);
  }
}

class GeminiLiveDemoController {
  // 상태
  AppStatus status = AppStatus.disconnected;

  // 오디오/비디오 매니저
  late PCMProcessor pcmProcessor;
  LiveAudioOutputManager? audioOutputManager;
  LiveAudioInputManager? audioInputManager;
  LiveVideoManager? videoManager;
  LiveScreenManager? screenManager;

  // 카메라/마이크 리스트
  List<CameraDescription> cameraList = [];
  CameraController? cameraController;
  String? selectedCameraId;
  String? selectedMicId;

  // 채팅 메시지
  List<String> messages = [];

  // 콜백
  void Function(String message)? onShowDialog;
  void Function()? onStatusChanged;
  void Function(String message)? onNewModelMessage;

  // WebSocket
  WebSocketChannel? _ws;
  StreamSubscription? _wsSub;
  String? _projectId;
  String? _systemInstructions;
  String? _responseModality;

  GeminiLiveDemoController();
  Future<void> init() async {
    // 카메라 목록 불러오기
    cameraList = await availableCameras();
    // print('카메라 목록:');
    for (final cam in cameraList) {
      // print('  - 33m[33m${cam.name}[0m (${cam.lensDirection})');
    }
    // 후면 카메라 우선 선택
    List<CameraDescription> cameras = await availableCameras();

    CameraDescription? backCam = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    // print('선택된 카메라: 32m[32m${backCam.name}[0m (${backCam.lensDirection})');
    selectedCameraId = backCam.name;
    cameraController = CameraController(backCam, ResolutionPreset.medium);
    try {
      await cameraController!.initialize();
      // print('카메라 초기화 성공');
    } catch (e) {
      // print('카메라 초기화 실패: $e');
      onShowDialog?.call("카메라 초기화 실패: $e");
      return;
    }
    videoManager = LiveVideoManager(cameraController!);
    // 오디오 매니저 초기화
    pcmProcessor = PCMProcessor();
    await pcmProcessor.initPlayer();
    audioOutputManager = LiveAudioOutputManager(pcmProcessor);
    audioInputManager = LiveAudioInputManager();
    audioInputManager!.onNewAudioRecordingChunk = (base64Audio) {
      sendAudioMessage(base64Audio);
    };
    // 화면공유 매니저 (PC/Web만)
    screenManager = LiveScreenManager();
    // 상태 콜백
    onStatusChanged?.call();
  }

  Future<void> dispose() async {
    // 오디오/비디오 매니저 해제
    await pcmProcessor.dispose();
    audioOutputManager = null;
    if (audioInputManager != null) {
      await audioInputManager!.disconnectMicrophone();
      audioInputManager = null;
    }
    if (videoManager != null) {
      await videoManager!.stopLiveStream();
      videoManager = null;
    }
    if (screenManager != null) {
      screenManager!.stopCapture();
      screenManager = null;
    }
    await cameraController?.dispose();
    cameraController = null;
  }

  void setAppStatus(AppStatus newStatus) {
    status = newStatus;
    onStatusChanged?.call();
  }

  // 연결 버튼 클릭
  Future<void> connect(
    String projectId,
    String systemInstructions,
    String responseModality,
  ) async {
    setAppStatus(AppStatus.connecting);
    _projectId = projectId;
    _systemInstructions = systemInstructions;
    _responseModality = responseModality;
    // WebSocket 연결
    try {
      final socketBaseUrl = dotenv.get('SOCKET_BASE_URL');
      print('[SOCKET] connect() 시도: wss://$socketBaseUrl');
      _ws = WebSocketChannel.connect(Uri.parse('wss://$socketBaseUrl'));
      _wsSub = _ws!.stream.listen(
        _onWsMessage,
        onError: (e) {
          print('[SOCKET] WebSocket 오류: $e');
          showDialogWithMessage('WebSocket 오류: $e');
          setAppStatus(AppStatus.disconnected);
        },
        onDone: () {
          print('[SOCKET] WebSocket 연결 종료');
          setAppStatus(AppStatus.disconnected);
        },
      );

      // // 연결 후 인증/설정 메시지 전송 (예시)
      // _ws!.sink.add(
      //   jsonEncode({
      //     'bearer_token': _accessToken,
      //     'service_url':
      //         'wss://us-central1-aiplatform.googleapis.com/ws/google.cloud.aiplatform.v1beta1.LlmBidiService/BidiGenerateContent',
      //   }),
      // );
      print('[SOCKET] SETUP 요청 전송');
      _ws!.sink.add(
        jsonEncode({
          'setup': {
            'model':
                'projects/$_projectId/locations/us-central1/publishers/google/models/gemini-2.0-flash-live-preview-04-09',
            'generation_config': {
              'response_modalities': [_responseModality ?? 'AUDIO'],
            },
            'system_instruction': {
              'parts': [
                {'text': _systemInstructions ?? ''},
              ],
            },
          },
        }),
      );
      print('[SOCKET] SETUP 요청 전송 완료');
      setAppStatus(AppStatus.connected);
      startAudioInput();
    } catch (e) {
      print('[SOCKET] WebSocket 연결 실패: $e');
      showDialogWithMessage('WebSocket 연결 실패: $e');
      setAppStatus(AppStatus.disconnected);
    }
  }

  // 연결 해제
  Future<void> disconnect() async {
    print('[SOCKET] disconnect() 호출');
    setAppStatus(AppStatus.disconnected);
    await stopAudioInput();
    await stopCameraCapture();
    stopScreenCapture();
    await _wsSub?.cancel();
    _ws?.sink.close();
    _ws = null;
    _wsSub = null;
    print('[SOCKET] disconnect() 완료');
  }

  // 오디오 입력 시작/중지
  Future<void> startAudioInput() async {
    await audioInputManager?.connectMicrophone();
  }

  Future<void> stopAudioInput() async {
    await audioInputManager?.disconnectMicrophone();
  }

  // WebSocket 메시지 수신 처리
  void _onWsMessage(dynamic rawMessage) {
    print('[SOCKET] 수신(raw): $rawMessage');
    // Gemini 응답 메시지 파싱 (예시)
    try {
      if (rawMessage is List<int>) {
        rawMessage = utf8.decode(rawMessage);
      }
      final data = jsonDecode(rawMessage);
      final parts = data['serverContent']?['modelTurn']?['parts'];
      if (data['setupComplete'] == true) {
        // 연결 완료
        print('[SOCKET] SETUP 응답 수신: 연결 완료');
        setAppStatus(AppStatus.connected);
      } else if (parts != null &&
          parts.isNotEmpty &&
          parts[0]['text'] != null) {
        print('[SOCKET] TEXT 응답 수신: ${parts[0]['text']}');
        onReceiveTextResponse(parts[0]['text']);
      } else if (parts != null &&
          parts.isNotEmpty &&
          parts[0]['inlineData'] != null) {
        print('[SOCKET] AUDIO 응답 수신 (inlineData)');
        onReceiveAudioResponse(parts[0]['inlineData']['data']);
      }
    } catch (e) {
      print('[SOCKET] 메시지 파싱 오류: $e');
      showDialogWithMessage('메시지 파싱 오류: $e');
    }
  }

  // 오디오 응답 수신 시 (Gemini 응답)
  void onReceiveAudioResponse(String base64Audio) {
    print('⭐️⭐️⭐️⭐️⭐️⭐️⭐️[GeminiLiveDemoController] 오디오 응답 수신');
    audioOutputManager?.playAudioChunk(base64Audio);
  }

  // 텍스트 응답 수신 시 (Gemini 응답)
  void onReceiveTextResponse(String text) {
    print('⭐️⭐️⭐️⭐️⭐️⭐️⭐️[GeminiLiveDemoController] 텍스트 응답 수신: $text');
    messages.add(">> $text");
    onNewModelMessage?.call(text);
  }

  // 유저 메시지 전송
  void sendUserMessage(String text) {
    print('[GeminiLiveDemoController] 유저 메시지 전송: $text');
    messages.add("User: $text");
    sendTextMessage(text);
  }

  // Gemini API로 텍스트 메시지 전송
  void sendTextMessage(String text) {
    if (_ws != null) {
      print('[SOCKET] 텍스트 요청 전송: $text');
      print('[GeminiLiveDemoController] Gemini API로 텍스트 메시지 전송: $text');
      _ws!.sink.add(
        jsonEncode({
          'client_content': {
            'turns': [
              {
                'role': 'user',
                'parts': [
                  {'text': text},
                ],
              },
            ],
            'turn_complete': true,
          },
        }),
      );
      print('[SOCKET] 텍스트 요청 전송 완료');
    }
  }

  // Gemini API로 오디오 메시지 전송
  void sendAudioMessage(String base64Audio) {
    if (_ws != null) {
      print('[SOCKET] 오디오 요청 전송');
      print('[GeminiLiveDemoController] Gemini API로 오디오 메시지 전송');
      _ws!.sink.add(
        jsonEncode({
          'realtime_input': {
            'media_chunks': [
              {'mime_type': 'audio/pcm', 'data': base64Audio},
            ],
          },
        }),
      );
      print('[SOCKET] 오디오 요청 전송 완료');
    }
  }

  // 이미지 메시지 전송 (카메라/화면공유)
  void sendImageMessage(String base64Image) {
    if (_ws != null) {
      print('[SOCKET] 이미지 요청 전송');
      print('[GeminiLiveDemoController] 이미지 메시지 전송');
      _ws!.sink.add(
        jsonEncode({
          'realtime_input': {
            'media_chunks': [
              {'mime_type': 'image/jpeg', 'data': base64Image},
            ],
          },
        }),
      );
      print('[SOCKET] 이미지 요청 전송 완료');
    }
  }

  // 카메라 프레임 콜백 등록
  void setOnNewVideoFrame(void Function(String base64Image) onNewFrame) {
    int lastSentMillis = 0;
    videoManager?.onNewFrame = (b64Image) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastSentMillis >= 5000) {
        print('[GeminiLiveDemoController] 카메라 프레임 콜백 발생 (5초 제한)');
        sendImageMessage(b64Image);
        onNewFrame(b64Image);
        lastSentMillis = now;
      } else {
        // print('[GeminiLiveDemoController] 이미지 전송 스킵 (5초 미만)');
      }
    };
  }

  // 화면공유 프레임 콜백 등록
  void setOnNewScreenFrame(void Function(String base64Image) onNewFrame) {
    screenManager?.onNewFrame = (b64Image) {
      print('[GeminiLiveDemoController] 화면공유 프레임 콜백 발생');
      sendImageMessage(b64Image);
      onNewFrame(b64Image);
    };
  }

  // 카메라/마이크 선택
  Future<void> selectCamera(String cameraId) async {
    final cam = cameraList.firstWhere(
      (c) => c.name == cameraId,
      orElse: () => cameraList.first,
    );
    selectedCameraId = cam.name;
    await cameraController?.dispose();
    cameraController = CameraController(cam, ResolutionPreset.medium);
    await cameraController!.initialize();
    videoManager = LiveVideoManager(cameraController!);
  }

  void selectMic(String micId) {
    selectedMicId = micId;
    // 실제 마이크 변경은 플랫폼별 추가 구현 필요
  }

  // 카메라/화면공유 시작/중지
  Future<void> startCameraCapture() async {
    screenManager?.stopCapture();
    await videoManager?.startLiveStream();
  }

  Future<void> stopCameraCapture() async {
    await videoManager?.stopLiveStream();
  }

  void startScreenCapture() {
    videoManager?.stopLiveStream();
    screenManager?.startCapture();
  }

  void stopScreenCapture() {
    screenManager?.stopCapture();
  }

  // 다이얼로그 표시
  void showDialogWithMessage(String message) {
    onShowDialog?.call(message);
  }
}
