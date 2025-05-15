import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class QuickPlanTestScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? planList;

  const QuickPlanTestScreen({super.key, this.planList});

  @override
  State<QuickPlanTestScreen> createState() => _QuickPlanTestScreenState();
}

class _QuickPlanTestScreenState extends State<QuickPlanTestScreen> {
  late List<String> dates;
  late String selectedDate;

  @override
  void initState() {
    super.initState();
    final list = widget.planList ?? [];
    // 날짜 중복 제거 + 정렬
    dates =
        list
            .map((e) => e['date'] as String? ?? '')
            .where((d) => d.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    selectedDate = dates.isNotEmpty ? dates.first : '';
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.planList ?? [];
    final spots = list.where((e) => e['date'] == selectedDate).toList();

    return Scaffold(
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
