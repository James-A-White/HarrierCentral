// ignore_for_file: constant_identifier_names

import 'package:geolocator/geolocator.dart';

const String RANDOM_STRING_LIST = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

// ── Connection-test fallback URLs ──────────────────────────────────────────
const String CONNECTION_TEST_GOOGLE_URL = 'https://www.google.com/generate_204';
const String CONNECTION_TEST_MSFT_URL =
    'https://www.msftconnecttest.com/connecttest.txt';

// ── Geofence / location ────────────────────────────────────────────────────
// lat lon of London Eye
const double DEFAULT_LATITUDE = 51.5033;
const double DEFAULT_LONGITUDE = 0.1195;

// ── UI / device ────────────────────────────────────────────────────────────
const double BASE_DEVICE_WIDTH = 320;
const double BASE_DEVICE_HEIGHT = 576;

// ── Timeouts / delays (seconds unless noted) ──────────────────────────────
const int LOGIN_IS_DELAYED_WARNING_1 = 7;
const int LOGIN_IS_DELAYED_WARNING_2 = 15;
const int LOGIN_TIMEOUT = 20;
const int DEFAULT_HTTP_TIMEOUT = 10;
const int DISPLAY_SPLASH_ON_LAUNCH = 10;
const int SPLASH_SCREEN_DISPLAY_TIME = 3;

// ── Sync / replication ────────────────────────────────────────────────────
// Prevent a full re-sync within 30 seconds of a completed full sync. This means
// quick app restarts (e.g. from settings) skip the expensive sync, but a normal
// relaunch (minutes later) always gets fresh data.
const int DEBOUNCE_SYNC_USER_DATA = 30;

// ── Kennel membership states ──────────────────────────────────────────────
const int KENNEL_IS_FOLLOWING = 1;
const int KENNEL_IS_BLOCKED = 2;
const int KENNEL_IS_AUTO = 0;

const int INBOUND_INTEGRATION_NONE = 0;
const int INBOUND_INTEGRATION_FACEBOOK = 1;
const int INBOUND_INTEGRATION_GOOGLE = 2;
const int INBOUND_INTEGRATION_SAN_DIEGO = 3;

// const num ALLOW_AUTO_CHECKIN_HOURS_BEFORE_EVENT = 48;
// const num GEOFENCE_IN_METERS_AROUND_RUN_START_FOR_AUTO_CHECKIN = 10000;

const int ALLOW_AUTO_CHECKIN_HOURS_BEFORE_EVENT = 1;
const int ALLOW_AUTO_CHECKIN_HOURS_AFTER_EVENT = 6;

// put a 1 mile radius for auto checkins
const int GEOFENCE_IN_METERS_AROUND_RUN_START_FOR_AUTO_CHECKIN = 1609;

const int ALLOW_CHECKIN_SCAN_HOURS_BEFORE_EVENT = 3;
const int ALLOW_CHECKIN_SCAN_HOURS_AFTER_EVENT = 6;

const String EMPTY_RESULT = 'Empty';

const int NOTIFICATION_DAYS_IN_FUTURE = 90;

const double PROFILE_PIC_SIZE = 92.0;

const double PROFILE_PIC_SIZE2 = 60.0;

const double METERS_TO_MILES = 0.000621371;
const double MILES_TO_METERS = 1609.34449;

const LocationAccuracy BASE_APP_LOCATION_ACCURACY = LocationAccuracy.best;

// ── API endpoints ──────────────────────────────────────────────────────────
const String BASE_HCWEB_UPLOAD_URL = 'https://hcweb.azurewebsites.net/upload/';
const String BASE_HCWEB_MOBILE_URL = 'HTTPS://P.HC-APP.COM/#/C?';

const String BASE_HASHRUNS_DOT_ORG_URL = 'https://www.hashruns.org/';
const String HARRIER_CENTRAL_WEBSITE_URL = 'https://www.harriercentral.com';
const String APP_STORE_IOS_URL =
    'https://apps.apple.com/app/harrier-central/id1445513595';
