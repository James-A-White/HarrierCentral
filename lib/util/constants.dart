import 'package:harrier_central/imports.dart';
import 'package:geolocator/geolocator.dart';

// lat lon of London Eye
const num DEFAULT_LATITUDE = 51.5033;
const num DEFAULT_LONGITUDE = 0.1195;

const num BASE_DEVICE_WIDTH = 320;
const num BASE_DEVICE_HEIGHT = 576;

const int LOGIN_TIMEOUT = 10;
const int DEFAULT_HTTP_TIMEOUT = 10;

// const num ALLOW_AUTO_CHECKIN_HOURS_BEFORE_EVENT = 48;
// const num GEOFENCE_IN_METERS_AROUND_RUN_START_FOR_AUTO_CHECKIN = 10000;

const num ALLOW_AUTO_CHECKIN_HOURS_BEFORE_EVENT = 4;
const num GEOFENCE_IN_METERS_AROUND_RUN_START_FOR_AUTO_CHECKIN = 1500;

const num ALLOW_CHECKIN_SCAN_HOURS_BEFORE_EVENT = 3;
const num ALLOW_CHECKIN_SCAN_HOURS_AFTER_EVENT = 6;

const String EMPTY_RESULT = 'Empty';

const int NOTIFICATION_DAYS_IN_FUTURE = 90;

const num PROFILE_PIC_SIZE = 92.0;

const num PROFILE_PIC_SIZE2 = 60.0;

const num METERS_TO_MILES = 0.000621371;
const num MILES_TO_METERS = 1609.34449;

const int SPLASH_SCREEN_DISPLAY_TIME = 1;

const LocationAccuracy BASE_APP_LOCATION_ACCURACY = LocationAccuracy.best;

const String BASE_HCWEB_UPLOAD_URL = 'https://hcweb.azurewebsites.net/upload/';

const String BASE_API_URL = 'https://harrier.azurewebsites.net/api/';

const String BASE_PROFILE_PHOTOS_URL = 'https://harriercentral.blob.core.windows.net/profile-photos/';
const String BASE_RECEIPTS_URL = 'https://harriercentral.blob.core.windows.net/receipts/';

const String EMAIL_RUN_DETAILS_TO_PACK_API_URL = 'https://hcazurefunctions7.azurewebsites.net/api/SendRunDetailEmails';
const String EMAIL_PAYMENT_API_URL = 'https://hcazurefunctions7.azurewebsites.net/api/SendPaymentReport';
const String EMAIL_RUN_REPORT_API_URL = 'https://hcazurefunctions7.azurewebsites.net/api/SendRunCountsReport';
const String EMAIL_KENNEL_RUN_STATS_API_URL = 'https://hcazurefunctions7.azurewebsites.net/api/SendKennelRunStatsReport';
const String EMAIL_INVITE_CODE_API_URL = 'https://hcazurefunctions7.azurewebsites.net/api/EmailInviteCode';

const String GOOGLE_API_KEY = 'AIzaSyAiJXV8P99FwXq2FtYby7To80e9SBTrV2c';

const String NOTIFICATION_PREFIX_EVENT_UPDATE = 'evtUpdate_';

const String ERROR_PREFIX = 'HC_ERROR_';
const String ERROR_KEY_OK_BTN_PRESSED = ERROR_PREFIX + 'OK';
const String ERROR_KEY_CANCEL_BTN_PRESSED = ERROR_PREFIX + 'CANCEL';
const String ERROR_HANDLED = ERROR_PREFIX + 'HANDLED';
const String ERROR_NOT_HANDLED = ERROR_PREFIX + 'NOT_HANDLED';
const String ERROR_NO_CONNECTION = ERROR_PREFIX + 'NO_CONNECTION';
const String ERROR_UNKNOWN_HTTP_ERROR = ERROR_PREFIX + 'HTTP_ERROR';
const String ERROR_UNKNOWN_REMOTE_DB_ERROR = ERROR_PREFIX + 'REMOTE_DB_ERROR';
const String ERROR_INVITE_CODE_SENT = ERROR_PREFIX + 'INVITE_CODE_SENT';

const String GUID_EMPTY = '00000000-0000-0000-0000-000000000000';
const String GUID_8 = '88888888-8888-8888-8888-888888888888';
const String GUID_9 = '99999999-9999-9999-9999-999999999999';
const String GUID_MAX = 'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF';

const String DB_NAME = 'HcDb.db';
const int DB_VERSION = 300;

const int IGNORE_REPLICATION_TIMESTAMP = 628387200000; // 1990-01-01 00:00:00
const int FORCE_ALL_REPLICATION_TIMESTAMP = 949276800000; // 2000-01-31 00:00:00

const String QR_PREFIX_SPECIFIC_RUN_START = 'SRS:';
const String QR_PREFIX_SPECIFIC_RUN_END = 'SRE:';
const String QR_PREFIX_KENNEL_GENERIC_RUN_START = 'KRS:';
const String QR_PREFIX_KENNEL_GENERIC_RUN_END = 'KRE:';
const String QR_PREFIX_USER_CODE = 'UQR:';
const String QR_PREFIX_USER_SECRET_CODE = 'USC:';
const String QR_PREFIX_USER_RESET_CODE = 'URC:';

const String LAST_CACHE_CLEAR_KEY = 'lastCacheClear_';

const int hasherPref_distanceMeasuredIn = 0x00000003;
const int hasherPref_distanceForAutoDisplay = 0x0000001C;

const int hasherPref_0 = 0 * 4;
const int hasherPref_10 = 1 * 4;
const int hasherPref_25 = 2 * 4;
const int hasherPref_50 = 3 * 4;
const int hasherPref_75 = 4 * 4;
const int hasherPref_100 = 5 * 4;
const int hasherPref_150 = 6 * 4;
const int hasherPref_200 = 7 * 4;

const int mmAuthIsGm = 0x40000000; // TODO(James): Needs implementation
const int mmAuthCanGrantPermissions = 0x20000000; // TODO(James): Needs implementation

const int mmAuthAccessKennelAdmin = 0x00000001; // TODO(James): Needs implementation
const int mmAuthAllowCheckInAndOutFlag = 0x00000002;
const int mmAuthAllowHashCashFlag = 0x00000004;
const int mmAuthAllowAddNewMemberFlag = 0x00000008;
const int mmAuthAllowEnableDisableFacebookEvents = 0x00000010; // TODO(James): Needs implementation
const int mmAuthEditRuns = 0x00000020; // TODO(James): Needs implementation
const int mmAuthGenerateRunQrCodes = 0x00000040; // TODO(James): Needs implementation
const int mmAuthManageMembers = 0x00000080; // TODO(James): Needs implementation
const int mmAuthAllowEditRsvpFlag = 0x00000100;
const int mmAuthCanEditRunVisibility = 0x00000200; // TODO(James): Needs implementation

const int cacheDurationAllHashers = 60 * 86400000; // 60 days cache duration

// const String normalTable = 'normal'; // this is not used, but is added to make the code more clear
// const String hemUserTable = 'hasherEventMap';
// const String hemAdminTable = 'hasherEventMapForRunAdmin';
// const String hkmUserTable = 'hasherKennelMap';
// const String hkmEventAdminTable = 'hasherKennelMapForRunAdmin';
// const String hkmKennelAdminTable = 'hasherKennelMapForKennelAdmin';
// const String eventPaymentsTable = 'Payments';
// const String userPaymentsTable = 'userPayments';

const Map<String, int> runTags = <String, int>{
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
  'Multi-day event': 0x80000000,
};
