import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/pages/kennel_admin/add_member_page.dart';
import 'package:harrier_central/widgets/kennel_member_list_item.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/widgets/circular_progress_indicator.dart';
import 'package:harrier_central/data/hc3_services/sync_kennel_admin_service.dart';
import 'package:harrier_central/data/hc3_services/hasher_kennel_map_service.dart';

class KennelMembersList extends StatefulWidget {
  const KennelMembersList({Key key, @required this.kennel}) : super(key: key);

  final Map<String, dynamic> kennel;

  @override
  KennelMemberListState createState() => KennelMemberListState();
}

class KennelMembersResults {
  KennelMembersResults({this.hasherId, this.dispName, this.photo, this.isMember, this.following, this.dateOfLastRun, this.membershipExpirationDate, this.memberSince, this.membershipDurationInMonths, this.isLoading = false, this.membershipDateBeingUpdated = false});

  final String hasherId;
  final String dispName;
  final String photo;
  final int isMember;
  final int following;
  final DateTime dateOfLastRun;
  final DateTime membershipExpirationDate;
  final DateTime memberSince;
  final int membershipDurationInMonths;
  bool isLoading;
  bool membershipDateBeingUpdated;

  static KennelMembersResults fromMap(Map<String, dynamic> map) {
    final KennelMembersResults item = KennelMembersResults(
      hasherId: map['hasherId'],
      dispName: map['dispName'],
      photo: map['photo'],
      isMember: map['isMember'],
      following: map['following'],
      dateOfLastRun: (map['dateOfLastRun'] == null) ? null : DateTime.parse(map['dateOfLastRun'].toString().substring(0, 19)),
      membershipExpirationDate: (map['membershipExpirationDate'] == null) ? null : DateTime.parse(map['membershipExpirationDate'].toString().substring(0, 19)),
      memberSince: (map['memberSince'] == null) ? null : DateTime.parse(map['memberSince'].toString().substring(0, 19)),
      membershipDurationInMonths: map['membershipDurationInMonths'],
    );
    return item;
  }
}

class KennelMemberListState extends State<KennelMembersList> {
  KennelMemberListState();

  // @override
  // Widget build(BuildContext context) {

  //   return Scaffold(
  //     appBar: AppBar(
  //       centerTitle: true,
  //       backgroundColor: themeAppBarBackground,
  //       title: Text(
  //         '${widget.kennel['kennelShortName']} Members',
  //         style: const TextStyle(
  //           color: Colors.white,
  //         ),
  //       ),
  //     ),
  //     body: false
  //               ? _buildCircularProgressIndicator()
  //               : _buildListView()

  //   );
  // }

  // Widget _buildCircularProgressIndicator() {
  //   return const Center(
  //     child: HcCircularProgressIndicator(),
  //   );
  // }

  // Future<void> _handleRefresh() async {
  //   // model.getKennelMembersFromBackend(1, false, widget.kennel['kennelId']);
  //   // //model.notifyListeners();
  // }

  bool _isLoading = false;

  List<KennelMembersResults> kennelMemberList = <KennelMembersResults>[];

  @override
  void initState() {
    refreshRunHistoryFromTable(true);
    super.initState();
  }

