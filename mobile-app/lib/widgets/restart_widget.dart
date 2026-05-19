// restart_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:harrier_central/util/safe_set_state.dart';

final GlobalKey<RestartWidgetState> restartKey =
    GlobalKey<RestartWidgetState>();

class RestartWidget extends StatefulWidget {
  final Widget child;
  const RestartWidget({super.key, required this.child});

  @override
  State<RestartWidget> createState() => RestartWidgetState();
}

class RestartWidgetState extends State<RestartWidget> {
  // Use a Key to force the child to rebuild when changed.
  Key key = UniqueKey();

  // The flag determines which child is currently visible.
  bool showApp = true;

  void restartApp() {
    // 1. Unmount the RootApp immediately by switching to the placeholder.
    setStateIfMounted(() {
      showApp = false; // This swaps RootApp with SizedBox.shrink()
    });

    // 2. Schedule the re-creation of the RootApp.
    // We use a small delay combined with a microtask to ensure the unmounting
    // and disposal (including the rogue GetMaterialController) is complete.
    unawaited(
      Future.microtask(() {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            setStateIfMounted(() {
              key = UniqueKey(); // Generate a new key for the new RootApp
              showApp = true; // Show the RootApp again
            });
          }
        });
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (showApp) {
      // When showApp is true, we display the RootApp with a new key
      return KeyedSubtree(
        key: key,
        child: widget.child, // This is RootApp()
      );
    } else {
      // When showApp is false, we display an empty widget (tearing down GetMaterialApp)
      return const SizedBox.shrink();
      // You could also show a small loading indicator here
    }
  }
}
