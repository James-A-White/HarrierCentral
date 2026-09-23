// ignore_for_file: constant_identifier_names

import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

class LeaderboardModel {
  String displayName;
  int totalRunCount;
  int totalHaringCount;
  int ytdTotalRunCount;
  int ytdHaringCount;
  int rollingYearTotalRunCount;
  int rollingYearHaringCount;
  String kennelId;
  String? homeKennelId;
  String hasherId;
  int kennelCountTotal;
  int kennelCountYtd;
  int kennelCountRollingYear;
  String searchText;

  LeaderboardModel({
    required this.displayName,
    required this.totalRunCount,
    required this.totalHaringCount,
    required this.ytdTotalRunCount,
    required this.ytdHaringCount,
    required this.rollingYearTotalRunCount,
    required this.rollingYearHaringCount,
    required this.kennelId,
    this.homeKennelId,
    required this.hasherId,
    required this.kennelCountTotal,
    required this.kennelCountYtd,
    required this.kennelCountRollingYear,
    required this.searchText,
  });

  LeaderboardModel.fromJson(Map<String, dynamic> json)
    : displayName = json['displayName'],
      totalRunCount = json['totalRunCount'],
      totalHaringCount = json['totalHaringCount'],
      ytdTotalRunCount = json['ytdTotalRunCount'],
      ytdHaringCount = json['ytdHaringCount'],
      rollingYearTotalRunCount = json['rollingYearTotalRunCount'],
      rollingYearHaringCount = json['rollingYearHaringCount'],
      kennelId = (json['kennelId'] as String).toLowerCase(),
      homeKennelId = (json['homeKennelId'] as String?)?.toLowerCase(),
      hasherId = (json['hasherId'] as String).toLowerCase(),
      kennelCountTotal = 0,
      kennelCountYtd = 0,
      kennelCountRollingYear = 0,
      searchText = '';

  LeaderboardModel.clone(LeaderboardModel lm)
    : displayName = lm.displayName,
      totalRunCount = lm.totalRunCount,
      totalHaringCount = lm.totalHaringCount,
      ytdTotalRunCount = lm.ytdTotalRunCount,
      ytdHaringCount = lm.ytdHaringCount,
      rollingYearTotalRunCount = lm.rollingYearTotalRunCount,
      rollingYearHaringCount = lm.rollingYearHaringCount,
      kennelId = lm.kennelId,
      homeKennelId = lm.homeKennelId,
      hasherId = lm.hasherId,
      kennelCountTotal = lm.kennelCountTotal,
      kennelCountYtd = lm.kennelCountYtd,
      kennelCountRollingYear = lm.kennelCountRollingYear,
      searchText = lm.searchText;
}

