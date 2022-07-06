// @dart=2.11
import 'package:harrier_central/imports.dart';
import 'package:harrier_central/pages/kennel_admin/mismanagement_roles_page.dart';

class KennelMembersList extends StatefulWidget {
  const KennelMembersList({Key key, @required this.kennelListAggregate}) : super(key: key);

  final KennelListAggregate kennelListAggregate;

  @override
  KennelMemberListState createState() => KennelMemberListState();
}

class KennelMembersResults {
  KennelMembersResults(
      {this.hasherId,
      this.dispName,
      this.nameForSort,
      this.photo,
      this.following,
      this.kennelId,
      this.dateOfLastRun,
      this.historicalTotalRunCount,
      this.historicalHaringCount,
      this.hcHaringCount,
      this.hcTotalRunCount,
      this.kennelEmailAlertPreference,
      this.membershipExpirationDate,
      this.memberSince,
      this.membershipDurationInMonths,
      this.isLoading = false,
      this.kennelShortName,
      this.appAccessFlags,
      this.mismanagementRoles,
      this.kennelCredit,
      this.memberFollowingStatus,

      // this.homeKennelName,
      // this.homeKennelBeingUpdated = false,
      this.memberInfoBeingUpdated = false});

  final String hasherId;
  String dispName;
  String nameForSort;
  String photo;
  final int following;
  final String kennelId;
  final DateTime dateOfLastRun;
  final int hcTotalRunCount;
  final int hcHaringCount;
  final int historicalTotalRunCount;
  final int historicalHaringCount;
  int kennelEmailAlertPreference;
  final DateTime membershipExpirationDate;
  final DateTime memberSince;
  final int membershipDurationInMonths;
  int appAccessFlags;
  int mismanagementRoles;
  bool isLoading;
  bool memberInfoBeingUpdated;
  //bool homeKennelBeingUpdated;
  String kennelShortName;
  num kennelCredit;
  int memberFollowingStatus;
  //String homeKennelName;

  static KennelMembersResults fromMap(Map<String, dynamic> map) {
    final KennelMembersResults item = KennelMembersResults(
      hasherId: map['hasherId'],
      dispName: map['dispName'],
      nameForSort: map['nameForSort'],
      photo: map['photo'],
      following: map['following'],
      kennelId: map['kennelId'],
      dateOfLastRun: (map['dateOfLastRun'] == null) ? null : DateTime.parse(map['dateOfLastRun'].toString().substring(0, 19)),
      hcTotalRunCount: map['hcTotalRunCount'],
      hcHaringCount: map['hcHaringCount'],
      historicalTotalRunCount: map['historicalTotalRunCount'],
      historicalHaringCount: map['historicalHaringCount'],
      kennelEmailAlertPreference: map['kennelEmailAlertPreference'],
      membershipExpirationDate: (map['membershipExpirationDate'] == null) ? null : DateTime.parse(map['membershipExpirationDate'].toString().substring(0, 19)),
      memberSince: (map['memberSince'] == null) ? null : DateTime.parse(map['memberSince'].toString().substring(0, 19)),
      membershipDurationInMonths: map['membershipDurationInMonths'],
      appAccessFlags: map['appAccessFlags'],
      mismanagementRoles: map['mismanagementRoles'],
      kennelShortName: map['kennelShortName'],
      kennelCredit: map['kennelCredit'],
      memberFollowingStatus: map['memberFollowingStatus'],
      // homeKennelName: map['homeKennelName'],
    );
    return item;
  }

  Mismanagement get mismanagement {
    return Mismanagement(mismanagementRoles);
  }

  AppAccess get appAccess {
    return AppAccess(appAccessFlags);
  }
}

enum EnumSortByType { sortByName, sortByLastRunDate, sortByMembershipExpirationDate }

class KennelMemberListState extends State<KennelMembersList> with SingleTickerProviderStateMixin {
  KennelMemberListState();

  EnumSortByType _sortBy = EnumSortByType.sortByName;

