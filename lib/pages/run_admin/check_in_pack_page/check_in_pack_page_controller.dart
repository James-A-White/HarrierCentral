import 'package:harrier_central/imports.dart';

enum CheckInFilter { member, coming, atHash, paid, onIn, drink }

enum FilterOptions {
  hashersNotHereYet,
  hashersStillOnTrail,
  hashersNotPaid,
  visitors,
  virgins,
  clearAllFilters,
  cancel,
}

class CheckInPackController extends GetxController
    with GetTickerProviderStateMixin {
  final RunAdminAggregate eventAggregate;
  CheckInPackController(this.eventAggregate);

  final GlobalKey packListBoxKey = GlobalKey();

  bool isLoading = true;
  final RxList<CheckInPackModel> packList = <CheckInPackModel>[].obs;
  final RxList<CheckInPackModel> filteredList = <CheckInPackModel>[].obs;
  final RxList<CheckInPackModel> allHashers = <CheckInPackModel>[].obs;

  final RxString searchText = ''.obs;
  final RxInt countAtHash = 0.obs;
  final RxInt countComing = 0.obs;
  final RxInt countPaid = 0.obs;
  final RxInt countOnIn = 0.obs;
  final RxInt memberCount = 0.obs;
  final RxInt drinkCount = 0.obs;

  final RxnInt rsvpIndexUpdating = RxnInt();
  final RxnInt attendanceIndexUpdating = RxnInt();
  final RxnInt paymentIndexUpdating = RxnInt();

  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  late AnimationController animationController;
  late Animation<double> buttonAnimation;
  late Animation<Offset> filterPanelAnimation;
  late Animation<RelativeRect> hasherListAnimation;
  final ScrollController scrollController = ScrollController(
    initialScrollOffset: 0,
  );

  final RxString searchTypeText = ''.obs;
  final RxBool showFilter = false.obs;
  final RxBool highlightSearchType = false.obs;
  final RxBool showMultiSelect = false.obs;
  final RxBool forceShowAllHashers = false.obs;

  final Map<String, RxBool> multiSelectValues = {};

  static const String searchKennel = 'Searching Kennel members and RSVPs';
  static const String searchAllHashers = 'Searching all Hashers';

  List<RxInt> filterValues = List.generate(7, (_) => 0.obs);

  @override
  void onInit() {
    super.onInit();
    animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    buttonAnimation = Tween<double>(
      begin: 0,
      end: 90.0 / 360.0,
    ).animate(animationController);
    filterPanelAnimation = Tween<Offset>(
      begin: const Offset(0, -.35),
      end: const Offset(0, .71),
    ).animate(animationController);
    hasherListAnimation = RelativeRectTween(
      begin: const RelativeRect.fromLTRB(0, 86, 0, 0),
      end: const RelativeRect.fromLTRB(0, 204, 0, 0),
    ).animate(animationController);

    searchTypeText.value = searchKennel;

    _getAllHashers().then((_) {
      refreshSqlTablesFromBackend(true);
    });
  }

  Future<void> _getAllHashers() async {
    allHashers.clear();

    final offsetFromGmtToLocal = Utilities.getSqfliteTimeOffset();

    try {
      final String sql =
          '''
      SELECT 
          h.${tableModel.hashersTableHelper.colHasherId} AS hasherId,
          hem.${tableModel.hasherEventMapTableHelper.colHemId} AS hemId,
          CASE 
              WHEN (julianday(COALESCE(hkm.${tableModel.hasherKennelMapTableHelper.colMembershipExpirationDate},'1/1/2020')) >= julianday('now', '$offsetFromGmtToLocal')) 
              THEN 1 
              ELSE 0 
          END AS isMember,
          COALESCE(hkm.${tableModel.hasherKennelMapTableHelper.colFollowing},0) AS isFollowing,
          COALESCE(hem.${tableModel.hasherEventMapTableHelper.colIsHare}, 0) AS isHare,
          CASE 
              WHEN pay.${tableModel.paymentsTableHelper.colHemId} IS NULL 
              THEN NULL
              ELSE 1 
          END AS isPaid, 
          COALESCE(hkm.${tableModel.hasherKennelMapTableHelper.colKennelHashName}, 
          COALESCE(h.${tableModel.hashersTableHelper.colDispName}, 
                  h.${tableModel.hashersTableHelper.colHashName}, 
                  COALESCE(h.${tableModel.hashersTableHelper.colFirstName}, '') || ' ' || 
                  COALESCE(h.${tableModel.hashersTableHelper.colLastName}, ''))) AS nameForDisplay,
         COALESCE(h.${tableModel.hashersTableHelper.colFirstName}, '') as firstName,
         COALESCE(h.${tableModel.hashersTableHelper.colLastName}, '') as lastName,
         
          LOWER(COALESCE(' ' || hkm.${tableModel.hasherKennelMapTableHelper.colKennelHashName} || ' ', 
              ' ' || COALESCE(h.${tableModel.hashersTableHelper.colHashName}, '') || ' ' || 
              COALESCE(h.${tableModel.hashersTableHelper.colDispName}, '') || ' ' || 
              COALESCE(h.${tableModel.hashersTableHelper.colFirstName}, '') || ' ' || 
              COALESCE(h.${tableModel.hashersTableHelper.colLastName}, ''))) AS nameForSort,
          COALESCE(pay.${tableModel.paymentsTableHelper.colPaymentType}, 0) AS paymentType,
          COALESCE(pay.${tableModel.paymentsTableHelper.colCreditAmount}, 0) AS creditAmount,
          COALESCE(hkm.${tableModel.hasherKennelMapTableHelper.colKennelUserPhoto}, h.${tableModel.hashersTableHelper.colPhoto}) AS photo,
          0 AS virginVisitorType,
          COALESCE(hem.${tableModel.hasherEventMapTableHelper.colRsvpState}, 0) AS rsvpState,
          COALESCE(hem.${tableModel.hasherEventMapTableHelper.colTotalRunsThisKennel}, 0) AS totalRunsThisKennel,
          COALESCE(hem.${tableModel.hasherEventMapTableHelper.colTotalHaringThisKennel}, 0) AS totalHaringThisKennel,
          COALESCE(hem.${tableModel.hasherEventMapTableHelper.colAttendenceState}, 0) AS attendenceState,
          hem.${tableModel.hasherEventMapTableHelper.colUpdatedAt} AS hemUpdatedAt,
          pay.${tableModel.paymentsTableHelper.colUpdatedAt} AS payUpdatedAt,
          COALESCE(hkm.${tableModel.hasherKennelMapTableHelper.colKennelCredit},0) AS credit,
          COALESCE(hkm.${tableModel.hasherKennelMapTableHelper.colDiscountAmount}, 0) AS discountAmount,
          COALESCE(hkm.${tableModel.hasherKennelMapTableHelper.colDiscountPercent}, 0) AS discountPercent,
          COALESCE(hkm.${tableModel.hasherKennelMapTableHelper.colHcTotalRunCount}, 0) AS hcTotalRunCount,
          COALESCE(hkm.${tableModel.hasherKennelMapTableHelper.colHcHaringCount}, 0) AS hcHaringCount,
          COALESCE(hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalTotalRunCount}, 0) AS historicalTotalRunCount,
          COALESCE(hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalHaringCount}, 0) AS historicalHaringCount,
          COALESCE(hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalCountIsEstimate}, 0) AS historicalCountIsEstimate,
          ken.${tableModel.kennelsTableHelper.colKennelName} as homeKennelName
      FROM ${tableModel.hashersTableHelper.getTableName(AppDomainType.user)} h 
      LEFT OUTER JOIN ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.event)} hkm ON h.hasherId = hkm.userId
      LEFT OUTER JOIN ${tableModel.hasherEventMapTableHelper.getTableName(AppDomainType.event)} hem ON hem.userId = hkm.userId AND hem.eventId = "${eventAggregate.event.eventId}"
      LEFT OUTER JOIN ${tableModel.paymentsTableHelper.getTableName(AppDomainType.event)} pay ON pay.hemId = hem.hemId AND pay.cancelledBy IS NULL
      LEFT OUTER JOIN ${tableModel.kennelsTableHelper.getTableName(AppDomainType.user)} ken on h.${tableModel.hashersTableHelper.colHomeKennelId} = ken.${tableModel.kennelsTableHelper.colKennelId}
      WHERE h.${tableModel.hashersTableHelper.colDispName} NOT LIKE 'Placeholder user for%'
      ORDER BY nameForDisplay;
      ''';

      final List<Map<String, dynamic>> results = await database.rawQuery(sql);

      allHashers.addAll(results.map((row) => CheckInPackModel.fromMap(row)));
    } catch (e) {
      // Optionally log or handle error
      debugPrint('Error in _getAllHashers: $e');
    }
  }

  Future<void> refreshSqlTablesFromBackend(bool showLoadingIndicator) async {
    if (appModel.connectionStatus != EnumConnectionStatus2.connected) {
      return;
    }

    if (showLoadingIndicator) {
      isLoading = true;
      update(['AppScaffold']);
    }

    await tableModel.syncEventAdminService.updateFromBackend(
      SyncEventAdminService.flagHashersTable |
          SyncEventAdminService.flagPaymentsTable |
          SyncEventAdminService.flagHasherEventMapTable |
          SyncEventAdminService.flagHasherKennelMapTable,
      true,
      eventAggregate.event.eventId,
    );

    await refreshPackListFromTables(false);
    await _refreshCounters(forceRefresh: true);
  }

  Future<void> _refreshCounters({bool forceRefresh = false}) async {
    try {
      final String sql =
          '''
      SELECT 
        COUNT(CASE WHEN attendenceState >= 20 THEN 1 ELSE NULL END) as atHash,
        COUNT(CASE WHEN pay.paymentType >= 2 THEN 1 ELSE NULL END) as paid,
        COUNT(CASE WHEN rsvpState >= 2 AND attendenceState < 20 THEN 1 ELSE NULL END) as coming,
        COUNT(CASE WHEN attendenceState >= 30 THEN 1 ELSE NULL END) as onIn,
        (SELECT COUNT(*) FROM ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.event)} hkm 
         WHERE hkm.kennelId = "${eventAggregate.event.kennelId}" AND hkm.isMember = 1) as memberCount
      FROM ${tableModel.hasherEventMapTableHelper.getTableName(AppDomainType.event)} hem
      INNER JOIN ${tableModel.hashersTableHelper.getTableName(AppDomainType.user)} h 
        ON hem.${tableModel.hasherEventMapTableHelper.colUserId} = h.${tableModel.hashersTableHelper.colHasherId}
      LEFT OUTER JOIN ${tableModel.paymentsTableHelper.getTableName(AppDomainType.event)} pay 
        ON pay.hemId = hem.hemId AND pay.cancelledBy IS NULL
      WHERE h.${tableModel.hashersTableHelper.colRemoved} = 0
    ''';

      final List<Map<String, dynamic>> results = await database.rawQuery(sql);
      if (results.isNotEmpty) {
        final row = results[0];
        countAtHash.value = row['atHash'] ?? 0;
        countComing.value = row['coming'] ?? 0;
        countOnIn.value = row['onIn'] ?? 0;
        countPaid.value = row['paid'] ?? 0;
        memberCount.value = row['memberCount'] ?? 0;
      }

      // Calculate drinkCount based on packList
      final specialRunNumbers = packList.where((a) {
        final atHash = a.attendenceState >= attendenceAtHash.value;
        final specialRun =
            Utilities.checkSpecialRun(
              a.totalRunsThisKennel + a.historicalTotalRunCount,
            ) !=
            0;
        final specialHaring =
            a.isHare == 1 &&
            Utilities.checkSpecialHaring(
                  a.totalHaringThisKennel + a.historicalHaringCount,
                ) !=
                0;
        return atHash && (specialRun || specialHaring);
      }).toList();

      drinkCount.value = specialRunNumbers.length;

      if (forceRefresh) {
        isLoading = false;
        update(['AppScaffold']);
      }
    } catch (e) {
      debugPrint('Error in _refreshCounters: $e');
    }
  }

  Future<void> refreshPackListFromTables(bool forceRefresh) async {
    final offsetFromGmtToLocal = Utilities.getSqfliteTimeOffset();

    try {
      final String sql =
          '''
      SELECT 
          h.${tableModel.hashersTableHelper.colHasherId} AS hasherId,
          hem.${tableModel.hasherEventMapTableHelper.colHemId} AS hemId,
          CASE 
              WHEN (julianday(hkm.${tableModel.hasherKennelMapTableHelper.colMembershipExpirationDate}) >= julianday('now', '$offsetFromGmtToLocal')) 
              THEN 1 
              ELSE 0 
          END AS isMember,
          hkm.${tableModel.hasherKennelMapTableHelper.colFollowing} AS isFollowing,
          COALESCE(hem.${tableModel.hasherEventMapTableHelper.colIsHare}, 0) AS isHare,
          CASE 
              WHEN pay.${tableModel.paymentsTableHelper.colHemId} IS NULL 
              THEN NULL
              ELSE 1 
          END AS isPaid, 
          COALESCE(hkm.${tableModel.hasherKennelMapTableHelper.colKennelHashName}, 
              COALESCE(h.${tableModel.hashersTableHelper.colDispName}, 
                  h.${tableModel.hashersTableHelper.colHashName}, 
                  COALESCE(h.${tableModel.hashersTableHelper.colFirstName}, '') || ' ' || 
                  COALESCE(h.${tableModel.hashersTableHelper.colLastName}, ''))) AS nameForDisplay,
         COALESCE(h.${tableModel.hashersTableHelper.colFirstName}, '') as firstName,
         COALESCE(h.${tableModel.hashersTableHelper.colLastName}, '') as lastName,
         
          LOWER(COALESCE(' ' || hkm.${tableModel.hasherKennelMapTableHelper.colKennelHashName} || ' ', 
              ' ' || COALESCE(h.${tableModel.hashersTableHelper.colHashName}, '') || ' ' || 
              COALESCE(h.${tableModel.hashersTableHelper.colDispName}, '') || ' ' || 
              COALESCE(h.${tableModel.hashersTableHelper.colFirstName}, '') || ' ' || 
              COALESCE(h.${tableModel.hashersTableHelper.colLastName}, ''))) AS nameForSort,
          COALESCE(pay.${tableModel.paymentsTableHelper.colPaymentType}, 0) AS paymentType,
          COALESCE(pay.${tableModel.paymentsTableHelper.colCreditAmount}, 0) AS creditAmount,
          COALESCE(hkm.${tableModel.hasherKennelMapTableHelper.colKennelUserPhoto}, h.${tableModel.hashersTableHelper.colPhoto}) AS photo,
          0 AS virginVisitorType,
          COALESCE(hem.${tableModel.hasherEventMapTableHelper.colRsvpState}, 0) AS rsvpState,
          COALESCE(hem.${tableModel.hasherEventMapTableHelper.colTotalRunsThisKennel}, 0) AS totalRunsThisKennel,
          COALESCE(hem.${tableModel.hasherEventMapTableHelper.colTotalHaringThisKennel}, 0) AS totalHaringThisKennel,
          COALESCE(hem.${tableModel.hasherEventMapTableHelper.colAttendenceState}, 0) AS attendenceState,
          hem.${tableModel.hasherEventMapTableHelper.colUpdatedAt} AS hemUpdatedAt,
          pay.${tableModel.paymentsTableHelper.colUpdatedAt} AS payUpdatedAt,
          hkm.${tableModel.hasherKennelMapTableHelper.colKennelCredit} AS credit,
          COALESCE(hkm.${tableModel.hasherKennelMapTableHelper.colDiscountAmount}, 0) AS discountAmount,
          COALESCE(hkm.${tableModel.hasherKennelMapTableHelper.colDiscountPercent}, 0) AS discountPercent,
          hkm.${tableModel.hasherKennelMapTableHelper.colHcTotalRunCount} AS hcTotalRunCount,
          hkm.${tableModel.hasherKennelMapTableHelper.colHcHaringCount} AS hcHaringCount,
          hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalTotalRunCount} AS historicalTotalRunCount,
          hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalHaringCount} AS historicalHaringCount,
          hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalCountIsEstimate} AS historicalCountIsEstimate,
          ken.${tableModel.kennelsTableHelper.colKennelName} as homeKennelName
      FROM ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.event)} hkm
      INNER JOIN ${tableModel.hashersTableHelper.getTableName(AppDomainType.user)} h ON h.hasherId = hkm.userId
      LEFT OUTER JOIN ${tableModel.hasherEventMapTableHelper.getTableName(AppDomainType.event)} hem ON hem.userId = hkm.userId AND hem.eventId = "${eventAggregate.event.eventId}"
      LEFT OUTER JOIN ${tableModel.paymentsTableHelper.getTableName(AppDomainType.event)} pay ON pay.hemId = hem.hemId AND pay.cancelledBy IS NULL
      LEFT OUTER JOIN ${tableModel.kennelsTableHelper.getTableName(AppDomainType.user)} ken on h.${tableModel.hashersTableHelper.colHomeKennelId} = ken.${tableModel.kennelsTableHelper.colKennelId}
      WHERE hkm.kennelId = "${eventAggregate.event.kennelId}" 
        AND COALESCE(hem.virginVisitorType, 0) = 0
        AND (
          hkm.isKennelFollowing = 1
          OR (
            hkm.isKennelFollowing = 0
            AND (
              julianday(hkm.membershipExpirationDate) >= julianday('now', '$offsetFromGmtToLocal')
              OR julianday(hkm.dateOfLastRun) >= julianday('now', '$offsetFromGmtToLocal', '-2 months')
            )
          )
        )

      UNION

      SELECT 
          NULL AS hasherId,
          COALESCE(hem2.hemId, "00000000-0000-0000-0000-000000000000") AS hemId,
          0 AS isMember,
          0 AS isFollowing,
          hem2.isHare AS isHare,
          CASE 
              WHEN pay2.hemId IS NULL 
              THEN NULL
              ELSE 1 
          END AS isPaid, 
          COALESCE(hem2.displayName, 
              CASE WHEN hem2.virginVisitorType = 3 THEN h2.dispName ELSE "<no name>" END) || 
              CASE WHEN hem2.virginVisitorType = 1 THEN " (virgin)" ELSE " (visitor)" END AS nameForDisplay,
          COALESCE(h2.firstName, '') as firstName,
          COALESCE(h2.lastName, '') as lastName,
          LOWER(COALESCE(hem2.displayName, 
              CASE WHEN hem2.virginVisitorType = 3 THEN ' ' || COALESCE(h2.dispName, h2.hashName, COALESCE(h2.firstName, '') || ' ' || COALESCE(h2.lastName, '')) || ' ' 
              ELSE "<no name>" END) || 
              CASE WHEN hem2.virginVisitorType = 1 THEN " (virgin)" ELSE " (visitor)" END) AS nameForSort,
          COALESCE(pay2.paymentType, 0) AS paymentType,
          COALESCE(pay2.creditAmount, 0) AS creditAmount,
          CASE 
              WHEN hem2.virginVisitorType = 1 
              THEN "https://harriercentral.blob.core.windows.net/harrier/Virgin.png" 
              ELSE "https://harriercentral.blob.core.windows.net/harrier/Visitor.png" 
          END AS photo,
          COALESCE(hem2.virginVisitorType, 1) AS virginVisitorType,
          COALESCE(hem2.rsvpState, 0) AS rsvpState,
          COALESCE(hem2.${tableModel.hasherEventMapTableHelper.colTotalRunsThisKennel}, 0) AS totalRunsThisKennel,
          COALESCE(hem2.${tableModel.hasherEventMapTableHelper.colTotalHaringThisKennel}, 0) AS totalHaringThisKennel,
          COALESCE(hem2.attendenceState, 0) AS attendenceState,
          hem2.updatedAt AS hemUpdatedAt,
          pay2.updatedAt AS payUpdatedAt,
          0 AS credit,
          0 AS ${tableModel.hasherKennelMapTableHelper.colDiscountAmount},
          0 AS ${tableModel.hasherKennelMapTableHelper.colDiscountPercent},
          NULL AS ${tableModel.hasherKennelMapTableHelper.colHcTotalRunCount},
          NULL AS ${tableModel.hasherKennelMapTableHelper.colHcHaringCount},
          NULL AS ${tableModel.hasherKennelMapTableHelper.colHistoricalTotalRunCount},
          NULL AS ${tableModel.hasherKennelMapTableHelper.colHistoricalHaringCount},
          NULL AS ${tableModel.hasherKennelMapTableHelper.colHistoricalCountIsEstimate},
          ken2.${tableModel.kennelsTableHelper.colKennelName} as homeKennelName
      FROM ${tableModel.hasherEventMapTableHelper.getTableName(AppDomainType.event)} hem2
      INNER JOIN ${tableModel.hashersTableHelper.getTableName(AppDomainType.user)} h2 ON h2.hasherId = hem2.userId
      LEFT OUTER JOIN ${tableModel.paymentsTableHelper.getTableName(AppDomainType.event)} pay2 ON pay2.hemId = hem2.hemId AND pay2.cancelledBy IS NULL
      LEFT OUTER JOIN ${tableModel.kennelsTableHelper.getTableName(AppDomainType.user)} ken2 on h2.${tableModel.hashersTableHelper.colHomeKennelId} = ken2.${tableModel.kennelsTableHelper.colKennelId}
      WHERE hem2.eventId = "${eventAggregate.event.eventId}" 
        AND hem2.virginVisitorType != 0

      UNION

      SELECT 
          hem3.userId AS hasherId,
          hem3.hemId AS hemId,
          0 AS isMember,
          hkm4.${tableModel.hasherKennelMapTableHelper.colFollowing} AS isFollowing,
          hem3.isHare AS isHare,
          CASE 
              WHEN pay3.hemId IS NULL 
              THEN NULL
              ELSE 1 
          END AS isPaid, 
          COALESCE(hkm4.${tableModel.hasherKennelMapTableHelper.colKennelHashName}, 
              COALESCE(h3.dispName, h3.hashName, COALESCE(h3.firstName, '') || ' ' || 
              COALESCE(h3.lastName, ''))) AS nameForDisplay,
          COALESCE(h3.firstName, '') as firstName,
          COALESCE(h3.lastName, '') as lastName,
    
          LOWER(COALESCE(hkm4.${tableModel.hasherKennelMapTableHelper.colKennelHashName}, 
              COALESCE(h3.dispName, h3.hashName, '') || ' ' || 
              COALESCE(h3.lastName, '') || ' ' || 
              COALESCE(h3.firstName, ''))) AS nameForSort,
          COALESCE(pay3.paymentType, 0) AS paymentType,
          COALESCE(pay3.creditAmount, 0) AS creditAmount,
          COALESCE(hkm4.${tableModel.hasherKennelMapTableHelper.colKennelUserPhoto}, h3.photo) AS photo,
          hem3.virginVisitorType AS virginVisitorType,
          COALESCE(hem3.rsvpState, 0) AS rsvpState,
          COALESCE(hem3.${tableModel.hasherEventMapTableHelper.colTotalRunsThisKennel}, 0) AS totalRunsThisKennel,
          COALESCE(hem3.${tableModel.hasherEventMapTableHelper.colTotalHaringThisKennel}, 0) AS totalHaringThisKennel,
          COALESCE(hem3.attendenceState, 0) AS attendenceState,
          hem3.updatedAt AS hemUpdatedAt,
          pay3.updatedAt AS payUpdatedAt,
          hkm4.${tableModel.hasherKennelMapTableHelper.colKennelCredit} AS credit,
          COALESCE(hkm4.${tableModel.hasherKennelMapTableHelper.colDiscountAmount}, 0) AS discountAmount,
          COALESCE(hkm4.${tableModel.hasherKennelMapTableHelper.colDiscountPercent}, 0) AS discountPercent,
          hkm4.${tableModel.hasherKennelMapTableHelper.colHcTotalRunCount},
          hkm4.${tableModel.hasherKennelMapTableHelper.colHcHaringCount},
          hkm4.${tableModel.hasherKennelMapTableHelper.colHistoricalTotalRunCount},
          hkm4.${tableModel.hasherKennelMapTableHelper.colHistoricalHaringCount},
          hkm4.${tableModel.hasherKennelMapTableHelper.colHistoricalCountIsEstimate},
          ken3.${tableModel.kennelsTableHelper.colKennelName} as homeKennelName
      FROM ${tableModel.hasherEventMapTableHelper.getTableName(AppDomainType.event)} hem3
      INNER JOIN ${tableModel.hashersTableHelper.getTableName(AppDomainType.user)} h3 ON h3.hasherId = hem3.userId
      LEFT OUTER JOIN ${tableModel.paymentsTableHelper.getTableName(AppDomainType.event)} pay3 ON pay3.hemId = hem3.hemId AND pay3.cancelledBy IS NULL
      LEFT OUTER JOIN ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.event)} hkm3 ON hkm3.userId = h3.hasherId AND hkm3.kennelId = "${eventAggregate.event.kennelId}" AND julianday(hkm3.membershipExpirationDate) >= julianday('now', '$offsetFromGmtToLocal')
      LEFT OUTER JOIN ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.event)} hkm4 ON hkm4.userId = h3.hasherId AND hkm4.kennelId = "${eventAggregate.event.kennelId}" 
      LEFT OUTER JOIN ${tableModel.kennelsTableHelper.getTableName(AppDomainType.user)} ken3 on h3.${tableModel.hashersTableHelper.colHomeKennelId} = ken3.${tableModel.kennelsTableHelper.colKennelId}
      WHERE hem3.eventId = "${eventAggregate.event.eventId}" 
        AND hem3.virginVisitorType = 0 
        AND (
          (
            hkm4.userId IS NULL
          ) OR NOT (
            hkm4.isKennelFollowing = 1
            OR (
              hkm4.isKennelFollowing = 0
              AND (
                julianday(COALESCE(hkm4.membershipExpirationDate, '2000-01-01T01:00:00.000Z')) >= julianday('now', '$offsetFromGmtToLocal') 
                OR julianday(COALESCE(hkm4.dateOfLastRun, '2000-01-01T01:00:00.000Z')) >= julianday('now', '$offsetFromGmtToLocal', '-2 months')
              )
            )
          )
        )

      ORDER BY nameForSort

          ''';

      final List<Map<String, dynamic>> results = await database.rawQuery(sql);

      if (results.isNotEmpty) {
        packList.clear();
        multiSelectValues.clear();
        for (final row in results) {
          final hasher = CheckInPackModel.fromMap(row);
          if (!hasher.nameForDisplay.toLowerCase().startsWith(
            'placeholder user',
          )) {
            packList.add(hasher);
            if (hasher.hasherId != null) {
              multiSelectValues[hasher.hasherId!] = false.obs;
            }
          }
        }
      }

      if (forceRefresh) {
        isLoading = false;
        update(['AppScaffold']);
      }

      filterPackListResults();

      if (forceShowAllHashers.value) {
        await _getAllHashers();
      }
    } catch (e) {
      debugPrint('Error refreshing pack list: $e');
    }
  }

  void filterPackListResults() {
    final String query = searchText.value.toLowerCase();
    final bool hasSearch = query.isNotEmpty;
    final bool applyFilters = showFilter.value;

    List<CheckInPackModel> results = [...packList];

    if (applyFilters) {
      results = results.where((a) {
        return ((filterValues[0].value == 0) ||
                (filterValues[0].value == -1 && a.rsvpState <= 1) ||
                (filterValues[0].value == 1 && a.rsvpState >= 2)) &&
            ((filterValues[1].value == 0) ||
                (filterValues[1].value == 1 &&
                    a.attendenceState < 20 &&
                    a.rsvpState >= 2)) &&
            ((filterValues[2].value == 0) ||
                (filterValues[2].value == -1 && a.attendenceState < 20) ||
                (filterValues[2].value == 1 && a.attendenceState >= 20)) &&
            ((filterValues[3].value == 0) ||
                (filterValues[3].value == -1 &&
                    (a.isPaid == 0 || a.isPaid == null)) ||
                (filterValues[3].value == 1 && a.isPaid == 1)) &&
            ((filterValues[4].value == 0) ||
                (filterValues[4].value == -1 && a.attendenceState < 30) ||
                (filterValues[4].value == 1 && a.attendenceState >= 30)) &&
            ((filterValues[5].value == 0) ||
                (filterValues[5].value == -1 && a.isMember == 0) ||
                (filterValues[5].value == 1 && a.isMember == 1)) &&
            ((filterValues[6].value == 0) ||
                (filterValues[6].value == -1) ||
                (filterValues[6].value == 1 &&
                    a.attendenceState >= attendenceAtHash.value &&
                    (Utilities.checkSpecialRun(
                              a.totalRunsThisKennel + a.historicalTotalRunCount,
                            ) !=
                            0 ||
                        (a.isHare == 1 &&
                            Utilities.checkSpecialHaring(
                                  a.totalHaringThisKennel +
                                      a.historicalHaringCount,
                                ) !=
                                0))));
      }).toList();
    }

    if (hasSearch || forceShowAllHashers.value) {
      final List<CheckInPackModel> filteredByName = results
          .where((a) => a.nameForSort.toLowerCase().contains(query))
          .toList();

      if ((filteredByName.isNotEmpty) && (!forceShowAllHashers.value)) {
        filteredList.assignAll(filteredByName);
        searchTypeText.value = searchKennel;
      } else {
        final fallback = allHashers
            .where((a) => a.nameForSort.toLowerCase().contains(query))
            .toList();
        filteredList.assignAll(fallback);
        searchTypeText.value = searchAllHashers;
      }

      highlightSearchType.value = true;
      Future.delayed(const Duration(milliseconds: 1500)).then((_) {
        highlightSearchType.value = false;
      });
    } else {
      searchTypeText.value = searchKennel;
      filteredList.assignAll(results);
    }

    update(['hasherList']);
  }

  void toggleFilterPanel() {
    if (showFilter.value) {
      animationController.reverse();
    } else {
      animationController.forward();
    }
    showFilter.toggle();
    refreshPackListFromTables(true);
  }

  void clearSearch() {
    searchController.clear();
    searchText.value = '';
    forceShowAllHashers.value = false;
    refreshPackListFromTables(true);
  }

  void onSearchChanged(String value) {
    searchText.value = value;
    filterPackListResults();
  }

  void onHasherTapped(BuildContext context, int index) async {
    final CheckInPackModel hasher = filteredList[index];
    searchFocusNode.unfocus();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (eventAggregate.extensions.appAccess.canManageRuns) {
      final double baseAmount = hasher.isMember != 1
          ? eventAggregate.extensions.nonMemberPrice
          : eventAggregate.extensions.memberPrice;

      double amountOwed = baseAmount - hasher.discountAmount;
      amountOwed -= amountOwed * (hasher.discountPercent / 100.0);

      final snackbar = PaymentSnackBar(
        context: context,
        eventAggregate: eventAggregate,
        packMember: hasher,
        amountOwed: amountOwed,
        multiSelectEnabled: showMultiSelect.value,
        onRsvpCallback:
            (
              updated, {
              rsvpState = -1,
              attendenceState = -1,
              isHare = -1,
            }) async {
              ScaffoldMessenger.of(
                context,
              ).removeCurrentSnackBar(reason: SnackBarClosedReason.hide);
              if (rsvpState != -1 && attendenceState == -1) {
                rsvpIndexUpdating.value = index;
                await updateRsvpState(updated, rsvpState, isHare);
                rsvpIndexUpdating.value = null;
              } else if (attendenceState != -1) {
                attendanceIndexUpdating.value = index;
                await updateAttendenceState(
                  updated,
                  rsvpState,
                  attendenceState,
                  isHare,
                );
                attendanceIndexUpdating.value = null;
              }
              await refreshPackListFromTables(false);
              await _refreshCounters(forceRefresh: true);
            },
        onPaidCallback: (updated, paymentType, {userInput}) async {
          ScaffoldMessenger.of(
            context,
          ).removeCurrentSnackBar(reason: SnackBarClosedReason.hide);
          paymentIndexUpdating.value = index;

          if (showMultiSelect.value) {
            await bulkPayForEvent(context, paymentType);
          } else {
            await payForEvent(
              context,
              paymentType,
              index,
              userInput?.totalAmount,
              specialRunPrice: userInput?.specialPriceAmount,
              specialRunPriceReason: userInput?.specialPriceReason,
              useSpecialPriceAsDefault: userInput?.useSpecialPriceAsDefault,
            );
          }

          paymentIndexUpdating.value = null;

          // await refreshPackListFromTables(false);
          // await _refreshCounters(forceRefresh: true);
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(snackbar);
    }
  }

  Future<void> bulkPayForEvent(BuildContext context, int paymentType) async {
    ScaffoldMessenger.of(
      context,
    ).removeCurrentSnackBar(reason: SnackBarClosedReason.hide);

    await _processBulkPayment(paymentType);

    paymentIndexUpdating.value = null;
    rsvpIndexUpdating.value = null;
    attendanceIndexUpdating.value = null;
    await refreshPackListFromTables(false);
    await _refreshCounters(forceRefresh: true);
  }

  Future<void> payForEvent(
    BuildContext context,
    int paymentType,
    int index,
    double? otherAmount, {
    double? specialRunPrice,
    String? specialRunPriceReason,
    bool? useSpecialPriceAsDefault,
  }) async {
    ScaffoldMessenger.of(
      context,
    ).removeCurrentSnackBar(reason: SnackBarClosedReason.hide);
    dynamic payForExtras = payForRunOnly;

    if (((paymentType == paymentFreeRun.value) ||
            (paymentType == paymentCash.value) ||
            (paymentType == paymentBankTransfer.value) ||
            (paymentType == paymentCashOtherAmount.value) ||
            (paymentType == paymentHashCredit.value) ||
            (paymentType == paymentBankTransferOtherAmount.value)) &&
        ((eventAggregate.event.eventPriceForExtras ?? 0) != 0)) {
      final double runOnlyPrice =
          specialRunPrice ??
          (filteredList[index].isMember != 0
              ? eventAggregate.extensions.memberPrice
              : eventAggregate.extensions.nonMemberPrice);
      final double runPlusExtrasPrice =
          runOnlyPrice + (eventAggregate.event.eventPriceForExtras!);

      final String runOnlyPriceStr = IveCoreUtilities.getFormattedMoney(
        runOnlyPrice,
        eventAggregate.extensions.digAfterDec,
        eventAggregate.extensions.curSym,
      );
      final String runPlusExtrasPriceStr = IveCoreUtilities.getFormattedMoney(
        runPlusExtrasPrice,
        eventAggregate.extensions.digAfterDec,
        eventAggregate.extensions.curSym,
      );

      final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
        <String, dynamic>{
          'title': 'Run only ($runOnlyPriceStr)',
          'icon': <Widget>[Container()],
          'returnValue': payForRunOnly,
        },
        <String, dynamic>{
          'title':
              'Run + ${eventAggregate.event.extrasDescription} ($runPlusExtrasPriceStr)',
          'icon': <Widget>[Container()],
          'returnValue': payForRunAndExtras,
        },
      ];

      final MultipleChoicePopupHc popup = MultipleChoicePopupHc(
        key: const Key('4555116132'),
        title: 'Payment options',
        buttons: buttons,
        cancelButtonTitle: 'Cancel',
        cancelButtonReturnValue: followTypeCancel,
      );

      payForExtras = await showDialog<dynamic>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return popup;
        },
      );
    }
    final List<dynamic>? results = await _processPayment(
      index,
      paymentType,
      otherAmount: otherAmount,
      doPayForExtras: payForExtras,
      specialRunPrice: specialRunPrice,
      specialRunPriceReason: specialRunPriceReason,
      useSpecialPriceAsDefault: useSpecialPriceAsDefault,
    );
    if (results != null) {
      if ((results[0]['terminalWasUsedForPayment'] == null) ||
          (!results[0]['terminalWasUsedForPayment'])) {
        BankTransferQr.showBankTransferSnackbar(
          eventAggregate,
          results,
          paymentType,
          navigatorKey.currentContext!,
          filteredList[index].nameForDisplay,
          filteredList[index].isMember,
          otherAmount,
        );
      }
    }

    paymentIndexUpdating.value = null;
    rsvpIndexUpdating.value = null;
    attendanceIndexUpdating.value = null;
    await refreshPackListFromTables(false);
    await _refreshCounters(forceRefresh: true);
  }

  Future<List<dynamic>?> _processBulkPayment(int paymentType) async {
    final String selectedHasherIds = multiSelectValues.entries
        .where((entry) => entry.value.value)
        .map((entry) => entry.key)
        .join(',');

    final PaymentsService paySrv = PaymentsService();
    final List<dynamic> result = await paySrv.bulkPayForEvent(
      eventAggregate.event.eventId,
      selectedHasherIds,
      paymentType,
    );

    return result;
  }

  Future<List<dynamic>?> _processPayment(
    int index,
    int paymentType, {
    double? otherAmount = -1,
    EnumPayForExtras doPayForExtras = payForRunOnly,
    double? specialRunPrice,
    String? specialRunPriceReason,
    bool? useSpecialPriceAsDefault = false,
  }) async {
    //bool paymentCancelled = false;
    bool terminalWasUsedForPayment = false;

    rsvpIndexUpdating.value = index;
    attendanceIndexUpdating.value = index;

    // filteredList[index] = filteredList[index].copyWith(
    //   rsvpStateIndicator: Future<int>.value(rsvpUpdating.value),
    //   attendenceStateIndicator: Future<int>.value(attendenceUpdating.value),
    //   paidStateIndicator: Future<int>.value(isPaidUpdating.value),
    // );

    final String? hemId = filteredList[index].hemId;
    final String? hasherId = filteredList[index].hasherId;
    double amount = filteredList[index].isMember != 0
        ? eventAggregate.extensions.memberPrice
        : eventAggregate.extensions.nonMemberPrice;
    if ((otherAmount != null) && (otherAmount != -1)) {
      amount = otherAmount;
    }

    final Random random = Random.secure();
    final List<int> values = List<int>.generate(
      6,
      (int i) => random.nextInt(26),
    );
    final String randomString = String.fromCharCodes(
      Iterable<int>.generate(values.length, (int i) => values[i] + 65),
    );

    String paymentReference = '';

    paymentReference = 'HC:$randomString';

    final PaymentsService paySrv = PaymentsService();
    final List<dynamic> result = await paySrv.payForEvent(
      eventAggregate.event.eventId,
      ((hasherId?.length != GUID_EMPTY.length)) ? GUID_EMPTY : hasherId,
      (((hemId?.length ?? 0) != GUID_EMPTY.length)) ? GUID_EMPTY : hemId,
      paymentType,
      amount,
      attendenceAtHash.value,
      doPayForExtras,
      AppDomainType.event,
      paymentReference: paymentReference,
      specialRunPrice: specialRunPrice,
      specialRunPriceReason: specialRunPriceReason,
      useSpecialPriceAsDefault: useSpecialPriceAsDefault,
    );

    if (result.isNotEmpty) {
      final Map<String, dynamic> m = result[0];
      m.addAll(<String, dynamic>{
        'terminalWasUsedForPayment': terminalWasUsedForPayment,
      });
    }

    return result;
  }

  Future<void> updateAttendenceState(
    CheckInPackModel packMember,
    int rsvpState,
    int attendenceState,
    int isHare,
  ) async {
    if (showMultiSelect.value) {
      final String selectedHasherIds = multiSelectValues.entries
          .where((entry) => entry.value.value)
          .map((entry) => entry.key)
          .join(',');

      await tableModel.hasherEventMapService.setBulkEventAttendence(
        eventAggregate.event.eventId,
        selectedHasherIds,
        attendenceState,
      );
    } else {
      await tableModel.hasherEventMapService.setEventAttendence(
        eventAggregate.event.eventId,
        packMember.hasherId,
        AppDomainType.event,
        attendenceState,
        hemId: packMember.hemId,
      );
    }

    await refreshPackListFromTables(false);
    await _refreshCounters(forceRefresh: true);
  }

  Future<void> updateRsvpState(
    CheckInPackModel packMember,
    int rsvpState,
    int isHare,
  ) async {
    final String? hasherId = packMember.hasherId;

    if (kDebugMode) {
      print('rsvpState = $rsvpState');
    }

    final List<dynamic> adHocData = await tableModel.hasherEventMapService
        .setEventRsvp(
          eventAggregate.event.eventId,
          hasherId,
          AppDomainType.event,
          rsvpState,
          isHare: isHare,
          hemId: packMember.hemId,
        );

    final String serverMessage = adHocData[0]['serverMessage'] ?? '';

    if (serverMessage.isNotEmpty) {
      await Utilities.showAlert('RSVP Result', serverMessage, 'OK');
    }

    await refreshPackListFromTables(false);

    await _refreshCounters(forceRefresh: true);
  }

  TextStyle getRunLabelStyle(CheckInPackModel hasher) {
    final int totalRuns =
        hasher.totalRunsThisKennel + hasher.historicalTotalRunCount;

    if (totalRuns == 0) {
      return ts_footnoteSmall;
    } else if (totalRuns < 10) {
      return ts_footnoteSmall.copyWith(color: Colors.grey);
    } else if (totalRuns < 50) {
      return ts_footnoteSmall.copyWith(color: Colors.orange);
    } else if (totalRuns < 100) {
      return ts_footnoteSmall.copyWith(color: Colors.green);
    } else {
      return ts_footnoteSmall.copyWith(color: Colors.blue);
    }
  }

  bool shouldHighlightHasher(CheckInPackModel hasher) {
    var doHighlightRow =
        ((eventAggregate.event.isCountedRun == 1) &&
        (hasher.attendenceState >= attendenceAtHash.value) &&
        ((Utilities.checkSpecialRun(
                  (hasher.totalRunsThisKennel) +
                      (hasher.historicalTotalRunCount),
                ) !=
                specialRunNo) ||
            ((hasher.isHare == 1) &&
                (Utilities.checkSpecialRun(
                      (hasher.totalHaringThisKennel) +
                          (hasher.historicalHaringCount),
                    ) !=
                    specialRunNo))));

    return doHighlightRow;
  }

  TextStyle getHaringLabelStyle(CheckInPackModel hasher) {
    final int totalHared =
        hasher.totalHaringThisKennel + hasher.historicalHaringCount;

    if (totalHared == 0) {
      return ts_footnoteSmall;
    } else if (totalHared < 5) {
      return ts_footnoteSmall.copyWith(color: Colors.brown);
    } else if (totalHared < 15) {
      return ts_footnoteSmall.copyWith(color: Colors.deepOrange);
    } else if (totalHared < 30) {
      return ts_footnoteSmall.copyWith(color: Colors.teal);
    } else {
      return ts_footnoteSmall.copyWith(color: Colors.purple);
    }
  }

  bool shouldShowDrinkIcon(CheckInPackModel hasher) {
    bool showDrinkIcon = false;

    // print(
    //   '${hasher.nameForDisplay} - ${hasher.totalRunsThisKennel + hasher.historicalTotalRunCount} + ${hasher.totalHaringThisKennel + hasher.historicalHaringCount}',
    // );

    // print(
    //   hasher.nameForDisplay +
    //       ' - ' +
    //       (hasher.totalRunsThisKennel + hasher.historicalTotalRunCount)
    //           .toString(),
    // );

    if (hasher.attendenceState >= attendenceAtHash.value) {
      showDrinkIcon =
          Utilities.checkSpecialRun(
            hasher.totalRunsThisKennel + hasher.historicalTotalRunCount,
          ) !=
          specialRunNo;
      if (!showDrinkIcon && (hasher.isHare == 1)) {
        showDrinkIcon =
            Utilities.checkSpecialHaring(
              hasher.totalHaringThisKennel + hasher.historicalHaringCount,
            ) !=
            specialRunNo;
      }
    }

    return showDrinkIcon;
  }

  Widget buildAttendanceIcon(
    int index,
    int? rsvpState,
    int? attendanceState,
    CheckInPackModel hasher,
  ) {
    return Obx(
      () => Stack(
        alignment: AlignmentDirectional.center,
        children: <Widget>[
          Container(height: 30, width: 30, color: Colors.transparent),
          CircleAvatar(
            backgroundColor:
                // (attendanceState == null ||
                //         attendanceState == attendenceUnknown.value ||
                //         rsvpState == rsvpNo.value)
                //     ? (attendanceIndexUpdating.value == null
                //         ? Colors.grey[350]
                //         : Colors.white)
                //     : Colors.white,
                ((attendanceState == null) ||
                    (attendanceState == attendenceUnknown.value) ||
                    (rsvpState == rsvpNo.value))
                ? attendanceIndexUpdating.value != index
                      ? Colors.grey[350]
                      : Colors.white
                : Colors.white,
            radius: 14.0,
          ),
          index == attendanceIndexUpdating.value
              ? Icon(delayIcon, color: hc_blue)
              : ((attendanceState == attendenceUnknown.value) ||
                    (rsvpState == rsvpNo.value))
              ? Container()
              : attendanceState == attendenceNo.value
              ? Image.asset(
                  'images/icons/not_at_hash_icon.png',
                  height: 24.0,
                  width: 24.0,
                  color: hc_red,
                )
              : attendanceState == attendenceAtHash.value
              ? Image.asset(
                  'images/icons/runner_icon.png',
                  height: 24.0,
                  width: 24.0,
                  color: Colors.orange,
                )
              : attendanceState! >= attendenceOnIn.value
              ? Image.asset(
                  'images/icons/beer_icon.png',
                  height: 24.0,
                  width: 24.0,
                  color: Colors.green,
                )
              : Container(),
        ],
      ),
    );
  }

  Widget buildPaymentIcon(
    int index,
    int attendenceState,
    int? isPaid,
    int paymentType,
    CheckInPackModel hasher,
  ) {
    if (attendenceState >= attendenceAtHash.value) {
      // if the Hasher has checked in but not paid,
      // go ahead and change the indicator value to show
      // they are not paid.
      isPaid ??= 0;
    } else {
      isPaid = null;
    }
    return Obx(
      () => Stack(
        alignment: AlignmentDirectional.center,
        children: <Widget>[
          Container(height: 30, width: 30, color: Colors.transparent),
          CircleAvatar(
            backgroundColor: paymentIndexUpdating.value == index
                ? Colors.white
                : ((isPaid == null))
                ? Colors.grey[350]
                : Colors.white,
            radius: 14.0,
          ),
          index == paymentIndexUpdating.value
              ? Icon(delayIcon, color: hc_blue)
              : (isPaid == null)
              ? Container()
              : isPaid == isPaidNo.value
              ? Image.asset(
                  'images/icons/dollar_sign_icon.png',
                  height: 24.0,
                  width: 24.0,
                  color: hc_red,
                )
              : isPaid == isPaidYes.value
              ? Image.asset(
                  'images/icons/payment_type_$paymentType.png',
                  height: 24.0,
                  width: 24.0,
                  color: Colors.green,
                )
              : Container(),
        ],
      ),
    );
  }

  Widget buildRsvpIcon(
    int index,
    int? rsvpState,
    int? isHare,
    CheckInPackModel hasher,
  ) {
    return Obx(
      () => Stack(
        alignment: AlignmentDirectional.center,
        children: <Widget>[
          Container(height: 30, width: 30, color: Colors.transparent),
          CircleAvatar(
            backgroundColor: ((rsvpState == null) || (rsvpState == 0))
                ? Colors.grey[350]
                : Colors.white,
            radius: 14.0,
          ),
          index == rsvpIndexUpdating.value
              ? Icon(delayIcon, color: hc_blue)
              : ((rsvpState ?? 0) == 0)
              ? Container()
              : rsvpState == rsvpNo.value
              ? Icon(FontAwesome.times_circle, color: hc_red, size: 27.0)
              : rsvpState == rsvpMaybe.value
              ? const Icon(
                  FontAwesome.question_circle,
                  color: Colors.orange,
                  size: 27.0,
                )
              : (isHare ?? 0) == 0
              ? const Icon(
                  FontAwesome.check_circle,
                  color: Colors.green,
                  size: 27.0,
                )
              : Image.asset(
                  'images/icons/hare_icon.png',
                  color: Colors.deepPurple,
                  height: 24.0,
                  width: 24.0,
                ),
        ],
      ),
    );
  }

  Future<void> showVirginVisitorPopup(BuildContext parentContext) async {
    //int? scrollIndex = -1;

    const AddVisitorVirginPopup addVirginVisitorPopup = AddVisitorVirginPopup();

    final Map<String, String>? x = await showDialog<Map<String, String>>(
      context: parentContext,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return addVirginVisitorPopup;
      },
    );

    if (x != null) {
      final String name = x['name'] ?? '';
      final String type = x['type'] ?? '';
      final String email = x['email'] ?? '';
      final String phoneNumber = x['phone'] ?? '';

      EnumVirginVisitor evv = enumVirgin;
      if (type == enumAnonymousVisitor.value.toString()) {
        evv = enumAnonymousVisitor;
      }

      if (type != 'cancel') {
        // setState(() {
        //   _isLoading = true;
        // });
        await tableModel
            //final List<dynamic> adHocData = await tableModel
            .hasherEventMapService
            .joinEventAsVisitor(
              eventAggregate.event.eventId,
              name,
              evv.value,
              attendenceUnknown.value,
              email,
              phoneNumber,
              AppDomainType.event,
            );

        await refreshPackListFromTables(false);
        _refreshCounters(forceRefresh: true);

        // setState(() {
        //   _isLoading = false;
        // });

        // if (eventAggregate.extensions.appAccess.canManageRuns) {
        //   if (adHocData.isNotEmpty) {
        //     final String hem =
        //         adHocData[0]['hasherEventMapId'].toString().toLowerCase();
        //     scrollIndex = filteredList.indexWhere(
        //       (CheckInPackModel k) =>
        //           k.hemId.toString().toLowerCase() == hem,
        //     );
        //     if ((scrollIndex ?? -1) >= 0) {
        //       //final CheckInPackModel hasher = _packList[scrollIndex!];
        //       //if (hasher != null) {
        //       if (scrollIndex != null) {
        //         final SnackBar snackBar = _buildRsvpAndPaymentSnackbar(
        //           navigatorKey.currentContext!,
        //           _ScaffoldKey.currentState!,
        //           scrollIndex!,
        //         );

        //         ScaffoldMessenger.of(
        //           navigatorKey.currentContext!,
        //         ).removeCurrentSnackBar(
        //           reason: SnackBarClosedReason.hide,
        //         );
        //         ScaffoldMessenger.of(navigatorKey.currentContext!)
        //             .showSnackBar(snackBar)
        //             .closed
        //             .then((SnackBarClosedReason reason) {
        //               setState(() {
        //                 if ((scrollIndex ?? -1) >= 0) {
        //                   if (_scrollController.hasClients) {
        //                     _scrollController.animateTo(
        //                       scrollIndex! * LIST_ITEM_HEIGHT,
        //                       duration: const Duration(seconds: 1),
        //                       curve: Curves.ease,
        //                     );
        //                   }
        //                 }
        //               });
        //             });
        //       }
        //     }
        //   }
        // }
      }
    }
    return;

    // dlg.whenComplete(action)
  }

  void copyRsvpsFromLastRun(BuildContext parentContext) async {
    var result = await QueryRuns.queryPreviousRun(
      eventAggregate.kennel.kennelId,
      eventAggregate.event.eventStartDatetime,
    );

    String lastRunName = result[0]['eventName'].toString();
    String fromEventId = result[0]['eventId'].toString();

    bool doCopyRsvps =
        await Utilities.showAlert(
          'Copy RSVPs',
          'Are you sure you want to copy all RSVPs from\r\n\r\n$lastRunName\r\n\r\nto this run?',
          'Yes',
          showCancelButton: true,
          cancelButtonText: 'No',
        ) ??
        false;

    if (doCopyRsvps) {
      final List<dynamic> adHocData = await tableModel.hasherEventMapService
          .copyEventRsvps(fromEventId, eventAggregate.event.eventId);

      final String serverMessage = adHocData[0]['serverMessage'] ?? '';

      if (serverMessage.isNotEmpty) {
        await Utilities.showAlert('RSVP Result', serverMessage, 'OK');
      }

      await refreshPackListFromTables(false);
      await _refreshCounters(forceRefresh: true);
    }
  }

  void filterOptionsPopup(BuildContext context) {
    final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
      <String, dynamic>{
        'title': 'Hashers not here yet',
        'icon': <Widget>[
          Container(
            height: 30,
            width: 30,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const Icon(FontAwesome.check_circle, color: Colors.green),
        ],
        'returnValue': FilterOptions.hashersNotHereYet,
      },
      <String, dynamic>{
        'title': 'Hashers still on trail',
        'icon': <Widget>[
          Container(
            height: 30,
            width: 30,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          Image.asset(
            'images/icons/runner_icon.png',
            height: 25,
            width: 25,
            color: Colors.orange,
          ),
        ],
        'returnValue': FilterOptions.hashersStillOnTrail,
      },
      <String, dynamic>{
        'title': 'Hashers who have not paid',
        'icon': <Widget>[
          Container(
            height: 30,
            width: 30,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          Image.asset(
            'images/icons/dollar_sign_icon.png',
            height: 25,
            width: 25,
            color: hc_red,
          ),
        ],
        'returnValue': FilterOptions.hashersNotPaid,
      },
      <String, dynamic>{
        'title': 'Visitors',
        'icon': <Widget>[
          Container(
            height: 30,
            width: 30,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const Positioned(
            bottom: 0,
            child: Icon(
              MaterialCommunityIcons.alpha_v_circle,
              size: 31,
              color: Colors.purple,
            ),
          ),
        ],
        'returnValue': FilterOptions.visitors,
      },
      <String, dynamic>{
        'title': 'Virgins',
        'icon': <Widget>[
          Container(
            height: 30,
            width: 30,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          Positioned(
            bottom: 0,
            child: Icon(
              MaterialCommunityIcons.alpha_v_circle,
              size: 31,
              color: Colors.pink[300],
            ),
          ),
        ],
        'returnValue': FilterOptions.virgins,
      },
      <String, dynamic>{
        'title': 'Clear all filters',
        'icon': <Widget>[
          Container(
            height: 30,
            width: 30,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          Icon(FontAwesome.times_circle, color: hc_red),

          // Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          // const Positioned(bottom: 0, child: Icon(Ionicons.md_remove_circle, size: 30, color: Colors.teal))
        ],
        'returnValue': FilterOptions.clearAllFilters,
      },
    ];

    final MultipleChoicePopupHc popup = MultipleChoicePopupHc(
      key: const Key('6919321235'),
      title: 'Common filter options',
      buttons: buttons,
      cancelButtonTitle: 'Cancel',
      cancelButtonReturnValue: followTypeCancel,
    );

    showDialog<dynamic>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return popup;
      },
    ).then((dynamic retVal) {
      switch (retVal) {
        case FilterOptions.hashersNotHereYet:
          filterValues = <RxInt>[
            0.obs,
            1.obs,
            0.obs,
            0.obs,
            0.obs,
            0.obs,
            0.obs,
            0.obs,
            0.obs,
            0.obs,
          ];
          searchText.value = '';
          searchController.text = '';
          break;
        case FilterOptions.hashersNotPaid:
          filterValues = <RxInt>[
            0.obs,
            0.obs,
            1.obs,
            (-1).obs,
            0.obs,
            0.obs,
            0.obs,
            0.obs,
            0.obs,
            0.obs,
          ];
          searchText.value = '';
          searchController.text = '';
          break;
        case FilterOptions.hashersStillOnTrail:
          filterValues = <RxInt>[
            0.obs,
            0.obs,
            1.obs,
            0.obs,
            (-1).obs,
            0.obs,
            0.obs,
            0.obs,
            0.obs,
            0.obs,
          ];
          searchText.value = '';
          searchController.text = '';
          break;
        case FilterOptions.clearAllFilters:
          filterValues = <RxInt>[
            0.obs,
            0.obs,
            0.obs,
            0.obs,
            0.obs,
            0.obs,
            0.obs,
            0.obs,
            0.obs,
            0.obs,
          ];
          searchText.value = '';
          searchController.text = '';
          break;
        case FilterOptions.visitors:
          filterValues = <RxInt>[
            0.obs,
            0.obs,
            1.obs,
            0.obs,
            0.obs,
            0.obs,
            0.obs,
            0.obs,
            0.obs,
            0.obs,
          ];
          searchText.value = '(visitor)';
          searchController.text = '(visitor)';
          break;
        case FilterOptions.virgins:
          filterValues = <RxInt>[
            0.obs,
            0.obs,
            1.obs,
            0.obs,
            0.obs,
            0.obs,
            0.obs,
            0.obs,
            0.obs,
            0.obs,
          ];
          searchText.value = '(virgin)';
          searchController.text = '(virgin)';
          break;
        case FilterOptions.cancel:
          break;
        default:
          filterValues = <RxInt>[
            0.obs,
            0.obs,
            0.obs,
            0.obs,
            0.obs,
            0.obs,
            0.obs,
            0.obs,
            0.obs,
            0.obs,
          ];
          searchText.value = '';
          searchController.text = '';
          break;
      }

      if (retVal != FilterOptions.cancel) {
        if (!showFilter.value) {
          showFilter.value = true;

          animationController.forward();
        }
        refreshPackListFromTables(true);
      }
    });
  }

  Future<void> findHasher(BuildContext context) async {
    final Map<String, dynamic>? result =
        await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute<Map<String, dynamic>>(
            settings: const RouteSettings(),
            builder: (BuildContext context) {
              return FindHasherPage(
                FindHasherPageType.addHasherToRun,
                kennelId: eventAggregate.event.kennelId,
                eventId: eventAggregate.event.eventId,
              );
            },
          ),
        );

    if ((result != null) && (result['hasher']?.hasherId != null)) {
      // NOTE:this method returns adHoc data that we are ignoring
      await tableModel.hasherEventMapService.setEventAttendence(
        eventAggregate.event.eventId,
        result['hasher'].hasherId,
        AppDomainType.event,
        attendenceAtHash.value,
      );

      await refreshPackListFromTables(true);
      await _refreshCounters(forceRefresh: true);
    }
  }
}
