// ignore_for_file: library_private_types_in_public_api
// Run Location Lookup Dialog
//
// A dialog with two tabs:
// 1. Previous Runs – browse/search unique past run locations on a map.
// 2. Search Places – query the online gazetteer (same API used on the
//    Location tab) and pick from the results.
//
// Returns a [LocationLookupResult] that wraps either a [RunListModel]
// (previous run) or a gazetteer [Results] (place search).
//
// State is managed by [RunLocationLookupController]. The caller
// (RunEditPageController.openLocationLookupDialog) creates the controller
// and passes it directly — avoids Get.find() timing issues during close animation.
//
// The two map widgets are extracted as tiny StatefulWidgets — the map
// package requires setState after transformer.drag(), matching the same
// pattern used by _InteractiveMapWidget in run_location_page/layout.dart.

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
// Controller
// ---------------------------------------------------------------------------

class RunLocationLookupController extends GetxController
    with GetSingleTickerProviderStateMixin {
  RunLocationLookupController({
    required this.events,
    required this.kennelLat,
    required this.kennelLon,
    required this.kennelCountryCodes,
    this.initialPlaceDescription,
  });

  // ── Constructor params ────────────────────────────────────────────────────

  final List<RunListModel> events;
  final double kennelLat;
  final double kennelLon;
  final String kennelCountryCodes;
  final String? initialPlaceDescription;

  // ── Shared ────────────────────────────────────────────────────────────────

  late final TabController tabController;

  // ── Previous Runs tab ─────────────────────────────────────────────────────

  late final List<_UniqueLocation> _allLocations;
  final RxList<_UniqueLocation> filteredLocations = <_UniqueLocation>[].obs;
  final TextEditingController searchController = TextEditingController();
  final RxString searchText = ''.obs;
  final Rx<int?> selectedIndex = Rx<int?>(null);
  final ScrollController listScrollController = ScrollController();
  final Map<int, GlobalKey> itemKeys = {};
  late final geo_map.MapController mapController;

  // ── Gazetteer tab ─────────────────────────────────────────────────────────

  final TextEditingController gazetteerSearchController =
      TextEditingController();
  final RxString gazetteerSearchText = ''.obs;
  final RxList<Results> gazetteerResults = <Results>[].obs;
  final RxBool isSearching = false.obs;
  final Rx<int?> gazetteerSelectedIndex = Rx<int?>(null);
  final ScrollController gazetteerListScrollController = ScrollController();
  final Map<int, GlobalKey> gazetteerItemKeys = {};
  late final geo_map.MapController gazetteerMapController;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    _buildUniqueLocations();
    filteredLocations.assignAll(_allLocations);
    mapController = geo_map.MapController(
      location: LatLng(Angle.degree(kennelLat), Angle.degree(kennelLon)),
      zoom: 11,
    );
    gazetteerMapController = geo_map.MapController(
      location: LatLng(Angle.degree(kennelLat), Angle.degree(kennelLon)),
      zoom: 11,
    );
    _applyInitialSearch();
    if (selectedIndex.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(scrollToSelectedIndex());
      });
    }
  }

  @override
  void onClose() {
    tabController.dispose();
    searchController.dispose();
    listScrollController.dispose();
    gazetteerSearchController.dispose();
    gazetteerListScrollController.dispose();
    super.onClose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// De-duplicates events by [locationOneLineDesc], keeping only the first
  /// occurrence. Skips events without lat/lon.
  void _buildUniqueLocations() {
    final seen = <String>{};
    final result = <_UniqueLocation>[];

    for (final event in events) {
      final desc = event.locationOneLineDesc?.trim() ?? '';
      if (desc.isEmpty) continue;
      final lat = event.syncLat;
      final lon = event.syncLong;
      if (lat == null || lon == null || lat == 0.0 || lon == 0.0) continue;
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
    final desc = initialPlaceDescription?.trim() ?? '';
    if (desc.isEmpty) return;

    searchController.text = desc;
    searchText.value = desc;
    final query = desc.toLowerCase();
    final matches = _allLocations
        .where((loc) => loc.label.toLowerCase().contains(query))
        .toList();
    filteredLocations.assignAll(matches);

    if (filteredLocations.length == 1) {
      selectedIndex.value = 0;
      final loc = filteredLocations[0];
      if (loc.lat != null && loc.lon != null) {
        mapController.center =
            LatLng(Angle.degree(loc.lat!), Angle.degree(loc.lon!));
        mapController.zoom = 14;
      }
    } else if (filteredLocations.isEmpty) {
      gazetteerSearchController.text = desc;
      gazetteerSearchText.value = desc;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        tabController.animateTo(1);
        unawaited(performGazetteerSearch());
      });
    }
  }

  Future<void> scrollToSelectedIndex() async {
    final idx = selectedIndex.value;
    if (idx == null) return;
    final key = itemKeys[idx];
    if (key == null || key.currentContext == null) return;
    await Scrollable.ensureVisible(
      key.currentContext!,
      alignment: 0.5,
      duration: const Duration(milliseconds: 200),
    );
  }

  // ── Previous Runs tab actions ─────────────────────────────────────────────

  void onSearchChanged(String text) {
    final query = text.trim().toLowerCase();
    searchText.value = text;
    selectedIndex.value = null;
    itemKeys.clear();
    if (query.isEmpty) {
      filteredLocations.assignAll(_allLocations);
    } else {
      filteredLocations.assignAll(
        _allLocations
            .where((loc) => loc.label.toLowerCase().contains(query))
            .toList(),
      );
    }
  }

  void clearSearch() {
    searchController.clear();
    onSearchChanged('');
  }

  void selectLocation(int index, {bool scrollToItem = false}) {
    final loc = filteredLocations[index];
    selectedIndex.value = index;
    if (loc.lat != null && loc.lon != null) {
      mapController.center =
          LatLng(Angle.degree(loc.lat!), Angle.degree(loc.lon!));
      mapController.zoom = 14;
    }
    if (scrollToItem) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(scrollToSelectedIndex());
      });
    }
  }

  void confirmSelection(int index) {
    Get.back(result: PreviousRunResult(filteredLocations[index].run));
  }

  // ── Gazetteer tab actions ─────────────────────────────────────────────────

  void onGazetteerSearchChanged(String text) {
    gazetteerSearchText.value = text;
  }

  void clearGazetteerSearch() {
    gazetteerSearchController.clear();
    gazetteerSearchText.value = '';
    gazetteerResults.clear();
    gazetteerSelectedIndex.value = null;
  }

  Future<void> performGazetteerSearch() async {
    final searchText = gazetteerSearchController.text.trim();
    if (searchText.isEmpty) return;

    isSearching.value = true;
    gazetteerSelectedIndex.value = null;

    try {
      final params = <String, String>{
        'q': searchText,
        'lat': kennelLat.toString(),
        'lon': kennelLon.toString(),
      };
      if (kennelCountryCodes.isNotEmpty) params['countryCodes'] = kennelCountryCodes;
      final url = Uri.parse(PORTAL_GEOCODE_PLACE_TO_ADDRESS_API_URL).replace(
        queryParameters: params,
      );
      final response = await http.get(
        url,
        headers: {
          'Accept': '*/*',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final azurePlace = AzurePlace.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
        final results = azurePlace.results ?? [];
        gazetteerResults.assignAll(results);

        if (results.isNotEmpty) {
          final first = results[0];
          if (first.position?.lat != null && first.position?.lon != null) {
            gazetteerMapController.center = LatLng(
              Angle.degree(first.position!.lat!),
              Angle.degree(first.position!.lon!),
            );
            gazetteerMapController.zoom = results.length == 1 ? 14 : 12;
          }
          if (results.length == 1) {
            gazetteerSelectedIndex.value = 0;
          }
        }
      }
    } catch (_) {
      // Search failed — leave results empty
    } finally {
      isSearching.value = false;
    }
  }

  void selectGazetteerResult(int index) {
    gazetteerSelectedIndex.value = index;
    final result = gazetteerResults[index];
    if (result.position?.lat != null && result.position?.lon != null) {
      gazetteerMapController.center = LatLng(
        Angle.degree(result.position!.lat!),
        Angle.degree(result.position!.lon!),
      );
      gazetteerMapController.zoom = 14;
    }
  }

  void confirmGazetteerSelection(int index) {
    Get.back(result: GazetteerResult(gazetteerResults[index]));
  }
}

