import 'package:hcportal/imports.dart';

// ignore: avoid_classes_with_only_static_members
class CoreUtilities {
  static Future<bool?> showAlert(
    String title,
    String body,
    String buttonText, {
    bool showCancelButton = false,
    String cancelButtonText = 'Cancel',
    String? dialogImage,
    TextAlign textAlign = TextAlign.justify,
    double? width,
    double? height,
  }) async {
    return Get.defaultDialog<bool>(
      title: title,
      content: SizedBox(
        width: width,
        height: height,
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (dialogImage != null) ...<Widget>[
                Image.asset(
                  dialogImage,
                  height: 300,
                ),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
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
            ],
          ),
        ),
      ),
      actions: <Widget>[
        if (showCancelButton)
          TextButton(
            child: Text(
              cancelButtonText,
              style: ts_button,
            ),
            onPressed: () {
              Get.back(result: false);
            },
          ),
        TextButton(
          child: Text(
            buttonText,
            style: ts_button,
          ),
          onPressed: () {
            Get.back(result: true);
          },
        ),
      ],
    );
  }
}
