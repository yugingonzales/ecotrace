import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../models/map_tree.dart';

/// Opens the photo gallery for [tree] as a modal bottom sheet.
///
/// Modal (not a pushed route) so the map stays mounted underneath: dismissing
/// the gallery returns straight to the still-open tree details card.
Future<void> showTreePhotoGallery(BuildContext context, MapTree tree) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x8C000000),
      builder: (_) => TreePhotoGallerySheet(tree: tree),
    );

/// Renders a tree photo from either a bundled asset path or a remote URL.
///
/// The current placeholder is a bundled asset while real documentation photos
/// will arrive from the admin portal over HTTP, so both sources must render.
class TreePhotoImage extends StatelessWidget {
  const TreePhotoImage({
    super.key,
    required this.photo,
    this.fit = BoxFit.contain,
  });

  final String photo;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => photo.startsWith('http')
      ? Image.network(photo, fit: fit, errorBuilder: _onError)
      : Image.asset(photo, fit: fit, errorBuilder: _onError);
}

/// Tappable cover photo for the details card.
///
/// Shows only the first photo so the card stays scannable; tapping it hands off
/// to the full gallery. `tree.photosList` is never empty, so there is no
/// empty-state branch here.
class TreePhotoCover extends StatelessWidget {
  const TreePhotoCover({super.key, required this.tree, required this.onTap});

  final MapTree tree;
  final VoidCallback onTap;

  /// Fixed height (rather than a 16:9 box) so the cover cannot push the action
  /// buttons off a short screen — the details card scrolls instead.
  static const double _height = 140;

  @override
  Widget build(BuildContext context) {
    final photos = tree.photosList;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: _height,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                TreePhotoImage(photo: photos.first, fit: BoxFit.cover),
                // Bottom scrim keeps the labels legible over bright photos.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0x8A000000)],
                      stops: [0.5, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  bottom: 8,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.photo_camera_back_outlined,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        photos.length > 1
                            ? '${photos.length} photos'
                            : 'Documentation photo',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View all',
                          style: TextStyle(
                            color: EcoTraceColors.forest,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(
                          Icons.open_in_full_rounded,
                          size: 11,
                          color: EcoTraceColors.forest,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown when a photo path fails to resolve, so a bad URL degrades to a
/// neutral tile instead of the red-and-yellow debug box.
Widget _onError(BuildContext context, Object error, StackTrace? stackTrace) =>
    const ColoredBox(
      color: EcoTraceColors.canvas,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 28,
          color: EcoTraceColors.muted,
        ),
      ),
    );

/// Swipeable, pinch-zoomable viewer for every documentation photo of a tree.
class TreePhotoGallerySheet extends StatefulWidget {
  const TreePhotoGallerySheet({super.key, required this.tree});

  final MapTree tree;

  @override
  State<TreePhotoGallerySheet> createState() => _TreePhotoGallerySheetState();
}

class _TreePhotoGallerySheetState extends State<TreePhotoGallerySheet> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.tree.photosList;
    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 34,
              height: 4,
              decoration: BoxDecoration(
                color: EcoTraceColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'DOCUMENTATION',
                          style: TextStyle(
                            color: Color(0xFF7A9185),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.tree.id} · ${widget.tree.species}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: EcoTraceColors.forest,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 22),
                    color: EcoTraceColors.forest,
                    tooltip: 'Close gallery',
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: photos.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => InteractiveViewer(
                  maxScale: 4,
                  child: Center(child: TreePhotoImage(photo: photos[i])),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_index + 1} / ${photos.length}',
                    style: const TextStyle(
                      color: EcoTraceColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (photos.length > 1) ...[
                    const SizedBox(width: 12),
                    for (var i = 0; i < photos.length; i++)
                      Container(
                        width: i == _index ? 16 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i == _index
                              ? EcoTraceColors.forest
                              : EcoTraceColors.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