// ---------------------------------------------------------------------------
// Dialog
// ---------------------------------------------------------------------------

class RunLocationLookupDialog extends StatelessWidget {
  const RunLocationLookupDialog({required this.controller, super.key});

  final RunLocationLookupController controller;

  // Phone-sized layout: drop the side map, full-width panel, compact text.
  bool get _isNarrow => Get.width < 600;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Dialog(
      insetPadding: _isNarrow
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 24)
          : const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(c),
            _buildTabBar(c),
            Flexible(
              child: TabBarView(
                controller: c.tabController,
                children: [
                  _buildPreviousRunsTab(c),
                  _buildGazetteerTab(c),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(RunLocationLookupController c) {
    final narrow = _isNarrow;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: narrow ? 12 : 16, vertical: 8),
      color: Colors.grey.shade200,
      child: Row(
        children: [
          Icon(
            FontAwesome5Solid.map_marker_alt,
            color: Colors.red[800],
            size: narrow ? 16 : null,
          ),
          SizedBox(width: narrow ? 8 : 12),
          Text(
            'Location Lookup',
            style: buttonLabelStyleMedium.copyWith(
              color: Colors.black,
              fontSize: narrow ? 14 : null,
            ),
          ),
          const Spacer(),
          IconButton(
            visualDensity: narrow ? VisualDensity.compact : null,
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // ── Bubble tab bar ────────────────────────────────────────────────────────

  Widget _buildTabBar(RunLocationLookupController c) {
    return Container(
      color: Colors.grey.shade200,
      padding: EdgeInsets.only(
        left: _isNarrow ? 12 : 16,
        right: _isNarrow ? 12 : 16,
        bottom: _isNarrow ? 8 : 12,
        top: 4,
      ),
      child: AnimatedBuilder(
        animation: c.tabController,
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
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    left: c.tabController.index * tabWidth,
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
                  Row(
                    children: [
                      _buildBubbleTab(
                        c,
                        index: 0,
                        icon: FontAwesome5Solid.history,
                        label: 'Previous Runs',
                      ),
                      _buildBubbleTab(
                        c,
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
    );
  }

  Widget _buildBubbleTab(
    RunLocationLookupController c, {
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = c.tabController.index == index;
    final narrow = _isNarrow;
    return Expanded(
      child: GestureDetector(
        onTap: () => c.tabController.animateTo(index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: narrow ? 8 : 10),
          color: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: narrow ? 13 : 15,
                  color: isSelected ? Colors.white : Colors.black87),
              SizedBox(width: narrow ? 6 : 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: buttonLabelStyleMedium.copyWith(
                    color: isSelected ? Colors.white : Colors.black,
                    fontSize: narrow ? 12.5 : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab 1 — Previous Runs ─────────────────────────────────────────────────

  Widget _buildPreviousRunsTab(RunLocationLookupController c) {
    // Phone: list only (no side map, no fixed-width panel that would overflow).
    if (_isNarrow) return _buildSearchPanel(c);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 360, child: _buildSearchPanel(c)),
        const VerticalDivider(width: 1),
        Expanded(child: _PreviousRunsMap(controller: c)),
      ],
    );
  }

  Widget _buildSearchPanel(RunLocationLookupController c) {
    return Column(
      children: [
        // Search field — suffix icon reacts to searchText
        Padding(
          padding: const EdgeInsets.all(12),
          child: Obx(
            () => TextField(
              controller: c.searchController,
              decoration: InputDecoration(
                hintText: 'Type to filter locations…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: c.searchText.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: c.clearSearch,
                      )
                    : null,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: c.onSearchChanged,
            ),
          ),
        ),

        // Results list
        Expanded(
          child: Obx(
            () => c.filteredLocations.isEmpty
                ? const Center(child: Text('No matching locations'))
                : SingleChildScrollView(
                    controller: c.listScrollController,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < c.filteredLocations.length; i++)
                          ..._buildLocationTile(c, i),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildLocationTile(RunLocationLookupController c, int index) {
    c.itemKeys.putIfAbsent(index, () => GlobalKey());
    return [
      Obx(() {
        final isSelected = index == c.selectedIndex.value;
        final loc = c.filteredLocations[index];
        final narrow = _isNarrow;
        return ListTile(
          key: c.itemKeys[index],
          selected: isSelected,
          selectedTileColor: Colors.blue.shade50,
          dense: narrow,
          visualDensity: narrow ? VisualDensity.compact : null,
          contentPadding: narrow
              ? const EdgeInsets.symmetric(horizontal: 10, vertical: 2)
              : null,
          horizontalTitleGap: narrow ? 8 : null,
          leading: _tileBadge('${index + 1}',
              isSelected ? Colors.green : Colors.red[800]!, narrow),
          title: Text(
            loc.label,
            style: bodyStyleBlack.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: narrow ? 13.5 : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            loc.run.eventCityAndCountry,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: narrow ? const TextStyle(fontSize: 11.5) : null,
          ),
          trailing: _tileTrailing(isSelected, () => c.confirmSelection(index),
              narrow),
          onTap: () => c.selectLocation(index),
          onLongPress: () => c.confirmSelection(index),
        );
      }),
      if (index < c.filteredLocations.length - 1) const Divider(height: 1),
    ];
  }

  // ── Tab 2 — Gazetteer Search ──────────────────────────────────────────────

  Widget _buildGazetteerTab(RunLocationLookupController c) {
    // Phone: list only (no side map, no fixed-width panel that would overflow).
    if (_isNarrow) return _buildGazetteerPanel(c);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 360, child: _buildGazetteerPanel(c)),
        const VerticalDivider(width: 1),
        Expanded(child: _GazetteerMap(controller: c)),
      ],
    );
  }

  Widget _buildGazetteerPanel(RunLocationLookupController c) {
    return Column(
      children: [
        // Search input row
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Obx(
                  () => TextField(
                    controller: c.gazetteerSearchController,
                    decoration: InputDecoration(
                      hintText: 'Search for a place…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: c.gazetteerSearchText.value.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: c.clearGazetteerSearch,
                            )
                          : null,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: c.onGazetteerSearchChanged,
                    onSubmitted: (_) => unawaited(c.performGazetteerSearch()),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Obx(
                () => ElevatedButton(
                  onPressed: c.isSearching.value
                      ? null
                      : () => unawaited(c.performGazetteerSearch()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  child: c.isSearching.value
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
              ),
            ],
          ),
        ),

        // Results list
        Expanded(
          child: Obx(
            () => c.gazetteerResults.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        c.isSearching.value
                            ? 'Searching…'
                            : c.gazetteerSearchController.text.isEmpty
                                ? 'Enter a place name, address, or establishment'
                                : 'No results found',
                        style: bodyStyleBlack.copyWith(
                            color: Colors.grey.shade700),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: c.gazetteerResults.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) =>
                        _buildGazetteerTile(c, index),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildGazetteerTile(RunLocationLookupController c, int index) {
    return Obx(() {
      final result = c.gazetteerResults[index];
      final isSelected = index == c.gazetteerSelectedIndex.value;
      final address = result.address;
      final name = result.poi?.name ?? address?.freeformAddress ?? 'Unknown';
      final subtitle = <String?>[
        address?.municipality,
        address?.countrySubdivision,
        address?.country,
      ].where((s) => s != null && s.isNotEmpty).join(', ');

      final narrow = _isNarrow;
      return ListTile(
        selected: isSelected,
        selectedTileColor: Colors.blue.shade50,
        dense: narrow,
        visualDensity: narrow ? VisualDensity.compact : null,
        contentPadding: narrow
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 2)
            : null,
        horizontalTitleGap: narrow ? 8 : null,
        leading: _tileBadge('${index + 1}',
            isSelected ? Colors.green : Colors.blue[700]!, narrow),
        title: Text(
          name,
          style: bodyStyleBlack.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: narrow ? 13.5 : null,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: narrow ? const TextStyle(fontSize: 11.5) : null,
              )
            : null,
        trailing: _tileTrailing(
            isSelected, () => c.confirmGazetteerSelection(index), narrow),
        onTap: () => c.selectGazetteerResult(index),
        onLongPress: () => c.confirmGazetteerSelection(index),
      );
    });
  }

  // Shared compact tile bits so phone rows fit without clipping.
  Widget _tileBadge(String n, Color color, bool narrow) {
    return CircleAvatar(
      radius: narrow ? 13 : 20,
      backgroundColor: color,
      child: Text(
        n,
        style: TextStyle(color: Colors.white, fontSize: narrow ? 11 : null),
      ),
    );
  }

  Widget _tileTrailing(bool isSelected, VoidCallback onUse, bool narrow) {
    if (!isSelected) {
      return Icon(Icons.chevron_right, size: narrow ? 18 : null);
    }
    return ElevatedButton(
      onPressed: onUse,
      style: narrow
          ? ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          : defaultButtonStyle,
      child: narrow
          ? const Text('Use', style: TextStyle(fontSize: 12.5))
          : Text('Use', style: textStyleButton),
    );
  }
}

// ---------------------------------------------------------------------------
// Map sub-widgets — StatefulWidget for gesture tracking
//
// MapController is a ChangeNotifier, but the map package's TileLayer does not
// subscribe to it — it reads the controller once via findAncestorWidgetOfExactType
// and never registers a rebuild dependency. We must call setState() ourselves
// whenever the controller changes (drag, zoom, or scroll wheel) so the tile
// layer and markers repaint. ever() listeners do the same for business-logic
// state changes (filter results, selection).
// ---------------------------------------------------------------------------

class _PreviousRunsMap extends StatefulWidget {
  const _PreviousRunsMap({required this.controller});
  final RunLocationLookupController controller;

  @override
  State<_PreviousRunsMap> createState() => _PreviousRunsMapState();
}

class _PreviousRunsMapState extends State<_PreviousRunsMap> {
  Offset _dragStart = Offset.zero;
  double _zoomStart = 10.0;
  late final Worker _filteredWatcher;
  late final Worker _selectedWatcher;

  void _onMapChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _filteredWatcher = ever(widget.controller.filteredLocations, (_) {
      if (mounted) setState(() {});
    });
    _selectedWatcher = ever(widget.controller.selectedIndex, (_) {
      if (mounted) setState(() {});
    });
    widget.controller.mapController.addListener(_onMapChanged);
  }

  @override
  void dispose() {
    _filteredWatcher.dispose();
    _selectedWatcher.dispose();
    widget.controller.mapController.removeListener(_onMapChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: geo_map.MapLayout(
        controller: c.mapController,
        builder: (context, transformer) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTap: () {
              c.mapController.zoom =
                  (c.mapController.zoom + 1.0).clamp(1.0, 20.0);
            },
            onScaleStart: (details) {
              _dragStart = details.focalPoint;
              _zoomStart = c.mapController.zoom;
            },
            onScaleUpdate: (details) {
              if ((details.scale - 1.0).abs() > 0.01) {
                c.mapController.zoom =
                    (_zoomStart * details.scale).clamp(1.0, 20.0);
              }
              final now = details.focalPoint;
              transformer.drag(
                  (now - _dragStart).dx, (now - _dragStart).dy);
              _dragStart = now;
            },
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) {
                  c.mapController.zoom =
                      (c.mapController.zoom - event.scrollDelta.dy / 100.0)
                          .clamp(1.0, 20.0);
                } else if (event is PointerScaleEvent) {
                  c.mapController.zoom =
                      (c.mapController.zoom * event.scale).clamp(1.0, 20.0);
                }
              },
              child: Stack(
                children: [
                  geo_map.TileLayer(
                    builder: (context, x, y, z) {
                      final url =
                          'https://www.google.com/maps/vt/pb=!1m4!1m3!1i$z!2i$x!3i$y!2m3!1e0!2sm!3i420120488!3m7!2sen!5e1105!12m4!1e68!2m2!1sset!2sRoadmap!4e0!5m1!1e0!23i4111425';
                      return Image.network(url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const SizedBox.shrink());
                    },
                  ),
                  ..._buildLocationMarkers(c, transformer),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildLocationMarkers(
    RunLocationLookupController c,
    geo_map.MapTransformer transformer,
  ) {
    final markers = <Widget>[];
    Widget? selectedMarker;

    for (var i = 0; i < c.filteredLocations.length; i++) {
      final loc = c.filteredLocations[i];
      if (loc.lat == null || loc.lon == null) continue;

      final pos = transformer.toOffset(
        LatLng(Angle.degree(loc.lat!), Angle.degree(loc.lon!)),
      );
      final isSelected = i == c.selectedIndex.value;

      final marker = Positioned(
        left: pos.dx - 16,
        top: pos.dy - 45,
        child: GestureDetector(
          onTap: () => c.selectLocation(i, scrollToItem: true),
          onDoubleTap: () => c.confirmSelection(i),
          child: _buildPin(i, isSelected: isSelected, color: Colors.red[800]!),
        ),
      );

      if (isSelected) {
        selectedMarker = marker;
      } else {
        markers.add(marker);
      }
    }

    if (selectedMarker != null) markers.add(selectedMarker);
    return markers;
  }
}

class _GazetteerMap extends StatefulWidget {
  const _GazetteerMap({required this.controller});
  final RunLocationLookupController controller;

  @override
  State<_GazetteerMap> createState() => _GazetteerMapState();
}

class _GazetteerMapState extends State<_GazetteerMap> {
  Offset _dragStart = Offset.zero;
  double _zoomStart = 10.0;
  late final Worker _resultsWatcher;
  late final Worker _selectedWatcher;

  void _onMapChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _resultsWatcher = ever(widget.controller.gazetteerResults, (_) {
      if (mounted) setState(() {});
    });
    _selectedWatcher = ever(widget.controller.gazetteerSelectedIndex, (_) {
      if (mounted) setState(() {});
    });
    widget.controller.gazetteerMapController.addListener(_onMapChanged);
  }

  @override
  void dispose() {
    _resultsWatcher.dispose();
    _selectedWatcher.dispose();
    widget.controller.gazetteerMapController.removeListener(_onMapChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: geo_map.MapLayout(
        controller: c.gazetteerMapController,
        builder: (context, transformer) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTap: () {
              c.gazetteerMapController.zoom =
                  (c.gazetteerMapController.zoom + 1.0).clamp(1.0, 20.0);
            },
            onScaleStart: (details) {
              _dragStart = details.focalPoint;
              _zoomStart = c.gazetteerMapController.zoom;
            },
            onScaleUpdate: (details) {
              if ((details.scale - 1.0).abs() > 0.01) {
                c.gazetteerMapController.zoom =
                    (_zoomStart * details.scale).clamp(1.0, 20.0);
              }
              final now = details.focalPoint;
              transformer.drag(
                  (now - _dragStart).dx, (now - _dragStart).dy);
              _dragStart = now;
            },
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) {
                  c.gazetteerMapController.zoom =
                      (c.gazetteerMapController.zoom -
                              event.scrollDelta.dy / 100.0)
                          .clamp(1.0, 20.0);
                } else if (event is PointerScaleEvent) {
                  c.gazetteerMapController.zoom =
                      (c.gazetteerMapController.zoom * event.scale)
                          .clamp(1.0, 20.0);
                }
              },
              child: Stack(
                children: [
                  geo_map.TileLayer(
                    builder: (context, x, y, z) {
                      final url =
                          'https://www.google.com/maps/vt/pb=!1m4!1m3!1i$z!2i$x!3i$y!2m3!1e0!2sm!3i420120488!3m7!2sen!5e1105!12m4!1e68!2m2!1sset!2sRoadmap!4e0!5m1!1e0!23i4111425';
                      return Image.network(url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const SizedBox.shrink());
                    },
                  ),
                  ..._buildGazetteerMarkers(c, transformer),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildGazetteerMarkers(
    RunLocationLookupController c,
    geo_map.MapTransformer transformer,
  ) {
    final markers = <Widget>[];

    for (var i = 0; i < c.gazetteerResults.length; i++) {
      final result = c.gazetteerResults[i];
      if (result.position?.lat == null || result.position?.lon == null) {
        continue;
      }

      final pos = transformer.toOffset(
        LatLng(
          Angle.degree(result.position!.lat!),
          Angle.degree(result.position!.lon!),
        ),
      );
      final isSelected = i == c.gazetteerSelectedIndex.value;

      markers.add(
        Positioned(
          left: pos.dx - 16,
          top: pos.dy - 45,
          child: GestureDetector(
            onTap: () => c.selectGazetteerResult(i),
            onDoubleTap: () => c.confirmGazetteerSelection(i),
            child: _buildPin(i, isSelected: isSelected, color: Colors.blue[700]!),
          ),
        ),
      );
    }

    return markers;
  }
}

// ---------------------------------------------------------------------------
// Shared pin widget
// ---------------------------------------------------------------------------

Widget _buildPin(int index, {required bool isSelected, required Color color}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : color,
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
            '${index + 1}',
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
          color: isSelected ? Colors.green : color,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    ],
  );
}
