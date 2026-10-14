import 'package:harrier_central/imports.dart';
import 'package:harrier_central/util/social_links.dart';

/// A kennel's social and chat links for THIS caller (E12.F4.S4), from
/// HC6.hcapp_getKennelSocialLinks. Fetched when the kennel page opens and
/// never synced: members-only entries are chat-group invite links, and the
/// kennels sync goes to every phone. Read-only — no idempotency concern.
class KennelSocialLinksService {
  KennelSocialLinksService._();

  /// The links in stored order (already vetted by [socialLinksFromJson]) and
  /// whether the members-only ones were included. Null when the call failed —
  /// offline, auth refused, an unreadable reply. No error dialog: the page
  /// simply shows no icons.
  static Future<({List<SocialLink> links, bool includesMembers})?> fetch(
    HcId kennelId,
  ) async {
    final String userId = currentUserId;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String secret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';
    if (userId.isEmpty || deviceId.isEmpty || secret.isEmpty) return null;
    if (!kennelId.isValid) return null;

    final String result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': 'getKennelSocialLinks',
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          userId,
          'hcapp_getKennelSocialLinks',
          paramString: secret,
        ),
        'kennelId': kennelId,
      }),
      errorCallback: (_) async => true,
    );
    if (result.startsWith(ERROR_PREFIX)) return null;
    return parseReply(result);
  }

  /// The SP's reply → links, or null for an error row or anything unreadable.
  /// Split out so the unit test can feed it replies.
  static ({List<SocialLink> links, bool includesMembers})? parseReply(
    String result,
  ) {
    try {
      final Object? outer = jsonDecode(result);
      if (outer is! List || outer.isEmpty || outer[0] is! List) return null;
      final List<dynamic> rowset = outer[0] as List<dynamic>;
      if (rowset.isEmpty || rowset[0] is! Map<String, dynamic>) return null;
      final Map<String, dynamic> row = rowset[0] as Map<String, dynamic>;
      // Auth failure: rowset 0 is the standard error-detail row instead.
      if (row.containsKey('errorId')) return null;
      final Object? raw = row['socialLinksJson'];
      final Object? inc = row['includesMembers'];
      return (
        links: socialLinksFromJson(raw is String ? raw : null),
        includesMembers: inc == true || inc == 1,
      );
    } catch (e, s) {
      BootLogger.logError(
        '[ERROR][SOCIAL]',
        'kennel social links unreadable: $e',
        s,
      );
      return null;
    }
  }
}
