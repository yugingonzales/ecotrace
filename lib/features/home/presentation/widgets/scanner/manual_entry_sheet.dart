import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

class ManualEntrySheet extends StatefulWidget {
  const ManualEntrySheet({super.key});

  @override
  State<ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends State<ManualEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _treeTag = TextEditingController();
  final _dbh = TextEditingController();
  final _crownDimension = TextEditingController();
  final _notes = TextEditingController();
  String _plantStatus = 'Healthy';
  String _measurementSource = 'Manual';

  @override
  void dispose() {
    _treeTag.dispose();
    _dbh.dispose();
    _crownDimension.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? '$label is required' : null;

  String? _measurement(String? value, String label) {
    final required = _required(value, label);
    if (required != null) return required;
    final number = double.tryParse(value!.trim());
    if (number == null || number <= 0) return 'Enter a value greater than 0';
    return null;
  }

  void _saveDraft() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Verification draft for ${_treeTag.text.trim()} saved locally.',
        ),
        backgroundColor: EcoTraceColors.forest,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      18,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD5DFD8),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Manual tree verification',
              style: TextStyle(
                color: Color(0xFF0A231C),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _treeTag,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Tree tag',
                hintText: 'e.g., T-104',
              ),
              validator: (value) => _required(value, 'Tree tag'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dbh,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'DBH (cm)',
                hintText: 'Enter measured diameter',
              ),
              validator: (value) => _measurement(value, 'DBH'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _crownDimension,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Crown dimension (m)',
                hintText: 'Enter measured crown',
              ),
              validator: (value) => _measurement(value, 'Crown dimension'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _plantStatus,
              decoration: const InputDecoration(labelText: 'Plant status'),
              items: const [
                DropdownMenuItem(value: 'Healthy', child: Text('Healthy')),
                DropdownMenuItem(value: 'At risk', child: Text('At risk')),
                DropdownMenuItem(value: 'Damaged', child: Text('Damaged')),
                DropdownMenuItem(value: 'Missing', child: Text('Missing')),
                DropdownMenuItem(value: 'Unknown', child: Text('Unknown')),
              ],
              onChanged: (value) =>
                  setState(() => _plantStatus = value ?? 'Healthy'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _measurementSource,
              decoration: const InputDecoration(
                labelText: 'Measurement source',
              ),
              items: const [
                DropdownMenuItem(value: 'Automated', child: Text('Automated')),
                DropdownMenuItem(value: 'Manual', child: Text('Manual')),
                DropdownMenuItem(
                  value: 'Corrected',
                  child: Text('Corrected manually'),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _measurementSource = value ?? 'Manual'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Optional field observations',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saveDraft,
              style: FilledButton.styleFrom(
                backgroundColor: EcoTraceColors.forest,
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Save verification draft'),
            ),
          ],
        ),
      ),
    ),
  );
}
