import 'package:flutter/material.dart';

enum AlertFilter { all, recent, byDate }

class AlertData {
  const AlertData({
    required this.title,
    required this.time,
    required this.label,
    required this.color,
    required this.textColor,
    required this.body,
    required this.filter,
  });

  final String title;
  final String time;
  final String label;
  final Color color;
  final Color textColor;
  final String body;
  final AlertFilter filter;
}
