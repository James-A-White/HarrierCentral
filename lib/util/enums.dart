// ignore_for_file: constant_identifier_names

import 'package:harrier_central/imports.dart';

enum EnumAppPages {
  settings,
  futureRuns,
  kennelList,
  runCounts,
  qrCodePage,
  friends,
  fab,
}

enum StringPrefsEnum {
  adminEventId,
  adminKennelId,
  androidDownloadLink,
  apnsToken,
  bootType,
  customEmailBody,
  deviceId,
  deviceSecret,
  displayName,
  email,
  facebookProfilePhoto,
  fcmToken,
  firstName,
  gender,
  harrierCentralPreviousVersion,
  harrierCentralVersion,
  harrierCentralVersionAndBuild,
  hashName,
  homeKennelId,
  imageRootUrl,
  iosDownloadLink,
  lastName,
  leaderboardJson,
  mapPreference,
  paymentTerminalAccountKey,
  profilePhotoUrl,
  publicHasherId,
  qrCode,
  qrSecretCode,
  resetCode,
  splashSequenceRootName,
  splashSequenceRootNameViewed,
  ssoAuthType,
  supportCode,
  thirdPartyAccessToken,
  thirdPartyAuthorizationCode,
  thirdPartyEmail,
  thirdPartyForceTokenRefresh,
  thirdPartyLoginEmail,
  thirdPartyLoginType,
  thirdPartyUserId,
  userId,
}

enum NumPrefsEnum {
  currentDeviceLat,
  currentDeviceLon,
  homeKennelLat,
  homeKennelLon,
}

enum BoolPrefsEnum {
  notificationPreferencesRequested,
  fcmTokenSavedToServer,
  automaticallySetNotifiationPrefs,
}

enum IntPrefsEnum {
  databaseVersion,
  hasherPreferences,
  timeWindow,
  //lastSuccessfulUserDataSyncInMs,
  //hasLocationPermissions,
  mapCenterOption,
  mapShowSearchBar,
  mapShowKennels,
  isBetaTester,
  isResettingCache,
  splashSequenceType,
  //isLoggingOutOfFacebook,
  //usePlatformNativeMapApp,
}

enum DatePrefsEnum {
  lastSuccessfulUserDataSyncAsDate,
  // lastFbTokenUpdate,
  // fbLoginCancelled,
  thirdPartyTokenLastUpdated,
  thirdPartyTokenExpires,
  lastLocationUpdate,
  lastLeaderboardUpdate,
  lastRunStartCheck,
  splashSequenceViewedAt, // this value gets erased once it is reported to the server
  lastSplashSequenceDisplayed, // this value is retained over time and can be used to calculate splash delay intervals
}

enum MapPrefsEnum { chatCounts }

enum TriStateFilter { neutral, include, exclude }

/// Chat tabs with their corresponding integer IDs.
enum RunsToDisplay {
  allRuns(
    0,
    '~ Runs',
    1,
    4,
    true,
    true,
    'All Runs View',
    'Welcome to the default view! Here you’ll find all upcoming Hash runs from across the globe, sorted so it’s easy to spot what’s happening near you — at home or while traveling.\r\n\r\nSwitch to past runs to browse your Kennels’ history: you’ll see every run from the Kennels you follow, plus the last 30 days of runs from all others. Use the search tool to dig even deeper into your Hashing adventures!',
  ),
  myRuns(
    1,
    'My ~ Runs',
    2,
    0,
    true,
    true,
    'My Runs View',
    'Want to relive your favorite trails? This view lets you scroll through all the runs you’ve RSVPed for or attended.\r\n\r\nRead the original run descriptions, see who else was there, view run artwork, and dive back into those unforgettable Hashing moments!',
  ),
  unreadChats(
    2,
    'Unseen Chats',
    3,
    1,
    false,
    false,
    'Unread Chats View',
    'This view shows only runs with new chat messages you haven’t read yet, keeping you up to date on the latest info — whether the run is today or months away.\r\n\r\nTrail Chat keeps everything organized: every run has its own chat thread, so no more losing important trail information inside noisy WhatsApp groups!',
  ),
  events(
    3,
    '~ Events',
    4,
    2,
    true,
    true,
    'Special Events View',
    'Ready to see what’s happening in the global Hashing world?\r\n\r\nScroll through special events hosted by Kennels everywhere. Whether you’re planning your next trip or just curious what’s coming up, this is your ticket to unforgettable Hash experiences!',
  ),
  onMap(
    4,
    'Runs on Map',
    0,
    3,
    true,
    false,
    'Map View',
    'Want to find runs in a specific area? The Map View is just what you need.\r\n\r\nYou can zoom and scroll to any location — from a single city block to an entire continent — and when you switch back to the runs list, it will display all runs within that area.\r\n\r\nIt’s also a great tool for planning your next trail by spotting places that haven’t seen a Hash run in a while.',
  );

