import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:tigo/presentation/view/live_chatbot/PCMProcessor.dart';
// import 'pcm_processor.dart'; // PCMProcessor를 별도 파일에서 import 하세요

// 오디오 재생 담당 (PCMProcessor 연동)
// PCM 오디오 청크(Base64 인코딩된)를 받아서 AudioWorklet을 통해 실시간 재생
class LiveAudioOutputManager {
  final PCMProcessor pcmProcessor;
  Completer<void> _playbackReady = Completer<void>();
  int _chunkCounter = 0;
  bool _isInitialized = false;

  LiveAudioOutputManager(this.pcmProcessor) {
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.delayed(Duration(milliseconds: 500));
    _isInitialized = true;
    if (!_playbackReady.isCompleted) {
      _playbackReady.complete();
    }
  }

  // Improved processing with chunk tracking and adaptive handling
  void playAudioChunk(String base64AudioChunk) async {
    if (!_isInitialized) {
      await _playbackReady.future;
    }

    try {
      _chunkCounter++;

      // Decode base64
      Uint8List pcm16Bytes = base64Decode(base64AudioChunk);

      // Convert more efficiently
      Float32List float32 = _pcm16leToFloat32(pcm16Bytes);

      // 4096 샘플씩 쪼개서 PCMProcessor에 전달
      // int chunkSize = 4096;
      // for (int i = 0; i < float32.length; i += chunkSize) {
      //   int end =
      //       (i + chunkSize < float32.length) ? i + chunkSize : float32.length;
      //   pcmProcessor.addPCMData(float32.sublist(i, end));
      // }

      int chunkSize = 4096;
      for (int i = 0; i < float32.length; i += chunkSize) {
        int end =
            (i + chunkSize < float32.length) ? i + chunkSize : float32.length;
        pcmProcessor.addPCMData(float32.sublist(i, end));
      }

      // Log occasional status for debugging
      if (_chunkCounter % 10 == 0) {
        print('Processed $_chunkCounter audio chunks');
      }
    } catch (e) {
      print('Error in playAudioChunk: $e');
    }
  }

  // Keep the original method for compatibility
  Float32List _pcm16leToFloat32(Uint8List pcm16Bytes) {
    final int16 = Int16List.view(pcm16Bytes.buffer);
    final float32 = Float32List(int16.length);
    for (int i = 0; i < int16.length; i++) {
      const normFactor = 1.0 / 32767.0;
      float32[i] = int16[i] * normFactor;
    }
    print('Float32 min: ${float32.reduce((a, b) => a < b ? a : b)}');
    print('Float32 max: ${float32.reduce((a, b) => a > b ? a : b)}');
    return float32;
  }
}

// 오디오 입력 담당 (마이크 입력 → 1초 단위로 PCM16LE → base64)
class LiveAudioInputManager {
  FlutterSoundRecorder? _recorder;
  StreamController<Uint8List>? _micStreamController;
  bool _isRecording = false;
  Function(String base64Audio)? onNewAudioRecordingChunk;
  Timer? _timer;

  // Use a Queue instead of a List for better performance
  final Queue<int> _pcmBuffer = Queue<int>();

  // Smaller chunks sent more frequently
  static const int SAMPLES_PER_CHUNK = 2048;

  Future<void> connectMicrophone() async {
    try {
      _micStreamController = StreamController<Uint8List>();

      // More efficient stream handling
      _micStreamController!.stream.listen((buffer) {
        _pcmBuffer.addAll(buffer);
        _processBufferIfNeeded();
      });

      _recorder = FlutterSoundRecorder();
      await _recorder!.openRecorder();

      await _recorder!.startRecorder(
        toStream: _micStreamController!.sink,
        codec: Codec.pcm16,
        sampleRate: 16000,
        numChannels: 1,
      );
      // Backup timer in case stream doesn't deliver consistently
      _timer = Timer.periodic(Duration(milliseconds: 100), (_) {
        _processBufferIfNeeded();
      });

      _isRecording = true;
      print('Microphone connected successfully');
    } catch (e) {
      print('Error connecting microphone: $e');
      await disconnectMicrophone();
      // Auto-retry with a delay
      Future.delayed(Duration(seconds: 1), connectMicrophone);
    }
  }

  void _processBufferIfNeeded() {
    // Process when we have enough data, but don't wait for exact amount
    if (_isRecording && _pcmBuffer.length >= SAMPLES_PER_CHUNK) {
      final buffer = Uint8List(SAMPLES_PER_CHUNK);

      // Copy only what we need, leave the rest for next chunk
      for (int i = 0; i < SAMPLES_PER_CHUNK; i++) {
        if (_pcmBuffer.isNotEmpty) {
          buffer[i] = _pcmBuffer.removeFirst();
        } else {
          break;
        }
      }

      // Convert and send
      String base64Audio = base64Encode(buffer);
      if (onNewAudioRecordingChunk != null) {
        onNewAudioRecordingChunk!(base64Audio);
      }
    }
  }

