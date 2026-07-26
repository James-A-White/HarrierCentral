import 'package:harrier_central/imports.dart';

class GuestDiscoveryController extends GetxController {
  final RxList<GuestRunModel> _allUpcomingRuns = <GuestRunModel>[].obs;
  final RxList<GuestRunModel> _allPastRuns = <GuestRunModel>[].obs;

  final RxBool isLoadingUpcoming = true.obs;
  final RxBool isLoadingPast = false.obs;
  final RxBool hasErrorUpcoming = false.obs;
  final RxBool hasErrorPast = false.obs;
  final RxBool _pastTabLoaded = false.obs;
  // searchQuery = the live text field value (updates per keystroke).
  // _appliedQuery = the debounced value the heavy list filter actually uses, so
  // typing doesn't re-filter up to 500 runs on every keystroke.
  final RxString searchQuery = ''.obs;
  final RxString _appliedQuery = ''.obs;
  Worker? _searchDebounce;
  // Per-run cache of normalised (diacritics-stripped, lowercased) fields, so the
  // filter doesn't re-normalise 6 fields per run on every keystroke. Expando is
  // weak-keyed: entries vanish when a run is replaced on reload — no manual clear.
  final Expando<List<String>> _fieldCache = Expando<List<String>>();
  final RxList<String> savedSearches = <String>[].obs;

  static const int maxSavedSearches = 5;

  bool get pastTabLoaded => _pastTabLoaded.value;

  /// The debounced query the list is currently filtered by (reactive).
  String get appliedQuery => _appliedQuery.value;

  List<GuestRunModel> get filteredUpcoming => _filter(_allUpcomingRuns);
  List<GuestRunModel> get filteredPast => _filter(_allPastRuns);

  void setSearch(String q) => searchQuery.value = q;

  Future<void> addSavedSearch(String term) async {
    final String t = term.trim();
    if (t.isEmpty) return;
    if (savedSearches.contains(t)) return;
    if (savedSearches.length >= maxSavedSearches) return;
    savedSearches.add(t);
    await _persistSavedSearches();
  }

  Future<void> removeSavedSearch(String term) async {
    savedSearches.remove(term);
    await _persistSavedSearches();
  }

  Future<void> _persistSavedSearches() async {
    if (savedSearches.isEmpty) {
      await setStringPref(StringPrefsEnum.guestSavedSearchTerm, null);
    } else {
      await setStringPref(
        StringPrefsEnum.guestSavedSearchTerm,
        jsonEncode(savedSearches.toList()),
      );
    }
  }

  // Returns the all-runs list split into [pinned = matching any saved term] and
  // [rest = everything else]. Only meaningful when savedSearches is non-empty.
  ({List<GuestRunModel> pinned, List<GuestRunModel> rest}) splitUpcoming() =>
      _splitBySaved(_allUpcomingRuns);

  ({List<GuestRunModel> pinned, List<GuestRunModel> rest}) splitPast() =>
      _splitBySaved(_allPastRuns);

  List<GuestRunModel> _filter(List<GuestRunModel> runs) {
    final String q = removeDiacritics(_appliedQuery.value.trim().toLowerCase());
    if (q.isEmpty) return runs;
    return runs.where((GuestRunModel r) => _matches(r, q)).toList();
  }

  /// Normalised searchable fields for a run, computed once and cached.
  List<String> _fields(GuestRunModel r) {
    final cached = _fieldCache[r];
    if (cached != null) return cached;
    final fields = <String?>[
      r.kennelName,
      r.kennelShortName,
      r.eventName,
      r.locationCity,
      r.locationCountry,
      r.kennelContinent,
    ]
        .where((String? s) => s != null && s.isNotEmpty)
        .map((String? s) => removeDiacritics(s!.toLowerCase()))
        .toList();
    _fieldCache[r] = fields;
    return fields;
  }

  ({List<GuestRunModel> pinned, List<GuestRunModel> rest}) _splitBySaved(
    List<GuestRunModel> runs,
  ) {
    if (savedSearches.isEmpty) {
      return (pinned: <GuestRunModel>[], rest: runs.toList());
    }
    final List<String> savedNorm = savedSearches
        .map((String s) => removeDiacritics(s.trim().toLowerCase()))
        .toList();
    final List<GuestRunModel> pinned = [];
    final List<GuestRunModel> rest = [];
    for (final GuestRunModel r in runs) {
      (savedNorm.any((String q) => _matches(r, q)) ? pinned : rest).add(r);
    }
    return (pinned: pinned, rest: rest);
  }

  bool _matches(GuestRunModel r, String q) =>
      _fields(r).any((String f) => f.contains(q));

  @override
  void onInit() {
    super.onInit();
    // Debounce the live query into _appliedQuery so the list re-filters ~250ms
    // after typing stops, not on every keystroke.
    _searchDebounce = debounce<String>(
      searchQuery,
      (String q) => _appliedQuery.value = q,
      time: const Duration(milliseconds: 250),
    );
    _loadSavedSearches();
    loadUpcoming();
  }

  @override
  void onClose() {
    _searchDebounce?.dispose();
    super.onClose();
  }

  void _loadSavedSearches() {
    final String? stored =
        getStringPref(StringPrefsEnum.guestSavedSearchTerm);
    if (stored == null || stored.isEmpty) return;
    try {
      final dynamic decoded = jsonDecode(stored);
      if (decoded is List) {
        savedSearches.addAll(
          decoded.cast<String>().take(maxSavedSearches),
        );
      } else {
        // Migration: old format was a plain string, not JSON.
        savedSearches.add(stored);
      }
    } catch (_) {
      // If JSON parse fails it was the old plain-string format.
      savedSearches.add(stored);
    }
  }

  Future<void> loadUpcoming() async {
    isLoadingUpcoming.value = true;
    hasErrorUpcoming.value = false;

    final (:bool success, :int total, :List<GuestRunModel> runs) =
        await GuestRunsService.getGlobalRuns(isFuture: true, pageSize: 500);

    _allUpcomingRuns
      ..clear()
      ..addAll(runs);

    isLoadingUpcoming.value = false;
    if (!success) hasErrorUpcoming.value = true;
  }

  Future<void> loadPast() async {
    if (_pastTabLoaded.value) return;
    _pastTabLoaded.value = true;
    isLoadingPast.value = true;
    hasErrorPast.value = false;

    final String minDate = DateTime.now()
        .subtract(const Duration(days: 60))
        .toUtc()
        .toIso8601String();

    final (:bool success, :int total, :List<GuestRunModel> runs) =
        await GuestRunsService.getGlobalRuns(
      isFuture: false,
      pageSize: 500,
      minEventDate: minDate,
    );

    _allPastRuns
      ..clear()
      ..addAll(runs);

    isLoadingPast.value = false;
    if (!success) hasErrorPast.value = true;
  }

  @override
  Future<void> refresh() async {
    _pastTabLoaded.value = false;
    _allPastRuns.clear();
    await loadUpcoming();
  }
}
