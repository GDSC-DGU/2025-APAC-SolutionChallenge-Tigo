import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PlanSpot {
  final String? date;
  final String? time;
  final String? place;
  final String? category;
  final String? openTime;
  final String? closeTime;
  final String? info;
  final int? fee;
  final double? latitude;
  final double? longitude;
  final String? thumbnail;
  final String? address;
  final String? phone;
  final String? website;

  PlanSpot({
    this.date,
    this.time,
    this.place,
    this.category,
    this.openTime,
    this.closeTime,
    this.info,
    this.fee,
    this.latitude,
    this.longitude,
    this.thumbnail,
    this.address,
    this.phone,
    this.website,
  });

  factory PlanSpot.fromJson(Map<String, dynamic> json) => PlanSpot(
    date: json['date'],
    time: json['time'],
    place: json['place'],
    category: json['category'],
    openTime: json['openTime'],
    closeTime: json['closeTime'],
    info: json['info'],
    fee: json['fee'],
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    thumbnail: json['thumbnail'],
    address: json['address'],
    phone: json['phone'],
    website: json['website'],
  );
}

class TigoPlanCompletedViewModel extends GetxController {
  final String planId;
  final spots = <PlanSpot>[].obs;
  final selectedDate = RxnString();

  String get projectId => dotenv.get('PROJECT_ID');
  String get GOOGLE_MAP_KEY => dotenv.get('GOOGLE_MAP_KEY');

  TigoPlanCompletedViewModel({required this.planId});

  @override
  void onInit() {
    super.onInit();
    fetchPlan();
  }

  Future<void> fetchPlan() async {
    // 실제 API 주소/파라미터에 맞게 수정
    final url = Uri.parse(
      'http://127.0.0.1:5001/$projectId/us-central1/getPlan?planId=$planId',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data =
          jsonDecode(response.body)['result'] is String
              ? jsonDecode(jsonDecode(response.body)['result'])
              : jsonDecode(response.body)['result'];
      spots.assignAll(data.map((e) => PlanSpot.fromJson(e)).toList());
      if (spots.isNotEmpty) {
        selectedDate.value = spots.first.date;
      }
    }
  }

  List<String> get availableDates =>
      spots.map((e) => e.date).whereType<String>().toSet().toList();

  List<PlanSpot> get spotsForSelectedDate =>
      spots.where((e) => e.date == selectedDate.value).toList();
}
