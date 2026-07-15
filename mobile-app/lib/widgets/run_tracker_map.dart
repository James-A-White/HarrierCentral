import 'dart:math' as math;

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
    this.controllerTag,
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

  /// Optional override for the GetX controller tag. Defaults to the event id so
  /// every map of a run shares one controller. The fullscreen map passes a
  /// distinct tag to get its OWN controller — flutter_map can't bind one
  /// MapController to two live maps at once (the embedded map stays mounted
  /// underneath the fullscreen route).
  final String? controllerTag;

  String get _controllerTag => controllerTag ?? event.eventId;

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
                  // GPS-accuracy halo under the viewer dot when the fix is loose.
                  if (controller.showsAccuracyHalo)
                    CircleLayer(
                      circles: <CircleMarker>[
                        CircleMarker(
                          point: latlng.LatLng(
                            deviceInfo.deviceLat!,
                            deviceInfo.deviceLon!,
                          ),
                          radius: deviceInfo.deviceAccuracy!,
                          useRadiusInMeter: true,
                          color: const Color(0xFF2A7FFF).withValues(alpha: 0.12),
                          borderColor:
                              const Color(0xFF2A7FFF).withValues(alpha: 0.4),
                          borderStrokeWidth: 1,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: <Marker>[
                      if ((appModel.hasLocationPermissions) &&
                          (deviceInfo.deviceLat != null) &&
                          (deviceInfo.deviceLon != null)) ...<Marker>[
                        Marker(
                          height: 44.0,
                          width: 44.0,
                          // Rotate with the map so the heading wedge points to a
                          // true (map-north-relative) bearing even when the map
                          // is rotated to a runner's heading. The dot itself is
                          // circular, so rotation only affects the wedge.
                          rotate: true,
                          point: latlng.LatLng(
                            deviceInfo.deviceLat!,
                            deviceInfo.deviceLon!,
                          ),
                          child: IgnorePointer(
                            ignoring: true,
                            child: _viewerDot(controller),
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
              // Locate/recenter on the viewer's own position (sits below the
              // page's north-lock button in the live-run map).
              if (appModel.hasLocationPermissions &&
                  deviceInfo.deviceLat != null &&
                  deviceInfo.deviceLon != null)
                Positioned(
                  top: 66,
                  right: 12,
                  child: _locateButton(controller),
                ),
              // In-map photo showcase — grows a photo out of its pin to centre
              // and back as the playhead crosses it (topmost overlay).
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (ctx, cons) => _buildPhotoShowcase(controller, cons),
                ),
              ),
            ],
          );
        });
      },
    );
  }

  /// Renders the active photo showcase: the photo grows from the pin's projected
  /// screen position toward centre (driven by the controller's 0→1
  /// [RunTrackerMapController.showcaseZoom]) and back. Tap to dismiss early.
  Widget _buildPhotoShowcase(
    RunTrackerMapController controller,
    BoxConstraints c,
  ) {
    final show = controller.photoShowcase.value;
    if (show == null) return const SizedBox.shrink();
    final z = controller.showcaseZoom.value;
    final center = Offset(c.maxWidth / 2, c.maxHeight / 2);
    Offset pin;
    try {
      pin = controller.mapController.camera.latLngToScreenOffset(show.point);
    } catch (_) {
      pin = center;
    }
    final pos = Offset.lerp(pin, center, z) ?? center;
    final double bigW = math.min(c.maxWidth * 0.84, c.maxHeight * 0.66);
    final double w = 60.0 + (bigW - 60.0) * z;
    return Stack(
      children: [
        Positioned(
          left: pos.dx - w / 2,
          top: pos.dy - w / 2,
          width: w,
          height: w,
          child: GestureDetector(
            onTap: controller.dismissShowcase,
            child: Opacity(
              opacity: (z * 2).clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 12),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(show.url, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Web-style viewer location dot: a blue dot with a white ring, plus a
  /// heading wedge when a device compass feed is available (null → dot only,
  /// so it degrades cleanly until the compass source is wired in).
  Widget _viewerDot(RunTrackerMapController controller) {
    const blue = Color(0xFF2A7FFF);
    final heading = controller.deviceHeading.value;
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (heading != null)
          Transform.rotate(
            angle: heading * math.pi / 180.0,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Align(
                alignment: Alignment.topCenter,
                child: Icon(
                  Icons.navigation,
                  size: 16,
                  color: blue.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
          ),
        ),
      ],
    );
  }

  Widget _locateButton(RunTrackerMapController controller) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(8),
      child: IconButton(
        tooltip: 'My location',
        icon: Icon(Icons.near_me, color: hc_blue),
        onPressed: controller.recenterOnUser,
      ),
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
                top: 8.0,
                bottom: 2.0,
              ),
              // Panel layout mirrors public-web top→bottom: runner carousel,
              // trail-type chips, selected-runner name, timestamp, distance,
              // transport row (play · scrubber · speed · tilt · follow).
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hasRunners) ...[
                    _buildRunnerCarousel(controller),
                    const SizedBox(height: 6.0),
                  ],
                  _buildInlineTrailChips(controller),
                  _buildSelectedRunnerName(controller),
                  _buildTimestampDistance(controller),
                  _buildTransportRow(controller),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Selected-runner name line (colour dot + trail emoji + name), centred —
  /// mirrors web's per-runner label above the timestamp.
  Widget _buildSelectedRunnerName(RunTrackerMapController controller) {
    final id = controller.selectedRunnerId.value;
    if (id == null) return const SizedBox.shrink();
    final runner = controller.userPositions.firstWhereOrNull((r) => r.id == id);
    final baseName = controller.userNames[id] ?? 'Runner';
    final emoji = runner == null
        ? ''
        : controller.trailTypeFor(controller.trailValueForRunner(runner)).emoji;
    final name = emoji.isNotEmpty ? '$emoji $baseName' : baseName;
    return Padding(
      padding: const EdgeInsets.only(top: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildRunnerColorDot(controller.runnerColor(id)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Timestamp + distance line for the current playhead / selected runner.
  Widget _buildTimestampDistance(RunTrackerMapController controller) {
    final label = controller.formattedTimelineLabel;
    final distanceLabel = controller.formattedDistanceLabel;
    final text = distanceLabel.isEmpty ? label : '$label     $distanceLabel';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: ts_listValueStyle,
      ),
    );
  }

  /// Transport row: play · scrubber · speed bubble · tilt · follow (web order).
  Widget _buildTransportRow(RunTrackerMapController controller) {
    return Row(
      children: [
        _iconBtn(
          icon: controller.isPlaying.value ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
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
        const SizedBox(width: 2),
        _buildSpeedBubble(controller),
        const SizedBox(width: 2),
        // Auto-photo showcase toggle — only when the selected runner has photos.
        if (controller.selectedRunnerHasPhotos)
          _iconBtn(
            icon: Icons.photo_camera,
            color: controller.photoShowcaseArmed.value
                ? Colors.lightBlueAccent
                : Colors.white54,
            tooltip: 'Auto-show photos during playback',
            onPressed: controller.togglePhotoShowcase,
          ),
        _iconBtn(
          icon: Icons.screen_rotation_alt,
          color: controller.tiltEnabled.value
              ? Colors.lightBlueAccent
              : Colors.white54,
          tooltip: controller.tiltEnabled.value
              ? 'Tilt control on'
              : 'Tilt to control playback speed',
          onPressed: controller.toggleTilt,
        ),
        _iconBtn(
          icon: Icons.my_location,
          color: controller.followRunner.value
              ? Colors.lightBlueAccent
              : Colors.white54,
          tooltip: controller.followRunner.value
              ? 'Following runner'
              : 'Follow runner',
          onPressed: controller.toggleFollow,
        ),
      ],
    );
  }

  /// Compact icon button used across the transport row (tightened so play +
  /// speed + tilt + follow + scrubber all fit on a phone-width panel).
  Widget _iconBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return IconButton(
      icon: Icon(icon, color: color),
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }

  /// Speed bubble: taps cycle 0.5/1/2/4 when tilt is off; while tilt is on it
  /// shows the live tilt multiplier (blue) and turns red with a pause glyph in
  /// the neutral/paused band. Mirrors web's speed bubble.
  Widget _buildSpeedBubble(RunTrackerMapController controller) {
    final bool tilt = controller.tiltEnabled.value;
    final bool paused = controller.tiltPaused;
    Widget child;
    Color bg;
    Color border;
    if (tilt && paused) {
      bg = const Color(0xFFEF4444);
      border = Colors.white70;
      child = const Icon(Icons.pause, size: 15, color: Colors.white);
    } else {
      final double shown =
          tilt ? controller.tiltSpeed.value : controller.playbackSpeed.value;
      final bool active = tilt ? true : controller.playbackSpeed.value != 1.0;
      bg = active ? const Color(0xFF3B82F6) : Colors.white.withValues(alpha: 0.12);
      border = active ? Colors.white70 : Colors.white24;
      final String prefix = (tilt && shown < 0) ? '⏪' : '';
      final double mag = shown.abs();
      final String num = tilt
          ? mag.toStringAsFixed(1)
          : (mag % 1 == 0 ? mag.toInt().toString() : mag.toStringAsFixed(1));
      child = Text(
        '$prefix×$num',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    return GestureDetector(
      onTap: tilt ? null : controller.cycleSpeed,
      child: Container(
        width: 40,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: border, width: 1),
        ),
        child: child,
      ),
    );
  }

  /// Trail-type filter chips, inside the control panel (web layout). Horizontal
  /// scroll for many lanes. Hidden when there's no real choice.
  Widget _buildInlineTrailChips(RunTrackerMapController controller) {
    final present = controller.presentTrailValues;
    if (present.length < 2) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: SizedBox(
        height: 32,
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

  /// Horizontal scroll-snap runner carousel (replaces the Cupertino wheel to
  /// match web). The centred tile is the selection; tapping a tile selects it.
  /// Equal half-viewport side padding lets any tile settle at centre, so item
  /// `i` is centred at scroll offset `i * runnerTileExtent`.
  Widget _buildRunnerCarousel(RunTrackerMapController controller) {
    final runners = controller.visibleRunners;
    if (runners.isEmpty) return const SizedBox.shrink();
    const double tile = RunTrackerMapController.runnerTileExtent;
    return SizedBox(
      height: 58.0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double sidePad = ((constraints.maxWidth - tile) / 2)
              .clamp(0.0, double.infinity);
          return NotificationListener<ScrollEndNotification>(
            onNotification: (_) {
              controller.onCarouselScrollEnd();
              return false;
            },
            child: ListView.builder(
              controller: controller.runnerCarouselController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: sidePad),
              itemExtent: tile,
              itemCount: runners.length,
              itemBuilder: (context, i) =>
                  _buildCarouselTile(controller, runners[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCarouselTile(
    RunTrackerMapController controller,
    UserTrack runner,
  ) {
    final bool selected = controller.selectedRunnerId.value == runner.id;
    final color = controller.runnerColor(runner.id);
    final logo = controller.userLogos[runner.id];
    final emoji =
        controller.trailTypeFor(controller.trailValueForRunner(runner)).emoji;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          controller.selectRunner(runner.id, recenter: true, syncPicker: true),
      child: Center(
        child: AnimatedScale(
          scale: selected ? 1.12 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: AnimatedOpacity(
            opacity: selected ? 1.0 : 0.65,
            duration: const Duration(milliseconds: 150),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? Colors.white : color,
                      width: selected ? 3 : 2,
                    ),
                  ),
                  child: ClipOval(
                    child: (logo != null && logo.isNotEmpty)
                        ? Image.network(logo, fit: BoxFit.cover)
                        : Container(
                            color: color.withValues(alpha: 0.35),
                            alignment: Alignment.center,
                            child: Text(
                              _initials(controller.userNames[runner.id]),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                  ),
                ),
                if (emoji.isNotEmpty)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 12)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Up-to-two-letter initials for a runner with no profile photo.
  String _initials(String? name) {
    final n = (name ?? '').trim();
    if (n.isEmpty) return '?';
    final parts = n.split(RegExp(r'\s+'));
    String head(String s) => s.isEmpty ? '' : s.substring(0, 1).toUpperCase();
    if (parts.length == 1) {
      return n.length >= 2 ? n.substring(0, 2).toUpperCase() : head(n);
    }
    return head(parts.first) + head(parts.last);
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

}
