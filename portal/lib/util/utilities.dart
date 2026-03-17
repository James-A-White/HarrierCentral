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
    return Get.defaultDialog(
      title: title,
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text(
              body.replaceAll('~', '\r\n'),
              textAlign: textAlign,
              style: ts_alertDialogBody,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        if (showCancelButton)
          ElevatedButton(
            style: defaultButtonStyle,
            onPressed: () {
              Get.back(result: false);
            },
            child: Text(
              cancelButtonText,
              style: ts_button,
            ),
          )
        else
          Container(),
        ElevatedButton(
          style: defaultButtonStyle,
          onPressed: () {
            Get.back(result: true);
          },
          child: Text(
            buttonText,
            style: ts_button,
          ),
        )
      ],
    );
  }
}
