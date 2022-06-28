// @dart=2.11

import 'package:harrier_central/imports.dart';

class CheckInPackModel {
  CheckInPackModel({
    this.hasherId,
    this.hemId,
    this.isMember,
    this.isHare,
    this.isPaid,
    this.nameForDisplay,
    this.nameForSort,
    this.paymentType,
    this.creditAmount,
    this.photo,
    this.virginVisitorType,
    this.rsvpState,
    this.attendenceState,
    this.discountPercent,
    this.discountAmount,
    this.rsvpStateIndicator,
    this.attendenceStateIndicator,
    this.paidStateIndicator,
    this.hcTotalRunCount,
    this.hcHaringCount,
    this.historicalTotalRunCount,
    this.historicalHaringCount,
    this.historicalCountIsEstimate,
    this.hemUpdatedAt,
    this.payUpdatedAt,
    this.credit,
    this.isFollowing,
  });

  final String hasherId;
  final String hemId;
  final int isMember;
  final int isHare;
  final int isPaid;
  final String nameForDisplay;
  final String nameForSort;
  final int paymentType;
  final num creditAmount;
  final String photo;
  final int virginVisitorType;
  final int rsvpState;
  final int attendenceState;
  final int discountPercent;
  final num discountAmount;
  Future<int> rsvpStateIndicator;
  Future<int> attendenceStateIndicator;
  Future<int> paidStateIndicator;
  final int hcTotalRunCount;
  final int hcHaringCount;
  final int historicalTotalRunCount;
  final int historicalHaringCount;
  final int historicalCountIsEstimate;
  final String hemUpdatedAt;
  final String payUpdatedAt;
  final num credit;
  final int isFollowing;

  static CheckInPackModel fromMap(Map<String, dynamic> map) {
    final CheckInPackModel item = CheckInPackModel(
        hasherId: map['hasherId'],
        hemId: map['hemId'],
        isMember: map['isMember'],
        isHare: map['isHare'],
        isPaid: map['isPaid'],
        nameForDisplay: map['nameForDisplay'],
        nameForSort: map['nameForSort'],
        paymentType: map['paymentType'],
        creditAmount: map['creditAmount'],
        photo: map['photo'],
        virginVisitorType: map['virginVisitorType'],
        rsvpState: map['rsvpState'],
        attendenceState: map['attendenceState'],
        rsvpStateIndicator: Future<int>.value(map['rsvpState']),
        attendenceStateIndicator: map['rsvpState'] != rsvpYes.value ? Future<int>.value(0) : Future<int>.value(map['attendenceState']),
        discountAmount: map['discountAmount'],
        discountPercent: map['discountPercent'],
        paidStateIndicator: map['attendenceState'] >= attendenceAtHash.value ? Future<int>.value(map['isPaid']) : Future<int>.value(-1),
        hcTotalRunCount: map['hcTotalRunCount'],
        hcHaringCount: map['hcHaringCount'],
        historicalTotalRunCount: map['historicalTotalRunCount'],
        historicalHaringCount: map['historicalHaringCount'],
        historicalCountIsEstimate: map['historicalCountIsEstimate'],
        hemUpdatedAt: map['hemUpdatedAt'],
        payUpdatedAt: map['payUpdatedAt'],
        isFollowing: map['isFollowing'],
        credit: map['credit']);
    return item;
  }
}

class CheckInPackPage extends StatefulWidget {
  const CheckInPackPage({Key key, @required this.eventAggregate}) : super(key: key);

  final RunAdminAggregate eventAggregate;

  @override
  State<CheckInPackPage> createState() {
    return CheckInPackPageState();
  }
}

enum FilterOptions { hashersNotHereYet, hashersStillOnTrail, hashersNotPaid, visitors, virgins, clearAllFilters, cancel }

class CheckInPackPageState extends State<CheckInPackPage> with SingleTickerProviderStateMixin {
  //final PackScopedModel _packScopedModel = PackScopedModel();
  //final PayScopedModel _payScopedModel = PayScopedModel();

  final GlobalKey _packListBoxKey = GlobalKey();

  bool _isLoading = true;
  final SlidableController _slidableController = SlidableController();

  List<CheckInPackModel> _packList;
  List<CheckInPackModel> _filteredList;
  List<CheckInPackModel> _allHashers;

  String _searchText = '';

  int _countAtHash = 0;
  //int _countRsvps = 0;
  int _countComing = 0;
  int _countPaid = 0;
  int _countOnIn = 0;
  int _memberCount = 0;
  int _drinkCount = 0;

  static const num LIST_ITEM_HEIGHT = 84.0;

  AnimationController _animationController;
  Animation<double> _buttonAnimation;
  Animation<Offset> _filterPanelAnimation;
  Animation<RelativeRect> _hasherListAnimation;
  final ScrollController _scrollController = ScrollController(initialScrollOffset: 0.0);
  FocusNode _searchFocusNode;
  TextEditingController _searchController;
  String _searchTypeText;
  bool _showFilter = false;

  bool _useTerminalForPayment = false;

  static const String _searchKennel = 'Searching Kennel members and RSVPs';
  static const String _searchAllHashers = 'Searching all Hashers';
  bool _highlightSearchType = false;

  final TextStyle _localFootnoteSmallRed = footnoteSmallRed.copyWith(fontSize: 12 * G0<DeviceInfo>().deviceWidthScaleFactor);
  final TextStyle _localFootnoteSmall = footnoteSmall.copyWith(fontSize: 12 * G0<DeviceInfo>().deviceWidthScaleFactor);

  List<int> _filterValues = <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

  @override
  void initState() {
    _searchTypeText = _searchKennel;
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();

    _getAllHashers().then((void _) {
      // get all Hashers first, then build the tables from the backend
      _refreshSqlTablesFromBackend(true);
    });
    super.initState();

    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _buttonAnimation = Tween<double>(begin: 0, end: 90.0 / 360.0).animate(_animationController)
      ..addListener(() {
        setState(() {});
      });
  }