  Future<List<dynamic>> _kennelMemberListFuture = Future<List<dynamic>>.value(<dynamic>[]);
  Future<List<dynamic>> _filteredKennelMemberListFuture = Future<List<dynamic>>.value(<dynamic>[]);

  final GlobalKey _packListBoxKey = GlobalKey();

  AnimationController _animationController;
  Animation<double> _buttonAnimation;
  Animation<Offset> _filterPanelAnimation;
  Animation<RelativeRect> _hasherListAnimation;
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  bool _showFilter = false;
  final List<int> _filterValues = <int>[0, 0, 0, 0, 0, 0, 0];

  static const int FILTER_IS_MEMBER = 0;
  static const int FILTER_IS_FOLLOWING = 1;
  static const int FILTER_IS_HOME_KENNEL = 2;
  static const int FILTER_RUNS_IN_LAST_YEAR = 3;

  String _searchText = '';

  @override
  void initState() {
    appBar = AppBar(
      centerTitle: true,
      backgroundColor: themeAppBarBackground,
      title: Text(
        '${widget.kennelListAggregate.kennel.kennelShortName} Members',
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
    );
    _refreshKennelMembersFromTable(true).then((void _) {
      _refreshCounters(true);
      setState(() {});
    });
    setSortBySpeedDial();
    super.initState();

    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _buttonAnimation = Tween<double>(begin: 0, end: 90.0 / 360.0).animate(_animationController)
      ..addListener(() {
        setState(() {});
      });
  }

  Future<void> _refreshKennelMembersFromTable(bool forceRefresh) async {
    String orderBy = 'lower(h.${G0<TableModel>().hashersTableHelper.colDispName})';

    switch (_sortBy) {
      case EnumSortByType.sortByName:
        orderBy = 'lower(h.${G0<TableModel>().hashersTableHelper.colDispName})';
        break;
      case EnumSortByType.sortByLastRunDate:
        orderBy = 'hkm.${G0<TableModel>().hasherKennelMapTableHelper.colDateOfLastRun}';
        break;
      case EnumSortByType.sortByMembershipExpirationDate:
        orderBy = 'hkm.${G0<TableModel>().hasherKennelMapTableHelper.colMembershipExpirationDate} asc';
        break;
    }

    final String query = ''' 
        SELECT 
          h.${G0<TableModel>().hashersTableHelper.colHasherId},
          coalesce(h.${G0<TableModel>().hashersTableHelper.colDispName},h.${G0<TableModel>().hashersTableHelper.colHashName},h.${G0<TableModel>().hashersTableHelper.colFirstName} || " " || h.${G0<TableModel>().hashersTableHelper.colLastName},"<no name>") as dispName,
          lower(" " || coalesce(h.${G0<TableModel>().hashersTableHelper.colHashName},"") || " " || coalesce(h.${G0<TableModel>().hashersTableHelper.colDispName},"") || " " || coalesce(h.${G0<TableModel>().hashersTableHelper.colFirstName},"") || " " || coalesce(h.${G0<TableModel>().hashersTableHelper.colLastName},"") || " ") as nameForSort,
          h.${G0<TableModel>().hashersTableHelper.colPhoto},
          hkm.${G0<TableModel>().hasherKennelMapTableHelper.colFollowing},
          hkm.${G0<TableModel>().hasherKennelMapTableHelper.colDateOfLastRun},
          hkm.${G0<TableModel>().hasherKennelMapTableHelper.colKennelEmailAlertPreference},
          hkm.${G0<TableModel>().hasherKennelMapTableHelper.colMembershipExpirationDate},
          hkm.${G0<TableModel>().hasherKennelMapTableHelper.colMemberSince},
          hkm.${G0<TableModel>().hasherKennelMapTableHelper.colAppAccessFlags},
          hkm.${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalTotalRunCount},
          hkm.${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalHaringCount},          
          hkm.${G0<TableModel>().hasherKennelMapTableHelper.colHcHaringCount},
          hkm.${G0<TableModel>().hasherKennelMapTableHelper.colHcTotalRunCount},
          hkm.${G0<TableModel>().hasherKennelMapTableHelper.colAppAccessFlags},
          hkm.${G0<TableModel>().hasherKennelMapTableHelper.colMismanagementRoles},
          hkm.${G0<TableModel>().hasherKennelMapTableHelper.colKennelCredit},
          k.${G0<TableModel>().kennelsTableHelper.colMembershipDurationInMonths},
          k.${G0<TableModel>().kennelsTableHelper.colKennelShortName},
          k.${G0<TableModel>().kennelsTableHelper.colKennelId}
          ,case 
            when hkm.${G0<TableModel>().hasherKennelMapTableHelper.colMembershipExpirationDate} >= date('now') then 1
            when ((hkm.${G0<TableModel>().hasherKennelMapTableHelper.colDateOfLastRun} is not null) AND (hkm.${G0<TableModel>().hasherKennelMapTableHelper.colDateOfLastRun} >= date('now','-182 day'))) then 2
            when hkm.${G0<TableModel>().hasherKennelMapTableHelper.colDateOfLastRun} is not null then 3
            when hkm.${G0<TableModel>().hasherKennelMapTableHelper.colFollowing} = 1 then 4
            else 5
          end as memberFollowingStatus
          FROM hashers h
          LEFT OUTER JOIN ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.kennel)} hkm on hkm.${G0<TableModel>().hasherKennelMapTableHelper.colUserId} = h.${G0<TableModel>().hashersTableHelper.colHasherId} 
          LEFT OUTER JOIN kennels k on k.${G0<TableModel>().kennelsTableHelper.colKennelId} = '${widget.kennelListAggregate.kennel.kennelId}'
          WHERE h.${G0<TableModel>().hashersTableHelper.colRemoved} = 0 
          ORDER BY memberFollowingStatus,$orderBy
          
          ''';

    _kennelMemberListFuture = Future<List<dynamic>>.value(<KennelMembersResults>[]);

    final List<dynamic> kList = <dynamic>[];
    int lastMemberType = 0;

    try {
      final List<Map<String, dynamic>> results = await G0<Database>().rawQuery(query);
      for (int i = 0; i < results.length; i++) {
        final KennelMembersResults hlrItem = KennelMembersResults.fromMap(results[i]);

        if (hlrItem.memberFollowingStatus != lastMemberType) {
          lastMemberType = hlrItem.memberFollowingStatus;
          kList.add(lastMemberType);
        }

        hlrItem.isLoading = false;
        kList.add(hlrItem);

        if (forceRefresh && (i == results.length - 1)) {
          setState(() {
            _kennelMemberListFuture = Future<List<dynamic>>.value(kList);
            filterResults();
          });
        }
      }
    } catch (e) {
      //print(e);
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
  int countHasRecentRuns = 0;

  Future<void> _refreshCounters(bool forceRefresh) async {
    try {
      final String sql = ''' 

          SELECT 
              COUNT(CASE WHEN ${G0<TableModel>().hasherKennelMapTableHelper.colFollowing} > 0 THEN 1 ELSE NULL END) as isFollowing,
              COUNT(CASE WHEN ${G0<TableModel>().hasherKennelMapTableHelper.colMembershipExpirationDate} > date('now') THEN 1 ELSE NULL END) as isMember,
          
              COUNT(CASE WHEN ${G0<TableModel>().hasherKennelMapTableHelper.colDateOfLastRun} >= date('now','-365 day') THEN 1 ELSE NULL END) as hasRecentRuns
              FROM ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.kennel)} hkm
              INNER JOIN ${G0<TableModel>().hashersTableHelper.getTableName(AppDomainType.user)} h on h.${G0<TableModel>().hashersTableHelper.colHasherId} = hkm.${G0<TableModel>().hasherKennelMapTableHelper.colUserId}
  
          ''';

      final List<Map<String, dynamic>> results = await G0<Database>().rawQuery(sql);
      if (results.isNotEmpty) {
        countIsMember = results[0]['isMember'];
        countIsFollowing = results[0]['isFollowing'];
        countHasRecentRuns = results[0]['hasRecentRuns'];
      }
      if (forceRefresh) {
        setState(() {});
      }
    } catch (e) {
      //print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    _filterPanelAnimation ??= Tween<Offset>(begin: const Offset(0, -.35), end: const Offset(0, .71)).animate(_animationController);
    _hasherListAnimation ??= RelativeRectTween(begin: const RelativeRect.fromLTRB(0, 86, 0, 0), end: const RelativeRect.fromLTRB(0, 204, 0, 0)).animate(_animationController);
    return Scaffold(
      appBar: appBar,
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
              child: Icon(sortBySpeedDialIcon),
              backgroundColor: Colors.deepOrange,
              label: sortBySpeedDialLabel,
              labelStyle: const TextStyle(fontSize: 18.0),
              onTap: () {
                _sortBy = sortBySpeedDialType;
                _refreshKennelMembersFromTable(true).then((void _) {
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
                      return FindHasherPage(
                        FindHasherPageType.addMember,
                        kennelId: widget.kennelListAggregate.kennel.kennelId,
                      );
                    },
                  ),
                ).then((Map<String, dynamic> result) {
                  setState(() {
                    //_isLoading = true;
                  });
                  if ((result != null) && (result['hasher']?.hasherId != null)) {
                    final HasherKennelMapService srv = HasherKennelMapService();
                    widget.kennelListAggregate.extensions.followingRequested = -1;
                    setState(() {});
                    srv
                        .updateHasherKennelStatus(widget.kennelListAggregate.kennel.kennelId, AppDomainType.kennel,
                            monthsToAddToMembership: widget.kennelListAggregate.kennel.membershipDurationInMonths, targetUserId: result['hasher'].hasherId)
                        .then((void _) {
                      _refreshKennelMembersFromTable(true).then((void _) {
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
                      kennelId: widget.kennelListAggregate.kennel.kennelId,
                      uiElementsToDisplay: HasherProfilePage.flagUiElement_followKennel,
                      kennelShortName: widget.kennelListAggregate.kennel.kennelShortName,
                    ),
                  ),
                ).then((HashersModel result) {
                  _refreshKennelMembersFromTable(true).then((void _) {
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
          SizedBox(height: MediaQuery.of(context).size.height, width: 10),
          // (snapshot?.data == null || snapshot.data.isEmpty)

          //     //? Positioned(top: (filterPanelAnimation.value.dy * 120) + 125, left: 0, right: 0, child: getAddHasherBlock())
          //     ? Positioned(top: (filterPanelAnimation.value.dy * 120) + 125, left: 0, right: 0, child: Container(color:Colors.red))
          //     :

          PositionedTransition(
            rect: _hasherListAnimation,
            child: SizedBox(
              key: _packListBoxKey,
              height: 300,
              child: FutureBuilder<List<dynamic>>(
                  future: _filteredKennelMemberListFuture,
                  builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
                    if (snapshot?.data == null) {
                      return const HcCircularProgressIndicator(key: Key('75223930'));
                    } else {
                      return _getKennelMemberList(snapshot);
                    }
                  }),
            ),
          ),
          SlideTransition(position: _filterPanelAnimation, child: filterBar()),
          Positioned(top: 0, child: _searchBar()),
        ],
      ),
    );
  }

  Column _getKennelMemberList(AsyncSnapshot<List<dynamic>> snapshot) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 0.0),
            child: snapshot.data.isEmpty
                ? const Center(child: Text('No members found.'))
                : RefreshIndicator(
                    onRefresh: _handleRefresh,
                    displacement: 40.0,
                    child: ListView.separated(
                      separatorBuilder: (BuildContext context, int index) => const Divider(
                        height: 1.0,
                        color: Colors.black45,
                      ),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: snapshot.data.length + 1,
                      itemBuilder: (BuildContext context, int index) {
                        if (index == snapshot.data.length) {
                          return const SizedBox(height: 100.0);
                        } else {
                          if (snapshot.data[index] is int) {
                            String memberType = '';
                            if (snapshot.data[index] == 1) {
                              memberType = 'Kennel Members';
                            } else if (snapshot.data[index] == 2) {
                              memberType = 'Recent runs with this Kennel';
                            } else if (snapshot.data[index] == 3) {
                              memberType = 'Has runs with this Kennel';
                            } else if (snapshot.data[index] == 4) {
                              memberType = 'Follows this Kennel';
                            } else {
                              memberType = 'Others';
                            }

                            return Container(
                              padding: const EdgeInsets.only(top: 7.0),
                              height: 40.0,
                              child: Text(
                                memberType,
                                style: titleStyle,
                                textAlign: TextAlign.center,
                              ),
                              color: themeBackgroundColor,
                            );
                          } else {
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
                                          // '${IveCoreUtilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Bank Transfer',
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
                                          //'${IveCoreUtilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Cash',
                                          'Add ${item.membershipDurationInMonths} months\r\nto membership',
                                          style: const TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 17.0, height: 1.0)),
                                    )
                                  ],
                                ),
                              ),
                              onDismissed: (DismissDirection direction) {
                                //print(direction.toString() + ' NOTE: We should never reach this point');
                              },
                              child: KennelMemberListItem(
                                  kennelListAggregate: widget.kennelListAggregate,
                                  kennelMember: snapshot.data[index],
                                  refreshRunCountsCallback: (bool refreshThisUserData) async {
                                    // if the user of this device is changing their own run
                                    // counts, make sure to also refresh the HKM users
                                    // table so the run history page is accurate
                                    if (refreshThisUserData) {
                                      await G0<TableModel>().syncUserDataService.updateFromBackend(
                                            SyncUserDataService.flagHasherKennelMapTable,
                                            true,
                                            useV3forInitialLoading: false,
                                          );
                                    }
                                    await _refreshKennelMembersFromTable(true);
                                    await _refreshCounters(true);
                                    setState(() {});
                                  },
                                  modifyMembershipCallback: (EnumMemberPopupActions retVal) {
                                    switch (retVal) {
                                      case EnumMemberPopupActions.addOneMonth:
                                        modifyMembership(snapshot.data[index], 1);
                                        break;
                                      case EnumMemberPopupActions.addSixMonths:
                                        modifyMembership(snapshot.data[index], 6);
                                        break;
                                      case EnumMemberPopupActions.addOneYear:
                                        modifyMembership(snapshot.data[index], 12);
                                        break;
                                      case EnumMemberPopupActions.permanentMembership:
                                        modifyMembership(snapshot.data[index], 9999);
                                        break;
                                      case EnumMemberPopupActions.cancelMembership:
                                        modifyMembership(snapshot.data[index], -9999);
                                        break;
                                      case EnumMemberPopupActions.editKennelAdmin:
                                        Navigator.push<int>(
                                          context,
                                          MaterialPageRoute<int>(builder: (BuildContext context) => AppAccessPage(appAccess: snapshot.data[index].appAccessFlags)),
                                        ).then((int result) {
                                          if (result != null) {
                                            setUserProperties(snapshot.data[index], appAccessFlags: result);
                                          }
                                        });
                                        break;
                                      case EnumMemberPopupActions.editMismanagementRole:
                                        Navigator.push<int>(
                                          context,
                                          MaterialPageRoute<int>(builder: (BuildContext context) => MismanagementRolesPage(mismanagementRoles: snapshot.data[index].mismanagementRoles)),
                                        ).then((int result) {
                                          if (result != null) {
                                            setUserProperties(snapshot.data[index], mismanagementRoles: result);
                                          }
                                        });
                                        break;
                                      // case EnumMemberPopupActions.setHomeKennel:
                                      //   setAsHomeKennel(snapshot.data[index], 1);
                                      //   break;
                                      // case EnumMemberPopupActions.clearHomeKennel:
                                      //   setAsHomeKennel(snapshot.data[index], 0);
                                      //   break;
                                    }
                                  },
                                  toggleEmailPreferenceCallback: () {
                                    if (Connection.checkForConnection(context, G0<AppModel>().connectionStatus,
                                        message: 'Setting Kennel email alerts is not available in offline mode. Please connect to the Internet to change the notification preferences for a kennel.')) {
                                      final HasherKennelMapService srv = HasherKennelMapService();
                                      final int emailAlertStatus = snapshot.data[index].kennelEmailAlertPreference != 1 ? 1 : 2;
                                      snapshot.data[index].kennelEmailAlertPreference = -1;
                                      setState(() {});
                                      srv
                                          .updateHasherKennelStatus(widget.kennelListAggregate.kennel.kennelId, AppDomainType.kennel,
                                              emailAlertState: emailAlertStatus, targetUserId: snapshot.data[index].hasherId)
                                          .then((
                                        List<dynamic> queryResults,
                                      ) {
                                        setState(() {
                                          if ((queryResults != null) && (queryResults.isNotEmpty)) {
                                            snapshot.data[index].kennelEmailAlertPreference = queryResults[0]['kennelEmailAlertPreference'];
                                          }
                                        });
                                      });
                                    }
                                  }),
                            );
                          }
                        }
                      },
                    ),
                  ),
          ),
        ),
      ],
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
                    _searchController.text = '';
                    _searchText = '';
                    _refreshKennelMembersFromTable(true).then((void _) {
                      _refreshCounters(true);
                      setState(() {});
                    });
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
                    TextField(
                      autocorrect: false,
                      onChanged: (String text) {
                        setState(() {
                          _searchText = text;
                          filterResults();
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
    final List<dynamic> fullList = await _kennelMemberListFuture;
    List<dynamic> filteredList;

    if (_showFilter) {
      filteredList = fullList
          .where(
            (dynamic a) =>
                a is int ||
                (((_filterValues[FILTER_IS_MEMBER] == 0) ||
                        (_filterValues[FILTER_IS_MEMBER] == -1 && ((a.membershipExpirationDate ?? DateTime.parse('19900101')).isBefore(DateTime.now())) ||
                            (_filterValues[FILTER_IS_MEMBER] == 1 && (a.membershipExpirationDate ?? DateTime.parse('19900101')).isAfter(DateTime.now())))) &&
                    ((_filterValues[FILTER_IS_FOLLOWING] == 0) ||
                        (_filterValues[FILTER_IS_FOLLOWING] == -1 && ((a.following ?? 0) == 0)) ||
                        (_filterValues[FILTER_IS_FOLLOWING] == 1 && (a.following ?? 0) == 1)) &&
                    // ((filterValues[FILTER_IS_HOME_KENNEL] == 0) ||
                    //     (filterValues[FILTER_IS_HOME_KENNEL] == -1 && ((a.homeKennelId == null) || ((a.homeKennelId) != (a.kennelId)))) ||
                    //     (filterValues[FILTER_IS_HOME_KENNEL] == 1 && (a.homeKennelId != null) && (a.homeKennelId) == (a.kennelId))) &&
                    ((_filterValues[FILTER_RUNS_IN_LAST_YEAR] == 0) ||
                        (_filterValues[FILTER_RUNS_IN_LAST_YEAR] == -1 && ((a.dateOfLastRun ?? DateTime.parse('19900101')).isBefore(DateTime.now().add(const Duration(days: -365)))) ||
                            (_filterValues[FILTER_RUNS_IN_LAST_YEAR] == 1 && (a.dateOfLastRun ?? DateTime.parse('19900101')).isAfter(DateTime.now().add(const Duration(days: -365))))))),
          )
          .toList();
    }

    if ((_searchText != null) && (_searchText.isNotEmpty)) {
      filteredList = (filteredList ?? fullList).where((dynamic a) => a is int || (a.nameForSort.toLowerCase().contains(_searchText.toLowerCase()))).toList();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    _filteredKennelMemberListFuture = Future<List<dynamic>>.value(filteredList ?? fullList);
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
              _refreshKennelMembersFromTable(true).then((void _) {
                _refreshCounters(true);
                setState(() {});
              });
            },
            filterValues: _filterValues,
          ),
          CheckinFiltersCell(
            counter: countIsFollowing,
            label: 'Follow',
            index: 1,
            onTap: () {
              _refreshKennelMembersFromTable(true).then((void _) {
                _refreshCounters(true);
                setState(() {});
              });
            },
            filterValues: _filterValues,
          ),
          // CheckinFiltersCell(
          //   counter: countIsHomeKennel,
          //   label: 'Home',
          //   index: 2,
          //   useTriState: true,
          //   onTap: () {
          //     refreshKennelMembersFromTable(true).then((void _) {
          //       _refreshCounters(true);
          //       setState(() {});
          //     });
          //   },
          //   filterValues: filterValues,
          // ),
          CheckinFiltersCell(
            counter: countHasRecentRuns,
            label: 'Have runs',
            index: 3,
            useTriState: true,
            onTap: () {
              _refreshKennelMembersFromTable(true).then((void _) {
                _refreshCounters(true);
                setState(() {});
              });
            },
            filterValues: _filterValues,
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
    setState(() {
      //_isLoading = true;
    });

    await G0<TableModel>().syncKennelAdminService.updateFromBackend(
        SyncKennelAdminService.flagKennelTable | SyncKennelAdminService.flagHashersTable | SyncKennelAdminService.flagHasherKennelMapTable, true, widget.kennelListAggregate.kennel.kennelId);
    //final String resultStr = result ? 'successfully' : 'unsuccessfully';
    //print('Kennel member data synchronized $resultStr');
    await _refreshKennelMembersFromTable(true);
    await _refreshCounters(true);
    setState(() {});
  }

  void modifyMembership(KennelMembersResults item, int monthsToAddToMembership) {
    final HasherKennelMapService srv = HasherKennelMapService();
    widget.kennelListAggregate.extensions.followingRequested = -1;
    item.memberInfoBeingUpdated = true;
    setState(() {});
    srv.updateHasherKennelStatus(widget.kennelListAggregate.kennel.kennelId, AppDomainType.kennel, monthsToAddToMembership: monthsToAddToMembership, targetUserId: item.hasherId).then((void _) {
      _refreshKennelMembersFromTable(true).then((void _) {
        item.memberInfoBeingUpdated = false;
        _refreshCounters(true);
        setState(() {});
      });
    });
  }

  void setUserProperties(KennelMembersResults item, {int appAccessFlags = -1, int mismanagementRoles = -1}) {
    final HasherKennelMapService srv = HasherKennelMapService();
    widget.kennelListAggregate.extensions.followingRequested = -1;
    item.memberInfoBeingUpdated = true;
    setState(() {});

    srv
        .updateHasherKennelStatus(widget.kennelListAggregate.kennel.kennelId, AppDomainType.kennel, targetUserId: item.hasherId, appAccessFlags: appAccessFlags, mismanagementRoles: mismanagementRoles)
        .then((void _) {
      _refreshKennelMembersFromTable(true).then((void _) {
        item.memberInfoBeingUpdated = false;
        _refreshCounters(true);
        setState(() {});
      });
    });
  }

  // void setAsHomeKennel(KennelMembersResults item, int isHomeKennel) {
  //   final HasherKennelMapService srv = HasherKennelMapService();
  //   widget.kennel.extensions.followingRequested = -1;
  //   item.homeKennelBeingUpdated = true;
  //   setState(() {});
  //   srv
  //       .updateHasherKennelStatus(widget.kennel.kennel.kennelId, AppDomainType.kennel,
  //           targetUserId: item.hasherId, followingState: followTypeToggleHomeKennel.value, isHomeKennel: isHomeKennel)
  //       .then((void _) {
  //     refreshKennelMembersFromTable(true).then((void _) {
  //       item.homeKennelBeingUpdated = false;
  //       _refreshCounters(true);
  //       setState(() {});
  //     });
  //   });
  // }
}
