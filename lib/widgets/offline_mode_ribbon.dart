import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/util/preferences.dart';

class OfflineModeRibbon extends StatelessWidget {
  const OfflineModeRibbon();

  @override
  Widget build(BuildContext context) {
    return Container();
    // return globalConnectionStatus == connectionStatus_notConnected
    //     ? Positioned(
    //         right: 0,
    //         top: 0,
    //         child: GestureDetector(
    //           onTap: () {
    //             final int lastSyncInt = getIntPref(IntPrefsEnum.lastSuccessfulUserDataSync);

    //             if (lastSyncInt != null) {
    //               final DateTime lastSync = DateTime.fromMillisecondsSinceEpoch(lastSyncInt);
    //               Utilities.showAlert(context, 'Offline Mode', 'The data displayed in the Harrier Central app might be out of date. The last time the app connected to the server was ${DateFormat("E, MMM d \'at\' h:mm a").format(lastSync)}', 'OK');
    //             } else {
    //               Utilities.showAlert(context, 'Offline Mode', 'The data displayed in the Harrier Central app might be out of date. There is no record indicating when the last sync occurred.', 'OK');
    //             }
    //           },
    //           child: Image.asset(
    //             'images/icons/offline_mode.png',
    //             height: 120,
    //             width: 120,
    //           ),
    //         ),
    //       )
    //     : Container();
  }
}