  /// The integer ID associated with this tab.
  final int id;
  final String label;
  final int next;
  final int previous;
  final bool showFuturePastToggle;
  final bool defaultViewIsFuture;

  final String helpTitle;
  final String helpText;

  const RunsToDisplay(
    this.id,
    this.label,
    this.next,
    this.previous,
    this.showFuturePastToggle,
    this.defaultViewIsFuture,

    this.helpTitle,
    this.helpText,
  );

  /// Lookup a MessageType by its [id]. Throws if not found.
  factory RunsToDisplay.fromId(int id) {
    return RunsToDisplay.values.firstWhere(
      (tab) => tab.id == id,
      orElse: () => throw ArgumentError('No Run type with id $id'),
    );
  }
}

/// Chat tabs with their corresponding integer IDs.
enum SortType {
  forFutureRuns(0, 'Future', 1),
  forPastRuns(1, 'Past', 0);

  /// The integer ID associated with this tab.
  final int id;
  final String label;
  final int next;

  const SortType(this.id, this.label, this.next);

  /// Lookup a MessageType by its [id]. Throws if not found.
  factory SortType.fromId(int id) {
    return SortType.values.firstWhere(
      (tab) => tab.id == id,
      orElse: () => throw ArgumentError('No Run type with id $id'),
    );
  }
}

/// Chat tabs with their corresponding integer IDs.
enum RunsTimeScope {
  future(0, 'Future', 1),
  past(1, 'Past', 0),
  all(
    2,
    'All',
    0,
  ); // the button rotation should never get here, but if it does revert back to future.

  /// The integer ID associated with this tab.
  final int id;
  final String label;
  final int next;

  const RunsTimeScope(this.id, this.label, this.next);

  /// Lookup a MessageType by its [id]. Throws if not found.
  factory RunsTimeScope.fromId(int id) {
    return RunsTimeScope.values.firstWhere(
      (tab) => tab.id == id,
      orElse: () => throw ArgumentError('No Run type with id $id'),
    );
  }
}

/// Chat tabs with their corresponding integer IDs.
enum MessageType {
  chat(0),
  checkinReminder(1),
  rsvpReminder(2);

  /// The integer ID associated with this tab.
  final int id;

  const MessageType(this.id);

  /// Lookup a MessageType by its [id]. Throws if not found.
  factory MessageType.fromId(int id) {
    return MessageType.values.firstWhere(
      (tab) => tab.id == id,
      orElse: () => throw ArgumentError('No ChatTab with id $id'),
    );
  }
}

/// Splash screen types with their corresponding integer IDs.

enum SplashSequenceType {
  unknown(0, 0),
  urgentAnnouncement(100, 0),
  kennelPromotion(200, 0),
  trainingContent(300, 36);

  /// The integer ID associated with this tab.
  final int id;

  /// This indicates how many hours must pass since the last splash
  /// screen was displayed before this splash screen will be displayed.
  /// This is important for splash screen types such as training, where
  /// we don't want to bother the user with a new splash screen every time
  /// they open the app
  final int delayInHours;

  const SplashSequenceType(this.id, this.delayInHours);

  /// Lookup a SplashSequenceType by its [id]. Throws if not found.
  factory SplashSequenceType.fromId(int id) {
    return SplashSequenceType.values.firstWhere(
      (tab) => tab.id == id,
      orElse: () => throw ArgumentError('No SplashSequenceType with id $id'),
    );
  }
}

enum ThirdPartyLoginType { apple, facebook, none }

enum EnumDataContext { user, event, kennel }

abstract class HcEnum<T> {
  const HcEnum(this._value);
  final T _value;
  T get value => _value;
}

