import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    this.onSearch,
    this.onFilter,
    this.onCalendar,
    this.onAnnouncements,
    this.center,
    this.showSearch = true,
    this.showFilter = true,
    this.edgeOffset = 4,
  });

  final VoidCallback? onSearch;
  final VoidCallback? onFilter;
  final VoidCallback? onCalendar;
  final VoidCallback? onAnnouncements;
  final Widget? center;
  final bool showSearch;
  final bool showFilter;
  // Retained for compatibility with other headers; actions stay within the
  // header bounds so the right margin remains balanced.
  final double edgeOffset;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: EcoTraceColors.lemon,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.eco,
              color: EcoTraceColors.forest,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'EcoTrace',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      if (center != null) ...[
        const SizedBox(width: 12),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: center!,
            ),
          ),
        ),
        if (showSearch ||
            onCalendar != null ||
            onAnnouncements != null ||
            showFilter)
          const SizedBox(width: 4),
      ] else
        const Spacer(),
      if (showSearch ||
          onCalendar != null ||
          onAnnouncements != null ||
          showFilter)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSearch)
              _buildActionButton(
                icon: Icons.search_rounded,
                tooltip: 'Search',
                onPressed: onSearch,
              ),
            if (onAnnouncements != null)
              _buildActionButton(
                icon: Icons.campaign_rounded,
                tooltip: 'Announcements',
                onPressed: onAnnouncements,
              ),
            if (onCalendar != null)
              _buildActionButton(
                icon: Icons.calendar_month_rounded,
                tooltip: 'Calendar',
                onPressed: onCalendar,
              ),
            if (showFilter)
              _buildActionButton(
                icon: Icons.tune_rounded,
                tooltip: 'Filter',
                onPressed: onFilter,
              ),
          ],
        ),
    ],
  );

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      padding: const EdgeInsets.all(7),
      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      icon: Icon(icon, color: Colors.white, size: 19),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white12,
        overlayColor: Colors.white24,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      tooltip: tooltip,
    );
  }
}
