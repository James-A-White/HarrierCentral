// ignore_for_file: avoid_classes_with_only_static_members

import 'package:harrier_central/imports.dart';

enum EnumConnectionStatus2 { connected, notConnected }

class Connection2 {
  // static Future<bool> checkInternetConnection() async {
  //   bool connected = false;
  //   try {
  //     final List<InternetAddress> result = await InternetAddress.lookup(
  //       'google.com',
  //     );
  //     if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
  //       //print('connected');
  //       connected = true;
  //     }
  //   } on SocketException catch (_) {
  //     //print('not connected');
  //     connected = false;
  //   }
  //   return connected;
  // }

  static Widget styleForConnected(
    EnumConnectionStatus2 status,
    Widget w, {
    num borderRadius = 0.0,
  }) {
    return Container(
      foregroundDecoration:
          status == EnumConnectionStatus2.connected
              ? const BoxDecoration()
              : BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius.toDouble()),
                color: Colors.grey,
                backgroundBlendMode: BlendMode.lighten,
              ),
      child: Container(
        foregroundDecoration:
            status == EnumConnectionStatus2.connected
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
    EnumConnectionStatus2 status, {
    String title = 'Offline mode',
    String message =
        'This feature is not available in offline mode. Please connect to the internet to use this feature',
  }) {
    if (status == EnumConnectionStatus2.notConnected) {
      Utilities.showAlert(title, message, 'OK');
    }
    return status == EnumConnectionStatus2.connected;
  }
}
