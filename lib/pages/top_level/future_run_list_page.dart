import 'dart:async';

import 'package:flutter/material.dart';

import 'package:geolocator/geolocator.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/widgets/run_list_item.dart';
import 'package:harrier_central/widgets/circular_progress_indicator.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/data/hc3_services/sync_user_data_service.dart';
import 'package:harrier_central/data/hc3_services/events_service.dart';
import 'package:harrier_central/data/hc3_services/base_service.dart';
import 'package:harrier_central/data/hc3_services/kennels_service.dart';
import 'package:harrier_central/pages/detail_pages/run_details_page.dart';

class FutureRunsListPage extends StatefulWidget {
  const FutureRunsListPage({Key key}) : super(key: key);

  @override
  FutureRunListPageState createState() => FutureRunListPageState();
}

class RunDetailsQueryExtensions {
  RunDetailsQueryExtensions({
    this.daysUntilEvent,
    this.distToEvent,
    this.mismanagementRoleFlags,
    this.currencySymbol,
    this.digitsAfterDecimal,
    this.rsvpState,
    this.isPaid,
    this.isHare,
    this.isMember,
    this.following,
    this.notificationPreference,
    this.emailAlertPreference,
    this.distancePreference,
    this.autoRunDistancePreference,
    this.userPrefs,
    this.searchText,
  });

  final num daysUntilEvent;
  num distToEvent;
  final int mismanagementRoleFlags;
  int digitsAfterDecimal;
  String currencySymbol;
  int rsvpState;
  int isPaid;
  int isHare;
  int isMember;
  final int following;
  int notificationPreference;
  int emailAlertPreference;
  int distancePreference;
  int autoRunDistancePreference;
  int userPrefs;
  String searchText;

  static RunDetailsQueryExtensions fromMap(Map<String, dynamic> map) {
    final RunDetailsQueryExtensions item = RunDetailsQueryExtensions(
      daysUntilEvent: map['daysUntilEvent'],
      digitsAfterDecimal: map['digitsAfterDecimal'],
      currencySymbol: map['currencySymbol'],
      mismanagementRoleFlags: map['mismanagementRoleFlags'],
      following: map['following'],
      rsvpState: map['rsvpState'],
      isPaid: map['isPaid'],
      isHare: map['isHare'],
      isMember: map['isMember'],
      notificationPreference: map['notificationPreference'],
      emailAlertPreference: map['emailAlertPreference'],
      distancePreference: map['distancePreference'],
      autoRunDistancePreference: map['autoRunDistancePreference'],
      userPrefs: map['userPrefs'],
      searchText: map['searchText'],
    );
    return item;
  }
}

class RunDetailsAggregate {
  RunDetailsAggregate({
    this.event,
    this.kennel,
    this.extensions,
    this.paymentUrl,
  });

  final EventModel event;
  final KennelsModel kennel;
  final RunDetailsQueryExtensions extensions;
  final String paymentUrl;
}

class FutureRunListPageState extends State<FutureRunsListPage> {
  // BuildContext context;

  // @override
  // bool get wantKeepAlive => true;

  int pageIndex = 1;
  List<RunDetailsAggregate> allRuns;
  List<RunDetailsAggregate> filteredRuns;

