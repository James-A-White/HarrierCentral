// // ignore_for_file: constant_identifier_names

// import 'package:harrier_central/imports.dart';
// import 'package:flutter_slidable/flutter_slidable.dart';

// class OldCheckInPage extends StatefulWidget {
//   const OldCheckInPage({super.key, required this.eventAggregate});

//   final RunAdminAggregate eventAggregate;

//   @override
//   State<OldCheckInPage> createState() {
//     return OldCheckInPageState();
//   }
// }

// enum FilterOptions {
//   hashersNotHereYet,
//   hashersStillOnTrail,
//   hashersNotPaid,
//   visitors,
//   virgins,
//   clearAllFilters,
//   cancel,
// }

// class OldCheckInPageState extends State<OldCheckInPage>
//     with TickerProviderStateMixin {
//   //final PackScopedModel _packScopedModel = PackScopedModel();
//   //final PayScopedModel _payScopedModel = PayScopedModel();

//   final GlobalKey _packListBoxKey = GlobalKey();

//   bool _isLoading = true;

//   List<CheckInPackModel> _packList = <CheckInPackModel>[];
//   List<CheckInPackModel> _filteredList = <CheckInPackModel>[];
//   List<CheckInPackModel> _allHashers = <CheckInPackModel>[];

//   String _searchText = '';

//   int _countAtHash = 0;
//   //int _countRsvps = 0;
//   int _countComing = 0;
//   int _countPaid = 0;
//   int _countOnIn = 0;
//   int _memberCount = 0;
//   int _drinkCount = 0;

//   static const double LIST_ITEM_HEIGHT = 84.0;

//   late AnimationController _animationController;
//   late Animation<double> _buttonAnimation;
//   late Animation<Offset> _filterPanelAnimation;
//   late Animation<RelativeRect> _hasherListAnimation;
//   final ScrollController _scrollController = ScrollController(
//     initialScrollOffset: 0.0,
//   );

//   final TextEditingController _searchController = TextEditingController();
//   final FocusNode _searchFocusNode = FocusNode();

//   String _searchTypeText = '';
//   bool _showFilter = false;

//   //bool _useTerminalForPayment = false;

//   static const String _searchKennel = 'Searching Kennel members and RSVPs';
//   static const String _searchAllHashers = 'Searching all Hashers';
//   bool _highlightSearchType = false;

//   final TextStyle _localFootnoteSmallRed = ts_footnoteSmallRed.copyWith(
//     fontSize: 12 * deviceInfo.deviceWidthScaleFactor,
//   );
//   final TextStyle _localFootnoteSmall = ts_footnoteSmall.copyWith(
//     fontSize: 12 * deviceInfo.deviceWidthScaleFactor,
//   );

//   List<int> _filterValues = <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

//   @override
//   void initState() {
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//     _buttonAnimation = Tween<double>(
//       begin: 0,
//       end: 90.0 / 360.0,
//     ).animate(_animationController)..addListener(() {
//       setState(() {});
//     });

//     _filterPanelAnimation = Tween<Offset>(
//       begin: const Offset(0, -.35),
//       end: const Offset(0, .71),
//     ).animate(_animationController);
//     _hasherListAnimation = RelativeRectTween(
//       begin: const RelativeRect.fromLTRB(0, 86, 0, 0),
//       end: const RelativeRect.fromLTRB(0, 204, 0, 0),
//     ).animate(_animationController);

//     _searchTypeText = _searchKennel;

//     _getAllHashers().then((void _) {
//       // get all Hashers first, then build the tables from the backend
//       _refreshSqlTablesFromBackend(true);
//     });
//     super.initState();
//   }

//   Future<void> _refreshSqlTablesFromBackend(bool showLoadingIndicator) async {
//     if (appModel.connectionStatus == EnumConnectionStatus2.connected) {
//       if (showLoadingIndicator) {
//         setState(() {
//           _isLoading = true;
//         });
//       }

//       await tableModel.syncEventAdminService.updateFromBackend(
//         SyncEventAdminService.flagHashersTable |
//             SyncEventAdminService.flagPaymentsTable |
//             SyncEventAdminService.flagHasherEventMapTable |
//             SyncEventAdminService.flagHasherKennelMapTable,
//         true,
//         widget.eventAggregate.event.eventId,
//       );
//       //final String resultStr = result ? 'successfully' : 'unsuccessfully';
//       //print('Payments data synchronized $resultStr');

//       await _refreshPackListFromTables(false);
//       await _refreshCounters(true);
//     }
//   }

//   Future<void> _getAllHashers() async {
//     _allHashers = <CheckInPackModel>[];

//     try {
//       final String sql = '''
//           SELECT 
//               -- get all hashers
//               h.hasherId,
//               null as hemId,
//               coalesce(
//                   CASE 
//                       WHEN (julianday(hkm.${tableModel.hasherKennelMapTableHelper.colMembershipExpirationDate}) >= julianday('now','$offsetFromGmtToLocal')) THEN 1 
//                       ELSE 0 
//                   END, 0) as isMember,
//               coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colFollowing}, 0) as isFollowing,
//               0 as isHare,
//               0 as isPaid, 
//               coalesce(
//                   hkm.${tableModel.hasherKennelMapTableHelper.colKennelHashName}, 
//                   coalesce(h.dispName, h.hashName, coalesce(h.firstName, '') || ' ' || coalesce(h.lastName, ''))
//               ) as nameForDisplay,
//               lower(
//                   coalesce(
//                       ' ' || hkm.${tableModel.hasherKennelMapTableHelper.colKennelHashName} || ' ',
//                       ' ' || coalesce(h.hashName, '') || ' ' || coalesce(h.dispName, '') || ' ' || coalesce(h.firstName, '') || ' ' || coalesce(h.lastName, '')
//                   )
//               ) as nameForSort,
//               0 as paymentType,
//               0 as creditAmount,
//               h.photo,
//               0 as virginVisitorType,
//               0 as rsvpState,
//               0 as attendanceState,
//               null as hemUpdatedAt,
//               null as payUpdatedAt,
//               coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colDiscountAmount}, 0) as discountAmount,
//               coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colDiscountPercent}, 0) as discountPercent,
//               0 as credit
//           FROM ${tableModel.hashersTableHelper.getTableName(AppDomainType.user)} h
//           LEFT OUTER JOIN ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.event)} hkm 
//               ON hkm.${tableModel.hasherKennelMapTableHelper.colUserId} = h.${tableModel.hashersTableHelper.colHasherId}
//           WHERE h.${tableModel.hashersTableHelper.colDispName} NOT LIKE 'Placeholder user for%'
//           ORDER BY nameForSort;

//           ''';

//       final List<Map<String, dynamic>> results = await database.rawQuery(
//         sql,
//       );

//       if (results.isNotEmpty) {
//         for (int i = 0; i < results.length; i++) {
//           final CheckInPackModel item = CheckInPackModel.fromMap(results[i]);
//           _allHashers.add(item);
//         }
//       }

//       //print('All hashers loaded @ ${DateTime.now().millisecondsSinceEpoch}');
//     } catch (e) {
//       //print(e);
//     }
//   }

//   Future<void> _refreshPackListFromTables(bool forceRefresh) async {
//     try {
//       final String sql = '''
//       SELECT 
//           h.${tableModel.hashersTableHelper.colHasherId} AS hasherId,
//           hem.${tableModel.hasherEventMapTableHelper.colHemId} AS hemId,
//           CASE 
//               WHEN (julianday(hkm.${tableModel.hasherKennelMapTableHelper.colMembershipExpirationDate}) >= julianday('now', '$offsetFromGmtToLocal')) 
//               THEN 1 
//               ELSE 0 
//           END AS isMember,
//           hkm.${tableModel.hasherKennelMapTableHelper.colFollowing} AS isFollowing,
//           COALESCE(hem.${tableModel.hasherEventMapTableHelper.colIsHare}, 0) AS isHare,
//           CASE 
//               WHEN pay.${tableModel.paymentsTableHelper.colHemId} IS NULL 
//               THEN 0 
//               ELSE 1 
//           END AS isPaid, 
//           COALESCE(hkm.${tableModel.hasherKennelMapTableHelper.colKennelHashName}, 
//               COALESCE(h.${tableModel.hashersTableHelper.colDispName}, 
//                   h.${tableModel.hashersTableHelper.colHashName}, 
//                   COALESCE(h.${tableModel.hashersTableHelper.colFirstName}, '') || ' ' || 
//                   COALESCE(h.${tableModel.hashersTableHelper.colLastName}, ''))) AS nameForDisplay,
//           LOWER(COALESCE(' ' || hkm.${tableModel.hasherKennelMapTableHelper.colKennelHashName} || ' ', 
//               ' ' || COALESCE(h.${tableModel.hashersTableHelper.colHashName}, '') || ' ' || 
//               COALESCE(h.${tableModel.hashersTableHelper.colDispName}, '') || ' ' || 
//               COALESCE(h.${tableModel.hashersTableHelper.colFirstName}, '') || ' ' || 
//               COALESCE(h.${tableModel.hashersTableHelper.colLastName}, ''))) AS nameForSort,
//           COALESCE(pay.${tableModel.paymentsTableHelper.colPaymentType}, 0) AS paymentType,
//           COALESCE(pay.${tableModel.paymentsTableHelper.colCreditAmount}, 0) AS creditAmount,
//           COALESCE(hkm.${tableModel.hasherKennelMapTableHelper.colKennelUserPhoto}, h.${tableModel.hashersTableHelper.colPhoto}) AS photo,
//           0 AS virginVisitorType,
//           COALESCE(hem.${tableModel.hasherEventMapTableHelper.colRsvpState}, 0) AS rsvpState,
//           COALESCE(hem.${tableModel.hasherEventMapTableHelper.colTotalRunsThisKennel}, 0) AS totalRunsThisKennel,
//           COALESCE(hem.${tableModel.hasherEventMapTableHelper.colTotalHaringThisKennel}, 0) AS totalHaringThisKennel,
//           COALESCE(hem.${tableModel.hasherEventMapTableHelper.colAttendenceState}, 0) AS attendenceState,
//           hem.${tableModel.hasherEventMapTableHelper.colUpdatedAt} AS hemUpdatedAt,
//           pay.${tableModel.paymentsTableHelper.colUpdatedAt} AS payUpdatedAt,
//           hkm.${tableModel.hasherKennelMapTableHelper.colKennelCredit} AS credit,
//           COALESCE(hkm.${tableModel.hasherKennelMapTableHelper.colDiscountAmount}, 0) AS discountAmount,
//           COALESCE(hkm.${tableModel.hasherKennelMapTableHelper.colDiscountPercent}, 0) AS discountPercent,
//           hkm.${tableModel.hasherKennelMapTableHelper.colHcTotalRunCount} AS hcTotalRunCount,
//           hkm.${tableModel.hasherKennelMapTableHelper.colHcHaringCount} AS hcHaringCount,
//           hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalTotalRunCount} AS historicalTotalRunCount,
//           hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalHaringCount} AS historicalHaringCount,
//           hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalCountIsEstimate} AS historicalCountIsEstimate
//       FROM ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.event)} hkm
//       INNER JOIN ${tableModel.hashersTableHelper.getTableName(AppDomainType.user)} h ON h.hasherId = hkm.userId
//       LEFT OUTER JOIN ${tableModel.hasherEventMapTableHelper.getTableName(AppDomainType.event)} hem ON hem.userId = hkm.userId AND hem.eventId = "${widget.eventAggregate.event.eventId}"
//       LEFT OUTER JOIN ${tableModel.paymentsTableHelper.getTableName(AppDomainType.event)} pay ON pay.hemId = hem.hemId AND pay.cancelledBy IS NULL
//       WHERE hkm.kennelId = "${widget.eventAggregate.event.kennelId}" 
//         AND COALESCE(hem.virginVisitorType, 0) = 0
//         AND (
//           hkm.isKennelFollowing = 1
//           OR (
//             hkm.isKennelFollowing = 0
//             AND (
//               julianday(hkm.membershipExpirationDate) >= julianday('now', '$offsetFromGmtToLocal')
//               OR julianday(hkm.dateOfLastRun) >= julianday('now', '$offsetFromGmtToLocal', '-2 months')
//             )
//           )
//         )

