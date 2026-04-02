/// Run Location Lookup Dialog
///
/// A dialog with two tabs:
/// 1. **Previous Runs** – browse/search unique past run locations on a map.
/// 2. **Search Places** – query the online gazetteer (same API used on the
///    Location tab) and pick from the results.
///
/// Returns a [LocationLookupResult] that wraps either a [RunListModel]
/// (previous run) or a gazetteer [Results] (place search).

import 'dart:convert';
import 'package:hcportal/imports.dart';
import 'package:hcportal/models/azure_geo_model.dart';
import 'package:http/http.dart' as http;
import 'package:latlng/latlng.dart';
import 'package:map/map.dart' as geo_map;

// ---------------------------------------------------------------------------
// Result wrapper returned by the dialog
// ---------------------------------------------------------------------------

/// Sealed result type so the caller can distinguish between the two tabs.
sealed class LocationLookupResult {}

/// The user picked a previous run location.
class PreviousRunResult extends LocationLookupResult {
  PreviousRunResult(this.run);
  final RunListModel run;
}

/// The user picked a gazetteer search result.
class GazetteerResult extends LocationLookupResult {
  GazetteerResult(this.result);
  final Results result;
}

// ---------------------------------------------------------------------------
// Data class for a unique location
// ---------------------------------------------------------------------------

/// Groups one or more [RunListModel] entries that share the same
/// [locationOneLineDesc]. Holds the display label, optional lat/lon, and the
/// list of run models at that location.
class _UniqueLocation {
  _UniqueLocation({
    required this.label,
    required this.run,
    this.lat,
    this.lon,
  });

  final String label;
  final RunListModel run;
  final double? lat;
  final double? lon;
}

// ---------------------------------------------------------------------------
// Dialog
// ---------------------------------------------------------------------------

/// Shows a dialog with two tabs: previous run locations and gazetteer search.
///
/// Returns a [LocationLookupResult] or `null` if the user cancels.
class RunLocationLookupDialog extends StatefulWidget {
  const RunLocationLookupDialog({
    required this.events,
    required this.kennelLat,
    required this.kennelLon,
    required this.kennelCountryCodes,
    this.initialPlaceDescription,
    super.key,
  });

  /// All events (past + future) available for location lookup.
  final List<RunListModel> events;

  /// Kennel latitude for initial map centre (fallback when no locations have coords).
  final double kennelLat;

  /// Kennel longitude for initial map centre.
  final double kennelLon;

  /// Comma-separated country codes for biasing gazetteer search.
  final String kennelCountryCodes;

  /// Current place description value – used to pre-select a matching location.
  final String? initialPlaceDescription;

  @override
  State<RunLocationLookupDialog> createState() =>
      _RunLocationLookupDialogState();
}