const String APP_STORE_ANDROID_URL =
    'https://play.google.com/store/apps/details?id=com.harriercentral.app';

// const String BASE_URL = 'harrier.azurewebsites.net';
// const String BASE_API_URL = 'https://$BASE_URL/api/';

const String BASE_AF_URL = 'harriercentralpublicapi.azurewebsites.net';
const String BASE_AF_API_URL = 'https://$BASE_AF_URL/api/AppApiHC6';
const String BASE_AF_CONNECTION_TEST_URL = 'https://$BASE_AF_URL/api/TestApi';

const String APP_GEOCODE_PLACE_TO_ADDRESS_API_URL =
    'https://$BASE_AF_URL/api/ProxyGeocode';

// new APIs below
const String PHOTO_UPLOAD_TOKEN_URL =
    'https://$BASE_AF_URL/api/GetPhotoUploadToken';
const String PROFILE_PHOTO_UPLOAD_TOKEN_URL =
    'https://$BASE_AF_URL/api/GetProfilePhotoUploadToken';

const String EMAIL_KENNEL_RUN_STATS_API_URL =
    "https://$BASE_AF_URL/api/SendKennelRunStatsReport";

const String EMAIL_INVITE_CODE_API_URL =
    'https://$BASE_AF_URL/api/EmailInviteCode';

const String EMAIL_PAYMENT_API_URL =
    'https://$BASE_AF_URL/api/SendPaymentReport';

const String EMAIL_RUN_REPORT_API_URL =
    'https://$BASE_AF_URL/api/SendRunCountsReport';

const String STORE_POSITIONS_URL = 'https://$BASE_AF_URL/api/StorePositions';
const String GET_POSITIONS_URL = 'https://$BASE_AF_URL/api/GetPositions';
// Removes specific stored track points for a runner+event (e.g. the On-Inn
// terminator when a stopped track is resumed). Guarded by the same X-Api-Key
// as GetPositions and scoped to the caller's own userId.
const String DELETE_POSITIONS_URL = 'https://$BASE_AF_URL/api/DeletePositions';

// Admin web portal — opened from the drawer for admin users. The app registers
// a one-time auth code and opens `$PORTAL_URL/?authCode=<code>` so the portal
// logs in without a QR scan (same-device login).
const String PORTAL_URL = 'https://portal.harriercentral.com';

// API key required by GetPositions (X-Api-Key header). Matches the ApiKey
// environment variable in Azure App Service. StorePositions is unauthenticated.
const String GET_POSITIONS_API_KEY =
    'npsXZr6xtEPv9iaA7LAEfjRZhCuGbpbwC8BSlLpwbwkGzZdRdNndXWNfvKr8p4l9hdBWE5acK8q';

// old APIs below

// TODO: Re-implement email run details
// const String EMAIL_RUN_DETAILS_TO_PACK_API_URL =
//     'https://hcazurefunctions7.azurewebsites.net/api/SendRunDetailEmails';

// const String EMAIL_PAYMENT_API_URL =
//     'https://hcazurefunctions7.azurewebsites.net/api/SendPaymentReport';

// const String EMAIL_RUN_REPORT_API_URL =
//     'https://hcazurefunctions7.azurewebsites.net/api/SendRunCountsReport';

// TODO: Re-implement email run details
// const String EMAIL_KENNEL_INVITE_CODES_API_URL =
//     'https://hcazurefunctions7.azurewebsites.net/api/SendKennelInviteCodes';

// const String EMAIL_KENNEL_RUN_STATS_API_URL =
//     'https://hcazurefunctions7.azurewebsites.net/api/SendKennelRunStatsReport';

// const String EMAIL_INVITE_CODE_API_URL =
//     'https://hcazurefunctions7.azurewebsites.net/api/EmailInviteCode';

// Storage locations

const String BASE_KENNEL_LOGOS_URL =
    'https://harriercentral.blob.core.windows.net/harrier/';
const String BASE_PROFILE_PHOTOS_URL =
    'https://harriercentral.blob.core.windows.net/profile-photos/';
