import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tigo/app/config/index.dart';
import 'package:tigo/presentation/view/live_chatbot/script.dart';

enum FullScreenType { none, map, camera }

class LiveChatbotScreen extends StatefulWidget {
  const LiveChatbotScreen({super.key});
  @override
  State<LiveChatbotScreen> createState() => _LiveChatbotScreenState();
}

class _LiveChatbotScreenState extends State<LiveChatbotScreen> {
  late GeminiLiveDemoController demoController;
  AppStatus status = AppStatus.disconnected;
  bool isConnected = false;
  bool isCameraOn = false;
  String lastError = "";
  CameraController? get cameraController => demoController.cameraController;
  FullScreenType _fullScreen = FullScreenType.none;

  @override
  void initState() {
    super.initState();
    _initAll();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      demoController.setOnNewVideoFrame((b64Image) {
        // 필요시 프레임 처리
      });
    });
  }

  Future<void> _initAll() async {
    demoController = GeminiLiveDemoController();
    demoController.onStatusChanged = () {
      setState(() {
        status = demoController.status;
        isConnected = status == AppStatus.connected;
      });
    };
    demoController.onShowDialog = (msg) {
      setState(() {
        lastError = msg;
      });
    };
    await demoController.init();
    _connect(); // 자동 연결
  }

  Future<void> _connect() async {
    setState(() {
      status = AppStatus.connecting;
      lastError = "";
    });
    final projectId = dotenv.get('PROJECT_ID');
    if (projectId == null || projectId.isEmpty) {
      setState(() {
        lastError = "dotenv에 PROJECT_ID가 없습니다.";
        status = AppStatus.disconnected;
      });
      return;
    }
    await demoController.connect(projectId, "", "AUDIO");
  }

  Future<void> _disconnect() async {
    await demoController.disconnect();
    setState(() {
      isConnected = false;
      status = AppStatus.disconnected;
      isCameraOn = false;
    });
  }

  @override
  void dispose() {
    cameraController?.dispose();
    demoController.audioInputManager?.disconnectMicrophone();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapView = Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(37.5665, 126.9780), // 서울 시청 위치
            zoom: 14,
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: _FullScreenButton(
            onTap: () {
              setState(() {
                _fullScreen =
                    _fullScreen == FullScreenType.map
                        ? FullScreenType.none
                        : FullScreenType.map;
              });
            },
          ),
        ),
      ],
    );

    final cameraView = Stack(
      children: [
        if (cameraController != null && cameraController!.value.isInitialized)
          CameraPreview(cameraController!)
        else
          Container(color: Colors.black),
        Positioned(
          bottom: 16,
          right: 16,
          child: _FullScreenButton(
            onTap: () {
              setState(() {
                _fullScreen =
                    _fullScreen == FullScreenType.camera
                        ? FullScreenType.none
                        : FullScreenType.camera;
              });
            },
          ),
        ),
      ],
    );

    Widget body;
    if (_fullScreen == FullScreenType.map) {
      body = mapView;
    } else if (_fullScreen == FullScreenType.camera) {
      body = cameraView;
    } else {
      body = Column(
        children: [Expanded(child: mapView), Expanded(child: cameraView)],
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.offAllNamed(AppRoutes.ROOT),
        ),
        title: const Text('Live Gemini View'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: body,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: isConnected ? null : _connect,
            child: Text("Connect"),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: isConnected ? _disconnect : null,
            child: Text("Disconnect"),
          ),
        ],
      ),
    );
  }
}

class _FullScreenButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FullScreenButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(Icons.open_in_full, size: 28, color: Colors.blueAccent),
        ),
      ),
    );
  }
}
