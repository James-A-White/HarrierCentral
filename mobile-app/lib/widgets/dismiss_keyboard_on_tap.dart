import 'package:flutter/material.dart';

/// A tap on empty space puts the keyboard away (2026-09-28).
///
/// iOS number pads have no Done key, and a TextField only dismisses on an
/// outside tap from a MOUSE, so 16 number fields held the keyboard up with no
/// way down — Payment options' top up among them (Kilty as Charged). Wrapped
/// round the whole app in main.dart, so every page and dialog gets it.
///
/// Buttons, fields, maps and lists claim their own taps first, so this only
/// fires where nothing else wanted the tap; a drag is never a tap.
class DismissKeyboardOnTap extends StatelessWidget {
  const DismissKeyboardOnTap({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
    child: child,
  );
}