const String BASE_EVENT_IMAGE_URL =
    'https://harriercentral.blob.core.windows.net/event-images/';
const String BASE_RECEIPTS_URL =
    'https://harriercentral.blob.core.windows.net/receipts/';
const String BASE_NEW_VERSION_IMAGES_URL =
    'https://harriercentral.blob.core.windows.net/splash-sequences/';
const String BASE_TRAIL_PHOTOS_URL =
    'https://harriercentral.blob.core.windows.net/trail-photos/';

// ── Storage / blob URLs ────────────────────────────────────────────────────

// IP geolocation is performed server-side via the HC API shim.
// The client calls GetIpGeoInfo — no token required on the client.
const String IP_GEO_INFO_URL = 'https://harriercentralpublicapi.azurewebsites.net/api/GetIpGeoInfo';

const String NOTIFICATION_PREFIX_EVENT_UPDATE = 'evtUpdate_';

const String ERROR_PREFIX = 'HC_ERROR_';
const String ERROR_KEY_OK_BTN_PRESSED = '${ERROR_PREFIX}OK';
const String ERROR_KEY_CANCEL_BTN_PRESSED = '${ERROR_PREFIX}CANCEL';
const String ERROR_HANDLED = '${ERROR_PREFIX}HANDLED';
const String ERROR_NOT_HANDLED = '${ERROR_PREFIX}NOT_HANDLED';
const String ERROR_NO_CONNECTION = '${ERROR_PREFIX}NO_CONNECTION';
const String ERROR_UNKNOWN_HTTP_ERROR = '${ERROR_PREFIX}HTTP_ERROR';
const String ERROR_UNKNOWN_REMOTE_DB_ERROR = '${ERROR_PREFIX}REMOTE_DB_ERROR';
const String ERROR_INVITE_CODE_SENT = '${ERROR_PREFIX}INVITE_CODE_SENT';

const String GUID_EMPTY = '00000000-0000-0000-0000-000000000000';
const String GUID_8 = '88888888-8888-8888-8888-888888888888';
const String GUID_9 = '99999999-9999-9999-9999-999999999999';
const String GUID_MAX = 'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF';

const String DB_NAME = 'HcDb.db';
const int DB_VERSION = 526;

const double CLEAR_LATLONG = -2.0;

const int IGNORE_REPLICATION_TIMESTAMP = 628387200000000; // 1990-01-01 00:00:00
const int FORCE_ALL_REPLICATION_TIMESTAMP =
    949276800000000; // 2000-01-31 00:00:00
const num TIME_MULTIPLIER = 1000000.00;

const String QR_PREFIX_SPECIFIC_RUN_START = 'SRS:';
const String QR_PREFIX_SPECIFIC_RUN_END = 'SRE:';
const String QR_PREFIX_KENNEL_GENERIC_RUN_START = 'KRS:';
const String QR_PREFIX_KENNEL_GENERIC_RUN_END = 'KRE:';
const String QR_PREFIX_USER_CODE = 'UQR:';
const String QR_PREFIX_USER_SECRET_CODE = 'USC:';
const String QR_PREFIX_USER_RESET_CODE = 'URC:';
const String QR_PREFIX_AUTHENTICATE_WEB_PORTAL_LOGIN = 'UWP:';
const String QR_PREFIX_HASHRUNS_DOT_ORG_RUN_LINK = 'RID?publicEventId=';

const String LAST_CACHE_CLEAR_KEY = 'lastCacheClear_';

//const int dividerCodeForMultipleChoicePopup = -2;
const int hasherPref_distanceMeasuredIn = 0x00000003;
const int hasherPref_distanceForAutoDisplay = 0x0000003C;
// Bit 6: global photo sharing opt-in flag.
const int hasherPref_globalPhotoSharing = 0x00000040;
// Bit 7: set = camera roll save DISABLED. Zero for all existing users, so the
// default behaviour (bit not set) is camera roll ENABLED — no migration needed.
const int hasherPref_cameraRollSaveDisabled = 0x00000080;
// Bit 8: set = debug log harvesting enabled for this device.
const int hasherPref_debugHarvestEnabled = 0x00000100;