  Future<void> _refreshSqlTablesFromBackend(bool showLoadingIndicator) async {
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus.connected) {
      if (showLoadingIndicator) {
        setState(() {
          _isLoading = true;
        });
      }

      await G0<TableModel>().syncEventAdminService.updateFromBackend(
          SyncEventAdminService.flagHashersTable | SyncEventAdminService.flagPaymentsTable | SyncEventAdminService.flagHasherEventMapTable | SyncEventAdminService.flagHasherKennelMapTable,
          true,
          widget.eventAggregate.event.eventId);
      //final String resultStr = result ? 'successfully' : 'unsuccessfully';
      //print('Payments data synchronized $resultStr');

      await _refreshPackListFromTables(false);
      await _refreshCounters(true);
    }
  }

  Future<void> _getAllHashers() async {
    _allHashers = <CheckInPackModel>[];

    try {
      final String sql = ''' 

          SELECT 
            -- get all hashers
            h.hasherId,
            null as hemId,
            coalesce(case when (julianday(hkm.${G0<TableModel>().hasherKennelMapTableHelper.colMembershipExpirationDate}) >= julianday('now','localtime')) then 1 else 0 end,0) as isMember,
            coalesce(hkm.${G0<TableModel>().hasherKennelMapTableHelper.colFollowing},0) as isFollowing,
            0 as isHare,
            0 as isPaid, 
            coalesce(h.dispName,h.hashName,coalesce(h.firstName,"") || " " || coalesce(h.lastName,"")) as nameForDisplay,
            lower(" " || coalesce(h.hashName,"") || " " || coalesce(h.dispName,"") || " " || coalesce(h.firstName,"") || " " || coalesce(h.lastName,"") || " ") as nameForSort,
            0 as paymentType,
            0 as creditAmount,
            h.photo,
            0 as virginVisitorType,
            0 as rsvpState,
            0 as attendenceState,
            null as hemUpdatedAt,
            null as payUpdatedAt,
            coalesce(hkm.${G0<TableModel>().hasherKennelMapTableHelper.colDiscountAmount},0) as discountAmount,
            coalesce(hkm.${G0<TableModel>().hasherKennelMapTableHelper.colDiscountPercent},0) as discountPercent,
            0 as credit
          FROM ${G0<TableModel>().hashersTableHelper.getTableName(AppDomainType.user)} h
          LEFT OUTER JOIN ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.event)} hkm on hkm.${G0<TableModel>().hasherKennelMapTableHelper.colUserId} = h.${G0<TableModel>().hashersTableHelper.colHasherId}
          ORDER BY nameForSort
          ''';

      final List<Map<String, dynamic>> results = await G0<Database>().rawQuery(sql);

      if (results.isNotEmpty) {
        for (int i = 0; i < results.length; i++) {
          final CheckInPackModel item = CheckInPackModel.fromMap(results[i]);
          _allHashers.add(item);
        }
      }

      //print('All hashers loaded @ ${DateTime.now().millisecondsSinceEpoch}');
    } catch (e) {
      //print(e);
    }
  }

  Future<void> _refreshPackListFromTables(bool forceRefresh) async {
    try {
      final String sql = ''' 

          SELECT 
            -- get all of the members of a Kennel and display them
            h.${G0<TableModel>().hashersTableHelper.colHasherId} as hasherId,
            hem.${G0<TableModel>().hasherEventMapTableHelper.colHemId} as hemId,
            case when (julianday(hkm.${G0<TableModel>().hasherKennelMapTableHelper.colMembershipExpirationDate}) >= julianday('now','localtime')) then 1 else 0 end as isMember,
            hkm.${G0<TableModel>().hasherKennelMapTableHelper.colFollowing} as isFollowing,
            coalesce(hem.${G0<TableModel>().hasherEventMapTableHelper.colIsHare},0) as isHare,
            CASE WHEN pay.${G0<TableModel>().paymentsTableHelper.colHemId} IS NULL THEN 0 ELSE 1 END as isPaid, 
            coalesce(h.${G0<TableModel>().hashersTableHelper.colDispName},h.${G0<TableModel>().hashersTableHelper.colHashName},coalesce(h.${G0<TableModel>().hashersTableHelper.colFirstName},"") || " " || coalesce(h.${G0<TableModel>().hashersTableHelper.colLastName},"")) as nameForDisplay,
            lower(" " || coalesce(h.${G0<TableModel>().hashersTableHelper.colHashName},"") || " " || coalesce(h.${G0<TableModel>().hashersTableHelper.colDispName},"") || " " || coalesce(h.${G0<TableModel>().hashersTableHelper.colFirstName},"") || " " || coalesce(h.${G0<TableModel>().hashersTableHelper.colLastName},"")) as nameForSort,
            coalesce(pay.${G0<TableModel>().paymentsTableHelper.colPaymentType},0) as paymentType,
            coalesce(pay.${G0<TableModel>().paymentsTableHelper.colCreditAmount},0) as creditAmount,
            h.${G0<TableModel>().hashersTableHelper.colPhoto} as photo,
            0 as virginVisitorType,
            coalesce(hem.${G0<TableModel>().hasherEventMapTableHelper.colRsvpState},0) as rsvpState,
            coalesce(hem.${G0<TableModel>().hasherEventMapTableHelper.colAttendenceState},0) as attendenceState,
            hem.${G0<TableModel>().hasherEventMapTableHelper.colUpdatedAt} as hemUpdatedAt,
            pay.${G0<TableModel>().paymentsTableHelper.colUpdatedAt} as payUpdatedAt,
            coalesce(credits.currentBalance,0) as credit,
            coalesce(hkm.${G0<TableModel>().hasherKennelMapTableHelper.colDiscountAmount},0) as discountAmount,
            coalesce(hkm.${G0<TableModel>().hasherKennelMapTableHelper.colDiscountPercent},0) as discountPercent,
            hkm.${G0<TableModel>().hasherKennelMapTableHelper.colHcTotalRunCount} as hcTotalRunCount,
            hkm.${G0<TableModel>().hasherKennelMapTableHelper.colHcHaringCount} as hcHaringCount,
            hkm.${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalTotalRunCount} as historicalTotalRunCount,
            hkm.${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalHaringCount} as historicalHaringCount,
            hkm.${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalCountIsEstimate} as historicalCountIsEstimate
          FROM ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.event)} hkm
          INNER JOIN ${G0<TableModel>().hashersTableHelper.getTableName(AppDomainType.user)} h on h.hasherId = hkm.userId
          LEFT OUTER JOIN ${G0<TableModel>().hasherEventMapTableHelper.getTableName(AppDomainType.event)} hem on hem.userId = hkm.userId and hem.eventId = "${widget.eventAggregate.event.eventId}"
          LEFT OUTER JOIN ${G0<TableModel>().paymentsTableHelper.getTableName(AppDomainType.event)} pay on pay.hemId = hem.hemId and pay.cancelledBy IS NULL
          LEFT OUTER JOIN ${G0<TableModel>().kennelCreditsTableHelper.getTableName(AppDomainType.event)} credits on credits.userId = hkm.userId and credits.kennelId = hkm.kennelId
    
          WHERE hkm.kennelId = "${widget.eventAggregate.event.kennelId}" 
            AND coalesce(hem.virginVisitorType,0) = 0
            AND (
              hkm.isKennelFollowing = 1
              OR 
              (
                hkm.isKennelFollowing = 0
                AND 
                (
                  julianday(hkm.membershipExpirationDate) >= julianday('now','localtime') -- is a member
                  OR
                  julianday(hkm.dateOfLastRun) >= julianday('now','localtime','-2 months')
                )
              )
            )
          UNION
          SELECT 
            -- now get all virgins & visitors
            null as hasherId,
            coalesce(hem2.hemId,"00000000-0000-0000-0000-000000000000") as hemId,
            0 as isMember,
            0 as isFollowing,
            hem2.isHare as isHare,
            CASE WHEN pay2.hemId IS NULL THEN 0 ELSE 1 END as isPaid, 
            coalesce(hem2.displayName,CASE WHEN hem2.virginVisitorType = 3 THEN h2.dispName ELSE "<no name>" END) || CASE WHEN hem2.virginVisitorType = 1 THEN " (virgin)" ELSE " (visitor)" END as nameForDisplay,
            lower(coalesce(hem2.displayName,CASE WHEN hem2.virginVisitorType = 3 THEN " " || coalesce(h2.dispName,h2.hashName,coalesce(h2.firstName,"") || " " || coalesce(h2.lastName,"")) || " " ELSE "<no name>" END) || CASE WHEN hem2.virginVisitorType = 1 THEN " (virgin)" ELSE " (visitor)" END) as nameForSort,
            coalesce(pay2.paymentType,0) as paymentType,
            coalesce(pay2.creditAmount,0) as creditAmount,
            CASE WHEN hem2.virginVisitorType = 1 THEN "https://harriercentral.blob.core.windows.net/harrier/Virgin.png" ELSE "https://harriercentral.blob.core.windows.net/harrier/Visitor.png" END as photo,
            coalesce(hem2.virginVisitorType,1) as virginVisitorType,
            coalesce(hem2.rsvpState,0) as rsvpState,
            coalesce(hem2.attendenceState,0) as attendenceState,
            hem2.updatedAt as hemUpdatedAt,
            pay2.updatedAt as payUpdatedAt,
            0 as credit,
            0 as ${G0<TableModel>().hasherKennelMapTableHelper.colDiscountAmount},
            0 as ${G0<TableModel>().hasherKennelMapTableHelper.colDiscountPercent},
            null as ${G0<TableModel>().hasherKennelMapTableHelper.colHcTotalRunCount},
            null as ${G0<TableModel>().hasherKennelMapTableHelper.colHcHaringCount},
            null as ${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalTotalRunCount},
            null as ${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalHaringCount},
            null as ${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalCountIsEstimate}
            FROM ${G0<TableModel>().hasherEventMapTableHelper.getTableName(AppDomainType.event)} hem2 
            INNER JOIN ${G0<TableModel>().hashersTableHelper.getTableName(AppDomainType.user)} h2 on h2.hasherId = hem2.userId
            LEFT OUTER JOIN ${G0<TableModel>().paymentsTableHelper.getTableName(AppDomainType.event)} pay2 on pay2.hemId = hem2.hemId and pay2.cancelledBy IS NULL
            WHERE hem2.eventId = "${widget.eventAggregate.event.eventId}" and hem2.virginVisitorType != 0
          UNION
          SELECT 
            -- now get all Hashers who are in HC and have RSVP'ed but are not members of the kennel
            hem3.userId as hasherId,
            hem3.hemId as hemId,
            0 as isMember,
            hkm4.${G0<TableModel>().hasherKennelMapTableHelper.colFollowing} as isFollowing,
            hem3.isHare as isHare,
            CASE WHEN pay3.hemId IS NULL THEN 0 ELSE 1 END as isPaid, 
            coalesce(h3.dispName,h3.hashName,coalesce(h3.firstName,"") || " " || coalesce(h3.lastName,"")) as nameForDisplay,    
            lower(coalesce(h3.dispName,h3.hashName,"") || " " || coalesce(h3.lastName,"") || " " || coalesce(h3.firstName,"")) as nameForSort,
            coalesce(pay3.paymentType,0) as paymentType,
            coalesce(pay3.creditAmount,0) as creditAmount,
            h3.photo as photo,
            hem3.virginVisitorType as virginVisitorType,
            coalesce(hem3.rsvpState,0) as rsvpState,
            coalesce(hem3.attendenceState,0) as attendenceState,
            hem3.updatedAt as hemUpdatedAt,
            pay3.updatedAt as payUpdatedAt,
            coalesce(credits3.currentBalance,0) as credit,
            coalesce(hkm4.${G0<TableModel>().hasherKennelMapTableHelper.colDiscountAmount},0) as discountAmount,
            coalesce(hkm4.${G0<TableModel>().hasherKennelMapTableHelper.colDiscountPercent},0) as discountPercent,
            hkm4.${G0<TableModel>().hasherKennelMapTableHelper.colHcTotalRunCount},
            hkm4.${G0<TableModel>().hasherKennelMapTableHelper.colHcHaringCount},
            hkm4.${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalTotalRunCount},
            hkm4.${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalHaringCount},
            hkm4.${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalCountIsEstimate}
            
            FROM ${G0<TableModel>().hasherEventMapTableHelper.getTableName(AppDomainType.event)} hem3
            INNER JOIN ${G0<TableModel>().hashersTableHelper.getTableName(AppDomainType.user)} h3 on h3.hasherId = hem3.userId
            LEFT OUTER JOIN ${G0<TableModel>().paymentsTableHelper.getTableName(AppDomainType.event)} pay3 on pay3.hemId = hem3.hemId and pay3.cancelledBy IS NULL
            LEFT OUTER JOIN ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.event)} hkm3 on hkm3.userId = h3.hasherId and hkm3.kennelId = "${widget.eventAggregate.event.kennelId}" AND julianday(hkm3.membershipExpirationDate) >= julianday('now','localtime')
            LEFT OUTER JOIN ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.event)} hkm4 on hkm4.userId = h3.hasherId and hkm4.kennelId = "${widget.eventAggregate.event.kennelId}" 
            LEFT OUTER JOIN ${G0<TableModel>().kennelCreditsTableHelper.getTableName(AppDomainType.user)} credits3 on credits3.userId = hkm3.userId and credits3.kennelId = hkm3.kennelId
            WHERE hem3.eventId = "${widget.eventAggregate.event.eventId}" 
              AND hem3.virginVisitorType = 0 
              AND  
              (
                (
                  hkm4.userId IS NULL
                )  
                OR NOT
                (
                  hkm4.isKennelFollowing = 1
                  OR 
                    (
                      hkm4.isKennelFollowing = 0
                AND 
                (
                  julianday(coalesce(hkm4.membershipExpirationDate,'2000-01-01T01:00:00.000Z')) >= julianday('now','localtime') -- is a member
                  OR
                  julianday(coalesce(hkm4.dateOfLastRun,'2000-01-01T01:00:00.000Z')) >= julianday('now','localtime','-2 months')
                )
              ) 
            )          
          )   

          ORDER BY nameForSort
            
          
          ''';

      List<Map<String, dynamic>> results;

      try {
        results = await G0<Database>().rawQuery(sql);
      } catch (x) {
        //print(x);
      }

      setState(() {
        if (results.isNotEmpty) {
          _packList = <CheckInPackModel>[];
          for (int i = 0; i < results.length; i++) {
            final CheckInPackModel item = CheckInPackModel.fromMap(results[i]);
            if (item.nameForDisplay.toLowerCase().startsWith('placeholder user')) {
              continue;
            }
            _packList.add(item);
          }

          setState(() {
            _isLoading = false;
          });
        }

        //print('Pack records retreived @ ${DateTime.now().millisecondsSinceEpoch}');

        _filterPackListResults();
      });
    } catch (e) {
      //print(e);
    }
  }

  void _filterPackListResults() {
    //bool showSnackbar = false;
    //bool searchingAllHashers = false;

    bool ignoreTextFilter = false;
    final String temp = _searchTypeText;

    if (_showFilter) {
      _filteredList = _packList
          .where((CheckInPackModel a) =>
              ((_filterValues[0] == 0) || (_filterValues[0] == -1 && ((a.rsvpState ?? 0) <= 1)) || (_filterValues[0] == 1 && (a.rsvpState ?? 0) >= 2)) &&
              ((_filterValues[1] == 0)
                  //|| (filterValues[1] == -1 && ((a.attendenceState ?? 0) < 20))
                  ||
                  (_filterValues[1] == 1 && (a.attendenceState ?? 0) < 20 && (a.rsvpState ?? 0) >= 2)) &&
              ((_filterValues[2] == 0) || (_filterValues[2] == -1 && ((a.attendenceState ?? 0) < 20)) || (_filterValues[2] == 1 && (a.attendenceState ?? 0) >= 20)) &&
              ((_filterValues[3] == 0) || (_filterValues[3] == -1 && ((a.isPaid ?? 0) == 0)) || (_filterValues[3] == 1 && (a.isPaid ?? 0) == 1)) &&
              ((_filterValues[4] == 0) || (_filterValues[4] == -1 && ((a.attendenceState ?? 0) < 30)) || (_filterValues[4] == 1 && (a.attendenceState ?? 0) >= 30)) &&
              ((_filterValues[5] == 0) || (_filterValues[5] == -1 && ((a.isMember ?? 0) == 0)) || (_filterValues[5] == 1 && (a.isMember ?? 0) == 1)) &&
              ((_filterValues[6] == 0) ||
                  (_filterValues[6] == -1) ||
                  (_filterValues[6] == 1 && ((a.attendenceState ?? 0) >= 20) && (_checkSpecialRun((a.historicalTotalRunCount ?? 0) + (a.hcTotalRunCount ?? 0))))))
          .toList();

      _filteredList.sort((CheckInPackModel a, CheckInPackModel b) => a.nameForDisplay.compareTo(b.nameForDisplay));
    } else {
      _filteredList = <CheckInPackModel>[];
      _filteredList.addAll(_packList);
    }

    if ((_searchText != null) && (_searchText.isNotEmpty)) {
      _filteredList = _filteredList.where((CheckInPackModel a) => a.nameForSort.toLowerCase().contains(_searchText.toLowerCase())).toList();
      if (_filteredList.isEmpty) {
        // if (!ignoreTextFilter) {
        //   showSnackbar = true;
        // }
        ignoreTextFilter = true;
        _filteredList = _allHashers.where((CheckInPackModel a) => a.nameForSort.toLowerCase().contains(_searchText.toLowerCase())).toList();
      } else {
        ignoreTextFilter = false;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    } else {
      _searchTypeText = _searchKennel;
    }

    _searchTypeText = ignoreTextFilter ? _searchAllHashers : _searchKennel;

    if (temp != _searchTypeText) {
      _highlightSearchType = true;
      Future<void>.delayed(const Duration(milliseconds: 1500)).then((void _) {
        setState(() {
          _highlightSearchType = false;
        });
      });
    }
  }

  Future<void> _refreshCounters(bool forceRefresh) async {
    try {
      final String sql = ''' 

          SELECT 
              -- COUNT(CASE WHEN rsvpState >= 2 THEN 1 ELSE NULL END) as rsvps,
              COUNT(CASE WHEN attendenceState >= 20 THEN 1 ELSE NULL END) as atHash,
              COUNT(CASE WHEN pay.paymentType >= 2 THEN 1 ELSE NULL END) as paid,
              COUNT(CASE WHEN rsvpState >= 2 AND attendenceState < 20 THEN 1 ELSE NULL END) as coming,
              COUNT(CASE WHEN attendenceState >= 30 THEN 1 ELSE NULL END) as onIn,
              (SELECT COUNT(*) FROM ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.event)} hkm WHERE hkm.kennelId = "${widget.eventAggregate.event.kennelId}" and hkm.isMember = 1) as memberCount
          FROM ${G0<TableModel>().hasherEventMapTableHelper.getTableName(AppDomainType.event)} hem
          LEFT OUTER JOIN ${G0<TableModel>().paymentsTableHelper.getTableName(AppDomainType.event)} pay on pay.hemId = hem.hemId and pay.cancelledBy IS NULL
  
          ''';

      final List<Map<String, dynamic>> results = await G0<Database>().rawQuery(sql);
      if (results.isNotEmpty) {
        //_countRsvps = results[0]['rsvps'];
        _countAtHash = results[0]['atHash'];
        _countComing = results[0]['coming'];
        _countOnIn = results[0]['onIn'];
        _countPaid = results[0]['paid'];
        _memberCount = results[0]['memberCount'];
      }

      if (_packList != null) {
        final List<CheckInPackModel> specialRunNumbers =
            _packList.where((CheckInPackModel a) => ((a.attendenceState ?? 0) >= 20) && (_checkSpecialRun((a.historicalTotalRunCount ?? 0) + (a.hcTotalRunCount ?? 0)))).toList();
        _drinkCount = specialRunNumbers.length;
      } else {
        _drinkCount = 0;
      }

      if (forceRefresh) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      //print(e);
    }
  }

  void _findHasher() {
    Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute<Map<String, dynamic>>(
        settings: const RouteSettings(),
        builder: (BuildContext context) {
          return FindHasherPage(FindHasherPageType.addHasherToRun, kennelId: widget.eventAggregate.event.kennelId, eventId: widget.eventAggregate.event.eventId);
        },
      ),
    ).then((Map<String, dynamic> result) {
      if ((result != null) && (result['hasher']?.hasherId != null)) {
        final Future<List<dynamic>> retVal = G0<TableModel>().hasherEventMapService.joinEvent(
              widget.eventAggregate.event.eventId,
              result['hasher'].hasherId,
              null,
              AppDomainType.event,
              rsvpState: rsvpYes.value,
              attendenceState: attendenceAtHash.value,
              isHare: isHareNo.value,
              virginVisitorType: result['virginVisitorType'],
            );

        retVal.then((List<dynamic> adHocData) {
          _refreshPackListFromTables(false).then((void _) {
            _refreshCounters(true);
          });
        });
      }
    });
  }

  void _showVirginVisitorPopup(BuildContext parentContext) {
    int scrollIndex = -1;

    const AddVisitorVirginPopup addVirginVisitorPopup = AddVisitorVirginPopup();

    final Future<Map<String, String>> dlg = showDialog<Map<String, String>>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return addVirginVisitorPopup;
        });

    dlg.then((Map<String, String> x) {
      final String name = x['name'];
      final String type = x['type'];
      final String email = x['email'] ?? '';
      final String phoneNumber = x['phone'] ?? '';

      EnumVirginVisitor<int> evv = enumVirgin;
      if (type == enumAnonymousVisitor.value.toString()) {
        evv = enumAnonymousVisitor;
      }

      if (type != 'cancel') {
        setState(() {
          _isLoading = true;
        });
        final Future<List<dynamic>> retVal = G0<TableModel>().hasherEventMapService.joinEventAsVisitor(
              widget.eventAggregate.event.eventId,
              name,
              evv.value,
              attendenceUnknown.value,
              email,
              phoneNumber,
              AppDomainType.event,
            );

        retVal.then((List<dynamic> adHocData) {
          _refreshPackListFromTables(false).then((void _) {
            _refreshCounters(true);
            // if (name?.isNotEmpty ?? false) {
            //   searchText = name;
            //   searchController.text = searchText;
            //   filterPackListResults();
            // }

            setState(() {
              _isLoading = false;
            });

            if (widget.eventAggregate.extensions.appAccess.canManageRuns) {
              if ((adHocData != null) && (adHocData.isNotEmpty)) {
                final String hem = adHocData[0]['hasherEventMapId'].toString().toLowerCase();
                scrollIndex = _packList.indexWhere((CheckInPackModel k) => k.hemId.toString().toLowerCase() == hem);
                if ((scrollIndex ?? -1) >= 0) {
                  final CheckInPackModel hasher = _packList[scrollIndex];
                  if (hasher != null) {
                    final SnackBar snackBar = _buildRsvpAndPaymentSnackbar(context, _scaffoldKey.currentState, hasher);

                    ScaffoldMessenger.of(context).removeCurrentSnackBar(reason: SnackBarClosedReason.hide);
                    ScaffoldMessenger.of(context).showSnackBar(snackBar).closed.then((SnackBarClosedReason reason) {
                      setState(() {
                        if ((scrollIndex ?? -1) >= 0) {
                          if (_scrollController.hasClients) {
                            _scrollController.animateTo(scrollIndex * LIST_ITEM_HEIGHT, duration: const Duration(seconds: 1), curve: Curves.ease);
                          }
                        }
                      });
                    });
                  }
                }
              }
            }
          });
        });
      }
    });

    // dlg.whenComplete(action)
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  AppBar _getAppBar(String title) {
    return AppBar(
      centerTitle: true,
      backgroundColor: themeAppBarBackground,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }

  Container _searchBar() {
    return Container(
      decoration: const BoxDecoration(
        // border: new Border.all(width: 1.0, color: Colors.black),
        //shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color.fromARGB(70, 0, 0, 0),
            offset: Offset(0.0, 6.0),
            blurRadius: 10.0,
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 10),
      width: MediaQuery.of(context).size.width,
      height: 85,
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              RotationTransition(
                turns: _buttonAnimation,
                child: IconButton(
                  padding: const EdgeInsets.all(0),
                  onPressed: () {
                    _searchFocusNode.unfocus();
                    if (_showFilter) {
                      _animationController.reverse();
                    } else {
                      _animationController.forward();
                    }
                    _showFilter = !_showFilter;
                    // searchController.text = '';
                    // searchText = '';
                    _refreshPackListFromTables(true);
                  },
                  icon: Icon(FontAwesome5Solid.arrow_alt_circle_right, size: 35, color: _showFilter ? Colors.green : Colors.grey),
                ),
              ),
              Container(
                height: 60,
                margin: const EdgeInsets.only(left: 3, right: 10),
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Colors.black, width: 1.0),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            autocorrect: false,
                            onChanged: (String text) {
                              setState(() {
                                _searchText = text;
                                _filterPackListResults();
                              });
                            },
                            focusNode: _searchFocusNode,
                            controller: _searchController,
                            keyboardType: TextInputType.text,
                            style: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0, color: Colors.black),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              icon: Icon(
                                FontAwesome.search,
                                color: Colors.black,
                              ),
                              hintText: 'Enter Hash or mortal name',
                              hintStyle: TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: TextButton(
                            style: TextButton.styleFrom(backgroundColor: Colors.white),
                            child: Text('X', style: TextStyle(color: Colors.grey.shade700)),
                            onPressed: () {
                              _searchController.text = '';
                              _searchText = '';
                              setState(() {
                                _filterPackListResults();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    Text(_searchTypeText, style: _highlightSearchType ? _localFootnoteSmallRed : _localFootnoteSmall)
                  ],
                ),
              ),
              SizedBox(
                width: 40,
                child: TextButton(
                  style: TextButton.styleFrom(textStyle: TextStyle(color: Colors.grey.shade700), backgroundColor: Colors.white),
                  child: Text('X', style: headingStyle20Black.copyWith(color: Colors.grey.shade700)),
                  onPressed: () {
                    _searchController.text = '';
                    _searchText = '';
                    _refreshPackListFromTables(true);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Container _filterBar() {
    return Container(
      decoration: const BoxDecoration(
        // border: new Border.all(width: 1.0, color: Colors.black),
        //shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color.fromARGB(70, 0, 0, 0),
            offset: Offset(0.0, 6.0),
            blurRadius: 10.0,
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 10),
      width: MediaQuery.of(context).size.width,
      height: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          CheckinFiltersCell(
            counter: _memberCount,
            label: 'Member',
            index: 5,
            onTap: () {
              _refreshPackListFromTables(true);
            },
            filterValues: _filterValues,
          ),
          // CheckinFiltersCell(
          //   counter: countRsvps,
          //   label: 'RSVP',
          //   index: 0,
          //   onTap: () {
          //     _refreshPackListFromTables(true);
          //   },
          //   filterValues: filterValues,
          // ),
          CheckinFiltersCell(
            counter: _countComing,
            label: 'Coming',
            index: 1,
            useTriState: false,
            onTap: () {
              _refreshPackListFromTables(true);
            },
            filterValues: _filterValues,
          ),
          CheckinFiltersCell(
            counter: _countAtHash,
            index: 2,
            label: 'At Hash',
            onTap: () {
              _refreshPackListFromTables(true);
            },
            filterValues: _filterValues,
          ),
          CheckinFiltersCell(
            counter: _countPaid,
            index: 3,
            label: 'Paid',
            onTap: () {
              _refreshPackListFromTables(true);
            },
            filterValues: _filterValues,
          ),
          CheckinFiltersCell(
            counter: _countOnIn,
            index: 4,
            label: 'On In',
            onTap: () {
              _refreshPackListFromTables(true);
            },
            filterValues: _filterValues,
          ),
          CheckinFiltersCell(
            counter: _drinkCount,
            index: 6,
            useTriState: false,
            label: 'Drink!',
            onTap: () {
              _refreshPackListFromTables(true);
            },
            filterValues: _filterValues,
          ),
        ],
      ),
    );
  }

  void _filterOptionsPopup() {
    final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
      <String, dynamic>{
        'title': 'Hashers not here yet',
        'icon': <Widget>[Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)), const Icon(FontAwesome.check_circle, color: Colors.green)],
        'returnValue': FilterOptions.hashersNotHereYet
      },
      <String, dynamic>{
        'title': 'Hashers still on trail',
        'icon': <Widget>[
          Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          Image.asset('images/icons/runner_icon.png', height: 25, width: 25, color: Colors.orange),
        ],
        'returnValue': FilterOptions.hashersStillOnTrail
      },
      <String, dynamic>{
        'title': 'Hashers who have not paid',
        'icon': <Widget>[
          Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          Image.asset('images/icons/dollar_sign_icon.png', height: 25, width: 25, color: Colors.red),
        ],
        'returnValue': FilterOptions.hashersNotPaid
      },
      <String, dynamic>{
        'title': 'Visitors',
        'icon': <Widget>[
          Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          const Positioned(bottom: 2, child: Icon(MaterialCommunityIcons.alpha_v_circle, size: 30, color: Colors.purple))
        ],
        'returnValue': FilterOptions.visitors
      },
      <String, dynamic>{
        'title': 'Virgins',
        'icon': <Widget>[
          Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          Positioned(bottom: 2, child: Icon(MaterialCommunityIcons.alpha_v_circle, size: 30, color: Colors.pink[300]))
        ],
        'returnValue': FilterOptions.virgins
      },
      <String, dynamic>{
        'title': 'Clear all filters',
        'icon': <Widget>[
          Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          const Positioned(bottom: 2, child: Icon(Ionicons.md_remove_circle, size: 30, color: Colors.teal))
        ],
        'returnValue': FilterOptions.clearAllFilters
      },
    ];

    final MultipleChoicePopup popup = MultipleChoicePopup(
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
        }).then((dynamic retVal) {
      switch (retVal) {
        case FilterOptions.hashersNotHereYet:
          _filterValues = <int>[0, 1, 0, 0, 0, 0, 0, 0, 0, 0];
          _searchText = '';
          _searchController.text = '';
          break;
        case FilterOptions.hashersNotPaid:
          _filterValues = <int>[0, 0, 1, -1, 0, 0, 0, 0, 0, 0];
          _searchText = '';
          _searchController.text = '';
          break;
        case FilterOptions.hashersStillOnTrail:
          _filterValues = <int>[0, 0, 1, 0, -1, 0, 0, 0, 0, 0];
          _searchText = '';
          _searchController.text = '';
          break;
        case FilterOptions.clearAllFilters:
          _filterValues = <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
          _searchText = '';
          _searchController.text = '';
          break;
        case FilterOptions.visitors:
          _filterValues = <int>[0, 0, 1, 0, 0, 0, 0, 0, 0, 0];
          _searchText = '(visitor)';
          _searchController.text = '(visitor)';
          break;
        case FilterOptions.virgins:
          _filterValues = <int>[0, 0, 1, 0, 0, 0, 0, 0, 0, 0];
          _searchText = '(virgin)';
          _searchController.text = '(virgin)';
          break;
        case FilterOptions.cancel:
          break;
        default:
          _filterValues = <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
          _searchText = '';
          _searchController.text = '';
          break;
      }

      if (retVal != FilterOptions.cancel) {
        if (!_showFilter) {
          _showFilter = true;

          _animationController.forward();
        }
        _refreshPackListFromTables(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ////print('mediaQuery = ${MediaQuery.of(context).size.toString()}');
    ////print('filter dx = ${filterPanelAnimation.value.dy}');
    _filterPanelAnimation ??= Tween<Offset>(begin: const Offset(0, -.35), end: const Offset(0, .71)).animate(_animationController);
    _hasherListAnimation ??= RelativeRectTween(begin: const RelativeRect.fromLTRB(0, 86, 0, 0), end: const RelativeRect.fromLTRB(0, 204, 0, 0)).animate(_animationController);
    ////print('rect = ${filterPanelAnimation.value}');
    return Scaffold(
      key: _scaffoldKey,
      floatingActionButton: SpeedDial(
          // both default to 16
          // marginEnd: 18,
          // marginBottom: 30,
          animatedIcon: AnimatedIcons.menu_close,
          animatedIconTheme: const IconThemeData(size: 22.0),
          // this is ignored if animatedIcon is non null
          // child:const  Icon(Icons.add),
          visible: true,
          curve: Curves.bounceIn,
          overlayColor: Colors.black,
          overlayOpacity: 0.5,
          onOpen: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            _searchFocusNode.unfocus();
          },
          //onClose: () => //print('DIAL CLOSED'),
          tooltip: 'Speed Dial',
          heroTag: 'speed-dial-hero-tag',
          backgroundColor: Colors.red.shade900,
          foregroundColor: Colors.white,
          elevation: 8.0,
          shape: const CircleBorder(),
          children: <SpeedDialChild>[
            SpeedDialChild(
              child: const Icon(Icons.filter_list),
              backgroundColor: Colors.green,
              label: 'Preset Filters',
              labelStyle: const TextStyle(fontSize: 18.0),
              onTap: () {
                _filterOptionsPopup();
              },
            ),
            // SpeedDialChild(
            //     child: const Icon(Icons.person_add),
            //     backgroundColor: Colors.blue,
            //     label: 'Add Hasher to Harrier Central',
            //     labelStyle: const TextStyle(fontSize: 18.0),
            //     onTap: () {
            //       Navigator.push<HashersModel>(
            //         context,
            //         MaterialPageRoute<HashersModel>(
            //           builder: (BuildContext context) => HasherProfilePage(
            //             dataContext: EnumDataContext.event,
            //             pageType: EnumMyProfilePageType.newHasherProfile,
            //             eventId: widget.eventAggregate.event.eventId,
            //             kennelId: widget.eventAggregate.event.kennelId,
            //             uiElementsToDisplay: HasherProfilePage.flagUiElement_followKennel,
            //           ),
            //         ),
            //       ).then((HashersModel result) {
            //         _refreshPackListFromTables(true);
            //       });
            //     }),
            SpeedDialChild(
              child: const Icon(FontAwesome.heart),
              backgroundColor: Colors.blue,
              label: 'Add Virgin / Visitor',
              labelStyle: const TextStyle(fontSize: 18.0),
              onTap: () => _showVirginVisitorPopup(context),
            ),
            SpeedDialChild(
              child: const Icon(MaterialCommunityIcons.account_search),
              backgroundColor: Colors.blue,
              label: 'Find Hasher and add',
              labelStyle: const TextStyle(fontSize: 18.0),
              onTap: () => _findHasher(),
            ),
            SpeedDialChild(
                child: const Icon(MaterialCommunityIcons.message_video),
                backgroundColor: Colors.deepOrange,
                label: 'View video tutorial',
                labelStyle: const TextStyle(fontSize: 18.0),
                onTap: () => Navigator.push<dynamic>(
                      context,
                      MaterialPageRoute<dynamic>(
                          builder: (BuildContext context) => const VideoTutorialPage(
                                title: 'How to use Check In Page',
                                videoUrl: 'https://harriercentral.blob.core.windows.net/help-videos/rabbit.mp4',
                              )),
                    )),
            if ((widget.eventAggregate?.kennel?.bankScheme != null) && (widget.eventAggregate?.kennel?.bankScheme != '')) ...<SpeedDialChild>[
              SpeedDialChild(
                child: const Icon(MaterialCommunityIcons.bank),
                backgroundColor: Colors.purple,
                label: 'Bank Transfer\r\n(Member)',
                labelStyle: const TextStyle(fontSize: 18.0),
                onTap: () => BankTransferQr.showBankTransferQrCode(context, widget.eventAggregate, true),
              ),
              SpeedDialChild(
                child: const Icon(MaterialCommunityIcons.bank),
                backgroundColor: Colors.purple,
                label: 'Bank Transfer\r\n(Non-Member)',
                labelStyle: const TextStyle(fontSize: 18.0),
                onTap: () => BankTransferQr.showBankTransferQrCode(context, widget.eventAggregate, false),
              ),
            ],
          ]),
      appBar: _getAppBar((_isLoading || (widget?.eventAggregate?.event?.eventName == null)) ? '... Loading' : (widget?.eventAggregate?.event?.eventName ?? '') + ' Check In'),
      body: _isLoading
          ? const HcCircularProgressIndicator(key: Key('430320291'))
          : Stack(fit: StackFit.loose, alignment: AlignmentDirectional.topStart, children: <Widget>[
              SizedBox(height: MediaQuery.of(context).size.height, width: 10),
              (_filteredList == null || _filteredList.isEmpty)
                  //? Positioned(top: showFilter ? 210 : 95, left:0, right: 0, child: getAddHasherBlock())
                  ? Positioned(top: (_filterPanelAnimation.value.dy * 120) + 125, left: 0, right: 0, child: _getAddHasherBlock())
                  : PositionedTransition(
                      rect: _hasherListAnimation,
                      child: SizedBox(key: _packListBoxKey, height: 300, child: _buildPackListView()),
                    ),
              SlideTransition(position: _filterPanelAnimation, child: _filterBar()),
              Positioned(top: 0, child: _searchBar()),
            ]),
    );
  }

  // Widget buildScanResultSnackbar(BuildContext contextl, String resultStr) {
  //   final SnackBar snackbar = SnackBar(
  //     duration: const Duration(seconds: 4),
  //     content: Column(
  //       mainAxisSize: MainAxisSize.min,
  //       children: <Widget>[
  //         Text(
  //           resultStr,
  //           style: const TextStyle(fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 20.0, height: 1.0),
  //         ),
  //       ],
  //     ),
  //     backgroundColor: Theme.of(context).accentColor,
  //   );

  //   return snackbar;
  // }

  SnackBar _buildRsvpAndPaymentSnackbar(BuildContext context, ScaffoldState scaffoldState, CheckInPackModel packMember) {
    num amountOwed = packMember.isMember != 1 ? widget.eventAggregate.extensions.nonMemberPrice : widget.eventAggregate.extensions.memberPrice;

    amountOwed = packMember.isMember != 1 ? widget.eventAggregate.extensions.nonMemberPrice : widget.eventAggregate.extensions.memberPrice;
    amountOwed -= packMember.discountAmount;
    amountOwed -= amountOwed * (packMember.discountPercent / 100.0);

    final SnackBar snackbar = PaymentSnackBar(
      context: context,
      eventAggregate: widget.eventAggregate,
      packMember: packMember,
      amountOwed: amountOwed,
      onRsvpCallback: (CheckInPackModel packMember, {int rsvpState = -1, int attendenceState = -1, int isHare = -1}) {
        if (rsvpState != -1) {
          setState(() {
            packMember.rsvpStateIndicator = Future<int>.value(rsvpUpdating.value);
          });
        }

        if (attendenceState != -1) {
          setState(() {
            packMember.attendenceStateIndicator = Future<int>.value(attendenceUpdating.value);
            packMember.paidStateIndicator = Future<int>.value(isPaidUpdating.value);
          });
        }
        ScaffoldMessenger.of(context).removeCurrentSnackBar(reason: SnackBarClosedReason.hide);
        _updateRsvpState(packMember, rsvpState, attendenceState, isHare);
      },
      onPaidCallback: (CheckInPackModel packMember, int paymentType, {OtherPaymentPopupResult userInput}) async {
        final num totalDue = userInput == null ? null : userInput.totalAmount;
        //final num topUpAmount = userInput['topUpAmount'];
        final num specialPriceAmount = userInput == null ? null : userInput.specialPriceAmount ?? amountOwed;
        final String specialPriceReason = userInput == null ? null : userInput.specialPriceReason;
        final bool useSpecialPriceAsDefault = userInput == null ? null : userInput.useSpecialPriceAsDefault;

        setState(() {
          packMember.rsvpStateIndicator = Future<int>.value(rsvpUpdating.value);
          packMember.attendenceStateIndicator = Future<int>.value(attendenceUpdating.value);
          packMember.paidStateIndicator = Future<int>.value(isPaidUpdating.value);
        });
        await _payForEvent(
          context,
          scaffoldState,
          paymentType,
          packMember,
          totalDue,
          specialRunPrice: specialPriceAmount,
          specialRunPriceReason: specialPriceReason,
          useSpecialPriceAsDefault: useSpecialPriceAsDefault,
        );
      },
    );

    return snackbar;
  }

  Future<void> _payForEvent(
    BuildContext context,
    ScaffoldState scaffoldState,
    int paymentType,
    CheckInPackModel packMember,
    num otherAmount, {
    num specialRunPrice,
    String specialRunPriceReason,
    bool useSpecialPriceAsDefault,
  }) async {
    ScaffoldMessenger.of(context).removeCurrentSnackBar(reason: SnackBarClosedReason.hide);
    dynamic payForExtras = payForRunOnly;

    if (((paymentType == paymentFreeRun.value) ||
            (paymentType == paymentCash.value) ||
            (paymentType == paymentBankTransfer.value) ||
            (paymentType == paymentCashOtherAmount.value) ||
            (paymentType == paymentHashCredit.value) ||
            (paymentType == paymentBankTransferOtherAmount.value)) &&
        ((widget.eventAggregate.event.eventPriceForExtras ?? 0) != 0)) {
      final num runOnlyPrice = packMember.isMember != 0 ? widget.eventAggregate.extensions.memberPrice : widget.eventAggregate.extensions.nonMemberPrice;
      final num runPlusExtrasPrice = runOnlyPrice + widget.eventAggregate.event.eventPriceForExtras;

      final String runOnlyPriceStr = IveCoreUtilities.getFormattedMoney(runOnlyPrice, widget.eventAggregate.extensions.digAfterDec, widget.eventAggregate.extensions.curSym);
      final String runPlusExtrasPriceStr = IveCoreUtilities.getFormattedMoney(runPlusExtrasPrice, widget.eventAggregate.extensions.digAfterDec, widget.eventAggregate.extensions.curSym);

      final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
        <String, dynamic>{
          'title': 'Run only ($runOnlyPriceStr)',
          'icon': <Widget>[
            Container(),
          ],
          'returnValue': payForRunOnly,
        },
        <String, dynamic>{
          'title': 'Run + ' + widget.eventAggregate.event.extrasDescription + ' ($runPlusExtrasPriceStr)',
          'icon': <Widget>[
            Container(),
          ],
          'returnValue': payForRunAndExtras
        },
      ];

      final MultipleChoicePopup popup = MultipleChoicePopup(
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
          });
    }

    final List<dynamic> results = await _processPayment(
      packMember,
      paymentType,
      otherAmount: otherAmount,
      doPayForExtras: payForExtras,
      specialRunPrice: specialRunPrice,
      specialRunPriceReason: specialRunPriceReason,
      useSpecialPriceAsDefault: useSpecialPriceAsDefault,
    );
    if (results != null) {
      if ((results[0]['terminalWasUsedForPayment'] == null) || (!results[0]['terminalWasUsedForPayment'])) {
        BankTransferQr.showBankTransferSnackbar(widget.eventAggregate, results, paymentType, context, packMember.nameForDisplay, packMember.isMember, otherAmount);
      }
    }
    await _refreshPackListFromTables(false);
    await _refreshCounters(true);
  }

  Future<List<dynamic>> _processPayment(
    CheckInPackModel packMember,
    int paymentType, {
    num otherAmount = -1,
    EnumPayForExtras<int> doPayForExtras = payForRunOnly,
    num specialRunPrice,
    String specialRunPriceReason,
    bool useSpecialPriceAsDefault = false,
  }) async {
    bool paymentCancelled = false;
    bool terminalWasUsedForPayment = false;

    setState(() {
      packMember.rsvpStateIndicator = Future<int>.value(rsvpUpdating.value);
      packMember.attendenceStateIndicator = Future<int>.value(attendenceUpdating.value);
      packMember.paidStateIndicator = Future<int>.value(isPaidUpdating.value);
    });

    final String hemId = packMember.hemId;
    final String hasherId = packMember.hasherId;
    num amount = packMember.isMember != 0 ? widget.eventAggregate.extensions.memberPrice : widget.eventAggregate.extensions.nonMemberPrice;
    if ((otherAmount != null) && (otherAmount != -1)) {
      amount = otherAmount;
    }

    final Random random = Random.secure();
    final List<int> values = List<int>.generate(6, (int i) => random.nextInt(26));
    final String randomString = String.fromCharCodes(Iterable<int>.generate(values.length, (int i) => values[i] + 65));
    String paymentReference;

    if (_useTerminalForPayment) {
      // this is a bit of a hack to use this boolean to indicate if the
      // payment terminal should be used. Maybe one day I'll clean this up.
      _useTerminalForPayment = false;
      terminalWasUsedForPayment = true;

      num terminalAmount = amount;
      if (doPayForExtras == payForRunAndExtras) {
        terminalAmount += widget.eventAggregate.event.eventPriceForExtras;
      }

      final String affiliateKey = getStringPref(StringPrefsEnum.paymentTerminalAccountKey);
      await Sumup.init(affiliateKey);

      bool isLoggedIn = await Sumup.isLoggedIn;
      if (!isLoggedIn) {
        await Sumup.login();
      }

      final String title = widget.eventAggregate.event.eventName + ' (' + packMember.nameForDisplay + ')';
      paymentReference = 'HC:' + randomString;

      isLoggedIn = await Sumup.isLoggedIn;
      if (isLoggedIn) {
        final SumupPayment payment = SumupPayment(
          title: title,
          total: terminalAmount + .0,
          currency: widget.eventAggregate.extensions.curCode ?? widget.eventAggregate.kennel.currencyCode ?? 'USD',
          foreignTransactionId: paymentReference,
          saleItemsCount: 1,
          skipSuccessScreen: true,
          tip: .0,
        );

        //"BGN" "BRL" "CHF" "CLP" "CZK" "DKK" "EUR" "GBP" "HRK" "HUF" "NOK" "PLN" "RON" "SEK" "USD"

        final SumupPaymentRequest request = SumupPaymentRequest(payment);

        request.info = <String, String>{
          'hashName': 'packMember.nameForDisplay',
          'foreignTransId': paymentReference,
        };

        final SumupPluginCheckoutResponse checkoutResult = await Sumup.checkout(request);
        if ((checkoutResult == null) || (!checkoutResult.success)) {
          paymentCancelled = true;
        } else {
          if (checkoutResult?.transactionCode != null) {
            paymentReference = 'SU:' + checkoutResult.transactionCode;
          }
        }
      }
    } else {
      paymentReference = 'HC:' + randomString;
    }

    if (paymentCancelled) {
      return null;
    } else {
      final PaymentsService paySrv = PaymentsService();
      final List<dynamic> result = await paySrv.payForEvent(
        widget.eventAggregate.event.eventId,
        ((hasherId == null) || (hasherId.length != GUID_EMPTY.length)) ? GUID_EMPTY : hasherId,
        ((hemId == null) || (hemId.length != GUID_EMPTY.length)) ? GUID_EMPTY : hemId,
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

      if ((result != null) && (result.isNotEmpty)) {
        final Map<String, dynamic> m = result[0];
        m.addAll(<String, dynamic>{'terminalWasUsedForPayment': terminalWasUsedForPayment});
      }

      return result;
    }
  }

  static const num LIST_ITEM_LEFT_MARGIN = 88.0;

  Widget _listItem(BuildContext context, CheckInPackModel packMember) {
    return GestureDetector(
      onTap: () {
        _searchFocusNode.unfocus();
        if (widget.eventAggregate.extensions.appAccess.canManageRuns) {
          final SnackBar snackBar = _buildRsvpAndPaymentSnackbar(context, _scaffoldKey.currentState, packMember);

          ScaffoldMessenger.of(context).removeCurrentSnackBar(reason: SnackBarClosedReason.hide);
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      },
      child: Container(
        color: ((packMember.attendenceState >= attendenceAtHash.value) && (_checkSpecialRun((packMember.hcTotalRunCount ?? 0) + (packMember.historicalTotalRunCount ?? 0))))
            ? Colors.amber.shade100
            : Colors.white,
        width: MediaQuery.of(context).size.width,
        child: Stack(
          children: <Widget>[
            GestureDetector(
              onTap: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => ZoomableImagePage2(
                        key: const Key('511203069'),
                        pageTitle: packMember.nameForDisplay,
                        imageUrl: packMember.photo.startsWith('http') ? packMember.photo : null,
                        assetImage: packMember.photo.contains('bundle://') ? 'images/avatars/' + packMember.photo.replaceAll('bundle://', '') + '.jpg' : null,
                        appBarBackgroundColor: themeAppBarBackground,
                        background: Backgrounds.defaultHcBackground(),
                        margin: 20.0),
                  ),
                );
              },
              child: packMember.photo.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: packMember.photo,
                      placeholder: (BuildContext context, String url) => const SizedBox(
                          child: Center(
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 3.0,
                              ),
                            ),
                          ),
                          height: LIST_ITEM_HEIGHT,
                          width: LIST_ITEM_HEIGHT),
                      errorWidget: (BuildContext context, String url, Object error) => const Icon(Icons.error, size: LIST_ITEM_HEIGHT, color: Colors.red),
                      //fadeOutDuration:  Duration(seconds: 1),
                      fadeInDuration: const Duration(milliseconds: 0),
                      width: LIST_ITEM_HEIGHT,
                      height: LIST_ITEM_HEIGHT,
                      fit: BoxFit.fill)
                  : packMember.photo.startsWith('bundle')
                      ? Image(
                          width: LIST_ITEM_HEIGHT,
                          height: LIST_ITEM_HEIGHT,
                          fit: BoxFit.fill,
                          image: AssetImage(('images/avatars/' + packMember.photo.toLowerCase().replaceFirst('bundle://', '') + '.jpg').toLowerCase()),
                        )
                      : const Image(
                          width: LIST_ITEM_HEIGHT,
                          height: LIST_ITEM_HEIGHT,
                          fit: BoxFit.fill,
                          image: AssetImage('images/avatars/avatar-2.jpg'),
                        ),
            ),

            Positioned(
              left: LIST_ITEM_LEFT_MARGIN + 2.0,
              top: 9.0,
              child: Text(packMember.nameForDisplay,
                  style: TextStyle(fontFamily: (packMember.isMember != 0) ? 'AvenirNextCondensedDemiBold' : 'AvenirNextCondensedMedium', fontStyle: FontStyle.normal, fontSize: 25.0, height: 1.0)),
            ),

            //(packMember.hcTotalRunCount + (packMember.historicalTotalRunCount ?? 0)

            if ((packMember.attendenceState >= attendenceAtHash.value) && (_checkSpecialRun((packMember.hcTotalRunCount ?? 0) + (packMember.historicalTotalRunCount ?? 0)))) ...<Widget>[
              Positioned(right: 8.0, top: 9.0, child: Image.asset('images/icons/beer_mug.png'), width: 35.0, height: 35.0),
            ],

            // Positioned(
            //   left: LIST_ITEM_LEFT_MARGIN + 2.0,
            //   top: 32.0,
            //   child: Text(
            //     packMember.homeKennelName ?? '',
            //     style: footnoteMedium,
            //     overflow: TextOverflow.ellipsis,
            //   ),
            // ),
            // this widget is here to grow the contents of the cell to a size that fills nearly the whole cell
            // in order to give plenty of room for the tap gesture.
            Positioned(
              left: LIST_ITEM_LEFT_MARGIN,
              top: 0,
              child: Container(width: MediaQuery.of(context).size.width - 200, height: 65, color: Colors.transparent),
            ),

            Positioned(
              left: LIST_ITEM_LEFT_MARGIN + 0.0,
              bottom: 5.0,
              child: FutureBuilder<int>(
                  future: packMember.rsvpStateIndicator,
                  builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                    return Stack(
                      alignment: AlignmentDirectional.center,
                      children: <Widget>[
                        Container(height: 30, width: 30, color: Colors.transparent),
                        CircleAvatar(
                          backgroundColor: ((snapshot?.data == null) || (snapshot.data == 0)) ? Colors.grey[350] : Colors.white,
                          radius: 14.0,
                        ),
                        ((snapshot?.data ?? 0) == 0)
                            ? Container()
                            : snapshot.data == rsvpUpdating.value
                                ? Icon(delayIcon, color: Colors.blue[800])
                                : snapshot.data == rsvpNo.value
                                    ? const Icon(FontAwesome.times_circle, color: Colors.red, size: 27.0)
                                    : snapshot.data == rsvpMaybe.value
                                        ? const Icon(FontAwesome.question_circle, color: Colors.orange, size: 27.0)
                                        : packMember.isHare == 0
                                            ? const Icon(FontAwesome.check_circle, color: Colors.green, size: 27.0)
                                            : Image.asset('images/icons/hare_icon.png', color: Colors.deepPurple, height: 24.0, width: 24.0)
                      ],
                    );
                  }),
            ),

            Positioned(
              left: LIST_ITEM_LEFT_MARGIN + 35.0,
              bottom: 5.0,
              child: FutureBuilder<int>(
                  future: packMember.attendenceStateIndicator,
                  builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                    return Stack(
                      alignment: AlignmentDirectional.center,
                      children: <Widget>[
                        Container(height: 30, width: 30, color: Colors.transparent),
                        CircleAvatar(
                          backgroundColor: ((snapshot?.data == null) || (snapshot.data == 0)) ? Colors.grey[350] : Colors.white,
                          radius: 14.0,
                        ),
                        ((!snapshot.hasData) || ((snapshot?.data ?? 0) == 0))
                            ? Container()
                            : snapshot.data == attendenceUpdating.value
                                ? Icon(delayIcon, color: Colors.blue[800])
                                : snapshot.data == attendenceNo.value
                                    ? Image.asset('images/icons/not_at_hash_icon.png', height: 24.0, width: 24.0, color: Colors.red[700])
                                    : snapshot.data == attendenceAtHash.value
                                        ? Image.asset('images/icons/runner_icon.png', height: 24.0, width: 24.0, color: Colors.orange)
                                        : snapshot.data >= attendenceOnIn.value
                                            ? Image.asset('images/icons/beer_icon.png', height: 24.0, width: 24.0, color: Colors.green)
                                            : Container()
                      ],
                    );
                  }),
            ),

            Positioned(
              left: LIST_ITEM_LEFT_MARGIN + 70.0,
              bottom: 5.0,
              child: FutureBuilder<int>(
                  future: packMember.paidStateIndicator,
                  builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                    return Stack(
                      alignment: AlignmentDirectional.center,
                      children: <Widget>[
                        Container(height: 30, width: 30, color: Colors.transparent),
                        CircleAvatar(
                          backgroundColor: ((snapshot?.data == null) || (snapshot.data < 0)) ? Colors.grey[350] : Colors.white,
                          radius: 14.0,
                        ),
                        ((snapshot?.data ?? -1) == -1)
                            ? Container()
                            : snapshot.data == isPaidUpdating.value
                                ? Icon(delayIcon, color: Colors.blue[800])
                                : snapshot.data == isPaidNo.value
                                    ? Image.asset('images/icons/dollar_sign_icon.png', height: 24.0, width: 24.0, color: Colors.red)
                                    : packMember.isPaid == isPaidYes.value
                                        ? Image.asset('images/icons/payment_type_${packMember.paymentType}.png', height: 24.0, width: 24.0, color: Colors.green)
                                        : Container()
                      ],
                    );
                  }),
            ),

            (packMember.hcHaringCount == null) || (packMember.hcHaringCount == 0)
                ? Container()
                : Positioned(
                    right: 4,
                    bottom: 17,
                    child: Text('Hared = ${packMember.hcHaringCount + (packMember.historicalHaringCount ?? 0)}',
                        style: _getRunLabelStyle(packMember.hcTotalRunCount + (packMember.historicalTotalRunCount ?? 0), packMember.attendenceState)),
                  ),
            packMember.hcTotalRunCount == null
                ? Container()
                : Positioned(
                    right: 4,
                    bottom: 1,
                    child: Text('Total Runs = ${packMember.hcTotalRunCount + (packMember.historicalTotalRunCount ?? 0)}',
                        style: _getRunLabelStyle(packMember.hcTotalRunCount + (packMember.historicalTotalRunCount ?? 0), packMember.attendenceState)),
                  ),
          ],
        ),
      ),
    );
  }

  TextStyle _getRunLabelStyle(int numRuns, int attendenceState) {
    if (attendenceState >= attendenceAtHash.value) {
      if (_checkSpecialRun(numRuns ?? 0)) {
        return mediumTextRed;
      }
    }
    return mediumText;
  }

  bool _checkSpecialRun(int runCount) {
    runCount ??= 0;
    bool result = false;
    if (runCount == 0) {
      result = true;
    }
    if (runCount == 1) {
      result = true;
    }
    if (runCount == 5) {
      result = true;
    }
    if (runCount == 10) {
      result = true;
    }
    if ((runCount % 25 == 0) && (runCount > 0)) {
      result = true;
    }
    if (runCount % 100 == 69) {
      result = true;
    }
    return result;
  }

  void _updateRsvpState(CheckInPackModel packMember, int rsvpState, int attendenceState, int isHare) {
    final String hemId = packMember.hemId;
    final String hasherId = packMember.hasherId;

    // setState(() {

    // });

    final Future<List<dynamic>> retVal = G0<TableModel>().hasherEventMapService.joinEvent(
          widget.eventAggregate.event.eventId,
          hasherId,
          hemId,
          AppDomainType.event,
          rsvpState: rsvpState,
          attendenceState: attendenceState,
          isHare: isHare,
          virginVisitorType: -1,
        );

    retVal.then((List<dynamic> adHocData) {
      _refreshPackListFromTables(false).then((void _) {
        _refreshCounters(true);
      });
    });
  }

  Widget _buildPackListView() {
    //print('buildPackListView: ${DateTime.now().millisecondsSinceEpoch.toString()}');

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollNotification) {
        if (scrollNotification is UserScrollNotification) {
          _searchFocusNode.unfocus();
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
        return true;
      },
      child: RefreshIndicator(
        displacement: 120,
        onRefresh: () async {
          await _refreshSqlTablesFromBackend(true);
        },
        child: ListView.separated(
          separatorBuilder: (BuildContext context, int index) => const Divider(
            height: 1.0,
            color: Colors.black45,
          ),
          physics: const AlwaysScrollableScrollPhysics(),
          scrollDirection: Axis.vertical,
          controller: _scrollController,
          itemCount: (_filteredList?.length ?? 0) + (_searchController.text.isNotEmpty ? 1 : 0),
          itemBuilder: (BuildContext context, int index) {
            if ((index == (_filteredList?.length ?? 0)) && (_searchController.text.isNotEmpty)) {
              return _getAddHasherBlock();
            } else {
              final CheckInPackModel packMember = _filteredList[index];

              num amountOwed = packMember.isMember != 1 ? widget.eventAggregate.extensions.nonMemberPrice : widget.eventAggregate.extensions.memberPrice;

              amountOwed = packMember.isMember != 1 ? widget.eventAggregate.extensions.nonMemberPrice : widget.eventAggregate.extensions.memberPrice;
              amountOwed -= packMember.discountAmount;
              amountOwed -= amountOwed * (packMember.discountPercent / 100.0);

              final String amountOwedStr = IveCoreUtilities.getFormattedMoney(amountOwed, widget.eventAggregate.extensions.digAfterDec, widget.eventAggregate.extensions.curSym);

              final Key key = Key(index.toString());

              return Slidable(
                key: key,
                controller: _slidableController,
                actionPane: const SlidableBehindActionPane(),
                actionExtentRatio: 0.35,
                child: Container(
                  color: Colors.white,
                  child: _listItem(context, packMember),
                ),
                dismissal: SlidableDismissal(
                  onWillDismiss: (SlideActionType actionType) {
                    if (actionType == SlideActionType.secondary) {
                      _useTerminalForPayment = false;
                    }
                    if (packMember.isPaid != 1) {
                      _payForEvent(
                        context,
                        _scaffoldKey.currentState,
                        actionType == SlideActionType.secondary ? paymentCash.value : paymentBankTransfer.value,
                        packMember,
                        -1,
                      );
                    } else {
                      if (actionType == SlideActionType.secondary) {
                        _updateRsvpState(packMember, -1, attendenceOnIn.value, -1);
                      }
                    }

                    Future<void>.delayed(const Duration(milliseconds: 10)).then((void _) {
                      _slidableController.activeState.close();
                    });

                    return false;
                  },
                  dismissThresholds: const <SlideActionType, double>{SlideActionType.secondary: 0.3},
                  child: const SlidableDrawerDismissal(),
                  onDismissed: (SlideActionType actionType) {
                    setState(() {});
                  },
                ),
                actions: <Widget>[
                  IconSlideAction(
                      iconWidget: packMember.isPaid == 1
                          ? Container(
                              color: Colors.grey,
                              width: G0<DeviceInfo>().deviceWidth,
                              child: Column(
                                children: const <Widget>[
                                  Padding(
                                    padding: EdgeInsets.only(top: 5.0),
                                    child: Icon(FontAwesome.check_circle, size: 30.0, color: Colors.white),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(top: 5.0),
                                    child: Text(
                                      'Already\r\npaid',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 20.0, height: 1.0),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              color: Colors.blue,
                              width: G0<DeviceInfo>().deviceWidth,
                              child: Column(
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Image.asset('images/icons/payment_type_4.png', height: 27.0, width: 27.0, color: Colors.white),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10.0),
                                    child: Text('${(widget.eventAggregate.event.eventPriceForExtras ?? 0) != 0 ? '' : amountOwedStr + '\r\n'}Bank Transfer',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 18.0, height: 1.0)),
                                  ),
                                ],
                              ),
                            ),
                      onTap: () {
                        _useTerminalForPayment = false;
                        _slidableController.activeState.dismiss(actionType: SlideActionType.primary);
                      }),
                  if ((packMember.isPaid != 1) && (getStringPref(StringPrefsEnum.paymentTerminalAccountKey) != null) && (Utilities.isOpeeOrTuna())) ...<Widget>[
                    IconSlideAction(
                        iconWidget: Container(
                          color: Colors.deepPurple,
                          width: G0<DeviceInfo>().deviceWidth,
                          child: Column(
                            children: <Widget>[
                              const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Icon(MaterialCommunityIcons.contactless_payment_circle, size: 30.0, color: Colors.white),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: Text('${(widget.eventAggregate.event.eventPriceForExtras ?? 0) != 0 ? '' : amountOwedStr + '\r\n'}Contactless',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 18.0, height: 1.0)),
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          _useTerminalForPayment = true;
                          _slidableController.activeState.dismiss(actionType: SlideActionType.primary);
                        }),
                  ],
                ],
                secondaryActions: <Widget>[
                  IconSlideAction(
                    iconWidget: packMember.isPaid == 1
                        ? packMember.attendenceState >= attendenceOnIn.value
                            ? Container(
                                width: G0<DeviceInfo>().deviceWidth,
                                color: Colors.grey,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: const <Widget>[
                                    Padding(
                                      padding: EdgeInsets.only(top: 5.0),
                                      child: Icon(FontAwesome.check_circle, size: 30.0, color: Colors.white),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(top: 5.0),
                                      child: Text(
                                        'Already\r\nOn-In',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 20.0, height: 1.0),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                color: Colors.amber[800],
                                width: G0<DeviceInfo>().deviceWidth,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: const <Widget>[
                                    Padding(
                                      padding: EdgeInsets.only(top: 2.0),
                                      child: Icon(Ionicons.ios_beer, size: 30.0, color: Colors.white),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(top: 5.0),
                                      child: Text(
                                        'Record as\r\nOn-In',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 20.0, height: 1.0),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                        : Container(
                            width: G0<DeviceInfo>().deviceWidth,
                            color: Colors.green,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 5.0, top: 8.0),
                                  child: Image.asset('images/icons/payment_type_3.png', height: 25.0, width: 25.0, color: Colors.white),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 5.0),
                                  child: Text('${(widget.eventAggregate.event.eventPriceForExtras ?? 0) != 0 ? '' : amountOwedStr + '\r\n'}Cash',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 20.0, height: 1.0)),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  String _capitalizeFirstLetter(String s) => (s?.isNotEmpty ?? false) ? '${s[0].toUpperCase()}${s.substring(1)}' : s;

  Widget _getAddHasherBlock() {
    return GestureDetector(
      onTap: () {
        Navigator.push<HashersModel>(
          context,
          MaterialPageRoute<HashersModel>(
            builder: (BuildContext context) => HasherProfilePage(
              dataContext: EnumDataContext.event,
              pageType: EnumMyProfilePageType.newHasherProfile,
              eventId: widget.eventAggregate.event.eventId,
              kennelId: widget.eventAggregate.event.kennelId,
              uiElementsToDisplay: HasherProfilePage.flagUiElement_followKennel,
              hashNameFromSearch: _capitalizeFirstLetter(_searchController.text),
            ),
          ),
        ).then((HashersModel result) {
          if (result != null) {
            _refreshPackListFromTables(true);
            if (result.dispName == '') {
              result.dispName = null;
            }
            if (result.hashName == '') {
              result.hashName = null;
            }

            _searchText = result.dispName ?? result.hashName ?? '${result.firstName} ${result.lastName}' ?? '<error no name entered>';
            _searchController.text = _searchText;
            _filterPackListResults();
          }
        });
      },
      child: Container(
        height: 80,
        margin: const EdgeInsets.only(left: 10),
        child: Row(
          children: <Widget>[
            Icon(SimpleLineIcons.question, size: 35.0, color: Colors.red.shade900),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 14.0, right: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Can\'t find a Hasher?', style: smallContentStyleDb),
                    AutoSizeText(
                      'Click here to add \'${_capitalizeFirstLetter(_searchController.text)}\'',
                      style: smallContentStyle,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class AddVisitorVirginPopup extends StatefulWidget {
  const AddVisitorVirginPopup({Key key}) : super(key: key);

  @override
  _AddVisitorVirginPopupState createState() => _AddVisitorVirginPopupState();
}

class _AddVisitorVirginPopupState extends State<AddVisitorVirginPopup> {
  final FocusNode myFocusNodeFirstName = FocusNode();

  TextEditingController nameTextController = TextEditingController();
  TextEditingController emailTextController = TextEditingController();
  TextEditingController phoneTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Visitor or Virgin'),
      content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        TextField(
          autofocus: true,
          focusNode: myFocusNodeFirstName,
          controller: nameTextController,
          keyboardType: TextInputType.text,
          style: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0, color: Colors.black),
          decoration: const InputDecoration(
            //border: InputBorder.none,
            icon: Icon(
              FontAwesome.money,
              color: Colors.white,
            ),
            hintText: 'Just Julie',
            hintStyle: TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
          ),
        ),
        TextField(
          autofocus: true,
          //focusNode: myFocusNodeFirstName,
          controller: emailTextController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0, color: Colors.black),
          decoration: const InputDecoration(
            //border: InputBorder.none,
            icon: Icon(
              FontAwesome.money,
              color: Colors.white,
            ),
            hintText: '(email - optional)',
            hintStyle: TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
          ),
        ),
        TextField(
          autofocus: true,
          //focusNode: myFocusNodeFirstName,
          controller: phoneTextController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0, color: Colors.black),
          decoration: const InputDecoration(
            //border: InputBorder.none,
            icon: Icon(
              FontAwesome.money,
              color: Colors.white,
            ),
            hintText: '(phone # - optional)',
            hintStyle: TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
          ),
        ),
      ]),
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop(<String, String>{'type': 'cancel', 'amount': ''});
          },
        ),

        TextButton(
            style: TextButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Add Visitor'),
            onPressed: () {
              Navigator.of(context).pop(<String, String>{
                'type': enumAnonymousVisitor.value.toString(),
                'name': nameTextController.text,
                'email': emailTextController.text,
                'phone': phoneTextController.text,
              });
            }),

        TextButton(
            style: TextButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Add Virgin'),
            onPressed: () {
              Navigator.of(context).pop(<String, String>{
                'type': enumVirgin.value.toString(),
                'name': nameTextController.text,
                'email': emailTextController.text,
                'phone': phoneTextController.text,
              });
            }),
        // ),
      ],
    );
  }
}
