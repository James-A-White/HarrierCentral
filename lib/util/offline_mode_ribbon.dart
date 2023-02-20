// @dart=2.11
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OfflineModeRibbon extends StatelessWidget {
  const OfflineModeRibbon({Key key, @required this.showRibbon, @required this.lastSync, this.ribbonImage = 'images/icons/offline_mode.png'}) : super(key: key);

  final bool showRibbon;
  final DateTime lastSync;
  final String ribbonImage;

  @override
  Widget build(BuildContext context) {
    return !showRibbon
        ? const SizedBox.shrink()
        : Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: () {
                if (lastSync != null) {
                  showAlert(context, 'Offline Mode',
                      'The data displayed in this app might be out of date. The last time the app connected to the server was ${DateFormat("E, MMM d 'at' h:mm a").format(lastSync)}', 'OK');
                } else {
                  showAlert(context, 'Offline Mode', 'The data displayed in this app might be out of date. There is no record indicating when the last sync occurred.', 'OK');
                }
              },
              child: Image.asset(
                'images/icons/offline_mode.png',
                height: 100,
                width: 100,
              ),
            ),
          );
  }

  static Future<bool> showAlert(BuildContext context, String title, String body, String buttonText, {bool showCancelButton = false, String cancelButtonText = 'Cancel'}) async {
    return showDialog<bool>(
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
                  textAlign: TextAlign.justify,
                  style: Theme.of(context).textTheme.titleMedium,
                )
              ],
            ),
          ),
          actions: <Widget>[
            showCancelButton == true
                ? TextButton(
                    child: Text(cancelButtonText),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                  )
                : Container(),
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
