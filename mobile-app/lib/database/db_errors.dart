// ignore_for_file: constant_identifier_names

const int DB_ERROR_EMAIL_ALREADY_EXISTS = 10005;

/// hcapp_authorizeDevice: the invite code did not match any hasher.
/// On a code the user just typed this almost always means a typo. On a code
/// read back from storage it means the stored code is dead — it was almost
/// certainly regenerated when someone requested a fresh one by email.
const int DB_ERROR_INVITE_CODE_NOT_FOUND = 1302;

/// hcapp_authorizeDevice: the invite code resolved to a REMOVED account.
/// Note this means the code was entered *correctly* — never ask the user to
/// retype it. It does not mean the person has no account: they may well have
/// a second, live one they do not know about (kennel admins create accounts
/// on members' behalf), so send them to look themselves up.
const int DB_ERROR_ACCOUNT_REMOVED = 1402;

/// True when [errorCode] means a reset/invite code can never work again, so a
/// stored copy should be discarded. Deliberately an allowlist: any other
/// outcome — no network, timeout, 500, unparseable body, token failure from a
/// skewed device clock — must KEEP the stored code. It is the only durable
/// recovery key a device has, and wrongly discarding it locks the user out.
bool isDeadInviteCode(int? errorCode) =>
    errorCode == DB_ERROR_INVITE_CODE_NOT_FOUND ||
    errorCode == DB_ERROR_ACCOUNT_REMOVED;
