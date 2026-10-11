import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../data/app_data_service.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

List<MapPin> memberMapPins(List<Member> members) {
  final groups = <List<int>>[];
  final assigned = <int>{};

  for (var index = 0; index < members.length; index++) {
    if (assigned.contains(index)) continue;
    final group = <int>[index];
    assigned.add(index);
    for (var candidate = index + 1; candidate < members.length; candidate++) {
      if (assigned.contains(candidate)) continue;
      final candidateMember = members[candidate];
      final isNearby = group.any((groupIndex) {
        final groupMember = members[groupIndex];
        return Geolocator.distanceBetween(
              groupMember.lat!,
              groupMember.lng!,
              candidateMember.lat!,
              candidateMember.lng!,
            ) <
            60;
      });
      if (isNearby) {
        group.add(candidate);
        assigned.add(candidate);
      }
    }
    groups.add(group);
  }

  const colors = [
    AppColors.red,
    AppColors.blue,
    AppColors.orange,
    AppColors.darkGreen,
    Color(0xFF8E44AD),
    Color(0xFF795548),
  ];
  final pins = <MapPin>[];
  for (final group in groups) {
    for (var offsetIndex = 0; offsetIndex < group.length; offsetIndex++) {
      final memberIndex = group[offsetIndex];
      final member = members[memberIndex];
      var latitude = member.lat!;
      var longitude = member.lng!;
      if (group.length > 1) {
        final angle = 2 * math.pi * offsetIndex / group.length;
        const spreadMeters = 45.0;
        latitude += spreadMeters * math.sin(angle) / 111320;
        final longitudeScale = 111320 * math.cos(latitude * math.pi / 180);
        longitude +=
            spreadMeters *
            math.cos(angle) /
            longitudeScale.abs().clamp(1, double.infinity);
      }
      pins.add(
        MapPin(
          position: LatLng(latitude, longitude),
          label: member.name.isEmpty ? 'Member' : member.name,
          color: colors[memberIndex % colors.length],
        ),
      );
    }
  }
  return pins;
}
