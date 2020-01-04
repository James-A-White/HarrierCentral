import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:harrier_central/data/hc3_services/kennels_service.dart';
import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/data/hc3_services/hasher_event_map_service.dart';
import 'package:harrier_central/data/hc3_services/hasher_kennel_map_service.dart';
import 'package:harrier_central/data/hc3_services/hashers_service.dart';
import 'package:harrier_central/data/hc3_services/kennel_credits_service.dart';
import 'package:harrier_central/data/hc3_services/payments_service.dart';
import 'package:harrier_central/data/hc3_services/sync_event_admin_service.dart';
import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/pages/menu_pages/hasher_profile_page.dart';
import 'package:harrier_central/pages/menu_pages/video_tutorial_page.dart';
import 'package:harrier_central/pages/run_admin/find_hasher_page.dart';
import 'package:harrier_central/pages/run_admin/run_admin_main.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/bank_transfer_qr.dart';
import 'package:harrier_central/widgets/circular_progress_indicator.dart';
import 'package:harrier_central/widgets/multiple_choice_popup.dart';
import 'package:harrier_central/widgets/payment_snackbar.dart';

class CheckInPackModel {
  CheckInPackModel(
      {this.hasherId,
      this.hemId,
      this.isMember,
      this.isHare,
      this.isPaid,
      this.homeKennelName,
      this.nameForDisplay,
      this.nameForSort,
      this.paymentType,
      this.creditAmount,
      this.photo,
      this.virginVisitorType,
      this.rsvpState,
      this.attendenceState,
      this.currentPackRunCount,
      this.currentHaringCount,
      this.hemUpdatedAt,
      this.payUpdatedAt,
      this.credit});

  final String hasherId;
  final String hemId;
  final int isMember;
  final int isHare;
  final int isPaid;
  final String homeKennelName;
  final String nameForDisplay;
  final String nameForSort;
  final int paymentType;
  final num creditAmount;
  final String photo;
  final int virginVisitorType;
  final int rsvpState;
  final int attendenceState;
  final int currentPackRunCount;
  final int currentHaringCount;
  final String hemUpdatedAt;
  final String payUpdatedAt;
  final num credit;

  static CheckInPackModel fromMap(Map<String, dynamic> map) {
    final CheckInPackModel item = CheckInPackModel(
        hasherId: map['hasherId'],
        hemId: map['hemId'],
        isMember: map['isMember'],
        isHare: map['isHare'],
        isPaid: map['isPaid'],
        homeKennelName: map['homeKennelName'],
        nameForDisplay: map['nameForDisplay'],
        nameForSort: map['nameForSort'],
        paymentType: map['paymentType'],
        creditAmount: map['creditAmount'],
        photo: map['photo'],
        virginVisitorType: map['virginVisitorType'],
        rsvpState: map['rsvpState'],
        attendenceState: map['attendenceState'],
        currentPackRunCount: map['currentPackRunCount'],
        currentHaringCount: map['currentHaringCount'],
        // ,hemUpdatedAt: DateTime.parse(map['hemUpdatedAt'].toString().substring(0, 19))
        // ,payUpdatedAt: DateTime.parse(map['payUpdatedAt'].toString().substring(0, 19))
        hemUpdatedAt: map['hemUpdatedAt'],
        payUpdatedAt: map['payUpdatedAt'],
        credit: map['credit']);
    return item;
  }
}

class CheckInPackPage extends StatefulWidget {
  const CheckInPackPage({@required this.eventAggregate});

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

  GlobalKey packListBox = GlobalKey();

  bool _isLoading = true;

  List<CheckInPackModel> packList;
  List<CheckInPackModel> filteredList;
  List<CheckInPackModel> allHashers;

  Map<String, String> indicatorRsvpUpdating = <String, String>{};
  Map<String, String> indicatorAttendenceUpdating = <String, String>{};
  Map<String, String> indicatorPaidUpdating = <String, String>{};

  String searchText = '';

  int countAtHash = 0;
  int countRsvps = 0;
  int countComing = 0;
  int countPaid = 0;
  int countOnIn = 0;
  int memberCount = 0;

  num snackBarButtonSize = 35.0;
  static const num LIST_ITEM_HEIGHT = 84.0;

  String userId = getStringPref(StringPrefsEnum.userId);

  AnimationController animationController;
  Animation<double> buttonAnimation;
  Animation<Offset> filterPanelAnimation;
  Animation<RelativeRect> hasherListAnimation;
  ScrollController scrollController = ScrollController(initialScrollOffset: 0.0);
  FocusNode searchFocusNode;
  TextEditingController searchController;
  String searchTypeText;

  static const String searchKennel = 'Searching Kennel members and RSVPs';
  static const String searchAllHashers = 'Searching all Hashers';
  bool highlightSearchType = false;

  TextStyle localFootnoteSmallRed = footnoteSmallRed.copyWith(fontSize: 12 * deviceWidthScaleFactor);
  TextStyle localFootnoteSmall = footnoteSmall.copyWith(fontSize: 12 * deviceWidthScaleFactor);
  
  @override
  void initState() {
    searchTypeText = searchKennel;
    searchController = TextEditingController();
    searchFocusNode = FocusNode();

    _getAllHashers().then((void dummy) {
      // get all Hashers first, then build the tables from the backend
      _refreshSqlTablesFromBackend(true);
    });
    super.initState();

    animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    buttonAnimation = Tween<double>(begin: 0, end: 90.0 / 360.0).animate(animationController)
      ..addListener(() {
        setState(() {});
      });
  }

  Future<void> _refreshSqlTablesFromBackend(bool showLoadingIndicator) async {
    if (showLoadingIndicator) {
      setState(() {
        _isLoading = true;
      });
    }

    DBProvider.db.database.then((Database db) async {
      final SyncEventAdminService cSrv = SyncEventAdminService();
      final bool result = await cSrv.updateFromBackend(db, SyncEventAdminService.flagHashersTable | SyncEventAdminService.flagPaymentsTable | SyncEventAdminService.flagHasherEventMapTable | SyncEventAdminService.flagHasherKennelMapTable, true, widget.eventAggregate.event.eventId);
      final String resultStr = result ? 'successfully' : 'unsuccessfully';
      print('Payments data synchronized $resultStr');

      _refreshPackListFromTables(false).then((void dummy) {
        _refreshCounters(true);
      });
    });
  } 

  Future<void> _getAllHashers() async {
    allHashers = <CheckInPackModel>[];
    final Database db = await DBProvider.db.database;
    try {
      const String sql = ''' 

          SELECT 
            -- get all hashers
            h.hasherId,
            null as hemId,
            0 as isMember,
            0 as isHare,
            0 as isPaid, 
            h.dispName as nameForDisplay,
            lower(h.dispName || " " || h.firstName || " " || h.lastName) as nameForSort,
            0 as paymentType,
            0 as creditAmount,
            h.photo,
            0 as virginVisitorType,
            0 as rsvpState,
            0 as attendenceState,
            null as hemUpdatedAt,
            null as payUpdatedAt,
            0 as credit
          FROM ${HashersTableHelper.tableName} h
          ORDER BY nameForSort
          ''';

      final List<Map<String, dynamic>> results = await db.rawQuery(sql);

      if (results.isNotEmpty) {
        for (int i = 0; i < results.length; i++) {
          final CheckInPackModel item = CheckInPackModel.fromMap(results[i]);
          allHashers.add(item);
        }
      }

      print('All hashers loaded @ ${DateTime.now().millisecondsSinceEpoch}');
    } catch (e) {
      print(e);
    }
  }