const int hasherPref_0 = 0 * 4;
const int hasherPref_10 = 1 * 4;
const int hasherPref_25 = 2 * 4;
const int hasherPref_50 = 3 * 4;
const int hasherPref_75 = 4 * 4;
const int hasherPref_100 = 5 * 4;
const int hasherPref_150 = 6 * 4;
const int hasherPref_250 = 7 * 4;
const int hasherPref_500 = 8 * 4;

// (Removed orphaned mmAuthIsGm / mmAuthCanGrantPermissions — the data-driven
// permission matrix (Permissions V2) now governs role→function grants, so these
// unused, bit-colliding constants are gone. "Assign roles / flags" are matrix
// functions gated via CheckKennelPermission.)

// ======================================
// APP AUTHORIZATIONS
// ======================================

const int authIsAdmin = 0x00000001;
const int authCanManageKennel = 0x00000002;
const int authCanManageRuns = 0x00000004;
const int authCanManageHashCash = 0x00000008;
const int authCanManageMembers = 0x00000010;
const int authCanManageAwards = 0x00000020;
const int authCanManageSongs = 0x00000040;
const int authCanManagePublicWebContent = 0x00000080;
const int authCanManagePhotos = 0x00000100;
const int authIsSuperAdmin = 0x40000000;
// All assignable functional flags (everything except SuperAdmin). Widen this
// whenever a new functional flag bit is added, or the new flag will be stripped
// when app access is saved (app_access_page.dart masks with authAllFlags).
const int authAllFlags = 0x000001ff;

const int selfPaymentNone = 0x00000000;
const int selfPaymentAutoPayAfterBankTransfer = 0x00000001;
const int selfPaymentShowBankButtonOnAutoCheckinDialog = 0x00000002;

class AppAccess {
  AppAccess(this.appAccessFlags, {this.mismanagementRoles = 0});

  int? appAccessFlags;
  int mismanagementRoles;

  bool getAppAccess(int aaFlag) {
    return (appAccessFlags ?? 0) & aaFlag != 0;
  }

  void setAppAccess(int aaFlag, bool value) {
    if (value) {
      appAccessFlags = aaFlag | (appAccessFlags ?? 0);
    } else {
      appAccessFlags = ~aaFlag & (appAccessFlags ?? 0);
    }
  }

  bool get isSuperAdmin {
    return (appAccessFlags ?? 0) & authIsSuperAdmin != 0;
  }

  bool get isAdmin {
    return (appAccessFlags ?? 0) & (authIsAdmin | authIsSuperAdmin) != 0;
  }

  bool get canManageKennel {
    return (appAccessFlags ?? 0) & (authCanManageKennel | authIsSuperAdmin) !=
        0;
  }

  bool get canManageRuns {
    return (appAccessFlags ?? 0) & (authCanManageRuns | authIsSuperAdmin) != 0;
  }

  bool get canManageHashCash {
    return (appAccessFlags ?? 0) & (authCanManageHashCash | authIsSuperAdmin) !=
        0;
  }

  bool get canManageMembers {
    return (appAccessFlags ?? 0) & (authCanManageMembers | authIsSuperAdmin) !=
        0;
  }

  bool get canManageAwards {
    return (appAccessFlags ?? 0) & (authCanManageAwards | authIsSuperAdmin) !=
        0;
  }

  bool get canManageSongs {
    return (appAccessFlags ?? 0) & (authCanManageSongs | authIsSuperAdmin) != 0;
  }

  bool get canManagePublicWebContent {
    return (appAccessFlags ?? 0) &
            (authCanManagePublicWebContent | authIsSuperAdmin) !=
        0;
  }

  bool get canManagePhotos {
    return (appAccessFlags ?? 0) & (authCanManagePhotos | authIsSuperAdmin) != 0;
  }

