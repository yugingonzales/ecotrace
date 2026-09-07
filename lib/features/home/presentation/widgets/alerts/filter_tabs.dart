import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

class FilterTabs extends StatefulWidget {
  const FilterTabs({super.key});

  @override
  State<FilterTabs> createState() => _FilterTabsState();
}

class _FilterTabsState extends State<FilterTabs> {
  String _selected = 'All';

  @override
  Widget build(BuildContext context) => Row(
    children: ['All', 'Recent', 'By date']
        .map(
          (label) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () => setState(() => _selected = label),
              style: TextButton.styleFrom(
                backgroundColor: label == _selected
                    ? EcoTraceColors.forest
                    : const Color(0xFFE8F0EC),
                foregroundColor: label == _selected
                    ? Colors.white
                    : EcoTraceColors.muted,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        )
        .toList(),
  );
}
