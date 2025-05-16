import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:tigo/app/config/app_routes.dart';
import 'package:tigo/app/config/color_system.dart';
import 'package:tigo/core/constant/assets.dart';
import 'package:tigo/presentation/view_model/home/home_view_model.dart';
import 'dart:math';
import 'package:intl/intl.dart';

class QuickPlanTestScreen extends StatefulWidget {
  final String? planId;
  final String? userId;
  final List<Map<String, dynamic>>? planList;

  const QuickPlanTestScreen({
    super.key,
    this.planId,
    this.userId,
    this.planList,
  });
  @override
  State<QuickPlanTestScreen> createState() => _QuickPlanTestScreenState();
}

class _QuickPlanTestScreenState extends State<QuickPlanTestScreen> {
  late List<String> dates;
  late String selectedDate;
  List<Map<String, dynamic>>? _planList;
  bool _isLoading = false;
  String? _error;
  String? _userId;

  @override
  void initState() {
    super.initState();

    // arguments에서 값 추출
    final args = Get.arguments as Map<String, dynamic>?;
    _planList = args?['planList']?.cast<Map<String, dynamic>>();
    _userId = args?['userId'];

    if (_planList != null) {
      _setPlanList(_planList!);
    } else if (widget.planId != null) {
      _fetchPlanById(widget.planId!);
    } else {
      _planList = [];
      dates = [];
      selectedDate = '';
    }
  }

