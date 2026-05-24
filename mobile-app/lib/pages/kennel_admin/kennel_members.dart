// ignore_for_file: constant_identifier_names

import 'package:harrier_central/imports.dart';

class KennelMembersList extends StatefulWidget {
  const KennelMembersList({super.key, required this.kennelListAggregate});

  final KennelListAggregate kennelListAggregate;

  @override
  KennelMemberListState createState() => KennelMemberListState();
}

enum EnumSortByType {
  sortByName,
  sortByLastRunDate,
  sortByMembershipExpirationDate,
}

class KennelMemberListState extends State<KennelMembersList>
    with SingleTickerProviderStateMixin {
  KennelMemberListState();

  EnumSortByType _sortBy = EnumSortByType.sortByName;

  Future<List<dynamic>> _kennelMemberListFuture = Future<List<dynamic>>.value(
    <dynamic>[],
  );
  Future<List<dynamic>> _filteredKennelMemberListFuture =
      Future<List<dynamic>>.value(<dynamic>[]);

  final GlobalKey _packListBoxKey = GlobalKey();

  late AnimationController _animationController;
  late Animation<double> _buttonAnimation;
  late Animation<Offset> _filterPanelAnimation;
  late Animation<RelativeRect> _hasherListAnimation;

  String _sortBySpeedDialLabel = 'Sort by Name';
  EnumSortByType _sortBySpeedDialType = EnumSortByType.sortByName;
  IconData _sortBySpeedDialIcon = FontAwesome.sort_alpha_asc;

  AppBar? _appBar;

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
    super.initState();
    _appBar = AppBar(
      centerTitle: true,
      backgroundColor: themeAppBarBackground,
      iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
      title: Text(
        '${widget.kennelListAggregate.kennel.kennelShortName} Members',
        style: const TextStyle(color: Colors.white),
      ),
    );
    unawaited(_initLoad());

    setSortBySpeedDial();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _filterPanelAnimation = Tween<Offset>(
      begin: const Offset(0, -.35),
      end: const Offset(0, .71),
    ).animate(_animationController);

    _hasherListAnimation = RelativeRectTween(
      begin: const RelativeRect.fromLTRB(0, 86, 0, 0),
      end: const RelativeRect.fromLTRB(0, 204, 0, 0),
    ).animate(_animationController);

    _buttonAnimation =
        Tween<double>(begin: 0, end: 90.0 / 360.0).animate(_animationController)
          ..addListener(() {
            setStateIfMounted(() {});
          });
  }

  Future<void> _initLoad() async {
    await _refreshKennelMembersFromTable(true);
    await _refreshCounters(true);

    if (!mounted) return;
    setStateIfMounted(() {});
  }

  Future<void> _refreshKennelMembersFromTable(bool forceRefresh) async {
    String orderBy = 'lower(h.${tableModel.hashersTableHelper.colDispName})';

    switch (_sortBy) {
      case EnumSortByType.sortByName:
        orderBy = 'lower(h.${tableModel.hashersTableHelper.colDispName})';
        break;
      case EnumSortByType.sortByLastRunDate:
        orderBy =
            'hkm.${tableModel.hasherKennelMapTableHelper.colDateOfLastRun}';
        break;
      case EnumSortByType.sortByMembershipExpirationDate:
        orderBy =
            'hkm.${tableModel.hasherKennelMapTableHelper.colMembershipExpirationDate} asc';
        break;
    }

    if (kDebugMode) {
      final String message = (await CommonQueries.countRecords(
        EnumDataTables.hasherKennelMap.kennelTableName,
      )).toString();
      debugPrint('HKM count = $message');
    }

    final String query =
        '''
        SELECT 
          h.${tableModel.hashersTableHelper.colHasherId},
          coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colKennelHashName},coalesce(h.${tableModel.hashersTableHelper.colDispName},h.${tableModel.hashersTableHelper.colHashName},h.${tableModel.hashersTableHelper.colFirstName} || " " || h.${tableModel.hashersTableHelper.colLastName},"<no name>")) as dispName,
          lower(coalesce(" " || hkm.${tableModel.hasherKennelMapTableHelper.colKennelHashName} || " ",(" " || coalesce(h.${tableModel.hashersTableHelper.colHashName},"") || " " || coalesce(h.${tableModel.hashersTableHelper.colDispName},"") || " " || coalesce(h.${tableModel.hashersTableHelper.colFirstName},"") || " " || coalesce(h.${tableModel.hashersTableHelper.colLastName},"") || " "))) as nameForSort,
          coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colKennelUserPhoto},h.${tableModel.hashersTableHelper.colPhoto}) as photo,
          hkm.${tableModel.hasherKennelMapTableHelper.colFollowing},
          hkm.${tableModel.hasherKennelMapTableHelper.colDateOfLastRun},
          hkm.${tableModel.hasherKennelMapTableHelper.colKennelEmailAlertPreference},
          hkm.${tableModel.hasherKennelMapTableHelper.colMembershipExpirationDate},
          hkm.${tableModel.hasherKennelMapTableHelper.colMemberSince},
          hkm.${tableModel.hasherKennelMapTableHelper.colAppAccessFlags},
          hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalTotalRunCount},
          hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalHaringCount},          
          hkm.${tableModel.hasherKennelMapTableHelper.colHcHaringCount},
          hkm.${tableModel.hasherKennelMapTableHelper.colHcTotalRunCount},
          hkm.${tableModel.hasherKennelMapTableHelper.colAppAccessFlags},
          hkm.${tableModel.hasherKennelMapTableHelper.colMismanagementRoles},
          hkm.${tableModel.hasherKennelMapTableHelper.colKennelCredit},
          k.${tableModel.kennelsTableHelper.colMembershipDurationInMonths},
          k.${tableModel.kennelsTableHelper.colKennelShortName},
          k.${tableModel.kennelsTableHelper.colKennelId}
          ,case 
            when hkm.${tableModel.hasherKennelMapTableHelper.colMembershipExpirationDate} >= date('now') then 1
            when ((hkm.${tableModel.hasherKennelMapTableHelper.colDateOfLastRun} is not null) AND (hkm.${tableModel.hasherKennelMapTableHelper.colDateOfLastRun} >= date('now','-182 day'))) then 2
            when hkm.${tableModel.hasherKennelMapTableHelper.colDateOfLastRun} is not null then 3
            when hkm.${tableModel.hasherKennelMapTableHelper.colFollowing} = 1 then 4
            else 5
          end as memberFollowingStatus
          FROM ${EnumDataTables.hashers.commonTableName} h
          LEFT OUTER JOIN ${EnumDataTables.hasherKennelMap.kennelTableName} hkm on hkm.${tableModel.hasherKennelMapTableHelper.colUserId} = h.${tableModel.hashersTableHelper.colHasherId} AND hkm.${tableModel.hasherKennelMapTableHelper.colKennelId} = '${widget.kennelListAggregate.kennel.kennelId}'
          LEFT OUTER JOIN ${EnumDataTables.kennels.commonTableName} k on k.${tableModel.kennelsTableHelper.colKennelId} = '${widget.kennelListAggregate.kennel.kennelId}'
          WHERE h.${tableModel.hashersTableHelper.colRemoved} = 0 
          AND h.${tableModel.hashersTableHelper.colDispName} not like 'Placeholder user for%'
          ORDER BY memberFollowingStatus,$orderBy
          
          ''';

    _kennelMemberListFuture = Future<List<dynamic>>.value(
      <KennelMemberResultsModel>[],
    );

    final List<dynamic> kList = <dynamic>[];
    int lastMemberType = 0;

    try {
      final List<Map<String, dynamic>> results = await database.rawQuery(query);
      for (int i = 0; i < results.length; i++) {
        final KennelMemberResultsModel hlrItem =
            KennelMemberResultsModel.fromMap(results[i]);

        if (hlrItem.memberFollowingStatus != lastMemberType) {
          lastMemberType = hlrItem.memberFollowingStatus;
          kList.add(lastMemberType);
        }

        kList.add(hlrItem);

        if (forceRefresh && (i == results.length - 1)) {
          _kennelMemberListFuture = Future<List<dynamic>>.value(kList);
          await filterResults();
          setStateIfMounted(() {});
        }
      }
    } catch (e) {
      //print(e);
    }
  }

  // NULLSAFETODO1 - figure out why these seem to be out of order
  void setSortBySpeedDial() {
    switch (_sortBy) {
      case EnumSortByType.sortByName:
        _sortBySpeedDialLabel = 'Sort by Date\r\nof last run';
        _sortBySpeedDialType = EnumSortByType.sortByLastRunDate;
        _sortBySpeedDialIcon = FontAwesome.sort_numeric_desc;
        break;
      case EnumSortByType.sortByLastRunDate:
        _sortBySpeedDialLabel = 'Sort by Date\r\nmembership expires';
        _sortBySpeedDialType = EnumSortByType.sortByMembershipExpirationDate;
        _sortBySpeedDialIcon = FontAwesome.sort_numeric_desc;
        break;
      case EnumSortByType.sortByMembershipExpirationDate:
        _sortBySpeedDialLabel = 'Sort by Name';
        _sortBySpeedDialType = EnumSortByType.sortByName;
        _sortBySpeedDialIcon = FontAwesome.sort_alpha_asc;
        break;
    }
  }

  int countIsMember = 0;
  int countIsFollowing = 0;
  int countHasRecentRuns = 0;

  Future<void> _refreshCounters(bool forceRefresh) async {
    try {
      final String sql =
          '''

          SELECT 
              COUNT(CASE WHEN ${tableModel.hasherKennelMapTableHelper.colFollowing} > 0 THEN 1 ELSE NULL END) as isFollowing,
              COUNT(CASE WHEN ${tableModel.hasherKennelMapTableHelper.colMembershipExpirationDate} > date('now') THEN 1 ELSE NULL END) as isMember,
          
              COUNT(CASE WHEN ${tableModel.hasherKennelMapTableHelper.colDateOfLastRun} >= date('now','-365 day') THEN 1 ELSE NULL END) as hasRecentRuns
              FROM ${EnumDataTables.hasherKennelMap.kennelTableName} hkm
              INNER JOIN ${EnumDataTables.hashers.commonTableName} h on h.${tableModel.hashersTableHelper.colHasherId} = hkm.${tableModel.hasherKennelMapTableHelper.colUserId}
  
          ''';

      final List<Map<String, dynamic>> results = await database.rawQuery(sql);
      if (results.isNotEmpty) {
        countIsMember = results[0]['isMember'];
        countIsFollowing = results[0]['isFollowing'];
        countHasRecentRuns = results[0]['hasRecentRuns'];
      }
      if (forceRefresh) {
        setStateIfMounted(() {});
      }
    } catch (e) {
      //print(e);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: _appBar,
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
        heroTag: 'speed-dial-hero-tag-422345',
        backgroundColor: hc_red,
        foregroundColor: Colors.white,
        elevation: 8.0,
        shape: const CircleBorder(),
        children: <SpeedDialChild>[
          SpeedDialChild(
            child: Icon(_sortBySpeedDialIcon),
            backgroundColor: Colors.deepOrange,
            label: _sortBySpeedDialLabel,
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () async {
              _sortBy = _sortBySpeedDialType;
              await _refreshKennelMembersFromTable(true);

              await _refreshCounters(true);

              setSortBySpeedDial();
            },
          ),
          SpeedDialChild(
            child: const Icon(MaterialCommunityIcons.account_search),
            backgroundColor: hc_blue,
            label: 'Find Hasher and add',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () async {
              final Map<String, dynamic>? result =
                  await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute<Map<String, dynamic>>(
                      settings: const RouteSettings(),
                      builder: (BuildContext context) => FindHasherPage(
                        FindHasherPageType.addMember,
                        kennelId: widget.kennelListAggregate.kennel.kennelId,
                      ),
                    ),
                  );

              if (result == null) return;

              final hasher = result['hasher'];
              final String? hasherId = hasher?.hasherId as String?;
              if (hasherId == null) return;

              // Optional: show loading / optimistic UI
              if (!mounted) return;
              setStateIfMounted(() {
                widget.kennelListAggregate.extensions.followingRequested = -1;
                // _isLoading = true;
              });

              try {
                final srv = HasherKennelMapService();

                await srv.updateHasherKennelStatus(
                  widget.kennelListAggregate.kennel.kennelId,
                  AppDomainType.kennel,
                  monthsToAddToMembership: widget
                      .kennelListAggregate
                      .kennel
                      .membershipDurationInMonths,
                  targetUserId: hasherId,
                );

                await _refreshKennelMembersFromTable(true);
                await _refreshCounters(true);

                if (!mounted) return;
                setStateIfMounted(() {
                  // _isLoading = false;
                });
              } catch (e) {
                if (!mounted) return;
                setStateIfMounted(() {
                  // _isLoading = false;
                });
                // optionally log / show snackbar
              }
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.person_add),
            backgroundColor: Colors.green,
            label: 'Add new Hasher\r\nto Harrier Central',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () async {
              final result = await Navigator.push<HashersModel>(
                context,
                MaterialPageRoute<HashersModel>(
                  builder: (BuildContext context) => HasherProfilePage(
                    dataContext: EnumDataContext.kennel,
                    pageType: EnumMyProfilePageType.newHasherProfile,
                    kennelId: widget.kennelListAggregate.kennel.kennelId,
                    uiElementsToDisplay:
                        HasherProfilePage.flagUiElement_followKennel,
                    kennelShortName:
                        widget.kennelListAggregate.kennel.kennelShortName,
                  ),
                ),
              );

              if (result == null) return;

              await _refreshKennelMembersFromTable(true);
              await _refreshCounters(true);
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.loose,
        alignment: AlignmentDirectional.topStart,
        children: <Widget>[
          SizedBox(height: MediaQuery.sizeOf(context).height, width: 10),

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
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<List<dynamic>> snapshot,
                    ) {
                      if (snapshot.data == null) {
                        return const HcAppCircularProgressIndicator(
                          key: Key('75223930'),
                        );
                      } else {
                        return _getKennelMemberList(snapshot);
                      }
                    },
              ),
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
            child: ((snapshot.data == null) || (snapshot.data!.isEmpty))
                ? Center(child: Text('No members found.', style: ts_regular))
                : RefreshIndicator(
                    onRefresh: _handleRefresh,
                    displacement: 40.0,
                    child: ListView.separated(
                      separatorBuilder: (BuildContext context, int index) =>
                          const Divider(height: 1.0, color: Colors.black45),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: snapshot.data!.length + 1,
                      itemBuilder: (BuildContext context, int index) {
                        if (index == snapshot.data!.length) {
                          return const SizedBox(height: 100.0);
                        } else {
                          if (snapshot.data![index] is int) {
                            String memberType = '';
                            if (snapshot.data![index] == 1) {
                              memberType = 'Kennel Members';
                            } else if (snapshot.data![index] == 2) {
                              memberType = 'Recent runs with this Kennel';
                            } else if (snapshot.data![index] == 3) {
                              memberType = 'Has runs with this Kennel';
                            } else if (snapshot.data![index] == 4) {
                              memberType = 'Follows this Kennel';
                            } else {
                              memberType = 'Others';
                            }

                            return Container(
                              padding: const EdgeInsets.only(top: 7.0),
                              height: 40.0,
                              color: themeBackgroundColor,
                              child: Text(
                                memberType,
                                style: ts_titleLarge,
                                textAlign: TextAlign.center,
                              ),
                            );
                          } else {
                            final KennelMemberResultsModel item =
                                snapshot.data![index];
                            return Dismissible(
                              key: Key(item.hasherId),
                              confirmDismiss: (DismissDirection direction) async {
                                // swipe from right to left to indicate that
                                // the hasher either attended the run as a pack
                                // member or as a hare
                                final int monthsToAdd =
                                    direction == DismissDirection.endToStart
                                    ? item.membershipDurationInMonths
                                    : -9999;

                                await _modifyMembership(
                                  snapshot,
                                  index,
                                  monthsToAdd,
                                );

                                return false;
                              },
                              background: Container(
                                color: hc_red,
                                child: Row(
                                  children: <Widget>[
                                    const Padding(
                                      padding: EdgeInsets.only(left: 10.0),
                                      child: Icon(
                                        FontAwesome.times_circle,
                                        color: Colors.white,
                                        size: 35.0,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 15.0,
                                      ),
                                      child: Text(
                                        // '${IveCoreUtilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Bank Transfer',
                                        'Cancel\r\nmembership',
                                        maxLines: 2,
                                        style: ts_titleMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              secondaryBackground: Container(
                                color: Colors.green,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    const Padding(
                                      padding: EdgeInsets.only(right: 15.0),
                                      child: Icon(
                                        FontAwesome.plus_circle,
                                        color: Colors.white,
                                        size: 35.0,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        right: 15.0,
                                      ),
                                      child: Text(
                                        //'${IveCoreUtilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Cash',
                                        'Add ${item.membershipDurationInMonths} months\r\nto membership',
                                        style: ts_titleMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onDismissed: (DismissDirection direction) {
                                //print(direction.toString() + ' NOTE: We should never reach this point');
                              },
                              child: KennelMemberListItem(
                                kennelListAggregate: widget.kennelListAggregate,
                                kennelMember: snapshot.data![index],
                                refreshRunCountsCallback:
                                    (
                                      bool refreshThisUserData,
                                      String dispName,
                                      String photo,
                                    ) async {
                                      // if the user of this device is changing their own run
                                      // counts, make sure to also refresh the HKM users
                                      // table so the run history page is accurate
                                      if (refreshThisUserData) {
                                        await tableModel.syncUserDataService
                                            .updateFromBackend(
                                              EnumDataTables
                                                  .hasherKennelMap
                                                  .flag,
                                              true,
                                              debugText: 'kennel_members: HKM',
                                            );
                                      }

                                      snapshot.data![index] =
                                          (snapshot.data![index]
                                                  as KennelMemberResultsModel)
                                              .copyWith(
                                                dispName: dispName,
                                                photo: photo,
                                              );

                                      await _refreshKennelMembersFromTable(
                                        true,
                                      );
                                      await _refreshCounters(true);
                                      setStateIfMounted(() {});
                                    },
                                modifyMembershipCallback: (EnumMemberPopupActions? retVal) async {
                                  if (retVal == null) return;

                                  switch (retVal) {
                                    case EnumMemberPopupActions.cancelDialog:
                                      break;
                                    case EnumMemberPopupActions.addOneMonth:
                                      await _modifyMembership(
                                        snapshot,
                                        index,
                                        1,
                                      );
                                      break;
                                    case EnumMemberPopupActions.addSixMonths:
                                      await _modifyMembership(
                                        snapshot,
                                        index,
                                        6,
                                      );
                                      break;
                                    case EnumMemberPopupActions.addOneYear:
                                      await _modifyMembership(
                                        snapshot,
                                        index,
                                        12,
                                      );
                                      break;
                                    case EnumMemberPopupActions
                                        .permanentMembership:
                                      await _modifyMembership(
                                        snapshot,
                                        index,
                                        9999,
                                      );
                                      break;
                                    case EnumMemberPopupActions
                                        .cancelMembership:
                                      await _modifyMembership(
                                        snapshot,
                                        index,
                                        -9999,
                                      );
                                      break;
                                    case EnumMemberPopupActions.editKennelAdmin:
                                      final int? appAccessResult =
                                          await Navigator.push<int>(
                                            context,
                                            MaterialPageRoute<int>(
                                              builder: (BuildContext context) =>
                                                  AppAccessPage(
                                                    appAccess: snapshot
                                                        .data![index]
                                                        .appAccessFlags,
                                                  ),
                                            ),
                                          );

                                      if (appAccessResult != null) {
                                        await _setUserProperties(
                                          snapshot,
                                          index,
                                          appAccessFlags: appAccessResult,
                                        );
                                      }
                                      break;
                                    case EnumMemberPopupActions
                                        .editMismanagementRole:
                                      final int? mismanagementResult =
                                          await Navigator.push<int>(
                                            context,
                                            MaterialPageRoute<int>(
                                              builder: (BuildContext context) =>
                                                  MismanagementRolesPage(
                                                    mismanagementRoles: snapshot
                                                        .data![index]
                                                        .mismanagementRoles,
                                                  ),
                                            ),
                                          );

                                      if (mismanagementResult != null) {
                                        await _setUserProperties(
                                          snapshot,
                                          index,
                                          mismanagementRoles:
                                              mismanagementResult,
                                        );
                                      }
                                      break;
                                    // case EnumMemberPopupActions.setHomeKennel:
                                    //   setAsHomeKennel(snapshot.data[index], 1);
                                    //   break;
                                    // case EnumMemberPopupActions.clearHomeKennel:
                                    //   setAsHomeKennel(snapshot.data[index], 0);
                                    //   break;
                                  }
                                },
                                toggleEmailPreferenceCallback: () async {
                                  if (Utilities.isConnected(
                                    showDialog: true,
                                    message:
                                        'Setting Kennel email alerts is not available in offline mode. Please connect to the Internet to change the notification preferences for a kennel.',
                                  )) {
                                    final HasherKennelMapService srv =
                                        HasherKennelMapService();
                                    final int emailAlertStatus =
                                        snapshot
                                                .data![index]
                                                .kennelEmailAlertPreference !=
                                            1
                                        ? 1
                                        : 2;
                                    snapshot
                                            .data![index]
                                            .kennelEmailAlertPreference =
                                        -1;
                                    setStateIfMounted(() {});
                                    final List<dynamic> queryResults = await srv
                                        .updateHasherKennelStatus(
                                          widget
                                              .kennelListAggregate
                                              .kennel
                                              .kennelId,
                                          AppDomainType.kennel,
                                          emailAlertState: emailAlertStatus,
                                          targetUserId:
                                              snapshot.data![index].hasherId,
                                        );

                                    if (!mounted) return;
                                    setStateIfMounted(() {
                                      if (queryResults.isNotEmpty) {
                                        snapshot
                                                .data![index]
                                                .kennelEmailAlertPreference =
                                            queryResults[0]['kennelEmailAlertPreference'];
                                      }
                                    });
                                  }
                                },
                              ),
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
      width: MediaQuery.sizeOf(context).width,
      height: 85,
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              RotationTransition(
                turns: _buttonAnimation,
                child: IconButton(
                  padding: const EdgeInsets.all(0),
                  onPressed: () async {
                    _searchFocusNode.unfocus();
                    if (_showFilter) {
                      await _animationController.reverse();
                    } else {
                      await _animationController.forward();
                    }
                    _showFilter = !_showFilter;
                    _searchController.text = '';
                    _searchText = '';
                    await _refreshKennelMembersFromTable(true);
                    await _refreshCounters(true);
                    if (!mounted) return;
                    setStateIfMounted(() {});
                  },
                  icon: Icon(
                    FontAwesome5Solid.arrow_alt_circle_right,
                    size: 35,
                    color: _showFilter ? Colors.green : Colors.grey,
                  ),
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
                      onChanged: (String text) async {
                        _searchText = text;
                        await filterResults();
                        setStateIfMounted(() {});
                      },
                      focusNode: _searchFocusNode,
                      controller: _searchController,
                      keyboardType: TextInputType.text,
                      style: ts_titleMediumBlack,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        icon: const Icon(
                          FontAwesome.search,
                          color: Colors.black,
                        ),
                        hintText: 'Enter Hash or mortal name',
                        hintStyle: ts_hint,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 40,
                child: TextButton(
                  style: text_button_style.copyWith(
                    textStyle: WidgetStatePropertyAll(
                      TextStyle(color: Colors.grey.shade700),
                    ),
                    backgroundColor: const WidgetStatePropertyAll(Colors.white),
                  ),
                  child: Text(
                    'X',
                    style: ts_headingBlack.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
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
    List<dynamic> filteredList = <dynamic>[];

    if (_showFilter) {
      filteredList = fullList
          .where(
            (dynamic a) =>
                a is int ||
                (((_filterValues[FILTER_IS_MEMBER] == 0) ||
                        (_filterValues[FILTER_IS_MEMBER] == -1 &&
                                ((a.membershipExpirationDate ??
                                        DateTime.parse('19900101'))
                                    .isBefore(DateTime.now())) ||
                            (_filterValues[FILTER_IS_MEMBER] == 1 &&
                                (a.membershipExpirationDate ??
                                        DateTime.parse('19900101'))
                                    .isAfter(DateTime.now())))) &&
                    ((_filterValues[FILTER_IS_FOLLOWING] == 0) ||
                        (_filterValues[FILTER_IS_FOLLOWING] == -1 &&
                            ((a.following ?? 0) == 0)) ||
                        (_filterValues[FILTER_IS_FOLLOWING] == 1 &&
                            (a.following ?? 0) == 1)) &&
                    // ((filterValues[FILTER_IS_HOME_KENNEL] == 0) ||
                    //     (filterValues[FILTER_IS_HOME_KENNEL] == -1 && ((a.homeKennelId == null) || ((a.homeKennelId) != (a.kennelId)))) ||
                    //     (filterValues[FILTER_IS_HOME_KENNEL] == 1 && (a.homeKennelId != null) && (a.homeKennelId) == (a.kennelId))) &&
                    ((_filterValues[FILTER_RUNS_IN_LAST_YEAR] == 0) ||
                        (_filterValues[FILTER_RUNS_IN_LAST_YEAR] == -1 &&
                                ((a.dateOfLastRun ?? DateTime.parse('19900101'))
                                    .isBefore(
                                      DateTime.now().add(
                                        const Duration(days: -365),
                                      ),
                                    )) ||
                            (_filterValues[FILTER_RUNS_IN_LAST_YEAR] == 1 &&
                                (a.dateOfLastRun ?? DateTime.parse('19900101'))
                                    .isAfter(
                                      DateTime.now().add(
                                        const Duration(days: -365),
                                      ),
                                    ))))),
          )
          .toList();
    }

    if (filteredList.isEmpty) {
      filteredList = fullList;
    }

    if (_searchText.isNotEmpty) {
      filteredList = filteredList
          .where(
            (dynamic a) =>
                a is int ||
                (a.nameForSort.toLowerCase().contains(
                  _searchText.toLowerCase(),
                )),
          )
          .toList();

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    _filteredKennelMemberListFuture = Future<List<dynamic>>.value(filteredList);
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
      width: MediaQuery.sizeOf(context).width,
      height: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          KennelFilterCell(
            counter: countIsMember,
            label: 'Member',
            index: 0,
            onTap: () async {
              await _refreshKennelMembersFromTable(true);
              await _refreshCounters(true);
              if (!mounted) return;
              setStateIfMounted(() {});
            },
            filterValues: _filterValues,
          ),
          KennelFilterCell(
            counter: countIsFollowing,
            label: 'Follow',
            index: 1,
            onTap: () async {
              await _refreshKennelMembersFromTable(true);
              await _refreshCounters(true);
              if (!mounted) return;
              setStateIfMounted(() {});
            },
            filterValues: _filterValues,
          ),
          // KennelFilterCell(
          //   counter: countIsHomeKennel,
          //   label: 'Home',
          //   index: 2,
          //   useTriState: true,
          //   onTap: () {
          //     refreshKennelMembersFromTable(true).then((void _) {
          //       _refreshCounters(true);
          //       setStateIfMounted(() {});
          //     });
          //   },
          //   filterValues: filterValues,
          // ),
          KennelFilterCell(
            counter: countHasRecentRuns,
            label: 'Have runs',
            index: 3,
            useTriState: true,
            onTap: () async {
              await _refreshKennelMembersFromTable(true);
              await _refreshCounters(true);
              if (!mounted) return;
              setStateIfMounted(() {});
            },
            filterValues: _filterValues,
          ),
          // KennelFilterCell(
          //   counter: countAtHash,
          //   index: 2,
          //   label: 'At Hash',
          //   onTap: () {
          //     _refreshPackListFromTables(true);
          //   },
          //   filterValues: filterValues,
          // ),
          // KennelFilterCell(
          //   counter: countPaid,
          //   index: 3,
          //   label: 'Paid',
          //   onTap: () {
          //     _refreshPackListFromTables(true);
          //   },
          // ),
          // KennelFilterCell(
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
    setStateIfMounted(() {
      //_isLoading = true;
    });

    await tableModel.syncKennelAdminService.updateFromBackend(
      EnumDataTables.kennels.flag |
          EnumDataTables.hashers.flag |
          EnumDataTables.hasherKennelMap.flag,
      true,
      widget.kennelListAggregate.kennel.kennelId,
    );
    //final String resultStr = result ? 'successfully' : 'unsuccessfully';
    //print('Kennel member data synchronized $resultStr');
    await _refreshKennelMembersFromTable(true);
    await _refreshCounters(true);
    setStateIfMounted(() {});
  }

  Future<void> _modifyMembership(
    AsyncSnapshot<List<dynamic>> snapshot,
    int index,
    int monthsToAddToMembership,
  ) async {
    final HasherKennelMapService srv = HasherKennelMapService();
    widget.kennelListAggregate.extensions.followingRequested = -1;

    setStateIfMounted(() {
      snapshot.data![index] = snapshot.data![index].copyWith(
        memberInfoBeingUpdated: true,
      );
    });
    await srv.updateHasherKennelStatus(
      widget.kennelListAggregate.kennel.kennelId,
      AppDomainType.kennel,
      monthsToAddToMembership: monthsToAddToMembership,
      targetUserId: snapshot.data![index].hasherId,
    );

    await _refreshKennelMembersFromTable(true);
    if (!mounted) return;
    setStateIfMounted(() {
      snapshot.data![index] = snapshot.data![index].copyWith(
        memberInfoBeingUpdated: false,
      );
    });
    await _refreshCounters(true);
  }

  Future<void> _setUserProperties(
    AsyncSnapshot<List<dynamic>> snapshot,
    int index, {
    int appAccessFlags = -1,
    int mismanagementRoles = -1,
  }) async {
    final HasherKennelMapService srv = HasherKennelMapService();
    widget.kennelListAggregate.extensions.followingRequested = -1;
    setStateIfMounted(() {
      snapshot.data![index] = snapshot.data![index].copyWith(
        memberInfoBeingUpdated: true,
      );
    });

    List<dynamic> result = [];
    try {
      result = await srv.updateHasherKennelStatus(
        widget.kennelListAggregate.kennel.kennelId,
        AppDomainType.kennel,
        targetUserId: snapshot.data![index].hasherId,
        appAccessFlags: appAccessFlags,
        mismanagementRoles: mismanagementRoles,
      );
    } catch (e) {
      debugPrint('_setUserProperties: updateHasherKennelStatus error: $e');
    } finally {
      await _refreshKennelMembersFromTable(true);
      if (mounted) {
        setStateIfMounted(() {
          snapshot.data![index] = snapshot.data![index].copyWith(
            memberInfoBeingUpdated: false,
          );
        });
      }
    }

    if (!mounted) return;

    if (mismanagementRoles != -1) {
      showHcSnackbar(
        result.isNotEmpty
            ? 'Mismanagement role updated.'
            : 'Could not save role — check your connection.',
        isError: result.isEmpty,
      );
    }
    if (appAccessFlags != -1) {
      showHcSnackbar(
        result.isNotEmpty
            ? 'App access updated.'
            : 'Could not save access — check your connection.',
        isError: result.isEmpty,
      );
    }

    await _refreshCounters(true);
  }

  // void setAsHomeKennel(KennelMemberResultsModel item, int isHomeKennel) {
  //   final HasherKennelMapService srv = HasherKennelMapService();
  //   widget.kennel.extensions.followingRequested = -1;
  //   item.homeKennelBeingUpdated = true;
  //   setStateIfMounted(() {});
  //   srv
  //       .updateHasherKennelStatus(widget.kennel.kennel.kennelId, AppDomainType.kennel,
  //           targetUserId: item.hasherId, followingState: followTypeToggleHomeKennel.value, isHomeKennel: isHomeKennel)
  //       .then((void _) {
  //     refreshKennelMembersFromTable(true).then((void _) {
  //       item.homeKennelBeingUpdated = false;
  //       _refreshCounters(true);
  //       setStateIfMounted(() {});
  //     });
  //   });
  // }
}
