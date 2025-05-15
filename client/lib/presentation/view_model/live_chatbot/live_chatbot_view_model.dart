// import 'package:get/get.dart';
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:tigo/presentation/view/live_chatbot/script.dart';
//
// class LiveChatbotViewModel extends GetxController {
//   // 상태
//   var status = AppStatus.disconnected.obs;
//   var chatMessages = <String>[].obs;
//   var isMicOn = false.obs;
//   var isCameraOn = false.obs;
//   var isConnected = false.obs;
//   var lastGeminiText = "".obs;
//   var lastError = "".obs;
//
//   TextEditingController textController = TextEditingController();
//
//   late GeminiLiveDemoController demoController;
//   CameraController? get cameraController => demoController.cameraController;
//
//   @override
//   void onInit() {
//     super.onInit();
//     _initAll();
//   }
//
//   Future<void> _initAll() async {
//     demoController = GeminiLiveDemoController();
//     demoController.onStatusChanged = () {
//       status.value = demoController.status;
//       isConnected.value = status.value == AppStatus.connected;
//     };
//     demoController.onNewModelMessage = (msg) {
//       chatMessages.add(">> $msg");
//       lastGeminiText.value = msg;
//     };
//     demoController.onShowDialog = (msg) {
//       lastError.value = msg;
//     };
//     await demoController.init();
//     demoController.setOnNewVideoFrame((base64Image) {
//       // print("🔥 카메라 프레임 전송됨 (길이: ${base64Image.length})");
//     });
//   }
//
//   Future<void> connect() async {
//     status.value = AppStatus.connecting;
//     lastError.value = "";
//     await demoController.connect(
//       "actual-practice-app",
//       "",
//       "AUDIO",
//     );
//   }
//
//   Future<void> disconnect() async {
//     await demoController.disconnect();
//     isConnected.value = false;
//     status.value = AppStatus.disconnected;
//     isCameraOn.value = false;
//   }
//
//   void sendText() {
//     final text = textController.text.trim();
//     if (text.isNotEmpty && isConnected.value) {
//       demoController.sendUserMessage(text);
//       chatMessages.add("User: $text");
//       textController.clear();
//     }
//   }
//
//   Future<void> toggleMic() async {
//     if (isMicOn.value) {
//       await demoController.stopAudioInput();
//     } else {
//       await demoController.startAudioInput();
//     }
//     isMicOn.value = !isMicOn.value;
//   }
//
//   Future<void> toggleCamera() async {
//     if (isCameraOn.value) {
//       await demoController.stopCameraCapture();
//     } else {
//       await demoController.startCameraCapture();
//     }
//     isCameraOn.value = !isCameraOn.value;
//   }
//
//   @override
//   void onClose() {
//     cameraController?.dispose();
//     demoController.audioInputManager.disconnectMicrophone();
//     super.onClose();
//   }
// }