// class EnumQrTypes<String> extends Enum<String> {
//   const EnumQrTypes(String val) : super(val);
// }

// const EnumQrTypes<String> enumQrPrefix_userQrCode = EnumQrTypes<String>('UQR:');
// const EnumQrTypes<String> enumQrPrefix_userSecretCode = EnumQrTypes<String>('USC:');
// const EnumQrTypes<String> enumQrPrefix_userResetCode = EnumQrTypes<String>('URC:');
// const EnumQrTypes<String> enumQrPrefix_specificRunStart = EnumQrTypes<String>('SRS:');
// const EnumQrTypes<String> enumQrPrefix_specificRunEnd = EnumQrTypes<String>('SRE:');
// const EnumQrTypes<String> enumQrPrefix_kennelGenericRunStart = EnumQrTypes<String>('KRS:');
// const EnumQrTypes<String> enumQrPrefix_kennelGenericRunEnd = EnumQrTypes<String>('KRE:');

//////////////////////////

class EnumVirginVisitor extends HcEnum<int> {
  const EnumVirginVisitor(super.val);
}

const EnumVirginVisitor enumHasher = EnumVirginVisitor(0);
const EnumVirginVisitor enumVirgin = EnumVirginVisitor(1);
const EnumVirginVisitor enumAnonymousVisitor = EnumVirginVisitor(2);
const EnumVirginVisitor enumKnownVisitor = EnumVirginVisitor(3);

//////////////////////////
///
// class EnumNotificationState<int> extends HcEnum<int> {
//   const EnumNotificationState(super.val);
//}

// const EnumNotificationState<int> NotificationState.unchanged =
//     EnumNotificationState<int>(-1);
// const EnumNotificationState<int> NotificationState.auto =
//     EnumNotificationState<int>(0);
// const EnumNotificationState<int> NotificationState.on =
//     EnumNotificationState<int>(1);
// const EnumNotificationState<int> NotificationState.ignore =
//     EnumNotificationState<int>(2);
// const EnumNotificationState<int> NotificationState.mute =
//     EnumNotificationState<int>(3);
// const EnumNotificationState<int> NotificationState.onBeforeRun =
//     EnumNotificationState<int>(4);

enum NotificationState {
  unchanged(-1),
  auto(0), // use the kennel default setting
  on(1), // always notify
  ignore(2), // never notify
  mute(3), //
  onBeforeRun(4); // notify only before the run starts

  final int value;

  const NotificationState(this.value);

  static final Map<int, NotificationState> _valueMap = {
    for (var state in NotificationState.values) state.value: state,
  };

  static NotificationState? fromInt(int value) => _valueMap[value];
}

enum EventType {
  unknown(0, 'Unknown event'), // use the kennel default setting
  localNormal(1, 'Normal run'), // use the kennel default setting
  localEvent(2, 'Local evvent'), // always notify
  regional(3, 'Regional event'), // never notify
  national(4, 'Nash Hash'), //
  interHash(5, 'InterHash'), //
  worldInterhash(6, 'World interhash'), // notify only before the run starts
  other(7, 'Other event'); // notify only before the run starts

  final int value;
  final String label;

  const EventType(this.value, this.label);

  static final Map<int, EventType> _valueMap = {
    for (var state in EventType.values) state.value: state,
  };

  static EventType? fromInt(int value) => _valueMap[value];
}

//////////////////////////
///
class EnumEmailAlertState extends HcEnum<int> {
  const EnumEmailAlertState(super.val);
}

const EnumEmailAlertState emailAlertsUnchanged = EnumEmailAlertState(-1);
const EnumEmailAlertState emailAlertsAuto = EnumEmailAlertState(0);
const EnumEmailAlertState emailAlertsOn = EnumEmailAlertState(1);
const EnumEmailAlertState emailAlertsOff = EnumEmailAlertState(2);

//////////////////////////

class EnumRsvpState extends HcEnum<int> {
  const EnumRsvpState(super.val);
}

const EnumRsvpState rsvpUpdating = EnumRsvpState(-2);
const EnumRsvpState rsvpNoChange = EnumRsvpState(-1);
const EnumRsvpState rsvpUnknown = EnumRsvpState(0);
const EnumRsvpState rsvpNo = EnumRsvpState(1);
const EnumRsvpState rsvpMaybe = EnumRsvpState(2);
const EnumRsvpState rsvpYes = EnumRsvpState(3);

