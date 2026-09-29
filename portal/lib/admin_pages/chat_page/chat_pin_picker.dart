// "Drop a pin" for a chat location (E9.F1.S12, 2026-09-29).
//
// The same Google-tile map the run editor's Location tab uses (package:map),
// with a crosshair at the centre: drag the map until the crosshair is on the
// spot and send. A "lat, lng" field accepts pasted coordinates and moves the
// map there. MapLayout does not listen to its controller, so the map is
// wrapped in a ListenableBuilder rather than a StatefulWidget.

import 'package:hcportal/admin_pages/chat_page/chat_message_kinds.dart';
import 'package:hcportal/imports.dart';
import 'package:latlng/latlng.dart';
import 'package:map/map.dart' as geo_map;

typedef ChatPin = ({double lat, double lng});

class ChatPinPickerController extends GetxController {
  ChatPinPickerController({required double lat, required double lng})
    : mapController = geo_map.MapController(
        location: LatLng(Angle.degree(lat), Angle.degree(lng)),
        zoom: 15,
      );

  final geo_map.MapController mapController;
  final TextEditingController coordsField = TextEditingController();
  final RxnString coordsError = RxnString();

  Offset _dragStart = Offset.zero;
  double _zoomStart = 15;

  ChatPin get centre => (
    lat: mapController.center.latitude.degrees,
    lng: mapController.center.longitude.degrees,
  );

  void onScaleStart(ScaleStartDetails d) {
    _dragStart = d.focalPoint;
    _zoomStart = mapController.zoom;
  }

  void onScaleUpdate(ScaleUpdateDetails d, geo_map.MapTransformer t) {
    if ((d.scale - 1.0).abs() > 0.01) {
      mapController.zoom = (_zoomStart * d.scale).clamp(1.0, 20.0);
    }
    final diff = d.focalPoint - _dragStart;
    _dragStart = d.focalPoint;
    t.drag(diff.dx, diff.dy);
  }

  void onPointerSignal(PointerSignalEvent e) {
    if (e is PointerScrollEvent) {
      mapController.zoom = (mapController.zoom - e.scrollDelta.dy / 100.0)
          .clamp(1.0, 20.0);
    } else if (e is PointerScaleEvent) {
      mapController.zoom = (mapController.zoom * e.scale).clamp(1.0, 20.0);
    }
  }

  void zoomIn() =>
      mapController.zoom = (mapController.zoom + 1).clamp(1.0, 20.0);
  void zoomOut() =>
      mapController.zoom = (mapController.zoom - 1).clamp(1.0, 20.0);

  /// Moves the map to pasted "lat, lng".
  void goToTyped() {
    final p = parseLatLng(coordsField.text);
    if (p == null) {
      coordsError.value = 'Enter latitude, longitude — e.g. 51.5074, -0.1278';
      return;
    }
    coordsError.value = null;
    mapController.center = LatLng(Angle.degree(p.lat), Angle.degree(p.lng));
  }

  @override
  void onClose() {
    coordsField.dispose();
    mapController.dispose();
    super.onClose();
  }
}

/// Opens the picker; resolves to the chosen point, or null on cancel.
Future<ChatPin?> showChatPinPicker({double? lat, double? lng}) async {
  final hasStart = lat != null && lng != null && !(lat == 0 && lng == 0);
  final tag = UniqueKey().toString();
  final c = Get.put(
    ChatPinPickerController(
      lat: hasStart ? lat : 51.5074, // no run location: London
      lng: hasStart ? lng : -0.1278,
    ),
    tag: tag,
  );
  try {
    return await Get.dialog<ChatPin>(_ChatPinPickerDialog(c));
  } finally {
    await Get.delete<ChatPinPickerController>(tag: tag, force: true);
  }
}

class _ChatPinPickerDialog extends StatelessWidget {
  const _ChatPinPickerDialog(this.c);

  final ChatPinPickerController c;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Drop a pin', textAlign: TextAlign.center),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Drag the map until the target is on the spot.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            SizedBox(height: 380, child: _map()),
            const SizedBox(height: 12),
            Obx(
              () => TextField(
                controller: c.coordsField,
                decoration: InputDecoration(
                  labelText: 'Or paste coordinates (lat, lng)',
                  errorText: c.coordsError.value,
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: IconButton(
                    tooltip: 'Go there',
                    icon: const Icon(Icons.search),
                    onPressed: c.goToTyped,
                  ),
                ),
                onSubmitted: (_) => c.goToTyped(),
              ),
            ),
            const SizedBox(height: 8),
            ListenableBuilder(
              listenable: c.mapController,
              builder: (_, _) => Text(
                chatLocationLabel(c.centre.lat, c.centre.lng),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        Builder(
          builder: (ctx) => ElevatedButton(
            style: hcDialogButtonStyle(hcDialogCancelColor),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', textAlign: TextAlign.center),
          ),
        ),
        Builder(
          builder: (ctx) => ElevatedButton(
            style: hcDialogButtonStyle(hcDialogPrimaryColor),
            onPressed: () => Navigator.of(ctx).pop<ChatPin>(c.centre),
            child: const Text(
              'Send this location',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _map() => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade400),
      borderRadius: BorderRadius.circular(8),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ListenableBuilder(
        listenable: c.mapController,
        builder: (_, _) => geo_map.MapLayout(
          controller: c.mapController,
          builder: (context, transformer) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTap: c.zoomIn,
            onScaleStart: c.onScaleStart,
            onScaleUpdate: (d) => c.onScaleUpdate(d, transformer),
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerSignal: c.onPointerSignal,
              child: Stack(
                children: [
                  geo_map.TileLayer(
                    builder: (context, x, y, z) => Image.network(
                      'https://www.google.com/maps/vt/pb=!1m4!1m3!1i$z!2i$x!3i$y!2m3!1e0!2sm!3i420120488!3m7!2sen!5e1105!12m4!1e68!2m2!1sset!2sRoadmap!4e0!5m1!1e0!23i4111425',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                  Center(
                    child: IgnorePointer(
                      child: Image.asset(
                        'images/maps/map_center_target.png',
                        width: 120,
                        height: 120,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _zoomButton(Icons.add, 'Zoom in', c.zoomIn),
                        const SizedBox(height: 6),
                        _zoomButton(Icons.remove, 'Zoom out', c.zoomOut),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _zoomButton(IconData icon, String tooltip, VoidCallback onPressed) =>
      IconButton.filled(
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E293B),
        ),
        icon: Icon(icon),
        onPressed: onPressed,
      );
}