  Future<void> _refreshPackListFromTables(bool forceRefresh) async {
    final Database db = await DBProvider.db.database;
    try {
      final String sql = ''' 

          SELECT 
            -- get all of the members of a Kennel and display them
            h.hasherId,
            k.kennelName as homeKennelName,
            hem.hemId,
            case when (julianday(hkm.membershipExpirationDate) >= julianday('now','localtime')) then 1 else 0 end as isMember,
            coalesce(hem.isHare,0) as isHare,
            CASE WHEN pay.hemId IS NULL THEN 0 ELSE 1 END as isPaid, 
            h.dispName as nameForDisplay,
            lower(h.dispName || " " || h.firstName || " " || h.lastName) as nameForSort,
            coalesce(pay.paymentType,0) as paymentType,
            coalesce(pay.creditAmount,0) as creditAmount,
            h.photo,
            0 as virginVisitorType,
            coalesce(hem.rsvpState,0) as rsvpState,
            coalesce(hem.attendenceState,0) as attendenceState,
            hem.updatedAt as hemUpdatedAt,
            pay.updatedAt as payUpdatedAt,
            coalesce(credits.currentBalance,0) as credit,
            hkm.currentPackRunCount,
            hkm.currentHaringCount
          FROM ${HasherKennelMapTableHelper.getTableName(HasherKennelMapTableType.eventAdmin)} hkm
          INNER JOIN ${HashersTableHelper.tableName} h on h.hasherId = hkm.userId
          LEFT OUTER JOIN ${KennelsTableHelper.tableName} k on k.kennelId = h.homeKennelId
          LEFT OUTER JOIN ${HasherEventMapTableHelper.getTableName(HasherEventMapTableType.eventAdmin)} hem on hem.userId = hkm.userId and hem.eventId = "${widget.eventAggregate.event.eventId}"
          LEFT OUTER JOIN ${PaymentsTableHelper.tableName} pay on pay.hemId = hem.hemId and pay.cancelledBy IS NULL
          LEFT OUTER JOIN ${KennelCreditsTableHelper.tableName} credits on credits.userId = hkm.userId and credits.kennelId = hkm.kennelId
          --WHERE hkm.kennelId = "${widget.eventAggregate.event.kennelId}" AND coalesce(hem.virginVisitorType,0) = 0
          WHERE hkm.kennelId = "${widget.eventAggregate.event.kennelId}" AND julianday(hkm.membershipExpirationDate) >= julianday('now','localtime') AND coalesce(hem.virginVisitorType,0) = 0
          UNION
          SELECT 
            -- now get all virgins & visitors
            null as hasherId,
            null as homeKennelName,
            coalesce(hem2.hemId,"00000000-0000-0000-0000-000000000000") as hemId,
            0 as isMember,
            hem2.isHare as isHare,
            CASE WHEN pay2.hemId IS NULL THEN 0 ELSE 1 END as isPaid, 
            coalesce(hem2.displayName,CASE WHEN hem2.virginVisitorType = 3 THEN h2.dispName ELSE "<no name>" END) || CASE WHEN hem2.virginVisitorType = 1 THEN " (virgin)" ELSE " (visitor)" END as nameForDisplay,
            lower(coalesce(hem2.displayName,CASE WHEN hem2.virginVisitorType = 3 THEN h2.dispName ELSE "<no name>" END) || CASE WHEN hem2.virginVisitorType = 1 THEN " (virgin)" ELSE " (visitor)" END) as nameForSort,
            coalesce(pay2.paymentType,0) as paymentType,
            coalesce(pay2.creditAmount,0) as creditAmount,
            CASE WHEN hem2.virginVisitorType = 1 THEN "https://harriercentral.blob.core.windows.net/harrier/Virgin.png" ELSE "https://harriercentral.blob.core.windows.net/harrier/Visitor.png" END as photo,
            coalesce(hem2.virginVisitorType,1) as virginVisitorType,
            coalesce(hem2.rsvpState,0) as rsvpState,
            coalesce(hem2.attendenceState,0) as attendenceState,
            hem2.updatedAt as hemUpdatedAt,
            pay2.updatedAt as payUpdatedAt,
            0 as credit,
            null as currentPackRunCount,
            null as currentHaringCount
            FROM ${HasherEventMapTableHelper.getTableName(HasherEventMapTableType.eventAdmin)} hem2 
            INNER JOIN ${HashersTableHelper.tableName} h2 on h2.hasherId = hem2.userId
            LEFT OUTER JOIN ${PaymentsTableHelper.tableName} pay2 on pay2.hemId = hem2.hemId and pay2.cancelledBy IS NULL
            WHERE hem2.eventId = "${widget.eventAggregate.event.eventId}" and hem2.virginVisitorType != 0
          UNION
          SELECT 
            -- now get all Hashers who are in HC and have RSVP'ed but are not members of the kennel
            hem3.userId as hasherId,
            k3.kennelName as homeKennelName,
            hem3.hemId as hemId,
            0 as isMember,
            hem3.isHare as isHare,
            CASE WHEN pay3.hemId IS NULL THEN 0 ELSE 1 END as isPaid, 
            coalesce(h3.dispName,"<no name>") as nameForDisplay,
            lower(h3.dispName || " " || h3.lastName || " " || h3.firstName) as nameForSort,
            coalesce(pay3.paymentType,0) as paymentType,
            coalesce(pay3.creditAmount,0) as creditAmount,
            h3.photo as photo,
            hem3.virginVisitorType as virginVisitorType,
            coalesce(hem3.rsvpState,0) as rsvpState,
            coalesce(hem3.attendenceState,0) as attendenceState,
            hem3.updatedAt as hemUpdatedAt,
            pay3.updatedAt as payUpdatedAt,
            coalesce(credits3.currentBalance,0) as credit,
            hkm4.currentPackRunCount,
            hkm4.currentHaringCount
            FROM ${HasherEventMapTableHelper.getTableName(HasherEventMapTableType.eventAdmin)} hem3
            INNER JOIN ${HashersTableHelper.tableName} h3 on h3.hasherId = hem3.userId
            LEFT OUTER JOIN ${KennelsTableHelper.tableName} k3 on k3.kennelId = h3.homeKennelId
            LEFT OUTER JOIN ${PaymentsTableHelper.tableName} pay3 on pay3.hemId = hem3.hemId and pay3.cancelledBy IS NULL
            LEFT OUTER JOIN ${HasherKennelMapTableHelper.getTableName(HasherKennelMapTableType.eventAdmin)} hkm3 on hkm3.userId = h3.hasherId and hkm3.kennelId = "${widget.eventAggregate.event.kennelId}" AND julianday(hkm3.membershipExpirationDate) >= julianday('now','localtime')
            LEFT OUTER JOIN ${HasherKennelMapTableHelper.getTableName(HasherKennelMapTableType.eventAdmin)} hkm4 on hkm4.userId = h3.hasherId and hkm4.kennelId = "${widget.eventAggregate.event.kennelId}" 
            LEFT OUTER JOIN ${KennelCreditsTableHelper.tableName} credits3 on credits3.userId = hkm3.userId and credits3.kennelId = hkm3.kennelId
            WHERE hem3.eventId = "${widget.eventAggregate.event.eventId}" AND hem3.virginVisitorType == 0 AND hkm3.hkmId IS NULL
          ORDER BY nameForSort
            
          
          ''';

      List<Map<String, dynamic>> results;

      try {
        results = await db.rawQuery(sql);
      } catch (x) {
        print(x);
      }

      setState(() {
        if (results.isNotEmpty) {
          packList = <CheckInPackModel>[];
          for (int i = 0; i < results.length; i++) {
            final CheckInPackModel item = CheckInPackModel.fromMap(results[i]);
            packList.add(item);
          }

          // this code is here to manage the "loading indicator" for RSVPs.
          // There's got to be a better way to do this, I just can't figure
          // it out!
          final List<String> removeList = <String>[];

          for (String key in indicatorRsvpUpdating.keys) {
            if (key.startsWith('hem:')) {
              final String hem = key.substring(4);

              final CheckInPackModel hasher = packList.firstWhere((CheckInPackModel k) => k.hemId.toString().toLowerCase() == hem, orElse: () => null);

              if (hasher != null) {
                if (hasher.hemUpdatedAt.toString() != indicatorRsvpUpdating[hem]) {
                  removeList.add('hem:' + hem.toLowerCase());
                }
              }
            } else {
              final String hid = key.substring(4);

              final CheckInPackModel hasher = packList.firstWhere((CheckInPackModel k) => k.hasherId.toLowerCase() == hid, orElse: () => null);

              if (hasher != null) {
                if (hasher.hemUpdatedAt.toString() != indicatorRsvpUpdating[hid]) {
                  removeList.add('hid:' + hid.toLowerCase());
                }
              }
            }
          }

          removeList.forEach(indicatorRsvpUpdating.remove);
          removeList.clear();

          for (String key in indicatorAttendenceUpdating.keys) {
            if (key.startsWith('hem:')) {
              final String hem = key.substring(4);

              final CheckInPackModel hasher = packList.firstWhere((CheckInPackModel k) => k.hemId.toString().toLowerCase() == hem, orElse: () => null);

              if (hasher != null) {
                if (hasher.hemUpdatedAt.toString() != indicatorAttendenceUpdating[hem]) {
                  removeList.add('hem:' + hem.toLowerCase());
                }
              }
            } else {
              final String hid = key.substring(4);

              final CheckInPackModel hasher = packList.firstWhere((CheckInPackModel k) => k.hasherId.toString().toLowerCase() == hid, orElse: () => null);

              if (hasher != null) {
                if (hasher.hemUpdatedAt.toString() != indicatorAttendenceUpdating[hid]) {
                  removeList.add('hid:' + hid.toLowerCase());
                }
              }
            }
          }

          removeList.forEach(indicatorAttendenceUpdating.remove);

          removeList.clear();
          for (String key in indicatorPaidUpdating.keys) {
            if (key.startsWith('hem:')) {
              final String hem = key.substring(4);

              final CheckInPackModel hasher = packList.firstWhere((CheckInPackModel k) => k.hemId.toString().toLowerCase() == hem, orElse: () => null);

              if (hasher != null) {
                if (hasher.hemUpdatedAt.toString() != indicatorPaidUpdating[hem]) {
                  removeList.add('hem:' + hem.toLowerCase());
                }
              }
            } else {
              final String hid = key.substring(4);

              final CheckInPackModel hasher = packList.firstWhere((CheckInPackModel k) => k.hasherId.toString().toLowerCase() == hid, orElse: () => null);

              if (hasher != null) {
                if (hasher.hemUpdatedAt.toString() != indicatorPaidUpdating[hid]) {
                  removeList.add('hid:' + hid.toLowerCase());
                }
              }
            }
          }

          removeList.forEach(indicatorPaidUpdating.remove);

          setState(() {
            if (forceRefresh) {
              _isLoading = false;
            }
          });
        }

        print('Pack records retreived @ ${DateTime.now().millisecondsSinceEpoch}');

        filterPackListResults();
      });
    } catch (e) {
      print(e);
    }
  }

