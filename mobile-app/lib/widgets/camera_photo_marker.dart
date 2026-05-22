import 'package:flutter/material.dart';

/// A map marker widget that renders a photo thumbnail inside a camera-shaped
/// map-pin frame.
///
/// The frame PNG (landscape or portrait) has a transparent cutout where the
/// camera LCD screen would be. The thumbnail is placed behind the frame,
/// aligned to that cutout, so it appears to be displayed on the camera screen.
///
/// Orientation is detected from the loaded image's pixel dimensions:
///   • width ≥ height → landscape frame  (camera_landscape.png)
///   • width <  height → portrait frame   (camera_portrait.png)
///
/// While the image is loading, the landscape frame is shown as a placeholder.
/// On network error the placeholder remains, preventing a blank marker.
class CameraPhotoMarker extends StatefulWidget {
  const CameraPhotoMarker({
    super.key,
    required this.photoUrl,
    required this.size,
  });

  final String photoUrl;

  /// The width and height of the square marker widget in logical pixels.
  final double size;

  @override
  State<CameraPhotoMarker> createState() => _CameraPhotoMarkerState();
}

class _CameraPhotoMarkerState extends State<CameraPhotoMarker> {
  bool? _isLandscape; // null = still loading
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void initState() {
    super.initState();
    _startDetection();
  }

  @override
  void didUpdateWidget(CameraPhotoMarker old) {
    super.didUpdateWidget(old);
    if (old.photoUrl != widget.photoUrl) {
      _cancelDetection();
      setState(() => _isLandscape = null);
      _startDetection();
    }
  }

  @override
  void dispose() {
    _cancelDetection();
    super.dispose();
  }

  void _startDetection() {
    _listener = ImageStreamListener(_onLoaded, onError: _onError);
    _stream = NetworkImage(widget.photoUrl).resolve(ImageConfiguration.empty);
    _stream!.addListener(_listener!);
  }

  void _cancelDetection() {
    if (_listener != null && _stream != null) {
      _stream!.removeListener(_listener!);
    }
    _listener = null;
    _stream = null;
  }

  void _onLoaded(ImageInfo info, bool _) {
    _cancelDetection();
    if (mounted) {
      setState(() {
        _isLandscape = info.image.width >= info.image.height;
      });
    }
  }

  void _onError(Object error, StackTrace? stack) {
    _cancelDetection();
    if (mounted) setState(() => _isLandscape = true); // fallback: landscape frame
  }

  @override
  Widget build(BuildContext context) {
    final double s = widget.size;

    // ── Placeholder while orientation is still being resolved ────────────────
    if (_isLandscape == null) {
      return Image.asset(
        'images/map_pins/other/camera_landscape.png',
        width: s,
        height: s,
        fit: BoxFit.fill,
      );
    }

    final bool landscape = _isLandscape!;

    // ── Screen-area coordinates derived from pixel analysis of the 400×400 PNGs
    // Landscape: transparent cutout at x=27–286, y=71–270 in source coords.
    // Portrait : transparent cutout at x=117–283, y=87–301 in source coords.
    final double photoLeft = landscape ? s * 0.0675 : s * 0.2925;
    final double photoTop = landscape ? s * 0.1775 : s * 0.2175;
    final double photoW = landscape ? s * 0.6475 : s * 0.4150;
    final double photoH = landscape ? s * 0.4975 : s * 0.5350;

    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        children: [
          // Thumbnail — rendered behind the frame, clipped to the screen area
          Positioned(
            left: photoLeft,
            top: photoTop,
            width: photoW,
            height: photoH,
            child: Image.network(
              widget.photoUrl,
              width: photoW,
              height: photoH,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) =>
                  ColoredBox(color: Colors.grey.shade400),
            ),
          ),
          // Camera frame on top — opaque body masks edges, transparent screen
          // lets the thumbnail show through
          Positioned.fill(
            child: Image.asset(
              landscape
                  ? 'images/map_pins/other/camera_landscape.png'
                  : 'images/map_pins/other/camera_portrait.png',
              fit: BoxFit.fill,
            ),
          ),
        ],
      ),
    );
  }
}
