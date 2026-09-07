import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../widgets/shared/section_title.dart';
import '../../widgets/shared/status_badge.dart';
import '../../widgets/shared/surface_card.dart';

class IncidentReportScreen extends StatelessWidget {
  const IncidentReportScreen({required this.treeCode, super.key});

  final String treeCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoTraceColors.canvas,
      appBar: AppBar(
        backgroundColor: EcoTraceColors.forest,
        foregroundColor: Colors.white,
        title: const Text(
          'Report incident',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          const SectionTitle('Linked tree record'),
          SurfaceCard(
            child: Row(
              children: [
                const Icon(Icons.park_outlined, color: EcoTraceColors.forest),
                const SizedBox(width: 10),
                Text(
                  treeCode,
                  style: const TextStyle(
                    color: Color(0xFF0A231C),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                const StatusBadge(label: 'Draft'),
              ],
            ),
          ),
          const SectionTitle('Incident details'),
          DropdownButtonFormField<String>(
            initialValue: 'Damaged tree',
            decoration: const InputDecoration(labelText: 'Incident type'),
            items: const [
              DropdownMenuItem(
                value: 'Damaged tree',
                child: Text('Damaged tree'),
              ),
              DropdownMenuItem(
                value: 'Missing tree',
                child: Text('Missing tree'),
              ),
              DropdownMenuItem(value: 'Other', child: Text('Other')),
            ],
            onChanged: (_) {},
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: 'Medium',
            decoration: const InputDecoration(labelText: 'Severity'),
            items: const [
              DropdownMenuItem(value: 'Low', child: Text('Low')),
              DropdownMenuItem(value: 'Medium', child: Text('Medium')),
              DropdownMenuItem(value: 'High', child: Text('High')),
            ],
            onChanged: (_) {},
          ),
          const SizedBox(height: 14),
          const TextField(
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Describe the damage or missing tree evidence',
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Add photo evidence'),
            style: OutlinedButton.styleFrom(
              foregroundColor: EcoTraceColors.forest,
              minimumSize: const Size.fromHeight(50),
              side: const BorderSide(color: EcoTraceColors.border),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Incident draft saved locally.'),
                  backgroundColor: EcoTraceColors.forest,
                ),
              );
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: EcoTraceColors.forest,
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('Save incident draft'),
          ),
        ],
      ),
    );
  }
}
