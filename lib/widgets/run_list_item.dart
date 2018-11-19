import 'dart:core';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:latlong/latlong.dart';

import 'package:harrier_central/data_models/future_run_model.dart';
import 'package:harrier_central/data_models/get_pack_model.dart';
import 'package:harrier_central/pages/run_admin/run_start_end_qr_codes_page.dart';
import 'package:harrier_central/pages/run_admin/check_in_scanner_page.dart';
import 'package:harrier_central/remote_api_data/future_run_scoped_model.dart';
import 'package:harrier_central/remote_api_data/get_pack_service.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/widgets/bubble_tab_indicator.dart';
import 'package:harrier_central/widgets/kennel_logo.dart';

import 'package:scoped_model/scoped_model.dart';
import 'package:url_launcher/url_launcher.dart';


class RunListItem extends StatefulWidget {
  RunListItem({Key key, @required FutureRun this.futureRun}) : super(key: key);

  FutureRun futureRun;

  @override
  _RunListItemState createState() => _RunListItemState();
}

class _RunListItemState extends State<RunListItem> with WidgetsBindingObserver {
  _RunListItemState();

  @override
  void initState() {
      // TODO: implement initState
      super.initState();
      WidgetsBinding.instance.addObserver(this);
    }

  @override void dispose() {
      WidgetsBinding.instance.removeObserver(this);
      super.dispose();
    }

  @override void didChangeAppLifecycleState(AppLifecycleState state) {
      print('App lifecycle state => ' + state.toString());
      super.didChangeAppLifecycleState(state);
    }

  @override
  Widget build(BuildContext context) {
    // return IntrinsicWidth(
    //     child:
    return Card(
        elevation: 4.0,
        margin: const EdgeInsets.only(top: 20.0, left: 15.0, right: 15.0),
        color: (widget.futureRun.isExpanded ?? false)
            ? Theme.of(context).selectedRowColor
            : Colors.white,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 5.0, left: 8.0, right: 8.0),
                child: Text(
                  widget.futureRun.eventName,
                  style: TextStyle(
                      fontFamily: 'AvenirNextCondensedDemiBold',
                      fontStyle: FontStyle.normal,
                      fontSize: 17.0,
                      color: (widget.futureRun.isExpanded ?? false)
                          ? Theme.of(context).accentColor
                          : Colors.black,
                      height: 1.0),
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                //padding: EdgeInsets.only(top: 15.0, bottom: 10.0),
                margin: EdgeInsets.only(top: 7.0, bottom: 0.0),
                padding: EdgeInsets.only(top: 7.0, bottom: 0.0),
                height: widget.futureRun.isExpanded ? 0.0 : 1.0,
                color: Colors.grey[300],
              ),
              ExpansionTile(
                backgroundColor: Theme.of(context).selectedRowColor,
                onExpansionChanged: (bool exp) {
                  setState(() {
                    widget.futureRun.isExpanded = exp;
                  });
                },
                title: Container(
                  padding: EdgeInsets.only(top: 7.0),
                  height: 83.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Stack(alignment: Alignment.center, children: <Widget>[
                            // Padding(
                            //   padding: widget.futureRun.daysUntilNextRun <= 9
                            //       ? const EdgeInsets.only(left:5.0, top: 22.0)
                            //       : const EdgeInsets.only(left:5.0, top: 14.0, right: 7.0),
                            //   child: Text(
                            //     widget.futureRun.daysUntilNextRun <= 9
                            //         ? '${widget.futureRun.daysUntilNextRun.toString()}'
                            //         : widget.futureRun.daysUntilNextRun <= 30
                            //             ? (widget.futureRun.daysUntilNextRun ~/ 7.0)
                            //                 .toString()
                            //             : widget.futureRun.daysUntilNextRun <= 365
                            //                 ? (widget.futureRun.daysUntilNextRun ~/
                            //                         30.0)
                            //                     .toString()
                            //                 : (widget.futureRun.daysUntilNextRun ~/
                            //                         365.0)
                            //                     .toString(),
                            //     style: TextStyle(
                            //         fontSize: 38.0,
                            //         fontWeight: FontWeight.w700,
                            //         color: widget.futureRun.daysUntilNextRun <= 3
                            //             ? Colors.red
                            //             : widget.futureRun.daysUntilNextRun <= 5
                            //                 ? Colors.blue
                            //                 : (widget.futureRun.isExpanded ?? false)
                            //                     ? Theme.of(context).accentColor
                            //                     : Theme.of(context).primaryColor),
                            //   ),
                            // ),

                            KennelLogo(
                              kennelLogoUrl: widget.futureRun.kennelLogo,
                              kennelShortName: widget.futureRun.kennelShortName,
                              logoHeight: 70.0,
                              leftPadding: 0.0,
                            ),

                            // Padding(
                            //   padding: EdgeInsets.only(left:10.0),
                            //   child: widget.futureRun.daysUntilNextRun <= 9
                            //     ? ImageIcon(
                            //         const AssetImage(
                            //             'images/icons/calendar_icon_days.png'),
                            //         size: 45.0,
                            //         color: widget.futureRun.daysUntilNextRun <= 3
                            //             ? Colors.red
                            //             : widget.futureRun.daysUntilNextRun <= 5
                            //                 ? Colors.blue
                            //                 : Theme.of(context).primaryColor)
                            //     : widget.futureRun.daysUntilNextRun <= 30
                            //         ? const ImageIcon(
                            //             AssetImage(
                            //                 'images/icons/calendar_icon_weeks.png'),
                            //             size: 45.0)
                            //         : widget.futureRun.daysUntilNextRun <= 365
                            //             ? const ImageIcon(
                            //                 AssetImage(
                            //                     'images/icons/calendar_icon_months.png'),
                            //                 size: 45.0)
                            //             : const ImageIcon(
                            //                 AssetImage(
                            //                     'images/icons/calendar_icon_years.png'),
                            //                 size: 45.0),),
                          ]),
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 3.0, left: 10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Run #${widget.futureRun.eventNumber}, in ' +
                                      (widget.futureRun.daysUntilNextRun <= 14
                                          ? '${widget.futureRun.daysUntilNextRun.toString()} days'
                                          : widget.futureRun.daysUntilNextRun <= 30
                                              ? (widget.futureRun.daysUntilNextRun ~/
                                                          7.0)
                                                      .toString() +
                                                  ' weeks'
                                              : widget.futureRun
                                                          .daysUntilNextRun <=
                                                      365
                                                  ? (widget.futureRun
                                                                  .daysUntilNextRun ~/
                                                              30.0)
                                                          .toString() +
                                                      ' months'
                                                  : (widget.futureRun
                                                                  .daysUntilNextRun ~/
                                                              365.0)
                                                          .toString() +
                                                      ' years'),
                                  style: const TextStyle(
                                      fontFamily: 'AvenirNextDemiBold',
                                      fontStyle: FontStyle.normal,
                                      fontSize: 15.0,
                                      height: 0.85),
                                  textAlign: TextAlign.left,
                                ),
                                Text(
                                  DateFormat("E, MMM d 'at' h:mm a").format(
                                      widget.futureRun.eventStartDatetime),
                                  style: const TextStyle(
                                      fontFamily: 'AvenirNextRegular',
                                      fontStyle: FontStyle.normal,
                                      fontSize: 15.0,
                                      height: 0.85),
                                  textAlign: TextAlign.left,
                                ),
                                Text(
                                  widget.futureRun.hareList.length <= 0
                                      ? 'RSVP to sign up to Hare!'
                                      : 'Hares: ' + widget.futureRun.hareList,
                                  style: const TextStyle(
                                      fontFamily: 'AvenirNextRegular',
                                      fontStyle: FontStyle.normal,
                                      fontSize: 15.0,
                                      height: 0.85),
                                  textAlign: TextAlign.left,
                                ),
                                widget.futureRun.distanceToEvent >= 0
                                    ? Text(
                                        Utilities.getDistance(
                                                widget
                                                    .futureRun.distanceToEvent,
                                                context) +
                                            ' from here',
                                        style: const TextStyle(
                                            fontFamily: 'AvenirNextRegular',
                                            fontStyle: FontStyle.normal,
                                            fontSize: 15.0,
                                            height: 0.85),
                                        textAlign: TextAlign.left,
                                      )
                                    : const Text(''),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                children: <Widget>[
                  Container(
                    //padding: EdgeInsets.only(top: 15.0, bottom: 10.0),
                    margin: EdgeInsets.only(top: 0.0, bottom: 0.0),
                    height: 1.0,
                    color: Colors.grey[300],
                  ),
                  Container(
                    height: 350.0,
                    child: RunTabs(
                      futureRun: widget.futureRun,
                    ),
                  ),
                  //  Container(
                  //    color:Colors.lightGreen[300],
                  //     height: 250.0,
                  //    )
                ],
              ),
            ]));
  }
}