/// State for the leaderboard (one kennel, or every kennel from the drawer):
/// the per-kennel rows and the per-hasher aggregate, the timespan tab, the
/// sort column/direction, the +/- search and the two checkboxes.
///
/// Migrated from a State on 2026-09-23. The per-hasher aggregate and the
/// sort are pure statics with unit tests; the four lists are assigned in one
/// step rather than cleared and refilled across an await.
class LeaderboardController extends GetxController
    with GetSingleTickerProviderStateMixin {
  LeaderboardController({this.kennelId});

  final String? kennelId;

  static String tagFor(String? kennelId) => 'leaderboard-${kennelId ?? 'all'}';

  static const int TABINDEX_365_DAYS = 0;
  static const int TABINDEX_CURRENT_YEAR = 1;
  static const int TABINDEX_TOTAL = 2;

  late final TabController timespanTabController;
  final RxInt tabIndex = 0.obs;

  /// kennelId → the kennel's detail row (name, short name, search text).
  Map<String, Map<String, dynamic>> kennels = <String, Map<String, dynamic>>{};

  List<LeaderboardModel> _rows = <LeaderboardModel>[];
  List<LeaderboardModel> _aggregate = <LeaderboardModel>[];
  final RxList<LeaderboardModel> filteredRows = <LeaderboardModel>[].obs;
  final RxList<LeaderboardModel> filteredAggregate = <LeaderboardModel>[].obs;

  final RxBool showKennels = false.obs;
  final RxBool showHomeKennel = false.obs;
  final RxBool isLoading = true.obs;

  final RxInt sortColumn = 0.obs;
  final RxBool sortAsc = false.obs;

  final ScrollController leaderScrollController = ScrollController(
    keepScrollOffset: false,
    initialScrollOffset: 50.0,
  );
  final FocusNode searchFocusNode = FocusNode();
  final TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    timespanTabController = TabController(vsync: this, length: 3);
    timespanTabController.addListener(_onTab);
    if (kennelId != null) showKennels.value = true;
    unawaited(_load());
  }

  @override
  void onClose() {
    timespanTabController.removeListener(_onTab);
    timespanTabController.dispose();
    leaderScrollController.dispose();
    searchFocusNode.dispose();
    searchController.dispose();
    super.onClose();
  }

  void _onTab() {
    tabIndex.value = timespanTabController.index;
  }

  /// A tab tap: the columns keep their sort, on the new timespan's numbers.
  void onTabTap() => sortLeaderboard(sortColumn.value, false);

  void toggleShowKennels() => showKennels.value = !showKennels.value;
  void toggleShowHomeKennel() => showHomeKennel.value = !showHomeKennel.value;

  Future<void> _load() async {
    final List<Map<String, dynamic>> kennelRows =
        await QueryKennels.queryKennelDetails();
    if (isClosed) return;
    kennels = <String, Map<String, dynamic>>{
      for (final Map<String, dynamic> k in kennelRows) k['kennelId']: k,
    };
    if (filteredRows.isEmpty) {
      await _getLeaderboard();
      if (isClosed) return;
      sortColumn.value = 0;
      sortAsc.value = false;
      sortLeaderboard(0, false);
    }
    isLoading.value = false;
  }

  Future<void> _getLeaderboard() async {
    String responseBody;
    bool updateLocalLeaderboardCache = false;

    final DateTime? lastLeaderboardUpdate = getDatePref(
      DatePrefsEnum.lastLeaderboardUpdate,
    );

    // The all-kennels board is cached for the day; a kennel's own is fresh.
    if ((kennelId != null) ||
        (lastLeaderboardUpdate == null) ||
        (DateFormat('yyyyMMMdd').format(lastLeaderboardUpdate) !=
            DateFormat('yyyyMMMdd').format(DateTime.now()))) {
      final String userId = getStringPref(StringPrefsEnum.userId) ?? '';
      final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
      final String deviceSecret =
          getStringPref(StringPrefsEnum.deviceSecret) ?? '';

      responseBody = await ServiceCommon.sendHttpPost(
        () => jsonEncode(<String, Object?>{
          'queryType': 'getLeaderboard',
          'deviceId': deviceId,
          'accessToken': Utilities.generateToken(
            userId,
            'hcapp_getLeaderboard',
            paramString: deviceSecret,
          ),
          'kennelId': kennelId,
        }),
      );
      updateLocalLeaderboardCache = true;
    } else {
      responseBody = getStringPref(StringPrefsEnum.leaderboardJson) ?? '';
      updateLocalLeaderboardCache = false;
    }
    if (isClosed) return;

    if (responseBody.startsWith(ERROR_PREFIX)) return;

    // temporarily cache the leaderboard
    if ((kennelId == null) && updateLocalLeaderboardCache) {
      await setDatePref(DatePrefsEnum.lastLeaderboardUpdate, DateTime.now());
      await setStringPref(StringPrefsEnum.leaderboardJson, responseBody);
      if (isClosed) return;
    }

    final List<dynamic> jsonResults = json.decode(responseBody);
    final List<LeaderboardModel> rows = <LeaderboardModel>[];
    for (final dynamic element in jsonResults[0]) {
      final LeaderboardModel lm = LeaderboardModel.fromJson(element);
      lm.searchText = searchTextFor(lm, kennels);
      rows.add(lm);
    }

    _rows = rows;
    // The per-hasher aggregate only means something across all kennels.
    _aggregate = (kennelId == null || kennelId!.isEmpty)
        ? aggregateByHasher(rows, kennels)
        : <LeaderboardModel>[];
    filteredAggregate.assignAll(_aggregate);
    filteredRows.assignAll(
      _rows.map((item) => LeaderboardModel.clone(item)).toList(),
    );
  }

  /// What the search box matches against: the name plus the kennel's own
  /// search text (short name, name, city…), and the home kennel's if set.
  static String searchTextFor(
    LeaderboardModel lm,
    Map<String, Map<String, dynamic>> kennels,
  ) {
    String text =
        ' ${lm.displayName}, ${kennels[lm.kennelId]?['searchText']}, ';
    if ((lm.homeKennelId != null) && (lm.homeKennelId!.isNotEmpty)) {
      text += '${kennels[lm.kennelId]?['searchText']}';
    }
    return text;
  }

  /// One row per hasher summed across their kennels, with a count of the
  /// kennels they have runs with in each timespan. Pure, unit-tested.
  static List<LeaderboardModel> aggregateByHasher(
    List<LeaderboardModel> rows,
    Map<String, Map<String, dynamic>> kennels,
  ) {
    final Map<String, LeaderboardModel> byHasher = <String, LeaderboardModel>{};
    for (final LeaderboardModel lm in rows) {
      final LeaderboardModel? agg = byHasher[lm.hasherId];
      if (agg != null) {
        agg.rollingYearHaringCount += lm.rollingYearHaringCount;
        agg.rollingYearTotalRunCount += lm.rollingYearTotalRunCount;
        agg.totalHaringCount += lm.totalHaringCount;
        agg.totalRunCount += lm.totalRunCount;
        agg.ytdHaringCount += lm.ytdHaringCount;
        agg.ytdTotalRunCount += lm.ytdTotalRunCount;
        agg.searchText += ' ${kennels[lm.kennelId]?['searchText']}, ';
        if (lm.totalRunCount > 0) agg.kennelCountTotal += 1;
        if (lm.rollingYearTotalRunCount > 0) agg.kennelCountRollingYear += 1;
        if (lm.ytdTotalRunCount > 0) agg.kennelCountYtd += 1;
      } else {
        final LeaderboardModel first = LeaderboardModel.clone(lm);
        first.searchText = searchTextFor(first, kennels);
        if (lm.totalRunCount > 0) first.kennelCountTotal = 1;
        if (lm.rollingYearTotalRunCount > 0) first.kennelCountRollingYear = 1;
        if (lm.ytdTotalRunCount > 0) first.kennelCountYtd = 1;
        byHasher[lm.hasherId] = first;
      }
    }
    return byHasher.values.toList();
  }

  /// Column 0 = runs, 1 = hared, 2 = name; the timespan picks which counts.
  /// Ties on a count fall back to name; ties on name to kennel. Pure.
  static Comparator<LeaderboardModel> comparator(
    int column,
    int tabIndex,
    bool asc,
  ) {
    int count(LeaderboardModel m) {
      if (column == 0) {
        return tabIndex == TABINDEX_TOTAL
            ? m.totalRunCount
            : tabIndex == TABINDEX_365_DAYS
            ? m.rollingYearTotalRunCount
            : m.ytdTotalRunCount;
      }
      return tabIndex == TABINDEX_TOTAL
          ? m.totalHaringCount
          : tabIndex == TABINDEX_365_DAYS
          ? m.rollingYearHaringCount
          : m.ytdHaringCount;
    }

    int byName(LeaderboardModel a, LeaderboardModel b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());

    if (column == 2) {
      return (a, b) {
        final int cmp = byName(a, b);
        if (cmp != 0) return asc ? cmp : -cmp;
        return a.kennelId.toLowerCase().compareTo(b.kennelId.toLowerCase());
      };
    }
    return (a, b) {
      final int cmp = count(a).compareTo(count(b));
      if (cmp != 0) return asc ? cmp : -cmp;
      return byName(a, b);
    };
  }

  void sortLeaderboard(int columnIndex, bool alternateSortOrder) {
    if (filteredRows.isEmpty && filteredAggregate.isEmpty) return;
    if (alternateSortOrder && (columnIndex == sortColumn.value)) {
      sortAsc.value = !sortAsc.value;
    }
    sortColumn.value = columnIndex;
    final Comparator<LeaderboardModel> cmp = comparator(
      columnIndex,
      tabIndex.value,
      sortAsc.value,
    );
    filteredRows.assignAll(List<LeaderboardModel>.of(filteredRows)..sort(cmp));
    filteredAggregate.assignAll(
      List<LeaderboardModel>.of(filteredAggregate)..sort(cmp),
    );
  }

  /// "+word" must match, "-word" must not, and the leading words are ORed
  /// with the + terms. Pure.
  static bool matches(
    LeaderboardModel a,
    List<String> addParams,
    List<String> subParams,
  ) {
    final String text = a.searchText.toLowerCase();
    for (final String param in subParams) {
      if (text.contains(param)) return false;
    }
    for (final String param in addParams) {
      if (text.contains(param)) return true;
    }
    return false;
  }

  void filterResults(String filter) {
    List<String> addParams = <String>[];
    List<String> subParams = <String>[];

    filter = filter.replaceAll('+ ', '+').replaceAll('- ', '-');

    final int firstPositive = filter.indexOf('+');
    if (firstPositive >= 0) {
      addParams = Utilities.parseSearchTokens(filter, r"\+");
    }
    final int firstNegative = filter.indexOf('-');
    if (firstNegative >= 0) {
      subParams = Utilities.parseSearchTokens(filter, r"-");
    }

    String firstTokenString = '';
    if ((firstPositive > 0) && (firstNegative > 0)) {
      final int firstToken = min(firstPositive, firstNegative);
      firstTokenString = filter.substring(0, firstToken).trim().toLowerCase();
    } else if (firstPositive > 0) {
      firstTokenString = filter
          .substring(0, firstPositive)
          .trim()
          .toLowerCase();
    } else if (firstNegative > 0) {
      firstTokenString = filter
          .substring(0, firstNegative)
          .trim()
          .toLowerCase();
    } else {
      firstTokenString = filter.trim().toLowerCase();
    }
    if (firstTokenString.isNotEmpty) addParams.add(firstTokenString);

    if (filter.isNotEmpty) {
      filteredRows.assignAll(
        _rows.where((a) => matches(a, addParams, subParams)).toList(),
      );
      filteredAggregate.assignAll(
        _aggregate.where((a) => matches(a, addParams, subParams)).toList(),
      );
    } else {
      filteredRows.assignAll(_rows);
      filteredAggregate.assignAll(_aggregate);
    }
  }

  void onSearchChanged(String text) {
    filterResults(text);
    sortLeaderboard(sortColumn.value, false);
  }

  void clearSearch() {
    searchController.text = '';
    onSearchChanged('');
  }
}