//       UNION

//       SELECT 
//           NULL AS hasherId,
//           COALESCE(hem2.hemId, "00000000-0000-0000-0000-000000000000") AS hemId,
//           0 AS isMember,
//           0 AS isFollowing,
//           hem2.isHare AS isHare,
//           CASE 
//               WHEN pay2.hemId IS NULL 
//               THEN 0 
//               ELSE 1 
//           END AS isPaid, 
//           COALESCE(hem2.displayName, 
//               CASE WHEN hem2.virginVisitorType = 3 THEN h2.dispName ELSE "<no name>" END) || 
//               CASE WHEN hem2.virginVisitorType = 1 THEN " (virgin)" ELSE " (visitor)" END AS nameForDisplay,
//           LOWER(COALESCE(hem2.displayName, 
//               CASE WHEN hem2.virginVisitorType = 3 THEN ' ' || COALESCE(h2.dispName, h2.hashName, COALESCE(h2.firstName, '') || ' ' || COALESCE(h2.lastName, '')) || ' ' 
//               ELSE "<no name>" END) || 
//               CASE WHEN hem2.virginVisitorType = 1 THEN " (virgin)" ELSE " (visitor)" END) AS nameForSort,
//           COALESCE(pay2.paymentType, 0) AS paymentType,
//           COALESCE(pay2.creditAmount, 0) AS creditAmount,
//           CASE 
//               WHEN hem2.virginVisitorType = 1 
//               THEN "https://harriercentral.blob.core.windows.net/harrier/Virgin.png" 
//               ELSE "https://harriercentral.blob.core.windows.net/harrier/Visitor.png" 
//           END AS photo,
//           COALESCE(hem2.virginVisitorType, 1) AS virginVisitorType,
//           COALESCE(hem2.rsvpState, 0) AS rsvpState,
//           COALESCE(hem2.${tableModel.hasherEventMapTableHelper.colTotalRunsThisKennel}, 0) AS totalRunsThisKennel,
//           COALESCE(hem2.${tableModel.hasherEventMapTableHelper.colTotalHaringThisKennel}, 0) AS totalHaringThisKennel,
//           COALESCE(hem2.attendenceState, 0) AS attendenceState,
//           hem2.updatedAt AS hemUpdatedAt,
//           pay2.updatedAt AS payUpdatedAt,
//           0 AS credit,
//           0 AS ${tableModel.hasherKennelMapTableHelper.colDiscountAmount},
//           0 AS ${tableModel.hasherKennelMapTableHelper.colDiscountPercent},
//           NULL AS ${tableModel.hasherKennelMapTableHelper.colHcTotalRunCount},
//           NULL AS ${tableModel.hasherKennelMapTableHelper.colHcHaringCount},
//           NULL AS ${tableModel.hasherKennelMapTableHelper.colHistoricalTotalRunCount},
//           NULL AS ${tableModel.hasherKennelMapTableHelper.colHistoricalHaringCount},
//           NULL AS ${tableModel.hasherKennelMapTableHelper.colHistoricalCountIsEstimate}
//       FROM ${tableModel.hasherEventMapTableHelper.getTableName(AppDomainType.event)} hem2
//       INNER JOIN ${tableModel.hashersTableHelper.getTableName(AppDomainType.user)} h2 ON h2.hasherId = hem2.userId
//       LEFT OUTER JOIN ${tableModel.paymentsTableHelper.getTableName(AppDomainType.event)} pay2 ON pay2.hemId = hem2.hemId AND pay2.cancelledBy IS NULL
//       WHERE hem2.eventId = "${widget.eventAggregate.event.eventId}" 
//         AND hem2.virginVisitorType != 0

//       UNION

//       SELECT 
//           hem3.userId AS hasherId,
//           hem3.hemId AS hemId,
//           0 AS isMember,
//           hkm4.${tableModel.hasherKennelMapTableHelper.colFollowing} AS isFollowing,
//           hem3.isHare AS isHare,
//           CASE 
//               WHEN pay3.hemId IS NULL 
//               THEN 0 
//               ELSE 1 
//           END AS isPaid, 
//           COALESCE(hkm4.${tableModel.hasherKennelMapTableHelper.colKennelHashName}, 
//               COALESCE(h3.dispName, h3.hashName, COALESCE(h3.firstName, '') || ' ' || 
//               COALESCE(h3.lastName, ''))) AS nameForDisplay,
//           LOWER(COALESCE(hkm4.${tableModel.hasherKennelMapTableHelper.colKennelHashName}, 
//               COALESCE(h3.dispName, h3.hashName, '') || ' ' || 
//               COALESCE(h3.lastName, '') || ' ' || 
//               COALESCE(h3.firstName, ''))) AS nameForSort,
//           COALESCE(pay3.paymentType, 0) AS paymentType,
//           COALESCE(pay3.creditAmount, 0) AS creditAmount,
//           COALESCE(hkm4.${tableModel.hasherKennelMapTableHelper.colKennelUserPhoto}, h3.photo) AS photo,
//           hem3.virginVisitorType AS virginVisitorType,
//           COALESCE(hem3.rsvpState, 0) AS rsvpState,
//           COALESCE(hem3.${tableModel.hasherEventMapTableHelper.colTotalRunsThisKennel}, 0) AS totalRunsThisKennel,
//           COALESCE(hem3.${tableModel.hasherEventMapTableHelper.colTotalHaringThisKennel}, 0) AS totalHaringThisKennel,
//           COALESCE(hem3.attendenceState, 0) AS attendenceState,
//           hem3.updatedAt AS hemUpdatedAt,
//           pay3.updatedAt AS payUpdatedAt,
//           hkm4.${tableModel.hasherKennelMapTableHelper.colKennelCredit} AS credit,
//           COALESCE(hkm4.${tableModel.hasherKennelMapTableHelper.colDiscountAmount}, 0) AS discountAmount,
//           COALESCE(hkm4.${tableModel.hasherKennelMapTableHelper.colDiscountPercent}, 0) AS discountPercent,
//           hkm4.${tableModel.hasherKennelMapTableHelper.colHcTotalRunCount},
//           hkm4.${tableModel.hasherKennelMapTableHelper.colHcHaringCount},
//           hkm4.${tableModel.hasherKennelMapTableHelper.colHistoricalTotalRunCount},
//           hkm4.${tableModel.hasherKennelMapTableHelper.colHistoricalHaringCount},
//           hkm4.${tableModel.hasherKennelMapTableHelper.colHistoricalCountIsEstimate}
//       FROM ${tableModel.hasherEventMapTableHelper.getTableName(AppDomainType.event)} hem3
//       INNER JOIN ${tableModel.hashersTableHelper.getTableName(AppDomainType.user)} h3 ON h3.hasherId = hem3.userId
//       LEFT OUTER JOIN ${tableModel.paymentsTableHelper.getTableName(AppDomainType.event)} pay3 ON pay3.hemId = hem3.hemId AND pay3.cancelledBy IS NULL
//       LEFT OUTER JOIN ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.event)} hkm3 ON hkm3.userId = h3.hasherId AND hkm3.kennelId = "${widget.eventAggregate.event.kennelId}" AND julianday(hkm3.membershipExpirationDate) >= julianday('now', '$offsetFromGmtToLocal')
//       LEFT OUTER JOIN ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.event)} hkm4 ON hkm4.userId = h3.hasherId AND hkm4.kennelId = "${widget.eventAggregate.event.kennelId}" 
//       WHERE hem3.eventId = "${widget.eventAggregate.event.eventId}" 
//         AND hem3.virginVisitorType = 0 
//         AND (
//           (
//             hkm4.userId IS NULL
//           ) OR NOT (
//             hkm4.isKennelFollowing = 1
//             OR (
//               hkm4.isKennelFollowing = 0
//               AND (
//                 julianday(COALESCE(hkm4.membershipExpirationDate, '2000-01-01T01:00:00.000Z')) >= julianday('now', '$offsetFromGmtToLocal') 
//                 OR julianday(COALESCE(hkm4.dateOfLastRun, '2000-01-01T01:00:00.000Z')) >= julianday('now', '$offsetFromGmtToLocal', '-2 months')
//               )
//             )
//           )
//         )

//       ORDER BY nameForSort

//           ''';

//       try {
//         List<Map<String, dynamic>> results;
//         results = await database.rawQuery(sql);

//         setState(() {
//           if (results.isNotEmpty) {
//             _packList = <CheckInPackModel>[];
//             for (int i = 0; i < results.length; i++) {
//               final CheckInPackModel item = CheckInPackModel.fromMap(
//                 results[i],
//               );
//               if (item.nameForDisplay.toLowerCase().startsWith(
//                 'placeholder user',
//               )) {
//                 continue;
//               }
//               _packList.add(item);
//             }

//             setState(() {
//               _isLoading = false;
//             });
//           }

//           //print('Pack records retreived @ ${DateTime.now().millisecondsSinceEpoch}');

//           _filterPackListResults();
//         });
//       } catch (x) {
//         //print(x);
//       }
//     } catch (e) {
//       //print(e);
//     }
//   }

//   void _filterPackListResults() {
//     //bool showSnackbar = false;
//     //bool searchingAllHashers = false;

//     bool ignoreTextFilter = false;
//     final String temp = _searchTypeText;

//     if (_showFilter) {
//       _filteredList =
//           _packList
//               .where(
//                 (CheckInPackModel a) =>
//                     ((_filterValues[0] == 0) ||
//                         (_filterValues[0] == -1 && ((a.rsvpState) <= 1)) ||
//                         (_filterValues[0] == 1 && (a.rsvpState) >= 2)) &&
//                     ((_filterValues[1] == 0)
//                         //|| (filterValues[1] == -1 && ((a.attendenceState) < 20))
//                         ||
//                         (_filterValues[1] == 1 &&
//                             (a.attendenceState) < 20 &&
//                             (a.rsvpState) >= 2)) &&
//                     ((_filterValues[2] == 0) ||
//                         (_filterValues[2] == -1 &&
//                             ((a.attendenceState) < 20)) ||
//                         (_filterValues[2] == 1 && (a.attendenceState) >= 20)) &&
//                     ((_filterValues[3] == 0) ||
//                         (_filterValues[3] == -1 && ((a.isPaid) == 0)) ||
//                         (_filterValues[3] == 1 && (a.isPaid) == 1)) &&
//                     ((_filterValues[4] == 0) ||
//                         (_filterValues[4] == -1 &&
//                             ((a.attendenceState) < 30)) ||
//                         (_filterValues[4] == 1 && (a.attendenceState) >= 30)) &&
//                     ((_filterValues[5] == 0) ||
//                         (_filterValues[5] == -1 && ((a.isMember) == 0)) ||
//                         (_filterValues[5] == 1 && (a.isMember) == 1)) &&
//                     ((_filterValues[6] == 0) ||
//                         (_filterValues[6] == -1) ||
//                         (_filterValues[6] == 1 &&
//                             ((a.attendenceState) >= attendenceAtHash.value) &&
//                             ((_checkSpecialRun(
//                                   (a.totalRunsThisKennel) +
//                                       (a.historicalTotalRunCount),
//                                 )) ||
//                                 ((a.isHare == 1) &&
//                                     (_checkSpecialHaring(
//                                       (a.totalHaringThisKennel) +
//                                           (a.historicalHaringCount),
//                                     )))))),
//               )
//               .toList();