class RunTabs extends StatefulWidget {
  const RunTabs({Key key, @required this.futureRun}) : super(key: key);

  final FutureRun futureRun;

  @override
  State<RunTabs> createState() {
    return RunTabsState();
  }
}

const double detailsFontSize = 16.0;
const double detailLineSpace = 1.0;
const double detailLineSpaceForBold = 0.892;

class RunTabsState extends State<RunTabs> with SingleTickerProviderStateMixin {
  // final List<Tab> tabs = <Tab>[
  //   Tab(text: 'Photo'),
  //   Tab(text: 'Detail'),
  //   Tab(text: 'RSVP'),
  //   Tab(text: 'Desc'),
  //   Tab(text: 'Map'),
  // ];

  final List<Tab> tabs = <Tab>[];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  GlobalKey packListBox = GlobalKey();

  bool isAdmin = true;

  void _initTabs() {
    tabs.clear();

    if (!(widget.futureRun.eventImage ?? '').isEmpty &&
        widget.futureRun.eventImage.startsWith('http')) {
      tabs.add(Tab(text: 'Photo'));
    }
    tabs.add(Tab(text: 'Detail'));
    tabs.add(Tab(text: 'RSVP'));
    tabs.add(Tab(text: 'Desc'));
    tabs.add(Tab(text: 'Map'));
    if (isAdmin) {
      tabs.add(Tab(text: 'Admin'));
    }
  }

  TabController _tabController;

  bool _loadingPack = false;

  List<GetPackModel> packList;

  GetPackService _getPackService = GetPackService();

  final String userId = Preferences.getStringPref(StringPrefsEnum.userId);

  Future<Null> _getPackWithRefresh() async {
    _getPackService
        .getPack(widget.futureRun.eventId)
        .then((List<GetPackModel> _thePack) {
      packList = _thePack;
      setState(() {});
    });

    setState(() {});

    return null;
  }

