class ChatMessage {
  final String text;
  final bool isUser;
  final bool isTimetable;
  final String? videoUrl;
  final String? videoTitle;
  final String? videoSummary;
  final String? thumbnailUrl;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isTimetable = false,
    this.videoUrl,
    this.videoTitle,
    this.videoSummary,
    this.thumbnailUrl,
  });

  // 예: 서버 저장 또는 불러오기를 위해 toJson/fromJson 메서드 정의 가능
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] ?? '',
      isUser: json['isUser'] ?? false,
      isTimetable: json['isTimetable'] ?? false,
      videoUrl: json['videoUrl'],
      videoTitle: json['videoTitle'],
      videoSummary: json['videoSummary'],
      thumbnailUrl: json['thumbnailUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'isTimetable': isTimetable,
      'videoUrl': videoUrl,
      'videoTitle': videoTitle,
      'videoSummary': videoSummary,
      'thumbnailUrl': thumbnailUrl,
    };
  }
}
