import 'package:harrier_central/imports.dart';

/// Name + avatar of one photographer, as the photo viewer's footer shows it.
typedef PhotographerInfo = ({String name, String photo});

/// Resolves photographer name + avatar for every distinct uploader in
/// [photos], keyed by normalised userId. One local read per distinct
/// uploader, so N photos = at most N distinct reads.
///
/// The ONE place the run-photo entry points (Photos tab, Featured strip,
/// PackTrack map) turn a `UserId` into what the footer draws. The Featured
/// strip had its own copy that passed the name and forgot the avatar, so every
/// photographer wore the default bunny (James, 2026-09-30).
///
///  - Name: others carry `uploaderDisplayName` from the SP; own photos use the
///    signed-in user's stored display name.
///  - Avatar: the raw `colPhoto` value from the local hashers table (http or
///    `bundle://`) — resolved for display via `avatarImageProvider`.
Future<Map<String, PhotographerInfo>> resolvePhotographersFor(
  Iterable<RunPhotoModel> photos,
) async {
  final result = <String, PhotographerInfo>{};
  final currentUserId = normalizeUuid(
    getStringPref(StringPrefsEnum.userId) ?? '',
  );
  for (final p in List<RunPhotoModel>.of(photos)) {
    final uid = normalizeUuid(p.userId ?? '');
    if (uid.isEmpty || result.containsKey(uid)) continue;

    var name = p.uploaderDisplayName ?? '';
    if (name.isEmpty && uid == currentUserId) {
      name = getStringPref(StringPrefsEnum.displayName) ?? '';
    }

    var photo = '';
    final rows = await QueryUsers.querySingleUser(uid);
    if (rows.isNotEmpty) {
      photo =
          (rows.first[tableModel.hashersTableHelper.colPhoto] as String?) ?? '';
    }

    result[uid] = (name: name, photo: photo);
  }
  return result;
}
