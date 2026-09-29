# flutter_vector_icons 2.0.0 — Harrier Central patched copy

A verbatim copy of the pub.dev package with FOUR constants removed, each of
which names a code point its font does not contain:

- `FontAwesome5.font_awesome_logo_full` (regular, brands and solid) — 0xF4E6
- `MaterialCommunityIcons.blank` — 0xF68C

Flutter's icon tree-shaker aborts the entire web build on any such constant
("Codepoint N not found in font, aborting"), which is why the portal had to
build with `--no-tree-shake-icons` until 2026-09-29. `pubspec.yaml` points at
this copy through `dependency_overrides`. Nothing in the portal used the four
icons. If the package is upgraded, re-apply or drop this copy.
