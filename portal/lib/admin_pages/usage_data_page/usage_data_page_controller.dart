import 'package:hcportal/imports.dart';
import 'package:hcportal/admin_pages/usage_data_page/category_detail_dialog.dart';
import 'package:hcportal/models/usage_data_new_events/usage_data_new_events.dart';

class UsageDataPageController extends GetxController {
  final hcVersions = <UdHcVersion>[].obs;
  final maxHcVersion = 0.obs;
  final appActivity = <UdAppActivityModel>[].obs;
  final integrationMonitor = <UdIntegrationMonitorModel>[].obs;
  final recentUsers = <UdRecentUserModel>[].obs;
  final newEvents = <UdNewEventsModel>[].obs;

  final isUpdatingId = (-1).obs;
  final isUpdatingDays = (-1).obs;
  final isUpdatingVersion = ''.obs;

  bool _isFetching = false;
  Timer? _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    unawaited(_fetchUsageData());
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _fetchUsageData(),
    );
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    super.onClose();
  }

  Future<void> _fetchUsageData() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      final accessToken = Utilities.generateToken(
        box.get(HIVE_HASHER_ID) as String,
        'hcportal_getUsageData',
      );

      final body = <String, String>{
        'queryType': 'getUsageData',
        'publicHasherId': box.get(HIVE_HASHER_ID) as String,
        'accessToken': accessToken,
      };

      final jsonString =
          await ServiceCommon.sendHttpPostToAzureFunctionApi(body);
      if (jsonString.startsWith(ERROR_PREFIX)) return;
      final jsonStringNormalised =
          jsonString.replaceAll('[[{', '{').replaceAll('}]]', '}');
      final elements = jsonStringNormalised.split('],[');

      hcVersions.value = _parseList(elements[0], UdHcVersion.fromJson);
      _calculateMaxHcVersion();

      integrationMonitor.value =
          _parseList(elements[1], UdIntegrationMonitorModel.fromJson);
      appActivity.value = _parseList(elements[2], UdAppActivityModel.fromJson);
      recentUsers.value = _parseList(elements[3], UdRecentUserModel.fromJson);
      newEvents.value = _parseList(elements[4], UdNewEventsModel.fromJson);

      // Safety net: clear any stuck loading indicators on refresh
      isUpdatingId.value = -1;
      isUpdatingDays.value = -1;
      isUpdatingVersion.value = '';
    } finally {
      _isFetching = false;
    }
  }

  List<T> _parseList<T>(
    String raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final list = json.decode('[$raw]') as List<dynamic>;
    return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  void _calculateMaxHcVersion() {
    var maxValue = 0;
    for (final version in hcVersions) {
      final value = version.isNotiPhone + version.isiPhone;
      if (value > maxValue) maxValue = value;
    }
    maxHcVersion.value = maxValue;
  }

  Future<void> getCategoryDetail(
    int categoryId,
    int days, {
    String title = 'Details',
  }) async {
    isUpdatingId.value = categoryId;
    isUpdatingDays.value = days;

    try {
      final accessToken = Utilities.generateToken(
        box.get(HIVE_HASHER_ID) as String,
        'hcportal_getCategoryDetail2',
      );

      final body = <String, String>{
        'queryType': 'getCategoryDetail2',
        'publicHasherId': box.get(HIVE_HASHER_ID) as String,
        'accessToken': accessToken,
        'categoryId': categoryId.toString(),
        'days': days.toString(),
      };

      final result = await ServiceCommon.sendHttpPostToAzureFunctionApi(body);
      await _showCategoryDetailDialog(result, title);
    } catch (_) {
      // getCategoryDetail error
    } finally {
      isUpdatingId.value = -1;
      isUpdatingDays.value = -1;
    }
  }

  Future<void> getHcVersionDetail(
    String version,
    String buildNumber, {
    String title = 'Version Details',
  }) async {
    isUpdatingVersion.value = '$version/$buildNumber';

    try {
      final accessToken = Utilities.generateToken(
        box.get(HIVE_HASHER_ID) as String,
        'hcportal_getCategoryDetail2',
      );

      final body = <String, String>{
        'queryType': 'getCategoryDetail2',
        'publicHasherId': box.get(HIVE_HASHER_ID) as String,
        'accessToken': accessToken,
        'categoryId': '100',
        'days': '14',
        'hcVersion': version,
        'hcBuild': buildNumber,
      };

      final result = await ServiceCommon.sendHttpPostToAzureFunctionApi(body);
      await _showCategoryDetailDialog(result, title);
    } catch (_) {
      // getHcVersionDetail error
    } finally {
      isUpdatingVersion.value = '';
    }
  }

  Future<void> _showCategoryDetailDialog(
    String result,
    String title,
  ) async {
    if (result.startsWith(ERROR_PREFIX)) return;
    final outer = json.decode(result) as List<dynamic>;
    if (outer.isEmpty) return;

    final firstSet = outer[0] as List<dynamic>;
    if (firstSet.isEmpty) return;

    final firstRow = firstSet.first as Map<String, dynamic>;

    // Check if this is an error response from validation
    if (firstRow.containsKey('errorId')) {
      return;
    }

    // Parse headers — only include non-empty columns
    final activeColumns = <int>[];
    final headers = <String>[];
    for (var i = 1; i <= 6; i++) {
      final h = (firstRow['col$i'] as String?) ?? '';
      if (h.isNotEmpty) {
        activeColumns.add(i);
        headers.add(h);
      }
    }

    // Parse data rows
    final dataList = outer.length > 1 ? outer[1] as List<dynamic> : <dynamic>[];
    final rows = <List<String>>[];
    for (final item in dataList) {
      final map = item as Map<String, dynamic>;
      final row = <String>[];
      for (final colIdx in activeColumns) {
        row.add((map['col$colIdx'] as String?) ?? '');
      }
      rows.add(row);
    }

    await showDialog<void>(
      context: navigatorKey.currentContext!,
      builder: (_) => CategoryDetailDialog(
        title: title,
        headers: headers,
        rows: rows,
      ),
    );
  }

  Future<void> integrationBlockPressed(
    UdIntegrationMonitorModel integration,
  ) async {
    if (integration.integrationId == 1) {
      final naughty = integration.kennelsFailedInfo.replaceAll(',', '\r\n');
      final nice = integration.kennelsSucceededInfo.replaceAll(',', '\r\n');
      await IveCoreUtilities.showAlert(
        navigatorKey.currentContext!,
        'Naughty / Nice list',
        'Naughty List\r\n$naughty\r\nNice List\r\n$nice',
        'Done',
      );
    }
  }

  /// Formats a minutes-based duration into a human-readable string.
  String formatMinutesDuration(int totalMinutes, {required bool isFuture}) {
    final absMinutes = totalMinutes.abs();
    if (absMinutes < 60) {
      return isFuture
          ? 'Run starts in $absMinutes minutes'
          : 'Run started $absMinutes minutes ago';
    }
    if (absMinutes < 1440) {
      final hours = absMinutes ~/ 60;
      final mins = absMinutes % 60;
      return isFuture
          ? 'Run starts in $hours hours, $mins minutes'
          : 'Run started $hours hours, $mins minutes ago';
    }
    final days = absMinutes ~/ 1440;
    final hours = (absMinutes % 1440) ~/ 60;
    final mins = absMinutes % 60;
    return isFuture
        ? 'Run starts in $days days, $hours hours, $mins minutes'
        : 'Run started $days days, $hours hours, $mins minutes ago';
  }

  /// Formats creation/update time into a human-readable string.
  String formatCreatedUpdated(UdNewEventsModel evt) {
    if (evt.minutesAgoCreated - 2 > evt.minutesAgoUpdated) {
      return evt.minutesAgoUpdated < 60
          ? 'Updated ${evt.minutesAgoUpdated} minutes ago'
          : 'Updated ${evt.minutesAgoUpdated ~/ 60} hours, ${evt.minutesAgoUpdated % 60} minutes ago';
    }
    return evt.minutesAgoCreated < 60
        ? 'Created ${evt.minutesAgoCreated} minutes ago'
        : 'Created ${evt.minutesAgoCreated ~/ 60} hours, ${evt.minutesAgoCreated % 60} minutes ago';
  }

  /// Returns a login time string for a recent user.
  String formatLoginTime(UdRecentUserModel user) {
    final minAgo = user.minutesSinceLastLogin;
    final timeStr = (minAgo ~/ 60) == 0
        ? '${minAgo % 60} min ago'
        : '${minAgo ~/ 60}:${(minAgo % 60).toString().padLeft(2, '0')} ago';
    return '$timeStr / ${user.loginCount} login(s)';
  }

  /// Fetches login history for a user and returns the list.
  Future<List<UdLoginHistoryModel>> getLoginHistory(String userId) async {
    try {
      final accessToken = Utilities.generateToken(
        box.get(HIVE_HASHER_ID) as String,
        'hcportal_getLoginHistory',
      );

      final body = <String, String>{
        'queryType': 'getLoginHistory',
        'publicHasherId': box.get(HIVE_HASHER_ID) as String,
        'accessToken': accessToken,
        'userId': userId,
      };

      final result = await ServiceCommon.sendHttpPostToAzureFunctionApi(body);
      final outer = json.decode(result) as List<dynamic>;
      final items = outer.first as List<dynamic>;
      return items
          .map(
            (e) => UdLoginHistoryModel.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return <UdLoginHistoryModel>[];
    }
  }
}
