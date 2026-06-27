import 'package:flutter/cupertino.dart';
import 'package:harrier_central/imports.dart';
import 'package:latlong2/latlong.dart' as latlng;

class RunTrackerMap extends StatelessWidget {
  const RunTrackerMap(
    this.event,
    this.eventLocation,
    this.mapCenter,
    this.kennelLocation,
    this.minZoom,
    this.maxZoom,
    this.zoom,
    this.trueNorthLock, {
    super.key,
    this.markerClicked,
    this.mapMoved,
    this.overlayBottomPadding = -25.0,
  });

  final EventModel event;
  final latlng.LatLng? eventLocation;
  final latlng.LatLng mapCenter;
  final latlng.LatLng kennelLocation;
  final double minZoom;
  final double maxZoom;
  final double zoom;
  final bool trueNorthLock;
  final Function? markerClicked;
  final Function? mapMoved;
  final double overlayBottomPadding;

  String get _controllerTag => event.eventId;

  @override
  Widget build(BuildContext context) {
    final bool alreadyRegistered = Get.isRegistered<RunTrackerMapController>(
      tag: _controllerTag,
    );

    return GetBuilder<RunTrackerMapController>(
      tag: _controllerTag,
      init: alreadyRegistered
          ? null
          : RunTrackerMapController(
              event: event,
              eventLocation: eventLocation,
              mapCenter: mapCenter,
              kennelLocation: kennelLocation,
              minZoom: minZoom,
              maxZoom: maxZoom,
              initialZoom: zoom,
              trueNorthLock: trueNorthLock,
            ),
      builder: (controller) {
        controller.updateTrueNorthLock(trueNorthLock);
        return Obx(() {
          final bool controllerLock = controller.trueNorthLock;
          return Stack(
            children: <Widget>[
              FlutterMap(
                mapController: controller.mapController,
                options: controllerLock
                    ? _lockedMapOptions(controller)
                    : _unlockedMapOptions(controller),
                children: <Widget>[
                  TileLayer(
                    urlTemplate:
                        'http://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                    subdomains: const <String>['mt0', 'mt1', 'mt2', 'mt3'],
                  ),

                  PolylineLayer(polylines: controller.dimmedPolylines),
                  if (controller.highlightedPolyline != null)
                    PolylineLayer(polylines: [controller.highlightedPolyline!]),
                  MarkerLayer(
                    markers: <Marker>[
                      if ((appModel.hasLocationPermissions) &&
                          (deviceInfo.deviceLat != null) &&
                          (deviceInfo.deviceLon != null)) ...<Marker>[
                        Marker(
                          height: 50.0,
                          width: 50.0,
                          point: latlng.LatLng(
                            deviceInfo.deviceLat!,
                            deviceInfo.deviceLon!,
                          ),
                          child: GestureDetector(
                            child: Container(
                              padding: const EdgeInsets.all(1.0),
                              height: 50.0,
                              width: 50.0,
                              child: IgnorePointer(
                                ignoring: true,
                                child: Image.asset(
                                  'images/other/map_current_location.png',
                                  height: 50.0,
                                  width: 50.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (eventLocation != null) ...<Marker>[
                        Marker(
                          width: 120.0,
                          height: 120.0,
                          point: eventLocation!,
                          child: GestureDetector(
                            onTap: () {
                              markerClicked?.call();
                            },
                            child: Container(
                              padding: const EdgeInsets.only(bottom: 58.0),
                              child: Image.asset(
                                'images/icons/map_pin_foot.png',
                              ),
                            ),
                          ),
                        ),
                      ],

                      ...controller.checkpointMarkers,
                    ],
                  ),
                  MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      maxClusterRadius: 40,
                      size: const Size(52, 52),
                      spiderfyCircleRadius: 90,
                      markers: controller.photoCheckpointMarkers,
                      builder: (context, markers) => Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.photo_camera, color: Colors.white, size: 18),
                            Text(
                              '${markers.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  MarkerLayer(markers: controller.runnerMarkers),
                ],
              ),
              _buildTimelineSlider(context, controller),
              _buildTrailFilterChips(controller),
            ],
          );
        });
      },
    );
  }

  MapOptions _lockedMapOptions(RunTrackerMapController controller) {
    return MapOptions(
      interactionOptions: InteractionOptions(
        flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
      ),
      initialCenter: controller.mapCenterPoint,
      initialZoom: controller.initialZoom,
      minZoom: controller.minZoom,
      maxZoom: controller.maxZoom,
      initialRotation: 0.0,
    );
  }

  MapOptions _unlockedMapOptions(RunTrackerMapController controller) {
    return MapOptions(
      interactionOptions: InteractionOptions(
        flags:
            InteractiveFlag.pinchZoom |
            InteractiveFlag.drag |
            InteractiveFlag.rotate,
      ),
      initialCenter: controller.mapCenterPoint,
      initialZoom: controller.initialZoom,
      minZoom: controller.minZoom,
      maxZoom: controller.maxZoom,
    );
  }

  Widget _buildTimelineSlider(
    BuildContext context,
    RunTrackerMapController controller,
  ) {
    if (!controller.timelineAvailable) return const SizedBox.shrink();

    final bool hasRunners = controller.userPositions.isNotEmpty;

    return Positioned(
      left: 0,
      right: 0,
      bottom: overlayBottomPadding,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 12.0,
                right: 12.0,
                top: 10.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hasRunners) ...[
                    _buildRunnerPicker(controller),
                    const SizedBox(height: 2.0),
                  ],
                  _buildTimelineInfo(controller),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineInfo(RunTrackerMapController controller) {
    final label = controller.formattedTimelineLabel;
    final distanceLabel = controller.formattedDistanceLabel;
    final headingText = distanceLabel.isEmpty
        ? label
        : '$label\r\n$distanceLabel';

    return SizedBox(
      height: 70.0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                headingText,
                textAlign: TextAlign.center,
                style: ts_listValueStyle,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    controller.isPlaying.value ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: controller.togglePlayback,
                ),
                Expanded(
                  child: Slider(
                    value: controller.currentTimestampMs.value!,
                    min: controller.minTimestampMs.value!,
                    max: controller.maxTimestampMs.value!,
                    onChanged: controller.seekTo,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrailFilterChips(RunTrackerMapController controller) {
    final present = controller.presentTrailValues;
    // Only worth showing when there's an actual choice between lanes.
    if (present.length < 2) return const SizedBox.shrink();
    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final v in present) ...[
              _trailFilterChip(controller, v),
              const SizedBox(width: 6),
            ],
          ],
        ),
      ),
    );
  }

  Widget _trailFilterChip(RunTrackerMapController controller, int value) {
    final type = controller.trailTypeFor(value);
    final selected = controller.selectedTrailValues.contains(value);
    return GestureDetector(
      onTap: () => controller.toggleTrailFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.blue.shade700 : Colors.black54,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.white : Colors.white30,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (type.emoji.isNotEmpty) ...[
              Text(type.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
            ],
            Text(
              type.label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunnerPicker(RunTrackerMapController controller) {
    final runners = controller.visibleRunners;
    if (runners.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 80.0,
      child: CupertinoPicker(
        backgroundColor: Colors.transparent,
        magnification: 1.1,
        squeeze: 0.95,
        useMagnifier: true,
        itemExtent: 32,
        scrollController: controller.runnerPickerController,
        selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
          background: Colors.white.withValues(alpha: 0.12),
        ),
        onSelectedItemChanged: (index) {
          if (index >= 0 && index < runners.length) {
            controller.selectRunner(runners[index].id, recenter: true);
          }
        },
        children: runners
            .map((runner) {
              final isSelected = controller.selectedRunnerId.value == runner.id;
              final baseName = controller.userNames[runner.id] ?? 'Runner';
              // Prefix the runner's trail-lane emoji as a lightweight badge
              // (track colour still carries runner identity).
              final emoji =
                  controller.trailTypeFor(controller.trailValueForRunner(runner)).emoji;
              final name = emoji.isNotEmpty ? '$emoji $baseName' : baseName;
              final color = controller.runnerColor(runner.id);
              final logo = controller.userLogos[runner.id];
              return Stack(
                children: [
                  // Name centered over the full picker width — aligns with
                  // the timestamp/distance text in the section below.
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSelected ? 18 : 16,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                  // Dot + avatar left-aligned with a small inset so the dot
                  // is never flush against the picker's clipping edge.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildRunnerColorDot(color),
                          const SizedBox(width: 6),
                          _buildRunnerAvatar(logo, isSelected: isSelected),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            })
            .toList(growable: false),
      ),
    );
  }

  Widget _buildRunnerColorDot(Color color) {
    return Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1,
        ),
      ),
    );
  }

  Widget _buildRunnerAvatar(String? logo, {required bool isSelected}) {
    final double size = isSelected ? 34 : 30;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: isSelected ? 0.9 : 0.6),
          width: 1.4,
        ),
      ),
      child: ClipOval(
        child: (logo != null && logo.isNotEmpty)
            ? Image.network(logo, fit: BoxFit.cover)
            : Container(
                color: Colors.white.withValues(alpha: 0.12),
                child: Icon(
                  Icons.person_outline,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: isSelected ? 20 : 18,
                ),
              ),
      ),
    );
  }
}
