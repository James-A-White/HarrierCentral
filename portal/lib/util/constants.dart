// ignore_for_file: constant_identifier_names

const int DEFAULT_HTTP_TIMEOUT = 30;

// const String ROUTE_REGISTER_VIRGIN = '/C';
// const String ROUTE_SHOW_RUN_DETAILS = '/RD';

const String HC_PORTAL_ADMIN_KILTY = 'ABEF03FB-4E1A-4D1C-B543-C22B7059C9D4';
const String HC_PORTAL_ADMIN_TUNA = '7F413FA4-9291-474E-9E50-94DAA16E5CFC';
const String HC_PORTAL_ADMIN_OPEE = 'B6BAFD0D-5D2E-41CD-8495-811D551F01D0';

const int NUM_COLS_A4 = 25;
const int NUM_COLS_LETTER = 20;
const int NUM_COLS_LEGAL = 42;

const double COL_WIDTH = 10;
const double ROW_HEIGHT = 20;

const int SET_DB_NUMERIC_FIELD_TO_NULL = -2;
const String SET_DB_STRING_FIELD_TO_NULL = '<null>';

const String HC_ADMIN_PORTAL_INTERNAL_USER_ID =
    '22222222-2222-2222-2222-222222222222';

const String FIREBASE_VAPID_KEY =
    'BJxyzluRCiPgUYF-QlpYoqWZIpjmnNXh0fAvcPLutbimF8jIHnfQ3RovPrWZmxESnSAMRaRUWvYOcAJtNiq3JRI';

const int AUTH_POLL_MAX_ATTEMPTS = 300;
const int AUTH_POLL_INTERVAL_SECONDS = 1;
const int FCM_DENIED_REMINDER_INTERVAL = 15;

const String BASE_UPLOAD_URL = 'unknown';

const String BASE_UPLOAD_URL_REGEX =
    r'^https:\/\/challengeplatform\.blob\.core\.windows\.net\/proposals\/.*';

const String BASE_EVENT_IMAGE_URL =
    'https://harriercentral.blob.core.windows.net/event-images/';
const String BASE_PROMO_IMAGE_URL =
    'https://harriercentral.blob.core.windows.net/promos/';
const String BASE_NEWSFLASH_IMAGE_URL =
    'https://harriercentral.blob.core.windows.net/newsflash/';
const String NEWSFLASH_IMAGE_UPLOAD_SAS =
    '?sv=2025-07-05&spr=https&st=2026-04-10T20%3A45%3A21Z&se=2100-01-01T21%3A45%3A00Z&sr=c&sp=racw&sig=1%2Bkjc3ATaqcD0%2ByjPUDFbl1M14gUWexW3dT0fqoLUbA%3D';

const String BASE_KENNEL_LOGOS_URL =
    'https://harriercentral.blob.core.windows.net/harrier/';
const String KENNEL_LOGO_UPLOAD_SAS =
    '?sv=2025-07-05&spr=https%2Chttp&st=2026-03-24T13%3A01%3A00Z&se=2100-03-26T13%3A01%3A00Z&sr=c&sp=racwltf&sig=2WpGaXuqWmmqg57XpbnEOAnffMo9rNfZ6d61%2BENs7a4%3D';
const String BASE_API_URL = 'https://hcwebapi.azurewebsites.net';

const String BASE_AF_API_URL =
    'https://harriercentralpublicapi.azurewebsites.net/api/PortalApi/';

const String BASE_HC6_API_URL =
    'https://harriercentralpublicapi.azurewebsites.net/api/PortalApiHC6';

// const String BASE_AF_API_URL = 'http://localhost:7071/api/PortalApi/';

const String PORTAL_REVERSE_GEOCODE_API_URL =
    'https://hcazurefunctions7.azurewebsites.net/api/HcPortalReverseGeocode';

// const String PORTAL_GEOCODE_PLACE_TO_ADDRESS_API_URL =
//     'https://hcazurefunctions7.azurewebsites.net/api/HcPortalGeocodePlaceToAddress';

const String PORTAL_GEOCODE_PLACE_TO_ADDRESS_API_URL =
    'https://prod-53.northeurope.logic.azure.com:443/workflows/e36d1f4ba09348b79c6fe5dc959a51aa/triggers/When_a_HTTP_request_is_received/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2FWhen_a_HTTP_request_is_received%2Frun&sv=1.0&sig=ZmWyRgOKgt_ZsT6AMRD74LudI8XndBHVzmDcUeMCNKc';

