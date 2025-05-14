import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tigo/core/screen/base_screen.dart';
import 'package:tigo/presentation/view_model/tigo_plan_completed/tigo_plan_completed_view_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TigoPlanCompletedScreen extends BaseScreen<TigoPlanCompletedViewModel> {

  const TigoPlanCompletedScreen({super.key});

  @override
  Widget buildBody(BuildContext context) {
    // 토글 상태를 위한 변수
    final RxBool newSpotPicks = false.obs;

    return GetBuilder<TigoPlanCompletedViewModel>(
      builder: (vm) {
        return Scaffold(
          body: Column(
            children: [
              // 상단 지도
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.28,
                child: Obx(() {
                  final spots = vm.spotsForSelectedDate;
                  if (spots.isEmpty) {
                    return const Center(child: Text('일정이 없습니다.'));
                  }
                  final first = spots.first;
                  return GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        first.latitude ?? 37.5665,
                        first.longitude ?? 126.9780,
                      ),
                      zoom: 13,
                    ),
                    markers:
                        spots
                            .where(
                              (s) => s.latitude != null && s.longitude != null,
                            )
                            .map(
                              (s) => Marker(
                                markerId: MarkerId(s.place ?? ''),
                                position: LatLng(s.latitude!, s.longitude!),
                                infoWindow: InfoWindow(title: s.place),
                              ),
                            )
                            .toSet(),
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                  );
                }),
              ),
              // 도시명 + 토글
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Text(
                      "SEOUL",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        letterSpacing: -1,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Text(
                          "New Spot Picks",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        Obx(
                          () => Switch(
                            value: newSpotPicks.value,
                            onChanged: (v) => newSpotPicks.value = v,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 날짜 칩
              Obx(() {
                final dates = vm.availableDates;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children:
                      dates
                          .map(
                            (date) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: ChoiceChip(
                                label: Text(date),
                                selected: vm.selectedDate.value == date,
                                onSelected: (_) => vm.selectedDate.value = date,
                                selectedColor: Colors.black,
                                labelStyle: TextStyle(
                                  color:
                                      vm.selectedDate.value == date
                                          ? Colors.white
                                          : Colors.black,
                                ),
                                backgroundColor: Colors.grey[200],
                              ),
                            ),
                          )
                          .toList(),
                );
              }),
              // 타임라인 일정표 리스트
              Expanded(
                child: Obx(() {
                  final spots = vm.spotsForSelectedDate;
                  if (spots.isEmpty) {
                    return const Center(child: Text('해당 날짜에 일정이 없습니다.'));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 0,
                    ),
                    itemCount: spots.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final spot = spots[idx];
                      final isLast = idx == spots.length - 1;
                      // 거리 계산
                      double? distance;
                      if (idx > 0) {
                        distance = _calcDistance(
                          spots[idx - 1].latitude,
                          spots[idx - 1].longitude,
                          spot.latitude,
                          spot.longitude,
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 타임라인 원 & 선
                          Column(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.black,
                                child: Text(
                                  "${idx + 1}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (!isLast)
                                Container(
                                  width: 2,
                                  height: 70,
                                  color: Colors.grey[300],
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // spot 정보
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (spot.thumbnail != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          spot.thumbnail!,
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          spot.place ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17,
                                          ),
                                        ),
                                        if (spot.category != null)
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.location_on,
                                                size: 15,
                                                color: Colors.grey,
                                              ),
                                              Text(
                                                spot.category!,
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (distance != null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 4,
                                      left: 4,
                                    ),
                                    child: Text(
                                      "${distance.toStringAsFixed(1)} km",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                if (spot.info != null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 8,
                                      left: 4,
                                    ),
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.all(10),
                                      child: Text(
                                        spot.info!,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  // 하버사인 공식(거리 계산, km)
  double _calcDistance(double? lat1, double? lon1, double? lat2, double? lon2) {
    if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) return 0;
    const R = 6371; // 지구 반지름(km)
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            (sin(dLon / 2) * sin(dLon / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }
}
