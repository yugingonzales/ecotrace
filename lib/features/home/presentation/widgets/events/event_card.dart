import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

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
    this.eventLabel,
    this.statusLabel,
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
  final String? eventLabel;
  final String? statusLabel;
  final bool warm;

  bool get _isOngoing => eventLabel == 'ONGOING';
  bool get _isHistorical => statusLabel != null;

  @override
  Widget build(BuildContext context) {
    final actionLabel = _isHistorical
        ? statusLabel!
        : joined
        ? 'Manage Activity'
        : 'Join activity';
    final actionIcon = _isHistorical
        ? Icons.check_circle_outline_rounded
        : joined
        ? Icons.tune_rounded
        : Icons.play_arrow_rounded;

    return Semantics(
      button: true,
      label: 'View details for $title',
      hint: 'Opens the full event details',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FCF9),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFDCEBE3)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0B173C2D),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 5,
                      color: _isHistorical
                          ? const Color(0xFFB8CFC5)
                          : _isOngoing
                          ? const Color(0xFF079447)
                          : const Color(0xFF91E2C9),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (eventLabel != null)
                                  _StatusPill(
                                    label: eventLabel!,
                                    ongoing: _isOngoing,
                                  )
                                else if (statusLabel != null)
                                  _StatusPill(
                                    label: statusLabel!,
                                    ongoing: false,
                                  ),
                                const Spacer(),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _EventImagePlaceholder(ongoing: _isOngoing),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF0A231C),
                                          fontSize: 20,
                                          height: 1.05,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _EventMetaRow(
                                        icon: Icons.location_on_outlined,
                                        text: location,
                                      ),
                                      const SizedBox(height: 6),
                                      _EventMetaRow(
                                        icon: Icons.calendar_month_outlined,
                                        text: time,
                                      ),
                                      const SizedBox(height: 6),
                                      _EventMetaRow(
                                        icon: Icons.groups_outlined,
                                        text: '$attendeeCount participants',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Divider(height: 1, color: Color(0xFFD5E6DE)),
                            const SizedBox(height: 9),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.eco_rounded,
                                    color: Color(0xFF237A5B),
                                    size: 17,
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    description.isEmpty
                                        ? 'EcoTrace field activity.'
                                        : description,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF55766A),
                                      fontSize: 12,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: _isHistorical
                                      ? null
                                      : joined
                                      ? onOpen
                                      : onConfirm,
                                  icon: Icon(actionIcon, size: 17),
                                  label: Text(actionLabel),
                                  style: TextButton.styleFrom(
                                    backgroundColor: _isHistorical
                                        ? const Color(0xFFE8F0EC)
                                        : EcoTraceColors.forestDeep,
                                    foregroundColor: _isHistorical
                                        ? const Color(0xFF547568)
                                        : Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 9,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.ongoing});
  final String label;
  final bool ongoing;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: ongoing ? const Color(0xFF087C3E) : const Color(0xFFD8F4E9),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          ongoing ? Icons.play_circle_outline_rounded : Icons.event_outlined,
          size: 16,
          color: ongoing ? Colors.white : const Color(0xFF21634F),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: ongoing ? Colors.white : const Color(0xFF21634F),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: .35,
          ),
        ),
        if (ongoing) ...[
          const SizedBox(width: 7),
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF50D978),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    ),
  );
}

class _EventImagePlaceholder extends StatelessWidget {
  const _EventImagePlaceholder({required this.ongoing});
  final bool ongoing;

  @override
  Widget build(BuildContext context) => Container(
    width: 100,
    height: 94,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: ongoing
            ? const [Color(0xFF75A866), Color(0xFF234F31)]
            : const [Color(0xFFB8DCF0), Color(0xFF6EA78B)],
      ),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          ongoing ? Icons.spa_rounded : Icons.landscape_rounded,
          size: 50,
          color: Colors.white.withValues(alpha: .86),
        ),
        Positioned(
          bottom: 7,
          child: Icon(
            Icons.grass_rounded,
            size: 28,
            color: Colors.white.withValues(alpha: .7),
          ),
        ),
      ],
    ),
  );
}

class _EventMetaRow extends StatelessWidget {
  const _EventMetaRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const SizedBox(width: 1),
      Icon(icon, color: Color(0xFF1D5A4A), size: 17),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF4E7063),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}
