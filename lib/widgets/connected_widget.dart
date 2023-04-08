import 'package:harrier_central/imports.dart';

class ConnectedWidget extends StatelessWidget {
  const ConnectedWidget({
    Key? key,
    required this.child,
    this.disconnectedChild,
    this.showConnectButton = false,
    this.showHcBackground = false,
    this.refreshFunction,
    this.padding,
  }) : super(key: key);

  final Widget child;
  final Widget? disconnectedChild;
  final bool showConnectButton;
  final bool showHcBackground;
  final Function? refreshFunction;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected) {
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
        style: textStyleButton,
      ),
    );
  }

  Future<void> _attemptReconnect() async {
    await Utilities.checkForInternetConnection(true);

    if (G0<AppModel>().connectionStatus == EnumConnectionStatus.connected) {
      await Utilities.showAlert(
        navigatorKey.currentContext!,
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