//////////////////////////

class EnumYesNo extends HcEnum<int> {
  const EnumYesNo(super.val);
}

const EnumYesNo enumYesNo_Cancel = EnumYesNo(-1);
const EnumYesNo enumYesNo_No = EnumYesNo(0);
const EnumYesNo enumYesNo_Yes = EnumYesNo(1);

//////////////////////////

class EnumCheckinOptions extends HcEnum<int> {
  const EnumCheckinOptions(super.val);
}

const EnumCheckinOptions enumCheckInOption_Cancel = EnumCheckinOptions(-1);
const EnumCheckinOptions enumCheckInOption_No = EnumCheckinOptions(0);
const EnumCheckinOptions enumCheckInOption_Yes = EnumCheckinOptions(1);
const EnumCheckinOptions enumCheckInOption_YesAndPayByCredit =
    EnumCheckinOptions(2);
const EnumCheckinOptions enumCheckInOption_YesAndPayPlusExtrasByCredit =
    EnumCheckinOptions(3);
const EnumCheckinOptions enumCheckInOption_YesAndPayByBankXfer =
    EnumCheckinOptions(4);
const EnumCheckinOptions enumCheckInOption_YesAndPayPlusExtrasByBankXfer =
    EnumCheckinOptions(5);

//////////////////////////

class EnumIsHare extends HcEnum<int> {
  const EnumIsHare(super.val);
}

const EnumIsHare isHareNoChange = EnumIsHare(-1);
const EnumIsHare isHareNo = EnumIsHare(0);
const EnumIsHare isHareYes = EnumIsHare(1);

/////////////////////////

class EnumAttendenceState extends HcEnum<int> {
  const EnumAttendenceState(super.val);
}

const EnumAttendenceState attendenceUpdating = EnumAttendenceState(-2);
const EnumAttendenceState attendenceNoChange = EnumAttendenceState(-1);
const EnumAttendenceState attendenceUnknown = EnumAttendenceState(0);
const EnumAttendenceState attendenceNo = EnumAttendenceState(10);
const EnumAttendenceState attendenceAtHash = EnumAttendenceState(20);
const EnumAttendenceState attendenceOnIn = EnumAttendenceState(30);
const EnumAttendenceState attendenceGone = EnumAttendenceState(40);

//////////////////////////

class EnumIsPaid extends HcEnum<int> {
  const EnumIsPaid(super.val);
}

const EnumIsPaid isPaidEmpty = EnumIsPaid(-3);
const EnumIsPaid isPaidUpdating = EnumIsPaid(-2);
const EnumIsPaid isPaidNo = EnumIsPaid(0);
const EnumIsPaid isPaidYes = EnumIsPaid(1);

//////////////////////////

class EnumPaymentType extends HcEnum<int> {
  const EnumPaymentType(super.val);
}

const EnumPaymentType paymentTypeUnknown = EnumPaymentType(0);
const EnumPaymentType paymentNotPaid = EnumPaymentType(1);
const EnumPaymentType paymentFreeRun = EnumPaymentType(2);
const EnumPaymentType paymentCash = EnumPaymentType(3);
const EnumPaymentType paymentBankTransfer = EnumPaymentType(4);
const EnumPaymentType paymentCashOtherAmount = EnumPaymentType(5);
const EnumPaymentType paymentHashCredit = EnumPaymentType(6);
const EnumPaymentType paymentBankTransferOtherAmount = EnumPaymentType(7);
const EnumPaymentType paymentHashCreditOtherAmount = EnumPaymentType(8);
const EnumPaymentType paymentConfirmBankTransfer = EnumPaymentType(100);

//////////////////////////

class EnumPayForExtras extends HcEnum<int> {
  const EnumPayForExtras(super.val);
}

const EnumPayForExtras payForRunOnly = EnumPayForExtras(0);
const EnumPayForExtras payForRunAndExtras = EnumPayForExtras(1);

//////////////////////////

class EnumProductType extends HcEnum<int> {
  const EnumProductType(super.val);
}

const EnumProductType productTypeEvent = EnumProductType(1);
const EnumProductType productTypeMembership = EnumProductType(2);
const EnumProductType productTypeHaberdashery = EnumProductType(3);

//////////////////////////