  Future<void> _fetchPlanById(String planId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // userId를 HomeViewModel에서 가져옴
      final userId = _userId ?? Get.find<HomeViewModel>().userBriefState.id;
      print('userId: $userId');
      print('planId: $planId');
      final doc =
          await FirebaseFirestore.instance
              .collection('tripPlans')
              .doc(userId)
              .collection('plans')
              .doc(planId)
              .get();

      print('doc: ${jsonEncode(doc.data())}');
      if (!doc.exists) {
        setState(() {
          _planList = [];
          _isLoading = false;
          _error = '플랜 정보를 찾을 수 없습니다.';
        });
        return;
      }
      final data = doc.data();

      final schedules = data?['schedules'] as List<dynamic>? ?? [];
      final planList =
          schedules.map((e) => Map<String, dynamic>.from(e)).toList();
      _setPlanList(planList);
      print('planList: $planList');
    } catch (e) {
      setState(() {
        _planList = [];
        _isLoading = false;
        _error = '플랜 정보를 불러오는 중 오류가 발생했습니다.';
      });
    }
  }

  void _setPlanList(List<Map<String, dynamic>> planList) {
    _planList = planList;
    dates =
        planList
            .map((e) => e['date'] as String? ?? '')
            .where((d) => d.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    selectedDate = dates.isNotEmpty ? dates.first : '';
    print('dates: $dates');
    print('selectedDate: $selectedDate');
    setState(() {
      _isLoading = false;
      _error = null;
    });
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 6371; // 지구 반지름 (km)
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c; // km 단위
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(body: Center(child: Text(_error!)));
    }
    final list = _planList ?? [];
    final spots = list.where((e) => e['date'] == selectedDate).toList();
    print('spots: $spots');
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // 뒤로가기 시 ROOT로 이동
            Get.offAllNamed(AppRoutes.ROOT);
          },
        ),
        title: const Text('여행 플랜 결과'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          // 메인 컨텐츠
          Column(
            children: [
              // 상단 지도
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.3,
                child:
                    spots.isEmpty
                        ? const Center(child: Text('일정이 없습니다.'))
                        : GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              (spots.first['latitude'] is num
                                      ? spots.first['latitude']
                                      : double.tryParse(
                                        '${spots.first['latitude']}',
                                      )) ??
                                  37.5665,
                              (spots.first['longitude'] is num
                                      ? spots.first['longitude']
                                      : double.tryParse(
                                        '${spots.first['longitude']}',
                                      )) ??
                                  126.9780,
                            ),
                            zoom: 13,
                          ),
                          markers:
                              spots
                                  .where(
                                    (s) =>
                                        s['latitude'] != null &&
                                        s['longitude'] != null,
                                  )
                                  .map(
                                    (s) => Marker(
                                      markerId: MarkerId(s['place'] ?? ''),
                                      position: LatLng(
                                        (s['latitude'] is num
                                                ? s['latitude']
                                                : double.tryParse(
                                                  '${s['latitude']}',
                                                )) ??
                                            37.5665,
                                        (s['longitude'] is num
                                                ? s['longitude']
                                                : double.tryParse(
                                                  '${s['longitude']}',
                                                )) ??
                                            126.9780,
                                      ),
                                      infoWindow: InfoWindow(
                                        title: s['place'] ?? '',
                                      ),
                                    ),
                                  )
                                  .toSet(),
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                        ),
              ),

              // 날짜 선택 탭
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children:
                    dates.map((date) {
                      String displayDate;
                      try {
                        final parsed = DateTime.parse(date);
                        displayDate = DateFormat(
                          'MMM dd',
                          'en_US',
                        ).format(parsed);
                      } catch (_) {
                        displayDate = date;
                      }
                      final bool isSelected = selectedDate == date;
                      return Padding(
                        padding: const EdgeInsets.all(8), // 버튼 사이 간격
                        child: GestureDetector(
                          onTap: () => setState(() => selectedDate = date),
                          child: Container(
                            width: 80, // 모든 버튼 동일한 width
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? const Color(0xFF454545)
                                      : const Color(0xFFEEEFF8),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              displayDate,
                              style: TextStyle(
                                color:
                                    isSelected
                                        ? Colors.white
                                        : const Color(0xFF454545),
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
              // 일정 리스트
              Expanded(
                child:
                    spots.isEmpty
                        ? const Center(child: Text('해당 날짜에 일정이 없습니다.'))
                        : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: spots.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, idx) {
                            final spot = spots[idx];
                            final prevSpot = idx > 0 ? spots[idx - 1] : null;
                            double? distance;
                            if (prevSpot != null) {
                              distance = calculateDistance(
                                prevSpot['latitude'],
                                prevSpot['longitude'],
                                spot['latitude'],
                                spot['longitude'],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 1. 타임라인(번호, 거리, 점선) - 고정 width
                                SizedBox(
                                  width: 48, // 원하는 만큼
                                  child: Column(
                                    children: [
                                      // 번호 원
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Colors.grey[800],
                                        child: Text(
                                          '${idx + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      // 거리/아이콘/텍스트
                                      if (idx > 0) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                            ),
                                          ),
                                          child: Center(
                                            child: SvgPicture.asset(
                                              Assets.distanceIcon,
                                              width: 16,
                                              height: 16,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        if (distance != null)
                                          Text(
                                            '${distance.toStringAsFixed(1)} km',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                      // 아래쪽 점선
                                      if (idx < spots.length - 1)
                                        Container(
                                          height: 120, // 원하는 점선 길이
                                          width: 2,
                                          child: CustomPaint(
                                            painter: DashedLinePainter(),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12), // 타임라인과 본문 사이 간격
                                // 2. 본문(썸네일, 이름, 카테고리, 상세정보)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // 썸네일, 이름, 카테고리 Row
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: 56,
                                            height: 56,
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child:
                                                  (spot['thumbnail'] != null &&
                                                          (spot['thumbnail']
                                                                  as String)
                                                              .isNotEmpty)
                                                      ? Image.network(
                                                        spot['thumbnail'],
                                                        fit: BoxFit.cover,
                                                      )
                                                      : Container(
                                                        color: Colors.grey[300],
                                                        child: const Icon(
                                                          Icons.broken_image,
                                                          color: Colors.grey,
                                                          size: 32,
                                                        ),
                                                      ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  spot['place'] ?? '',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 17,
                                                  ),
                                                ),
                                                if (spot['category'] != null)
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.place,
                                                        size: 16,
                                                        color: Colors.grey,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        spot['category'],
                                                        style: const TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // 상세정보(회색 박스)
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF4F5F7),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (spot['info'] != null)
                                              Text(
                                                spot['info'],
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF6B7280),
                                                ),
                                              ),
                                            if (spot['openTime'] != null &&
                                                spot['closeTime'] != null)
                                              Text(
                                                '영업: ${spot['openTime']} ~ ${spot['closeTime']}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF6B7280),
                                                ),
                                              ),
                                            if (spot['fee'] != null)
                                              Text(
                                                '입장료: ${spot['fee']}원',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF6B7280),
                                                ),
                                              ),
                                            if (spot['address'] != null)
                                              Text(
                                                spot['address'],
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF6B7280),
                                                ),
                                              ),
                                            if (spot['phone'] != null)
                                              Text(
                                                '전화: ${spot['phone']}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF6B7280),
                                                ),
                                              ),
                                            if (spot['website'] != null &&
                                                spot['website'] !=
                                                    "undefined" &&
                                                (spot['website'] as String)
                                                    .isNotEmpty)
                                              Text(
                                                '웹사이트: ${spot['website']}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF6B7280),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
              ),
            ],
          ),
          // Ask Tigo 버튼 (하단 우측 floating)
          Positioned(
            right: 24,
            bottom: 48,
            child: GestureDetector(
              onTap: () {
                Get.toNamed(AppRoutes.TIGO_PLAN_CHAT);
              },
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(Assets.askTigoImage, width: 48, height: 48),
                    const SizedBox(height: 6),
                    const Text(
                      'Ask Tigo',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 4, dashSpace = 4, startY = 0;
    final paint =
        Paint()
          ..color = Colors.grey[300]!
          ..strokeWidth = 2;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
