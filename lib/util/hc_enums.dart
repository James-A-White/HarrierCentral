// @dart=2.11
import 'package:harrier_central/imports.dart';

enum EnumAppPages { settings, futureRuns, kennelList, runCounts, qrCodePage, friends, fab }

enum StringPrefsEnum {
  userId,
  qrCode,
  supportCode,
  resetCode,
  qrSecretCode,
  displayName,
  firstName,
  lastName,
  harrierCentralVersion,
  hashName,
  email,
  thirdPartyLoginEmail,
  gender,
  profilePhotoUrl,
  adminEventId,
  adminKennelId,
  customEmailBody,
  iosDownloadLink,
  androidDownloadLink,
  imageRootUrl,
  homeKennelId,
  ssoAuthType,
  facebookId,
  facebookAccessToken,
  facebookProfilePhoto,
  facebookEmail,
  thirdPartyAccessToken,
  thirdPartyUserId,
  thirdPartyAuthorizationCode,
  thirdPartyLoginType,
  thirdPartyEmail,
  paymentTerminalAccountKey,
}

enum NumPrefsEnum {
  currentDeviceLat,
  currentDeviceLon,
  homeKennelLat,
  homeKennelLon,
}

enum BoolPrefsEnum { showEnvironmentWarning }

enum IntPrefsEnum {
  databaseVersion,
  hasherPreferences,
  //lastSuccessfulUserDataSyncInMs,
  hasLocationPermissions,
  mapCenterOption,
  mapShowSearchBar,
  mapShowKennels,
  isBetaTester,
  isResettingCache,
}

enum DatePrefsEnum {
  lastSuccessfulUserDataSyncAsDate,
  lastFbTokenUpdate,
  fbLoginCancelled,
  thirdPartyTokenLastUpdated,
  thirdPartyTokenExpires,
  lastLocationUpdate,
}

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

class EnumVirginVisitor<int> extends HcEnum<int> {
  const EnumVirginVisitor(int val) : super(val);
}

const EnumVirginVisitor<int> enumHasher = EnumVirginVisitor<int>(0);
const EnumVirginVisitor<int> enumVirgin = EnumVirginVisitor<int>(1);
const EnumVirginVisitor<int> enumAnonymousVisitor = EnumVirginVisitor<int>(2);
const EnumVirginVisitor<int> enumKnownVisitor = EnumVirginVisitor<int>(3);

//////////////////////////
///
class EnumNotificationState<int> extends HcEnum<int> {
  const EnumNotificationState(int val) : super(val);
}

const EnumNotificationState<int> notificationsUnchanged = EnumNotificationState<int>(-1);
const EnumNotificationState<int> notificationsAuto = EnumNotificationState<int>(0);
const EnumNotificationState<int> notificationsOn = EnumNotificationState<int>(1);
const EnumNotificationState<int> notificationsOff = EnumNotificationState<int>(2);

//////////////////////////
///
class EnumEmailAlertState<int> extends HcEnum<int> {
  const EnumEmailAlertState(int val) : super(val);
}

const EnumEmailAlertState<int> emailAlertsUnchanged = EnumEmailAlertState<int>(-1);
const EnumEmailAlertState<int> emailAlertsAuto = EnumEmailAlertState<int>(0);
const EnumEmailAlertState<int> emailAlertsOn = EnumEmailAlertState<int>(1);
const EnumEmailAlertState<int> emailAlertsOff = EnumEmailAlertState<int>(2);

//////////////////////////

class EnumRsvpState<int> extends HcEnum<int> {
  const EnumRsvpState(int val) : super(val);
}

const EnumRsvpState<int> rsvpUpdating = EnumRsvpState<int>(-2);
const EnumRsvpState<int> rsvpNoChange = EnumRsvpState<int>(-1);
const EnumRsvpState<int> rsvpUnknown = EnumRsvpState<int>(0);
const EnumRsvpState<int> rsvpNo = EnumRsvpState<int>(1);
const EnumRsvpState<int> rsvpMaybe = EnumRsvpState<int>(2);
const EnumRsvpState<int> rsvpYes = EnumRsvpState<int>(3);

//////////////////////////

class EnumYesNo<int> extends HcEnum<int> {
  const EnumYesNo(int val) : super(val);
}

const EnumYesNo<int> enumYesNo_Cancel = EnumYesNo<int>(-1);
const EnumYesNo<int> enumYesNo_No = EnumYesNo<int>(0);
const EnumYesNo<int> enumYesNo_Yes = EnumYesNo<int>(1);

