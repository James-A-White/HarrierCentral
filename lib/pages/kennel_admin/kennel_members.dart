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
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/widgets/circular_progress_indicator.dart';
import 'package:harrier_central/data/hc3_services/sync_kennel_admin_service.dart';
import 'package:harrier_central/data/hc3_services/hasher_kennel_map_service.dart';
import 'package:harrier_central/data/hc3_services/hashers_service.dart';
import 'package:harrier_central/pages/menu_pages/hasher_profile_page.dart';

class KennelMembersList extends StatefulWidget {
  const KennelMembersList({Key key, @required this.kennel}) : super(key: key);

  final KennelListAggregate kennel;

  @override
  KennelMemberListState createState() => KennelMemberListState();
}

class KennelMembersResults {
  KennelMembersResults(
      {this.hasherId, this.dispName, this.photo, this.isMember, this.following, this.kennelId, this.dateOfLastRun, this.membershipExpirationDate, this.memberSince, this.membershipDurationInMonths, this.isLoading = false, this.kennelShortName, this.homeKennelName, this.homeKennelId, this.homeKennelBeingUpdated = false, this.membershipDateBeingUpdated = false});

  final String hasherId;
  String dispName;
  String photo;
  final int isMember;
  final int following;
  final String kennelId;
  final DateTime dateOfLastRun;
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
      isMember: map['isMember'],
      following: map['following'],
      kennelShortName: map['kennelShortName'],
      homeKennelName: map['homeKennelName'],
      homeKennelId: map['homeKennelId'],
      kennelId: map['kennelId'],
      dateOfLastRun: (map['dateOfLastRun'] == null) ? null : DateTime.parse(map['dateOfLastRun'].toString().substring(0, 19)),
      membershipExpirationDate: (map['membershipExpirationDate'] == null) ? null : DateTime.parse(map['membershipExpirationDate'].toString().substring(0, 19)),
      memberSince: (map['memberSince'] == null) ? null : DateTime.parse(map['memberSince'].toString().substring(0, 19)),
      membershipDurationInMonths: map['membershipDurationInMonths'],
    );
    return item;
  }
}

enum EnumSortByType { sortByName, sortByLastRunDate, sortByMembershipExpirationDate }

class KennelMemberListState extends State<KennelMembersList> {
  KennelMemberListState();

  EnumSortByType _sortBy = EnumSortByType.sortByName;
  bool _isLoading = false;

  List<KennelMembersResults> kennelMemberList = <KennelMembersResults>[];

