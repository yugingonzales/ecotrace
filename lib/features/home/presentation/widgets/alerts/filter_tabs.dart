import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../models/alert_data.dart';

class FilterTabs extends StatelessWidget {
  const FilterTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final AlertFilter selected;
  final ValueChanged<AlertFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = <(String, AlertFilter)>[
      ('All', AlertFilter.all),
      ('Recent', AlertFilter.recent),
      ('By date', AlertFilter.byDate),
    ];
    return Row(
      children: tabs
          .map(
            (tab) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: () => onChanged(tab.$2),
                style: TextButton.styleFrom(
                  backgroundColor: tab.$2 == selected
                      ? EcoTraceColors.forest
                      : const Color(0xFFE8F0EC),
                  foregroundColor: tab.$2 == selected
                      ? Colors.white
                      : EcoTraceColors.muted,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                ),
                child: Text(
                  tab.$1,
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
}
