import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

/// Bundled avatar shown when a hasher has no photo at all (null/empty). Matches
/// the generic default used across the app.
const String kDefaultAvatarAsset = 'images/avatars/avatar-2.jpg';

/// Base URL for the avatar images mirrored to Azure Blob storage. These are the
/// same images as the bundled `images/avatars/avatar-N.jpg` assets, now served
/// over http so BOTH the app and the public web can render them as normal
/// network images. New signups store `bundledAvatarUrl(n)` instead of the legacy
/// `bundle://avatar-N` scheme; existing `bundle://` values are migrated in the
/// DB. The `bundle://` branch in [avatarImageProvider] remains only as a
/// fallback for old rows / old app versions during the transition.
const String kAvatarBaseUrl =
    'https://harriercentral.blob.core.windows.net/profile-photos';

/// The public http URL for bundled avatar number [n] (0–50).
String bundledAvatarUrl(int n) => '$kAvatarBaseUrl/avatar-$n.jpg';

/// Translates a stored hasher `photo` value to a renderable http URL.
///
///  - `bundle://avatar-N` → the mirrored blob URL
///    (`$kAvatarBaseUrl/avatar-n.jpg`, lowercased). Old app versions (≤ 2.1.x)
///    still create `bundle://` values on signup, so the 3.0 app translates them
///    here rather than depending on the bundled assets — this keeps them
///    rendering (from the network, same as the web) even after the bundled
///    assets are eventually dropped from the app.
///  - `http(s)://…` or anything else → returned unchanged.
///  - null / empty → null.
///
/// Note: `bundle://` always maps to `.jpg`, matching the stored data (numeric
/// avatars + `avatar-null`). The `.png` `avatar-virgin` / `avatar-visitor`
/// assets are never stored as photo values, so they need no special case.
String? blobUrlForPhoto(String? photo) {
  final p = (photo ?? '').trim();
  if (p.isEmpty) return null;
  if (p.toLowerCase().startsWith('bundle://')) {
    return '$kAvatarBaseUrl/${p.toLowerCase().replaceFirst('bundle://', '')}.jpg';
  }
  return photo;
}

/// Resolves a hasher `photo` value (HC.Hasher.Photo / `colPhoto`) to an
/// [ImageProvider]. Values are one of:
///
///  - `http(s)://…`       → cached network image
///  - `bundle://avatar-N` → translated to its blob URL via [blobUrlForPhoto]
///    and loaded from the network (NOT the local asset), so old-app-created
///    bundle values render consistently and survive removal of bundled assets
///  - null / empty / anything else → [kDefaultAvatarAsset]
///
/// Use this everywhere a hasher avatar is shown so bundled avatars and the
/// no-photo case render a real image instead of a blank/broken one.
ImageProvider avatarImageProvider(String? photo) {
  final p = (blobUrlForPhoto(photo) ?? '').trim();
  if (p.startsWith('http')) {
    return CachedNetworkImageProvider(p);
  }
  return const AssetImage(kDefaultAvatarAsset);
}
