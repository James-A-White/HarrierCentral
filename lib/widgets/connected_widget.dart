import 'package:harrier_central/imports.dart';

class ConnectedWidget extends StatelessWidget {
  const ConnectedWidget({
    super.key,
    required this.child,
    this.disconnectedChild,
    this.showConnectButton = false,
    this.showHcBackground = false,
    this.refreshFunction,
    this.padding,
  });

  final Widget child;
  final Widget? disconnectedChild;
  final bool showConnectButton;
  final bool showHcBackground;
  final Function? refreshFunction;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus2.notConnected) {
      if (showHcBackground) {
        return Container(
          decoration: Backgrounds.defaultHcBackground(),
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (disconnectedChild != null) ...<Widget>[disconnectedChild!],
                if (showConnectButton) ...<Widget>[_connectButton()],
              ],
            ),
          ),
        );
      } else {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (disconnectedChild != null) ...<Widget>[disconnectedChild!],
            if (showConnectButton) ...<Widget>[_connectButton()],
          ],
        );
      }
    } else {
      return child;
    }
  }

  Widget _connectButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.only(top: 8, bottom: 8, left: 20, right: 20),
      ),
      onPressed: () async {
        await _attemptReconnect();
      },
      child: Text(
        'Attempt to Connect',
        style: ts_button,
      ),
    );
  }

  Future<void> _attemptReconnect() async {
    await Utilities.checkForInternetConnection(true);

    if (G0<AppModel>().connectionStatus == EnumConnectionStatus2.connected) {
      await Utilities.showAlert2(
        'Connected',
        'You are now connected to the Internet',
        'OK',
      );
      if (refreshFunction != null) {
        refreshFunction!();
      }
    }
  }
}