//       _filteredList.sort(
//         (CheckInPackModel a, CheckInPackModel b) =>
//             a.nameForDisplay.compareTo(b.nameForDisplay),
//       );
//     } else {
//       _filteredList = <CheckInPackModel>[];
//       _filteredList.addAll(_packList);
//     }

//     if (_searchText.isNotEmpty) {
//       _filteredList =
//           _filteredList
//               .where(
//                 (CheckInPackModel a) => a.nameForSort.toLowerCase().contains(
//                   _searchText.toLowerCase(),
//                 ),
//               )
//               .toList();
//       if (_filteredList.isEmpty) {
//         // if (!ignoreTextFilter) {
//         //   showSnackbar = true;
//         // }
//         ignoreTextFilter = true;
//         _filteredList =
//             _allHashers
//                 .where(
//                   (CheckInPackModel a) => a.nameForSort.toLowerCase().contains(
//                     _searchText.toLowerCase(),
//                   ),
//                 )
//                 .toList();
//       } else {
//         ignoreTextFilter = false;
//         ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       }
//     } else {
//       _searchTypeText = _searchKennel;
//     }

//     _searchTypeText = ignoreTextFilter ? _searchAllHashers : _searchKennel;

//     if (temp != _searchTypeText) {
//       _highlightSearchType = true;
//       Future<void>.delayed(const Duration(milliseconds: 1500)).then((void _) {
//         setState(() {
//           _highlightSearchType = false;
//         });
//       });
//     }
//     for (int i = 0; i < _filteredList.length; i++) {
//       _filteredList[i] = _filteredList[i].copyWith(
//         rsvpStateIndicator: Future<int>.value(_filteredList[i].rsvpState),
//         attendenceStateIndicator: Future<int>.value(
//           _filteredList[i].attendenceState,
//         ),
//         paidStateIndicator: Future<int>.value(
//           _filteredList[i].attendenceState < attendenceAtHash.value
//               ? isPaidEmpty.value
//               : (_filteredList[i].paymentType == paymentNotPaid.value ||
//                   _filteredList[i].paymentType == paymentTypeUnknown.value)
//               ? isPaidNo.value
//               : isPaidYes.value,
//         ),
//       );
//     }
//     setState(() {});
//   }

//   bool _checkSpecialRun(int runCount) {
//     return Utilities.checkSpecialRun(runCount) != 0;
//   }

//   bool _checkSpecialHaring(int haringCount) {
//     return Utilities.checkSpecialHaring(haringCount) != 0;
//   }

//   Future<void> _refreshCounters(bool forceRefresh) async {
//     try {
//       final String sql = '''

//           SELECT 
//               -- COUNT(CASE WHEN rsvpState >= 2 THEN 1 ELSE NULL END) as rsvps,
//               COUNT(CASE WHEN attendenceState >= 20 THEN 1 ELSE NULL END) as atHash,
//               COUNT(CASE WHEN pay.paymentType >= 2 THEN 1 ELSE NULL END) as paid,
//               COUNT(CASE WHEN rsvpState >= 2 AND attendenceState < 20 THEN 1 ELSE NULL END) as coming,
//               COUNT(CASE WHEN attendenceState >= 30 THEN 1 ELSE NULL END) as onIn,
//               (SELECT COUNT(*) FROM ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.event)} hkm WHERE hkm.kennelId = "${widget.eventAggregate.event.kennelId}" and hkm.isMember = 1) as memberCount
//           FROM ${tableModel.hasherEventMapTableHelper.getTableName(AppDomainType.event)} hem
//           INNER JOIN ${tableModel.hashersTableHelper.getTableName(AppDomainType.user)} h ON hem.${tableModel.hasherEventMapTableHelper.colUserId} = h.${tableModel.hashersTableHelper.colHasherId}
//           LEFT OUTER JOIN ${tableModel.paymentsTableHelper.getTableName(AppDomainType.event)} pay on pay.hemId = hem.hemId and pay.cancelledBy IS NULL
//           WHERE h.${tableModel.hashersTableHelper.colRemoved} = 0
  
//           ''';

//       final List<Map<String, dynamic>> results = await database.rawQuery(
//         sql,
//       );
//       if (results.isNotEmpty) {
//         //_countRsvps = results[0]['rsvps'];
//         _countAtHash = results[0]['atHash'];
//         _countComing = results[0]['coming'];
//         _countOnIn = results[0]['onIn'];
//         _countPaid = results[0]['paid'];
//         _memberCount = results[0]['memberCount'];
//       }

//       if (_packList.isNotEmpty) {
//         final List<CheckInPackModel> specialRunNumbers =
//             _packList
//                 .where(
//                   (CheckInPackModel a) =>
//                       ((a.attendenceState) >= attendenceAtHash.value) &&
//                       (_checkSpecialRun(
//                         (a.historicalTotalRunCount) + (a.totalRunsThisKennel),
//                       )),
//                 )
//                 .toList();

//         specialRunNumbers.addAll(
//           _packList
//               .where(
//                 (CheckInPackModel a) =>
//                     ((a.attendenceState) >= attendenceAtHash.value) &&
//                     ((a.isHare == 1) &&
//                         (_checkSpecialHaring(
//                           (a.historicalHaringCount) + (a.totalHaringThisKennel),
//                         ))),
//               )
//               .toList(),
//         );

//         _drinkCount = specialRunNumbers.length;
//       } else {
//         _drinkCount = 0;
//       }

//       if (forceRefresh) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       //print(e);
//     }
//   }

//   Future<void> _findHasher() async {
//     final Map<String, dynamic>? result =
//         await Navigator.push<Map<String, dynamic>>(
//           context,
//           MaterialPageRoute<Map<String, dynamic>>(
//             settings: const RouteSettings(),
//             builder: (BuildContext context) {
//               return FindHasherPage(
//                 FindHasherPageType.addHasherToRun,
//                 kennelId: widget.eventAggregate.event.kennelId,
//                 eventId: widget.eventAggregate.event.eventId,
//               );
//             },
//           ),
//         );

//     if ((result != null) && (result['hasher']?.hasherId != null)) {
//       // NOTE:this method returns adHoc data that we are ignoring
//       await tableModel.hasherEventMapService.setEventAttendence(
//         widget.eventAggregate.event.eventId,
//         result['hasher'].hasherId,
//         AppDomainType.event,
//         attendenceAtHash.value,
//       );

//       await _refreshPackListFromTables(true);
//       await _refreshCounters(true);
//     }
//   }

//   void _copyRsvpsFromLastRun(BuildContext parentContext) async {
//     var result = await QueryRuns.queryPreviousRun(
//       widget.eventAggregate.kennel.kennelId,
//       widget.eventAggregate.event.eventStartDatetime,
//     );

//     String lastRunName = result[0]['eventName'].toString();
//     String fromEventId = result[0]['eventId'].toString();

//     bool doCopyRsvps =
//         await Utilities.showAlert(
//           'Copy RSVPs',
//           'Are you sure you want to copy all RSVPs from\r\n\r\n$lastRunName\r\n\r\nto this run?',
//           'Yes',
//           showCancelButton: true,
//           cancelButtonText: 'No',
//         ) ??
//         false;

//     if (doCopyRsvps) {
//       final List<dynamic> adHocData = await tableModel
//           .hasherEventMapService
//           .copyEventRsvps(fromEventId, widget.eventAggregate.event.eventId);

//       final String serverMessage = adHocData[0]['serverMessage'] ?? '';

//       if (serverMessage.isNotEmpty) {
//         await Utilities.showAlert('RSVP Result', serverMessage, 'OK');
//       }

//       await _refreshPackListFromTables(false);
//       await _refreshCounters(true);
//     }
//   }

//   void _showVirginVisitorPopup(BuildContext parentContext) {
//     int? scrollIndex = -1;

//     const AddVisitorVirginPopup addVirginVisitorPopup = AddVisitorVirginPopup();

//     final Future<Map<String, String>?> dlg = showDialog<Map<String, String>>(
//       context: context,
//       barrierDismissible: false, // user must tap button!
//       builder: (BuildContext context) {
//         return addVirginVisitorPopup;
//       },
//     );

//     dlg.then<Map<String, String>?>((Map<String, String>? x) {
//       if (x != null) {
//         final String name = x['name'] ?? '';
//         final String type = x['type'] ?? '';
//         final String email = x['email'] ?? '';
//         final String phoneNumber = x['phone'] ?? '';

//         EnumVirginVisitor<int> evv = enumVirgin;
//         if (type == enumAnonymousVisitor.value.toString()) {
//           evv = enumAnonymousVisitor;
//         }

//         if (type != 'cancel') {
//           setState(() {
//             _isLoading = true;
//           });
//           final Future<List<dynamic>> retVal = tableModel
//               .hasherEventMapService
//               .joinEventAsVisitor(
//                 widget.eventAggregate.event.eventId,
//                 name,
//                 evv.value,
//                 attendenceUnknown.value,
//                 email,
//                 phoneNumber,
//                 AppDomainType.event,
//               );

//           retVal.then((List<dynamic> adHocData) {
//             _refreshPackListFromTables(false).then((void _) {
//               _refreshCounters(true);
//               // if (name?.isNotEmpty ?? false) {
//               //   searchText = name;
//               //   searchController.text = searchText;
//               //   filterPackListResults();
//               // }

//               setState(() {
//                 _isLoading = false;
//               });

//               if (widget.eventAggregate.extensions.appAccess.canManageRuns) {
//                 if (adHocData.isNotEmpty) {
//                   final String hem =
//                       adHocData[0]['hasherEventMapId'].toString().toLowerCase();
//                   scrollIndex = _filteredList.indexWhere(
//                     (CheckInPackModel k) =>
//                         k.hemId.toString().toLowerCase() == hem,
//                   );
//                   if ((scrollIndex ?? -1) >= 0) {
//                     //final CheckInPackModel hasher = _packList[scrollIndex!];
//                     //if (hasher != null) {
//                     if (scrollIndex != null) {
//                       final SnackBar snackBar = _buildRsvpAndPaymentSnackbar(
//                         navigatorKey.currentContext!,
//                         _scaffoldKey.currentState!,
//                         scrollIndex!,
//                       );

//                       ScaffoldMessenger.of(
//                         navigatorKey.currentContext!,
//                       ).removeCurrentSnackBar(
//                         reason: SnackBarClosedReason.hide,
//                       );
//                       ScaffoldMessenger.of(navigatorKey.currentContext!)
//                           .showSnackBar(snackBar)
//                           .closed
//                           .then((SnackBarClosedReason reason) {
//                             setState(() {
//                               if ((scrollIndex ?? -1) >= 0) {
//                                 if (_scrollController.hasClients) {
//                                   _scrollController.animateTo(
//                                     scrollIndex! * LIST_ITEM_HEIGHT,
//                                     duration: const Duration(seconds: 1),
//                                     curve: Curves.ease,
//                                   );
//                                 }
//                               }
//                             });
//                           });
//                     }
//                   }
//                 }
//               }
//             });
//           });
//         }
//       }
//       return;
//     });

//     // dlg.whenComplete(action)
//   }

//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