  Future<void> refreshRunHistoryFromTable(bool forceRefresh) async {
    final Database db = await DBProvider.db.database;

    const String query = ''' 
        SELECT 
          h.hasherId,
          h.dispName,
          h.photo,
          hkm.isMember,
          hkm.following,
          hkm.dateOfLastRun,
          hkm.membershipExpirationDate,
          hkm.memberSince,
          k.membershipDurationInMonths
          FROM hasherKennelMapForKennelAdmin hkm
          INNER JOIN kennels k on k.kennelId = hkm.kennelId
          INNER JOIN hashers h on h.hasherId = hkm.userId
          ORDER BY lower(h.dispName)
          
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: themeAppBarBackground,
          title: Text(
            '${widget.kennel['kennelShortName']} Members',
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        body: _isLoading ? _buildCircularProgressIndicator() : _buildListView());
  }

  Widget _buildCircularProgressIndicator() {
    return const Center(
      child: HcCircularProgressIndicator(),
    );
  }

  Future<void> _handleRefresh() async {
    final Database db = await DBProvider.db.database;

    setState(() {
      _isLoading = true;
    });

    final SyncKennelAdminService cSrv = SyncKennelAdminService();
    final bool result = await cSrv.updateFromBackend(db, SyncKennelAdminService.flagKennelTable | SyncKennelAdminService.flagHasherKennelMapTable, true, widget.kennel['kennelId']);
    final String resultStr = result ? 'successfully' : 'unsuccessfully';
    print('Event map data synchronized $resultStr');
    refreshRunHistoryFromTable(true);
  }

  Widget _buildListView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: kennelMemberList.isEmpty
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

                                final HasherKennelMapService srv = HasherKennelMapService();
                                widget.kennel['followingRequested'] = -1;
                                item.membershipDateBeingUpdated = true;
                                setState(() {});
                                srv.updateHasherKennelStatus(widget.kennel, HasherKennelMapTableType.kennelAdmin, monthsToAddToMembership: item.membershipDurationInMonths, targetUserId: item.hasherId).then((void dummy) {
                                  refreshRunHistoryFromTable(true).then((void dummy) {
                                    item.membershipDateBeingUpdated = false;
                                    setState(() {});
                                  });
                                });
                              } else {
                                final HasherKennelMapService srv = HasherKennelMapService();
                                widget.kennel['followingRequested'] = -1;
                                item.membershipDateBeingUpdated = true;
                                setState(() {});
                                srv.updateHasherKennelStatus(widget.kennel, HasherKennelMapTableType.kennelAdmin, monthsToAddToMembership: -9999, targetUserId: item.hasherId).then((void dummy) {
                                  refreshRunHistoryFromTable(true).then((void dummy) {
                                    item.membershipDateBeingUpdated = false;
                                    setState(() {});
                                  });
                                });
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
                          child: KennelMemberListItem(kennelMember: kennelMemberList[index]),
                        );
                      },
                    ),
                  ),
          ),
        ),
        Container(
          width: 150.0,
          child: RaisedButton(
            child: const Text(
              'Add Member',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              Navigator.push<dynamic>(
                context,
                MaterialPageRoute<dynamic>(
                  builder: (BuildContext context) => AddMemberPage(
                        kennelId: widget.kennel['kennelId'],
                      ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// import 'dart:async';

// import 'package:flutter/material.dart';

// import 'package:scoped_model/scoped_model.dart';

// import 'package:harrier_central/data/services/kennel_member_scoped_model.dart';
// import 'package:harrier_central/pages/kennel_admin/add_member_page.dart';
// import 'package:harrier_central/widgets/kennel_member_list_item.dart';
// import 'package:harrier_central/util/styles.dart';
// import 'package:harrier_central/widgets/circular_progress_indicator.dart';

// class KennelMembersList extends StatefulWidget {
//   const KennelMembersList({Key key, @required this.kennel}) : super(key: key);

//   final Map<String,dynamic> kennel;

//   @override
//   KennelMemberListState createState() => KennelMemberListState();

//   // @override
//   // Widget build(BuildContext context) {
//   //   if ((kennelMemberModel?.kennelMembersList?.length ?? 0) == 0) {
//   //     kennelMemberModel.getKennelMembersFromBackend(1, true, kennel.kennelId);
//   //   }

//   //   return Scaffold(
//   //     appBar: AppBar(
//   //       centerTitle: true,
//   //       backgroundColor: themeAppBarBackground,
//   //       title: Text(
//   //         '${kennel.kennelShortName} Members',
//   //         style: const TextStyle(
//   //           color: Colors.white,
//   //         ),
//   //       ),
//   //     ),
//   //     body: ScopedModel<KennelMemberScopedModel>(
//   //         model: kennelMemberModel,
//   //         child: KennelMemberListState(
//   //           kennelId: kennel.kennelId,
//   //         )),
//   //   );

// }

// class KennelMemberListState extends State<KennelMembersList> {
//   KennelMemberListState();

//   final KennelMemberScopedModel kennelMemberModel = KennelMemberScopedModel();

//   KennelMemberScopedModel model;

//   int pageIndex = 1;

//   @override
//   Widget build(BuildContext context) {

//     if (kennelMemberModel.kennelMembersList.isEmpty) {
//       kennelMemberModel.getKennelMembersFromBackend(1, true, widget.kennel['kennelId']);
//     }

//     return Scaffold(
//       appBar: AppBar(
//         centerTitle: true,
//         backgroundColor: themeAppBarBackground,
//         title: Text(
//           '${widget.kennel['kennelShortName']} Members',
//           style: const TextStyle(
//             color: Colors.white,
//           ),
//         ),
//       ),
//       body: ScopedModel<KennelMemberScopedModel>(
//         model: kennelMemberModel,
//         child: ScopedModelDescendant<KennelMemberScopedModel>(
//           builder: (BuildContext context, Widget child,
//               KennelMemberScopedModel model) {
//             this.model = model;
//             return model.isLoading
//                 ? _buildCircularProgressIndicator()
//                 : _buildListView();
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildCircularProgressIndicator() {
//     return const Center(
//       child: HcCircularProgressIndicator(),
//     );
//   }

//   Future<void> _handleRefresh() async {
//     model.getKennelMembersFromBackend(1, false, widget.kennel['kennelId']);
//     //model.notifyListeners();
//   }

//   Widget _buildListView() {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.start,
//       children: <Widget>[
//         Expanded(
//           child: Padding(
//             padding: const EdgeInsets.only(top: 10.0),
//             child: model.getKennelMembersListCount() == 0
//                 ? const Center(child: Text('No Kennels available.'))
//                 : RefreshIndicator(
//                     onRefresh: () => _handleRefresh(),
//                     displacement: 40.0,
//                     child: ListView.builder(
//                       physics: const AlwaysScrollableScrollPhysics(),
//                       itemCount: model.getKennelMembersListCount(),
//                       itemBuilder: (BuildContext context, int index) {
//                         return Container(
//                           height: 85.0,
//                           padding: const EdgeInsets.all(0.0),
//                           child: ListView(
//                               scrollDirection: Axis.horizontal,
//                               children: <Widget>[
//                                 KennelMemberListItem(
//                                     kennelMember:
//                                         model.kennelMembersList[index]),
//                               ]),
//                         );
//                       },
//                     ),
//                   ),
//           ),
//         ),
//         Container(
//           width: 150.0,
//           child: RaisedButton(
//             child: const Text(
//               'Add Member',
//               style: TextStyle(color: Colors.white),
//             ),
//             onPressed: () {
//               Navigator.push<dynamic>(
//                 context,
//                 MaterialPageRoute<dynamic>(
//                   builder: (BuildContext context) => AddMemberPage(
//                         kennelId: widget.kennel['kennelId'],
//                       ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }
