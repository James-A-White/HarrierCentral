import 'package:harrier_central/imports.dart';

class GuestDiscoveryController extends GetxController {
  final RxList<GuestRunModel> _allUpcomingRuns = <GuestRunModel>[].obs;
  final RxList<GuestRunModel> _allPastRuns = <GuestRunModel>[].obs;

  final RxBool isLoadingUpcoming = true.obs;
  final RxBool isLoadingPast = false.obs;
  final RxBool hasErrorUpcoming = false.obs;
  final RxBool hasErrorPast = false.obs;
  final RxBool _pastTabLoaded = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString savedSearch = ''.obs;

  bool get pastTabLoaded => _pastTabLoaded.value;

  List<GuestRunModel> get filteredUpcoming => _filter(_allUpcomingRuns);
  List<GuestRunModel> get filteredPast => _filter(_allPastRuns);

  void setSearch(String q) => searchQuery.value = q;

  Future<void> setSavedSearch(String term) async {
    savedSearch.value = term.trim();
    await setStringPref(StringPrefsEnum.guestSavedSearchTerm, term.trim());
  }

  Future<void> clearSavedSearch() async {
    savedSearch.value = '';
    await setStringPref(StringPrefsEnum.guestSavedSearchTerm, null);
  }

  // Returns the all-runs list split into [pinned = matching saved term] and
  // [rest = everything else]. Only meaningful when savedSearch is non-empty.
  ({List<GuestRunModel> pinned, List<GuestRunModel> rest}) splitUpcoming() =>
      _splitBySaved(_allUpcomingRuns);

  ({List<GuestRunModel> pinned, List<GuestRunModel> rest}) splitPast() =>
      _splitBySaved(_allPastRuns);

  List<GuestRunModel> _filter(List<GuestRunModel> runs) {
    final String q =
        removeDiacritics(searchQuery.value.trim().toLowerCase());
    if (q.isEmpty) return runs;
    return runs.where((GuestRunModel r) => _matches(r, q)).toList();
  }

  ({List<GuestRunModel> pinned, List<GuestRunModel> rest}) _splitBySaved(
    List<GuestRunModel> runs,
  ) {
    final String saved =
        removeDiacritics(savedSearch.value.trim().toLowerCase());
    if (saved.isEmpty) {
      return (pinned: <GuestRunModel>[], rest: runs.toList());
    }
    final List<GuestRunModel> pinned = [];
    final List<GuestRunModel> rest = [];
    for (final GuestRunModel r in runs) {
      (_matches(r, saved) ? pinned : rest).add(r);
    }
    return (pinned: pinned, rest: rest);
  }

  bool _matches(GuestRunModel r, String q) {
    bool hit(String? s) =>
        s != null && removeDiacritics(s.toLowerCase()).contains(q);
    return hit(r.kennelName) ||
        hit(r.kennelShortName) ||
        hit(r.eventName) ||
        hit(r.locationCity) ||
        hit(r.locationCountry) ||
        hit(r.kennelContinent);
  }

  @override
  void onInit() {
    super.onInit();
    savedSearch.value =
        getStringPref(StringPrefsEnum.guestSavedSearchTerm) ?? '';
    loadUpcoming();
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
