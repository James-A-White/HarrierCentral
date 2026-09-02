// Vendored from ive_flutter_core_mobile @ eefbbc16 on 2026-09-02.
//
// Moved in-project because the 3.1 sync work has to change it: the UNIQUE
// constraint on the server primary key belongs in table creation and
// INSERT OR REPLACE belongs in the batch insert, both of which live here.
// Iterating on that across two repos behind a pinned commit hash is friction
// on every loop, and harrier_central was the only live consumer — the other,
// HarrierCentralMobile-Flutter, is the retired pre-HC6 repo.
//
// ive_flutter_core (non-mobile) is NOT vendored: four live consumers,
// including the portal, and the bug was never in it.

// Lints inherited from the vendored source, suppressed so this commit stays a
// faithful move rather than a move mixed with style edits. Worth clearing when
// these files are next opened for the 3.1 sync work — in particular the 19
// print() calls, which run on every sync in release builds too and would be
// better behind kDebugMode.
// ignore_for_file: avoid_print, no_leading_underscores_for_local_identifiers
// ignore_for_file: prefer_interpolation_to_compose_strings
// ignore_for_file: constant_identifier_names

// ignore_for_file: avoid_classes_with_only_static_members
import 'dart:async';
import 'dart:core';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:harrier_central/core_mobile/util/core_mobile_utilities.dart';

enum EnumConnectionStatus { connected, not_connected }

class Connection {
  static Future<bool> checkInternetConnection() async {
    bool connected = false;
    try {
      final List<InternetAddress> result = await InternetAddress.lookup(
        'google.com',
      );
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('connected');
        connected = true;
      }
    } on SocketException catch (_) {
      print('not connected');
      connected = false;
    }
    return connected;
  }

  static Widget styleForConnected(
    EnumConnectionStatus status,
    Widget w, {
    num borderRadius = 0.0,
  }) {
    return Container(
      foregroundDecoration:
          status == EnumConnectionStatus.connected
              ? const BoxDecoration()
              : BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius.toDouble()),
                color: Colors.grey,
                backgroundBlendMode: BlendMode.lighten,
              ),
      child: Container(
        foregroundDecoration:
            status == EnumConnectionStatus.connected
                ? const BoxDecoration()
                : const BoxDecoration(
                  color: Colors.grey,
                  backgroundBlendMode: BlendMode.saturation,
                ),
        child: w,
      ),
    );
  }

  static bool checkForConnection(
    BuildContext context,
    EnumConnectionStatus status, {
    String title = 'Offline mode',
    String message =
        'This feature is not available in offline mode. Please connect to the internet to use this feature',
  }) {
    if (status == EnumConnectionStatus.not_connected) {
      unawaited(
        IveCoreMobileUtilities.showAlert(context, title, message, 'OK'),
      );
    }
    return status == EnumConnectionStatus.connected;
  }
}
