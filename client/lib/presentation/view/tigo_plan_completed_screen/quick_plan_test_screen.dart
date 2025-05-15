import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:tigo/app/config/app_routes.dart';
import 'package:tigo/presentation/view_model/home/home_view_model.dart';

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
      final userId = widget.userId;
      final doc =
          await FirebaseFirestore.instance
              .collection('tripPlans')
              .doc(userId)
              .collection('plans')
              .doc(planId)
              .get();
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
    setState(() {
      _isLoading = false;
      _error = null;
    });
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
      body: Column(
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
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                dates
                    .map(
                      (date) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(date),
                          selected: selectedDate == date,
                          onSelected:
                              (_) => setState(() => selectedDate = date),
                        ),
                      ),
                    )
                    .toList(),
          ),
          // 일정 리스트
          Expanded(
            child:
                spots.isEmpty
                    ? const Center(child: Text('해당 날짜에 일정이 없습니다.'))
                    : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: spots.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final spot = spots[idx];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (spot['thumbnail'] != null &&
                                    (spot['thumbnail'] as String).isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      spot['thumbnail'],
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        // 이미지 로딩 실패 시 기본 이미지 또는 아이콘 표시
                                        return Container(
                                          width: 64,
                                          height: 64,
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.broken_image,
                                            color: Colors.grey,
                                            size: 32,
                                          ),
                                        );
                                      },
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
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (spot['category'] != null)
                                        Text(
                                          spot['category'],
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13,
                                          ),
                                        ),
                                      if (spot['info'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            spot['info'],
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      if (spot['openTime'] != null &&
                                          spot['closeTime'] != null)
                                        Text(
                                          '영업: ${spot['openTime']} ~ ${spot['closeTime']}',
                                        ),
                                      if (spot['fee'] != null)
                                        Text('입장료: ${spot['fee']}원'),
                                      if (spot['address'] != null)
                                        Text(spot['address']),
                                      if (spot['phone'] != null)
                                        Text('전화: ${spot['phone']}'),
                                      if (spot['website'] != null &&
                                          spot['website'] != "undefined" &&
                                          (spot['website'] as String)
                                              .isNotEmpty)
                                        Text('웹사이트: ${spot['website']}'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