//////////////////////////

class EnumCheckinOptions<int> extends HcEnum<int> {
  const EnumCheckinOptions(int val) : super(val);
}

const EnumCheckinOptions<int> enumCheckInOption_Cancel = EnumCheckinOptions<int>(-1);
const EnumCheckinOptions<int> enumCheckInOption_No = EnumCheckinOptions<int>(0);
const EnumCheckinOptions<int> enumCheckInOption_Yes = EnumCheckinOptions<int>(1);
const EnumCheckinOptions<int> enumCheckInOption_YesAndPay = EnumCheckinOptions<int>(2);
const EnumCheckinOptions<int> enumCheckInOption_YesAndPayPlusExtras = EnumCheckinOptions<int>(3);

//////////////////////////

class EnumIsHare<int> extends HcEnum<int> {
  const EnumIsHare(int val) : super(val);
}

const EnumIsHare<int> isHareNoChange = EnumIsHare<int>(-1);
const EnumIsHare<int> isHareNo = EnumIsHare<int>(0);
const EnumIsHare<int> isHareYes = EnumIsHare<int>(1);

/////////////////////////

class EnumAttendenceState<int> extends HcEnum<int> {
  const EnumAttendenceState(int val) : super(val);
}

const EnumAttendenceState<int> attendenceUpdating = EnumAttendenceState<int>(-2);
const EnumAttendenceState<int> attendenceNoChange = EnumAttendenceState<int>(-1);
const EnumAttendenceState<int> attendenceUnknown = EnumAttendenceState<int>(0);
const EnumAttendenceState<int> attendenceNo = EnumAttendenceState<int>(10);
const EnumAttendenceState<int> attendenceAtHash = EnumAttendenceState<int>(20);
const EnumAttendenceState<int> attendenceOnIn = EnumAttendenceState<int>(30);
const EnumAttendenceState<int> attendenceGone = EnumAttendenceState<int>(40);

//////////////////////////

class EnumIsPaid<int> extends HcEnum<int> {
  const EnumIsPaid(int val) : super(val);
}

const EnumIsPaid<int> isPaidUpdating = EnumIsPaid<int>(-2);
const EnumIsPaid<int> isPaidNo = EnumIsPaid<int>(0);
const EnumIsPaid<int> isPaidYes = EnumIsPaid<int>(1);

//////////////////////////

class EnumPaymentType<int> extends HcEnum<int> {
  const EnumPaymentType(int val) : super(val);
}

const EnumPaymentType<int> paymentTypeUnknown = EnumPaymentType<int>(0);
const EnumPaymentType<int> paymentNotPaid = EnumPaymentType<int>(1);
const EnumPaymentType<int> paymentFreeRun = EnumPaymentType<int>(2);
const EnumPaymentType<int> paymentCash = EnumPaymentType<int>(3);
const EnumPaymentType<int> paymentBankTransfer = EnumPaymentType<int>(4);
const EnumPaymentType<int> paymentCashOtherAmount = EnumPaymentType<int>(5);
const EnumPaymentType<int> paymentHashCredit = EnumPaymentType<int>(6);
const EnumPaymentType<int> paymentBankTransferOtherAmount = EnumPaymentType<int>(7);
const EnumPaymentType<int> paymentConfirmBankTransfer = EnumPaymentType<int>(100);

//////////////////////////

class EnumPayForExtras<int> extends HcEnum<int> {
  const EnumPayForExtras(int val) : super(val);
}

const EnumPayForExtras<int> payForRunOnly = EnumPayForExtras<int>(0);
const EnumPayForExtras<int> payForRunAndExtras = EnumPayForExtras<int>(1);

//////////////////////////

class EnumProductType<int> extends HcEnum<int> {
  const EnumProductType(int val) : super(val);
}

const EnumProductType<int> productTypeEvent = EnumProductType<int>(1);
const EnumProductType<int> productTypeMembership = EnumProductType<int>(2);
const EnumProductType<int> productTypeHaberdashery = EnumProductType<int>(3);

//////////////////////////

class EnumCheckInType<int> extends HcEnum<int> {
  const EnumCheckInType(int val) : super(val);
}

const EnumCheckInType<int> checkinTypeRunStart = EnumCheckInType<int>(0);
const EnumCheckInType<int> checkinTypeRunEnd = EnumCheckInType<int>(1);

//////////////////////////

class EnumHasherType<int> extends HcEnum<int> {
  const EnumHasherType(int val) : super(val);
}

