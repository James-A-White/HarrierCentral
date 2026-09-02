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

import 'dart:async';
import 'package:flutter/material.dart';

// ignore: avoid_classes_with_only_static_members
class IveCoreMobileUtilities {
  static Future<bool?> showAlert(
    BuildContext context,
    String title,
    String body,
    String buttonText, {
    bool showCancelButton = false,
    String cancelButtonText = 'Cancel',
    TextAlign textAlign = TextAlign.justify,
  }) async {
    return showDialog<bool?>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  body,
                  textAlign: textAlign,
                  style: const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 16.0, height: 1.0),
                )
              ],
            ),
          ),
          actions: <Widget>[
            if (showCancelButton)
              TextButton(
                child: Text(cancelButtonText),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              )
            else
              Container(),
            TextButton(
              child: Text(buttonText),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }
}
