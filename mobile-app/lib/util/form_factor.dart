import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Device form-factor helpers.
///
/// The app was designed phone-first and portrait-locked. Tablets (iPad,
/// unfolded foldables, Android tablets) run it at full width and in any
/// orientation, so a few layout decisions need to know which class of device
/// they are on. Everything keys off the Material "600dp shortest side" rule —
/// the same threshold Android uses for its large-screen behaviour.
///
/// Prefer the [BuildContext] extension (`context.isTabletWindow`) inside widgets: it
/// reacts to window resizing (iPadOS split view / windowing). Use
/// [FormFactor.isTabletDevice] only where there is no context yet — e.g. the
/// orientation lock in `main()`.
class FormFactor {
  FormFactor._();

  /// Material breakpoint between phones and tablets (logical pixels).
  static const double tabletShortestSide = 600.0;

  /// Largest QR code we render. A `QrImageView` with no size fills its
  /// parent, which on a tablet means ~1000pt — far past what a scanner needs.
  static const double maxQrSize = 520.0;

  /// Physical-device check that does not need a [BuildContext]. Reads the
  /// first view's size, so it is valid from `main()` onwards.
  static bool get isTabletDevice {
    final ui.FlutterView? view =
        WidgetsBinding.instance.platformDispatcher.implicitView;
    if (view == null) return false;
    final ui.Size logical = view.physicalSize / view.devicePixelRatio;
    return logical.shortestSide >= tabletShortestSide;
  }

  /// Orientations to allow. Phones stay portrait-only (the UI was designed
  /// for it); tablets get every orientation because iPadOS expects native
  /// iPad apps to rotate, and Android 16 ignores the lock on large screens
  /// anyway.
  static List<DeviceOrientation> get preferredOrientations => isTabletDevice
      ? const <DeviceOrientation>[
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]
      : const <DeviceOrientation>[DeviceOrientation.portraitUp];
}

/// Named `…Window` to avoid clashing with GetX's `context.isTablet` /
/// `context.isLandscape` extensions (same name ⇒ ambiguous_extension_member_access).
extension FormFactorContext on BuildContext {
  /// True when the current window's shortest side is tablet-class. Uses the
  /// window size (not the device), so a phone-sized iPad split-view window
  /// correctly reports `false`.
  bool get isTabletWindow =>
      MediaQuery.sizeOf(this).shortestSide >= FormFactor.tabletShortestSide;

  /// True when the window is wider than it is tall.
  bool get isLandscapeWindow =>
      MediaQuery.orientationOf(this) == Orientation.landscape;
}