  FocusNode searchFocusNode = FocusNode();
  TextEditingController searchController = TextEditingController();
  String searchText;
  bool searchAllRuns = false;
  ScrollController scrollController = ScrollController(initialScrollOffset: 100.0);
  bool showFilters = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: allRuns == null ? const HcCircularProgressIndicator() : _buildListView(),
    );
  }

  Future<void> _handleRefresh({bool queryBackend = true, bool clearLocalTables = false}) async {
    final Database db = await DBProvider.db.database;

    if (clearLocalTables) {
      setState(() {
        allRuns = null;
      });

      String query = 'DELETE FROM ${hasherEventMapTableHelper.getTableName(TableType.hemUser)}';
      try {
        await db.rawQuery(query);
      } catch (e) {
        print(e);
      }

      query = 'DELETE FROM ${paymentsTableHelper.getTableName(TableType.paymentsUser)}';
      try {
        await db.rawQuery(query);
      } catch (e) {
        print(e);
      }

      query = 'DELETE FROM ${eventsTableHelper.tableName}';
      try {
        await db.rawQuery(query);
      } catch (e) {
        print(e);
      }
    }

    if (queryBackend) {
      final SyncUserDataService cSrv = SyncUserDataService();
      cSrv.updateFromBackend(db, SyncUserDataService.flagHasherEventMapTable | SyncUserDataService.flagNarrowEventsTable | SyncUserDataService.flagKennelsTable | SyncUserDataService.flagPaymentsTable, false).then((bool result) {
        refreshFromTable(true);
        final String resultStr = result ? 'successfully' : 'unsuccessfully';
        print('Events user data synchronized $resultStr');
      });
    }
  }

  @override
  void initState() {
    searchController.text = '';
    searchText = '';

    // scrollController.addListener((){
    //   showFilters = true;
    // });

    _handleRefresh().then((void dummy) {
      refreshFromTable(false);
    });
    super.initState();
  }

  Widget searchBar() {
    return Container(
      height: 100,
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Checkbox(
                value: searchAllRuns,
                onChanged: (bool value) {
                  //allRuns = null;
                  searchAllRuns = !searchAllRuns;
                  setState(() {});
                  refreshFromTable(true);
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('Search all runs', style: headingStyleBlack.copyWith(fontSize: 18.0)),
              ),
            ],
          ),
          const Divider(
            height: 2.0,
            thickness: 2.0,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 14.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      autocorrect: false,
                      onChanged: (String text) {
                        setState(() {
                          searchText = text;
                          filterRuns();
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
                        hintText: 'Search...',
                        hintStyle: TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
                      ),
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
                        setState(() {
                          filterRuns();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void refreshFromTable(bool forceRefresh) {
    if (forceRefresh || (allRuns == null) || (allRuns.isEmpty)) {
      final Geolocator locator = Geolocator();

      final String userId = getStringPref(StringPrefsEnum.userId);

      Utilities.getLatLong().then((LatLon ll) {
        DBProvider.db.database.then((Database db) {
          final String query = ''' 
      
        SELECT  
          evt.*,
          k.*,
          coalesce(hkm.mismanagementRoleFlags,0) as mismanagementRoleFlags,
          coalesce(hkm.following,0) as following,
          coalesce(hem.rsvpState,0) as rsvpState,
          CASE WHEN coalesce(pay.paymentType,0) >= 2 THEN 1 ELSE 0 END as isPaid,
          coalesce(hem.isHare,0) as isHare,
          case when ((hkm.membershipExpirationDate IS NOT NULL) AND (julianday(hkm.membershipExpirationDate) >= julianday('now','localtime'))) then 1 else 0 end as isMember,
          coalesce(hem.eventNotificationPreference,hkm.kennelNotificationPreference,0) as notificationPreference,
          coalesce(hem.eventEmailAlertPreference,hkm.kennelEmailAlertPreference,0) as emailAlertPreference,
          n.digitsAfterDecimal,
          n.currencySymbol,
          CAST(julianday(evt.eventStartDatetime) + 0.5 AS INT) - CAST(julianday('now','localtime') + 0.5 AS INT) as daysUntilEvent,
          julianday(evt.eventStartDatetime) + 0.5 as eventJulian,
          julianday('now','localtime') + 0.5 as nowJulian,
          CASE WHEN h.preferences & 0x00000003 = 0 THEN COALESCE(k.distancePreference,n.distancePreference,0) ELSE (h.preferences & 0x00000003) - 2 END as distancePreference,
          h.preferences & 0x0000001C as autoRunDistancePreference,
          h.preferences as userPrefs,
            coalesce(evt.${eventsTableHelper.colEventName},"")
            || " " || coalesce(evt.${eventsTableHelper.colEventDescription},"")
            || " " || coalesce(evt.${eventsTableHelper.colHares},'')
            || " " || coalesce(evt.${eventsTableHelper.colLocationCity},'')
            || " " || coalesce(evt.${eventsTableHelper.colLocationCountry},'')
            || " " || coalesce(evt.${eventsTableHelper.colLocationOneLineDesc},'')
            || " " || coalesce(evt.${eventsTableHelper.colLocationPostCode},'')
            || " " || coalesce(evt.${eventsTableHelper.colLocationRegion},'')
            || " " || coalesce(evt.${eventsTableHelper.colLocationStreet},'')
            || " " || coalesce(evt.${eventsTableHelper.colLocationSubRegion},'')
            || " " || case when ${eventsTableHelper.colEventNumber} IS NOT NULL THEN cast(evt.${eventsTableHelper.colEventNumber} as TEXT) END
            || case 
              when n.${countriesTableHelper.colContinentCode} = "EU" then "europe" 
              when n.${countriesTableHelper.colContinentCode} = "AF" then "africa" 
              when n.${countriesTableHelper.colContinentCode} = "AS" then "asia" 
              when n.${countriesTableHelper.colContinentCode} = "NA" then "north america" 
              when n.${countriesTableHelper.colContinentCode} = "SA" then "south america" 
              when n.${countriesTableHelper.colContinentCode} = "OC" then "oceania" 
              when n.${countriesTableHelper.colContinentCode} = "AN" then "antarctica" 
              else "" 
              end
          as searchText
        
          FROM narrowEvents evt
          INNER JOIN kennels k on k.kennelId = evt.kennelId
          INNER JOIN countries n on n.countryId = k.countryId
          INNER JOIN hashers h on h.hasherId = "$userId"
          LEFT OUTER JOIN ${hasherKennelMapTableHelper.getTableName(TableType.hkmUser)} hkm on hkm.kennelId = evt.kennelId and hkm.userId = "$userId"
          LEFT OUTER JOIN hasherEventMap hem on hem.eventId = evt.eventId and hem.userId = "$userId"
          LEFT OUTER JOIN ${paymentsTableHelper.getTableName(TableType.paymentsUser)} pay on pay.${paymentsTableHelper.colHemId} = hem.${hasherEventMapTableHelper.colHemId} AND pay.${paymentsTableHelper.colCancelledBy} IS NULL
          WHERE evt.eventStartDatetime > datetime('now','localtime','-4 hours') and evt.isVisible = 1
          AND (
                "${searchAllRuns.toString()}" == "true"
                OR
                (coalesce(hkm.following,0) <= 1) 
                OR 
                (coalesce(hem.rsvpState,0) >= 2)
              )
          ORDER BY evt.eventStartDatetime
          ''';

          allRuns = <RunDetailsAggregate>[];
          allRuns.clear(); // make double sure it's cleared!
          try {
            db.rawQuery(query).then((List<Map<String, dynamic>> results) {
              for (int i = 0; i < results.length; i++) {
                locator.distanceBetween(Utilities.unInt(ll.latitude), Utilities.unInt(ll.longitude), Utilities.unInt(results[i]['narrowEventLatitude']), Utilities.unInt(results[i]['narrowEventLongitude'])).then((num dist) {
                  final EventModel eventItem = eventsTableHelper.fromMap(results[i]);
                  final KennelsModel kennelItem = kennelsTableHelper.fromMap(results[i]);
                  final RunDetailsQueryExtensions extensionsItem = RunDetailsQueryExtensions.fromMap(results[i]);
                  extensionsItem.distToEvent = dist;

                  String paymentLinkUrl = '';

                  if (((eventItem.eventPaymentUrl ?? '') != '') && (eventItem.eventPaymentUrlExpires.isAfter(DateTime.now()))) {
                    paymentLinkUrl = eventItem.eventPaymentUrl;
                  } else if (((kennelItem.kennelPaymentUrl ?? '') != '') && (kennelItem.kennelPaymentUrlExpires.isAfter(DateTime.now()))) {
                    paymentLinkUrl = kennelItem.kennelPaymentUrl;
                  }

                  final num julianNow = results[i]['nowJulian'];
                  final num eventJulian = results[i]['eventJulian'];

                  print('Julian now = $julianNow, Event julian = $eventJulian, EventName = ${eventItem.eventName}');

                  num meters = 0;

                  switch (extensionsItem.autoRunDistancePreference) {
                    case hasherPref_10:
                      meters = 10000;
                      break;
                    case hasherPref_25:
                      meters = 25000;
                      break;
                    case hasherPref_50:
                      meters = 50000;
                      break;
                    case hasherPref_75:
                      meters = 75000;
                      break;
                    case hasherPref_100:
                      meters = 100000;
                      break;
                    case hasherPref_150:
                      meters = 150000;
                      break;
                    case hasherPref_200:
                      meters = 200000;
                      break;
                    default:
                      meters = 50000;
                      break;
                  }

                  if ((extensionsItem.distancePreference != 0) || ((extensionsItem.userPrefs & 0x00000002) == 0))
                  {
                      meters = meters * MILES_TO_METERS / 1000;
                  }

                  if ((searchAllRuns == true) || (extensionsItem.following >= 1) || ((extensionsItem.following == 0) && (dist < meters))) {
                    final RunDetailsAggregate item = RunDetailsAggregate(event: eventItem, kennel: kennelItem, extensions: extensionsItem, paymentUrl: paymentLinkUrl);
                    allRuns.add(item);
                  }
                  if (i == results.length - 1) {
                    filterRuns();
                    setState(() {});
                  }
                });
              }
            });
          } catch (e) {
            print(e);
          }
        });
      });
    }
  }

  void filterRuns() {
    filteredRuns = <RunDetailsAggregate>[];
    filteredRuns.clear();
    if (allRuns != null) {
      // for some strange reason, we sometime get double results in the
      // list. I'm not sure why this is happening, so I'm clearing the list twice
      // below to make sure the filtered run list is really empty!

      if (searchController.text.isEmpty) {
        filteredRuns.addAll(allRuns);
      } else {
        filteredRuns = allRuns.where((RunDetailsAggregate a) => a.extensions.searchText.toLowerCase().contains(searchText.toLowerCase())).toList();
      }
    }
    setState(() {});
  }

  Widget _buildListView() {
    return Container(
      decoration: Backgrounds.defaultHcBackground(),
      child: allRuns.isEmpty
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 25, right: 25, bottom: 30),
                  child: Center(
                      child: Text(
                    'No Runs available.',
                    style: largeTitleStyle,
                    textAlign: TextAlign.center,
                  )),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 25.0, right: 25.0, bottom: 30),
                  child: Center(
                      child: Text(
                    'You might not be following any Kennels with upcoming runs. Check the Kennels page, select several Kennels and then return to this page and hit the "Reload runs" button below.',
                    style: smallTitleStyle,
                    textAlign: TextAlign.center,
                  )),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 0.0),
                  child: FlatButton(
                    color: Theme.of(context).accentColor,
                    child: Text('Reload runs', style: buttonLabelStyleMedium),
                    onPressed: () async {
                      _handleRefresh(queryBackend: true, clearLocalTables: false);
                    },
                  ),
                ),
              ],
            )
          : NestedScrollView(
              controller: scrollController,
              headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  // SliverAppBar(
                  //   expandedHeight: 200.0,
                  //   floating: false,
                  //   pinned: false,
                  //   flexibleSpace: FlexibleSpaceBar(
                  //       background: Image.network(
                  //         "https://images.pexels.com/photos/396547/pexels-photo-396547.jpeg?auto=compress&cs=tinysrgb&h=350",
                  //         fit: BoxFit.cover,
                  //       )),
                  // ),
                  SliverList(
                    delegate: SliverChildListDelegate(<Widget>[searchBar()]),
                  ),
                ];
              },
              body: RefreshIndicator(
                onRefresh: () => _handleRefresh(queryBackend: true, clearLocalTables: true),
                displacement: 40.0,
                child: ListView.builder(
                  padding: const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 50),
                  physics: const AlwaysScrollableScrollPhysics(),
                  //padding: const EdgeInsets.only( bottom: 40.0),
                  itemCount: filteredRuns.length,
                  itemBuilder: (BuildContext context, int index) {
                    return RunListItem(
                      futureRun: filteredRuns[index],
                      onItemTapped: () {
                        Navigator.push<dynamic>(
                          this.context,
                          MaterialPageRoute<dynamic>(
                            builder: (BuildContext context) => RunDetailsPage(futureRun: filteredRuns[index]),
                          ),
                        ).then((void dummy) {
                          _handleRefresh(queryBackend: true, clearLocalTables: false).then((void dummy) {
                            setState(() {});
                          });
                        });
                      },
                    );
                  },
                ),
              ),
            ),
    );
  }
}
