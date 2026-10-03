import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/loading/loading_views.dart';
import '../../../../../core/theme/app_theme.dart';

/// Camera-only evidence capture.
///
class EvidenceCapture extends StatefulWidget {
  const EvidenceCapture({
    super.key,
    required this.photoPaths,
    required this.onChanged,
    this.minPhotos = 3,
    this.maxPhotos = 5,
    this.picker,
  });

  final List<String> photoPaths;
  final ValueChanged<List<String>> onChanged;
  final int minPhotos;
  final int maxPhotos;

  /// Injectable so the capture flow can be exercised without a camera.
  final ImagePicker? picker;

  @override
  State<EvidenceCapture> createState() => _EvidenceCaptureState();
}

class _EvidenceCaptureState extends State<EvidenceCapture> {
  bool _capturing = false;

  bool get isComplete => widget.photoPaths.length >= widget.minPhotos;

  int get _remaining => widget.maxPhotos - widget.photoPaths.length;

  Future<void> _capture() async {
    if (_capturing || _remaining <= 0) return;
    setState(() => _capturing = true);
    try {
      final picked = await (widget.picker ?? ImagePicker()).pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      widget.onChanged([...widget.photoPaths, picked.path]);
    } on Object catch (error) {
      if (!mounted) return;
      // Camera denied, no camera, or the activity was reclaimed. The officer
      // needs the reason, because the fix is different each time.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open the camera. $error'),
          backgroundColor: EcoTraceColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoPaths = widget.photoPaths;
    final remaining = _remaining;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Photo evidence',
              style: TextStyle(
                color: EcoTraceColors.forest,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${photoPaths.length}/${widget.maxPhotos}',
              style: const TextStyle(
                color: EcoTraceColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Take at least ${widget.minPhotos} photos of the plant. '
          '${remaining > 0 ? '$remaining remaining.' : 'Maximum reached.'}',
          style: const TextStyle(
            color: EcoTraceColors.muted,
            fontSize: 12,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final path in photoPaths)
              _Thumb(
                path: path,
                onRemove: () => widget.onChanged([...photoPaths]..remove(path)),
              ),
            if (remaining > 0)
              _AddTile(onTap: _capture, label: 'Take photo', busy: _capturing),
          ],
        ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.path, required this.onRemove});

  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(path),
          width: 84,
          height: 84,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            width: 84,
            height: 84,
            color: EcoTraceColors.border,
            child: const Icon(Icons.broken_image, size: 20),
          ),
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: GestureDetector(
          onTap: onRemove,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: EcoTraceColors.error,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, size: 12, color: Colors.white),
          ),
        ),
      ),
    ],
  );
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap, required this.label, this.busy = false});

  final VoidCallback onTap;
  final String label;

  /// Shows the camera spinner while the picker is open.
  final bool busy;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: busy ? null : onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: EcoTraceColors.forest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (busy)
            const SizedBox.square(
              dimension: 22,
              child: EcoButtonLoader(size: 22),
            )
          else
            const Icon(
              Icons.photo_camera_rounded,
              color: Colors.white,
              size: 22,
            ),
          const SizedBox(height: 4),
          Text(
            busy ? 'Opening…' : label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}
