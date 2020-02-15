import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/pages/top_level/kennel_list_page.dart';
import 'package:harrier_central/pages/run_admin/find_hasher_page.dart';
import 'package:harrier_central/widgets/kennel_member_list_item.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/widgets/circular_progress_indicator.dart';
import 'package:harrier_central/data/hc3_services/base_service.dart';
import 'package:harrier_central/data/hc3_services/sync_kennel_admin_service.dart';
import 'package:harrier_central/data/hc3_services/hasher_kennel_map_service.dart';
import 'package:harrier_central/data/hc3_services/hashers_service.dart';
import 'package:harrier_central/pages/menu_pages/hasher_profile_page.dart';
import 'package:harrier_central/widgets/filter_cell.dart';

class KennelMembersList extends StatefulWidget {
  const KennelMembersList({Key key, @required this.kennel}) : super(key: key);

  final KennelListAggregate kennel;

  @override
  KennelMemberListState createState() => KennelMemberListState();
}

class KennelMembersResults {
  KennelMembersResults(
      {this.hasherId,
      this.dispName,
      this.photo,
      this.following,
      this.kennelId,
      this.dateOfLastRun,
      this.kennelEmailAlertPreference,
      this.membershipExpirationDate,
      this.memberSince,
      this.membershipDurationInMonths,
      this.isLoading = false,
      this.kennelShortName,
      this.homeKennelName,
      this.homeKennelId,
      this.homeKennelBeingUpdated = false,
      this.membershipDateBeingUpdated = false});

  final String hasherId;
  String dispName;
  String photo;
  final int following;
  final String kennelId;
  final DateTime dateOfLastRun;
  int kennelEmailAlertPreference;
  final DateTime membershipExpirationDate;
  final DateTime memberSince;
  final int membershipDurationInMonths;
  bool isLoading;
  bool membershipDateBeingUpdated;
  bool homeKennelBeingUpdated;
  String kennelShortName;
  String homeKennelName;
  String homeKennelId;

  static KennelMembersResults fromMap(Map<String, dynamic> map) {
    final KennelMembersResults item = KennelMembersResults(
      hasherId: map['hasherId'],
      dispName: map['dispName'],
      photo: map['photo'],
      following: map['following'],
      kennelShortName: map['kennelShortName'],
      homeKennelName: map['homeKennelName'],
      homeKennelId: map['homeKennelId'],
      kennelId: map['kennelId'],
      dateOfLastRun: (map['dateOfLastRun'] == null) ? null : DateTime.parse(map['dateOfLastRun'].toString().substring(0, 19)),
      kennelEmailAlertPreference: map['kennelEmailAlertPreference'],
      membershipExpirationDate: (map['membershipExpirationDate'] == null) ? null : DateTime.parse(map['membershipExpirationDate'].toString().substring(0, 19)),
      memberSince: (map['memberSince'] == null) ? null : DateTime.parse(map['memberSince'].toString().substring(0, 19)),
      membershipDurationInMonths: map['membershipDurationInMonths'],
    );
    return item;
  }
}

enum EnumSortByType { sortByName, sortByLastRunDate, sortByMembershipExpirationDate }

class KennelMemberListState extends State<KennelMembersList> with SingleTickerProviderStateMixin {
  KennelMemberListState();

  EnumSortByType _sortBy = EnumSortByType.sortByName;

  Future<List<KennelMembersResults>> kennelMemberListFuture = Future<List<KennelMembersResults>>.value(<KennelMembersResults>[]);
  Future<List<KennelMembersResults>> filteredKennelMemberListFuture = Future<List<KennelMembersResults>>.value(<KennelMembersResults>[]);

  GlobalKey packListBoxKey = GlobalKey();

  AnimationController animationController;
  Animation<double> buttonAnimation;
  Animation<Offset> filterPanelAnimation;
  Animation<RelativeRect> hasherListAnimation;
  ScrollController scrollController = ScrollController(initialScrollOffset: 0.0);
  FocusNode searchFocusNode;
  TextEditingController searchController;
  String searchTypeText;
  bool showFilter = false;
  List<int> filterValues = <int>[0, 0, 0, 0, 0, 0, 0];

