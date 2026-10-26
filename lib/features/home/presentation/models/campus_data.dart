import 'package:flutter/material.dart';

/// UEP Catarman, Northern Samar — surveyed planting site.

/// Mirror of the EcoTrace admin portal `site.ts` geometry so both apps share
/// the same real-world coordinates.
const double campusCenterLat = 12.5113;
const double campusCenterLng = 124.6641;

const double campusMinLat = 12.509;
const double campusMinLng = 124.6604;
const double campusMaxLat = 12.5136;
const double campusMaxLng = 124.6682;

/// A surveyed planting zone (admin `ZONES`).
class CampusZone {
  const CampusZone({
    required this.name,
    required this.lat,
    required this.lng,
    required this.elevation,
    required this.color,
  });

  final String name;
  final double lat;
  final double lng;
  final double elevation;
  final Color color;
}

const List<CampusZone> campusZones = [
  CampusZone(
    name: 'Zone I',
    lat: 12.5096,
    lng: 124.6674,
    elevation: 6.7,
    color: Color(0xFF2F9E6E),
  ),
  CampusZone(
    name: 'Zone II',
    lat: 12.5131,
    lng: 124.6613,
    elevation: 6.3,
    color: Color(0xFF2F6FB6),
  ),
  CampusZone(
    name: 'Zone III',
    lat: 12.5103,
    lng: 124.6609,
    elevation: 8.3,
    color: Color(0xFFD9902B),
  ),
];
