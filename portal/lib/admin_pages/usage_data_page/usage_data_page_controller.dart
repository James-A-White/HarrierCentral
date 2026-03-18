import 'package:flutter/foundation.dart' show kDebugMode;
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
      final deviceId = box.get(HIVE_DEVICE_ID) as String;
      final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';

      final accessToken = Utilities.generateToken(
        deviceId,
        'hcportal_getUsageData',
        paramString: deviceSecret,
      );

      final body = <String, String>{
        'queryType': 'getUsageData',
        'deviceId': deviceId,
        'accessToken': accessToken,
      };

      final jsonString = await ServiceCommon.sendHttpPostToHC6Api(body);
      if (jsonString.startsWith(ERROR_PREFIX)) return;

      final outer = json.decode(jsonString) as List<dynamic>;
      hcVersions.value = _parseList(outer[0] as List<dynamic>, UdHcVersion.fromJson);
      _calculateMaxHcVersion();

      integrationMonitor.value =
          _parseList(outer[1] as List<dynamic>, UdIntegrationMonitorModel.fromJson);
      appActivity.value = _parseList(outer[2] as List<dynamic>, UdAppActivityModel.fromJson);
      recentUsers.value = _parseList(outer[3] as List<dynamic>, UdRecentUserModel.fromJson);
      newEvents.value = _parseList(outer[4] as List<dynamic>, UdNewEventsModel.fromJson);

      // Safety net: clear any stuck loading indicators on refresh
      isUpdatingId.value = -1;
      isUpdatingDays.value = -1;
      isUpdatingVersion.value = '';
    } finally {
      _isFetching = false;
    }
  }

  List<T> _parseList<T>(
    List<dynamic> data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return data.map((e) => fromJson(e as Map<String, dynamic>)).toList();
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
      final deviceId = box.get(HIVE_DEVICE_ID) as String;
      final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';

      final accessToken = Utilities.generateToken(
        deviceId,
        'hcportal_getCategoryDetail2',
        paramString: deviceSecret,
      );

      final body = <String, String>{
        'queryType': 'getCategoryDetail2',
        'deviceId': deviceId,
        'accessToken': accessToken,
        'categoryId': categoryId.toString(),
        'days': days.toString(),
      };

      final result = await ServiceCommon.sendHttpPostToHC6Api(body);
      await _showCategoryDetailDialog(result, title);
    } catch (e) {
      if (kDebugMode) debugPrint('getCategoryDetail error: $e');
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
      final deviceId = box.get(HIVE_DEVICE_ID) as String;
      final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';

      final accessToken = Utilities.generateToken(
        deviceId,
        'hcportal_getCategoryDetail2',
        paramString: deviceSecret,
      );

      final body = <String, String>{
        'queryType': 'getCategoryDetail2',
        'deviceId': deviceId,
        'accessToken': accessToken,
        'categoryId': '100',
        'days': '14',
        'hcVersion': version,
        'hcBuild': buildNumber,
      };

      final result = await ServiceCommon.sendHttpPostToHC6Api(body);
      await _showCategoryDetailDialog(result, title);
    } catch (e) {
      if (kDebugMode) debugPrint('getHcVersionDetail error: $e');
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

    // HC6 format: [[{row1}, {row2}, ...]] — single rowset of typed columns
    final dataSet = outer[0] as List<dynamic>;
    if (dataSet.isEmpty) return;

    final firstRow = dataSet.first as Map<String, dynamic>;
    final headers = firstRow.keys.toList();

    final rows = <List<String>>[];
    for (final item in dataSet) {
      final map = item as Map<String, dynamic>;
      rows.add(headers.map((h) => _formatValue(h, map[h])).toList());
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

  String _formatValue(String columnName, dynamic value) {
    if (value == null) return '';
    final n = columnName.toLowerCase();
    final isDateCol = n.endsWith('at') ||
        n.endsWith('date') ||
        n.endsWith('datetime') ||
        n == 'timestamp';
    if (isDateCol) {
      try {
        final dt = DateTime.parse(value.toString()).toLocal();
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
        if (diff.inHours < 24) return '${diff.inHours}h ago';
        return '${diff.inDays}d ago';
      } catch (_) {}
    }
    return value.toString();
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
    } catch (e) {
      if (kDebugMode) debugPrint('getLoginHistory error: $e');
      return <UdLoginHistoryModel>[];
    }
  }
}
