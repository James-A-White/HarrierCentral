import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

class OfflineModeRibbon extends StatelessWidget {
  const OfflineModeRibbon({
    super.key,
    this.lastSync,
    this.ribbonImage = 'images/icons/offline_mode.png',
    required this.refreshFunction, // called after we successfully reconnect
  });

  final DateTime? lastSync;
  final String ribbonImage;
  final VoidCallback refreshFunction;

  @override
  Widget build(BuildContext context) {
    final network = Get.find<NetworkService>();

    return Obx(() {
      // Only show when we are OFFLINE
      final isOnline = network.isOnline();
      if (isOnline) return const SizedBox.shrink();

      final lastSyncText = lastSync != null
          ? DateFormat("E, MMM d 'at' h:mm a").format(lastSync!)
          : null;

      return Positioned(
        right: 0,
        top: 0,
        child: GestureDetector(
          onTap: () async {
            // Ask the user if they want to try reconnecting
            final tryReconnect =
                !(await Utilities.showAlert2(
                      'Offline Mode',
                      lastSyncText != null
                          ? 'The data displayed in this app might be out of date. '
                                'The last time the app connected to the server was $lastSyncText.'
                          : 'The data displayed in this app might be out of date. '
                                'There is no record indicating when the last sync occurred.',
                      'OK',
                      showCancelButton: true,
                      cancelButtonText: 'Try reconnect',
                    ) ??
                    false);

            if (!tryReconnect) return;

            // Optional: keep your existing utility check if needed
            await Utilities.checkForInternetConnection(true);

            // Then force a recheck via the service (updates Rx state)
            final reconnected = await network.forceRecheck();

            if (reconnected) {
              await Utilities.showAlert2(
                'Connected',
                'You are now connected to the Internet',
                'OK',
              );
              // Trigger your reload/refresh
              refreshFunction();
            }
          },
          child: Image.asset(
            ribbonImage, // <-- now uses the provided image path
            height: 100,
            width: 100,
          ),
        ),
      );
    });
  }
}
