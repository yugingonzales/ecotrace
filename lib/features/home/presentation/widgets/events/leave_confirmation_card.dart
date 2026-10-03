import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../models/local_event.dart';

class LeaveConfirmationCard extends StatefulWidget {
  const LeaveConfirmationCard({
    super.key,
    required this.event,
    required this.onCancel,
    required this.onConfirm,
  });

  final LocalEvent event;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  State<LeaveConfirmationCard> createState() => _LeaveConfirmationCardState();
}

class _LeaveConfirmationCardState extends State<LeaveConfirmationCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valid = _controller.text.trim() == 'Quit';
    return Material(
      color: EcoTraceColors.canvas,
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [EcoTraceColors.forestDeep, Color(0xFF7A3026)],
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.exit_to_app_rounded,
                  color: Color(0xFFFFD9D1),
                  size: 30,
                ),
                SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LEAVE ACTIVITY',
                      style: TextStyle(
                        color: Color(0xFFFFD9D1),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Are you sure?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This will remove you from the activity.',
                  style: TextStyle(
                    color: Color(0xFF0A231C),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.event.title,
                  style: const TextStyle(
                    color: EcoTraceColors.muted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('leave-confirmation-input'),
                  controller: _controller,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Type Quit to continue',
                    hintText: 'Quit',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: EcoTraceColors.border,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: EcoTraceColors.border,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    child: const Text('Keep activity'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: valid ? widget.onConfirm : null,
                    icon: const Icon(Icons.exit_to_app_rounded, size: 18),
                    label: const Text('Leave activity'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF7A3026),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
