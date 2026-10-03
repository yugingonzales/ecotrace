import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/loading/loading_views.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../widgets/shared/section_title.dart';
import '../../widgets/shared/status_badge.dart';
import '../../widgets/shared/surface_card.dart';

class IncidentReportScreen extends StatefulWidget {
  const IncidentReportScreen({required this.treeCode, super.key});

  final String treeCode;

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _picker = ImagePicker();
  String _incidentType = 'Damaged tree';
  String _severity = 'Medium';
  XFile? _evidence;
  bool _saving = false;
  bool _picking = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickEvidence() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 82,
        maxWidth: 1600,
      );
      if (!mounted || image == null) return;
      setState(() => _evidence = image);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open the camera. $error'),
          backgroundColor: EcoTraceColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Incident draft saved locally.'),
        backgroundColor: EcoTraceColors.forest,
      ),
    );
    Navigator.pop(context);
  }

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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            const SectionTitle('Linked tree record'),
            SurfaceCard(
              child: Row(
                children: [
                  const Icon(Icons.park_outlined, color: EcoTraceColors.forest),
                  const SizedBox(width: 10),
                  Text(
                    widget.treeCode,
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
              initialValue: _incidentType,
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
              onChanged: (value) {
                if (value != null) setState(() => _incidentType = value);
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _severity,
              decoration: const InputDecoration(labelText: 'Severity'),
              items: const [
                DropdownMenuItem(value: 'Low', child: Text('Low')),
                DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                DropdownMenuItem(value: 'High', child: Text('High')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _severity = value);
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _description,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe the damage or missing tree evidence',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Description is required'
                  : null,
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _picking ? null : _pickEvidence,
              icon: _picking
                  ? const EcoButtonLoader(color: EcoTraceColors.forest)
                  : const Icon(Icons.photo_camera_outlined),
              label: Text(
                _picking
                    ? 'Opening camera…'
                    : (_evidence == null
                          ? 'Add photo evidence'
                          : 'Replace photo evidence'),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: EcoTraceColors.forest,
                minimumSize: const Size.fromHeight(50),
                side: const BorderSide(color: EcoTraceColors.border),
              ),
            ),
            if (_evidence != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.image_outlined,
                  color: EcoTraceColors.forest,
                ),
                title: Text(_evidence!.name),
                trailing: IconButton(
                  tooltip: 'Remove photo evidence',
                  onPressed: () => setState(() => _evidence = null),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: EcoTraceColors.forest,
                minimumSize: const Size.fromHeight(52),
              ),
              child: _saving
                  ? const EcoButtonLoader()
                  : const Text('Save incident draft'),
            ),
          ],
        ),
      ),
    );
  }
}
