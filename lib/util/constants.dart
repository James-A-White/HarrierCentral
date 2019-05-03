
// lat lon of London Eye
const double DEFAULT_LATITUDE = 51.5033;
const double DEFAULT_LONGITUDE = 0.1195;

const int LOGIN_TIMEOUT = 10;
const int DEFAULT_HTTP_TIMEOUT = 10;

const int SPLASH_SCREEN_DISPLAY_TIME = 1;

const String BASE_API_URL = 'https://harrier.azurewebsites.net/api/';

const String BASE_PROFILE_PHOTOS_URL = 'https://harriercentral.blob.core.windows.net/profile-photos/';
const String BASE_RECEIPTS_URL =       'https://harriercentral.blob.core.windows.net/receipts/';

const String EMAIL_PAYMENT_API_URL = 'https://hcazurefunctions7.azurewebsites.net/api/SendPaymentReport';
const String EMAIL_RUN_REPORT_API_URL = 'https://hcazurefunctions7.azurewebsites.net/api/SendRunCountsReport';
const String EMAIL_KENNEL_RUN_STATS_API_URL = 'https://hcazurefunctions7.azurewebsites.net/api/SendKennelRunStatsReport';



const String ERROR_KEY = 'HC_ERROR';

const String GUID_EMPTY = '00000000-0000-0000-0000-000000000000';
const String GUID_8 =     '88888888-8888-8888-8888-888888888888';
const String GUID_9 =     '99999999-9999-9999-9999-999999999999';
const String GUID_MAX =   'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF';

const String DB_NAME = 'HcDb.db';


const int mmAuthIsGm = 0x80000000;                // TODO(James): Needs implementation
const int mmAuthCanGrantPermissions = 0x40000000; // TODO(James): Needs implementation

const int mmAuthAllowEditRsvpFlag = 0x00000001;
const int mmAuthAllowCheckInAndOutFlag = 0x00000002;
const int mmAuthAllowHashCashFlag = 0x00000004;
const int mmAuthAllowAddNewMemberFlag = 0x00000008; 
const int mmAuthAllowEnableDisableFacebookEvents = 0x00000010; // TODO(James): Needs implementation
const int mmAuthEditRuns = 0x00000020; // TODO(James): Needs implementation
const int mmAuthGenerateRunQrCodes = 0x00000040; // TODO(James): Needs implementation
const int mmAuthManageMembers = 0x00000080; // TODO(James): Needs implementation
const int mmAuthAccessKennelAdmin = 0x00000100; // TODO(James): Needs implementation

const int cacheDurationAllHashers = 60 * 86400000; // 60 days cache duration