  @override
  void initState() {
    //print('initState called from kennel_members @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
    _isLoading = true;
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
      setState(() {
        
      });
    });
    setSortBySpeedDial();
    super.initState();
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
          hkm.isMember,
          hkm.following,
          hkm.dateOfLastRun,
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

    kennelMemberList = <KennelMembersResults>[];
    try {
      final List<Map<String, dynamic>> results = await db.rawQuery(query);
      for (int i = 0; i < results.length; i++) {
        final KennelMembersResults hlrItem = KennelMembersResults.fromMap(results[i]);
        hlrItem.isLoading = false;
        kennelMemberList.add(hlrItem);

        if (forceRefresh && (i == results.length - 1)) {
          setState(() {
            _isLoading = false;
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
        sortBySpeedDialLabel = 'Date of last run';
        sortBySpeedDialType = EnumSortByType.sortByLastRunDate;
        sortBySpeedDialIcon = FontAwesome.sort_numeric_desc;
        break;
      case EnumSortByType.sortByLastRunDate:
        sortBySpeedDialLabel = 'Date membership expires';
        sortBySpeedDialType = EnumSortByType.sortByMembershipExpirationDate;
        sortBySpeedDialIcon = FontAwesome.sort_numeric_desc;
        break;
      case EnumSortByType.sortByMembershipExpirationDate:
        sortBySpeedDialLabel = 'Name';
        sortBySpeedDialType = EnumSortByType.sortByName;
        sortBySpeedDialIcon = FontAwesome.sort_alpha_asc;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          shape: CircleBorder(),
          children: <SpeedDialChild>[
            SpeedDialChild(
                child: Icon(sortBySpeedDialIcon),
                backgroundColor: Colors.deepOrange,
                label: sortBySpeedDialLabel,
                labelStyle: const TextStyle(fontSize: 18.0),
                onTap: () {
                  _sortBy = sortBySpeedDialType;
                  refreshKennelMembersFromTable(true);
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
                      _isLoading = true;
                    });
                    if ((result != null) && (result['hasher']?.hasherId != null)) {
                      final HasherKennelMapService srv = HasherKennelMapService();
                      widget.kennel.extensions.followingRequested = -1;
                      setState(() {});
                      srv.updateHasherKennelStatus(widget.kennel.kennel.kennelId, HasherKennelMapTableType.kennelAdmin, monthsToAddToMembership: widget.kennel.kennel.membershipDurationInMonths, targetUserId: result['hasher'].hasherId).then((void dummy) {
                        refreshKennelMembersFromTable(true).then((void dummy) {
                          setState(() {
                            _isLoading = false;
                          });
                        });
                      });
                    }
                  });
                }),
            SpeedDialChild(
                child: const Icon(Icons.person_add),
                backgroundColor: Colors.green,
                label: 'Add Hasher to Harrier Central',
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
                    refreshKennelMembersFromTable(true);
                  });
                }),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: HcCircularProgressIndicator(),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 0.0),
                      child: _isLoading
                          ? const Center(
                              child: HcCircularProgressIndicator(),
                            )
                          : kennelMemberList.isEmpty
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
                                    itemCount: kennelMemberList.length,
                                    itemBuilder: (BuildContext context, int index) {
                                      final KennelMembersResults item = kennelMemberList[index];
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
                                          kennelMember: kennelMemberList[index],
                                          modifyMembershipCallback: (EnumMemberPopupActions retVal) {
                                            switch (retVal) {
                                              case EnumMemberPopupActions.addOneMonth:
                                                modifyMembership(kennelMemberList[index], 1);
                                                break;
                                              case EnumMemberPopupActions.addSixMonths:
                                                modifyMembership(kennelMemberList[index], 6);
                                                break;
                                              case EnumMemberPopupActions.subtractOneMonth:
                                                modifyMembership(kennelMemberList[index], -1);
                                                break;
                                              case EnumMemberPopupActions.subtractSixMonths:
                                                modifyMembership(kennelMemberList[index], -6);
                                                break;
                                              case EnumMemberPopupActions.cancelMembership:
                                                modifyMembership(kennelMemberList[index], -9999);
                                                break;
                                              case EnumMemberPopupActions.toggleHomeKennel:
                                                setAsHomeKennel(kennelMemberList[index], 1);
                                                break;
                                              case EnumMemberPopupActions.setHomeKennel:
                                                setAsHomeKennel(kennelMemberList[index], 1);
                                                break;
                                              case EnumMemberPopupActions.clearHomeKennel:
                                                setAsHomeKennel(kennelMemberList[index], 0);
                                                break;
                                            }
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                    ),
                  ),
                ],
              ));
  }

  Future<void> _handleRefresh() async {
    final Database db = await DBProvider.db.database;

    setState(() {
      _isLoading = true;
    });

    final SyncKennelAdminService cSrv = SyncKennelAdminService();
    final bool result = await cSrv.updateFromBackend(db, SyncKennelAdminService.flagKennelTable | SyncKennelAdminService.flagHashersTable | SyncKennelAdminService.flagHasherKennelMapTable, true, widget.kennel.kennel.kennelId);
    final String resultStr = result ? 'successfully' : 'unsuccessfully';
    print('Event map data synchronized $resultStr');
    refreshKennelMembersFromTable(true);
  }

    void modifyMembership(KennelMembersResults item, int monthsToAddToMembership) {
    final HasherKennelMapService srv = HasherKennelMapService();
    widget.kennel.extensions.followingRequested = -1;
    item.membershipDateBeingUpdated = true;
    setState(() {});
    srv.updateHasherKennelStatus(widget.kennel.kennel.kennelId, HasherKennelMapTableType.kennelAdmin, monthsToAddToMembership: monthsToAddToMembership, targetUserId: item.hasherId).then((void dummy) {
      refreshKennelMembersFromTable(true).then((void dummy) {
        item.membershipDateBeingUpdated = false;
        setState(() {});
      });
    });
  }

  void setAsHomeKennel(KennelMembersResults item, int isHomeKennel) {
    final HasherKennelMapService srv = HasherKennelMapService();
    widget.kennel.extensions.followingRequested = -1;
    item.homeKennelBeingUpdated = true;
    setState(() {});
    srv.updateHasherKennelStatus(widget.kennel.kennel.kennelId, HasherKennelMapTableType.kennelAdmin, targetUserId: item.hasherId, followingState: followTypeToggleHomeKennel.value, isHomeKennel: isHomeKennel).then((void dummy) {
      refreshKennelMembersFromTable(true).then((void dummy) {
        item.homeKennelBeingUpdated = false;
        setState(() {});
      });
    });
  }
}