const String ERROR_PREFIX = 'HC_ERROR_';
const String ERROR_KEY_OK_BTN_PRESSED = '${ERROR_PREFIX}OK';
const String ERROR_KEY_CANCEL_BTN_PRESSED = '${ERROR_PREFIX}CANCEL';
const String ERROR_HANDLED = '${ERROR_PREFIX}HANDLED';
const String ERROR_NOT_HANDLED = '${ERROR_PREFIX}NOT_HANDLED';
const String ERROR_NO_CONNECTION = '${ERROR_PREFIX}NO_CONNECTION';
const String ERROR_UNKNOWN_HTTP_ERROR = '${ERROR_PREFIX}HTTP_ERROR';
const String ERROR_UNKNOWN_REMOTE_DB_ERROR = '${ERROR_PREFIX}REMOTE_DB_ERROR';
const String ERROR_INVITE_CODE_SENT = '${ERROR_PREFIX}INVITE_CODE_SENT';

const String BULK_IMPORT_RESPONSE_NEW_HC_USER = 'NEW HC USER';
const String BULK_IMPORT_RESPONSE_NEW_MEMBER = 'NEW MEMBER';
const String BULK_IMPORT_RESPONSE_NO_CHANGE = 'NO CHANGE';
const String BULK_IMPORT_RESPONSE_UPDATE_RUN_COUNTS = 'UPDATE RUN COUNTS';
const String BULK_IMPORT_RESPONSE_ERROR = 'ERROR';

const String GUID_EMPTY = '00000000-0000-0000-0000-000000000000';
const String GUID_8 = '88888888-8888-8888-8888-888888888888';
const String GUID_9 = '99999999-9999-9999-9999-999999999999';
const String GUID_MAX = 'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF';

const String RUN_DISPLAY_TYPE_DETAIL_ONLY = 'detailonly';
const String RUN_DISPLAY_TYPE_LIST_AND_DETAIL = 'listanddetail';

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
const int authIsSuperAdmin = 0x40000000;
const int authAllFlags = 0x0000007f;

const String TAG_NORMAL_RUN = 'Normal run';
const String TAG_RED_DRESS = 'Red Dress run';
const String TAG_FULL_MOON = 'Full Moon run';
const String TAG_HARRIETTE = 'Harriette run';
const String TAG_MEN_ONLY = 'Men-only Hash';
const String TAG_WOMEN_ONLY = 'Women-only Hash';
const String TAG_KIDS_ALLOWED = 'Kids welcomed';
const String TAG_NO_KIDS_ALLOWED = 'No kids allowed';
const String TAG_BRING_FLASHLIGHT = 'Bring flashlight';
const String TAG_WATER_ON_TRAIL = 'Water crossings on trail';
const String TAG_WALKER_TRAIL = 'Walker trail';
const String TAG_MEDIUM_TRAIL = 'Medium trail';
const String TAG_LONG_TRAIL = 'Long run trail';
const String TAG_PUB_CRAWL = 'Pub crawl';
const String TAG_ON_AFTER = 'On after / after party';
const String TAG_BABY_JOGGER_FRIENDLY = 'Baby jogger friendly';
const String TAG_SHIGGY_RUN = 'Shiggy run';
const String TAG_ACCESSIBLE_BY_PUBLIC_TRANSPORT =
    'Accessible by public transport';
const String TAG_BIKE_HASH = 'BASH / Bike Hash';
const String TAG_CITY_HASH = 'City run';
const String TAG_LIVE_HARE = 'Live hare';
const String TAG_DEAD_HARE = 'Dead hare';
const String TAG_NIGHT_RUN = 'Nighttime run';
const String TAG_STEEP_HILLS = 'Steep hills';
const String TAG_CHARITY_EVENT = 'Charity event';
const String TAG_DOG_FRIENDLY = 'Dog friendly';
const String TAG_PICK_UP_HASH = 'Pick-up Hash';
const String TAG_CATCH_THE_HARE = 'Catch the Hare';
const String TAG_BRING_CASH_ON_TRAIL = 'Bring cash on trail';
const String TAG_BAG_DROP_AVAILABLE = 'Bag drop available';
const String TAG_AGM = 'AGM';
const String TAG_MULTI_DAY_EVENT = 'Multi-day event';
const String TAG_NO_DOGS_ALLOWED = 'No dogs allowed';
const String TAG_FAMILY_HASH = 'Family hash';
const String TAG_BRING_DRY_CLOTHES = 'Bring dry clothes';
const String TAG_SHORT_TRAIL = 'Short trail';
const String TAG_PARKING_AVAILABLE = 'Parking available';
const String TAG_NO_PARKING_AVAILABLE = 'No parking available';
const String TAG_CAMPING_HASH = 'Camping hash';
const String TAG_NO_BAG_DROP_AVAILABLE = 'No bag drop available';
const String TAG_DRINKING_PRACTICE = 'Drinking practice';
const String TAG_BALLBREAKER_TRAIL = 'Ballbreaker trail';
const String TAG_OLD_FARTS_TRAIL = 'Short walk / Old Farts trail';
const String TAG_BRING_DRINKING_VESSEL = 'Bring drinking vessel';
const String TAG_BRING_CHAIR = 'Bring a chair';
const String TAG_A_TO_B_RUN = 'A-to-B run';
const String TAG_DRINK_STOP = 'Drink stop';
const String TAG_SWIM_STOP = 'Swim stop';
const String TAG_HANGOVER_RUN = 'Hangover run';