class EnumCheckInType extends HcEnum<int> {
  const EnumCheckInType(super.val);
}

const EnumCheckInType checkinTypeRunStart = EnumCheckInType(0);
const EnumCheckInType checkinTypeRunEnd = EnumCheckInType(1);

//////////////////////////

class EnumHasherType extends HcEnum<int> {
  const EnumHasherType(super.val);
}

const EnumHasherType hasherTypeMember = EnumHasherType(0);
const EnumHasherType hasherTypeVisitor = EnumHasherType(1);
const EnumHasherType hasherTypeVirgin = EnumHasherType(2);

//////////////////////////

class EnumFollowType extends HcEnum<int> {
  const EnumFollowType(super.val);
}

const EnumFollowType followTypeCancel = EnumFollowType(-1);
const EnumFollowType followTypeAuto = EnumFollowType(0);
const EnumFollowType followTypeFollow = EnumFollowType(1);
const EnumFollowType followTypeIgnore = EnumFollowType(2);
const EnumFollowType followTypeToggleHomeKennel = EnumFollowType(3);

//////////////////////////

class EnumNotificationType extends HcEnum<int> {
  const EnumNotificationType(super.val);
}

// const EnumNotificationType<int> notificationTypeCancel =
//     EnumNotificationType<int>(-1);
// const EnumNotificationType<int> notificationTypeAuto =
//     EnumNotificationType<int>(0);
// const EnumNotificationType<int> notificationTypeAlways =
//     EnumNotificationType<int>(1);
// const EnumNotificationType<int> notificationTypeBlock =
//     EnumNotificationType<int>(2);

//////////////////////////

class EnumEventFilterType extends HcEnum<int> {
  const EnumEventFilterType(super.val);
}

const EnumEventFilterType eventFilterType_refreshOnly = EnumEventFilterType(0);
const EnumEventFilterType eventFilterType_hideEvent = EnumEventFilterType(1);
const EnumEventFilterType eventFilterType_showEvent = EnumEventFilterType(2);
const EnumEventFilterType eventFilterType_countEvent = EnumEventFilterType(3);
const EnumEventFilterType eventFilterType_doNotCountEvent = EnumEventFilterType(
  4,
);
const EnumEventFilterType eventFilterType_setRunNumber = EnumEventFilterType(5);

//////////////////////////
///
class EnumServerStatus extends HcEnum<int> {
  const EnumServerStatus(super.val);
}

const EnumServerStatus serverStatusDownForMaintenance = EnumServerStatus(0);
const EnumServerStatus serverStatusUp = EnumServerStatus(1);
const EnumServerStatus serverStatusDegraded = EnumServerStatus(2);

//////////////////////////

class EnumLoginMessageType extends HcEnum<int> {
  const EnumLoginMessageType(super.val);
}

const EnumLoginMessageType loginMessageTypeNone = EnumLoginMessageType(0);
const EnumLoginMessageType loginMessageTypeAlert = EnumLoginMessageType(1);
const EnumLoginMessageType loginMessageTypeFullView = EnumLoginMessageType(2);
const EnumLoginMessageType loginMessageTypeFullViewWithCountdown =
    EnumLoginMessageType(3);
const EnumLoginMessageType loginMessageTypeImageViewNoContinue =
    EnumLoginMessageType(4);
const EnumLoginMessageType loginMessageTypeImageViewWithContinue =
    EnumLoginMessageType(5);

//////////////////////////

class EnumLoginApproval extends HcEnum<int> {
  const EnumLoginApproval(super.val);
}

const EnumLoginApproval loginApprovalUnknown = EnumLoginApproval(0);
const EnumLoginApproval loginApprovalApproved = EnumLoginApproval(1);
const EnumLoginApproval loginApprovalUnauthorizedDevice = EnumLoginApproval(2);
const EnumLoginApproval loginApprovalUserAccountDoesNotExist =
    EnumLoginApproval(3);
const EnumLoginApproval loginApprovalNotAuthorized = EnumLoginApproval(4);

//////////////////////////
///
class EnumMapCenterOption extends HcEnum<int> {
  const EnumMapCenterOption(super.val);
}

const EnumMapCenterOption centerOnCurrentLocation = EnumMapCenterOption(0);
const EnumMapCenterOption centerOnHomeKennel = EnumMapCenterOption(1);
