// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:tigo/presentation/view/live_chatbot/script.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
//
// // 테스트용 페이지
// class LiveChatbotScreen extends StatefulWidget {
//   const LiveChatbotScreen({super.key});
//   @override
//   State<LiveChatbotScreen> createState() => _LiveChatbotScreenState();
// }
//
// class _LiveChatbotScreenState extends State<LiveChatbotScreen> {
//   // DemoController로 통합 관리
//   late GeminiLiveDemoController demoController;
//   AppStatus status = AppStatus.disconnected;
//   List<String> chatMessages = [];
//   TextEditingController textController = TextEditingController();
//   bool isMicOn = false;
//   bool isCameraOn = false;
//   bool isConnected = false;
//   String lastGeminiText = "";
//   String lastError = "";
//   CameraController? get cameraController => demoController.cameraController;
//
//   @override
//   void initState() {
//     super.initState();
//     _initAll();
//     // 카메라 프레임 콜백 등록 (print만)
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       demoController.setOnNewVideoFrame((b64Image) {
//         // print('카메라 프레임 콜백(Flutter): ${b64Image.substring(0, 40)}...');
//         // 필요시 setState로 프리뷰 이미지로 활용 가능
//       });
//     });
//   }
//
//   Future<void> _initAll() async {
//     demoController = GeminiLiveDemoController();
//     demoController.onStatusChanged = () {
//       setState(() {
//         status = demoController.status;
//         isConnected = status == AppStatus.connected;
//       });
//     };
//
//     demoController.onNewModelMessage = (msg) {
//       setState(() {
//         chatMessages.add(">> " + msg);
//         lastGeminiText = msg;
//       });
//     };
//     demoController.onShowDialog = (msg) {
//       setState(() {
//         lastError = msg;
//       });
//     };
//     await demoController.init(); // PCMProcessor 생성/호출됨
//     demoController.setOnNewVideoFrame((base64Image) {
//       // print("🔥 카메라 프레임 전송됨 (길이: ${base64Image.length})");
//     });
//     setState(() {});
//   }
//
//   void _connect() async {
//     setState(() {
//       status = AppStatus.connecting;
//       lastError = "";
//     });
//     final projectId = dotenv.get('PROJECT_ID');
//     if (projectId == null || projectId.isEmpty) {
//       setState(() {
//         lastError = "dotenv에 PROJECT_ID가 설정되어 있지 않습니다.";
//         status = AppStatus.disconnected;
//       });
//       return;
//     }
//     await demoController.connect(projectId, "", "AUDIO");
//   }
//
//   void _disconnect() async {
//     await demoController.disconnect();
//     setState(() {
//       isConnected = false;
//       status = AppStatus.disconnected;
//       isCameraOn = false;
//     });
//   }
//
//   void _sendText() {
//     final text = textController.text.trim();
//     if (text.isNotEmpty && isConnected) {
//       demoController.sendUserMessage(text);
//       setState(() {
//         chatMessages.add("User: $text");
//         textController.clear();
//       });
//     }
//   }
//
//   void _toggleMic() async {
//     if (isMicOn) {
//       await demoController.stopAudioInput();
//     } else {
//       await demoController.startAudioInput();
//     }
//     setState(() {
//       isMicOn = !isMicOn;
//     });
//   }
//
//   void _toggleCamera() async {
//     if (isCameraOn) {
//       await demoController.stopCameraCapture();
//       demoController.setOnNewVideoFrame((_) {});
//     } else {
//       await demoController.startCameraCapture();
//       demoController.setOnNewVideoFrame((b64Image) {
//         setState(() {});
//       });
//     }
//     setState(() {
//       isCameraOn = !isCameraOn;
//     });
//   }
//
//   @override
//   void dispose() {
//     cameraController?.dispose();
//     demoController.audioInputManager.disconnectMicrophone();
//     demoController.disconnect();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final double cameraHeight = MediaQuery.of(context).size.height * 2 / 3;
//     return Scaffold(
//       appBar: AppBar(title: Text("Gemini Live Test")),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Wrap(children: [Text("Status: $status")]),
//               if (lastError.isNotEmpty)
//                 Text("Error: $lastError", style: TextStyle(color: Colors.red)),
//               SizedBox(height: 8),
//               Row(
//                 children: [
//                   ElevatedButton(
//                     onPressed: isConnected ? null : _connect,
//                     child: Text("Connect"),
//                   ),
//                   SizedBox(width: 8),
//                   ElevatedButton(
//                     onPressed: isConnected ? _disconnect : null,
//                     child: Text("Disconnect"),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 8),
//               if (isCameraOn &&
//                   cameraController != null &&
//                   cameraController!.value.isInitialized)
//                 SizedBox(
//                   width: double.infinity,
//                   height: cameraHeight,
//                   child: CameraPreview(cameraController!),
//                 )
//               else
//                 Container(
//                   height: cameraHeight,
//                   color: Colors.black12,
//                   child: Center(
//                     child: Text("카메라 꺼짐", style: TextStyle(fontSize: 24)),
//                   ),
//                 ),
//               SizedBox(height: 8),
//               SizedBox(
//                 height: 200,
//                 child: ListView.builder(
//                   itemCount: chatMessages.length,
//
//                   itemBuilder: (context, idx) => Text(chatMessages[idx]),
//                 ),
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   IconButton(
//                     icon: Icon(
//                       isCameraOn ? Icons.videocam : Icons.videocam_off,
//                     ),
//                     iconSize: 48,
//                     onPressed: _toggleCamera,
//                   ),
//                   SizedBox(width: 32),
//                   IconButton(
//                     icon: Icon(isMicOn ? Icons.mic : Icons.mic_off),
//                     iconSize: 48,
//                     onPressed: _toggleMic,
//                   ),
//                 ],
//               ),
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: textController,
//                       decoration: InputDecoration(
//                         hintText: "Type a message...",
//                       ),
//                       onSubmitted: (_) => _sendText(),
//                     ),
//                   ),
//                   IconButton(icon: Icon(Icons.send), onPressed: _sendText),
//                 ],
//               ),
//               if (lastGeminiText.isNotEmpty)
//                 Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Text(
//                     "Gemini: $lastGeminiText",
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