  static const int FILTER_IS_MEMBER = 0;
  static const int FILTER_IS_FOLLOWING = 1;
  static const int FILTER_IS_HOME_KENNEL = 2;
  static const int FILTER_RUNS_IN_LAST_YEAR = 3;

  TextStyle localFootnoteSmallRed = footnoteSmallRed.copyWith(fontSize: 12 * deviceWidthScaleFactor);
  TextStyle localFootnoteSmall = footnoteSmall.copyWith(fontSize: 12 * deviceWidthScaleFactor);

  String searchText = '';

  static const String searchKennel = 'Searching Kennel members';
  static const String searchAllHashers = 'Searching all Hashers';
  bool highlightSearchType = false;

  @override
  void initState() {
    appBar = AppBar(
      centerTitle: true,
      backgroundColor: themeAppBarBackground,
      title: Text(
        '${widget.kennel.kennel.kennelShortName} Members',
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
    );
    refreshKennelMembersFromTable(true).then((void dummy) {
      _refreshCounters(true);
      setState(() {});
    });
    setSortBySpeedDial();
    super.initState();

    searchTypeText = searchKennel;
    searchController = TextEditingController();
    searchFocusNode = FocusNode();

    animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    buttonAnimation = Tween<double>(begin: 0, end: 90.0 / 360.0).animate(animationController)
      ..addListener(() {
        setState(() {});
      });
  }

  Future<void> refreshKennelMembersFromTable(bool forceRefresh) async {
    final Database db = await DBProvider.db.database;

    String orderBy = 'lower(h.dispName)';

    switch (_sortBy) {
      case EnumSortByType.sortByName:
        orderBy = 'lower(h.dispName)';
        break;
      case EnumSortByType.sortByLastRunDate:
        orderBy = 'hkm.dateOfLastRun desc';
        break;
      case EnumSortByType.sortByMembershipExpirationDate:
        orderBy = 'hkm.membershipExpirationDate asc';
        break;
    }

    final String query = ''' 
        SELECT 
          h.hasherId,
          h.dispName,
          h.photo,
          hkm.following,
          hkm.dateOfLastRun,
          hkm.kennelEmailAlertPreference,
          hkm.membershipExpirationDate,
          hkm.memberSince,
          k.membershipDurationInMonths,
          k.kennelShortName,
          k.kennelId,
          hk.kennelName as homeKennelName,
          hk.kennelId as homeKennelId
          FROM hasherKennelMapForKennelAdmin hkm
          INNER JOIN kennels k on k.kennelId = hkm.kennelId
          INNER JOIN hashers h on h.hasherId = hkm.userId
          LEFT OUTER JOIN kennels hk on hk.kennelId = h.homeKennelId
          WHERE hkm.membershipExpirationDate >= date('now') OR hkm.following = 1
          ORDER BY $orderBy
          
          ''';

    kennelMemberListFuture = Future<List<KennelMembersResults>>.value(<KennelMembersResults>[]);

    final List<KennelMembersResults> kList = <KennelMembersResults>[];

    try {
      final List<Map<String, dynamic>> results = await db.rawQuery(query);
      for (int i = 0; i < results.length; i++) {
        final KennelMembersResults hlrItem = KennelMembersResults.fromMap(results[i]);
        hlrItem.isLoading = false;
        kList.add(hlrItem);

        if (forceRefresh && (i == results.length - 1)) {
          setState(() {
            kennelMemberListFuture = Future<List<KennelMembersResults>>.value(kList);
            filterResults();
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  String sortBySpeedDialLabel = '';
  IconData sortBySpeedDialIcon;
  EnumSortByType sortBySpeedDialType;

  AppBar appBar;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void setSortBySpeedDial() {
    switch (_sortBy) {
      case EnumSortByType.sortByName:
        sortBySpeedDialLabel = 'Sort by Date\r\nof last run';
        sortBySpeedDialType = EnumSortByType.sortByLastRunDate;
        sortBySpeedDialIcon = FontAwesome.sort_numeric_desc;
        break;
      case EnumSortByType.sortByLastRunDate:
        sortBySpeedDialLabel = 'Sort by Date\r\nmembership expires';
        sortBySpeedDialType = EnumSortByType.sortByMembershipExpirationDate;
        sortBySpeedDialIcon = FontAwesome.sort_numeric_desc;
        break;
      case EnumSortByType.sortByMembershipExpirationDate:
        sortBySpeedDialLabel = 'Sort by Name';
        sortBySpeedDialType = EnumSortByType.sortByName;
        sortBySpeedDialIcon = FontAwesome.sort_alpha_asc;
        break;
    }
  }

  int countIsMember = 0;
  int countIsFollowing = 0;
  int countIsHomeKennel = 0;
  int countHasRecentRuns = 0;

  Future<void> _refreshCounters(bool forceRefresh) async {
    final Database db = await DBProvider.db.database;
    try {
      final String sql = ''' 

          SELECT 
              COUNT(CASE WHEN ${hasherKennelMapTableHelper.colFollowing} > 0 THEN 1 ELSE NULL END) as isFollowing,
              COUNT(CASE WHEN ${hasherKennelMapTableHelper.colMembershipExpirationDate} > date('now') THEN 1 ELSE NULL END) as isMember,
              COUNT(CASE WHEN ${hasherKennelMapTableHelper.colKennelId} = ${hashersTableHelper.colHomeKennelId} THEN 1 ELSE NULL END) as isHomeKennel,
              COUNT(CASE WHEN ${hasherKennelMapTableHelper.colDateOfLastRun} >= date('now','-365 day') THEN 1 ELSE NULL END) as hasRecentRuns
              FROM ${hasherKennelMapTableHelper.getTableName(TableType.hkmKennelAdmin)} hkm
              INNER JOIN ${hashersTableHelper.tableName} h on h.${hashersTableHelper.colHasherId} = hkm.${hasherKennelMapTableHelper.colUserId}
  
          ''';

      db.rawQuery(sql).then((List<Map<String, dynamic>> results) {
        if (results.isNotEmpty) {
          countIsMember = results[0]['isMember'];
          countIsFollowing = results[0]['isFollowing'];
          countIsHomeKennel = results[0]['isHomeKennel'];
          countHasRecentRuns = results[0]['hasRecentRuns'];
        }
        if (forceRefresh) {
          setState(() {});
        }
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    filterPanelAnimation ??= Tween<Offset>(begin: const Offset(0, -.35), end: const Offset(0, .71)).animate(animationController);
    hasherListAnimation ??= RelativeRectTween(begin: const RelativeRect.fromLTRB(0, 86, 0, 0), end: const RelativeRect.fromLTRB(0, 204, 0, 0)).animate(animationController);
    return Scaffold(
      appBar: appBar,
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
              child: Icon(sortBySpeedDialIcon),
              backgroundColor: Colors.deepOrange,
              label: sortBySpeedDialLabel,
              labelStyle: const TextStyle(fontSize: 18.0),
              onTap: () {
                _sortBy = sortBySpeedDialType;
                refreshKennelMembersFromTable(true).then((void dummy) {
                  _refreshCounters(true);
                });
                setSortBySpeedDial();
              }),
          SpeedDialChild(
              child: const Icon(MaterialCommunityIcons.account_search),
              backgroundColor: Colors.blue,
              label: 'Find Hasher and add',
              labelStyle: const TextStyle(fontSize: 18.0),
              onTap: () {
                Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute<Map<String, dynamic>>(
                    settings: const RouteSettings(),
                    builder: (BuildContext context) {
                      return const FindHasherPage(FindHasherPageType.addMember);
                    },
                  ),
                ).then((Map<String, dynamic> result) {
                  setState(() {
                    //_isLoading = true;
                  });
                  if ((result != null) && (result['hasher']?.hasherId != null)) {
                    final HasherKennelMapService srv = HasherKennelMapService();
                    widget.kennel.extensions.followingRequested = -1;
                    setState(() {});
                    srv.updateHasherKennelStatus(widget.kennel.kennel.kennelId, TableType.hkmKennelAdmin, monthsToAddToMembership: widget.kennel.kennel.membershipDurationInMonths, targetUserId: result['hasher'].hasherId).then((void dummy) {
                      refreshKennelMembersFromTable(true).then((void dummy) {
                        _refreshCounters(true);
                      });
                    });
                  }
                });
              }),
          SpeedDialChild(
              child: const Icon(Icons.person_add),
              backgroundColor: Colors.green,
              label: 'Add new Hasher\r\nto Harrier Central',
              labelStyle: const TextStyle(fontSize: 18.0),
              onTap: () {
                Navigator.push<HashersModel>(
                  context,
                  MaterialPageRoute<HashersModel>(
                    builder: (BuildContext context) => HasherProfilePage(
                      dataContext: EnumDataContext.kennel,
                      pageType: EnumMyProfilePageType.newHasherProfile,
                      kennelId: widget.kennel.kennel.kennelId,
                      uiElementsToDisplay: HasherProfilePage.flagUiElement_followKennel,
                      kennelShortName: widget.kennel.kennel.kennelShortName,
                    ),
                  ),
                ).then((HashersModel result) {
                  refreshKennelMembersFromTable(true).then((void dummy) {
                    _refreshCounters(true);
                  });
                });
              }),
        ],
      ),
      body: Stack(
        fit: StackFit.loose,
        alignment: AlignmentDirectional.topStart,
        children: <Widget>[
          Container(height: MediaQuery.of(context).size.height, width: 10),
          // (snapshot?.data == null || snapshot.data.isEmpty)

          //     //? Positioned(top: (filterPanelAnimation.value.dy * 120) + 125, left: 0, right: 0, child: getAddHasherBlock())
          //     ? Positioned(top: (filterPanelAnimation.value.dy * 120) + 125, left: 0, right: 0, child: Container(color:Colors.red))
          //     :

          PositionedTransition(
            rect: hasherListAnimation,
            child: Container(
              key: packListBoxKey,
              height: 300,
              child: FutureBuilder<List<KennelMembersResults>>(
                  future: filteredKennelMemberListFuture,
                  builder: (BuildContext context, AsyncSnapshot<List<KennelMembersResults>> snapshot) {
                    if (snapshot?.data == null) {
                      return const HcCircularProgressIndicator();
                    } else {
                      return getKennelMemberList(snapshot);
                    }
                  }),
            ),
          ),
          SlideTransition(position: filterPanelAnimation, child: filterBar()),
          Positioned(top: 0, child: searchBar()),
        ],
      ),
    );
  }

  Column getKennelMemberList(AsyncSnapshot<List<KennelMembersResults>> snapshot) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 0.0),
            child: snapshot.data.isEmpty
                ? const Center(child: Text('No members found.'))
                : RefreshIndicator(
                    onRefresh: () => _handleRefresh(),
                    displacement: 40.0,
                    child: ListView.separated(
                      separatorBuilder: (BuildContext context, int index) => const Divider(
                        height: 1.0,
                        color: Colors.black45,
                      ),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: snapshot.data.length,
                      itemBuilder: (BuildContext context, int index) {
                        final KennelMembersResults item = snapshot.data[index];
                        return Dismissible(
                          key: Key(item.hasherId),
                          confirmDismiss: (DismissDirection direction) {
                            setState(() {
                              // swipe from right to left to indicate that
                              // the hasher either attended the run as a pack
                              // member or as a hare
                              if (direction == DismissDirection.endToStart) {
                                modifyMembership(item, item.membershipDurationInMonths);
                              } else {
                                modifyMembership(item, -9999);
                              }
                            });

                            return Future<bool>.value(false);
                          },
                          background: Container(
                              color: Colors.red,
                              child: Row(children: const <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(left: 10.0),
                                  child: Icon(FontAwesome.times_circle, color: Colors.white, size: 35.0),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(left: 15.0),
                                  child: Text(
                                      // '${Utilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Bank Transfer',
                                      'Cancel\r\nmembership',
                                      maxLines: 2,
                                      style: TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 17.0, height: 1.0)),
                                )
                              ])),
                          secondaryBackground: Container(
                            color: Colors.green,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                const Padding(
                                  padding: EdgeInsets.only(right: 15.0),
                                  child: Icon(FontAwesome.plus_circle, color: Colors.white, size: 35.0),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 15.0),
                                  child: Text(
                                      //'${Utilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Cash',
                                      'Add ${item.membershipDurationInMonths} months\r\nto membership',
                                      style: const TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 17.0, height: 1.0)),
                                )
                              ],
                            ),
                          ),
                          onDismissed: (DismissDirection direction) {
                            print(direction.toString() + ' NOTE: We should never reach this point');
                          },
                          child: KennelMemberListItem(
                              kennelId: widget.kennel.kennel.kennelId,
                              kennelMember: snapshot.data[index],
                              modifyMembershipCallback: (EnumMemberPopupActions retVal) {
                                switch (retVal) {
                                  case EnumMemberPopupActions.addOneMonth:
                                    modifyMembership(snapshot.data[index], 1);
                                    break;
                                  case EnumMemberPopupActions.addSixMonths:
                                    modifyMembership(snapshot.data[index], 6);
                                    break;
                                  case EnumMemberPopupActions.subtractOneMonth:
                                    modifyMembership(snapshot.data[index], -1);
                                    break;
                                  case EnumMemberPopupActions.subtractSixMonths:
                                    modifyMembership(snapshot.data[index], -6);
                                    break;
                                  case EnumMemberPopupActions.cancelMembership:
                                    modifyMembership(snapshot.data[index], -9999);
                                    break;
                                  case EnumMemberPopupActions.toggleHomeKennel:
                                    setAsHomeKennel(snapshot.data[index], 1);
                                    break;
                                  case EnumMemberPopupActions.setHomeKennel:
                                    setAsHomeKennel(snapshot.data[index], 1);
                                    break;
                                  case EnumMemberPopupActions.clearHomeKennel:
                                    setAsHomeKennel(snapshot.data[index], 0);
                                    break;
                                }
                              },
                              toggleEmailPreferenceCallback: () {
                                if (Utilities.checkForConnection(context, message: 'Setting Kennel email alerts is not available in offline mode. Please connect to the Internet to change the notification preferences for a kennel.')) {
                                  final HasherKennelMapService srv = HasherKennelMapService();
                                  final int emailAlertStatus = snapshot.data[index].kennelEmailAlertPreference != 1 ? 1 : 2;
                                  snapshot.data[index].kennelEmailAlertPreference = -1;
                                  setState(() {});
                                  srv.updateHasherKennelStatus(widget.kennel.kennel.kennelId, TableType.hkmKennelAdmin, emailAlertState: emailAlertStatus, targetUserId: snapshot.data[index].hasherId).then((List<dynamic> queryResults) {
                                    setState(() {
                                      if ((queryResults != null) && (queryResults.isNotEmpty)) {
                                        snapshot.data[index].kennelEmailAlertPreference = queryResults[0]['kennelEmailAlertPreference'];
                                      }
                                    });
                                  });
                                }
                              }),
                        );
                      },
                    ),
                  ),
          ),
        ),
      ],
    );
  }

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
                    searchController.text = '';
                    searchText = '';
                    refreshKennelMembersFromTable(true).then((void dummy) {
                      _refreshCounters(true);
                      setState(() {});
                    });
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
                          filterResults();
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
                    //_refreshPackListFromTables(true);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> filterResults() async {
    bool ignoreTextFilter = false;
    final String temp = searchTypeText;

    final List<KennelMembersResults> fullList = await kennelMemberListFuture;
    List<KennelMembersResults> filteredList;

    if (showFilter) {
      filteredList = fullList
          .where((KennelMembersResults a) => 
          ((filterValues[FILTER_IS_MEMBER] == 0) || (filterValues[FILTER_IS_MEMBER] == -1 && ((a.membershipExpirationDate ?? DateTime.parse('19900101')).isBefore(DateTime.now())) || (filterValues[FILTER_IS_MEMBER] == 1 && (a.membershipExpirationDate ?? DateTime.parse('19900101')).isAfter(DateTime.now()))))
          && ((filterValues[FILTER_IS_FOLLOWING] == 0) || (filterValues[FILTER_IS_FOLLOWING] == -1 && ((a.following ?? 0) == 0)) || (filterValues[FILTER_IS_FOLLOWING] == 1 && (a.following ?? 0) == 1))
          && ((filterValues[FILTER_IS_HOME_KENNEL] == 0) || (filterValues[FILTER_IS_HOME_KENNEL] == -1 && ((a.homeKennelId == null) || ((a.homeKennelId) != (a.kennelId)))) || (filterValues[FILTER_IS_HOME_KENNEL] == 1 && (a.homeKennelId != null) && (a.homeKennelId) == (a.kennelId)))
          && ((filterValues[FILTER_RUNS_IN_LAST_YEAR] == 0) || (filterValues[FILTER_RUNS_IN_LAST_YEAR] == -1 && ((a.dateOfLastRun ?? DateTime.parse('19900101')).isBefore(DateTime.now().add(const Duration(days: -365)))) || (filterValues[FILTER_RUNS_IN_LAST_YEAR] == 1 && (a.dateOfLastRun ?? DateTime.parse('19900101')).isAfter(DateTime.now().add(const Duration(days:-365))))))   
              
              // ((filterValues[1] == 0)
              //     //|| (filterValues[1] == -1 && ((a.attendenceState ?? 0) < 20))
              //     ||
              //     (filterValues[1] == 1 && (a.attendenceState ?? 0) < 20 && (a.rsvpState ?? 0) >= 2)) &&
              // ((filterValues[2] == 0) || (filterValues[2] == -1 && ((a.attendenceState ?? 0) < 20)) || (filterValues[2] == 1 && (a.attendenceState ?? 0) >= 20)) &&
              // ((filterValues[3] == 0) || (filterValues[3] == -1 && ((a.isPaid ?? 0) == 0)) || (filterValues[3] == 1 && (a.isPaid ?? 0) == 1)) &&
              // ((filterValues[4] == 0) || (filterValues[4] == -1 && ((a.attendenceState ?? 0) < 30)) || (filterValues[4] == 1 && (a.attendenceState ?? 0) >= 30)) &&
              // ((filterValues[5] == 0) || (filterValues[5] == -1 && ((a.isMember ?? 0) == 0)) || (filterValues[5] == 1 && (a.isMember ?? 0) == 1))
              )
          .toList();
    } else {
      filteredList = <KennelMembersResults>[];
      filteredList.addAll(fullList);
    }

    if ((searchText != null) && (searchText.isNotEmpty)) {
      filteredList = filteredList.where((KennelMembersResults a) => a.dispName.toLowerCase().contains(searchText.toLowerCase())).toList();
      if (filteredList.isEmpty) {
        // if (!ignoreTextFilter) {
        //   showSnackbar = true;
        // }
        ignoreTextFilter = true;
        //filteredList = allHashers.where((CheckInPackModel a) => a.nameForSort.toLowerCase().contains(searchText.toLowerCase())).toList();
      } else {
        ignoreTextFilter = false;
        _scaffoldKey.currentState.hideCurrentSnackBar();
      }
    } else {
      searchTypeText = searchKennel;
    }

    searchTypeText = ignoreTextFilter ? searchAllHashers : searchKennel;

    filteredKennelMemberListFuture = Future<List<KennelMembersResults>>.value(filteredList ?? fullList);

    if (temp != searchTypeText) {
      highlightSearchType = true;
      Future<void>.delayed(const Duration(milliseconds: 1500)).then((void dummy) {
        setState(() {
          highlightSearchType = false;
        });
      });
    }
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
            counter: countIsMember,
            label: 'Member',
            index: 0,
            onTap: () {
              refreshKennelMembersFromTable(true).then((void dummy) {
                _refreshCounters(true);
                setState(() {});
              });
            },
            filterValues: filterValues,
          ),
          CheckinFiltersCell(
            counter: countIsFollowing,
            label: 'Follow',
            index: 1,
            onTap: () {
              refreshKennelMembersFromTable(true).then((void dummy) {
                _refreshCounters(true);
                setState(() {});
              });
            },
            filterValues: filterValues,
          ),
          CheckinFiltersCell(
            counter: countIsHomeKennel,
            label: 'Home',
            index: 2,
            useTriState: true,
            onTap: () {
              refreshKennelMembersFromTable(true).then((void dummy) {
                _refreshCounters(true);
                setState(() {});
              });
            },
            filterValues: filterValues,
          ),
          CheckinFiltersCell(
            counter: countHasRecentRuns,
            label: 'Have runs',
            index: 3,
            useTriState: true,
            onTap: () {
              refreshKennelMembersFromTable(true).then((void dummy) {
                _refreshCounters(true);
                setState(() {});
              });
            },
            filterValues: filterValues,
          ),
          // CheckinFiltersCell(
          //   counter: countAtHash,
          //   index: 2,
          //   label: 'At Hash',
          //   onTap: () {
          //     _refreshPackListFromTables(true);
          //   },
          //   filterValues: filterValues,
          // ),
          // CheckinFiltersCell(
          //   counter: countPaid,
          //   index: 3,
          //   label: 'Paid',
          //   onTap: () {
          //     _refreshPackListFromTables(true);
          //   },
          // ),
          // CheckinFiltersCell(
          //   counter: countOnIn,
          //   index: 4,
          //   label: 'On In',
          //   onTap: () {
          //     _refreshPackListFromTables(true);
          //   },
          //   filterValues: filterValues,
          // ),
        ],
      ),
    );
  }

  Future<void> _handleRefresh() async {
    final Database db = await DBProvider.db.database;

    setState(() {
      //_isLoading = true;
    });

    final SyncKennelAdminService cSrv = SyncKennelAdminService();
    final bool result = await cSrv.updateFromBackend(db, SyncKennelAdminService.flagKennelTable | SyncKennelAdminService.flagHashersTable | SyncKennelAdminService.flagHasherKennelMapTable, true, widget.kennel.kennel.kennelId);
    final String resultStr = result ? 'successfully' : 'unsuccessfully';
    print('Kennel member data synchronized $resultStr');
    refreshKennelMembersFromTable(true).then((void dummy) {
      _refreshCounters(true);
      setState(() {});
    });
  }

  void modifyMembership(KennelMembersResults item, int monthsToAddToMembership) {
    final HasherKennelMapService srv = HasherKennelMapService();
    widget.kennel.extensions.followingRequested = -1;
    item.membershipDateBeingUpdated = true;
    setState(() {});
    srv.updateHasherKennelStatus(widget.kennel.kennel.kennelId, TableType.hkmKennelAdmin, monthsToAddToMembership: monthsToAddToMembership, targetUserId: item.hasherId).then((void dummy) {
      refreshKennelMembersFromTable(true).then((void dummy) {
        item.membershipDateBeingUpdated = false;
        _refreshCounters(true);
        setState(() {});
      });
    });
  }

  void setAsHomeKennel(KennelMembersResults item, int isHomeKennel) {
    final HasherKennelMapService srv = HasherKennelMapService();
    widget.kennel.extensions.followingRequested = -1;
    item.homeKennelBeingUpdated = true;
    setState(() {});
    srv.updateHasherKennelStatus(widget.kennel.kennel.kennelId, TableType.hkmKennelAdmin, targetUserId: item.hasherId, followingState: followTypeToggleHomeKennel.value, isHomeKennel: isHomeKennel).then((void dummy) {
      refreshKennelMembersFromTable(true).then((void dummy) {
        item.homeKennelBeingUpdated = false;
        _refreshCounters(true);
        setState(() {});
      });
    });
  }
}