const String TAG_VISIBILITY_MISMANAGEMENT = 'Mismanagement';
const String TAG_VISIBILITY_MEMBERS = 'Members';
const String TAG_VISIBILITY_FOLLOWERS = 'Followers';
const String TAG_VISIBILITY_LOCAL_HASHERS = 'Hashers in local area';
const String TAG_VISIBILITY_EVERYONE = 'Everyone';

const Map<String, int> VISIBILTY_TAGS = <String, int>{
  TAG_VISIBILITY_MISMANAGEMENT: 0x100000001,
  TAG_VISIBILITY_MEMBERS: 0x100000002,
  TAG_VISIBILITY_FOLLOWERS: 0x100000004,
  TAG_VISIBILITY_LOCAL_HASHERS: 0x100000008,
  TAG_VISIBILITY_EVERYONE: 0x100000010,
};

const Map<String, int> RUN_TAGS = <String, int>{
  TAG_NORMAL_RUN: 0x100000001,
  TAG_RED_DRESS: 0x100000002,
  TAG_FULL_MOON: 0x100000004,
  TAG_HARRIETTE: 0x100000008,
  TAG_MEN_ONLY: 0x100000010,
  TAG_WOMEN_ONLY: 0x100000020,
  TAG_KIDS_ALLOWED: 0x100000040,
  TAG_NO_KIDS_ALLOWED: 0x100000080,
  TAG_BRING_FLASHLIGHT: 0x100000100,
  TAG_WATER_ON_TRAIL: 0x100000200,
  TAG_WALKER_TRAIL: 0x100000400,
  TAG_MEDIUM_TRAIL: 0x100000800,
  TAG_LONG_TRAIL: 0x100001000,
  TAG_PUB_CRAWL: 0x100002000,
  TAG_ON_AFTER: 0x100004000,
  TAG_BABY_JOGGER_FRIENDLY: 0x100008000,
  TAG_SHIGGY_RUN: 0x100010000,
  TAG_ACCESSIBLE_BY_PUBLIC_TRANSPORT: 0x100020000,
  TAG_BIKE_HASH: 0x100040000,
  TAG_CITY_HASH: 0x100080000,
  TAG_LIVE_HARE: 0x100100000,
  TAG_DEAD_HARE: 0x100200000,
  TAG_NIGHT_RUN: 0x100400000,
  TAG_STEEP_HILLS: 0x100800000,
  TAG_CHARITY_EVENT: 0x101000000,
  TAG_DOG_FRIENDLY: 0x102000000,
  TAG_PICK_UP_HASH: 0x104000000,
  TAG_CATCH_THE_HARE: 0x108000000,
  TAG_BRING_CASH_ON_TRAIL: 0x110000000,
  TAG_BAG_DROP_AVAILABLE: 0x120000000,
  TAG_AGM: 0x140000000,
  TAG_MULTI_DAY_EVENT: 0x200000001,
  TAG_NO_DOGS_ALLOWED: 0x200000002,
  TAG_FAMILY_HASH: 0x200000004,
  TAG_BRING_DRY_CLOTHES: 0x200000008,
  TAG_SHORT_TRAIL: 0x200000010,
  TAG_PARKING_AVAILABLE: 0x200000020,
  TAG_NO_PARKING_AVAILABLE: 0x200000040,
  TAG_CAMPING_HASH: 0x200000080,
  TAG_NO_BAG_DROP_AVAILABLE: 0x200000100,
  TAG_DRINKING_PRACTICE: 0x200000200,
  TAG_BALLBREAKER_TRAIL: 0x200000400,
  TAG_OLD_FARTS_TRAIL: 0x200000800,
  TAG_BRING_DRINKING_VESSEL: 0x200001000,
  TAG_BRING_CHAIR: 0x200002000,
  TAG_A_TO_B_RUN: 0x200004000,
  TAG_DRINK_STOP: 0x200008000,
  TAG_SWIM_STOP: 0x200010000,
  TAG_HANGOVER_RUN: 0x200020000,
};

