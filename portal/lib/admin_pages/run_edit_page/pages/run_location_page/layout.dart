/// Location Page Layout
///
/// This file contains the UI layout for the Location tab with:
/// - Place search with inline results navigation
/// - Interactive map with crosshair
/// - Required latitude/longitude fields with geocoding actions
/// - Optional address fields

part of '../../run_edit_page_ui.dart';

// ---------------------------------------------------------------------------
// Location Tab Content Widget
// ---------------------------------------------------------------------------

/// Content widget for the Location tab.
///
/// Layout structure:
/// 1. Fixed map at top (always visible)
/// 2. Scrollable content below with:
///    - Find Location section - search field with inline results navigation
///    - Coordinates section - required lat/lon with action buttons
///    - Address section - optional address fields
class RunLocationTabContent extends StatelessWidget {
  const RunLocationTabContent({required this.controller, super.key});

  final RunEditPageController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isMobileScreen =
          controller.screenSize.value == EScreenSize.isMobileScreen;
      final hasIntegration = controller.inboundIntegrationId.value != 0;
      final isAddressDisabled =
          hasIntegration && controller.useExtLocation.value;
      final isLatLonDisabled = hasIntegration && controller.useExtLatLon.value;

      // Return a Column that will be handled specially by the parent
      // The map is NOT inside the scroll view - it stays fixed
      final scrollController = ScrollController();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -----------------------------------------------------------------
          // 1. Map Section (Fixed - not scrollable, fills available space)
          // -----------------------------------------------------------------
          Expanded(
            child: _buildMapSection(),
          ),