  void filterPackListResults() {
    //bool showSnackbar = false;
    //bool searchingAllHashers = false;

    bool ignoreTextFilter = false;
    final String temp = searchTypeText;

    if (showFilter) {
      filteredList = packList
          .where((CheckInPackModel a) =>
              ((filterValues[0] == 0) || (filterValues[0] == -1 && ((a.rsvpState ?? 0) <= 1)) || (filterValues[0] == 1 && (a.rsvpState ?? 0) >= 2)) &&
              ((filterValues[1] == 0)
                  //|| (filterValues[1] == -1 && ((a.attendenceState ?? 0) < 20))
                  ||
                  (filterValues[1] == 1 && (a.attendenceState ?? 0) < 20 && (a.rsvpState ?? 0) >= 2)) &&
              ((filterValues[2] == 0) || (filterValues[2] == -1 && ((a.attendenceState ?? 0) < 20)) || (filterValues[2] == 1 && (a.attendenceState ?? 0) >= 20)) &&
              ((filterValues[3] == 0) || (filterValues[3] == -1 && ((a.isPaid ?? 0) == 0)) || (filterValues[3] == 1 && (a.isPaid ?? 0) == 1)) &&
              ((filterValues[4] == 0) || (filterValues[4] == -1 && ((a.attendenceState ?? 0) < 30)) || (filterValues[4] == 1 && (a.attendenceState ?? 0) >= 30)) &&
              ((filterValues[5] == 0) || (filterValues[5] == -1 && ((a.isMember ?? 0) == 0)) || (filterValues[5] == 1 && (a.isMember ?? 0) == 1)))
          .toList();
    } else {
      filteredList = <CheckInPackModel>[];
      filteredList.addAll(packList);
    }

    if ((searchText != null) && (searchText.isNotEmpty)) {
      filteredList = filteredList.where((CheckInPackModel a) => a.nameForSort.toLowerCase().contains(searchText.toLowerCase())).toList();
      if (filteredList.isEmpty) {
        // if (!ignoreTextFilter) {
        //   showSnackbar = true;
        // }
        ignoreTextFilter = true;
        filteredList = allHashers.where((CheckInPackModel a) => a.nameForSort.toLowerCase().contains(searchText.toLowerCase())).toList();
      } else {
        ignoreTextFilter = false;
        _scaffoldKey.currentState.hideCurrentSnackBar();
      }
    } else {
      searchTypeText = searchKennel;
    }

    searchTypeText = ignoreTextFilter ? searchAllHashers : searchKennel;

    if (temp != searchTypeText) {
      highlightSearchType = true;
      Future<void>.delayed(const Duration(milliseconds: 1500)).then((void dummy) {
        setState(() {
          highlightSearchType = false;
        });
      });
    }
  }