enum EScreenSize { isMobileScreen, isNarrowScreen, isNormalScreen }

// ignore: non_constant_identifier_names
const Map<String, int> SPECIAL_EVENT_STRINGS = <String, int>{
  'Not specified': 0,
  'Normal run': 1,
  'Special local event': 2,
  'Special regional / state event': 3,
  'Nash Hash / national event': 4,
  'Interhash / continental event': 5,
  'World Interhash / global event': 6,
  'Other special event': 7,
};

const Map<String, int> CAN_EDIT_RUN_ATTENDENCE_STRINGS = <String, int>{
  'Only admins can edit run attendence': 0,
  'Anyone can edit run attendence': 1,
  "Use the Kennel's default setting for run attendence": 2,
};

// int-keyed version for the run editor dropdown (-2 = use kennel setting sentinel)
const Map<int, String> CAN_EDIT_RUN_ATTENDANCE_OPTIONS = <int, String>{
  -2: 'Use Kennel Setting',
  0: 'No',
  1: 'Yes',
};

const Map<String, int> YES_NO_INHERIT = <String, int>{
  'No': 0,
  'Yes': 1,
  'Use Kennel setting': 2,
};

const Map<int?, String> HASH_RUNS_DOT_ORG_SETTINGS = <int?, String>{
  -2: 'Use Kennel Setting',
  0: 'Do not publish on the web',
  // 1: 'Publish runs on our Kennel''s Harrier Central portal only',
  // 2: 'Publish on our webpage and other hash web sites in our state / region',
  // 3: 'Publish on our webpage and other hash web sites in our country',
  // 4: 'Publish on our webpage and other hash web sites on our continent',
  5: 'Publish globally on hashruns.org',
};

const Map<int?, String> HASH_GLOBAL_CALENDAR_SETTINGS = <int?, String>{
  -2: 'Use Kennel Setting',
  0: 'Do not publish on the Harrier Central global calendar',
  1: 'Publish runs on the Harrier Central global calendar',
};

const Map<int?, String> RUN_AUDIENCE = <int?, String>{
  -2: 'Use Kennel Setting',
  0: 'No one',
  1: 'Mismanagement only',
  3: 'Mismanagement + Members',
  7: 'Mismanagement + Members + Followers',
  15: 'Everyone',
};

// ignore: non_constant_identifier_names
const List<String> INBOUND_DATA_SOURCES = <String>[
  'Not from an external data source',
  'Facebook group',
  'Google calendar',
  'San Diego website',
  '',
  'Berlin website',
];

const String RESET_TO_LOOKTHROUGH_VALUE = 'makeNull';

const String BOOL_FALSE = 'false';
const String BOOL_TRUE = 'true';

const int MINIMUM_TAGS_REQUIRED = 5;
const int MAXIMUM_TAGS_ALLOWWED = 9;

const int AUTOSAVE_PERIOD_IN_SECONDS = 60;
const int AUTOSAVE_INTERVAL_IN_MILLISECONDS = 5000;

const double SIDEBAR_WIDTH = 300;

// class AppAccess {
//   AppAccess(
//     this.appAccessFlags,
//   );

//   int appAccessFlags;

//   bool getAppAccess(int aaFlag) {
//     return appAccessFlags & aaFlag != 0;
//   }

//   // ignore: avoid_positional_boolean_parameters
//   void setAppAccess(int aaFlag, bool value) {
//     if (value) {
//       appAccessFlags |= aaFlag;
//     } else {
//       appAccessFlags &= ~aaFlag;
//     }
//   }

//   bool get isAdmin {
//     return appAccessFlags & authIsAdmin != 0;
//   }

//   bool get isSuperAdmin {
//     return appAccessFlags & authIsSuperAdmin != 0;
//   }

//   bool get canManageKennel {
//     return appAccessFlags & authCanManageKennel != 0;
//   }

//   bool get canManageRuns {
//     return appAccessFlags & authCanManageRuns != 0;
//   }

//   bool get canManageHashCash {
//     return appAccessFlags & authCanManageHashCash != 0;
//   }

//   bool get canManageMembers {
//     return appAccessFlags & authCanManageMembers != 0;
//   }

//   bool get canManageAwards {
//     return appAccessFlags & authCanManageAwards != 0;
//   }
// }
