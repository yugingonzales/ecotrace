import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../shared/avatar.dart';
import '../shared/surface_card.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.time,
    required this.title,
    required this.location,
    required this.description,
    required this.attendeeCount,
    required this.joined,
    required this.onOpen,
    required this.onConfirm,
    this.warm = false,
  });

  final String time;
  final String title;
  final String location;
  final String description;
  final int attendeeCount;
  final bool joined;
  final VoidCallback onOpen;
  final VoidCallback onConfirm;
  final bool warm;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'View details for $title',
      hint: 'Opens the full event details',
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(20),
        child: SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: warm
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFD7F5E3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  time,
                  style: TextStyle(
                    color: warm
                        ? const Color(0xFFD97706)
                        : const Color(0xFF15803D),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF0A231C),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: EcoTraceColors.muted,
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: EcoTraceColors.muted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      location,
                      style: const TextStyle(
                        color: EcoTraceColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: const TextStyle(
                  color: EcoTraceColors.muted,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF0F4F1)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Avatar('JA'),
                        Avatar('MC'),
                        Avatar('KV'),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '+$attendeeCount joined',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF7A9185),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: onConfirm,
                    style: TextButton.styleFrom(
                      backgroundColor: joined
                          ? const Color(0xFFE8F0EC)
                          : EcoTraceColors.forest,
                      foregroundColor: joined
                          ? const Color(0xFF2D8A56)
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      joined ? 'Joined' : 'Confirm',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
