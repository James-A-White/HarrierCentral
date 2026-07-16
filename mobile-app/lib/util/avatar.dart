import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

/// Bundled avatar shown when a hasher has no photo at all (null/empty). Matches
/// the generic default used across the app.
const String kDefaultAvatarAsset = 'images/avatars/avatar-2.jpg';

/// Resolves a hasher `photo` value (HC.Hasher.Photo / `colPhoto`) to an
/// [ImageProvider]. The value is one of:
///
///  - `http(s)://…`      → an uploaded profile photo (cached network image)
///  - `bundle://avatar-N` → a bundled avatar the user picked, mapped to
///    `images/avatars/avatar-n.jpg` (lowercased). Most photo-less users have one
///    of these, assigned at signup — NOT a plain URL, so `Image.network` on it
///    fails and renders blank. That's exactly the trap this helper avoids.
///  - null / empty / anything else → [kDefaultAvatarAsset]
///
/// Use this everywhere a hasher avatar is shown so bundled avatars and the
/// no-photo case render a real image instead of a blank/broken one.
///
/// Note: the `bundle://` → `.jpg` mapping matches the rest of the app; the
/// `avatar-virgin` / `avatar-visitor` assets are `.png` and are the known
/// exception (not used as ordinary photo values).
ImageProvider avatarImageProvider(String? photo) {
  final p = (photo ?? '').trim();
  if (p.startsWith('http')) {
    return CachedNetworkImageProvider(p);
  }
  if (p.toLowerCase().startsWith('bundle://')) {
    return AssetImage(
      'images/avatars/${p.toLowerCase().replaceFirst('bundle://', '')}.jpg',
    );
  }
  return const AssetImage(kDefaultAvatarAsset);
}
