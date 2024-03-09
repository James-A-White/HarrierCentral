import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

class OfflineModeRibbon extends StatelessWidget {
  const OfflineModeRibbon({
    super.key,
    required this.showRibbon,
    this.lastSync,
    required this.refreshFunction,
    this.ribbonImage = 'images/icons/offline_mode.png',
  });

  final bool showRibbon;
  final DateTime? lastSync;
  final String ribbonImage;
  final Function refreshFunction;

  @override
  Widget build(BuildContext context) {
    return !showRibbon
        ? const SizedBox.shrink()
        : Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: () async {
                bool tryReconnect = false;

                if (lastSync != null) {
                  tryReconnect = !(await Utilities.showAlert2('Offline Mode',
                          'The data displayed in this app might be out of date. The last time the app connected to the server was ${DateFormat("E, MMM d 'at' h:mm a").format(lastSync!)}', 'OK',
                          showCancelButton: true, cancelButtonText: 'Try reconnect') ??
                      false);
                } else {
                  tryReconnect = !(await Utilities.showAlert2('Offline Mode', 'The data displayed in this app might be out of date. There is no record indicating when the last sync occurred.', 'OK',
                          showCancelButton: true, cancelButtonText: 'Try reconnect') ??
                      false);
                }

                if (tryReconnect) {
                  await Utilities.checkForInternetConnection(true);

                  if (G0<AppModel>().connectionStatus == EnumConnectionStatus2.connected) {
                    await Utilities.showAlert2(
                      'Connected',
                      'You are now connected to the Internet',
                      'OK',
                    );
                    refreshFunction();
                  }
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
}