  Future<void> disconnectMicrophone() async {
    if (_isRecording) {
      _isRecording = false;
      _timer?.cancel();
      _timer = null;

      try {
        await _recorder?.stopRecorder();
        await _recorder?.closeRecorder();
      } catch (e) {
        print('Error stopping recorder: $e');
      }

      await _micStreamController?.close();
      _recorder = null;
      _micStreamController = null;
      _pcmBuffer.clear();
    }
  }
}

// 카메라 캡처 담당 (1초 단위로 프레임 캡처 → base64 JPEG)
class LiveVideoManager {
  final CameraController cameraController;
  Function(String base64Image)? onNewFrame;
  bool _isStreaming = false;
  Timer? _intervalTimer;
  CameraImage? _latestImage;

  LiveVideoManager(this.cameraController);

  // 실시간 스트림 시작 (1초마다 프레임 추출)
  Future<void> startLiveStream() async {
    if (_isStreaming) return;
    _isStreaming = true;

    // 1. 카메라 프레임 스트림 시작
    await cameraController.startImageStream((CameraImage image) {
      _latestImage = image; // 항상 최신 프레임만 저장
    });

  // 2. 1초마다 최신 프레임을 캡처해서 콜백
    _intervalTimer = Timer.periodic(Duration(seconds: 1), (_) async {
      if (_latestImage != null && onNewFrame != null) {
        String? base64Image = await _convertCameraImageToBase64Jpeg(
          _latestImage!,
        );
        if (base64Image != null) {
          onNewFrame!(base64Image);
        }
      }
    });
  }

  // 스트림 중지
  Future<void> stopLiveStream() async {
    if (!_isStreaming) return;
    await cameraController.stopImageStream();
    _isStreaming = false;
    _intervalTimer?.cancel();
    _intervalTimer = null;
    _latestImage = null;
  }

  // YUV420 CameraImage → JPEG(base64) 변환
  Future<String?> _convertCameraImageToBase64Jpeg(CameraImage image) async {
    try {
      final img.Image rgbImage = convertYUV420ToImage(image); // 안전 변환 함수 사용
      final jpegBytes = img.encodeJpg(rgbImage, quality: 80);
      return base64Encode(jpegBytes);
    } catch (e) {
      print('카메라 프레임 변환 오류: $e');
      return null;
    }
  }
}

// 화면공유는 Optional
// 화면 공유 캡처 담당 (PC/Web에서만 동작, 1초 단위로 프레임 캡처 → base64 JPEG)
class LiveScreenManager {
  Timer? _frameTimer;
  Function(String base64Image)? onNewFrame;
  bool _isStreaming = false;

  void startCapture({Duration interval = const Duration(seconds: 1)}) {
    // 실제 구현은 플랫폼별로 다름 (Web/PC에서만 가능)
    // 예: desktop_capture, window_manager 등 패키지 활용
    // 아래는 예시용 구조
    if (_isStreaming) return;
    _isStreaming = true;
    _frameTimer = Timer.periodic(interval, (_) async {
      await _captureAndSendFrame();
    });
  }

  void stopCapture() {
    _frameTimer?.cancel();
    _isStreaming = false;
  }

  Future<void> _captureAndSendFrame() async {
    // 실제 구현 필요: 플랫폼별 화면 캡처 후 base64 인코딩
    // 예시: Web/PC에서만 동작, 모바일은 미지원
    // String base64Image = ...;
    // if (onNewFrame != null) {
    //   onNewFrame!(base64Image);
    // }
  }
}

img.Image convertYUV420ToImage(CameraImage image) {
  final int width = image.width;
  final int height = image.height;
  final img.Image imgImage = img.Image(width: width, height: height);

  if (image.format.group == ImageFormatGroup.yuv420) {
    final Uint8List y = image.planes[0].bytes;
    final Uint8List u = image.planes[1].bytes;
    final Uint8List v = image.planes[2].bytes;

    int uvRowStride = image.planes[1].bytesPerRow;
    int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

    for (int h = 0; h < height; h++) {
      for (int w = 0; w < width; w++) {
        int uvIndex = uvPixelStride * (w ~/ 2) + uvRowStride * (h ~/ 2);
        int yIndex = h * width + w;
        int yValue = y.length > yIndex ? y[yIndex] : 0;
        int uValue = u.length > uvIndex ? u[uvIndex] : 128;
        int vValue = v.length > uvIndex ? v[uvIndex] : 128;

        int r = (yValue + (1.370705 * (vValue - 128))).round();
        int g =
            (yValue - (0.337633 * (uValue - 128)) - (0.698001 * (vValue - 128)))
                .round();
        int b = (yValue + (1.732446 * (uValue - 128))).round();

        imgImage.setPixelRgba(
          w,
          h,
          r.clamp(0, 255),
          g.clamp(0, 255),
          b.clamp(0, 255),
          255,
        );
      }
    }
    return imgImage;
  } else if (image.format.group == ImageFormatGroup.bgra8888) {
    // iOS에서 주로 발생, BGRA8888은 바로 변환 가능
    final plane = image.planes[0];
    return img.Image.fromBytes(
      width: width,
      height: height,
      bytes: plane.bytes.buffer,
      order: img.ChannelOrder.bgra,
    );
  } else {
    throw Exception('지원하지 않는 카메라 포맷: ${image.format.group}');
  }
}
