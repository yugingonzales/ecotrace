import 'package:flutter/material.dart';

import 'map_tree.dart';

/// UEP Catarman, Northern Samar — surveyed planting site.
///
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

/// Complete tree inventory (admin `trees.ts`), transcribed 1:1 with real
/// coordinates and admin statuses. 23 records: 11 verified, 6 pending,
/// 4 incident, 2 unverified.
const List<MapTree> campusTrees = [
  // ── Zone I ──────────────────────────────────────────────────────
  MapTree(
    id: 'TRE-0892',
    lat: 12.5101,
    lng: 124.6679,
    status: TreeStatus.verified,
    planter: 'Juan Santos',
    species: 'Narra',
    datePlanted: 'Mar 12, 2026',
    zone: 'Zone I',
  ),
  MapTree(
    id: 'TRE-0567',
    lat: 12.5098,
    lng: 124.6681,
    status: TreeStatus.incident,
    planter: 'Maria Reyes',
    species: 'Molave',
    datePlanted: 'Mar 15, 2026',
    zone: 'Zone I',
  ),
  MapTree(
    id: 'TRE-1204',
    lat: 12.5092,
    lng: 124.6677,
    status: TreeStatus.pending,
    planter: 'Carlo Diaz',
    species: 'Ipil',
    datePlanted: 'Mar 18, 2026',
    zone: 'Zone I',
  ),
  MapTree(
    id: 'TRE-0341',
    lat: 12.5100,
    lng: 124.6671,
    status: TreeStatus.verified,
    planter: 'Ana Lim',
    species: 'Mahogany',
    datePlanted: 'Mar 20, 2026',
    zone: 'Zone I',
  ),
  MapTree(
    id: 'TRE-1108',
    lat: 12.5094,
    lng: 124.6671,
    status: TreeStatus.pending,
    planter: 'Sofia Torres',
    species: 'Kamagong',
    datePlanted: 'Mar 25, 2026',
    zone: 'Zone I',
  ),
  MapTree(
    id: 'TRE-0223',
    lat: 12.5105,
    lng: 124.6676,
    status: TreeStatus.verified,
    planter: 'Rico Mendoza',
    species: 'Narra',
    datePlanted: 'Mar 28, 2026',
    zone: 'Zone I',
  ),
  MapTree(
    id: 'TRE-0412',
    lat: 12.5094,
    lng: 124.6679,
    status: TreeStatus.verified,
    planter: 'Marc Tan',
    species: 'Ipil',
    datePlanted: 'Apr 3, 2026',
    zone: 'Zone I',
  ),
  MapTree(
    id: 'TRE-1501',
    lat: 12.5097,
    lng: 124.6673,
    status: TreeStatus.verified,
    planter: 'Luis Reyes',
    species: 'Narra',
    datePlanted: 'Jan 15, 2025',
    zone: 'Zone I',
  ),
  MapTree(
    id: 'TRE-1502',
    lat: 12.5103,
    lng: 124.6680,
    status: TreeStatus.pending,
    planter: 'Ria Santos',
    species: 'Molave',
    datePlanted: 'Jun 20, 2025',
    zone: 'Zone I',
  ),
  MapTree(
    id: 'TRE-1503',
    lat: 12.5089,
    lng: 124.6675,
    status: TreeStatus.verified,
    planter: 'Nico Bautista',
    species: 'Kamagong',
    datePlanted: 'Nov 8, 2025',
    zone: 'Zone I',
  ),
  // ── Zone II ─────────────────────────────────────────────────────
  MapTree(
    id: 'TRE-0783',
    lat: 12.5135,
    lng: 124.6616,
    status: TreeStatus.incident,
    planter: 'Ben Cruz',
    species: 'Banaba',
    datePlanted: 'Mar 22, 2026',
    zone: 'Zone II',
  ),
  MapTree(
    id: 'TRE-0950',
    lat: 12.5128,
    lng: 124.6617,
    status: TreeStatus.incident,
    planter: 'Lena Bautista',
    species: 'Molave',
    datePlanted: 'Apr 1, 2026',
    zone: 'Zone II',
  ),
  MapTree(
    id: 'TRE-1056',
    lat: 12.5134,
    lng: 124.6610,
    status: TreeStatus.unverified,
    planter: 'Donna Uy',
    species: 'Narra',
    datePlanted: 'Apr 5, 2026',
    zone: 'Zone II',
  ),
  MapTree(
    id: 'TRE-0834',
    lat: 12.5129,
    lng: 124.6612,
    status: TreeStatus.pending,
    planter: 'Chris Ramos',
    species: 'Narra',
    datePlanted: 'Apr 11, 2026',
    zone: 'Zone II',
  ),
  MapTree(
    id: 'TRE-1504',
    lat: 12.5132,
    lng: 124.6614,
    status: TreeStatus.verified,
    planter: 'Ella Torres',
    species: 'Ipil',
    datePlanted: 'Mar 5, 2025',
    zone: 'Zone II',
  ),
  MapTree(
    id: 'TRE-1505',
    lat: 12.5127,
    lng: 124.6615,
    status: TreeStatus.incident,
    planter: 'Mark Dela Cruz',
    species: 'Banaba',
    datePlanted: 'Aug 18, 2025',
    zone: 'Zone II',
  ),
  MapTree(
    id: 'TRE-1506',
    lat: 12.5130,
    lng: 124.6611,
    status: TreeStatus.verified,
    planter: 'Sara Lim',
    species: 'Mahogany',
    datePlanted: 'Dec 1, 2024',
    zone: 'Zone II',
  ),
  // ── Zone III ────────────────────────────────────────────────────
  MapTree(
    id: 'TRE-0678',
    lat: 12.5099,
    lng: 124.6612,
    status: TreeStatus.unverified,
    planter: 'Kai Lopez',
    species: 'Mahogany',
    datePlanted: 'Apr 7, 2026',
    zone: 'Zone III',
  ),
  MapTree(
    id: 'TRE-0199',
    lat: 12.5107,
    lng: 124.6612,
    status: TreeStatus.verified,
    planter: 'Jess Flores',
    species: 'Banaba',
    datePlanted: 'Apr 9, 2026',
    zone: 'Zone III',
  ),
  MapTree(
    id: 'TRE-0455',
    lat: 12.5104,
    lng: 124.6605,
    status: TreeStatus.verified,
    planter: 'Pat Soriano',
    species: 'Kamagong',
    datePlanted: 'Apr 13, 2026',
    zone: 'Zone III',
  ),
  MapTree(
    id: 'TRE-1320',
    lat: 12.5100,
    lng: 124.6608,
    status: TreeStatus.pending,
    planter: 'Kim Garcia',
    species: 'Ipil',
    datePlanted: 'Apr 15, 2026',
    zone: 'Zone III',
  ),
  MapTree(
    id: 'TRE-1507',
    lat: 12.5101,
    lng: 124.6609,
    status: TreeStatus.verified,
    planter: 'Jay Pascual',
    species: 'Narra',
    datePlanted: 'Feb 10, 2025',
    zone: 'Zone III',
  ),
  MapTree(
    id: 'TRE-1508',
    lat: 12.5106,
    lng: 124.6610,
    status: TreeStatus.pending,
    planter: 'Rina Garcia',
    species: 'Molave',
    datePlanted: 'Sep 22, 2025',
    zone: 'Zone III',
  ),
];