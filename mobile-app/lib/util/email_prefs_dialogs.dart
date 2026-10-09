import 'package:harrier_central/imports.dart';

/// The run and kennel email-preference dialogs, callable from anywhere
/// (no widget context): the links in every run email open the app straight
/// to these — `?emailPrefs=run` / `?emailPrefs=kennel` on the run URL
/// (James, 2026-10-09). The same three/two options, icons and service calls
/// as the envelope on a run card and on a kennel card.
Map<String, dynamic> _option(String title, String asset, Object returnValue) =>
    <String, dynamic>{
      'title': title,
      'icon': <Widget>[
        Container(
          height: 30,
          width: 30,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        Positioned(
          left: 3,
          top: 1.5,
          child: Image(
            width: 25.0,
            height: 25.0,
            fit: BoxFit.fill,
            image: AssetImage(asset),
          ),
        ),
      ],
      'returnValue': returnValue,
    };

const String _gold = 'images/icons/envelope_gold_50px.png';
const String _struck = 'images/icons/envelope_silver_strike_out_50px.png';
const String _silver = 'images/icons/envelope_silver_50px.png';

/// "Email options for this run": on / off / use the kennel setting.
Future<void> showRunEmailPrefsDialog(HcId eventId, {String? runTitle}) async {
  final dynamic retVal = await Get.dialog<dynamic>(
    MultipleChoicePopupHc(
      key: const Key('runemail-prefs-run'),
      title: runTitle == null
          ? 'Email options for this run'
          : 'Email options for $runTitle',
      buttons: <Map<String, dynamic>>[
        _option('Turn email\r\nmessages on', _gold, emailAlertsOn),
        _option('Turn email\r\nmessages off', _struck, emailAlertsOff),
        _option('Use Kennel setting', _silver, emailAlertsAuto),
      ],
      cancelButtonTitle: 'Cancel',
      cancelButtonReturnValue: emailAlertsUnchanged,
    ),
    barrierDismissible: false,
  );
  if (retVal != emailAlertsOn &&
      retVal != emailAlertsOff &&
      retVal != emailAlertsAuto) {
    return;
  }
  if (!Utilities.isConnected(
    showDialog: true,
    message:
        'Changing email options needs a connection. Please connect to the Internet and try again.',
  )) {
    return;
  }
  try {
    await tableModel.hasherEventMapService.setEmailAndNotificationPreferences(
      eventId,
      currentUserId,
      AppDomainType.user,
      NotificationState.unchanged,
      retVal as EnumEmailAlertState,
    );
    hcSnack(
      retVal == emailAlertsOn
          ? 'Run emails on for this run.'
          : retVal == emailAlertsOff
          ? 'Run emails off for this run.'
          : 'This run follows the kennel setting.',
    );
  } catch (e, s) {
    BootLogger.logError('[showRunEmailPrefsDialog] eventId=$eventId', e, s);
    hcSnack('That could not be saved. Try again.', error: true);
  }
}

/// "Email options for this Kennel": on / off.
Future<void> showKennelEmailPrefsDialog(
  HcId kennelId, {
  String? kennelName,
}) async {
  final dynamic retVal = await Get.dialog<dynamic>(
    MultipleChoicePopupHc(
      key: const Key('runemail-prefs-kennel'),
      title: kennelName == null
          ? 'Email options for this Kennel'
          : 'Email options for $kennelName',
      buttons: <Map<String, dynamic>>[
        _option('Turn email alerts on', _gold, emailAlertsOn),
        _option('Turn email alerts off', _struck, emailAlertsOff),
      ],
      cancelButtonTitle: 'Cancel',
      cancelButtonReturnValue: emailAlertsUnchanged,
    ),
    barrierDismissible: false,
  );
  if (retVal != emailAlertsOn && retVal != emailAlertsOff) return;
  if (!Utilities.isConnected(
    showDialog: true,
    message:
        'Setting Kennel email alerts is not available in offline mode. Please connect to the Internet to change the notification preferences for a kennel.',
  )) {
    return;
  }
  try {
    await tableModel.hasherKennelMapService.setEmailAndNotificationPreferences(
      kennelId,
      currentUserId,
      AppDomainType.user,
      NotificationState.unchanged,
      retVal as EnumEmailAlertState,
    );
    hcSnack(
      retVal == emailAlertsOn
          ? 'Run emails on for this kennel.'
          : 'Run emails off for this kennel.',
    );
  } catch (e, s) {
    BootLogger.logError(
      '[showKennelEmailPrefsDialog] kennelId=$kennelId',
      e,
      s,
    );
    hcSnack('That could not be saved. Try again.', error: true);
  }
}