  Future<void> _refreshCounters(bool forceRefresh) async {
    final Database db = await DBProvider.db.database;
    try {
      final String sql = ''' 

          SELECT 
              COUNT(CASE WHEN rsvpState >= 2 THEN 1 ELSE NULL END) as rsvps,
              COUNT(CASE WHEN attendenceState >= 20 THEN 1 ELSE NULL END) as atHash,
              COUNT(CASE WHEN pay.paymentType >= 2 THEN 1 ELSE NULL END) as paid,
              COUNT(CASE WHEN rsvpState >= 2 AND attendenceState < 20 THEN 1 ELSE NULL END) as coming,
              COUNT(CASE WHEN attendenceState >= 30 THEN 1 ELSE NULL END) as onIn,
              (SELECT COUNT(*) FROM ${HasherKennelMapTableHelper.getTableName(HasherKennelMapTableType.eventAdmin)} hkm WHERE hkm.kennelId = "${widget.eventAggregate.event.kennelId}" and hkm.isMember = 1) as memberCount
          FROM ${HasherEventMapTableHelper.getTableName(HasherEventMapTableType.eventAdmin)} hem
          LEFT OUTER JOIN ${PaymentsTableHelper.tableName} pay on pay.hemId = hem.hemId and pay.cancelledBy IS NULL
  
          ''';

      db.rawQuery(sql).then((List<Map<String, dynamic>> results) {
        if (results.isNotEmpty) {
          countRsvps = results[0]['rsvps'];
          countAtHash = results[0]['atHash'];
          countComing = results[0]['coming'];
          countOnIn = results[0]['onIn'];
          countPaid = results[0]['paid'];
          memberCount = results[0]['memberCount'];
        }
        if (forceRefresh) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      print(e);
    }
  }

  void findHasher() {
    Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute<Map<String, dynamic>>(
        settings: const RouteSettings(),
        builder: (BuildContext context) {
          return const FindHasherPage(FindHasherPageType.addHasherToRun);
        },
      ),
    ).then((Map<String, dynamic> result) {
      if ((result != null) && (result['hasher']?.hasherId != null)) {
        final HasherEventMapService hemSrv = HasherEventMapService();
        final Future<List<dynamic>> retVal =
            hemSrv.joinEvent(widget.eventAggregate.event.eventId, HasherEventMapTableType.eventAdmin, result['hasher'].hasherId, null, rsvpState: rsvpYes.value, attendenceState: attendenceAtHash.value, isHare: isHareNo.value, virginVisitorType: result['virginVisitorType']);

        retVal.then((List<dynamic> adHocData) {
          _refreshPackListFromTables(false).then((void dummy) {
            _refreshCounters(true);
          });
        });
      }
    });
  }

  void showVirginVisitorPopup(BuildContext parentContext) {
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
        final HasherEventMapService hemSrv = HasherEventMapService();
        final Future<List<dynamic>> retVal = hemSrv.joinEventAsVisitor(widget.eventAggregate.event.eventId, HasherEventMapTableType.eventAdmin, name, evv.value, attendenceUnknown.value, email, phoneNumber);

        retVal.then((List<dynamic> adHocData) {
          _refreshPackListFromTables(false).then((void dummy) {
            _refreshCounters(true);
            // if (name?.isNotEmpty ?? false) {
            //   searchText = name;
            //   searchController.text = searchText;
            //   filterPackListResults();
            // }

            setState(() {
              _isLoading = false;
            });

            if (((widget.eventAggregate.extensions.mismanagementRoleFlags ?? 0) & mmAuthAllowCheckInAndOutFlag) != 0) {
              if ((adHocData != null) && (adHocData.isNotEmpty)) {
                final String hem = adHocData[0]['hasherEventMapId'].toString().toLowerCase();
                scrollIndex = packList.indexWhere((CheckInPackModel k) => k.hemId.toString().toLowerCase() == hem);
                if ((scrollIndex ?? -1) >= 0) {
                  final CheckInPackModel hasher = packList[scrollIndex];
                  if (hasher != null) {
                    final SnackBar snackBar = buildRsvpAndPaymentSnackbar(context, _scaffoldKey.currentState, hasher);

                    _scaffoldKey.currentState.removeCurrentSnackBar(reason: SnackBarClosedReason.hide);
                    _scaffoldKey.currentState.showSnackBar(snackBar).closed.then((SnackBarClosedReason reason) {
                      setState(() {
                        if ((scrollIndex ?? -1) >= 0) {
                          if (scrollController.hasClients) {
                            scrollController.animateTo(scrollIndex * LIST_ITEM_HEIGHT, duration: const Duration(seconds: 1), curve: Curves.ease);
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

  AppBar getAppBar(String title) {
    return AppBar(
      centerTitle: true,
      backgroundColor: themeAppBarBackground,
      title: Text(
        '$title',
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }

  bool showFilter = false;

  Container searchBar() {
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
                turns: buttonAnimation,
                child: IconButton(
                  padding: const EdgeInsets.all(0),
                  onPressed: () {
                    searchFocusNode.unfocus();
                    if (showFilter) {
                      animationController.reverse();
                    } else {
                      animationController.forward();
                    }
                    showFilter = !showFilter;
                    // searchController.text = '';
                    // searchText = '';
                    _refreshPackListFromTables(true);
                  },
                  icon: Icon(FontAwesome5Solid.arrow_alt_circle_right, size: 35, color: showFilter ? Colors.green : Colors.grey),
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
                    TextField(
                      autocorrect: false,
                      onChanged: (String text) {
                        setState(() {
                          searchText = text;
                          filterPackListResults();
                        });
                      },
                      focusNode: searchFocusNode,
                      controller: searchController,
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
                    Text(searchTypeText, style: highlightSearchType ? localFootnoteSmallRed : localFootnoteSmall)
                  ],
                ),
              ),
              Container(
                width: 40,
                child: FlatButton(
                  //color: Colors.red,
                  child: const Text('X'),
                  textColor: Colors.grey[700],
                  onPressed: () {
                    searchController.text = '';
                    searchText = '';
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

  Container filterBar() {
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
            counter: memberCount,
            label: 'Member',
            index: 5,
            onTap: () {
              _refreshPackListFromTables(true);
            },
          ),
          CheckinFiltersCell(
            counter: countRsvps,
            label: 'RSVP',
            index: 0,
            onTap: () {
              _refreshPackListFromTables(true);
            },
          ),
          CheckinFiltersCell(
            counter: countComing,
            label: 'Coming',
            index: 1,
            useTriState: false,
            onTap: () {
              _refreshPackListFromTables(true);
            },
          ),
          CheckinFiltersCell(
            counter: countAtHash,
            index: 2,
            label: 'At Hash',
            onTap: () {
              _refreshPackListFromTables(true);
            },
          ),
          CheckinFiltersCell(
            counter: countPaid,
            index: 3,
            label: 'Paid',
            onTap: () {
              _refreshPackListFromTables(true);
            },
          ),
          CheckinFiltersCell(
            counter: countOnIn,
            index: 4,
            label: 'On In',
            onTap: () {
              _refreshPackListFromTables(true);
            },
          ),
        ],
      ),
    );
  }

  void filterOptionsPopup() {
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
        'icon': <Widget>[Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)), const Positioned(bottom: 2, child: Icon(MaterialCommunityIcons.alpha_v_circle, size: 30, color: Colors.purple))],
        'returnValue': FilterOptions.visitors
      },
      <String, dynamic>{
        'title': 'Virgins',
        'icon': <Widget>[Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)), Positioned(bottom: 2, child: Icon(MaterialCommunityIcons.alpha_v_circle, size: 30, color: Colors.pink[300]))],
        'returnValue': FilterOptions.virgins
      },
      <String, dynamic>{
        'title': 'Clear all filters',
        'icon': <Widget>[Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)), const Positioned(bottom: 2, child: Icon(Ionicons.md_remove_circle, size: 30, color: Colors.teal))],
        'returnValue': FilterOptions.clearAllFilters
      },
    ];

    final MultipleChoicePopup popup = MultipleChoicePopup(
        title: 'Common filter options',
        buttons: buttons,
        cancelButtonTitle: 'Cancel',
        buttonPress: (dynamic retVal) {
          switch (retVal) {
            case FilterOptions.hashersNotHereYet:
              filterValues = <int>[0, 1, 0, 0, 0, 0, 0];
              searchText = '';
              searchController.text = '';
              break;
            case FilterOptions.hashersNotPaid:
              filterValues = <int>[0, 0, 1, -1, 0, 0, 0];
              searchText = '';
              searchController.text = '';
              break;
            case FilterOptions.hashersStillOnTrail:
              filterValues = <int>[0, 0, 1, 0, -1, 0, 0];
              searchText = '';
              searchController.text = '';
              break;
            case FilterOptions.clearAllFilters:
              filterValues = <int>[0, 0, 0, 0, 0, 0, 0];
              searchText = '';
              searchController.text = '';
              break;
            case FilterOptions.visitors:
              filterValues = <int>[0, 0, 1, 0, 0, 0, 0];
              searchText = '(visitor)';
              searchController.text = '(visitor)';
              break;
            case FilterOptions.virgins:
              filterValues = <int>[0, 0, 1, 0, 0, 0, 0];
              searchText = '(virgin)';
              searchController.text = '(virgin)';
              break;
            case FilterOptions.cancel:
              break;
            default:
              filterValues = <int>[0, 0, 0, 0, 0, 0, 0];
              searchText = '';
              searchController.text = '';
              break;
          }

          if (retVal != FilterOptions.cancel) {
            if (!showFilter) {
              showFilter = true;

              animationController.forward();
            }
            _refreshPackListFromTables(true);
          }

          // );
        });

    showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return popup;
        });
  }

  @override
  Widget build(BuildContext context) {
    //print('mediaQuery = ${MediaQuery.of(context).size.toString()}');
    //print('filter dx = ${filterPanelAnimation.value.dy}');
    filterPanelAnimation ??= Tween<Offset>(begin: const Offset(0, -.35), end: const Offset(0, .71)).animate(animationController);
    hasherListAnimation ??= RelativeRectTween(begin: const RelativeRect.fromLTRB(0, 86, 0, 0), end: const RelativeRect.fromLTRB(0, 204, 0, 0)).animate(animationController);
    //print('rect = ${filterPanelAnimation.value}');
    return Scaffold(
      key: _scaffoldKey,
      floatingActionButton: SpeedDial(
        // both default to 16
        marginRight: 18,
        marginBottom: 30,
        animatedIcon: AnimatedIcons.menu_close,
        animatedIconTheme: const IconThemeData(size: 22.0),
        // this is ignored if animatedIcon is non null
        // child:const  Icon(Icons.add),
        visible: true,
        curve: Curves.bounceIn,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        onOpen: () {
          _scaffoldKey.currentState.hideCurrentSnackBar();
          searchFocusNode.unfocus();
        },
        onClose: () => print('DIAL CLOSED'),
        tooltip: 'Speed Dial',
        heroTag: 'speed-dial-hero-tag',
        backgroundColor: Theme.of(context).accentColor,
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
              filterOptionsPopup();
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
            onTap: () => showVirginVisitorPopup(context),
          ),
          // SpeedDialChild(
          //   child: const Icon(MaterialCommunityIcons.account_search),
          //   backgroundColor: Colors.blue,
          //   label: 'Find Hasher',
          //   labelStyle: const TextStyle(fontSize: 18.0),
          //   onTap: () => findHasher(),
          // ),
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
        ]..addAll(((widget.eventAggregate?.kennel?.bankScheme == null) || (widget.eventAggregate?.kennel?.bankScheme == ''))
            ? List<SpeedDialChild>.from(<SpeedDialChild>[])
            : List<SpeedDialChild>.from(<SpeedDialChild>[
                SpeedDialChild(
                  child: const Icon(MaterialCommunityIcons.bank),
                  backgroundColor: Colors.purple,
                  label: 'Bank Transfer (Member)',
                  labelStyle: const TextStyle(fontSize: 18.0),
                  onTap: () => BankTransferQr.showBankTransferQrCode(context, widget.eventAggregate, true),
                ),
                SpeedDialChild(
                  child: const Icon(MaterialCommunityIcons.bank),
                  backgroundColor: Colors.purple,
                  label: 'Bank Transfer (Non-Member)',
                  labelStyle: const TextStyle(fontSize: 18.0),
                  onTap: () => BankTransferQr.showBankTransferQrCode(context, widget.eventAggregate, false),
                ),
              ])),
      ),
      appBar: getAppBar((_isLoading || (widget?.eventAggregate?.event?.eventName == null)) ? '... Loading' : (widget?.eventAggregate?.event?.eventName ?? '') + ' Check In'),
      body: _isLoading
          ? const HcCircularProgressIndicator()
          : Stack(fit: StackFit.loose, alignment: AlignmentDirectional.topStart, children: <Widget>[
              Container(height: MediaQuery.of(context).size.height, width: 10),
              (filteredList == null || filteredList.isEmpty)
                  //? Positioned(top: showFilter ? 210 : 95, left:0, right: 0, child: getAddHasherBlock())
                  ? Positioned(top: (filterPanelAnimation.value.dy * 120) + 125, left: 0, right: 0, child: getAddHasherBlock())
                  : PositionedTransition(
                      rect: hasherListAnimation,
                      child: Container(key: packListBox, height: 300, child: buildPackListView()),
                    ),
              SlideTransition(position: filterPanelAnimation, child: filterBar()),
              Positioned(top: 0, child: searchBar()),
            ]),
    );
  }

  Widget buildScanResultSnackbar(BuildContext contextl, String resultStr) {
    final SnackBar snackbar = SnackBar(
      duration: const Duration(seconds: 4),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            resultStr,
            style: const TextStyle(fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 20.0, height: 1.0),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).accentColor,
    );

    return snackbar;
  }

  SnackBar buildRsvpAndPaymentSnackbar(BuildContext context, ScaffoldState scaffoldState, CheckInPackModel packMember) {
    final SnackBar snackbar = PaymentSnackBar(
      context: context,
      eventAggregate: widget.eventAggregate,
      packMember: packMember,
      onRsvpCallback: (CheckInPackModel packMember, {int rsvpState = -1, int attendenceState = -1, int isHare = -1}) {
        scaffoldState.removeCurrentSnackBar(reason: SnackBarClosedReason.hide);
        updateRsvpState(packMember, rsvpState, attendenceState, isHare);
      },
      onPaidCallback: (CheckInPackModel packMember, int paymentType, {num otherAmount = -1}) {
        scaffoldState.removeCurrentSnackBar(reason: SnackBarClosedReason.hide);
        payForEvent(packMember, paymentType, otherAmount: otherAmount).then((List<dynamic> results) {
          _refreshPackListFromTables(false).then((void dummy) {
            _refreshCounters(true);
            BankTransferQr.showBankTransferSnackbar(widget.eventAggregate, results, paymentType, context, packMember.nameForDisplay, packMember.isMember, otherAmount);
          });
        });
      },
    );

    return snackbar;
  }

  static const num LIST_ITEM_LEFT_MARGIN = 88.0;

  Widget listItem(BuildContext context, CheckInPackModel packMember) {
    return GestureDetector(
      onTap: () {
        searchFocusNode.unfocus();
        if (((widget.eventAggregate.extensions.mismanagementRoleFlags ?? 0) & mmAuthAllowCheckInAndOutFlag) != 0) {
          final SnackBar snackBar = buildRsvpAndPaymentSnackbar(context, _scaffoldKey.currentState, packMember);

          _scaffoldKey.currentState.removeCurrentSnackBar(reason: SnackBarClosedReason.hide);
          _scaffoldKey.currentState.showSnackBar(snackBar);
        }
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        child: Stack(
          children: <Widget>[
            packMember.photo.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: packMember.photo,
                    // placeholder: (context, url) => Container(
                    //     child: Center(
                    //       child: Container(
                    //         height: 20,
                    //         width: 20,
                    //         child: CircularProgressIndicator(
                    //           strokeWidth: 3.0,
                    //         ),
                    //       ),
                    //     ),
                    //     height: 70.0,
                    //    width: 70.0),
                    errorWidget: (BuildContext context, String url, Object error) => const Icon(Icons.error),
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

            Positioned(
              left: LIST_ITEM_LEFT_MARGIN + 2.0,
              top: packMember.homeKennelName == null ? 9.0 : 3.0,
              child: Text(packMember.nameForDisplay, style: TextStyle(fontFamily: (packMember.isMember != 0) ? 'AvenirNextCondensedDemiBold' : 'AvenirNextCondensedMedium', fontStyle: FontStyle.normal, fontSize: 25.0, height: 1.0)),
            ),
            Positioned(
              left: LIST_ITEM_LEFT_MARGIN + 2.0,
              top: 32.0,
              child: Text(packMember.homeKennelName ?? '', style: footnoteMedium, overflow: TextOverflow.ellipsis,),
            ),
            // this widget is here to grow the contents of the cell to a size that fills nearly the whole cell
            // in order to give plenty of room for the tap gesture.
            Positioned(
              left: LIST_ITEM_LEFT_MARGIN,
              top: 0,
              child: Container(width: MediaQuery.of(context).size.width - 200, height: 65, color: Colors.transparent),
            ),

            Positioned(
              left: LIST_ITEM_LEFT_MARGIN,
              bottom: packMember.homeKennelName == null ? 9.0 : 3.0,
              child: packMember.rsvpState == -1
                  ? CircleAvatar(
                      backgroundColor: Colors.grey[350],
                      radius: 14.0,
                    )
                  : CircleAvatar(
                      backgroundColor: packMember.rsvpState == 0 ? Colors.grey[350] : Colors.white,
                      radius: 14.0,
                    ),
            ),
            Positioned(
              left: LIST_ITEM_LEFT_MARGIN + 1.0,
              bottom: (packMember.rsvpState <= 0 ? 2.0 : packMember.isHare == 1 ? 5.0 : 3.5) + (packMember.homeKennelName == null ? 6.0 : 0.0),
              child: ((packMember.hemId != null) && (indicatorRsvpUpdating.containsKey('hem:' + (packMember.hemId.toString().toLowerCase() ?? ''))) || ((packMember.hasherId != null) && (indicatorRsvpUpdating.containsKey('hid:' + (packMember.hasherId.toString().toLowerCase() ?? '')))))
                  ? Icon(delayIcon, color: Colors.blue[800])
                  : packMember.rsvpState == 0
                      ? Container()
                      : packMember.rsvpState == rsvpNo.value
                          ? const Icon(FontAwesome.times_circle, color: Colors.red, size: 27.0)
                          : packMember.rsvpState == rsvpMaybe.value
                              ? const Icon(FontAwesome.question_circle, color: Colors.orange, size: 27.0)
                              : packMember.isHare == 0 ? const Icon(FontAwesome.check_circle, color: Colors.green, size: 27.0) : Image.asset('images/icons/hare_icon.png', color: Colors.deepPurple, height: 24.0, width: 24.0),
            ),
            Positioned(
              left: LIST_ITEM_LEFT_MARGIN + 40.0,
              bottom: packMember.homeKennelName == null ? 9.0 : 3.0,
              child: ((packMember.hemId != null) && (indicatorAttendenceUpdating.containsKey('hem:' + (packMember.hemId.toString().toLowerCase() ?? ''))) || ((packMember.hasherId != null) && (indicatorRsvpUpdating.containsKey('hid:' + (packMember.hasherId.toString().toLowerCase() ?? '')))))
                  ? Icon(delayIcon, color: Colors.blue[800])
                  : (packMember.rsvpState != rsvpYes.value)
                      ? CircleAvatar(
                          backgroundColor: Colors.grey[350],
                          radius: 14.0,
                        )
                      : CircleAvatar(
                          backgroundColor: packMember.attendenceState == 0 ? Colors.grey[350] : Colors.white,
                          radius: 14.0,
                        ),
            ),
            Positioned(
              left: LIST_ITEM_LEFT_MARGIN + 42.0,
              bottom: (packMember.attendenceState <= 0 ? 4.5 : 5.5) + (packMember.homeKennelName == null ? 6.0 : 0.0),
              child: ((packMember.hemId != null) && (indicatorAttendenceUpdating.containsKey('hem:' + (packMember.hemId.toString().toLowerCase() ?? ''))) || ((packMember.hasherId != null) && (indicatorRsvpUpdating.containsKey('hid:' + (packMember.hasherId.toString().toLowerCase() ?? '')))))
                  ? Container()
                  : (packMember.rsvpState != rsvpYes.value)
                      ? Container()
                      : packMember.attendenceState == attendenceNo.value
                          ? Image.asset('images/icons/not_at_hash_icon.png', height: 24.0, width: 24.0, color: Colors.red[700])
                          : packMember.attendenceState == attendenceAtHash.value
                              ? Image.asset('images/icons/runner_icon.png', height: 24.0, width: 24.0, color: Colors.orange)
                              : packMember.attendenceState >= attendenceOnIn.value ? Image.asset('images/icons/beer_icon.png', height: 24.0, width: 24.0, color: Colors.green) : Container(),
            ),
            Positioned(
              left: LIST_ITEM_LEFT_MARGIN + 80.0,
              bottom: packMember.homeKennelName == null ? 9.0 : 3.0,
              child: ((packMember.hemId != null) && (indicatorPaidUpdating.containsKey('hem:' + (packMember.hemId.toString().toLowerCase() ?? ''))) || ((packMember.hasherId != null) && (indicatorRsvpUpdating.containsKey('hid:' + (packMember.hasherId.toString().toLowerCase() ?? '')))))
                  ? Icon(delayIcon, color: Colors.blue[800])
                  : (packMember.attendenceState < attendenceAtHash.value)
                      ? CircleAvatar(
                          backgroundColor: Colors.grey[350],
                          radius: 14.0,
                        )
                      : (packMember.rsvpState != rsvpYes.value)
                          ? CircleAvatar(
                              backgroundColor: Colors.grey[350],
                              radius: 14.0,
                            )
                          : CircleAvatar(
                              backgroundColor: packMember.attendenceState == 0 ? Colors.transparent : Colors.white,
                              radius: 14.0,
                            ),
            ),

            Positioned(
                left: LIST_ITEM_LEFT_MARGIN + 82.0,
                bottom: (packMember.attendenceState < -1 ? 4.5 : 5.5) + (packMember.homeKennelName == null ? 6.0 : 0.0),
                child: ((packMember.hemId != null) && (indicatorPaidUpdating.containsKey('hem:' + (packMember.hemId.toString().toLowerCase() ?? ''))) || ((packMember.hasherId != null) && (indicatorRsvpUpdating.containsKey('hid:' + (packMember.hasherId.toString().toLowerCase() ?? '')))))
                    ? Container()
                    : (packMember.attendenceState < attendenceAtHash.value)
                        ? Container()
                        : (packMember.rsvpState != rsvpYes.value)
                            ? Container()
                            : (packMember.attendenceState <= attendenceNo.value)
                                ? Image.asset('images/icons/dollar_sign_icon.png', height: 24.0, width: 24.0, color: Colors.transparent)
                                : packMember.isPaid == isPaidNo.value
                                    ? Image.asset('images/icons/dollar_sign_icon.png', height: 24.0, width: 24.0, color: Colors.red)
                                    : packMember.isPaid == isPaidYes.value ? Image.asset('images/icons/payment_type_${packMember.paymentType}.png', height: 24.0, width: 24.0, color: Colors.green) : Container()),


            (packMember.currentHaringCount == null) || (packMember.currentHaringCount == 0)
                ? Container()
                : Positioned(
                    right: 4,
                    bottom: 17,
                    child: Text('Hared = ${packMember.currentHaringCount}' , style:getRunLabelStyle(packMember.currentPackRunCount+packMember.currentHaringCount,packMember.attendenceState)),
                  ),
            packMember.currentPackRunCount == null
                ? Container()
                : Positioned(
                    right: 4,
                    bottom: 1,
                    child: Text('Runs = ${packMember.currentPackRunCount + packMember.currentHaringCount}', style:getRunLabelStyle(packMember.currentPackRunCount+packMember.currentHaringCount,packMember.attendenceState)),
                  ),
            //packMember.currentPackRunCount == null ? Container() : Positioned(right: 20, bottom: 1, child: Text('Times hared = ${packMember.currentHaringCount}')),
          ],
        ),
      ),
    );
  }

  TextStyle getRunLabelStyle(int numRuns,int attendenceState)
  {
    if (attendenceState >= attendenceAtHash.value)
    {
      if ((numRuns == 1)
          || (numRuns == 5)
          || (numRuns == 10)
          || (numRuns % 25 == 0)
          || (numRuns % 100 == 69))
          {
            return mediumTextRed;
          }
    }
    return mediumText;
  }

  bool checkSpecialRun(int runCount) {
    bool result = false;
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

  void updateRsvpState(CheckInPackModel packMember, int rsvpState, int attendenceState, int isHare) {
    final String hemId = packMember.hemId;
    final String hasherId = packMember.hasherId;

    setState(() {
      // these are here to manage the loading indicator on the list items
      // basically, we keep a list of the items that are loading
      // and then remove them from the list once they are loaded
      // there is probably a better way to do this, but this is all I could
      // think of at the time.
      if (rsvpState != -1) {
        if (!indicatorRsvpUpdating.containsKey(packMember.hemId.toString().toLowerCase())) {
          if (!indicatorRsvpUpdating.containsKey(packMember.hasherId.toString().toLowerCase())) {
            indicatorRsvpUpdating.addAll(<String, String>{packMember.hemId != null ? 'hem:' + packMember.hemId.toString().toLowerCase() : 'hid:' + packMember.hasherId.toString().toLowerCase(): packMember.hemUpdatedAt.toString() ?? ''});
          }
        }
      }

      if (attendenceState != -1) {
        if (!indicatorAttendenceUpdating.containsKey(packMember.hemId.toString().toLowerCase())) {
          if (!indicatorAttendenceUpdating.containsKey(packMember.hasherId.toString().toLowerCase())) {
            indicatorAttendenceUpdating.addAll(<String, String>{packMember.hemId != null ? 'hem:' + packMember.hemId.toString().toLowerCase() : 'hid:' + packMember.hasherId.toString().toLowerCase(): packMember.hemUpdatedAt.toString() ?? ''});
            print('updating attendence indicator @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
          }
        }
      }
    });

    final HasherEventMapService hemSrv = HasherEventMapService();
    final Future<List<dynamic>> retVal = hemSrv.joinEvent(widget.eventAggregate.event.eventId, HasherEventMapTableType.eventAdmin, hasherId, hemId, rsvpState: rsvpState, attendenceState: attendenceState, isHare: isHare, virginVisitorType: -1);

    retVal.then((List<dynamic> adHocData) {
      _refreshPackListFromTables(false).then((void dummy) {
        _refreshCounters(true);
      });
    });
  }

  Future<List<dynamic>> payForEvent(CheckInPackModel packMember, int paymentType, {num otherAmount = -1}) async {
    final String hemId = packMember.hemId;
    final String hasherId = packMember.hasherId;
    num amount = packMember.isMember != 0 ? widget.eventAggregate.extensions.memberPrice : widget.eventAggregate.extensions.nonMemberPrice;
    if (otherAmount != -1) {
      amount = otherAmount;
    }

    setState(() {
      // these are here to manage the loading indicator on the list items
      // basically, we keep a list of the items that are loading
      // and then remove them from the list once they are loaded
      // there is probably a better way to do this, but this is all I could
      // think of at the time.
      if ((packMember.rsvpState ?? 0) < rsvpYes.value) {
        if (!indicatorRsvpUpdating.containsKey(packMember.hemId.toString().toLowerCase())) {
          if (!indicatorRsvpUpdating.containsKey(packMember.hasherId.toString().toLowerCase())) {
            indicatorRsvpUpdating.addAll(<String, String>{packMember.hemId != null ? 'hem:' + packMember.hemId.toString().toLowerCase() : 'hid:' + packMember.hasherId.toString().toLowerCase(): packMember.hemUpdatedAt.toString() ?? ''});
          }
        }
      }

      if ((packMember.attendenceState ?? 0) < attendenceAtHash.value) {
        if (!indicatorAttendenceUpdating.containsKey(packMember.hemId.toString().toLowerCase())) {
          if (!indicatorAttendenceUpdating.containsKey(packMember.hasherId.toString().toLowerCase())) {
            indicatorAttendenceUpdating.addAll(<String, String>{packMember.hemId != null ? 'hem:' + packMember.hemId.toString().toLowerCase() : 'hid:' + packMember.hasherId.toString().toLowerCase(): packMember.hemUpdatedAt.toString() ?? ''});
          }
        }
      }
    });

    indicatorPaidUpdating.addAll(<String, String>{packMember.hemId != null ? 'hem:' + packMember.hemId.toString().toLowerCase() : 'hid:' + packMember.hasherId.toString().toLowerCase(): packMember.payUpdatedAt.toString() ?? ''});

    final PaymentsService paySrv = PaymentsService();
    return paySrv.payForEvent(
      widget.eventAggregate.event.eventId,
      ((hasherId == null) || (hasherId.length != GUID_EMPTY.length)) ? GUID_EMPTY : hasherId,
      ((hemId == null) || (hemId.length != GUID_EMPTY.length)) ? GUID_EMPTY : hemId,
      paymentType,
      amount,
      attendenceAtHash.value,
    );
  }

  Widget buildPackListView() {
    print('buildPackListView: ${DateTime.now().millisecondsSinceEpoch.toString()}');
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollNotification) {
        if (scrollNotification is UserScrollNotification) {
          searchFocusNode.unfocus();
          _scaffoldKey.currentState.hideCurrentSnackBar();
        }
        return true;
      },
      child: RefreshIndicator(
        displacement: 120,
        onRefresh: () async {
          _refreshSqlTablesFromBackend(true);
        },
        child: ListView.separated(
          separatorBuilder: (BuildContext context, int index) => const Divider(
            height: 1.0,
            color: Colors.black45,
          ),
          physics: const AlwaysScrollableScrollPhysics(),
          scrollDirection: Axis.vertical,
          controller: scrollController,
          itemCount: (filteredList?.length ?? 0) + (searchController.text.isNotEmpty ? 1 : 0),
          itemBuilder: (BuildContext context, int index) {
            if ((index == (filteredList?.length ?? 0)) && (searchController.text.isNotEmpty)) {
              return getAddHasherBlock();
            } else {
              final CheckInPackModel packMember = filteredList[index];
              final Key key = Key(index.toString());
              return Dismissible(
                child: listItem(context, packMember),
                key: key,
                confirmDismiss: (DismissDirection direction) {
                  if (packMember.isPaid != 1) {
                    print(direction.toString() + ' ' + index.toString());
                    payForEvent(packMember, direction == DismissDirection.endToStart ? 3 : 4).then((List<dynamic> results) {
                      _refreshPackListFromTables(false).then((void dummy) {
                        _refreshCounters(true);
                        BankTransferQr.showBankTransferSnackbar(widget.eventAggregate, results, direction == DismissDirection.endToStart ? paymentCash.value : paymentBankTransfer.value, context, packMember.nameForDisplay, packMember.isMember, -1);
                      });
                    });
                  } else {
                    if (direction == DismissDirection.endToStart) {
                      updateRsvpState(packMember, -1, attendenceOnIn.value, -1);
                    }
                  }
                  return Future<bool>.value(false);
                },
                background: packMember.isPaid == 1
                    ? Container(
                        color: Colors.grey,
                        child: Row(
                          children: const <Widget>[
                            Padding(
                              padding: EdgeInsets.only(left: 15.0),
                              child: Icon(FontAwesome.check_circle, size: 35.0, color: Colors.white),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 15.0),
                              child: Text(
                                'Already paid',
                                style: TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 20.0, height: 1.0),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        color: Colors.blue,
                        child: Row(
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(left: 15.0),
                              child: Image.asset('images/icons/payment_type_4.png', height: 30.0, width: 30.0, color: Colors.white),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 15.0),
                              child: Text('${Utilities.getFormattedMoney(packMember.isMember != 0 ? widget.eventAggregate.extensions.memberPrice : widget.eventAggregate.extensions.nonMemberPrice, widget.eventAggregate.extensions.digAfterDec, widget.eventAggregate.extensions.curSym)} Bank Transfer',
                                  style: const TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 20.0, height: 1.0)),
                            ),
                          ],
                        ),
                      ),
                secondaryBackground: packMember.isPaid == 1
                    ? packMember.attendenceState >= attendenceOnIn.value
                        ? Container(
                            color: Colors.grey,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: const <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(right: 15.0),
                                  child: Icon(FontAwesome.check_circle, size: 35.0, color: Colors.white),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(right: 15.0),
                                  child: Text(
                                    'Already marked On-In',
                                    style: TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 20.0, height: 1.0),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            color: Colors.amber[800],
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: const <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(right: 15.0),
                                  child: Icon(Ionicons.ios_beer, size: 35.0, color: Colors.white),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(right: 15.0),
                                  child: Text(
                                    'Record as On-In',
                                    style: TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 20.0, height: 1.0),
                                  ),
                                ),
                              ],
                            ),
                          )
                    : Container(
                        color: Colors.green,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(right: 15.0),
                              child: Image.asset('images/icons/payment_type_3.png', height: 30.0, width: 30.0, color: Colors.white),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 15.0),
                              child: Text('${Utilities.getFormattedMoney(packMember.isMember != 0 ? widget.eventAggregate.extensions.memberPrice : widget.eventAggregate.extensions.nonMemberPrice, widget.eventAggregate.extensions.digAfterDec, widget.eventAggregate.extensions.curSym)} Cash',
                                  style: const TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 20.0, height: 1.0)),
                            ),
                          ],
                        ),
                      ),
                onDismissed: (DismissDirection direction) {
                  print(direction.toString() + ' NOTE: We should never reach this point');
                },
              );
            }
          },
        ),
      ),
    );
  }

  String capitalizeFirstLetter(String s) => (s?.isNotEmpty ?? false) ? '${s[0].toUpperCase()}${s.substring(1)}' : s;

  Widget getAddHasherBlock() {
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
              hashNameFromSearch: capitalizeFirstLetter(searchController.text),
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

            searchText = result.dispName ?? result.hashName ?? '${result.firstName} ${result.lastName}' ?? '<error no name entered>';
            searchController.text = searchText;
            filterPackListResults();
          }
        });
      },
      child: Container(
        height: 80,
        margin: const EdgeInsets.only(left: 10),
        child: Row(children: <Widget>[
          Icon(SimpleLineIcons.question, size: 35.0, color: Theme.of(context).accentColor),
          Expanded(
              child: Padding(
            padding: const EdgeInsets.only(left: 14.0, right: 10.0),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Text('Can\'t find a Hasher?', style: smallContentStyleDb),
              AutoSizeText(
                'Click here to add \'${capitalizeFirstLetter(searchController.text)}\'',
                style: smallContentStyle,
                maxLines: 1,
              ),
            ]),
          ))
        ]),
      ),
    );
  }
}

