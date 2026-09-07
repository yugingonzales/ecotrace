import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key, this.onSearch, this.onFilter, this.onCalendar});

  final VoidCallback? onSearch;
  final VoidCallback? onFilter;
  final VoidCallback? onCalendar;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: EcoTraceColors.lemon,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.layers_outlined,
          color: EcoTraceColors.forest,
          size: 20,
        ),
      ),
      const SizedBox(width: 10),
      const Flexible(
        child: Text(
          'EcoTrace',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const Spacer(),
      if (onCalendar != null) ...[
        _buildActionButton(
          icon: Icons.calendar_month_rounded,
          tooltip: 'Calendar',
          onPressed: onCalendar,
        ),
        const SizedBox(width: 2),
      ],
      _buildActionButton(
        icon: Icons.search_rounded,
        tooltip: 'Search',
        onPressed: onSearch,
      ),
      const SizedBox(width: 2),
      _buildActionButton(
        icon: Icons.tune_rounded,
        tooltip: 'Filter',
        onPressed: onFilter,
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
      style: IconButton.styleFrom(backgroundColor: Colors.white12),
      tooltip: tooltip,
    );
  }
}
