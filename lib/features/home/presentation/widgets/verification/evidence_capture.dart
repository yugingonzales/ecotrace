import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/theme/app_theme.dart';

/// Camera-only evidence capture.
///
class EvidenceCapture extends StatelessWidget {
  const EvidenceCapture({
    super.key,
    required this.photoPaths,
    required this.onChanged,
    this.minPhotos = 3,
    this.maxPhotos = 5,
  });

  final List<String> photoPaths;
  final ValueChanged<List<String>> onChanged;
  final int minPhotos;
  final int maxPhotos;

  bool get isComplete => photoPaths.length >= minPhotos;

  Future<void> _capture(BuildContext context) async {
    if (photoPaths.length >= maxPhotos) return;
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null || !context.mounted) return;
      onChanged([...photoPaths, picked.path]);
    } on Object catch (error) {
      if (!context.mounted) return;
      // Camera denied, no camera, or the activity was reclaimed. The officer
      // needs the reason, because the fix is different each time.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open the camera. $error'),
          backgroundColor: EcoTraceColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = maxPhotos - photoPaths.length;
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
              '${photoPaths.length}/$maxPhotos',
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
          'Take at least $minPhotos photos of the plant. '
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
                onRemove: () => onChanged(
                  [...photoPaths]..remove(path),
                ),
              ),
            if (remaining > 0)
              _AddTile(
                onTap: () => _capture(context),
                label: 'Take photo',
              ),
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
  const _AddTile({required this.onTap, required this.label});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
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
          const Icon(Icons.photo_camera_rounded, color: Colors.white, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
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