  /// True when the user holds Hash Flash, GM, VGM, or RA for this kennel —
  /// the roles that grant access to pending photo review (hcapp_getKennelPendingPhotos).
  ///
  /// NOTE: role-only leg, retained for existing callers. Prefer the canonical
  /// [canAccessFeature]([KennelFeature.reviewPhotos]), which also honours the
  /// ManagePhotos override flag and SuperAdmin, matching the server.
  bool get isPhotoAdmin {
    return mismanagementRoles &
            (mmRoleFlagHashFlash | mmRoleFlagGm | mmRoleFlagVgm | mmRoleFlagRa) !=
        0;
  }
}

// ======================================
// Promo button flags
// ======================================

const int promoButtonClose = 0x00000001;
const int promoButtonPermanentlyDismiss = 0x00000002;
const int promoButtonSnooze = 0x00000004;
const int promoButtonGoToRun = 0x00000008;
const int promoButtonLaunchExternalUrl = 0x00000010;

// ======================================
// Mismanagement
// ======================================

const int mmRoleIsOnMm = 0x00000001;
const int mmRoleFlagGm = 0x00000002;
const int mmRoleFlagVgm = 0x00000004;
const int mmRoleFlagRa = 0x00000008;
const int mmRoleFlagBeerMeister = 0x00000010;
const int mmRoleFlagHashFlash = 0x00000020;
const int mmRoleFlagOnSec = 0x00000040;
const int mmRoleFlagSongMeister = 0x00000080;
const int mmRoleFlagTrailMaster = 0x00000100;
const int mmRoleFlagHareRaiser = 0x00000200;
const int mmRoleFlagHashCash = 0x00000400;
const int mmRoleFlagScribe = 0x00000800;
const int mmRoleFlagWebMeister = 0x00001000;
const int mmRoleFlagHashHugs = 0x00002000;
const int mmRoleFlagHashHo = 0x00004000;
const int mmRoleFlagHaberdasher = 0x00008000;
const int mmRoleFlagHashSweep = 0x00010000;
const int mmRoleFlagHashTrash = 0x00020000;
const int mmRoleFlagHashBank = 0x00040000;
const int mmRoleFlagEventMeister = 0x00080000;
const int mmRoleFlagCommunications = 0x00100000;

const int mmRoleFlagOther = 0x00200000;

const int mmRoleFlagBashMaster = 0x00400000;
const int mmRoleFlagBashMoney = 0x00800000;
const int mmRoleFlagTranslator = 0x01000000;
const int mmRoleFlagSocialMediaWhore = 0x02000000;
const int mmRoleFlagDownDownMaster = 0x04000000;

const int mmRoleAllFlags = 0x07ffffff;

const int specialRunNo = 0;
const int specialRunFirstRun = 1;
const int specialRunFifthRun = 5;
const int specialRunTenthRun = 10;
const int specialRun25 = 25;
const int specialRun69 = 69;
const int specialRun100 = 100;
const int specialRun250 = 250;
const int specialRun1000 = 1000;
const int specialRunPalindrome = 969;

const String BOOT_TYPE_FIRST_TIME = 'firstTime';
const String BOOT_TYPE_NORMAL = 'normal';
const String BOOT_TYPE_UPGRADE_1_2 = 'upgrade1.2';
const String BOOT_TYPE_UPGRADE_DB = 'upgradeDb';
const String BOOT_TYPE_RELOAD_DATA = 'reloadData';
const String BOOT_TYPE_UNKNOWN = 'unknown';

class Mismanagement {
  Mismanagement(this.mismanagementFlags);

  int? mismanagementFlags;

  bool getMismanagementState(int mmFlag) {
    return (mismanagementFlags ?? 0) & mmFlag != 0;
  }

  void setMismanagementState(int mmFlag, bool value) {
    if (value) {
      mismanagementFlags = mmFlag | (mismanagementFlags ?? 0);
    } else {
      mismanagementFlags = ~mmFlag & (mismanagementFlags ?? 0);
    }
  }

  bool get isOnMismanagement {
    return (mismanagementFlags ?? 0) & mmRoleIsOnMm != 0;
  }

