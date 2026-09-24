import 'package:flutter/material.dart';

/// Keeps a TabBarView / PageView child mounted while it is off screen.
///
/// A page that moved to a GetX controller loses the AutomaticKeepAlive its
/// State used to provide, and a TabBarView then disposes it on every swipe
/// away. For most tabs that is harmless; for one that owns a camera preview
/// it is not — mobile_scanner stops the camera on unmount and starts it
/// again on remount, and a start() while the previous start is still in
/// flight throws (seen 2026-09-24 on the check-in scanner tab). This is the
/// keep-alive shell on its own: no state of its own, no business logic.
class KeepAliveTab extends StatefulWidget {
  const KeepAliveTab({super.key, required this.child});

  final Widget child;

  @override
  State<KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
