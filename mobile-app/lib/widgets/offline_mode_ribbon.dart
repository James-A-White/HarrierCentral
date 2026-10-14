import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

/// True while "Try reconnect" is checking: a second tap is ignored.
bool _reconnecting = false;

class OfflineModeRibbon extends StatelessWidget {
  const OfflineModeRibbon({
    super.key,
    this.lastSync,
    this.ribbonImage = 'images/icons/offline_mode.png',
    required this.refreshFunction,
  });

  final DateTime? lastSync;
  final String ribbonImage;
  final VoidCallback refreshFunction;

  @override
  Widget build(BuildContext context) {
    final network = Get.find<NetworkService>();

    return Obx(() {
      final internet = network.hasInternet.value;
      final backend = network.backendReachable.value;

      if (internet && backend) return const SizedBox.shrink();

      // backend-only unavailable: internet up but HC server not yet reachable
      final backendOnly = internet && !backend;

      return Positioned(
        right: 0,
        top: 0,
        child: GestureDetector(
          onTap: () async {
            final String title = backendOnly ? 'Server Unavailable' : 'Offline Mode';
            final String body = backendOnly
                ? 'The app is connected to the internet but cannot reach the '
                    'Harrier Central server. This may be a temporary outage.\n\n'
                    'Tap "Try Reconnect" to check again.'
                : lastSync != null
                    ? 'The data displayed in this app might be out of date. '
                        'The last time the app connected to the server was '
                        '${DateFormat("E, MMM d 'at' h:mm a").format(lastSync!)}.'
                    : 'The data displayed in this app might be out of date. '
                        'There is no record indicating when the last sync occurred.';

            final tryReconnect =
                !(await Utilities.showAlert2(
                      title,
                      body,
                      'OK',
                      showCancelButton: true,
                      cancelButtonText: 'Try reconnect',
                    ) ??
                    false);

            if (!tryReconnect || _reconnecting) return;

            // Say so at once: the check can take several seconds.
            _reconnecting = true;
            hcSnack('Trying to reconnect…', seconds: 15);
            final bool reconnected;
            try {
              reconnected = await network.forceRecheck();
            } finally {
              _reconnecting = false;
              closeAllSnackbarsSafely();
            }

            if (!reconnected) {
              hcSnack('Still offline. Try again in a moment.', error: true);
            } else {
              await Utilities.showAlert2(
                'Connected',
                'You are now connected to Harrier Central.',
                'OK',
              );
              refreshFunction();
            }
          },
          child: Image.asset(
            ribbonImage,
            height: 100,
            width: 100,
          ),
        ),
      );
    });
  }
}