class AddVisitorVirginPopup extends StatefulWidget {
  const AddVisitorVirginPopup();

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
        FlatButton(
          color: Colors.red,
          child: const Text('Cancel'),
          textColor: Colors.white,
          onPressed: () {
            Navigator.of(context).pop(<String, String>{'type': 'cancel', 'amount': ''});
          },
        ),

        FlatButton(
            color: Colors.blue,
            child: const Text('Add Visitor'),
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).pop(<String, String>{
                'type': enumAnonymousVisitor.value.toString(),
                'name': nameTextController.text,
                'email': emailTextController.text,
                'phone': phoneTextController.text,
              });
            }),

        FlatButton(
            color: Colors.blue,
            child: const Text('Add Virgin'),
            textColor: Colors.white,
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





List<int> filterValues = <int>[0, 0, 0, 0, 0, 0, 0];

class CheckinFiltersCell extends StatelessWidget {
  const CheckinFiltersCell({@required this.counter, @required this.index, @required this.label, @required this.onTap, this.color, this.icon, this.useTriState = true});

  final IconData icon;
  final Color color;
  final Function onTap;
  final num counter;
  final String label;
  final int index;
  final bool useTriState;

  @override
  Widget build(BuildContext context) {
    //final String total = (creditAmount ?? 0) <= 0 ? '' : Utilities.getFormattedMoney(creditAmount ?? 0, digitsAfterDecimal, currencySymbol);

    const TextStyle textStyle = TextStyle(color: Colors.black, fontSize: 24.0, fontFamily: 'AvenirNextCondensedDemiBold');
    return Container(
      width: 50,
      child: Column(
        children: <Widget>[
          Text(
            counter < 0 ? '' : (counter ?? 0).toString(),
            style: textStyle,
          ),
          IconButton(
            padding: const EdgeInsets.all(0),
            onPressed: () {
              if (index >= 0) {
                filterValues[index]++;
                if (filterValues[index] > 1) {
                  filterValues[index] = useTriState ? -1 : 0;
                }
              }
              onTap();
            },
            icon: Icon(icon != null ? icon : filterValues[index] == -1 ? FontAwesome.times_circle : filterValues[index] == 0 ? FontAwesome.circle_thin : FontAwesome.check_circle,
                size: 35, color: color != null ? color : filterValues[index] == -1 ? Colors.red : filterValues[index] == 0 ? Colors.grey[350] : Colors.green),
          ),
          Container(
            child: AutoSizeText(
              label,
              style: textStyle,
              maxLines: 1,
              minFontSize: 2.0,
            ),
            height: 20,
          ),
        ],
      ),
    );
  }
}
