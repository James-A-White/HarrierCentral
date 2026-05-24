import 'dart:async';

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
/// While loading, a count-up number (0–9, 1 second per tick) is shown inside
/// the screen area so the user can see that loading is in progress.
/// When [photoUrl] is null the widget shows the static empty camera frame.
class CameraPhotoMarker extends StatefulWidget {
  const CameraPhotoMarker({
    super.key,
    required this.photoUrl,
    required this.size,
    this.cachedOrientation,
    this.onOrientationDetected,
  });

  /// Full HTTPS URL of the photo. Null shows the static empty camera frame.
  final String? photoUrl;

  /// The width and height of the square marker widget in logical pixels.
  final double size;

  /// Pre-resolved orientation from the controller cache. When non-null the
  /// widget skips detection and renders immediately without a loading state.
  final bool? cachedOrientation;

  /// Called the first time orientation is detected so the controller can
  /// cache it and skip detection on subsequent rebuilds.
  final void Function(String url, bool isLandscape)? onOrientationDetected;

  @override
  State<CameraPhotoMarker> createState() => _CameraPhotoMarkerState();
}

class _CameraPhotoMarkerState extends State<CameraPhotoMarker> {
  bool? _isLandscape;
  ImageStream? _stream;
  ImageStreamListener? _listener;
  Timer? _countTimer;
  int _loadingCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.cachedOrientation != null) {
      _isLandscape = widget.cachedOrientation;
    } else if (widget.photoUrl != null) {
      _startDetection();
    }
  }

  @override
  void didUpdateWidget(CameraPhotoMarker old) {
    super.didUpdateWidget(old);
    if (old.photoUrl != widget.photoUrl) {
      _cancelDetection();
      if (widget.cachedOrientation != null) {
        setState(() {
          _isLandscape = widget.cachedOrientation;
          _loadingCount = 0;
        });
      } else {
        setState(() {
          _isLandscape = null;
          _loadingCount = 0;
        });
        if (widget.photoUrl != null) _startDetection();
      }
    }
  }

  @override
  void dispose() {
    _cancelDetection();
    super.dispose();
  }

  void _startDetection() {
    _listener = ImageStreamListener(_onLoaded, onError: _onError);
    // photoUrl is guaranteed non-null — only called from the null-guard above
    _stream = NetworkImage(widget.photoUrl!).resolve(ImageConfiguration.empty);
    _stream!.addListener(_listener!);

    _countTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_loadingCount >= 9) {
        timer.cancel();
        return;
      }
      setState(() => _loadingCount++);
    });
  }

  void _cancelDetection() {
    if (_listener != null && _stream != null) {
      _stream!.removeListener(_listener!);
    }
    _listener = null;
    _stream = null;
    _countTimer?.cancel();
    _countTimer = null;
  }

  void _onLoaded(ImageInfo info, bool _) {
    _cancelDetection();
    if (mounted) {
      final bool isLandscape = info.image.width >= info.image.height;
      setState(() => _isLandscape = isLandscape);
      if (widget.photoUrl != null) {
        widget.onOrientationDetected?.call(widget.photoUrl!, isLandscape);
      }
    }
  }

  void _onError(Object error, StackTrace? stack) {
    _cancelDetection();
    if (mounted) setState(() => _isLandscape = true); // fallback: landscape frame
  }

  @override
  Widget build(BuildContext context) {
    final double s = widget.size;

    // ── No URL — static empty camera frame ───────────────────────────────────
    if (_isLandscape == null && widget.photoUrl == null) {
      return Image.asset(
        'images/map_pins/other/camera_landscape.png',
        width: s,
        height: s,
        fit: BoxFit.fill,
      );
    }

    // ── Screen-area coordinates derived from pixel analysis of the 400×400 PNGs
    // Landscape: transparent cutout at x=27–286, y=71–270 in source coords.
    // Portrait : transparent cutout at x=117–283, y=87–301 in source coords.
    // bleed expands the photo rect beyond the cutout edge on all sides so no
    // background pixel shows between the photo and the frame's zero-alpha area.
    final bool landscape = _isLandscape ?? true; // default landscape while loading
    const double bleedFactor = 0.015; // ~1.5 % of marker size per side
    final double bleed = s * bleedFactor;
    final double photoLeft = (landscape ? s * 0.0675 : s * 0.2925) - bleed;
    final double photoTop  = (landscape ? s * 0.1775 : s * 0.2175) - bleed;
    final double photoW    = (landscape ? s * 0.6475 : s * 0.4150) + bleed * 2;
    final double photoH    = (landscape ? s * 0.4975 : s * 0.5350) + bleed * 2;

    // ── Content for the screen area ───────────────────────────────────────────
    Widget screenContent;

    if (_isLandscape == null) {
      // Loading: count-up number centred in the screen area
      screenContent = Container(
        color: Colors.white.withValues(alpha: 0.55),
        alignment: Alignment.center,
        child: Text(
          '$_loadingCount',
          style: TextStyle(
            fontSize: s * 0.30,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
            height: 1.0,
          ),
        ),
      );
    } else {
      // Loaded: photo thumbnail (or grey box on network error)
      // photoUrl is non-null here — _isLandscape is only set after
      // _startDetection() fires, which requires a non-null photoUrl
      screenContent = Image.network(
        widget.photoUrl!,
        width: photoW,
        height: photoH,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) =>
            ColoredBox(color: Colors.grey.shade400),
      );
    }

    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        children: [
          Positioned(
            left: photoLeft,
            top: photoTop,
            width: photoW,
            height: photoH,
            child: screenContent,
          ),
          // Camera frame on top — opaque body masks edges, transparent screen
          // lets the content show through
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
