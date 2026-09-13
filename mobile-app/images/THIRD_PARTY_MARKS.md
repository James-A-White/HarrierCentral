# Third-party marks in `images/icons/`

Most icons in `images/icons/` are ours. These four are not — they are other companies'
product marks, used to point at the device's own camera and photo library so
the button reads without a label:

| File | Mark | Status |
|---|---|---|
| `android_gallery.png` | Google Photos | **Temporary placeholder** — see below |
| `ios_gallery.png` | Apple Photos | Current |
| `android_camera.png` | Android camera | Current |
| `ios_camera.png` | Apple Camera | Current |

Used by the profile-photo picker (`choose_profile_image.dart`) and the two
"Share my photos" buttons (`kennel_admin_main.dart`, `run_details.dart`),
each chosen at runtime by platform.

## android_gallery.png — replace when convenient

Carried the **2015–2020** Google Photos pinwheel until 2026-09-13, five years
stale. Swapped for the current (December 2025) mark rendered from Wikimedia
Commons `File:Google Photos (2025, no background).svg` — published as a public
domain text logo, and still a Google trademark.

It is a stand-in, not a sanctioned asset. Google's brand guidelines ask for
the mark from their own kit, so replace this with Google's own file when
there is a reason to touch it.

Every one of these ages on someone else's schedule. If that becomes a chore,
the alternative is a neutral Material `Icons.photo_library` in Harrier Central
red — less instantly recognisable, but ours.
