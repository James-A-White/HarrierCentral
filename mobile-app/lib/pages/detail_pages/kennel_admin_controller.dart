import 'package:geolocator/geolocator.dart';
import 'package:harrier_central/imports.dart';

class KennelAdminController extends GetxController {
  KennelAdminController({required this.kennelAggregateItem});

  final KennelListAggregate kennelAggregateItem;

  // ---------------------------------------------------------------------------
  // Observable state
  // ---------------------------------------------------------------------------
  final RxBool isLoading = true.obs;
  final RxBool showShareQrs = false.obs;
  final RxList<RunDetailsAggregate> allRuns = <RunDetailsAggregate>[].obs;
  final Rx<List<String>?> mismanagement = Rx<List<String>?>(null);
  final RxBool saveUserMapPreference = false.obs;

  // ---------------------------------------------------------------------------
  // Non-reactive state owned by controller
  // ---------------------------------------------------------------------------
  final MapController mapController = MapController();

  String nextRunUrlForQr = '';
  String kennelUrlForQr = '';
  String runUrlForCopy = '';

  StreamSubscription<DataChangeEvent>? _dataChangeSub;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  @override
  void onInit() {
    super.onInit();

    _parseMismanagement(kennelAggregateItem.kennel.kennelMismanagementTeam);

    nextRunUrlForQr =
        '$BASE_HASHRUNS_DOT_ORG_URL${kennelAggregateItem.kennel.kennelUniqueShortName}/nextrun';
    kennelUrlForQr =
        '$BASE_HASHRUNS_DOT_ORG_URL${kennelAggregateItem.kennel.kennelUniqueShortName}';

    _dataChangeSub = Get.find<DataChangeService>().stream.listen(_onDataChange);

    unawaited(_syncAndLoad());
  }

  @override
  void onClose() {
    _dataChangeSub?.cancel();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------
  void _parseMismanagement(String? raw) {
    final String? trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      mismanagement.value = null;
      return;
    }
    mismanagement.value = trimmed.contains('\r')
        ? trimmed.split('\r')
        : trimmed.split('\n');
  }

  Future<void> _syncAndLoad() async {
    await _ensureFollowingForAdmin();
    await tableModel.syncKennelAdminService.updateFromBackend(
      EnumDataTables.kennels.flag |
          EnumDataTables.hashers.flag |
          EnumDataTables.hasherKennelMap.flag |
          EnumDataTables.hasherEventMap.flag |
          EnumDataTables.payments.flag,
      false,
      kennelAggregateItem.kennel.kennelId,
    );
    await refreshFromTable(true);
    isLoading.value = false;
  }

  // Admin screens require full event history for the kennel. If the user is not
  // already following this kennel, auto-follow and force-replicate all events so
  // common_events is complete before any admin query runs.
  Future<void> _ensureFollowingForAdmin() async {
    final String userId = getStringPref(StringPrefsEnum.userId) ?? '';
    if (userId.isEmpty) return;

    final String kennelId = kennelAggregateItem.kennel.kennelId;

    final List<Map<String, dynamic>> rows = await database.rawQuery('''
      SELECT ${tableModel.hasherKennelMapTableHelper.colFollowing}
      FROM ${EnumDataTables.hasherKennelMap.commonTableName}
      WHERE lower(${tableModel.hasherKennelMapTableHelper.colUserId}) = "${normalizeUuid(userId)}"
      AND lower(${tableModel.hasherKennelMapTableHelper.colKennelId}) = "${normalizeUuid(kennelId)}"
      LIMIT 1
    ''');

    final int following = rows.isNotEmpty
        ? (rows[0][tableModel.hasherKennelMapTableHelper.colFollowing]
                  as int? ??
              0)
        : 0;

    if (following == 1) return;

    await HasherKennelMapService().updateHasherKennelStatus(
      kennelId,
      AppDomainType.user,
      followingState: followTypeFollow.value,
    );

    await database.rawDelete(
      'DELETE FROM ${EnumDataTables.events.commonTableName} '
      'WHERE lower(${tableModel.eventsTableHelper.colKennelId}) = "${normalizeUuid(kennelId)}"',
    );

    await tableModel.syncUserDataService.updateFromBackend(
      EnumDataTables.events.flag,
      true,
      forceReplicateAllRunsForKennel: kennelId,
      debugText:
          'kennel_admin_controller: auto-follow + force-replicate for admin',
    );
  }

  void _onDataChange(DataChangeEvent event) {
    if (event.type == DataChangeType.runUpdated ||
        event.type == DataChangeType.runCreated) {
      unawaited(refreshFromTable(true));
    }
  }

  // ---------------------------------------------------------------------------
  // Public methods
  // ---------------------------------------------------------------------------
  Future<void> refreshFromTable(bool forceRefresh) async {
    if (forceRefresh || allRuns.isEmpty) {
      final List<Map<String, dynamic>> results = await QueryRuns.queryRuns(
        EnumRunQueryType.kennelDetailPage,
        EnumRunQueryContext.kennelAdmin,
        kennelId: kennelAggregateItem.kennel.kennelId,
        runsTimeScope: RunsTimeScope.future,
        runsToDisplay: RunsToDisplay.allRuns,
      );

      final List<RunDetailsAggregate> newRuns = <RunDetailsAggregate>[];
      for (int i = 0; i < results.length; i++) {
        double? dist;
        if ((results[i]['evtLat'] != null) &&
            (results[i]['evtLon'] != null) &&
            deviceInfo.deviceLat != null &&
            deviceInfo.deviceLon != null) {
          dist = Geolocator.distanceBetween(
            deviceInfo.deviceLat!,
            deviceInfo.deviceLon!,
            results[i]['evtLat'] as double,
            results[i]['evtLon'] as double,
          );
        }

        final EventModel eventItem = tableModel.eventsTableHelper.fromMap(
          results[i],
        );
        final KennelsModel kennelItem = tableModel.kennelsTableHelper.fromMap(
          results[i],
        );
        final RunQueryExtensionsModel extensionsItem =
            RunQueryExtensionsModel.fromJsonWithDateSearchText(
              results[i],
              eventItem.eventStartDatetime,
              dist,
            );

        String paymentLinkUrl = '';
        if (((eventItem.eventPaymentUrl ?? '') != '') &&
            ((eventItem.eventPaymentUrlExpires == null) ||
                (eventItem.eventPaymentUrlExpires!.isAfter(DateTime.now())))) {
          paymentLinkUrl = eventItem.eventPaymentUrl!;
        } else if (((kennelItem.kennelPaymentUrl ?? '') != '') &&
            ((kennelItem.kennelPaymentUrlExpires == null) ||
                (kennelItem.kennelPaymentUrlExpires!.isAfter(
                  DateTime.now(),
                )))) {
          paymentLinkUrl = kennelItem.kennelPaymentUrl!;
        }

        newRuns.add(
          RunDetailsAggregate(
            event: eventItem,
            kennel: kennelItem,
            extensions: extensionsItem,
            paymentUrl: paymentLinkUrl,
          ),
        );
      }
      allRuns.value = newRuns;
    }
  }

  /// Re-parse mismanagement after returning from the manage-members page.
  Future<void> refreshMismanagement() async {
    final KennelListAggregate? kennelAggregate =
        await QueryKennels.getSingleKennel(kennelAggregateItem.kennel.kennelId);
    _parseMismanagement(kennelAggregate?.kennel.kennelMismanagementTeam);
  }
}
