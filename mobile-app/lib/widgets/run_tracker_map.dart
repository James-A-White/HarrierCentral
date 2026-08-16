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
    this.autoFollowOnLoad = true,
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

  /// When false, the camera does NOT auto-follow the selected runner on load —
  /// it stays on [mapCenter]/[zoom]. Used when opening focused on a specific
  /// coordinate (e.g. the spot a run photo was taken) so the load-time
  /// recenter doesn't drag the view to the run's end.
  final bool autoFollowOnLoad;

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
              autoFollowOnLoad: autoFollowOnLoad,
            ),
      builder: (controller) {
        controller.updateTrueNorthLock(trueNorthLock);
        return Obx(() {
          final bool controllerLock = controller.trueNorthLock;
          // Rose view swaps ONLY the canvas — the timeline, playback controls
          // and lane filters below are shared, so scrubbing works identically
          // in either rendering.
          if (controller.roseView.value) {
            final blips = controller.roseBlips;
            final range = controller.roseRangeMetres(blips);
            return Stack(
              children: <Widget>[
                Positioned.fill(
                  child: GestureDetector(
                    onScaleUpdate: (d) {
                      if (d.pointerCount >= 2) {
                        controller.applyRoseScale(d.scale, blips);
                      }
                    },
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.55),
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 92),
                      // Own Obx: under north-lock roseFacingDeg follows the
                      // compass, which ticks every ≥2°. Reading it here (not
                      // in the rose's top-level Obx) means a facing change
                      // repaints only this canvas — never the timeline,
                      // legend or playback panel around it.
                      child: Obx(
                        () => RoseCanvas(
                          blips: blips,
                          ringMetres: range,
                          heading: controller.roseHeading,
                          facingDeg: controller.roseFacingDeg,
                        ),
                      ),
                    ),
                  ),
                ),
                _buildTimelineSlider(context, controller),
                // Switch in the same slot as over the map, so changing view
                // never moves the control out from under your thumb — with the
                // scale legend hung directly beneath it.
                //
                // The legend used to sit at bottom: 96, which put it under the
                // playback panel: the panel is drawn later in this Stack and
                // its height varies with what it contains (runner carousel,
                // trail chips, selected name), so no fixed bottom offset clears
                // it. Anchoring to the switch instead means it can never be
                // covered, whatever the panel grows to.
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      _viewSwitch(controller),
                      const SizedBox(height: 10),
                      IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(999.0),
                            border: Border.all(
                              color: Colors.yellow.withValues(alpha: 0.55),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14.0,
                              vertical: 6.0,
                            ),
                            child: Text(
                              'Ring = ${range < 1000 ? '${range.round()} m' : '${(range / 1000).toStringAsFixed(2)} km'}'
                              '  ·  centred on ${controller.roseFocusRunnerLabel}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.yellow,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Long-press anywhere on the readout resets the pinch range —
                // the switch no longer carries that gesture.
                Positioned(
                  bottom: 96,
                  right: 12,
                  child: MapOverlayButton(
                    icon: Icons.center_focus_strong,
                    tooltip: 'Reset range',
                    onTap: controller.resetRoseRange,
                  ),
                ),
              ],
            );
          }

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
                  // The viewer's own un-uploaded tail, dotted — its own Obx so
                  // every GPS fix extends it without rebuilding the map.
                  _pendingTailLayer(controller),
                  // Viewer dot + accuracy halo — own reactive layer (below the
                  // main marker layer so pins stay on top).
                  _viewerLayer(controller),
                  MarkerLayer(
                    // Keep pins and trail-mark icons upright on screen when the
                    // map rotates to a runner's heading — a sideways or upside
                    // down icon is just harder to read, and labelled marks
                    // become unreadable. Individual markers can still opt out
                    // (Marker.rotate wins over the layer), which the viewer dot
                    // does so its heading wedge keeps pointing at a true
                    // bearing rather than a screen-relative one.
                    rotate: true,
                    markers: <Marker>[
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
                      rotate: true, // photos and cluster counts stay upright
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
                            const Icon(
                              Icons.photo_camera,
                              color: Colors.white,
                              size: 18,
                            ),
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
                  MarkerLayer(rotate: true, markers: controller.runnerMarkers),
                ],
              ),
              _buildTimelineSlider(context, controller),
              // Right-hand control column, continuing below the page's
              // north-lock button. A Column (not separate Positioneds) so the
              // stack closes up when locate is unavailable instead of leaving
              // a hole.
              if (appModel.hasLocationPermissions &&
                  deviceInfo.deviceLat != null &&
                  deviceInfo.deviceLon != null)
                Positioned(
                  top: 66,
                  right: 12,
                  child: _locateButton(controller),
                ),
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(child: _viewSwitch(controller)),
              ),
              // "Tracks updated N min ago" — freshness of the live feed, so a
              // runner in a coverage hole knows how old the drawn pack is.
              Positioned(
                top: 58,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(child: _tracksUpdatedPill(controller)),
                ),
              ),
              // In-map photo showcase — grows a photo out of its pin to centre
              // and back as the playhead crosses it (topmost overlay).
              //
              // Wrapped in its OWN Obx so the ~60fps zoom/pan ticks repaint only
              // this overlay, not the whole map. Read inside the big top-level
              // Obx, the showcase couldn't repaint reliably (the map is busy) —
              // the photo mostly didn't render. The overlay reads no map state.
              Positioned.fill(
                // Obx must be INSIDE LayoutBuilder: _buildPhotoShowcase reads the
                // showcase observables, and those reads have to happen in the
                // Obx's own build scope. Obx(() => LayoutBuilder(...)) reads
                // nothing in the Obx itself (the reads are deferred to layout),
                // which throws GetX's "improper use of Obx" — a full-screen grey
                // ErrorWidget in release — and never observes showcaseZoom.
                child: LayoutBuilder(
                  builder: (ctx, cons) =>
                      Obx(() => _buildPhotoShowcase(controller, cons)),
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
    final panX = controller.showcasePan.value; // -1 (left) … 0 … +1 (right)
    final center = Offset(c.maxWidth / 2, c.maxHeight / 2);
    // Horizontal navigation sweep: the photo enters from the leading side and
    // exits the trailing side (see RunTrackerMapController.showcasePan),
    // vertically centred — so the direction of travel shows which way playback
    // is navigating.
    final double panMag = c.maxWidth * 0.42;
    final pos = Offset(center.dx + panX * panMag, center.dy);
    final double bigW = math.min(c.maxWidth * 0.84, c.maxHeight * 0.66);
    // Square bounding region that grows with the zoom. The photo is fitted
    // INSIDE it preserving aspect (no crop) and centred at [pos]; the rounded
    // corners hug the actual photo, not the square region.
    final double box = 60.0 + (bigW - 60.0) * z;
    return Stack(
      children: [
        Positioned(
          left: pos.dx - box / 2,
          top: pos.dy - box / 2,
          width: box,
          height: box,
          child: Opacity(
            opacity: (z * 2).clamp(0.0, 1.0),
            // Center gives loose constraints, so the Image sizes to its own
            // aspect ratio within the box (Flutter preserves aspect on loose
            // constraints) — full photo, no crop, corners hugging the image.
            child: Center(
              child: GestureDetector(
                onTap: controller.dismissShowcase,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, blurRadius: 12),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    // CachedNetworkImage (disk + memory cache) so the photo, once
                    // fetched (by the arm-time precache or a prior view), shows
                    // instantly and survives memory-cache eviction. fadeIn off —
                    // the showcase controls its own opacity via the zoom ramp.
                    child: CachedNetworkImage(
                      imageUrl: show.url,
                      fit: BoxFit.contain,
                      fadeInDuration: Duration.zero,
                      fadeOutDuration: Duration.zero,
                    ),
                  ),
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
    // Own Obx: the compass updates deviceHeading many times a second. Reading it
    // here (not in the map's top-level Obx) means a heading change rebuilds only
    // this dot's wedge — never FlutterMap or the marker-cluster layer.
    return Obx(() {
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
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 2),
              ],
            ),
          ),
        ],
      );
    });
  }

  /// Viewer dot + GPS-accuracy halo as their own reactive layer. Reading
  /// [LocationService.lastKnownPosition] inside this Obx means every GPS fix
  /// moves the dot immediately, repainting ONLY this layer — never FlutterMap,
  /// the polylines or the marker-cluster layer. Before this, the dot's
  /// position was read once per map rebuild, so it sat frozen until zoom or
  /// the 15-second auto-update happened to rebuild the tree.
  Widget _viewerLayer(RunTrackerMapController controller) {
    if (!Get.isRegistered<LocationService>()) return const SizedBox.shrink();
    final LocationService loc = Get.find<LocationService>();
    return Obx(() {
      final pos = loc.lastKnownPosition.value;
      if (!appModel.hasLocationPermissions) return const SizedBox.shrink();
      final double? lat = pos?.latitude ?? deviceInfo.deviceLat;
      final double? lon = pos?.longitude ?? deviceInfo.deviceLon;
      if (lat == null || lon == null) return const SizedBox.shrink();
      final double? acc = pos?.accuracy ?? deviceInfo.deviceAccuracy;
      final point = latlng.LatLng(lat, lon);
      return Stack(
        children: <Widget>[
          // Halo only when the fix is loose enough to be worth signalling
          // (matches web's 25 m threshold).
          if (acc != null && acc > 25.0)
            CircleLayer(
              circles: <CircleMarker>[
                CircleMarker(
                  point: point,
                  radius: acc,
                  useRadiusInMeter: true,
                  color: const Color(0xFF2A7FFF).withValues(alpha: 0.12),
                  borderColor: const Color(0xFF2A7FFF).withValues(alpha: 0.4),
                  borderStrokeWidth: 1,
                ),
              ],
            ),
          MarkerLayer(
            rotate: true,
            markers: <Marker>[
              Marker(
                height: 44.0,
                width: 44.0,
                // Rotate with the map so the heading wedge points to a true
                // (map-north-relative) bearing even when the map is rotated
                // to a runner's heading. The dot itself is circular, so
                // rotation only affects the wedge.
                rotate: true,
                point: point,
                child: IgnorePointer(
                  ignoring: true,
                  child: _viewerDot(controller),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  /// The viewer's own not-yet-uploaded track tail as a dotted polyline. Own
  /// Obx: reading [LocationService.lastKnownPosition] here means every GPS
  /// fix extends the tail by repainting only this layer. The controller
  /// getter also reads userPositions/isPlaying, so a successful upload (the
  /// server track catching up) retracts the dotted portion automatically.
  Widget _pendingTailLayer(RunTrackerMapController controller) {
    if (!Get.isRegistered<LocationService>()) return const SizedBox.shrink();
    final LocationService loc = Get.find<LocationService>();
    return Obx(() {
      loc.lastKnownPosition.value; // dependency: new fix → longer tail
      final tail = controller.pendingOwnTailPolyline;
      if (tail == null) return const SizedBox.shrink();
      return PolylineLayer(polylines: [tail]);
    });
  }

  /// Freshness pill for the live feed: how long since the last successful
  /// positions fetch. Neutral under a minute; amber once the feed is two
  /// missed polls behind — the situation (coverage hole) where knowing the
  /// pack picture is stale actually changes what a runner does.
  Widget _tracksUpdatedPill(RunTrackerMapController controller) {
    return Obx(() {
      controller.stalenessTick.value; // re-evaluate every 15 s
      final DateTime? at = controller.lastServerUpdateAt.value;
      if (at == null || !controller.isLiveWindow) {
        return const SizedBox.shrink();
      }
      final int secs = DateTime.now().difference(at).inSeconds;
      final String label = secs < 60
          ? 'Tracks updated just now'
          : secs < 3600
          ? 'Tracks updated ${secs ~/ 60} min ago'
          : 'Tracks updated ${secs ~/ 3600}h ${(secs % 3600) ~/ 60}m ago';
      final bool lagging = secs >= 120;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: lagging
              ? Colors.deepOrange.shade700.withValues(alpha: 0.85)
              : Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    });
  }

  Widget _locateButton(RunTrackerMapController controller) {
    return MapOverlayButton(
      icon: Icons.near_me,
      tooltip: 'My location',
      onTap: controller.recenterOnUser,
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

  /// Switches the canvas between the map and the rose. Long-press while in the
  /// rose resets the pinch range back to the auto 90% fit.
  Widget _viewSwitch(RunTrackerMapController controller) {
    return MapViewSwitch(
      roseSelected: controller.roseView.value,
      onSelect: (rose) => controller.roseView.value = rose,
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
                left: 8.0,
                right: 8.0,
                top: 8.0,
                bottom: 0.0,
              ),
              // Panel layout top→bottom: runner carousel, trail-type chips,
              // selected-runner name, elapsed time + distance, transport buttons
              // (play · speed · camera · tilt · follow), then a full-width
              // scrubber on its own row at the very bottom.
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
                  _buildFullWidthSlider(context, controller),
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
      child: Text(text, textAlign: TextAlign.center, style: ts_listValueStyle),
    );
  }

  /// Transport row: play · scrubber · speed bubble · tilt · follow (web order).
  // Transport buttons row (no scrubber — that's a full-width row below). Spread
  // evenly so the buttons have room to breathe.
  Widget _buildTransportRow(RunTrackerMapController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _iconBtn(
          icon: controller.isPlaying.value ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          onPressed: controller.togglePlayback,
        ),
        _buildSpeedBubble(controller),
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

  /// The scrubber on its own full-width row at the very bottom of the panel.
  Widget _buildFullWidthSlider(
    BuildContext context,
    RunTrackerMapController controller,
  ) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3,
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      child: Slider(
        value: controller.currentTimestampMs.value!,
        min: controller.minTimestampMs.value!,
        max: controller.maxTimestampMs.value!,
        onChanged: controller.seekTo,
      ),
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
    // Own Obx: tiltSpeed updates at accelerometer rate. Reading it here (not in
    // the map's top-level Obx via the timeline panel) means a tilt change
    // rebuilds only this bubble, never FlutterMap / the cluster layer.
    return Obx(() {
      final bool tilt = controller.tiltEnabled.value;
      final bool paused = controller.tiltPaused;
      final double shown = tilt
          ? controller.tiltSpeed.value
          : controller.playbackSpeed.value;
      final bool reverse = tilt && shown < 0;
      Widget child;
      Color bg;
      Color border;
      if (tilt && paused) {
        bg = const Color(0xFFEF4444); // red — paused
        border = Colors.white70;
        child = const Icon(Icons.pause, size: 15, color: Colors.white);
      } else {
        final bool active = tilt ? true : controller.playbackSpeed.value != 1.0;
        // Distinct colours per direction: blue forward, orange reverse.
        bg = reverse
            ? const Color(0xFFF97316) // orange — reverse
            : active
            ? const Color(0xFF3B82F6) // blue — forward
            : Colors.white.withValues(alpha: 0.12);
        border = (active || reverse) ? Colors.white70 : Colors.white24;
        final double mag = shown.abs();
        final String num = tilt
            ? mag.toStringAsFixed(1)
            : (mag % 1 == 0 ? mag.toInt().toString() : mag.toStringAsFixed(1));
        // No reverse glyph — the orange colour signals reverse, and the glyph
        // crowded the text.
        child = Text(
          '×$num',
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
    });
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
          final double sidePad = ((constraints.maxWidth - tile) / 2).clamp(
            0.0,
            double.infinity,
          );
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
    final emoji = controller
        .trailTypeFor(controller.trailValueForRunner(runner))
        .emoji;
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
                    // Square tile with slightly rounded corners (was a circle).
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? Colors.white : color,
                      width: selected ? 3 : 2,
                    ),
                  ),
                  child: ClipRRect(
                    // Inner radius a touch smaller than the border so the photo
                    // clips just inside the frame. Resolves http / bundle://
                    // avatars and falls back to a bundled default.
                    borderRadius: BorderRadius.circular(6),
                    child: Image(
                      image: avatarImageProvider(logo),
                      fit: BoxFit.cover,
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