//   AppBar _getAppBar(String title) {
//     return AppBar(
//       centerTitle: true,
//       backgroundColor: themeAppBarBackground,
//       iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
//       title: TextScaleFactorClamper(
//         textScaleFactor: deviceInfo.textClamp15,
//         child: Text(title, style: ts_appBarTitle),
//       ),
//     );
//   }

//   Container _searchBar() {
//     return Container(
//       decoration: const BoxDecoration(
//         // border: new Border.all(width: 1.0, color: Colors.black),
//         //shape: BoxShape.circle,
//         color: Colors.white,
//         boxShadow: <BoxShadow>[
//           BoxShadow(
//             color: Color.fromARGB(70, 0, 0, 0),
//             offset: Offset(0.0, 6.0),
//             blurRadius: 10.0,
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.only(top: 10),
//       width: MediaQuery.of(context).size.width,
//       height: 85,
//       child: Column(
//         children: <Widget>[
//           Row(
//             children: <Widget>[
//               RotationTransition(
//                 turns: _buttonAnimation,
//                 child: IconButton(
//                   padding: const EdgeInsets.all(0),
//                   onPressed: () {
//                     _searchFocusNode.unfocus();
//                     if (_showFilter) {
//                       _animationController.reverse();
//                     } else {
//                       _animationController.forward();
//                     }
//                     _showFilter = !_showFilter;
//                     // searchController.text = '';
//                     // searchText = '';
//                     _refreshPackListFromTables(true);
//                   },
//                   icon: Icon(
//                     FontAwesome5Solid.arrow_alt_circle_right,
//                     size: 35,
//                     color: _showFilter ? Colors.green : Colors.grey,
//                   ),
//                 ),
//               ),
//               Container(
//                 height: 60,
//                 margin: const EdgeInsets.only(left: 3, right: 10),
//                 decoration: const BoxDecoration(
//                   border: Border(
//                     left: BorderSide(color: Colors.black, width: 1.0),
//                   ),
//                 ),
//               ),
//               Expanded(
//                 child: TextScaleFactorClamper(
//                   textScaleFactor: deviceInfo.textClamp00,
//                   child: Column(
//                     children: <Widget>[
//                       Row(
//                         children: <Widget>[
//                           Expanded(
//                             child: TextField(
//                               autocorrect: false,
//                               onChanged: (String text) {
//                                 setState(() {
//                                   _searchText = text;
//                                   _filterPackListResults();
//                                 });
//                               },
//                               focusNode: _searchFocusNode,
//                               controller: _searchController,
//                               keyboardType: TextInputType.text,
//                               style: ts_titleMediumBlack,
//                               decoration: InputDecoration(
//                                 border: InputBorder.none,
//                                 icon: const Icon(
//                                   FontAwesome.search,
//                                   color: Colors.black,
//                                 ),
//                                 hintText: 'Enter Hash or mortal name',
//                                 hintStyle: ts_hint,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       Text(
//                         _searchTypeText,
//                         style:
//                             _highlightSearchType
//                                 ? _localFootnoteSmallRed
//                                 : _localFootnoteSmall,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               SizedBox(
//                 width: 40,
//                 child: TextButton(
//                   style: TextButton.styleFrom(
//                     shape: button_shape,
//                     textStyle: TextStyle(color: Colors.grey.shade700),
//                     backgroundColor: Colors.white,
//                   ),
//                   child: Text(
//                     'X',
//                     style: ts_headingBlack.copyWith(
//                       color: Colors.grey.shade700,
//                     ),
//                   ),
//                   onPressed: () {
//                     _searchController.text = '';
//                     _searchText = '';
//                     _refreshPackListFromTables(true);
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _filterBar() {
//     return TextScaleFactorClamper(
//       textScaleFactor: deviceInfo.textClamp25,
//       child: Container(
//         decoration: const BoxDecoration(
//           // border: new Border.all(width: 1.0, color: Colors.black),
//           //shape: BoxShape.circle,
//           color: Colors.white,
//           boxShadow: <BoxShadow>[
//             BoxShadow(
//               color: Color.fromARGB(70, 0, 0, 0),
//               offset: Offset(0.0, 6.0),
//               blurRadius: 10.0,
//             ),
//           ],
//         ),
//         padding: const EdgeInsets.only(top: 10),
//         width: MediaQuery.of(context).size.width,
//         height: 120,
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           mainAxisSize: MainAxisSize.max,
//           children: <Widget>[
//             CheckinFiltersCell(
//               counter: _memberCount,
//               label: 'Member',
//               index: 5,
//               onTap: () {
//                 _refreshPackListFromTables(true);
//               },
//               filterValues: _filterValues,
//             ),
//             // CheckinFiltersCell(
//             //   counter: countRsvps,
//             //   label: 'RSVP',
//             //   index: 0,
//             //   onTap: () {
//             //     _refreshPackListFromTables(true);
//             //   },
//             //   filterValues: filterValues,
//             // ),
//             CheckinFiltersCell(
//               counter: _countComing,
//               label: 'Coming',
//               index: 1,
//               useTriState: false,
//               onTap: () {
//                 _refreshPackListFromTables(true);
//               },
//               filterValues: _filterValues,
//             ),
//             CheckinFiltersCell(
//               counter: _countAtHash,
//               index: 2,
//               label: 'At Hash',
//               onTap: () {
//                 _refreshPackListFromTables(true);
//               },
//               filterValues: _filterValues,
//             ),
//             CheckinFiltersCell(
//               counter: _countPaid,
//               index: 3,
//               label: 'Paid',
//               onTap: () {
//                 _refreshPackListFromTables(true);
//               },
//               filterValues: _filterValues,
//             ),
//             CheckinFiltersCell(
//               counter: _countOnIn,
//               index: 4,
//               label: 'On In',
//               onTap: () {
//                 _refreshPackListFromTables(true);
//               },
//               filterValues: _filterValues,
//             ),
//             CheckinFiltersCell(
//               counter: _drinkCount,
//               index: 6,
//               useTriState: false,
//               label: 'Drink!',
//               onTap: () {
//                 _refreshPackListFromTables(true);
//               },
//               filterValues: _filterValues,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _filterOptionsPopup() {
//     final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
//       <String, dynamic>{
//         'title': 'Hashers not here yet',
//         'icon': <Widget>[
//           Container(
//             height: 30,
//             width: 30,
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               shape: BoxShape.circle,
//             ),
//           ),
//           const Icon(FontAwesome.check_circle, color: Colors.green),
//         ],
//         'returnValue': FilterOptions.hashersNotHereYet,
//       },
//       <String, dynamic>{
//         'title': 'Hashers still on trail',
//         'icon': <Widget>[
//           Container(
//             height: 30,
//             width: 30,
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               shape: BoxShape.circle,
//             ),
//           ),
//           Image.asset(
//             'images/icons/runner_icon.png',
//             height: 25,
//             width: 25,
//             color: Colors.orange,
//           ),
//         ],
//         'returnValue': FilterOptions.hashersStillOnTrail,
//       },
//       <String, dynamic>{
//         'title': 'Hashers who have not paid',
//         'icon': <Widget>[
//           Container(
//             height: 30,
//             width: 30,
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               shape: BoxShape.circle,
//             ),
//           ),
//           Image.asset(
//             'images/icons/dollar_sign_icon.png',
//             height: 25,
//             width: 25,
//             color: hc_red,
//           ),
//         ],
//         'returnValue': FilterOptions.hashersNotPaid,
//       },
//       <String, dynamic>{
//         'title': 'Visitors',
//         'icon': <Widget>[
//           Container(
//             height: 30,
//             width: 30,
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               shape: BoxShape.circle,
//             ),
//           ),
//           const Positioned(
//             bottom: 0,
//             child: Icon(
//               MaterialCommunityIcons.alpha_v_circle,
//               size: 31,
//               color: Colors.purple,
//             ),
//           ),
//         ],
//         'returnValue': FilterOptions.visitors,
//       },
//       <String, dynamic>{
//         'title': 'Virgins',
//         'icon': <Widget>[
//           Container(
//             height: 30,
//             width: 30,
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               shape: BoxShape.circle,
//             ),
//           ),
//           Positioned(
//             bottom: 0,
//             child: Icon(
//               MaterialCommunityIcons.alpha_v_circle,
//               size: 31,
//               color: Colors.pink[300],
//             ),
//           ),
//         ],
//         'returnValue': FilterOptions.virgins,
//       },
//       <String, dynamic>{
//         'title': 'Clear all filters',
//         'icon': <Widget>[
//           Container(
//             height: 30,
//             width: 30,
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               shape: BoxShape.circle,
//             ),
//           ),
//           Icon(FontAwesome.times_circle, color: hc_red),

//           // Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
//           // const Positioned(bottom: 0, child: Icon(Ionicons.md_remove_circle, size: 30, color: Colors.teal))
//         ],
//         'returnValue': FilterOptions.clearAllFilters,
//       },
//     ];

//     final MultipleChoicePopupHc popup = MultipleChoicePopupHc(
//       key: const Key('6919321235'),
//       title: 'Common filter options',
//       buttons: buttons,
//       cancelButtonTitle: 'Cancel',
//       cancelButtonReturnValue: followTypeCancel,
//     );

//     showDialog<dynamic>(
//       context: context,
//       barrierDismissible: false, // user must tap button!
//       builder: (BuildContext context) {
//         return popup;
//       },
//     ).then((dynamic retVal) {
//       switch (retVal) {
//         case FilterOptions.hashersNotHereYet:
//           _filterValues = <int>[0, 1, 0, 0, 0, 0, 0, 0, 0, 0];
//           _searchText = '';
//           _searchController.text = '';
//           break;
//         case FilterOptions.hashersNotPaid:
//           _filterValues = <int>[0, 0, 1, -1, 0, 0, 0, 0, 0, 0];
//           _searchText = '';
//           _searchController.text = '';
//           break;
//         case FilterOptions.hashersStillOnTrail:
//           _filterValues = <int>[0, 0, 1, 0, -1, 0, 0, 0, 0, 0];
//           _searchText = '';
//           _searchController.text = '';
//           break;
//         case FilterOptions.clearAllFilters:
//           _filterValues = <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
//           _searchText = '';
//           _searchController.text = '';
//           break;
//         case FilterOptions.visitors:
//           _filterValues = <int>[0, 0, 1, 0, 0, 0, 0, 0, 0, 0];
//           _searchText = '(visitor)';
//           _searchController.text = '(visitor)';
//           break;
//         case FilterOptions.virgins:
//           _filterValues = <int>[0, 0, 1, 0, 0, 0, 0, 0, 0, 0];
//           _searchText = '(virgin)';
//           _searchController.text = '(virgin)';
//           break;
//         case FilterOptions.cancel:
//           break;
//         default:
//           _filterValues = <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
//           _searchText = '';
//           _searchController.text = '';
//           break;
//       }

//       if (retVal != FilterOptions.cancel) {
//         if (!_showFilter) {
//           _showFilter = true;

//           _animationController.forward();
//         }
//         _refreshPackListFromTables(true);
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       floatingActionButton: SpeedDial(
//         // both default to 16
//         // marginEnd: 18,
//         // marginBottom: 30,
//         animatedIcon: AnimatedIcons.menu_close,
//         animatedIconTheme: const IconThemeData(size: 22.0),
//         // this is ignored if animatedIcon is non null
//         // child:const  Icon(Icons.add),
//         visible: true,
//         curve: Curves.bounceIn,
//         overlayColor: Colors.black,
//         overlayOpacity: 0.5,
//         onOpen: () {
//           ScaffoldMessenger.of(context).hideCurrentSnackBar();
//           _searchFocusNode.unfocus();
//         },
//         //onClose: () => //print('DIAL CLOSED'),
//         tooltip: 'Speed Dial',
//         heroTag: 'speed-dial-hero-tag-62345',
//         backgroundColor: hc_red,
//         foregroundColor: Colors.white,
//         elevation: 8.0,
//         shape: const CircleBorder(),
//         children: <SpeedDialChild>[
//           SpeedDialChild(
//             child: const Icon(Icons.filter_list),
//             backgroundColor: Colors.green,
//             label: 'Preset Filters',
//             labelStyle: TextStyle(
//               fontSize: 18.0 * (1.0 / deviceInfo.deviceTextScaleFactor),
//             ),
//             onTap: () {
//               _filterOptionsPopup();
//             },
//           ),
//           // SpeedDialChild(
//           //     child: const Icon(Icons.person_add),
//           //     backgroundColor: hc_blue,
//           //     label: 'Add Hasher to Harrier Central',
//           //     labelStyle: const TextStyle(fontSize: 18.0),
//           //     onTap: () {
//           //       Navigator.push<HashersModel>(
//           //         context,
//           //         MaterialPageRoute<HashersModel>(
//           //           builder: (BuildContext context) => HasherProfilePage(
//           //             dataContext: EnumDataContext.event,
//           //             pageType: EnumMyProfilePageType.newHasherProfile,
//           //             eventId: widget.eventAggregate.event.eventId,
//           //             kennelId: widget.eventAggregate.event.kennelId,
//           //             uiElementsToDisplay: HasherProfilePage.flagUiElement_followKennel,
//           //           ),
//           //         ),
//           //       ).then((HashersModel result) {
//           //         _refreshPackListFromTables(true);
//           //       });
//           //     }),
//           SpeedDialChild(
//             child: const Icon(FontAwesome.heart, color: Colors.white),
//             backgroundColor: hc_blue,
//             label: 'Add Virgin / Visitor',
//             labelStyle: TextStyle(
//               fontSize: 18.0 * (1.0 / deviceInfo.deviceTextScaleFactor),
//             ),
//             onTap: () => _showVirginVisitorPopup(context),
//           ),
//           SpeedDialChild(
//             child: const Icon(
//               MaterialCommunityIcons.account_search,
//               color: Colors.white,
//             ),
//             backgroundColor: hc_blue,
//             label: 'Find Hasher and add',
//             labelStyle: TextStyle(
//               fontSize: 18.0 * (1.0 / deviceInfo.deviceTextScaleFactor),
//             ),
//             onTap: () async => await _findHasher(),
//           ),
//           SpeedDialChild(
//             child: const Icon(
//               MaterialCommunityIcons.transfer_right,
//               color: Colors.white,
//             ),
//             backgroundColor: hc_blue,
//             label: 'Copy RSVPs from Previous run',
//             labelStyle: TextStyle(
//               fontSize: 18.0 * (1.0 / deviceInfo.deviceTextScaleFactor),
//             ),
//             onTap: () => _copyRsvpsFromLastRun(context),
//           ),
//           SpeedDialChild(
//             child: const Icon(
//               MaterialCommunityIcons.gesture_tap_button,
//               color: Colors.white,
//             ),
//             backgroundColor: Colors.deepOrange,
//             label: 'Enable multi-selection',
//             labelStyle: TextStyle(
//               fontSize: 18.0 * (1.0 / deviceInfo.deviceTextScaleFactor),
//             ),
//             onTap: () => _copyRsvpsFromLastRun(context),
//           ),
//           // SpeedDialChild(
//           //     child: const Icon(MaterialCommunityIcons.message_video),
//           //     backgroundColor: Colors.deepOrange,
//           //     label: 'View video tutorial',
//           //     labelStyle: TextStyle(
//           //       fontSize: 18.0 * (1.0 / deviceInfo.deviceTextScaleFactor),
//           //     ),
//           //     onTap: () => Navigator.push<dynamic>(
//           //           context,
//           //           MaterialPageRoute<dynamic>(
//           //               builder: (BuildContext context) => const VideoTutorialPage(
//           //                     title: 'How to use Check In Page',
//           //                     videoUrl: 'https://harriercentral.blob.core.windows.net/help-videos/rabbit.mp4',
//           //                   )),
//           //         )),
//           // if ((widget.eventAggregate.kennel.bankScheme != null) &&
//           //     (widget.eventAggregate.kennel.bankScheme !=
//           //         '')) ...<SpeedDialChild>[
//           //   SpeedDialChild(
//           //     child: const Icon(MaterialCommunityIcons.bank),
//           //     backgroundColor: Colors.purple,
//           //     label: 'Bank Transfer\r\n(Member)',
//           //     labelStyle: TextStyle(
//           //       fontSize: 18.0 * (1.0 / deviceInfo.deviceTextScaleFactor),
//           //     ),
//           //     onTap:
//           //         () => BankTransferQr.showBankTransferQrCode(
//           //           context,
//           //           widget.eventAggregate,
//           //           true,
//           //         ),
//           //   ),
//           //   SpeedDialChild(
//           //     child: const Icon(MaterialCommunityIcons.bank),
//           //     backgroundColor: Colors.purple,
//           //     label: 'Bank Transfer\r\n(Non-Member)',
//           //     labelStyle: TextStyle(
//           //       fontSize: 18.0 * (1.0 / deviceInfo.deviceTextScaleFactor),
//           //     ),
//           //     onTap:
//           //         () => BankTransferQr.showBankTransferQrCode(
//           //           context,
//           //           widget.eventAggregate,
//           //           false,
//           //         ),
//           //   ),
//           // ],
//         ],
//       ),
//       appBar: _getAppBar(
//         (_isLoading || (widget.eventAggregate.event.eventName.isEmpty))
//             ? '... Loading'
//             : '${widget.eventAggregate.event.eventName} Check In',
//       ),
//       body:
//           _isLoading
//               ? const HcAppCircularProgressIndicator(key: Key('430320291'))
//               : Stack(
//                 fit: StackFit.loose,
//                 alignment: AlignmentDirectional.topStart,
//                 children: <Widget>[
//                   SizedBox(
//                     height: MediaQuery.of(context).size.height,
//                     width: 10,
//                   ),
//                   (_filteredList.isEmpty)
//                       //? Positioned(top: showFilter ? 210 : 95, left:0, right: 0, child: getAddHasherBlock())
//                       ? Positioned(
//                         top: (_filterPanelAnimation.value.dy * 120) + 125,
//                         left: 0,
//                         right: 0,
//                         child: _getAddHasherBlock(),
//                       )
//                       : PositionedTransition(
//                         rect: _hasherListAnimation,
//                         child: SizedBox(
//                           key: _packListBoxKey,
//                           height: 300,
//                           child: _buildPackListView(),
//                         ),
//                       ),
//                   SlideTransition(
//                     position: _filterPanelAnimation,
//                     child: _filterBar(),
//                   ),
//                   Positioned(top: 0, child: _searchBar()),
//                 ],
//               ),
//     );
//   }

//   SnackBar _buildRsvpAndPaymentSnackbar(
//     BuildContext context,
//     ScaffoldState scaffoldState,
//     int index,
//   ) {
//     double amountOwed =
//         _filteredList[index].isMember != 1
//             ? widget.eventAggregate.extensions.nonMemberPrice
//             : widget.eventAggregate.extensions.memberPrice;

//     amountOwed =
//         _filteredList[index].isMember != 1
//             ? widget.eventAggregate.extensions.nonMemberPrice
//             : widget.eventAggregate.extensions.memberPrice;
//     amountOwed -= _filteredList[index].discountAmount;
//     amountOwed -= amountOwed * (_filteredList[index].discountPercent / 100.0);

//     final SnackBar snackbar = PaymentSnackBar(
//       context: context,
//       eventAggregate: widget.eventAggregate,
//       packMember: _filteredList[index],
//       amountOwed: amountOwed,
//       onRsvpCallback: (
//         CheckInPackModel packMember, {
//         int rsvpState = -1,
//         int attendenceState = -1,
//         int isHare = -1,
//       }) async {
//         ScaffoldMessenger.of(
//           context,
//         ).removeCurrentSnackBar(reason: SnackBarClosedReason.hide);
//         if ((rsvpState != -1) && (attendenceState == -1)) {
//           setState(() {
//             _filteredList[index] = packMember.copyWith(
//               rsvpStateIndicator: Future<int>.value(rsvpUpdating.value),
//             );
//           });
//           await _updateRsvpState(packMember, rsvpState, isHare);
//           setState(() {});
//         } else if (attendenceState != -1) {
//           setState(() {
//             _filteredList[index] = packMember.copyWith(
//               attendenceStateIndicator: Future<int>.value(
//                 attendenceUpdating.value,
//               ),
//               paidStateIndicator: Future<int>.value(isPaidUpdating.value),
//             );
//           });
//           await _updateAttendenceState(
//             packMember,
//             rsvpState,
//             attendenceState,
//             isHare,
//           );
//           setState(() {});
//         }
//       },
//       onPaidCallback: (
//         CheckInPackModel packMember,
//         int paymentType, {
//         OtherPaymentPopupResult? userInput,
//       }) async {
//         final double? totalDue = userInput?.totalAmount;
//         //final double topUpAmount = userInput['topUpAmount'];
//         final double? specialPriceAmount =
//             userInput == null
//                 ? null
//                 : userInput.specialPriceAmount ?? amountOwed;
//         final String? specialPriceReason = userInput?.specialPriceReason;
//         final bool? useSpecialPriceAsDefault =
//             userInput?.useSpecialPriceAsDefault;

//         setState(() {
//           _filteredList[index] = packMember.copyWith(
//             rsvpStateIndicator: Future<int>.value(rsvpUpdating.value),
//             attendenceStateIndicator: Future<int>.value(
//               attendenceUpdating.value,
//             ),
//             paidStateIndicator: Future<int>.value(isPaidUpdating.value),
//           );
//         });
//         await _payForEvent(
//           context,
//           scaffoldState,
//           paymentType,
//           index,
//           totalDue,
//           specialRunPrice: specialPriceAmount,
//           specialRunPriceReason: specialPriceReason,
//           useSpecialPriceAsDefault: useSpecialPriceAsDefault,
//         );
//       },
//     );

//     return snackbar;
//   }

//   Future<void> _payForEvent(
//     BuildContext context,
//     ScaffoldState scaffoldState,
//     int paymentType,
//     int index,
//     double? otherAmount, {
//     double? specialRunPrice,
//     String? specialRunPriceReason,
//     bool? useSpecialPriceAsDefault,
//   }) async {
//     ScaffoldMessenger.of(
//       context,
//     ).removeCurrentSnackBar(reason: SnackBarClosedReason.hide);
//     dynamic payForExtras = payForRunOnly;

//     if (((paymentType == paymentFreeRun.value) ||
//             (paymentType == paymentCash.value) ||
//             (paymentType == paymentBankTransfer.value) ||
//             (paymentType == paymentCashOtherAmount.value) ||
//             (paymentType == paymentHashCredit.value) ||
//             (paymentType == paymentBankTransferOtherAmount.value)) &&
//         ((widget.eventAggregate.event.eventPriceForExtras ?? 0) != 0)) {
//       final double runOnlyPrice =
//           _filteredList[index].isMember != 0
//               ? widget.eventAggregate.extensions.memberPrice
//               : widget.eventAggregate.extensions.nonMemberPrice;
//       final double runPlusExtrasPrice =
//           runOnlyPrice + (widget.eventAggregate.event.eventPriceForExtras!);

//       final String runOnlyPriceStr = IveCoreUtilities.getFormattedMoney(
//         runOnlyPrice,
//         widget.eventAggregate.extensions.digAfterDec,
//         widget.eventAggregate.extensions.curSym,
//       );
//       final String runPlusExtrasPriceStr = IveCoreUtilities.getFormattedMoney(
//         runPlusExtrasPrice,
//         widget.eventAggregate.extensions.digAfterDec,
//         widget.eventAggregate.extensions.curSym,
//       );

//       final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
//         <String, dynamic>{
//           'title': 'Run only ($runOnlyPriceStr)',
//           'icon': <Widget>[Container()],
//           'returnValue': payForRunOnly,
//         },
//         <String, dynamic>{
//           'title':
//               'Run + ${widget.eventAggregate.event.extrasDescription} ($runPlusExtrasPriceStr)',
//           'icon': <Widget>[Container()],
//           'returnValue': payForRunAndExtras,
//         },
//       ];

//       final MultipleChoicePopupHc popup = MultipleChoicePopupHc(
//         key: const Key('4555116132'),
//         title: 'Payment options',
//         buttons: buttons,
//         cancelButtonTitle: 'Cancel',
//         cancelButtonReturnValue: followTypeCancel,
//       );

//       payForExtras = await showDialog<dynamic>(
//         context: context,
//         barrierDismissible: false, // user must tap button!
//         builder: (BuildContext context) {
//           return popup;
//         },
//       );
//     }

//     final List<dynamic>? results = await _processPayment(
//       index,
//       paymentType,
//       otherAmount: otherAmount,
//       doPayForExtras: payForExtras,
//       specialRunPrice: specialRunPrice,
//       specialRunPriceReason: specialRunPriceReason,
//       useSpecialPriceAsDefault: useSpecialPriceAsDefault,
//     );
//     if (results != null) {
//       if ((results[0]['terminalWasUsedForPayment'] == null) ||
//           (!results[0]['terminalWasUsedForPayment'])) {
//         if (!mounted) return;
//         BankTransferQr.showBankTransferSnackbar(
//           widget.eventAggregate,
//           results,
//           paymentType,
//           navigatorKey.currentContext!,
//           _filteredList[index].nameForDisplay,
//           _filteredList[index].isMember,
//           otherAmount,
//         );
//       }
//     }
//     await _refreshPackListFromTables(false);
//     await _refreshCounters(true);
//   }

//   Future<List<dynamic>?> _processPayment(
//     int index,
//     int paymentType, {
//     double? otherAmount = -1,
//     EnumPayForExtras<int> doPayForExtras = payForRunOnly,
//     double? specialRunPrice,
//     String? specialRunPriceReason,
//     bool? useSpecialPriceAsDefault = false,
//   }) async {
//     //bool paymentCancelled = false;
//     bool terminalWasUsedForPayment = false;

//     setState(() {
//       _filteredList[index] = _filteredList[index].copyWith(
//         rsvpStateIndicator: Future<int>.value(rsvpUpdating.value),
//         attendenceStateIndicator: Future<int>.value(attendenceUpdating.value),
//         paidStateIndicator: Future<int>.value(isPaidUpdating.value),
//       );
//     });

//     final String? hemId = _filteredList[index].hemId;
//     final String? hasherId = _filteredList[index].hasherId;
//     double amount =
//         _filteredList[index].isMember != 0
//             ? widget.eventAggregate.extensions.memberPrice
//             : widget.eventAggregate.extensions.nonMemberPrice;
//     if ((otherAmount != null) && (otherAmount != -1)) {
//       amount = otherAmount;
//     }

//     final Random random = Random.secure();
//     final List<int> values = List<int>.generate(
//       6,
//       (int i) => random.nextInt(26),
//     );
//     final String randomString = String.fromCharCodes(
//       Iterable<int>.generate(values.length, (int i) => values[i] + 65),
//     );

//     String paymentReference = '';

//     // if (_useTerminalForPayment) {
//     //   // this is a bit of a hack to use this boolean to indicate if the
//     //   // payment terminal should be used. Maybe one day I'll clean this up.
//     //   _useTerminalForPayment = false;
//     //   terminalWasUsedForPayment = true;

//     //   double terminalAmount = amount;
//     //   if ((doPayForExtras == payForRunAndExtras) && (widget.eventAggregate.event.eventPriceForExtras != null)) {
//     //     terminalAmount += widget.eventAggregate.event.eventPriceForExtras!;
//     //   }

//     //   String? affiliateKey = getStringPref(StringPrefsEnum.paymentTerminalAccountKey);

//     //   if (affiliateKey != null) {
//     //     await Sumup.init(affiliateKey);

//     //     bool isLoggedIn = await Sumup.isLoggedIn ?? false;
//     //     if (!isLoggedIn) {
//     //       await Sumup.login();
//     //     }

//     //     final String title = '${widget.eventAggregate.event.eventName} (${packMember.nameForDisplay})';
//     //     paymentReference = 'HC:$randomString';

//     //     isLoggedIn = await Sumup.isLoggedIn ?? false;
//     //     if (isLoggedIn) {
//     //       final SumupPayment payment = SumupPayment(
//     //         title: title,
//     //         total: terminalAmount,
//     //         //             currency: widget.eventAggregate.extensions.curCode ?? widget.eventAggregate.kennel.currencyCode,
//     //         currency: widget.eventAggregate.extensions.curCode,
//     //         foreignTransactionId: paymentReference,
//     //         saleItemsCount: 1,
//     //         skipSuccessScreen: true,
//     //         tip: .0,
//     //       );

//     //       //"BGN" "BRL" "CHF" "CLP" "CZK" "DKK" "EUR" "GBP" "HRK" "HUF" "NOK" "PLN" "RON" "SEK" "USD"

//     //       final SumupPaymentRequest request = SumupPaymentRequest(payment);

//     //       request.info = <String, String>{
//     //         'hashName': 'packMember.nameForDisplay',
//     //         'foreignTransId': paymentReference,
//     //       };

//     //       final SumupPluginCheckoutResponse checkoutResult = await Sumup.checkout(request);
//     //       if (!(checkoutResult.success ?? false)) {
//     //         paymentCancelled = true;
//     //       } else {
//     //         if (checkoutResult.transactionCode != null) {
//     //           paymentReference = 'SU:${checkoutResult.transactionCode}';
//     //         }
//     //       }
//     //     }
//     //   }
//     // } else {
//     //   paymentReference = 'HC:$randomString';
//     // }

//     paymentReference = 'HC:$randomString';

//     // if (paymentCancelled) {
//     //   return null;
//     // }
//     // else
//     // {
//     final PaymentsService paySrv = PaymentsService();
//     final List<dynamic> result = await paySrv.payForEvent(
//       widget.eventAggregate.event.eventId,
//       ((hasherId?.length != GUID_EMPTY.length)) ? GUID_EMPTY : hasherId,
//       (((hemId?.length ?? 0) != GUID_EMPTY.length)) ? GUID_EMPTY : hemId,
//       paymentType,
//       amount,
//       attendenceAtHash.value,
//       doPayForExtras,
//       AppDomainType.event,
//       paymentReference: paymentReference,
//       specialRunPrice: specialRunPrice,
//       specialRunPriceReason: specialRunPriceReason,
//       useSpecialPriceAsDefault: useSpecialPriceAsDefault,
//     );

//     if (result.isNotEmpty) {
//       final Map<String, dynamic> m = result[0];
//       m.addAll(<String, dynamic>{
//         'terminalWasUsedForPayment': terminalWasUsedForPayment,
//       });
//     }

//     return result;
//   }
//   //}

//   static const double LIST_ITEM_LEFT_MARGIN = 88.0;

//   Widget _listItem(BuildContext context, int index) {
//     return GestureDetector(
//       onTap: () {
//         _searchFocusNode.unfocus();
//         if (widget.eventAggregate.extensions.appAccess.canManageRuns) {
//           final SnackBar snackBar = _buildRsvpAndPaymentSnackbar(
//             context,
//             _scaffoldKey.currentState!,
//             index,
//           );

//           ScaffoldMessenger.of(
//             context,
//           ).removeCurrentSnackBar(reason: SnackBarClosedReason.hide);
//           ScaffoldMessenger.of(context).showSnackBar(snackBar);
//         }
//       },
//       child: Container(
//         color:
//             ((widget.eventAggregate.event.isCountedRun == 1) &&
//                     (_filteredList[index].attendenceState >=
//                         attendenceAtHash.value) &&
//                     ((_checkSpecialRun(
//                           (_filteredList[index].totalRunsThisKennel) +
//                               (_filteredList[index].historicalTotalRunCount),
//                         )) ||
//                         ((_filteredList[index].isHare == 1) &&
//                             (_checkSpecialHaring(
//                               (_filteredList[index].totalHaringThisKennel) +
//                                   (_filteredList[index].historicalHaringCount),
//                             )))))
//                 ? Colors.amber.shade100
//                 : Colors.white,
//         width: MediaQuery.of(context).size.width,
//         child: Stack(
//           children: <Widget>[
//             Utilities.getProfilePic(
//               _filteredList[index].photo,
//               LIST_ITEM_HEIGHT,
//               LIST_ITEM_HEIGHT,
//               context,
//               _filteredList[index].nameForDisplay,
//             ),

//             Positioned(
//               left: LIST_ITEM_LEFT_MARGIN + 2.0,
//               top: 9.0,
//               child: Text(
//                 _filteredList[index].nameForDisplay,
//                 style: TextStyle(
//                   fontFamily:
//                       (_filteredList[index].isMember != 0)
//                           ? 'AvenirNextCondensedDemiBold'
//                           : 'AvenirNextCondensedMedium',
//                   fontStyle: FontStyle.normal,
//                   fontSize: 25.0,
//                   height: 1.0,
//                 ),
//               ),
//             ),

//             //(packMember.hcTotalRunCount + (packMember.historicalTotalRunCount)
//             if ((widget.eventAggregate.event.isCountedRun == 1) &&
//                 (_filteredList[index].attendenceState >=
//                     attendenceAtHash.value) &&
//                 ((_checkSpecialRun(
//                       (_filteredList[index].totalRunsThisKennel) +
//                           (_filteredList[index].historicalTotalRunCount),
//                     )) ||
//                     ((_filteredList[index].isHare == 1) &&
//                         (_checkSpecialHaring(
//                           (_filteredList[index].totalHaringThisKennel) +
//                               (_filteredList[index].historicalHaringCount),
//                         ))))) ...<Widget>[
//               Positioned(
//                 right: 8.0,
//                 top: 9.0,
//                 width: 35.0,
//                 height: 35.0,
//                 child: Image.asset('images/icons/beer_mug.png'),
//               ),
//             ],

//             // Positioned(
//             //   left: LIST_ITEM_LEFT_MARGIN + 2.0,
//             //   top: 32.0,
//             //   child: Text(
//             //     packMember.homeKennelName ?? '',
//             //     style: footnoteMedium,
//             //     overflow: TextOverflow.ellipsis,
//             //   ),
//             // ),
//             // this widget is here to grow the contents of the cell to a size that fills nearly the whole cell
//             // in order to give plenty of room for the tap gesture.
//             Positioned(
//               left: LIST_ITEM_LEFT_MARGIN,
//               top: 0,
//               child: Container(
//                 width: MediaQuery.of(context).size.width - 200,
//                 height: 65,
//                 color: Colors.transparent,
//               ),
//             ),

//             Positioned(
//               left: LIST_ITEM_LEFT_MARGIN + 0.0,
//               bottom: 5.0,
//               child: FutureBuilder<int>(
//                 future: _filteredList[index].rsvpStateIndicator,
//                 builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
//                   return Stack(
//                     alignment: AlignmentDirectional.center,
//                     children: <Widget>[
//                       Container(
//                         height: 30,
//                         width: 30,
//                         color: Colors.transparent,
//                       ),
//                       CircleAvatar(
//                         backgroundColor:
//                             ((snapshot.data == null) || (snapshot.data == 0))
//                                 ? Colors.grey[350]
//                                 : Colors.white,
//                         radius: 14.0,
//                       ),
//                       ((snapshot.data ?? 0) == 0)
//                           ? Container()
//                           : snapshot.data == rsvpUpdating.value
//                           ? Icon(delayIcon, color: hc_blue)
//                           : snapshot.data == rsvpNo.value
//                           ? Icon(
//                             FontAwesome.times_circle,
//                             color: hc_red,
//                             size: 27.0,
//                           )
//                           : snapshot.data == rsvpMaybe.value
//                           ? const Icon(
//                             FontAwesome.question_circle,
//                             color: Colors.orange,
//                             size: 27.0,
//                           )
//                           : _filteredList[index].isHare == 0
//                           ? const Icon(
//                             FontAwesome.check_circle,
//                             color: Colors.green,
//                             size: 27.0,
//                           )
//                           : Image.asset(
//                             'images/icons/hare_icon.png',
//                             color: Colors.deepPurple,
//                             height: 24.0,
//                             width: 24.0,
//                           ),
//                     ],
//                   );
//                 },
//               ),
//             ),

//             Positioned(
//               left: LIST_ITEM_LEFT_MARGIN + 35.0,
//               bottom: 5.0,
//               child: FutureBuilder<int>(
//                 future: _filteredList[index].attendenceStateIndicator,
//                 builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
//                   return Stack(
//                     alignment: AlignmentDirectional.center,
//                     children: <Widget>[
//                       Container(
//                         height: 30,
//                         width: 30,
//                         color: Colors.transparent,
//                       ),
//                       CircleAvatar(
//                         backgroundColor:
//                             ((snapshot.data == null) || (snapshot.data == 0))
//                                 ? Colors.grey[350]
//                                 : Colors.white,
//                         radius: 14.0,
//                       ),
//                       ((!snapshot.hasData) || ((snapshot.data) == 0))
//                           ? Container()
//                           : snapshot.data == attendenceUpdating.value
//                           ? Icon(delayIcon, color: hc_blue)
//                           : snapshot.data == attendenceNo.value
//                           ? Image.asset(
//                             'images/icons/not_at_hash_icon.png',
//                             height: 24.0,
//                             width: 24.0,
//                             color: hc_red,
//                           )
//                           : snapshot.data == attendenceAtHash.value
//                           ? Image.asset(
//                             'images/icons/runner_icon.png',
//                             height: 24.0,
//                             width: 24.0,
//                             color: Colors.orange,
//                           )
//                           : snapshot.data! >= attendenceOnIn.value
//                           ? Image.asset(
//                             'images/icons/beer_icon.png',
//                             height: 24.0,
//                             width: 24.0,
//                             color: Colors.green,
//                           )
//                           : Container(),
//                     ],
//                   );
//                 },
//               ),
//             ),

//             Positioned(
//               left: LIST_ITEM_LEFT_MARGIN + 70.0,
//               bottom: 5.0,
//               child: FutureBuilder<int>(
//                 future: _filteredList[index].paidStateIndicator,
//                 builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
//                   return Stack(
//                     alignment: AlignmentDirectional.center,
//                     children: <Widget>[
//                       Container(
//                         height: 30,
//                         width: 30,
//                         color: Colors.transparent,
//                       ),
//                       CircleAvatar(
//                         backgroundColor:
//                             ((snapshot.data == null) || (snapshot.data! < 0))
//                                 ? Colors.grey[350]
//                                 : Colors.white,
//                         radius: 14.0,
//                       ),
//                       ((snapshot.data ?? isPaidEmpty.value) ==
//                               isPaidEmpty.value)
//                           ? Container()
//                           : snapshot.data == isPaidUpdating.value
//                           ? Icon(delayIcon, color: hc_blue)
//                           : snapshot.data == isPaidNo.value
//                           ? Image.asset(
//                             'images/icons/dollar_sign_icon.png',
//                             height: 24.0,
//                             width: 24.0,
//                             color: hc_red,
//                           )
//                           : _filteredList[index].isPaid == isPaidYes.value
//                           ? Image.asset(
//                             'images/icons/payment_type_${_filteredList[index].paymentType}.png',
//                             height: 24.0,
//                             width: 24.0,
//                             color: Colors.green,
//                           )
//                           : Container(),
//                     ],
//                   );
//                 },
//               ),
//             ),

//             if (_filteredList[index].totalHaringThisKennel > 0)
//               Positioned(
//                 right: 4,
//                 bottom: 17,
//                 child: Text(
//                   'Hared = ${_filteredList[index].totalHaringThisKennel + (_filteredList[index].historicalHaringCount)}',
//                   style: _getHaringLabelStyle(
//                     _filteredList[index].totalHaringThisKennel +
//                         (_filteredList[index].historicalHaringCount),
//                     _filteredList[index].attendenceState,
//                     _filteredList[index].isHare,
//                   ),
//                 ),
//               ),
//             if (_filteredList[index].totalRunsThisKennel > 0)
//               Positioned(
//                 right: 4,
//                 bottom: 1,
//                 child: Text(
//                   'Total Runs = ${_filteredList[index].totalRunsThisKennel + (_filteredList[index].historicalTotalRunCount)}',
//                   style: _getRunLabelStyle(
//                     _filteredList[index].totalRunsThisKennel +
//                         (_filteredList[index].historicalTotalRunCount),
//                     _filteredList[index].attendenceState,
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   TextStyle _getRunLabelStyle(int numRuns, int attendenceState) {
//     if (widget.eventAggregate.event.isCountedRun == 0) {
//       return ts_mediumDarkGrey.copyWith(color: Colors.grey);
//     } else if (attendenceState >= attendenceAtHash.value) {
//       if (_checkSpecialRun(numRuns)) {
//         return ts_mediumRed;
//       }
//     }
//     return ts_mediumDarkGrey.copyWith(color: hc_blue);
//   }

//   TextStyle _getHaringLabelStyle(
//     int numHaring,
//     int attendenceState,
//     int isHare,
//   ) {
//     if (widget.eventAggregate.event.isCountedRun == 0) {
//       return ts_mediumDarkGrey.copyWith(color: Colors.grey);
//     } else if ((attendenceState >= attendenceAtHash.value) && (isHare == 1)) {
//       if (_checkSpecialHaring(numHaring)) {
//         return ts_mediumRed;
//       }
//     }
//     return ts_mediumDarkGrey.copyWith(color: hc_blue);
//   }

//   Future<void> _updateRsvpState(
//     CheckInPackModel packMember,
//     int rsvpState,
//     int isHare,
//   ) async {
//     final String? hasherId = packMember.hasherId;

//     if (kDebugMode) {
//       print('rsvpState = $rsvpState');
//     }

//     final List<dynamic> adHocData = await tableModel.hasherEventMapService
//         .setEventRsvp(
//           widget.eventAggregate.event.eventId,
//           hasherId,
//           AppDomainType.event,
//           rsvpState,
//           isHare: isHare,
//           hemId: packMember.hemId,
//         );

//     final String serverMessage = adHocData[0]['serverMessage'] ?? '';

//     if (serverMessage.isNotEmpty) {
//       await Utilities.showAlert('RSVP Result', serverMessage, 'OK');
//     }

//     await _refreshPackListFromTables(false);
//     await _refreshCounters(true);
//   }

//   Future<void> _updateAttendenceState(
//     CheckInPackModel packMember,
//     int rsvpState,
//     int attendenceState,
//     int isHare,
//   ) async {
//     await tableModel.hasherEventMapService.setEventAttendence(
//       widget.eventAggregate.event.eventId,
//       packMember.hasherId,
//       AppDomainType.event,
//       attendenceState,
//       hemId: packMember.hemId,
//     );

//     await _refreshPackListFromTables(false);
//     await _refreshCounters(true);
//   }

//   Widget _buildPackListView() {
//     //print('buildPackListView: ${DateTime.now().millisecondsSinceEpoch.toString()}');

//     return NotificationListener<ScrollNotification>(
//       onNotification: (ScrollNotification scrollNotification) {
//         if (scrollNotification is UserScrollNotification) {
//           _searchFocusNode.unfocus();
//           ScaffoldMessenger.of(context).hideCurrentSnackBar();
//         }
//         return true;
//       },
//       child: RefreshIndicator(
//         displacement: 120,
//         onRefresh: () async {
//           await _refreshSqlTablesFromBackend(true);
//         },
//         child: TextScaleFactorClamper(
//           textScaleFactor: deviceInfo.textClamp25,
//           child: ListView.separated(
//             separatorBuilder:
//                 (BuildContext context, int index) =>
//                     const Divider(height: 1.0, color: Colors.black45),
//             physics: const AlwaysScrollableScrollPhysics(),
//             scrollDirection: Axis.vertical,
//             controller: _scrollController,
//             itemCount: (_filteredList.length) + 2,
//             itemBuilder: (BuildContext context, int index) {
//               if (index == (_filteredList.length)) {
//                 return _getAddHasherBlock();
//               } else if (index == (_filteredList.length) + 1) {
//                 return const SizedBox(height: 120);
//               } else {
//                 double amountOwed =
//                     _filteredList[index].isMember != 1
//                         ? widget.eventAggregate.extensions.nonMemberPrice
//                         : widget.eventAggregate.extensions.memberPrice;

//                 amountOwed =
//                     _filteredList[index].isMember != 1
//                         ? widget.eventAggregate.extensions.nonMemberPrice
//                         : widget.eventAggregate.extensions.memberPrice;
//                 amountOwed -= _filteredList[index].discountAmount;
//                 amountOwed -=
//                     amountOwed * (_filteredList[index].discountPercent / 100.0);

//                 final String amountOwedStr = IveCoreUtilities.getFormattedMoney(
//                   amountOwed,
//                   widget.eventAggregate.extensions.digAfterDec,
//                   widget.eventAggregate.extensions.curSym,
//                 );

//                 CheckInPackModel packMember = _filteredList[index];

//                 return Slidable(
//                   key: Key(index.toString()),
//                   // controller: slidableController,

//                   // The start action pane is the one at the left or the top side.
//                   startActionPane: ActionPane(
//                     motion: const BehindMotion(),
//                     // A pane can dismiss the Slidable.
//                     dismissible: DismissiblePane(
//                       closeOnCancel: true,
//                       dismissThreshold: 0.65,
//                       dismissalDuration: const Duration(milliseconds: 800),
//                       resizeDuration: const Duration(milliseconds: 800),
//                       confirmDismiss: () async {
//                         if (packMember.isPaid != 1) {
//                           _payForEvent(
//                             context,
//                             _scaffoldKey.currentState!,
//                             paymentBankTransfer.value,
//                             index,
//                             -1,
//                           );
//                         }
//                         return false;
//                       },
//                       onDismissed: () {},
//                     ),
//                     dragDismissible: true,
//                     children: [
//                       CustomSlidableAction(
//                         // An action can be bigger than the others.
//                         flex: 2,
//                         onPressed: emptyFunction,
//                         backgroundColor:
//                             (packMember.isPaid == 1 ? Colors.grey : hc_blue),

//                         foregroundColor: Colors.white,
//                         child:
//                             packMember.isPaid == 1
//                                 ? Container(
//                                   color: Colors.grey,
//                                   width: deviceInfo.deviceWidth,
//                                   child: Column(
//                                     children: <Widget>[
//                                       const Padding(
//                                         padding: EdgeInsets.only(top: 5.0),
//                                         child: Icon(
//                                           FontAwesome.check_circle,
//                                           size: 30.0,
//                                           color: Colors.white,
//                                         ),
//                                       ),
//                                       Padding(
//                                         padding: const EdgeInsets.only(
//                                           top: 5.0,
//                                         ),
//                                         child: Text(
//                                           'Already\r\npaid',
//                                           textAlign: TextAlign.center,
//                                           style: ts_title,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 )
//                                 : Container(
//                                   color: hc_blue,
//                                   width: deviceInfo.deviceWidth,
//                                   child: Column(
//                                     children: <Widget>[
//                                       Padding(
//                                         padding: const EdgeInsets.only(
//                                           top: 8.0,
//                                         ),
//                                         child: Image.asset(
//                                           'images/icons/payment_type_4.png',
//                                           height: 27.0,
//                                           width: 27.0,
//                                           color: Colors.white,
//                                         ),
//                                       ),
//                                       Padding(
//                                         padding: const EdgeInsets.only(
//                                           top: 10.0,
//                                         ),
//                                         child: Text(
//                                           '${(widget.eventAggregate.event.eventPriceForExtras) != 0 ? '' : '$amountOwedStr\r\n'}Bank Transfer',
//                                           textAlign: TextAlign.center,
//                                           style: ts_titleMedium,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                       ),
//                     ],
//                   ),

//                   // The end action pane is the one at the right or the bottom side.
//                   endActionPane: ActionPane(
//                     motion: const BehindMotion(),
//                     // A pane can dismiss the Slidable.
//                     dismissible: DismissiblePane(
//                       closeOnCancel: true,
//                       dismissThreshold: 0.65,
//                       dismissalDuration: const Duration(milliseconds: 800),
//                       resizeDuration: const Duration(milliseconds: 800),
//                       confirmDismiss: () async {
//                         if (packMember.isPaid != 1) {
//                           _payForEvent(
//                             context,
//                             _scaffoldKey.currentState!,
//                             paymentCash.value,
//                             index,
//                             -1,
//                           );
//                         } else {
//                           _updateAttendenceState(
//                             packMember,
//                             -1,
//                             attendenceOnIn.value,
//                             -1,
//                           );
//                         }
//                         return false;
//                       },
//                       onDismissed: () {},
//                     ),
//                     dragDismissible: true,
//                     children: [
//                       CustomSlidableAction(
//                         // An action can be bigger than the others.
//                         flex: 2,
//                         onPressed: emptyFunction,
//                         backgroundColor:
//                             (packMember.isPaid == 1
//                                 ? packMember.attendenceState >=
//                                         attendenceOnIn.value
//                                     ? Colors.grey
//                                     : Colors.amber[800]
//                                 : Colors.green) ??
//                             Colors.white,

//                         foregroundColor: Colors.white,
//                         child:
//                             packMember.isPaid == 1
//                                 ? packMember.attendenceState >=
//                                         attendenceOnIn.value
//                                     ? Container(
//                                       width: deviceInfo.deviceWidth,
//                                       color: Colors.grey,
//                                       child: Column(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.end,
//                                         children: <Widget>[
//                                           const Padding(
//                                             padding: EdgeInsets.only(top: 5.0),
//                                             child: Icon(
//                                               FontAwesome.check_circle,
//                                               size: 30.0,
//                                               color: Colors.white,
//                                             ),
//                                           ),
//                                           Padding(
//                                             padding: const EdgeInsets.only(
//                                               top: 5.0,
//                                             ),
//                                             child: Text(
//                                               'Already\r\nOn-In',
//                                               textAlign: TextAlign.center,
//                                               style: ts_title,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     )
//                                     : Container(
//                                       color: Colors.amber[800],
//                                       width: deviceInfo.deviceWidth,
//                                       child: Column(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.end,
//                                         children: <Widget>[
//                                           const Padding(
//                                             padding: EdgeInsets.only(top: 2.0),
//                                             child: Icon(
//                                               Ionicons.ios_beer,
//                                               size: 30.0,
//                                               color: Colors.white,
//                                             ),
//                                           ),
//                                           Padding(
//                                             padding: const EdgeInsets.only(
//                                               top: 5.0,
//                                             ),
//                                             child: Text(
//                                               'Record as\r\nOn-In',
//                                               textAlign: TextAlign.center,
//                                               style: ts_title,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     )
//                                 : Container(
//                                   width: deviceInfo.deviceWidth,
//                                   color: Colors.green,
//                                   child: Column(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     mainAxisSize: MainAxisSize.max,
//                                     children: <Widget>[
//                                       Padding(
//                                         padding: const EdgeInsets.only(
//                                           bottom: 5.0,
//                                           top: 8.0,
//                                         ),
//                                         child: Image.asset(
//                                           'images/icons/payment_type_3.png',
//                                           height: 25.0,
//                                           width: 25.0,
//                                           color: Colors.white,
//                                         ),
//                                       ),
//                                       Padding(
//                                         padding: const EdgeInsets.only(
//                                           bottom: 5.0,
//                                         ),
//                                         child: Text(
//                                           '${(widget.eventAggregate.event.eventPriceForExtras ?? 0) != 0 ? '' : '$amountOwedStr\r\n'}Cash',
//                                           textAlign: TextAlign.center,
//                                           style: ts_title,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                       ),
//                     ],
//                   ),

//                   child: Container(
//                     color: Colors.white,
//                     child: _listItem(context, index),
//                   ),
//                 );
//               }
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   void emptyFunction(BuildContext context) {}

//   String _capitalizeFirstLetter(String s) =>
//       s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : s;

//   Widget _getAddHasherBlock() {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push<HashersModel>(
//           context,
//           MaterialPageRoute<HashersModel>(
//             builder:
//                 (BuildContext context) => HasherProfilePage(
//                   dataContext: EnumDataContext.event,
//                   pageType: EnumMyProfilePageType.newHasherProfile,
//                   eventId: widget.eventAggregate.event.eventId,
//                   kennelId: widget.eventAggregate.event.kennelId,
//                   uiElementsToDisplay:
//                       HasherProfilePage.flagUiElement_followKennel,
//                   hashNameFromSearch: _capitalizeFirstLetter(
//                     _searchController.text,
//                   ),
//                 ),
//           ),
//         ).then((HashersModel? result) {
//           if (result != null) {
//             _refreshPackListFromTables(true);
//             // NULLSAFETEST
//             // if (result.dispName == '') {
//             //   result = result.copyWith(dispName: null);
//             // }
//             // if (result.hashName == '') {
//             //   result = result.copyWith(hashName: null);
//             // }

//             _searchText = result.dispName;
//             _searchController.text = _searchText;
//             _filterPackListResults();
//           }
//         });
//       },
//       child: Container(
//         height: 80,
//         margin: const EdgeInsets.only(left: 10),
//         child: Row(
//           children: <Widget>[
//             Icon(SimpleLineIcons.question, size: 35.0, color: hc_red),
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.only(left: 14.0, right: 10.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: <Widget>[
//                     Text('Can\'t find a Hasher?', style: ts_contentStyle),
//                     AutoSizeText(
//                       'Click here to add \'${_capitalizeFirstLetter(_searchController.text)}\'',
//                       style: ts_contentStyle,
//                       maxLines: 1,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class AddVisitorVirginPopup extends StatefulWidget {
//   const AddVisitorVirginPopup({super.key});

//   @override
//   AddVisitorVirginPopupState createState() => AddVisitorVirginPopupState();
// }

// class AddVisitorVirginPopupState extends State<AddVisitorVirginPopup> {
//   final FocusNode myFocusNodeFirstName = FocusNode();

//   TextEditingController nameTextController = TextEditingController();
//   TextEditingController emailTextController = TextEditingController();
//   TextEditingController phoneTextController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return TextScaleFactorClamper(
//       textScaleFactor: deviceInfo.textClamp25,
//       child: AlertDialog(
//         title: Text('Add Visitor or Virgin', style: ts_alertDialogTitle),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: <Widget>[
//             TextField(
//               autofocus: true,
//               focusNode: myFocusNodeFirstName,
//               controller: nameTextController,
//               keyboardType: TextInputType.text,
//               style: ts_alertDialogBody,
//               decoration: InputDecoration(
//                 //border: InputBorder.none,
//                 icon: const Icon(
//                   MaterialCommunityIcons.run,
//                   color: Colors.black,
//                 ),
//                 hintText: 'Just Julie',
//                 hintStyle: ts_hint,
//               ),
//             ),
//             TextField(
//               autofocus: true,
//               //focusNode: myFocusNodeFirstName,
//               controller: emailTextController,
//               keyboardType: TextInputType.emailAddress,
//               style: ts_titleMediumBlack,
//               decoration: InputDecoration(
//                 //border: InputBorder.none,
//                 icon: const Icon(
//                   MaterialCommunityIcons.email,
//                   color: Colors.black,
//                 ),
//                 hintText: '(email - optional)',
//                 hintStyle: ts_hint,
//               ),
//             ),
//             TextField(
//               autofocus: true,
//               //focusNode: myFocusNodeFirstName,
//               controller: phoneTextController,
//               keyboardType: TextInputType.phone,
//               style: ts_titleMediumBlack,
//               decoration: InputDecoration(
//                 //border: InputBorder.none,
//                 icon: const Icon(Entypo.old_phone, color: Colors.black),
//                 hintText: '(phone # - optional)',
//                 hintStyle: ts_hint,
//               ),
//             ),
//           ],
//         ),
//         actions: <Widget>[
//           SizedBox(
//             height: 55,
//             child: TextButton(
//               style: TextButton.styleFrom(
//                 shape: button_shape,
//                 backgroundColor: hc_red,
//               ),
//               child: const Text(
//                 'Cancel',
//                 textAlign: TextAlign.center,
//                 //textScaleFactor: deviceInfo.textClamp15,
//               ),
//               onPressed: () {
//                 Navigator.of(
//                   context,
//                 ).pop(<String, String>{'type': 'cancel', 'amount': ''});
//               },
//             ),
//           ),

//           SizedBox(
//             height: 55.0,
//             child: TextButton(
//               style: TextButton.styleFrom(
//                 shape: button_shape,
//                 backgroundColor: hc_blue,
//               ),
//               child: const Text(
//                 'Add\r\nVisitor',
//                 textAlign: TextAlign.center,
//                 //textScaleFactor: deviceInfo.textClamp15,
//               ),
//               onPressed: () {
//                 Navigator.of(context).pop(<String, String>{
//                   'type': enumAnonymousVisitor.value.toString(),
//                   'name': nameTextController.text,
//                   'email': emailTextController.text,
//                   'phone': phoneTextController.text,
//                 });
//               },
//             ),
//           ),

//           SizedBox(
//             height: 55.0,
//             child: TextButton(
//               style: TextButton.styleFrom(
//                 shape: button_shape,
//                 backgroundColor: hc_blue,
//               ),
//               child: const Text(
//                 'Add\r\nVirgin',
//                 textAlign: TextAlign.center,
//                 //textScaleFactor: deviceInfo.textClamp15,
//               ),
//               onPressed: () {
//                 Navigator.of(context).pop(<String, String>{
//                   'type': enumVirgin.value.toString(),
//                   'name': nameTextController.text,
//                   'email': emailTextController.text,
//                   'phone': phoneTextController.text,
//                 });
//               },
//             ),
//           ),
//           // ),
//         ],
//       ),
//     );
//   }
// }