          // -----------------------------------------------------------------
          // 2. Scrollable Content (with horizontal padding)
          // -----------------------------------------------------------------
          Expanded(
            child: Stack(
              children: [
                // Shadow at top of scrollable area (cast by map above)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: 12,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.25),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Scrollable content
                ScrollbarTheme(
                  data: ScrollbarThemeData(
                    thumbVisibility: WidgetStateProperty.all(true),
                    trackVisibility: WidgetStateProperty.all(true),
                    thickness: WidgetStateProperty.all(16),
                    radius: const Radius.circular(8),
                    thumbColor: WidgetStateProperty.all(Colors.grey.shade500),
                    trackColor: WidgetStateProperty.all(Colors.grey.shade200),
                    trackBorderColor:
                        WidgetStateProperty.all(Colors.grey.shade300),
                  ),
                  child: Scrollbar(
                    controller: scrollController,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Find Location Section
                          HelperWidgets().categoryLabelWidget('Find Location'),
                          _buildFindLocationButton(),
                          const SizedBox(height: 24),

                          // Coordinates Section (Required)
                          HelperWidgets()
                              .categoryLabelWidget('Coordinates (Required)'),

                          if (hasIntegration) ...[
                            _buildLatLonIntegrationSelector(),
                            const SizedBox(height: 12),
                          ],

                          RowColumn(
                            isRow: !isMobileScreen,
                            rowFlexValues: const [1, 1],
                            rowLeftPaddingValues: const [0.0, 20.0],
                            children: [
                              _buildTextField(
                                RunLocationField.latitude,
                                isDisabled: isLatLonDisabled,
                              ),
                              _buildTextField(
                                RunLocationField.longitude,
                                isDisabled: isLatLonDisabled,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildCoordinateActionButtons(
                              isDisabled: isLatLonDisabled),
                          const SizedBox(height: 24),

                          // Address Section (Optional)
                          _buildAddressLabelWithLookupButton(
                              isDisabled: isLatLonDisabled),

                          if (hasIntegration) ...[
                            _buildAddressIntegrationSelector(),
                            const SizedBox(height: 12),
                          ],

                          _buildTextField(RunLocationField.street,
                              isDisabled: isAddressDisabled),
                          const SizedBox(height: 12),

                          RowColumn(
                            isRow: !isMobileScreen,
                            rowFlexValues: const [2, 1],
                            rowLeftPaddingValues: const [0.0, 20.0],
                            children: [
                              _buildTextField(RunLocationField.city,
                                  isDisabled: isAddressDisabled),
                              _buildTextField(RunLocationField.postcode,
                                  isDisabled: isAddressDisabled),
                            ],
                          ),
                          const SizedBox(height: 12),

                          RowColumn(
                            isRow: !isMobileScreen,
                            rowFlexValues: const [1, 1, 1],
                            rowLeftPaddingValues: const [0.0, 20.0, 20.0],
                            children: [
                              _buildTextField(RunLocationField.region,
                                  isDisabled: isAddressDisabled),
                              _buildTextField(RunLocationField.country,
                                  isDisabled: isAddressDisabled),
                              _buildTextField(RunLocationField.phone,
                                  isDisabled: isAddressDisabled),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Find Location Button
  // ---------------------------------------------------------------------------

  /// Builds a button that opens the combined location lookup dialog
  /// (previous runs + gazetteer search).
  Widget _buildFindLocationButton() {
    return Obx(() => ElevatedButton.icon(
          icon: controller.isLookupLoading.value
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.search, size: 18, color: Colors.white),
          label: Text(
            controller.isLookupLoading.value ? 'Loading…' : 'Find Location',
            style: const TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          onPressed: controller.isLookupLoading.value
              ? null
              : controller.openLocationLookupDialog,
        ));
  }

  // ---------------------------------------------------------------------------
  // Map Section
  // ---------------------------------------------------------------------------

  Widget _buildMapSection() {
    return _InteractiveMapWidget(controller: controller);
  }

  // ---------------------------------------------------------------------------
  // Coordinate Action Buttons
  // ---------------------------------------------------------------------------

  Widget _buildCoordinateActionButtons({required bool isDisabled}) {
    final hasIntegration = controller.inboundIntegrationId.value != 0;
    final sourceName =
        INBOUND_DATA_SOURCES[controller.inboundIntegrationId.value];

    // Only show if there's integration - the reverse geocode button moved to address label
    if (!hasIntegration) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        // Copy from integration (if applicable)
        OutlinedButton.icon(
          onPressed: controller.copyLatLonFromExternal,
          icon: const Icon(FontAwesome5Solid.copy, size: 16),
          label: Text('Copy from $sourceName'),
        ),
      ],
    );
  }

  /// Builds the Address label with the lookup button positioned next to it.
  Widget _buildAddressLabelWithLookupButton({required bool isDisabled}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Address (Optional)',
                style: TextStyle(
                  fontFamily: 'AvenirNextBold',
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 12),
              Obx(() => OutlinedButton.icon(
                    onPressed: isDisabled || controller.isGeocoding.value
                        ? null
                        : controller.reverseGeocode,
                    icon: controller.isGeocoding.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(MaterialCommunityIcons.arrow_down_bold,
                            size: 18),
                    label: const Text('Lookup address from lat/lon'),
                  )),
            ],
          ),
        ),
        Divider(thickness: 3, color: Colors.deepOrange.shade100),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Integration Selectors
  // ---------------------------------------------------------------------------

  Widget _buildAddressIntegrationSelector() {
    return Obx(() => Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Address Source', style: titleStyleBlack),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: controller.useExtLocation.value,
                      onChanged: (value) {
                        controller.useExtLocation.value = value ?? false;
                        controller.checkIfFormIsDirty();
                      },
                    ),
                    Expanded(
                      child: Text(
                        'Use address from ${INBOUND_DATA_SOURCES[controller.inboundIntegrationId.value]} (read-only)',
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Radio<bool>(
                      value: false,
                      groupValue: controller.useExtLocation.value,
                      onChanged: (value) {
                        controller.useExtLocation.value = value ?? false;
                        controller.checkIfFormIsDirty();
                      },
                    ),
                    const Expanded(
                      child: Text('Use Harrier Central address (editable)'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: controller.copyAddressFromExternal,
                  icon: const Icon(FontAwesome5Solid.copy, size: 16),
                  label: Text(
                    'Copy address from ${INBOUND_DATA_SOURCES[controller.inboundIntegrationId.value]}',
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildLatLonIntegrationSelector() {
    return Obx(() => Card(
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Coordinates Source', style: titleStyleBlack),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: controller.useExtLatLon.value,
                      onChanged: (value) {
                        controller.useExtLatLon.value = value ?? false;
                        controller.checkIfFormIsDirty();
                      },
                    ),
                    Expanded(
                      child: Text(
                        'Use coordinates from ${INBOUND_DATA_SOURCES[controller.inboundIntegrationId.value]} (read-only)',
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Radio<bool>(
                      value: false,
                      groupValue: controller.useExtLatLon.value,
                      onChanged: (value) {
                        controller.useExtLatLon.value = value ?? false;
                        controller.checkIfFormIsDirty();
                      },
                    ),
                    const Expanded(
                      child: Text('Use Harrier Central coordinates (editable)'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
  }

  // ---------------------------------------------------------------------------
  // Text Field Builder
  // ---------------------------------------------------------------------------

  Widget _buildTextField(RunLocationField field, {bool isDisabled = false}) {
    final controlKey = '${RunTabType.location.key}_${field.name}';
    final uiControl = controller.uiControls[controlKey];

    if (uiControl == null) return const SizedBox.shrink();

    if (isDisabled) {
      return TextFormField(
        controller: uiControl.textController,
        readOnly: true,
        style: bodyStyleBlack.copyWith(color: Colors.grey.shade600),
        decoration: InputDecoration(
          labelText: uiControl.label,
          fillColor: Colors.grey.shade200,
          filled: true,
        ),
      );
    }

    return EditableOverrideTextField(
      controller: controller,
      uiControl: uiControl,
      onChanged: (_) => controller.checkIfFormIsDirty(),
    );
  }
}

// ---------------------------------------------------------------------------
// Interactive Map Widget (StatefulWidget for gesture handling)
// ---------------------------------------------------------------------------

/// A StatefulWidget wrapper for the map that handles pan/zoom gestures.
///
/// The map package requires setState to be called after transformer.drag()
/// to trigger a rebuild. This widget provides that functionality.
class _InteractiveMapWidget extends StatefulWidget {
  const _InteractiveMapWidget({required this.controller});

  final RunEditPageController controller;

  @override
  State<_InteractiveMapWidget> createState() => _InteractiveMapWidgetState();
}

class _InteractiveMapWidgetState extends State<_InteractiveMapWidget> {
  Offset _dragStart = Offset.zero;
  double _zoomStart = 10.0;
  final List<Worker> _listeners = [];

  @override
  void initState() {
    super.initState();
    // Listen to reactive values and call setState to force rebuild
    _listeners.add(ever(widget.controller.mapRebuildTrigger, (_) {
      if (mounted) setState(() {});
    }));
    _listeners.add(ever(widget.controller.mapController, (_) {
      if (mounted) setState(() {});
    }));
    _listeners.add(ever(widget.controller.editedData, (_) {
      if (mounted) setState(() {});
    }));
  }

  @override
  void dispose() {
    for (final listener in _listeners) {
      listener.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapController = widget.controller.mapController.value;

    if (mapController == null) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: geo_map.MapLayout(
        controller: mapController,
        builder: (BuildContext context, geo_map.MapTransformer transformer) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTap: () {
              setState(() {
                mapController.zoom =
                    (mapController.zoom + 1.0).clamp(1.0, 20.0);
              });
            },
            onScaleStart: (details) {
              _dragStart = details.focalPoint;
              _zoomStart = mapController.zoom;
            },
            onScaleUpdate: (details) {
              setState(() {
                // Handle zoom - check if this is a pinch gesture (scale != 1.0)
                if ((details.scale - 1.0).abs() > 0.01) {
                  // Apply zoom based on scale from gesture start
                  final newZoom = _zoomStart * details.scale;
                  mapController.zoom = newZoom.clamp(1.0, 20.0);
                }

                // Handle pan - always apply drag
                final now = details.focalPoint;
                final diff = now - _dragStart;
                _dragStart = now;
                transformer.drag(diff.dx, diff.dy);
              });
            },
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) {
                  // Mouse wheel or trackpad two-finger scroll
                  final delta = event.scrollDelta;
                  setState(() {
                    final newZoom = mapController.zoom - (delta.dy / 100.0);
                    mapController.zoom = newZoom.clamp(1.0, 20.0);
                  });
                } else if (event is PointerScaleEvent) {
                  // macOS trackpad pinch-to-zoom
                  setState(() {
                    final newZoom = mapController.zoom * event.scale;
                    mapController.zoom = newZoom.clamp(1.0, 20.0);
                  });
                }
              },
              child: Stack(
                children: [
                  // Map tiles
                  geo_map.TileLayer(
                    builder: (context, x, y, z) {
                      final url =
                          'https://www.google.com/maps/vt/pb=!1m4!1m3!1i$z!2i$x!3i$y!2m3!1e0!2sm!3i420120488!3m7!2sen!5e1105!12m4!1e68!2m2!1sset!2sRoadmap!4e0!5m1!1e0!23i4111425';
                      return Image.network(url, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink());
                    },
                  ),

                  // Current location marker
                  _buildCurrentLocationMarker(transformer),

                  // Center crosshair
                  _buildCenterCrosshair(transformer),

                  // Map action buttons overlay (bottom left)
                  _buildMapOverlayButtons(mapController),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentLocationMarker(geo_map.MapTransformer transformer) {
    final lat = widget.controller.editedData.value.hcLatitude;
    final lon = widget.controller.editedData.value.hcLongitude;

    if (lat == null || lon == null) return const SizedBox.shrink();

    final pos = transformer.toOffset(
      LatLng(Angle.degree(lat), Angle.degree(lon)),
    );

    return Positioned(
      left: pos.dx - 50,
      top: pos.dy - 100,
      width: 100,
      height: 100,
      child: IgnorePointer(
        child: Image.asset(
          'images/maps/map_pin_foot.png',
          height: 100,
          width: 100,
        ),
      ),
    );
  }

  Widget _buildCenterCrosshair(geo_map.MapTransformer transformer) {
    final centerX = transformer.constraints.biggest.width / 2;
    final centerY = transformer.constraints.biggest.height / 2;

    return Positioned(
      left: centerX - 100,
      top: centerY - 100,
      width: 200,
      height: 200,
      child: IgnorePointer(
        child: Image.asset('images/maps/map_center_target.png'),
      ),
    );
  }

  Widget _buildMapOverlayButtons(geo_map.MapController mapController) {
    // Check if crosshair (map center) differs from current lat/lon
    final lat = widget.controller.editedData.value.hcLatitude;
    final lon = widget.controller.editedData.value.hcLongitude;

    final centerLat = mapController.center.latitude.degrees;
    final centerLon = mapController.center.longitude.degrees;

    // Threshold for 1-2 meter accuracy:
    // 1 degree latitude ≈ 111,000 meters
    // 2 meters ≈ 0.00002 degrees
    const threshold = 0.00002;

    // Check if crosshair position differs from current lat/lon
    final hasLatLon = lat != null && lon != null;
    final crosshairMoved = !hasLatLon ||
        (centerLat - lat).abs() > threshold ||
        (centerLon - lon).abs() > threshold;

    // If both buttons would be hidden, don't show anything
    if (!crosshairMoved) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // Set lat/lon from crosshair - only show if crosshair moved
          if (crosshairMoved)
            _buildMapButton(
              icon: MaterialCommunityIcons.crosshairs_gps,
              label: 'Set lat/lon from map crosshair',
              onPressed: () {
                widget.controller.setLatLonFromMap();
                setState(() {});
              },
            ),

          // Center map on lat/lon - only show if crosshair moved from lat/lon position
          if (crosshairMoved && hasLatLon)
            _buildMapButton(
              icon: MaterialCommunityIcons.crosshairs,
              label: 'Center map on lat/lon',
              onPressed: () {
                widget.controller.centerMapOnLatLon();
                setState(() {});
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.red[800],
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
