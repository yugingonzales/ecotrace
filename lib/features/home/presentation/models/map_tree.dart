import 'package:flutter/material.dart';

class MapTree {
  const MapTree({
    required this.code,
    required this.species,
    required this.scientificName,
    required this.planted,
    required this.planter,
    required this.sector,
    required this.status,
    required this.dbh,
    required this.crown,
    required this.color,
  });

  final String code;
  final String species;
  final String scientificName;
  final String planted;
  final String planter;
  final String sector;
  final String status;
  final String dbh;
  final String crown;
  final Color color;
}