class _RunLocationLookupDialogState extends State<RunLocationLookupDialog>
    with SingleTickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // State — shared
  // ---------------------------------------------------------------------------

  late final TabController _tabController;

  // ---------------------------------------------------------------------------
  // State — Previous Runs tab
  // ---------------------------------------------------------------------------

  late final List<_UniqueLocation> _allLocations;
  List<_UniqueLocation> _filteredLocations = [];
  final TextEditingController _searchController = TextEditingController();

  int? _selectedIndex; // index into _filteredLocations
  late geo_map.MapController _mapController;
  final ScrollController _listScrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = {};

  // Gesture tracking
  Offset _dragStart = Offset.zero;
  double _zoomStart = 10.0;

  // ---------------------------------------------------------------------------
  // State — Gazetteer Search tab
  // ---------------------------------------------------------------------------

  final TextEditingController _gazetteerSearchController =
      TextEditingController();
  List<Results> _gazetteerResults = [];
  bool _isSearching = false;
  int? _gazetteerSelectedIndex;
  late geo_map.MapController _gazetteerMapController;
  Offset _gazDragStart = Offset.zero;
  double _gazZoomStart = 10.0;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _buildUniqueLocations();
    _filteredLocations = List.of(_allLocations);
    _initMapController();
    _initGazetteerMapController();
    _applyInitialSearch();

    // After the first frame, scroll the list to centre the pre-selected item.
    if (_selectedIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_scrollToSelectedIndex());
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _listScrollController.dispose();
    _gazetteerSearchController.dispose();
    super.dispose();
  }

  /// Scrolls the list so [_selectedIndex] is centred in the viewport.
  Future<void> _scrollToSelectedIndex() async {
    if (_selectedIndex == null) return;
    final key = _itemKeys[_selectedIndex!];
    if (key == null || key.currentContext == null) return;
    await Scrollable.ensureVisible(
      key.currentContext!,
      alignment: 0.5,
      duration: const Duration(milliseconds: 200),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// De-duplicates events by [locationOneLineDesc], keeping only the first
  /// occurrence (i.e. the most recent or whichever appears first in the list).
  void _buildUniqueLocations() {
    final seen = <String>{};
    final result = <_UniqueLocation>[];

    for (final event in widget.events) {
      final desc = event.locationOneLineDesc?.trim() ?? '';
      if (desc.isEmpty) continue;
      if (event.syncLat == null || event.syncLong == null) continue;
      final key = desc.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);

      result.add(_UniqueLocation(
        label: desc,
        run: event,
        lat: event.syncLat,
        lon: event.syncLong,
      ));
    }

    // Sort alphabetically by label
    result
        .sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));

    _allLocations = result;
  }

  /// Applies [initialPlaceDescription] on open:
  /// 1. Pre-fills the search field and filters the previous-runs list.
  /// 2. Exactly one match → auto-selects it.
  /// 3. Multiple matches → shows the filtered list (user picks).
  /// 4. No matches → switches to the gazetteer tab, pre-fills it, and
  ///    automatically fires a search.
  void _applyInitialSearch() {
    final desc = widget.initialPlaceDescription?.trim() ?? '';
    if (desc.isEmpty) return;

    // Pre-fill the search field and filter the list
    _searchController.text = desc;
    final query = desc.toLowerCase();
    _filteredLocations = _allLocations
        .where((loc) => loc.label.toLowerCase().contains(query))
        .toList();

    if (_filteredLocations.length == 1) {
      // Exactly one match — auto-select it and centre the map
      _selectedIndex = 0;
      final loc = _filteredLocations[0];
      if (loc.lat != null && loc.lon != null) {
        _mapController.center =
            LatLng(Angle.degree(loc.lat!), Angle.degree(loc.lon!));
        _mapController.zoom = 14;
      }
    } else if (_filteredLocations.isEmpty) {
      // No matches in past runs — switch to gazetteer and auto-search
      _gazetteerSearchController.text = desc;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tabController.animateTo(1);
        unawaited(_performGazetteerSearch());
      });
    }
    // Multiple matches: just show the filtered list, no auto-selection needed
  }

  /// Centres the map on the kennel's coordinates.
  void _initMapController() {
    _mapController = geo_map.MapController(
      location: LatLng(
        Angle.degree(widget.kennelLat),
        Angle.degree(widget.kennelLon),
      ),
      zoom: 11,
    );
  }

  /// Initialises the gazetteer tab map controller.
  void _initGazetteerMapController() {
    _gazetteerMapController = geo_map.MapController(
      location: LatLng(
        Angle.degree(widget.kennelLat),
        Angle.degree(widget.kennelLon),
      ),
      zoom: 11,
    );
  }

  void _onSearchChanged(String text) {
    final query = text.trim().toLowerCase();
    setState(() {
      _selectedIndex = null;
      _itemKeys.clear();
      if (query.isEmpty) {
        _filteredLocations = List.of(_allLocations);
      } else {
        _filteredLocations = _allLocations
            .where((loc) => loc.label.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _selectLocation(int filteredIndex, {bool scrollToItem = false}) {
    final loc = _filteredLocations[filteredIndex];
    setState(() {
      _selectedIndex = filteredIndex;
    });
    // Centre map on this location if it has coordinates
    if (loc.lat != null && loc.lon != null) {
      setState(() {
        _mapController.center =
            LatLng(Angle.degree(loc.lat!), Angle.degree(loc.lon!));
        _mapController.zoom = 14;
      });
    }
    if (scrollToItem) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_scrollToSelectedIndex());
      });
    }
  }

  void _confirmSelection(int filteredIndex) {
    Get.back(result: PreviousRunResult(_filteredLocations[filteredIndex].run));
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            // Bubble tab bar with sliding indicator
            Container(
              color: Colors.grey.shade200,
              padding: const EdgeInsets.only(
                  left: 16, right: 16, bottom: 12, top: 4),
              child: AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) => LayoutBuilder(
                  builder: (context, constraints) {
                    final tabWidth = (constraints.maxWidth - 8) / 2;
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.brown.shade100,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Stack(
                        children: [
                          // Sliding pill indicator
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            left: _tabController.index * tabWidth,
                            top: 0,
                            bottom: 0,
                            width: tabWidth,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red.shade900,
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                          ),
                          // Tab labels
                          Row(
                            children: [
                              _buildBubbleTab(
                                index: 0,
                                icon: FontAwesome5Solid.history,
                                label: 'Previous Runs',
                              ),
                              _buildBubbleTab(
                                index: 1,
                                icon: FontAwesome5Solid.search_location,
                                label: 'Search Places',
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            // Tab content
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPreviousRunsTab(),
                  _buildGazetteerTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey.shade200,
      child: Row(
        children: [
          Icon(FontAwesome5Solid.map_marker_alt, color: Colors.red[800]),
          const SizedBox(width: 12),
          Text(
            'Location Lookup',
            style: buttonLabelStyleMedium.copyWith(color: Colors.black),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bubble Tab Helper
  // ---------------------------------------------------------------------------

  Widget _buildBubbleTab({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          color: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 15, color: isSelected ? Colors.white : Colors.black87),
              const SizedBox(width: 8),
              Text(
                label,
                style: buttonLabelStyleMedium.copyWith(
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 1 — Previous Runs
  // ---------------------------------------------------------------------------

  Widget _buildPreviousRunsTab() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left panel — filter + list
        SizedBox(
          width: 360,
          child: _buildSearchPanel(),
        ),
        const VerticalDivider(width: 1),
        // Right panel — map
        Expanded(child: _buildMap()),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Search panel (left)
  // ---------------------------------------------------------------------------

  Widget _buildSearchPanel() {
    return Column(
      children: [
        // Search field
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Type to filter locations…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: _onSearchChanged,
          ),
        ),

        // Results list
        Expanded(
          child: _filteredLocations.isEmpty
              ? const Center(child: Text('No matching locations'))
              : SingleChildScrollView(
                  controller: _listScrollController,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var index = 0;
                          index < _filteredLocations.length;
                          index++)
                        ..._buildLocationTile(index),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Location tile builder
  // ---------------------------------------------------------------------------

  /// Builds a single location tile with a divider, keyed for scroll targeting.
  List<Widget> _buildLocationTile(int index) {
    final loc = _filteredLocations[index];
    final isSelected = index == _selectedIndex;
    _itemKeys.putIfAbsent(index, () => GlobalKey());

    return [
      ListTile(
        key: _itemKeys[index],
        selected: isSelected,
        selectedTileColor: Colors.blue.shade50,
        leading: CircleAvatar(
          backgroundColor: isSelected ? Colors.green : Colors.red[800],
          child: Text(
            '${index + 1}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          loc.label,
          style: bodyStyleBlack.copyWith(fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          loc.run.eventCityAndCountry,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isSelected
            ? ElevatedButton(
                onPressed: () => _confirmSelection(index),
                style: defaultButtonStyle,
                child: Text('Use', style: textStyleButton),
              )
            : const Icon(Icons.chevron_right),
        onTap: () => _selectLocation(index),
        onLongPress: () => _confirmSelection(index),
      ),
      if (index < _filteredLocations.length - 1) const Divider(height: 1),
    ];
  }

  // ---------------------------------------------------------------------------
  // Map (right)
  // ---------------------------------------------------------------------------

  Widget _buildMap() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: geo_map.MapLayout(
        controller: _mapController,
        builder: (BuildContext context, geo_map.MapTransformer transformer) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTap: () {
              setState(() {
                _mapController.zoom =
                    (_mapController.zoom + 1.0).clamp(1.0, 20.0);
              });
            },
            onScaleStart: (details) {
              _dragStart = details.focalPoint;
              _zoomStart = _mapController.zoom;
            },
            onScaleUpdate: (details) {
              setState(() {
                if ((details.scale - 1.0).abs() > 0.01) {
                  final newZoom = _zoomStart * details.scale;
                  _mapController.zoom = newZoom.clamp(1.0, 20.0);
                }
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
                  setState(() {
                    final newZoom =
                        _mapController.zoom - (event.scrollDelta.dy / 100.0);
                    _mapController.zoom = newZoom.clamp(1.0, 20.0);
                  });
                } else if (event is PointerScaleEvent) {
                  setState(() {
                    final newZoom = _mapController.zoom * event.scale;
                    _mapController.zoom = newZoom.clamp(1.0, 20.0);
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
                      return Image.network(url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox.shrink());
                    },
                  ),

                  // Location pins
                  ..._buildLocationMarkers(transformer),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Map markers
  // ---------------------------------------------------------------------------

  List<Widget> _buildLocationMarkers(geo_map.MapTransformer transformer) {
    final markers = <Widget>[];
    Widget? selectedMarker;

    // Only show pins for locations currently in the filtered list,
    // so pin numbers always match list numbers.
    for (var i = 0; i < _filteredLocations.length; i++) {
      final loc = _filteredLocations[i];
      if (loc.lat == null || loc.lon == null) continue;

      final pos = transformer.toOffset(
        LatLng(Angle.degree(loc.lat!), Angle.degree(loc.lon!)),
      );

      final isSelected = i == _selectedIndex;

      final marker = Positioned(
        left: pos.dx - 16,
        top: pos.dy - 45,
        child: GestureDetector(
          onTap: () => _selectLocation(i, scrollToItem: true),
          onDoubleTap: () => _confirmSelection(i),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green : Colors.red[800],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              Container(
                width: 2,
                height: 12,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green : Colors.red[800],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      // Defer the selected marker so it renders on top of all others.
      if (isSelected) {
        selectedMarker = marker;
      } else {
        markers.add(marker);
      }
    }

    // Add selected marker last so it's always on top.
    if (selectedMarker != null) {
      markers.add(selectedMarker);
    }

    return markers;
  }

  // ---------------------------------------------------------------------------
  // Tab 2 — Gazetteer Search
  // ---------------------------------------------------------------------------

  Widget _buildGazetteerTab() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left panel — search input + results list
        SizedBox(
          width: 360,
          child: _buildGazetteerPanel(),
        ),
        const VerticalDivider(width: 1),
        // Right panel — map
        Expanded(child: _buildGazetteerMap()),
      ],
    );
  }

  Widget _buildGazetteerPanel() {
    return Column(
      children: [
        // Search input
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _gazetteerSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search for a place…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _gazetteerSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _gazetteerSearchController.clear();
                              setState(() {
                                _gazetteerResults = [];
                                _gazetteerSelectedIndex = null;
                              });
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _performGazetteerSearch(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSearching ? null : _performGazetteerSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                child: _isSearching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                          backgroundColor: Colors.blue,
                        ),
                      )
                    : const Text(
                        'Search',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          ),
        ),

        // Results list
        Expanded(
          child: _gazetteerResults.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _isSearching
                          ? 'Searching…'
                          : _gazetteerSearchController.text.isEmpty
                              ? 'Enter a place name, address, or establishment'
                              : 'No results found',
                      style:
                          bodyStyleBlack.copyWith(color: Colors.grey.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: _gazetteerResults.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) => _buildGazetteerTile(index),
                ),
        ),
      ],
    );
  }

  Widget _buildGazetteerTile(int index) {
    final result = _gazetteerResults[index];
    final isSelected = index == _gazetteerSelectedIndex;
    final address = result.address;

    // Build display name
    final name = result.poi?.name ?? address?.freeformAddress ?? 'Unknown';
    // Build subtitle from address parts
    final subtitle = <String?>[
      address?.municipality,
      address?.countrySubdivision,
      address?.country,
    ].where((s) => s != null && s.isNotEmpty).join(', ');

    return ListTile(
      selected: isSelected,
      selectedTileColor: Colors.blue.shade50,
      leading: CircleAvatar(
        backgroundColor: isSelected ? Colors.green : Colors.blue[700],
        child: Text(
          '${index + 1}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(
        name,
        style: bodyStyleBlack.copyWith(fontWeight: FontWeight.bold),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: isSelected
          ? ElevatedButton(
              onPressed: () => _confirmGazetteerSelection(index),
              style: defaultButtonStyle,
              child: Text('Use', style: textStyleButton),
            )
          : const Icon(Icons.chevron_right),
      onTap: () => _selectGazetteerResult(index),
      onLongPress: () => _confirmGazetteerSelection(index),
    );
  }

  Future<void> _performGazetteerSearch() async {
    final searchText = _gazetteerSearchController.text.trim();
    if (searchText.isEmpty) return;

    setState(() {
      _isSearching = true;
      _gazetteerSelectedIndex = null;
    });

    try {
      final body = <String, dynamic>{
        'placeName': searchText,
        'lat': widget.kennelLat,
        'lon': widget.kennelLon,
        'radius': 160934, // 100 miles
        'countrySet': widget.kennelCountryCodes,
      };

      final url = Uri.parse(PORTAL_GEOCODE_PLACE_TO_ADDRESS_API_URL);
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Accept': '*/*',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final azurePlace = AzurePlace.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
        setState(() {
          _gazetteerResults = azurePlace.results ?? [];
          if (_gazetteerResults.isNotEmpty) {
            final first = _gazetteerResults[0];
            if (first.position?.lat != null && first.position?.lon != null) {
              _gazetteerMapController.center = LatLng(
                Angle.degree(first.position!.lat!),
                Angle.degree(first.position!.lon!),
              );
              // Zoom closer when there's only one result
              _gazetteerMapController.zoom =
                  _gazetteerResults.length == 1 ? 14 : 12;
            }
            // Auto-select when only one result returned
            if (_gazetteerResults.length == 1) {
              _gazetteerSelectedIndex = 0;
            }
          }
        });
      }
    } catch (_) {
      // Search failed — leave results empty
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _selectGazetteerResult(int index) {
    final result = _gazetteerResults[index];
    setState(() {
      _gazetteerSelectedIndex = index;
      if (result.position?.lat != null && result.position?.lon != null) {
        _gazetteerMapController.center = LatLng(
          Angle.degree(result.position!.lat!),
          Angle.degree(result.position!.lon!),
        );
        _gazetteerMapController.zoom = 14;
      }
    });
  }

  void _confirmGazetteerSelection(int index) {
    Get.back(result: GazetteerResult(_gazetteerResults[index]));
  }

  // ---------------------------------------------------------------------------
  // Gazetteer Map
  // ---------------------------------------------------------------------------

  Widget _buildGazetteerMap() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: geo_map.MapLayout(
        controller: _gazetteerMapController,
        builder: (BuildContext context, geo_map.MapTransformer transformer) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTap: () {
              setState(() {
                _gazetteerMapController.zoom =
                    (_gazetteerMapController.zoom + 1.0).clamp(1.0, 20.0);
              });
            },
            onScaleStart: (details) {
              _gazDragStart = details.focalPoint;
              _gazZoomStart = _gazetteerMapController.zoom;
            },
            onScaleUpdate: (details) {
              setState(() {
                if ((details.scale - 1.0).abs() > 0.01) {
                  final newZoom = _gazZoomStart * details.scale;
                  _gazetteerMapController.zoom = newZoom.clamp(1.0, 20.0);
                }
                final now = details.focalPoint;
                final diff = now - _gazDragStart;
                _gazDragStart = now;
                transformer.drag(diff.dx, diff.dy);
              });
            },
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) {
                  setState(() {
                    final newZoom = _gazetteerMapController.zoom -
                        (event.scrollDelta.dy / 100.0);
                    _gazetteerMapController.zoom = newZoom.clamp(1.0, 20.0);
                  });
                } else if (event is PointerScaleEvent) {
                  setState(() {
                    final newZoom = _gazetteerMapController.zoom * event.scale;
                    _gazetteerMapController.zoom = newZoom.clamp(1.0, 20.0);
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
                      return Image.network(url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox.shrink());
                    },
                  ),

                  // Gazetteer result pins
                  ..._buildGazetteerMarkers(transformer),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildGazetteerMarkers(geo_map.MapTransformer transformer) {
    final markers = <Widget>[];

    for (var i = 0; i < _gazetteerResults.length; i++) {
      final result = _gazetteerResults[i];
      if (result.position?.lat == null || result.position?.lon == null) {
        continue;
      }

      final pos = transformer.toOffset(
        LatLng(
          Angle.degree(result.position!.lat!),
          Angle.degree(result.position!.lon!),
        ),
      );

      final isSelected = i == _gazetteerSelectedIndex;

      markers.add(
        Positioned(
          left: pos.dx - 16,
          top: pos.dy - 45,
          child: GestureDetector(
            onTap: () => _selectGazetteerResult(i),
            onDoubleTap: () => _confirmGazetteerSelection(i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green : Colors.blue[700],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 2,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green : Colors.blue[700],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return markers;
  }
}
