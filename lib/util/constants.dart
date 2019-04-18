
// lat lon of London Eye
const double DEFAULT_LATITUDE = 51.5033;
const double DEFAULT_LONGITUDE = 0.1195;

const int SPLASH_SCREEN_DISPLAY_TIME = 1;

const String BASE_API_URL = 'https://harrier.azurewebsites.net/api/';

const String BASE_PROFILE_PHOTOS_URL = 'https://harriercentral.blob.core.windows.net/profile-photos/';

const String EMAIL_PAYMENT_API_URL = 'https://hcazurefunctions7.azurewebsites.net/api/SendPaymentReport';
const String EMAIL_RUN_REPORT_API_URL = 'https://hcazurefunctions7.azurewebsites.net/api/SendRunCountsReport';
//const String EMAIL_PAYMENT_API_KEY = 'x1RkI1c7tVCEGO2vQvL6yk6ebtCiitOrTb6aVr5LyqiNRTe91H0Nbw==';

const String ERROR_KEY = 'HC_ERROR';

const String GUID_EMPTY = '00000000-0000-0000-0000-000000000000';

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

const int cacheDurationAllHashers = 60 * 86400000; // 60 days cache duration








