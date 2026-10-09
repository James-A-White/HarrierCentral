// ignore_for_file: constant_identifier_names

import 'package:hcportal/imports.dart';

// ignore: avoid_classes_with_only_static_members
class Utilities {
  static const int TIME_WINDOW = 69;

  static String generateToken(
    String publicHasherId,
    String procName, {
    String paramString = '',
  }) {
    final difference =
        DateTime.now().toUtc().difference(DateTime.utc(1963, 8, 15, 9, 52, 28));
    //final int timeBlocks = (difference.inSeconds / 5760).toInt();
    final timeBlocks = difference.inSeconds ~/ TIME_WINDOW;
    var accessString = '$publicHasherId#$procName#$timeBlocks';
    if (paramString.isNotEmpty) {
      accessString = '$publicHasherId#$procName#$timeBlocks#$paramString';
    }
    final List<int> bytes =
        utf8.encode(accessString.toUpperCase()); // data being hashed
    final digest = sha256.convert(bytes);
    return '$digest'.toUpperCase();
  }

  static Future<bool?> showAlert(
    String title,
    String body,
    String buttonText, {
    bool showCancelButton = false,
    String cancelButtonText = 'Cancel',
    TextAlign textAlign = TextAlign.justify,
  }) async {
    // An AlertDialog with the portal's own buttons: Get.defaultDialog drew
    // the Done button with no colour (James, 2026-10-09).
    return Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(
            body.replaceAll('~', '\r\n'),
            textAlign: textAlign,
            style: ts_alertDialogBody,
          ),
        ),
        actions: <Widget>[
          if (showCancelButton)
            HcButton.secondary(
              label: cancelButtonText,
              onPressed: () => Get.back<bool>(result: false),
            ),
          HcButton.primary(
            label: buttonText,
            onPressed: () => Get.back<bool>(result: true),
          ),
        ],
      ),
    );
  }
}