  void getPack(bool forceRefresh) {
    if ((packList == null) || forceRefresh) {
      _getPackService
          .getPack(widget.futureRun.eventId)
          .then((List<GetPackModel> _thePack) {
        packList = _thePack;
        setState(() {});
      });
    }
  }



  @override
  void initState() {
    super.initState();
    _initTabs();
    _tabController = TabController(vsync: this, length: tabs.length);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Theme.of(context).selectedRowColor,
        //title: Text('Bubble Tab Indicator'),
        automaticallyImplyLeading: false,
        flexibleSpace: Center(
          child: TabBar(
            labelStyle: const TextStyle(
                fontFamily: 'AvenirNextCondensedMedium',
                fontStyle: FontStyle.normal,
                fontSize: 16.0,
                height: 1.0),
            unselectedLabelStyle: const TextStyle(
                fontFamily: 'AvenirNextCondensedMedium',
                fontStyle: FontStyle.normal,
                fontSize: 16.0,
                height: 1.0),
            isScrollable: true,
            unselectedLabelColor: Colors.grey,
            labelColor: Colors.white,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BubbleTabIndicator(
              indicatorHeight: 25.0,
              indicatorColor: Theme.of(context).buttonColor,
              tabBarIndicatorSize: TabBarIndicatorSize.tab,
            ),
            tabs: tabs,
            controller: _tabController,
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: ((!(widget.futureRun.eventImage ?? '').isEmpty &&
                widget.futureRun.eventImage.startsWith('http'))
            ? List<Widget>.from(<Widget>[
                Container(
                  child:
                      CachedNetworkImage(imageUrl: widget.futureRun.eventImage),
                  decoration:
                      BoxDecoration(color: Theme.of(context).selectedRowColor),
                )
              ])
            : List<Widget>.from(<Widget>[]))
          ..addAll(
            List<Widget>.from(
              <Widget>[
                Container(
                  // Details
                  decoration:
                      BoxDecoration(color: Theme.of(context).selectedRowColor),
                  child: SingleChildScrollView(
                    child: Stack(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(
                              top: 20.0, right: 30.0, left: 20.0, bottom: 20.0),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Text(
                                  'Run:',
                                  style: const TextStyle(
                                      fontFamily: 'AvenirNextRegular',
                                      fontStyle: FontStyle.normal,
                                      fontSize: detailsFontSize,
                                      height: detailLineSpace),
                                  textAlign: TextAlign.left,
                                ),
                                Text(
                                  'Date:',
                                  style: const TextStyle(
                                      fontFamily: 'AvenirNextRegular',
                                      fontStyle: FontStyle.normal,
                                      fontSize: detailsFontSize,
                                      height: detailLineSpace),
                                  textAlign: TextAlign.left,
                                ),
                                Text(
                                  'Time:',
                                  style: const TextStyle(
                                      fontFamily: 'AvenirNextRegular',
                                      fontStyle: FontStyle.normal,
                                      fontSize: detailsFontSize,
                                      height: detailLineSpace),
                                  textAlign: TextAlign.left,
                                ),
                                Text(
                                  'Run fees:',
                                  style: const TextStyle(
                                      fontFamily: 'AvenirNextRegular',
                                      fontStyle: FontStyle.normal,
                                      fontSize: detailsFontSize,
                                      height: detailLineSpace),
                                  textAlign: TextAlign.left,
                                ),
                                Text(
                                  '',
                                  style: const TextStyle(
                                      fontFamily: 'AvenirNextRegular',
                                      fontStyle: FontStyle.normal,
                                      fontSize: detailsFontSize,
                                      height: detailLineSpace),
                                  textAlign: TextAlign.left,
                                ),
                                Text(
                                  'Bag drop:',
                                  style: const TextStyle(
                                      fontFamily: 'AvenirNextRegular',
                                      fontStyle: FontStyle.normal,
                                      fontSize: detailsFontSize,
                                      height: detailLineSpace),
                                  textAlign: TextAlign.left,
                                ),
                                Text(
                                  'Hares:',
                                  style: const TextStyle(
                                      fontFamily: 'AvenirNextRegular',
                                      fontStyle: FontStyle.normal,
                                      fontSize: detailsFontSize,
                                      height: detailLineSpace),
                                  textAlign: TextAlign.left,
                                ),
                                Text(
                                  'Distance:',
                                  style: const TextStyle(
                                      fontFamily: 'AvenirNextRegular',
                                      fontStyle: FontStyle.normal,
                                      fontSize: detailsFontSize,
                                      height: detailLineSpace),
                                  textAlign: TextAlign.left,
                                ),
                                Text(
                                  'Street:',
                                  style: const TextStyle(
                                      fontFamily: 'AvenirNextRegular',
                                      fontStyle: FontStyle.normal,
                                      fontSize: detailsFontSize,
                                      height: detailLineSpace),
                                  textAlign: TextAlign.left,
                                ),
                                Text(
                                  'City:',
                                  style: const TextStyle(
                                      fontFamily: 'AvenirNextRegular',
                                      fontStyle: FontStyle.normal,
                                      fontSize: detailsFontSize,
                                      height: detailLineSpace),
                                  textAlign: TextAlign.left,
                                ),
                                Text(
                                  'Location:',
                                  style: const TextStyle(
                                      fontFamily: 'AvenirNextRegular',
                                      fontStyle: FontStyle.normal,
                                      fontSize: detailsFontSize,
                                      height: detailLineSpace),
                                  textAlign: TextAlign.left,
                                ),
                              ]),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                              top: 21.0,
                              right: 20.0,
                              left: 102.0,
                              bottom: 20.0),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  '#${widget.futureRun.eventNumber}',
                                  style: const TextStyle(
                                      fontFamily: 'AvenirNextDemiBold',
                                      fontStyle: FontStyle.normal,
                                      fontSize: detailsFontSize,
                                      height: detailLineSpaceForBold),
                                  textAlign: TextAlign.left,
                                ),
                                Text(
                                  DateFormat('E, MMM d').format(
                                      widget.futureRun.eventStartDatetime),
                                  style: const TextStyle(
                                      fontFamily: 'AvenirNextDemiBold',
                                      fontStyle: FontStyle.normal,
                                      fontSize: detailsFontSize,
                                      height: detailLineSpaceForBold),
                                  textAlign: TextAlign.left,
                                ),
                                Text(
                                  DateFormat('h:mm a').format(
                                      widget.futureRun.eventStartDatetime),
                                  style: const TextStyle(
                                      fontFamily: 'AvenirNextDemiBold',
                                      fontStyle: FontStyle.normal,
                                      fontSize: detailsFontSize,
                                      height: detailLineSpaceForBold),
                                  textAlign: TextAlign.left,
                                ),
                                Text(
                                  (widget.futureRun.eventPriceForMembers > 0)
                                      ? '${Utilities.getFormattedMoney(widget.futureRun.eventPriceForMembers, widget.futureRun.digitsAfterDecimal, widget.futureRun.currencySymbol)} (members)'
                                      : '',
                                  style: const TextStyle(
                                      fontFamily: 'AvenirNextDemiBold',
                                      fontStyle: FontStyle.normal,
                                      fontSize: detailsFontSize,
                                      height: detailLineSpaceForBold),
                                  textAlign: TextAlign.left,
                                ),
                                Text(
                                  (widget.futureRun.eventPriceForNonMembers > 0)
                                      ? '${Utilities.getFormattedMoney(widget.futureRun.eventPriceForNonMembers, widget.futureRun.digitsAfterDecimal, widget.futureRun.currencySymbol)} (non-members)'
                                      : '',
                                  style: const TextStyle(
                                      fontFamily: 'AvenirNextDemiBold',
                                      fontStyle: FontStyle.normal,
                                      fontSize: detailsFontSize,
                                      height: detailLineSpaceForBold),
                                  textAlign: TextAlign.left,
                                ),
                                Text(
                                  'Unknown',
                                  style: const TextStyle(
                                      fontFamily: 'AvenirNextDemiBold',
                                      fontStyle: FontStyle.normal,
                                      fontSize: detailsFontSize,
                                      height: detailLineSpaceForBold),
                                  textAlign: TextAlign.left,
                                ),
                                Text(
                                  widget.futureRun.hareList,
                                  style: const TextStyle(
                                      fontFamily: 'AvenirNextDemiBold',
                                      fontStyle: FontStyle.normal,
                                      fontSize: detailsFontSize,
                                      height: detailLineSpaceForBold),
                                  textAlign: TextAlign.left,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                widget.futureRun.distanceToEvent >= 0
                                    ? Text(
                                        Utilities.getDistance(
                                            widget.futureRun.distanceToEvent,
                                            context),
                                        style: const TextStyle(
                                            fontFamily: 'AvenirNextDemiBold',
                                            fontStyle: FontStyle.normal,
                                            fontSize: detailsFontSize,
                                            height: detailLineSpaceForBold),
                                        textAlign: TextAlign.left,
                                      )
                                    : const Text(
                                        '<unknown>',
                                        style: const TextStyle(
                                            fontFamily: 'AvenirNextDemiBold',
                                            fontStyle: FontStyle.normal,
                                            fontSize: detailsFontSize,
                                            height: detailLineSpaceForBold),
                                        textAlign: TextAlign.left,
                                      ),
                                Text(
                                  widget.futureRun.locationStreet ?? '',
                                  style: const TextStyle(
                                      fontFamily: 'AvenirNextDemiBold',
                                      fontStyle: FontStyle.normal,
                                      fontSize: detailsFontSize,
                                      height: detailLineSpaceForBold),
                                  textAlign: TextAlign.left,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  (widget.futureRun.locationPostCode ?? '') +
                                      ' ' +
                                      (widget.futureRun.locationCity ?? ''),
                                  style: const TextStyle(
                                      fontFamily: 'AvenirNextDemiBold',
                                      fontStyle: FontStyle.normal,
                                      fontSize: detailsFontSize,
                                      height: detailLineSpaceForBold),
                                  textAlign: TextAlign.left,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  widget.futureRun.locationOneLineDesc ?? '',
                                  style: const TextStyle(
                                      fontFamily: 'AvenirNextDemiBold',
                                      fontStyle: FontStyle.normal,
                                      fontSize: detailsFontSize,
                                      height: detailLineSpaceForBold),
                                  textAlign: TextAlign.left,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ]),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  // RSVP
                  decoration:
                      BoxDecoration(color: Theme.of(context).selectedRowColor),
                  child: Center(
                    child: ScopedModelDescendant<FutureRunScopedModel>(
                      builder: (BuildContext context, Widget child,
                          FutureRunScopedModel model) {
                        getPack(false);
                        return Column(
                          //mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width / 5.5,
                                    child: Column(
                                      children: <Widget>[
                                        Text(
                                          'Going: ' +
                                              (widget.futureRun.attendingEvent +
                                                          widget.futureRun
                                                              .haresCount >=
                                                      0
                                                  ? (widget.futureRun
                                                              .attendingEvent +
                                                          widget.futureRun
                                                              .haresCount)
                                                      .toString()
                                                  : ''),
                                          style: const TextStyle(
                                              fontFamily:
                                                  'AvenirNextCondensedDemiBold',
                                              fontStyle: FontStyle.normal,
                                              fontSize: 17.0,
                                              height: 0.85),
                                        ),
                                        IconButton(
                                          icon: Icon(FontAwesomeIcons
                                              .solidCheckCircle),
                                          color: widget.futureRun
                                                      .requestedRsvpState ==
                                                  rsvpYes.value
                                              ? Colors.blue
                                              : widget.futureRun.rsvpState ==
                                                      rsvpYes.value
                                                  ? Colors.green
                                                  : Colors.grey,
                                          //tooltip: 'Select to follow a Kennel',
                                          iconSize: 35.0,
                                          alignment: Alignment.topCenter,
                                          splashColor: Colors.greenAccent,
                                          onPressed: () {
                                            model.setRsvpState(rsvpYes.value,
                                                widget.futureRun);
                                          },
                                          // ),
                                          // Text(
                                          //   widget.futureRun.attendingEvent +
                                          //               widget.futureRun.haresCount >=
                                          //           0
                                          //       ? (widget.futureRun.attendingEvent +
                                          //               widget.futureRun.haresCount)
                                          //           .toString()
                                          //       : '',
                                          //   style: const TextStyle(
                                          //       fontFamily: 'AvenirNext',
                                          //       fontStyle: FontStyle.normal,
                                          //       fontSize: 20.0,
                                          //       height: 0.85),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width / 5.5,
                                    child: Column(
                                      children: <Widget>[
                                        Text(
                                          'Maybe: ' +
                                              (widget.futureRun
                                                          .maybeAttendingEvent >=
                                                      0
                                                  ? widget.futureRun
                                                      .maybeAttendingEvent
                                                      .toString()
                                                  : ''),
                                          style: const TextStyle(
                                              fontFamily:
                                                  'AvenirNextCondensedDemiBold',
                                              fontStyle: FontStyle.normal,
                                              fontSize: 17.0,
                                              height: 0.85),
                                        ),
                                        IconButton(
                                          icon: Icon(FontAwesomeIcons
                                              .solidQuestionCircle),
                                          color: widget.futureRun
                                                      .requestedRsvpState ==
                                                  rsvpMaybe.value
                                              ? Colors.blue
                                              : widget.futureRun.rsvpState ==
                                                      rsvpMaybe.value
                                                  ? Colors.orange
                                                  : Colors.grey,
                                          //tooltip: 'Select to follow a Kennel',
                                          iconSize: 35.0,
                                          alignment: Alignment.topCenter,
                                          splashColor: Colors.greenAccent,
                                          onPressed: () {
                                            model.setRsvpState(rsvpMaybe.value,
                                                widget.futureRun);
                                            //model.toggleFollowing(kennel);

                                            // setState(() {
                                            // kennel.followingBool = kennel.followingBool == 0 ? 1 : 0;
                                            // });
                                          },
                                        ),
                                        // Text(
                                        //   widget.futureRun.maybeAttendingEvent >= 0
                                        //       ? widget.futureRun.maybeAttendingEvent
                                        //           .toString()
                                        //       : '',
                                        //   style: const TextStyle(
                                        //       fontFamily: 'AvenirNext',
                                        //       fontStyle: FontStyle.normal,
                                        //       fontSize: 20.0,
                                        //       height: 0.85),
                                        // ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width / 5.5,
                                    child: Column(
                                      children: <Widget>[
                                        Text(
                                          "Not go: " +
                                              (widget.futureRun
                                                          .notAttendingEvent >=
                                                      0
                                                  ? widget.futureRun
                                                      .notAttendingEvent
                                                      .toString()
                                                  : ''),
                                          style: const TextStyle(
                                              fontFamily:
                                                  'AvenirNextCondensedDemiBold',
                                              fontStyle: FontStyle.normal,
                                              fontSize: 16.0,
                                              height: 0.85),
                                        ),
                                        IconButton(
                                          icon: Icon(FontAwesomeIcons
                                              .solidTimesCircle),
                                          color: widget.futureRun
                                                      .requestedRsvpState ==
                                                  rsvpNo.value
                                              ? Colors.blue
                                              : widget.futureRun.rsvpState ==
                                                      rsvpNo.value
                                                  ? Colors.red
                                                  : Colors.grey,
                                          //tooltip: 'Select to follow a Kennel',
                                          iconSize: 35.0,
                                          alignment: Alignment.topCenter,
                                          splashColor: Colors.greenAccent,
                                          onPressed: () {
                                            model.setRsvpState(
                                                rsvpNo.value, widget.futureRun);
                                            //model.toggleFollowing(kennel);

                                            // setState(() {
                                            // kennel.followingBool = kennel.followingBool == 0 ? 1 : 0;
                                            // });
                                          },
                                        ),
                                        // Text(
                                        //   widget.futureRun.notAttendingEvent >= 0
                                        //       ? widget.futureRun.notAttendingEvent
                                        //           .toString()
                                        //       : '',
                                        //   style: const TextStyle(
                                        //       fontFamily: 'AvenirNext',
                                        //       fontStyle: FontStyle.normal,
                                        //       fontSize: 20.0,
                                        //       height: 0.85),
                                        // ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width / 5.5,
                                    child: Column(
                                      children: <Widget>[
                                        Text(
                                          'Hares: ' +
                                              (widget.futureRun.haresCount >= 0
                                                  ? widget.futureRun.haresCount
                                                      .toString()
                                                  : ''),
                                          style: const TextStyle(
                                              fontFamily:
                                                  'AvenirNextCondensedDemiBold',
                                              fontStyle: FontStyle.normal,
                                              fontSize: 17.0,
                                              height: 0.85),
                                        ),
                                        IconButton(
                                          icon: ImageIcon(AssetImage(
                                              'images/icons/hare_icon.png')),
                                          color: widget.futureRun
                                                      .requestedRsvpState ==
                                                  rsvpHare.value
                                              ? Colors.blue
                                              : widget.futureRun.rsvpState ==
                                                      rsvpHare.value
                                                  ? Colors.deepPurple
                                                  : Colors.grey,
                                          //tooltip: 'Select to follow a Kennel',
                                          iconSize: 35.0,
                                          alignment: Alignment.topCenter,
                                          splashColor: Colors.greenAccent,
                                          onPressed: () {
                                            _promptForHare(
                                                    widget.futureRun.hareList)
                                                .then<dynamic>((bool willHare) {
                                              if (willHare) {
                                                model.setRsvpState(
                                                    rsvpHare.value,
                                                    widget.futureRun);
                                              }
                                            });

                                            // model.setRsvpState(
                                            //     rsvpHare.value, widget.futureRun);
                                            //model.toggleFollowing(kennel);

                                            // setState(() {
                                            // kennel.followingBool = kennel.followingBool == 0 ? 1 : 0;
                                            // });
                                          },
                                        ),
                                        // Text(
                                        //   widget.futureRun.haresCount >= 0
                                        //       ? widget.futureRun.haresCount.toString()
                                        //       : '',
                                        //   style: const TextStyle(
                                        //       fontFamily: 'AvenirNext',
                                        //       fontStyle: FontStyle.normal,
                                        //       fontSize: 20.0,
                                        //       height: 0.85),
                                        // ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Container(
                                key: packListBox,
                                margin: const EdgeInsets.only(
                                    left: 16.0, right: 16.0, bottom: 15.0),
                                padding: const EdgeInsets.all(8.0),
                                decoration: new BoxDecoration(
                                    border: new Border.all(
                                        color: Theme.of(context).accentColor)),
                                child: Scrollbar(
                                  child: RefreshIndicator(
                                    onRefresh: _getPackWithRefresh,
                                    child: ClipRect(
                                      clipBehavior: Clip.antiAlias,
                                      clipper: packListBox.currentContext ==
                                              null
                                          ? null
                                          : RectClipper(
                                              width: packListBox.currentContext
                                                  .findRenderObject()
                                                  .paintBounds
                                                  .width,
                                              height: packListBox.currentContext
                                                  .findRenderObject()
                                                  .paintBounds
                                                  .height),
                                      child: StaggeredGridView.countBuilder(
                                        crossAxisCount: 4,
                                        itemCount: packList?.length ?? 0,
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                          if (packList[index].hasherId ==
                                              userId) {
                                            packList[index].userStatus =
                                                widget.futureRun.rsvpState;

                                            if (widget.futureRun.rsvpState ==
                                                4) {
                                              packList[index].isHare = 1;
                                            } else {
                                              packList[index].isHare = 0;
                                            }
                                          }

                                          return packList.isEmpty
                                              ? new Container(
                                                  color: Colors.grey[300],
                                                  width: 70.0,
                                                  height: 70.0,
                                                  child: new Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5.0),
                                                      child: new Center(
                                                          child:
                                                              new CircularProgressIndicator())),
                                                )
                                              : GestureDetector(
                                                  onTap: () {
                                                    String actionText = '';

                                                    if (packList[index]
                                                            .isHare ==
                                                        1) {
                                                      actionText =
                                                          ' will hare the Hash';
                                                    } else {
                                                      switch (packList[index]
                                                          .userStatus) {
                                                        case 1:
                                                          actionText =
                                                              ' will not join the Hash';
                                                          break;
                                                        case 2:
                                                          actionText =
                                                              ' might join the Hash';
                                                          break;
                                                        case 3:
                                                        case 4:
                                                        case 5:
                                                        case 6:
                                                          actionText =
                                                              ' will join the Hash';
                                                          break;
                                                        case 0:
                                                        default:
                                                          break;
                                                      }
                                                    }
                                                    ;

                                                    final snackBar = SnackBar(
                                                      duration:
                                                          Duration(seconds: 2),
                                                      content: Text(
                                                        packList[index]
                                                                .displayName +
                                                            actionText,
                                                        style: const TextStyle(
                                                            fontFamily:
                                                                'AvenirNextCondensedDemiBold',
                                                            fontStyle: FontStyle
                                                                .normal,
                                                            fontSize: 20.0,
                                                            height: 0.85),
                                                      ),
                                                      backgroundColor:
                                                          Theme.of(context)
                                                              .accentColor,
                                                    );

                                                    Scaffold.of(context)
                                                        .showSnackBar(snackBar);
                                                  },
                                                  child: Stack(
                                                    children: <Widget>[
                                                      packList[index]
                                                              .photo
                                                              .startsWith(
                                                                  'http')
                                                          ? CachedNetworkImage(
                                                              imageUrl:
                                                                  packList[
                                                                          index]
                                                                      .photo,
                                                              placeholder:
                                                                  const CircularProgressIndicator(),
                                                              errorWidget:
                                                                  const Icon(Icons
                                                                      .error),
                                                              //fadeOutDuration:  Duration(seconds: 1),
                                                              fadeInDuration:
                                                                  Duration(
                                                                      milliseconds:
                                                                          0),
                                                              width: 300.0,
                                                              height: 300.0,
                                                              fit: BoxFit.fill)
                                                          : packList[index]
                                                                  .photo
                                                                  .startsWith(
                                                                      'bundle')
                                                              ? Image(
                                                                  width: 300.0,
                                                                  height: 300.0,
                                                                  fit: BoxFit
                                                                      .fill,
                                                                  image: AssetImage('images/avatars/' +
                                                                      packList[
                                                                              index]
                                                                          .photo
                                                                          .toLowerCase()
                                                                          .replaceFirst(
                                                                              'bundle://',
                                                                              '') +
                                                                      '.png'),
                                                                )
                                                              : Image(
                                                                  width: 300.0,
                                                                  height: 300.0,
                                                                  fit: BoxFit
                                                                      .fill,
                                                                  image: AssetImage(
                                                                      'images/avatars/avatar-2.png'),
                                                                ),
                                                      Positioned(
                                                        right: 1.0,
                                                        bottom: 1.0,
                                                        child: CircleAvatar(
                                                          backgroundColor:
                                                              Colors.white,
                                                          radius: 12.0,
                                                        ),
                                                      ),
                                                      Positioned(
                                                        right: 3.0,
                                                        bottom: packList[index]
                                                                    .userStatus <=
                                                                0
                                                            ? 2.5
                                                            : packList[index]
                                                                        .isHare ==
                                                                    1
                                                                ? 3.0
                                                                : 3.5,
                                                        child: packList[index]
                                                                    .userStatus <=
                                                                0
                                                            ? CircleAvatar(
                                                                backgroundColor:
                                                                    Colors.blue,
                                                                radius: 10.0,
                                                              )
                                                            : packList[index].userStatus == 1
                                                                ? Icon(
                                                                    FontAwesomeIcons
                                                                        .solidTimesCircle,
                                                                    color: Colors
                                                                        .red,
                                                                    size: 20.0)
                                                                : packList[index].userStatus == 2
                                                                    ? Icon(FontAwesomeIcons.solidQuestionCircle,
                                                                        color: Colors
                                                                            .orange,
                                                                        size:
                                                                            20.0)
                                                                    : packList[index].isHare ==
                                                                            0
                                                                        ? Icon(FontAwesomeIcons.solidCheckCircle,
                                                                            color: Colors
                                                                                .green,
                                                                            size:
                                                                                20.0)
                                                                        : Image.asset(
                                                                            'images/icons/hare_icon.png',
                                                                            color: Colors.deepPurple,
                                                                            height: 20.0,
                                                                            width: 20.0),

                                                        // AssetImage(
                                                        //     'images/icons/hare_icon.png'),
                                                      ),
                                                    ],
                                                  ),
                                                ); //TODO: Replace this with another avatar for missing image
                                        },
                                        staggeredTileBuilder: (int index) {
                                          return packList[index].isHare == 0
                                              ? new StaggeredTile.count(1, 1)
                                              : new StaggeredTile.count(2, 2);
                                        },
                                        mainAxisSpacing: 8.0,
                                        crossAxisSpacing: 8.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  // Description
                  decoration:
                      BoxDecoration(color: Theme.of(context).selectedRowColor),
                  child: Center(
                    child: Scrollbar(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.only(
                              top: 20.0, right: 20.0, left: 20.0, bottom: 20.0),
                          child: Text(
                            widget.futureRun.eventDescription,
                            style: const TextStyle(
                                fontFamily: 'AvenirNext',
                                fontStyle: FontStyle.normal,
                                fontSize: 20.0,
                                height: 0.85),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  // Map
                  child: FlutterMap(
                    options: MapOptions(
                      center: LatLng(widget.futureRun.latitude,
                          widget.futureRun.longitude),
                      zoom: 15.0,
                    ),
                    layers: [
                      TileLayerOptions(
                          urlTemplate:
                              //'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                              'http://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                          //subdomains: ['a', 'b', 'c']),
                          subdomains: ['mt0', 'mt1', 'mt2', 'mt3']),
                      MarkerLayerOptions(
                        markers: <Marker>[
                          Marker(
                            width: 120.0,
                            height: 120.0,
                            point: LatLng(widget.futureRun.latitude,
                                widget.futureRun.longitude),
                            builder: (ctx) => GestureDetector(
                                  onTap: () => _launchMaps(
                                      widget.futureRun.latitude,
                                      widget.futureRun.longitude),
                                  child: Container(
                                    padding:
                                        const EdgeInsets.only(bottom: 58.0),
                                    child: Image.asset(
                                        'images/icons/map_pin_foot.png'),
                                    //child: FlutterLogo(colors: Colors.purple),
                                  ),
                                ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          )
          ..addAll(isAdmin
              ? List<Widget>.from(<Widget>[
                  Container(
                    decoration: BoxDecoration(
                        color: Theme.of(context).selectedRowColor),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Container(
                              width: 150.0,
                              child: RaisedButton(
                                  child: const Text(
                                    'Check in Pack',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onPressed: () {
                                    int i = 0;
                                  }),
                            ),
                            Container(
                              width: 150.0,
                              child: RaisedButton(
                                  child: const Text(
                                    'Edit Run',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onPressed: () {
                                    int i = 0;
                                  }),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Container(
                              width: 150.0,
                              child: RaisedButton(
                                  child: const Text(
                                    'Check in Scanner',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onPressed: () {
                                    Navigator.push<dynamic>(
                                        context,
                                        MaterialPageRoute<dynamic>(
                                            builder: (context) =>
                                                CheckInScannerPage(
                                                  kennelShortName: widget
                                                      .futureRun
                                                      .kennelShortName,
                                                  eventId:
                                                      widget.futureRun.eventId,
                                                  eventName: widget
                                                      .futureRun.eventName,
                                                  eventNumber: widget
                                                      .futureRun.eventNumber,
                                                )));
                                  }
                                  ),
                            ),
                            Container(
                              width: 150.0,
                              child: RaisedButton(
                                  child: const Text(
                                    '<tbd>',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onPressed: () {
                                    int i = 0;
                                  }),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Container(
                              width: 150.0,
                              child: RaisedButton(
                                  child: const Text(
                                    'Run Start QR',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onPressed: () {
                                    Navigator.push<dynamic>(
                                        context,
                                        MaterialPageRoute<dynamic>(
                                            builder: (context) =>
                                                RunStartEndQrCodes(
                                                  kennelShortName: widget
                                                      .futureRun
                                                      .kennelShortName,
                                                  eventId:
                                                      widget.futureRun.eventId,
                                                  eventName: widget
                                                      .futureRun.eventName,
                                                  eventNumber: widget
                                                      .futureRun.eventNumber,
                                                  eventStartDatetime: widget
                                                      .futureRun
                                                      .eventStartDatetime,
                                                  isStart: true,
                                                )));
                                  }
                                  ),
                            ),
                            Container(
                              width: 150.0,
                              child: RaisedButton(
                                  child: const Text(
                                    'Run End QR',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onPressed: () {
                                    Navigator.push<dynamic>(
                                        context,
                                        MaterialPageRoute<dynamic>(
                                            builder: (context) =>
                                                RunStartEndQrCodes(
                                                  kennelShortName: widget
                                                      .futureRun
                                                      .kennelShortName,
                                                  eventId:
                                                      widget.futureRun.eventId,
                                                  eventName: widget
                                                      .futureRun.eventName,
                                                  eventNumber: widget
                                                      .futureRun.eventNumber,
                                                  eventStartDatetime: widget
                                                      .futureRun
                                                      .eventStartDatetime,
                                                  isStart: false,
                                                )));
                                  }),
                            ),
                          ],
                        )
                      ],
                    ),
                  )
                ])
              : List<Widget>.from(<Widget>[])),
        // children: tabs.map((Tab tab) {
        //   return Center(
        //       child: Text(
        //     tab.text,
        //     style: TextStyle(fontSize: 20.0),
        //   ));
        // }).toList(),
      ),
    );
  }

  void _launchMaps(double lat, double lon) async {
    String googleWebUrl =
        'https://www.google.com/maps/search/?api=1&query=${lat},${lon}';
    //String googleAppUrl = 'comgooglemaps://maps.google.com/maps/place/<name>/@<lat>,<long>,15z/data=<mode-value>';
    String googleAppUrl = 'comgooglemaps://?q=${lat},${lon}';
    String appleUrl = 'https://maps.apple.com/?sll=${lat},${lon}';
    if (await canLaunch("comgooglemaps://")) {
      print('launching com googleUrl');
      await launch(googleAppUrl);
    } else if (await canLaunch(googleWebUrl)) {
      print('launching apple url');
      await launch(googleWebUrl);
    } else if (await canLaunch(appleUrl)) {
      print('launching apple url');
      await launch(appleUrl);
    } else {
      throw 'Could not launch url';
    }
  }

  void showInSnackBar(String value) {
    FocusScope.of(context).requestFocus(FocusNode());
    _scaffoldKey.currentState?.removeCurrentSnackBar();
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(
        value,
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 16.0,
            fontFamily: 'WorkSansSemiBold'),
      ),
      backgroundColor: Colors.blue,
      duration: Duration(seconds: 3),
    ));
  }

  Future<bool> _promptForHare(String hareList) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Will you Hare this run?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Please confirm that you are'),
                Text('signing up to hare this run'),
                Text(hareList.length <= 0 ? '' : 'with ' + hareList),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text("No Thanks!"),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            FlatButton(
              child: Text("Yes, I'll Hare!"),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.source, this.index);

  final String source;
  final int index;

  @override
  Widget build(BuildContext context) {
    return new Card(
      child: new Column(
        children: <Widget>[
          new Image.network(source),
          new Padding(
            padding: const EdgeInsets.all(4.0),
            child: new Column(
              children: <Widget>[
                new Text(
                  'Image number $index',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                new Text(
                  'Vincent Van Gogh',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class RectClipper extends CustomClipper<Rect> {
  RectClipper({@required this.width, @required this.height});

  double width;
  double height;

  @override
  Rect getClip(Size size) {
    Rect r = const Offset(0.0, 0.0) & Size(width, height - 33);

    // This is where we decide what part of our image is going to be
    // visible. If you try to run the app now, nothing will be shown.
    return r;
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => false;
}
