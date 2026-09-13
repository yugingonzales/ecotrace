import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../models/campus_data.dart';
import '../../models/map_tree.dart';

/// Floating button that toggles the [MapFilterPanel]. Shows a small badge with
/// the number of active filters once any zone/status filter is selected.
class MapFilterButton extends StatelessWidget {
  const MapFilterButton({
    super.key,
    required this.open,
    required this.activeFilterCount,
    required this.onTap,
  });

  final bool open;
  final int activeFilterCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final highlighted = open || activeFilterCount > 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: highlighted ? EcoTraceColors.forest : Colors.white,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(color: Color(0x26000000), blurRadius: 10),
                ],
              ),
              child: Icon(
                Icons.tune_rounded,
                color: highlighted ? Colors.white : EcoTraceColors.forest,
                size: 21,
              ),
            ),
          ),
        ),
        if (activeFilterCount > 0)
          Positioned(
            right: -2,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFDC3A3A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                '$activeFilterCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Zone + status filter panel with live inventory counts, rendered above the
/// real map. Mirrors the admin portal's zone/status filter vocabulary.
class MapFilterPanel extends StatelessWidget {
  const MapFilterPanel({
    super.key,
    required this.zoneFilter,
    required this.statusFilter,
    required this.onZoneSelected,
    required this.onStatusSelected,
  });

  final String? zoneFilter;
  final TreeStatus? statusFilter;
  final ValueChanged<String?> onZoneSelected;
  final ValueChanged<TreeStatus?> onStatusSelected;

  static const _sectionStyle = TextStyle(
    color: Color(0xFF7A9185),
    fontSize: 9,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.6,
  );

  int _zoneCount(String name) =>
      campusTrees.where((tree) => tree.zone == name).length;

  int _statusCount(TreeStatus status) =>
      campusTrees.where((tree) => tree.status == status).length;

  @override
  Widget build(BuildContext context) => Container(
    width: 244,
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .97),
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(color: Color(0x26000000), blurRadius: 14),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.filter_alt_outlined,
              size: 15,
              color: EcoTraceColors.forest,
            ),
            const SizedBox(width: 6),
            const Text(
              'FILTERS',
              style: TextStyle(
                color: Color(0xFF7A9185),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: .6,
              ),
            ),
            const Spacer(),
            Text(
              '${campusTrees.length} trees',
              style: const TextStyle(
                color: Color(0xFF7A9185),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('ZONES', style: _sectionStyle),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _ZonePill(
              label: 'All zones',
              count: campusTrees.length,
              selected: zoneFilter == null,
              onTap: () => onZoneSelected(null),
            ),
            for (final zone in campusZones)
              _ZonePill(
                label: zone.name,
                count: _zoneCount(zone.name),
                color: zone.color,
                selected: zoneFilter == zone.name,
                onTap: () => onZoneSelected(zone.name),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('STATUS', style: _sectionStyle),
        const SizedBox(height: 4),
        _StatusTile(
          label: 'All statuses',
          count: campusTrees.length,
          color: EcoTraceColors.forest,
          selected: statusFilter == null,
          onTap: () => onStatusSelected(null),
        ),
        for (final status in TreeStatus.values)
          _StatusTile(
            label: status.label,
            count: _statusCount(status),
            color: status.color,
            selected: statusFilter == status,
            onTap: () => onStatusSelected(status),
          ),
      ],
    ),
  );
}

class _ZonePill extends StatelessWidget {
  const _ZonePill({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? EcoTraceColors.forest : const Color(0xFFF1F5F2),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? EcoTraceColors.forest : const Color(0xFFDDE6E0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : EcoTraceColors.forest,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '$count',
              style: TextStyle(
                color: selected
                    ? const Color(0xFFD7F5E3)
                    : const Color(0xFF7A9185),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: .12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : const Color(0xFF0A231C),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              '$count',
              style: const TextStyle(
                color: Color(0xFF7A9185),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}