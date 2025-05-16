import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tigo/app/config/index.dart';
import 'package:tigo/presentation/view/live_chatbot/script.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initAll();
    _getCurrentLocation(); // 현재 위치 가져오기
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

  void _showSnackBar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.black.withOpacity(0.7),
      colorText: Colors.white,
    );
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
    await demoController.startCameraCapture();
    _showSnackBar(
      'Connect With TigoLiveChatbot',
      'You can use Multimodal Live Streaming Tigo!',
    );
  }

  Future<void> _disconnect() async {
    await demoController.disconnect();
    await demoController.stopCameraCapture();
    setState(() {
      isConnected = false;
      status = AppStatus.disconnected;
      isCameraOn = false;
    });
    _showSnackBar(
      'DisConnect With TigoLiveChatbot',
      'You can not use Multimodal Live Streaming Tigo!',
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _markers.add(
          Marker(
            markerId: const MarkerId('currentLocation'),
            position: _currentPosition!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
            infoWindow: const InfoWindow(title: '현재 위치'),
          ),
        );
      });

      // 지도 컨트롤러가 있다면 카메라 이동
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentPosition!, zoom: 15),
        ),
      );
    } catch (e) {
      print('위치를 가져오는데 실패했습니다: $e');
    }
  }

  @override
  void dispose() {
    cameraController?.dispose();
    demoController.audioInputManager?.disconnectMicrophone();
    demoController.stopCameraCapture(); // 카메라 프레임 스트림 중지
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapView = Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(37.5665, 126.9780),
            zoom: 14,
          ),
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
          markers: _markers,
          myLocationEnabled: true, // 내 위치 버튼 활성화
          myLocationButtonEnabled: true, // 내 위치 버튼 표시
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
        children: [
          Expanded(child: mapView),
          Expanded(child: Container(width: double.infinity, child: cameraView)),
        ],
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
      floatingActionButton: Center(
        child: ElevatedButton(
          onPressed: isConnected ? _disconnect : _connect,
          child: Text(
            isConnected ? "UnConnect With Tigo" : "Connect With Tigo",
          ),
        ),
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
