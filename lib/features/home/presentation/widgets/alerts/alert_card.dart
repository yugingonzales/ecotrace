import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../shared/surface_card.dart';

class AlertCard extends StatefulWidget {
  const AlertCard({
    required this.title,
    required this.time,
    required this.label,
    required this.color,
    required this.textColor,
    required this.body,
    this.onViewed,
    this.actionable = false,
    this.eventName,
    this.notificationCode,
    this.onAction,
    super.key,
  });

  final String title;
  final String time;
  final String label;
  final Color color;
  final Color textColor;
  final String body;
  final VoidCallback? onViewed;
  final bool actionable;
  final String? eventName;
  final String? notificationCode;
  final VoidCallback? onAction;

  @override
  State<AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<AlertCard> {
  bool _viewedReported = false;

  @override
  void initState() {
    super.initState();
    if (!widget.actionable) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_viewedReported) {
          _viewedReported = true;
          widget.onViewed?.call();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: const TextStyle(
                  color: Color(0xFF0A231C),
                  fontSize: 16,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widget.label,
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          widget.time,
          style: const TextStyle(
            color: Color(0xFF7A9185),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (widget.eventName != null &&
            widget.eventName!.trim().isNotEmpty &&
            !{
              'upcoming_event',
              'event_conclusion',
            }.contains(widget.notificationCode)) ...[
          const SizedBox(height: 6),
          Text(
            widget.eventName!,
            style: const TextStyle(
              color: EcoTraceColors.forest,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        if (widget.body.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            widget.body,
            style: const TextStyle(
              color: EcoTraceColors.muted,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ],
    );

    if (widget.actionable && widget.onAction != null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: EcoTraceColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onAction,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: cardContent,
            ),
          ),
        ),
      );
    }

    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 8),
      borderRadius: 8,
      child: cardContent,
    );
  }
}
