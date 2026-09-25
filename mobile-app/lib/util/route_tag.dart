import 'package:flutter/widgets.dart';

/// A GetX tag that belongs to ONE page, not to the thing the page shows.
///
/// A controller tagged by an id alone (`runtabs-<eventId>`) is shared by
/// every page showing that id. GetX deletes a controller when the page that
/// CREATED it goes away, so two pages for the same run break each other: a
/// notification tap pops the open run page and pushes a fresh one in the same
/// frame, the fresh page finds the old page's controller still registered and
/// adopts it, and when the pop animation ends the old page deletes it —
/// TabController, MapController and all — from under the page on screen
/// ("Cannot add new events after calling close" from flutter_map and a
/// null-check in TabBar's _DragAnimation, build 1401, 2026-09-25).
///
/// Appending the route's identity gives each page its own controllers. Any
/// widget inside the same page gets the same tag; a second page for the same
/// run gets a different one. Outside a route (tests, overlays) the base tag
/// is returned unchanged.
String routeScopedTag(BuildContext context, String base) {
  final ModalRoute<Object?>? route = ModalRoute.of(context);
  if (route == null) return base;
  return '$base@r${_routeIds[route] ??= ++_nextRouteId}';
}

// Sequential rather than identityHashCode, which is not guaranteed unique.
// Expando holds the route weakly, so a popped route's id is not kept alive.
final Expando<int> _routeIds = Expando<int>('routeScopedTag');
int _nextRouteId = 0;