const EnumHasherType<int> hasherTypeMember = EnumHasherType<int>(0);
const EnumHasherType<int> hasherTypeVisitor = EnumHasherType<int>(1);
const EnumHasherType<int> hasherTypeVirgin = EnumHasherType<int>(2);

//////////////////////////

class EnumFollowType<int> extends HcEnum<int> {
  const EnumFollowType(int val) : super(val);
}

const EnumFollowType<int> followTypeCancel = EnumFollowType<int>(-1);
const EnumFollowType<int> followTypeAuto = EnumFollowType<int>(0);
const EnumFollowType<int> followTypeFollow = EnumFollowType<int>(1);
const EnumFollowType<int> followTypeIgnore = EnumFollowType<int>(2);
const EnumFollowType<int> followTypeToggleHomeKennel = EnumFollowType<int>(3);

//////////////////////////

class EnumNotificationType<int> extends HcEnum<int> {
  const EnumNotificationType(int val) : super(val);
}

const EnumNotificationType<int> notificationTypeCancel = EnumNotificationType<int>(-1);
const EnumNotificationType<int> notificationTypeAuto = EnumNotificationType<int>(0);
const EnumNotificationType<int> notificationTypeAlways = EnumNotificationType<int>(1);
const EnumNotificationType<int> notificationTypeBlock = EnumNotificationType<int>(2);

//////////////////////////

class EnumEventFilterType<int> extends HcEnum<int> {
  const EnumEventFilterType(int val) : super(val);
}

const EnumEventFilterType<int> eventFilterType_refreshOnly = EnumEventFilterType<int>(0);
const EnumEventFilterType<int> eventFilterType_hideEvent = EnumEventFilterType<int>(1);
const EnumEventFilterType<int> eventFilterType_showEvent = EnumEventFilterType<int>(2);
const EnumEventFilterType<int> eventFilterType_countEvent = EnumEventFilterType<int>(3);
const EnumEventFilterType<int> eventFilterType_doNotCountEvent = EnumEventFilterType<int>(4);
const EnumEventFilterType<int> eventFilterType_setRunNumber = EnumEventFilterType<int>(5);

//////////////////////////
///
class EnumServerStatus<int> extends HcEnum<int> {
  const EnumServerStatus(int val) : super(val);
}

const EnumServerStatus<int> serverStatusDownForMaintenance = EnumServerStatus<int>(0);
const EnumServerStatus<int> serverStatusUp = EnumServerStatus<int>(1);
const EnumServerStatus<int> serverStatusDegraded = EnumServerStatus<int>(2);

//////////////////////////

class EnumLoginMessageType<int> extends HcEnum<int> {
  const EnumLoginMessageType(int val) : super(val);
}

const EnumLoginMessageType<int> loginMessageTypeNone = EnumLoginMessageType<int>(0);
const EnumLoginMessageType<int> loginMessageTypeAlert = EnumLoginMessageType<int>(1);
const EnumLoginMessageType<int> loginMessageTypeFullView = EnumLoginMessageType<int>(2);
const EnumLoginMessageType<int> loginMessageTypeFullViewWithCountdown = EnumLoginMessageType<int>(3);
const EnumLoginMessageType<int> loginMessageTypeImageViewNoContinue = EnumLoginMessageType<int>(4);
const EnumLoginMessageType<int> loginMessageTypeImageViewWithContinue = EnumLoginMessageType<int>(5);

//////////////////////////

class EnumLoginApproval<int> extends HcEnum<int> {
  const EnumLoginApproval(int val) : super(val);
}

const EnumLoginApproval<int> loginApprovalUnknown = EnumLoginApproval<int>(0);
const EnumLoginApproval<int> loginApprovalApproved = EnumLoginApproval<int>(1);
const EnumLoginApproval<int> loginApprovalUnauthorizedDevice = EnumLoginApproval<int>(2);
const EnumLoginApproval<int> loginApprovalUserAccountDoesNotExist = EnumLoginApproval<int>(3);
const EnumLoginApproval<int> loginApprovalNotAuthorized = EnumLoginApproval<int>(4);

//////////////////////////
///
class EnumMapCenterOption<int> extends HcEnum<int> {
  const EnumMapCenterOption(int val) : super(val);
}

const EnumMapCenterOption<int> centerOnCurrentLocation = EnumMapCenterOption<int>(0);
const EnumMapCenterOption<int> centerOnHomeKennel = EnumMapCenterOption<int>(1);