  // set isOnMismanagement(bool value) {
  //   mismanagementFlags ??= 0;
  //   if (value) {
  //     mismanagementFlags |= mmRoleIsOnMm;
  //   } else {
  //     mismanagementFlags &= ~mmRoleIsOnMm;
  //   }
  // }
}

const int cacheDurationAllHashers = 60 * 86400000; // 60 days cache duration

// NOTE: The order of these strings should match with the integrationId values in the HC.Integration
// table in the main DB
const List<String> integrationPlatformNames = <String>[
  'Harrier Central',
  'Facebook',
  'Google In',
  'San Diego DB',
  'Google Out',
  'Berlin H3',
];

// const String normalTable = 'normal'; // this is not used, but is added to make the code more clear
// const String hemUserTable = 'hasherEventMap';
// const String hemAdminTable = 'hasherEventMapForRunAdmin';
// const String hkmUserTable = 'hasherKennelMap';
// const String hkmEventAdminTable = 'hasherKennelMapForRunAdmin';
// const String hkmKennelAdminTable = 'hasherKennelMapForKennelAdmin';
// const String eventPaymentsTable = 'Payments';
// const String userPaymentsTable = 'userPayments';

const Map<String, int> runTags1 = <String, int>{
  'Normal run': 0x00000001,
  'Red Dress run': 0x00000002,
  'Full Moon run': 0x00000004,
  'Harriette run': 0x00000008,
  'Men-only Hash': 0x00000010,
  'Woman-only Hash': 0x00000020,
  'Kids allowed': 0x00000040,
  'No kids allowed': 0x00000080,
  'Bring flashlight': 0x00000100,
  'Water on trail': 0x00000200,
  'Walker trail': 0x00000400,
  'Runner trail': 0x00000800,
  'Long run trail': 0x00001000,
  'Pub crawl': 0x00002000,
  'On after': 0x00004000,
  'Baby jogger friendly': 0x00008000,
  'Shiggy run': 0x00010000,
  'Accessible by public transport': 0x00020000,
  'Bike Hash': 0x00040000,
  'City run': 0x00080000,
  'Live hare': 0x00100000,
  'Dead hare': 0x00200000,
  'Nighttime run': 0x00400000,
  'Steep hills': 0x00800000,
  'Charity event': 0x01000000,
  'Dog friendly': 0x02000000,
  'Pick-up Hash': 0x04000000,
  'Catch the Hare': 0x08000000,
  'Bring cash on trail': 0x10000000,
  'Bag drop available': 0x20000000,
  'AGM': 0x40000000,
};

const Map<String, int> runTags2 = <String, int>{
  'Multi-day event': 0x00000001,
  'No dogs allowed': 0x00000002,
  'Family hash': 0x00000004,
  'Bring dry clothes': 0x00000008,
  'Short trail': 0x00000010,
  'Parking available': 0x00000020,
  'No parking available': 0x00000040,
  'Camping Hash': 0x00000080,
  'No bag drop available': 0x00000100,
  'Drinking practice': 0x00000200,
  'Ballbreaker trail': 0x00000400,
  'Short walk / Old Farts trail': 0x00000800,
  'Bring Drinking Vessel': 0x00001000,
  'Bring Chair': 0x00002000,
  'A to B run': 0x00004000,
  'Drink Stop': 0x00008000,
  'Swim Stop': 0x00010000,
  'Hangover Run': 0x00020000,
  // 'Bike Hash': 0x00040000,
  // 'City run': 0x00080000,
  // 'Live hare': 0x00100000,
  // 'Dead hare': 0x00200000,
  // 'Nighttime run': 0x00400000,
  // 'Steep hills': 0x00800000,
  // 'Charity event': 0x01000000,
  // 'Dog friendly': 0x02000000,
  // 'Pick-up Hash': 0x04000000,
  // 'Catch the Hare': 0x08000000,
  // 'Bring cash on trail': 0x10000000,
  // 'Bag drop available': 0x20000000,
  // 'AGM': 0x40000000,
};
