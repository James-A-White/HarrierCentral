# HC — Hasher Avatars & Profile Photos

> **Load this skill whenever you render a hasher's avatar/profile photo, or read
> the `photo` field.** The `photo` value is NOT always a URL — it is often a
> `bundle://avatar-N` reference to a bundled asset. Calling `Image.network()` on
> it renders a blank/broken image with no error. This is a silent, recurring
> trap (it caused blank runner pins on the PackTrack map, fixed 2026-07-16).

Every hasher has a single `photo` string (`HC.Hasher.Photo`, surfaced as the
`colPhoto` column, e.g. `tableModel.hashersTableHelper.colPhoto`). It is the one
source for their avatar everywhere — profile, member lists, run admin, Down
Downs, PackTrack runner pins/carousel, etc.

---

## The three shapes of `photo`

| Value | Meaning | How to render |
|---|---|---|
| `http(s)://…` | An **uploaded** profile photo | Network image (prefer cached) |
| `bundle://avatar-N` | A **bundled avatar the user picked** (or was assigned) | `AssetImage('images/avatars/avatar-n.jpg')` — strip `bundle://`, lowercase, append `.jpg` |
| `null` / empty / anything else | **No photo** | The default bundled avatar (`images/avatars/avatar-2.jpg`) |

**Most photo-less users are the middle case, not the null case.** Signup assigns
a random bundled avatar — `bundle://avatar-${Random.secure().nextInt(49) + 1}`
(see `create_new_account.dart`, `use_invite_code_page.dart`,
`hasher_profile_page.dart`). So a user who "has no photo" usually has a
`bundle://avatar-N` string, which **fails `Image.network`**.

---

## Use the canonical resolver — don't hand-roll it

`lib/util/avatar.dart` (exported via `imports.dart`):

```dart
ImageProvider avatarImageProvider(String? photo)
```

- `http…`        → `CachedNetworkImageProvider(photo)`
- `bundle://…`   → `AssetImage('images/avatars/<name>.jpg')` (lowercased)
- null/empty/other → `AssetImage(kDefaultAvatarAsset)` (`avatar-2.jpg`)

Render it with `Image(image: avatarImageProvider(photo), fit: BoxFit.cover)` (or
feed the provider to `CircleAvatar.backgroundImage`, `DecorationImage`, etc).

**Never** do `Image.network(photo)` directly — it blanks on `bundle://` values.

---

## The bundled asset set (`images/avatars/`)

- `avatar-0.jpg` … `avatar-50.jpg` — the picker set (`avatar_icons_page.dart`
  offers `avatar-${index+1}`; signup assigns `avatar-1`..`avatar-49`).
- `avatar-2.jpg` — the **generic default** used across the app for "no photo".
- `avatar-null.jpg` — a "null" placeholder variant (jpg).
- `avatar-virgin.png`, `avatar-visitor.png` — special-case avatars, and the
  **only `.png`** ones. `images/icons/avatar.png` is the pick-an-avatar icon.

### `.jpg` gotcha
The whole app maps `bundle://<name>` → `<name>.jpg`. So `bundle://avatar-virgin`
would resolve to the non-existent `avatar-virgin.jpg`. That's a pre-existing
inconsistency — the `.png` specials aren't used as ordinary `photo` values.
`avatarImageProvider` matches the established `.jpg` convention on purpose (don't
"fix" it here without checking every call site).

---

## Where the value comes from

- Stored in `HC.Hasher.Photo`; read via `colPhoto`.
- In PackTrack, `RunTrackerMapController.userLogos[userId]` caches the **raw**
  `colPhoto` (hydrated by `_hydrateLogos` → `QueryUsers.querySingleUser`) — so it
  can be a URL **or** a `bundle://` string. Resolve it with `avatarImageProvider`.

---

## Legacy: inline resolvers — MIGRATED (2026-07-18)

The old inline http/bundle/default branch (a latent `bundle://` trap if copied
wrong) has been removed from every known hasher-avatar site. All now route
through `avatarImageProvider` (rendering) / `blobUrlForPhoto` (zoom-page URL),
so `bundle://` values are translated to their blob http URL instead of a bundled
asset. Migrated: `util/utilities_null_safe.dart` (`getProfilePic`),
`widgets/kennel_member_list_item.dart`, `pages/run_admin/find_hasher_page.dart`,
`pages/run_admin/down_downs_page.dart`,
`pages/run_admin/check_in_pack_page/check_in_pack_page.dart`,
`pages/init/choose_profile_image.dart` (`getProfilePhoto`),
`widgets/profile_photo.dart`, `widgets/run_tabs.dart` (`_hasherPhoto` +
`_getHasherZoomablePhoto`).

**Rule for new code:** never hand-roll the http/bundle/default branch again —
always use `avatarImageProvider(photo)` for an `ImageProvider`, or
`blobUrlForPhoto(photo)` when you need the raw http URL (e.g. `ZoomableImagePage2`).
`kennel_logo.dart` is NOT an avatar resolver — kennel logos are a separate
`.png` scheme and are intentionally untouched.
