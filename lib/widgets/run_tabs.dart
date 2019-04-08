import 'dart:core';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:intl/intl.dart';
import 'package:latlong/latlong.dart';

import 'package:harrier_central/data_models/planned_run_model.dart';
import 'package:harrier_central/data_models/user_model.dart';
import 'package:harrier_central/pages/run_admin/run_start_end_qr_codes_page.dart';
import 'package:harrier_central/pages/run_admin/check_in_scanner_page.dart';
import 'package:harrier_central/pages/run_admin/payment_report.dart';
import 'package:harrier_central/services/future_run_scoped_model.dart';
import 'package:harrier_central/services/get_pack_service.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/widgets/bubble_tab_indicator.dart';
import 'package:harrier_central/widgets/fancy_divider.dart';
import 'package:harrier_central/pages/run_admin/check_in_pack_page.dart';
import 'package:harrier_central/util/styles.dart';

import 'package:scoped_model/scoped_model.dart';
import 'package:url_launcher/url_launcher.dart';

class RunTabs extends StatefulWidget {
  const RunTabs({Key key, @required this.futureRun}) : super(key: key);

  final PlannedRun futureRun;

  @override
  State<RunTabs> createState() {
    return RunTabsState();
  }
}

const double detailsFontSize = 16.0;
const double detailLineSpace = 1.0;
const double detailLineSpaceForBold = 0.892;

class RunTabsState extends State<RunTabs> with SingleTickerProviderStateMixin {
  final List<Tab> tabs = <Tab>[];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  GlobalKey packListBox = GlobalKey();

  bool isAdmin = true;

  void _initTabs() {
    tabs.clear();
    tabs.add(const Tab(text: 'Details'));
    tabs.add(const Tab(text: 'RSVP'));
    tabs.add(const Tab(text: 'Map'));
    if (widget.futureRun.hasMmPrivileges) {
      tabs.add(const Tab(text: 'Admin'));
    }
  }

  TabController _tabController;

  List<UserModel> packList;

  final GetPackService _getPackService = GetPackService();

  final String userId = getStringPref(StringPrefsEnum.userId);

  Future<void> _getPackWithRefresh() async {
    _getPackService
        .getPack(widget.futureRun.eventId)
        .then((List<UserModel> _thePack) {
      packList = _thePack;
      setState(() {});
    });

    setState(() {});
  }

  void getPack(bool forceRefresh) {
    if ((packList == null) || forceRefresh) {
      _getPackService
          .getPack(widget.futureRun.eventId)
          .then((List<UserModel> _thePack) {
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
    _tabController.addListener(() {
      if (fabIsVisible !=
          (tabs[_tabController.index].text.toLowerCase() == 'rsvp')) {
        setState(() {
          fabIsVisible =
              tabs[_tabController.index].text.toLowerCase() == 'rsvp';
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  TextStyle headerStyle = const TextStyle(
      color: Colors.yellow,
      fontFamily: 'AvenirNextRegular',
      fontStyle: FontStyle.normal,
      fontSize: detailsFontSize,
      height: detailLineSpace);

  TextStyle infoStyle = const TextStyle(
      color: Colors.white,
      fontFamily: 'AvenirNextDemiBold',
      fontStyle: FontStyle.normal,
      fontSize: detailsFontSize,
      height: detailLineSpaceForBold);

  TextStyle bodyStyle = const TextStyle(
      color: Colors.white,
      fontFamily: 'AvenirNextRegular',
      fontStyle: FontStyle.normal,
      fontSize: 20.0,
      height: 1.0);

  TextStyle titleStyle = const TextStyle(
      color: Colors.white,
      fontFamily: 'AvenirNextRegular',
      fontStyle: FontStyle.normal,
      fontSize: 30.0,
      height: 1.0);

  Container buildRunDetailsView() {
    return Container(
      // Details
      // decoration:
      //     BoxDecoration(color: Theme.of(context).selectedRowColor),
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            ((widget.futureRun.eventImage ?? '').isNotEmpty &&
                    widget.futureRun.eventImage.startsWith('http'))
                ? Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: CachedNetworkImage(
                      imageUrl: widget.futureRun.eventImage,
                      // errorWidget:
                      //     (BuildContext context, String url, Exception error) =>
                      //         const  Icon(Icons.error),
                    )
                    //decoration: BoxDecoration(color: Theme.of(context).selectedRowColor),
                    )
                : Container(),
            ((widget.futureRun.eventImage ?? '').isNotEmpty &&
                    widget.futureRun.eventImage.startsWith('http'))
                ? const Padding(
                    padding: EdgeInsets.only(top: 20.0, bottom: 10.0),
                    child: FancyDivider(innerColor: Colors.white),
                  )
                : Container(),
            Padding(
              padding: const EdgeInsets.only(
                  top: 25, left: 20, right: 20, bottom: 10),
              child: AutoSizeText(widget.futureRun.eventName,
                  style: titleStyle, textAlign: TextAlign.center, maxLines: 2),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 20.0, bottom: 10.0),
              child: FancyDivider(innerColor: Colors.white),
            ),
            Stack(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(
                      top: 20.0, right: 30.0, left: 20.0, bottom: 20.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          'Run:',
                          style: headerStyle,
                          textAlign: TextAlign.left,
                        ),
                        Text(
                          'Date:',
                          style: headerStyle,
                          textAlign: TextAlign.left,
                        ),
                        Text(
                          'Time:',
                          style: headerStyle,
                          textAlign: TextAlign.left,
                        ),
                        Text(
                          'Run fees:',
                          style: headerStyle,
                          textAlign: TextAlign.left,
                        ),
                        Text(
                          '',
                          style: headerStyle,
                          textAlign: TextAlign.left,
                        ),
                        Text(
                          'Bag drop:',
                          style: headerStyle,
                          textAlign: TextAlign.left,
                        ),
                        Text(
                          'Hares:',
                          style: headerStyle,
                          textAlign: TextAlign.left,
                        ),
                        Text(
                          'Distance:',
                          style: headerStyle,
                          textAlign: TextAlign.left,
                        ),
                        Text(
                          'Street:',
                          style: headerStyle,
                          textAlign: TextAlign.left,
                        ),
                        Text(
                          'City:',
                          style: headerStyle,
                          textAlign: TextAlign.left,
                        ),
                        Text(
                          'Location:',
                          style: headerStyle,
                          textAlign: TextAlign.left,
                        ),
                      ]),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      top: 21.0, right: 20.0, left: 102.0, bottom: 20.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '#${widget.futureRun.eventNumber}',
                          style: infoStyle,
                          textAlign: TextAlign.left,
                        ),
                        Text(
                          DateFormat('E, MMM d')
                              .format(widget.futureRun.eventStartDatetime),
                          style: infoStyle,
                          textAlign: TextAlign.left,
                        ),
                        Text(
                          DateFormat('h:mm a')
                              .format(widget.futureRun.eventStartDatetime),
                          style: infoStyle,
                          textAlign: TextAlign.left,
                        ),
                        Text(
                          (widget.futureRun.eventPriceForMembers > 0)
                              ? '${Utilities.getFormattedMoney(widget.futureRun.eventPriceForMembers, widget.futureRun.digitsAfterDecimal, widget.futureRun.currencySymbol)} (members)'
                              : '',
                          style: infoStyle,
                          textAlign: TextAlign.left,
                        ),
                        Text(
                          (widget.futureRun.eventPriceForNonMembers > 0)
                              ? '${Utilities.getFormattedMoney(widget.futureRun.eventPriceForNonMembers, widget.futureRun.digitsAfterDecimal, widget.futureRun.currencySymbol)} (non-members)'
                              : '',
                          style: infoStyle,
                          textAlign: TextAlign.left,
                        ),
                        Text(
                          'Unknown',
                          style: infoStyle,
                          textAlign: TextAlign.left,
                        ),
                        Text(
                          widget.futureRun.hareList,
                          style: infoStyle,
                          textAlign: TextAlign.left,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        widget.futureRun.distanceToEvent >= 0
                            ? Text(
                                Utilities.getDistance(
                                    widget.futureRun.distanceToEvent, context),
                                style: infoStyle,
                                textAlign: TextAlign.left,
                              )
                            : Text(
                                '<unknown>',
                                style: infoStyle,
                                textAlign: TextAlign.left,
                              ),
                        Text(
                          widget.futureRun.locationStreet ?? '',
                          style: infoStyle,
                          textAlign: TextAlign.left,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          (widget.futureRun.locationPostCode ?? '') +
                              ' ' +
                              (widget.futureRun.locationCity ?? ''),
                          style: infoStyle,
                          textAlign: TextAlign.left,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.futureRun.locationOneLineDesc ?? '',
                          style: infoStyle,
                          textAlign: TextAlign.left,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ]),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 10.0),
              child: FancyDivider(innerColor: Colors.white),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  top: 30.0, right: 20.0, left: 20.0, bottom: 20.0),
              child: Text(widget.futureRun.eventDescription, style: bodyStyle),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle rsvpTitlesView = const TextStyle(
      color: Colors.white,
      fontFamily: 'AvenirNextCondensedDemiBold',
      fontStyle: FontStyle.normal,
      fontSize: 17.0,
      height: 0.85);

  void addThisDeviceUserToPackList() {
    if (packList != null) {
      final String userId = getStringPref(StringPrefsEnum.userId);

      if (packList
          .where((UserModel user) =>
              user.hasherId.toLowerCase() == (userId.toLowerCase()))
          .isEmpty) {
        // add the user of this device to the RSVP list if they were not already in it
        final UserModel newUser = UserModel();
        newUser.hasherId = userId;
        newUser.displayName = getStringPref(StringPrefsEnum.displayName);
        newUser.photo = getStringPref(StringPrefsEnum.profilePhotoUrl);
        newUser.firstName = getStringPref(StringPrefsEnum.firstName);
        newUser.lastName = getStringPref(StringPrefsEnum.lastName);

        packList.add(newUser);

        //futureRunScopedModel.notifyListeners();
      }
    }
  }

  FutureRunScopedModel futureRunScopedModel;

  Container buildRsvpView() {
    print('buildRsvpView() -  = ${DateTime.now().millisecondsSinceEpoch}');

    return Container(
      child: Center(
        child: ScopedModelDescendant<FutureRunScopedModel>(
          builder: (BuildContext context, Widget child,
              FutureRunScopedModel _futureRunScopedModel) {
            futureRunScopedModel = _futureRunScopedModel;

            if (!_futureRunScopedModel.isLoading) {
              _futureRunScopedModel.getFutureRunsFromBackend(false);
            }
            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 17.0, bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Container(
                        width: MediaQuery.of(context).size.width / 5.5,
                        child: Column(
                          children: <Widget>[
                            Text(
                              'Going: ' +
                                  (widget.futureRun.rsvpYesCount >= 0
                                      ? (widget.futureRun.rsvpYesCount)
                                          .toString()
                                      : ''),
                              style: rsvpTitlesView,
                            ),
                            Stack(
                              alignment: AlignmentDirectional.center,
                              children: <Widget>[
                                widget.futureRun.rsvpState != rsvpYes.value
                                    ? Container()
                                    : Positioned(
                                        top: 6.5,
                                        left: 6.5,
                                        child: Container(
                                          height: 38,
                                          width: 38,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                IconButton(
                                  icon: const Icon(FontAwesome.check_circle),
                                  color: widget.futureRun.requestedRsvpState ==
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
                                    _futureRunScopedModel.setRsvpState(
                                        rsvpYes.value,
                                        isHareNo.value,
                                        -1,
                                        widget.futureRun);

                                    addThisDeviceUserToPackList();
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
                          ],
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width / 5.5,
                        child: Column(
                          children: <Widget>[
                            Text(
                              'Maybe: ' +
                                  (widget.futureRun.rsvpMaybeCount >= 0
                                      ? widget.futureRun.rsvpMaybeCount
                                          .toString()
                                      : ''),
                              style: rsvpTitlesView,
                            ),
                            Stack(
                              alignment: AlignmentDirectional.center,
                              children: <Widget>[
                                widget.futureRun.rsvpState != rsvpMaybe.value
                                    ? Container()
                                    : Positioned(
                                        top: 6.5,
                                        left: 6.5,
                                        child: Container(
                                          height: 38,
                                          width: 38,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                IconButton(
                                  icon: const Icon(FontAwesome.question_circle),
                                  color: widget.futureRun.requestedRsvpState ==
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
                                    setState(() {
                                      _futureRunScopedModel.setRsvpState(
                                          rsvpMaybe.value,
                                          isHareNo.value,
                                          -1,
                                          widget.futureRun);

                                      addThisDeviceUserToPackList();
                                    });

                                    //model.toggleFollowing(kennel);

                                    // setState(() {
                                    // kennel.followingBool = kennel.followingBool == 0 ? 1 : 0;
                                    // });
                                  },
                                ),
                              ],
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
                        width: MediaQuery.of(context).size.width / 5.5,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Text(
                                'Not go: ' +
                                    (widget.futureRun.rsvpNoCount >= 0
                                        ? widget.futureRun.rsvpNoCount
                                            .toString()
                                        : ''),
                                style: rsvpTitlesView),
                            Stack(
                              alignment: AlignmentDirectional.center,
                              children: <Widget>[
                                widget.futureRun.rsvpState != rsvpNo.value
                                    ? Container()
                                    : Positioned(
                                        top: 6.5,
                                        left: 6.5,
                                        child: Container(
                                          height: 38,
                                          width: 38,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                IconButton(
                                  icon: const Icon(FontAwesome.times_circle),
                                  color: widget.futureRun.requestedRsvpState ==
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
                                    _futureRunScopedModel.setRsvpState(
                                        rsvpNo.value,
                                        isHareNo.value,
                                        -1,
                                        widget.futureRun);

                                    addThisDeviceUserToPackList();
                                    //model.toggleFollowing(kennel);

                                    // setState(() {
                                    // kennel.followingBool = kennel.followingBool == 0 ? 1 : 0;
                                    // });
                                  },
                                ),
                              ],
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
                        width: MediaQuery.of(context).size.width / 5.5,
                        child: Column(
                          children: <Widget>[
                            Text(
                                'Hares: ' +
                                    (widget.futureRun.haresCount >= 0
                                        ? widget.futureRun.haresCount.toString()
                                        : ''),
                                style: rsvpTitlesView),
                            Stack(
                              alignment: AlignmentDirectional.center,
                              children: <Widget>[
                                widget.futureRun.isHare != 1
                                    ? Container()
                                    : Positioned(
                                        top: 6.5,
                                        left: 6.5,
                                        child: Container(
                                          height: 38,
                                          width: 38,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 2.5,
                                      left: 1.5,
                                      right: 2.5,
                                      bottom: 2),
                                  child: IconButton(
                                    icon: const ImageIcon(AssetImage(
                                        'images/icons/hare_icon.png')),
                                    color:
                                        widget.futureRun.requestedHaringState ==
                                                1
                                            ? Colors.blue
                                            : widget.futureRun.isHare == 1
                                                ? Colors.deepPurple
                                                : Colors.grey,
                                    //tooltip: 'Select to follow a Kennel',
                                    iconSize: 30.0,
                                    alignment: Alignment.topCenter,
                                    splashColor: Colors.greenAccent,
                                    onPressed: () {
                                      _promptForHare(widget.futureRun.hareList)
                                          .then<dynamic>((bool willHare) {
                                        if (willHare) {
                                          _futureRunScopedModel.setRsvpState(
                                              rsvpYes.value,
                                              isHareYes.value,
                                              -1,
                                              widget.futureRun);

                                          addThisDeviceUserToPackList();
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
                                ),
                              ],
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
                    color: const Color.fromARGB(60, 255, 255, 255),
                    margin: const EdgeInsets.only(
                        left: 16.0, right: 16.0, bottom: 15.0),
                    padding: const EdgeInsets.all(8.0),
                    child: Scrollbar(
                      child: RefreshIndicator(
                        onRefresh: _getPackWithRefresh,
                        child: StaggeredGridView.countBuilder(
                          crossAxisCount: 4,
                          itemCount: packList?.length ?? 0,
                          itemBuilder: (BuildContext context, int index) {
                            if (packList[index].hasherId == userId) {
                              packList[index].rsvpState =
                                  widget.futureRun.rsvpState;
                              packList[index].isHare = widget.futureRun.isHare;
                            }

                            return packList.isEmpty
                                ? Container(
                                    color: Colors.grey[300],
                                    width: 70.0,
                                    height: 70.0,
                                    child: const Padding(
                                        padding: EdgeInsets.all(5.0),
                                        child: Center(
                                            child:
                                                CircularProgressIndicator())),
                                  )
                                : GestureDetector(
                                    onTap: () {
                                      String actionText = '';

                                      if (packList[index].isHare == 1) {
                                        actionText = ' will hare the Hash';
                                      } else {
                                        switch (packList[index].rsvpState) {
                                          case 1:
                                            actionText =
                                                ' will not join the Hash';
                                            break;
                                          case 2:
                                            actionText = ' might join the Hash';
                                            break;
                                          case 3:
                                          case 4:
                                          case 5:
                                          case 6:
                                            actionText = ' will join the Hash';
                                            break;
                                          case 0:
                                          default:
                                            break;
                                        }
                                      }

                                      final SnackBar snackBar = SnackBar(
                                        duration: const Duration(seconds: 2),
                                        content: Text(
                                          packList[index].displayName +
                                              actionText,
                                          style: const TextStyle(
                                              fontFamily:
                                                  'AvenirNextCondensedDemiBold',
                                              fontStyle: FontStyle.normal,
                                              fontSize: 20.0,
                                              height: 0.85),
                                        ),
                                        backgroundColor:
                                            Theme.of(context).accentColor,
                                      );

                                      Scaffold.of(context)
                                          .showSnackBar(snackBar);
                                    },
                                    child: Stack(
                                      children: <Widget>[
                                        packList[index].photo.startsWith('http')
                                            ? CachedNetworkImage(
                                                imageUrl: packList[index].photo,
                                                //placeholder: const CircularProgressIndicator(),
                                                //errorWidget: const  Icon(Icons.error),

                                                // placeholder:
                                                //     (context,
                                                //             url) =>
                                                //         Container(
                                                //             child:
                                                //                 Center(
                                                //               child:
                                                //                   Container(
                                                //                 height: 20,
                                                //                 width: 20,
                                                //                 child: CircularProgressIndicator(
                                                //                   strokeWidth: 3.0,
                                                //                 ),
                                                //               ),
                                                //             ),
                                                //             height:
                                                //                 70.0,
                                                //             width:
                                                //                 70.0),
                                                // errorWidget: (BuildContext
                                                //             context,
                                                //         String
                                                //             url,
                                                //         Exception
                                                //             error) =>
                                                //     const  Icon(Icons
                                                //         .error),

                                                fadeInDuration: const Duration(
                                                    milliseconds: 0),
                                                width: 300.0,
                                                height: 300.0,
                                                fit: BoxFit.fill)
                                            : packList[index]
                                                    .photo
                                                    .startsWith('bundle')
                                                ? Image(
                                                    width: 300.0,
                                                    height: 300.0,
                                                    fit: BoxFit.fill,
                                                    image: AssetImage(
                                                        ('images/avatars/' +
                                                                packList[index]
                                                                    .photo
                                                                    .toLowerCase()
                                                                    .replaceFirst(
                                                                        'bundle://',
                                                                        '') +
                                                                '.png')
                                                            .toLowerCase()),
                                                  )
                                                : Image(
                                                    width: 300.0,
                                                    height: 300.0,
                                                    fit: BoxFit.fill,
                                                    image: const AssetImage(
                                                        'images/avatars/avatar-2.png'),
                                                  ),
                                        const Positioned(
                                          right: 1.0,
                                          bottom: 1.0,
                                          child: CircleAvatar(
                                            backgroundColor: Colors.white,
                                            radius: 12.0,
                                          ),
                                        ),
                                        Positioned(
                                          right: 3.0,
                                          bottom: packList[index].rsvpState <= 0
                                              ? 2.5
                                              : packList[index].isHare == 1
                                                  ? 3.0
                                                  : 3.5,
                                          child: packList[index].rsvpState <= 0
                                              ? const CircleAvatar(
                                                  backgroundColor: Colors.blue,
                                                  radius: 10.0,
                                                )
                                              : packList[index].rsvpState == 1
                                                  ? const Icon(
                                                      FontAwesome.times_circle,
                                                      color: Colors.red,
                                                      size: 20.0)
                                                  : packList[index].rsvpState ==
                                                          2
                                                      ? const Icon(
                                                          FontAwesome
                                                              .question_circle,
                                                          color: Colors.orange,
                                                          size: 20.0)
                                                      : packList[index]
                                                                  .isHare ==
                                                              0
                                                          ? const Icon(
                                                              FontAwesome
                                                                  .check_circle,
                                                              color:
                                                                  Colors.green,
                                                              size: 20.0)
                                                          : Image.asset(
                                                              'images/icons/hare_icon.png',
                                                              color: Colors
                                                                  .deepPurple,
                                                              height: 20.0,
                                                              width: 20.0),

                                          // AssetImage(
                                          //     'images/icons/hare_icon.png'),
                                        ),
                                      ],
                                    ),
                                  ); // TODO(James): Replace this with another avatar for missing image
                          },
                          staggeredTileBuilder: (int index) {
                            return packList[index].isHare != 1
                                ? const StaggeredTile.count(1, 1)
                                : const StaggeredTile.count(2, 2);
                          },
                          mainAxisSpacing: 8.0,
                          crossAxisSpacing: 8.0,
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
    );
  }

  // Widget buildMapView() {
  //   try {
  //     print('buildMapView() -  = ${DateTime.now().millisecondsSinceEpoch}');
  //     return _buildMapView();
  //   } catch (e) {
  //     print(e);
  //     return _buildMapView();
  //   }
  // }

  Widget buildMapView() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        // Map
        child: FlutterMap(
          options: MapOptions(
            center:
                LatLng(widget.futureRun.latitude, widget.futureRun.longitude),
            zoom: 15.0,
          ),
          layers: <LayerOptions>[
            TileLayerOptions(
                urlTemplate:
                    //'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    'http://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                //subdomains: ['a', 'b', 'c']),
                subdomains: <String>['mt0', 'mt1', 'mt2', 'mt3']),
            MarkerLayerOptions(
              markers: <Marker>[
                Marker(
                  width: 120.0,
                  height: 120.0,
                  point: LatLng(
                      widget.futureRun.latitude, widget.futureRun.longitude),
                  builder: (BuildContext ctx) => GestureDetector(
                        onTap: () => _launchMaps(widget.futureRun.latitude,
                            widget.futureRun.longitude),
                        child: Container(
                          padding: const EdgeInsets.only(bottom: 58.0),
                          child: Image.asset('images/icons/map_pin_foot.png'),
                          //child: FlutterLogo(colors: Colors.purple),
                        ),
                      ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  bool fabIsVisible = false;

  @override
  Widget build(BuildContext context) {
    getPack(false);

    return Scaffold(
      key: _scaffoldKey,
      floatingActionButton: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: fabIsVisible ? 1.0 : 0.0,
        child: SpeedDial(
          // both default to 16
          marginRight: 18,
          marginBottom: 20,
          animatedIcon: AnimatedIcons.menu_close,
          animatedIconTheme: const IconThemeData(size: 22.0),
          // this is ignored if animatedIcon is non null
          // child:const  Icon(Icons.add),
          visible: true,
          curve: Curves.bounceIn,
          overlayColor: Colors.black,
          overlayOpacity: 0.5,
          onOpen: () => print('OPENING DIAL'),
          onClose: () => print('DIAL CLOSED'),
          tooltip: 'Speed Dial',
          heroTag: 'speed-dial-hero-tag',
          backgroundColor: Theme.of(context).accentColor,
          foregroundColor: Colors.white,
          elevation: 8.0,
          shape: CircleBorder(),
          children: <SpeedDialChild>[
            SpeedDialChild(
              child: const Icon(Feather.x),
              backgroundColor: Colors.red[800],
              label: 'I\'m not coming',
              labelStyle: const TextStyle(fontSize: 18.0),
              onTap: () {
                futureRunScopedModel.setRsvpState(
                    rsvpNo.value, isHareNo.value, -1, widget.futureRun);

                addThisDeviceUserToPackList();
              },
            ),
            SpeedDialChild(
              child: const Icon(AntDesign.question),
              backgroundColor: Colors.orange,
              label: 'I might come',
              labelStyle: const TextStyle(fontSize: 18.0),
              onTap: () {
                futureRunScopedModel.setRsvpState(
                    rsvpMaybe.value, isHareNo.value, -1, widget.futureRun);

                addThisDeviceUserToPackList();
              },
            ),
            SpeedDialChild(
              child: const Icon(Feather.check),
              backgroundColor: Colors.green,
              label: 'I\'m coming',
              labelStyle: const TextStyle(fontSize: 18.0),
              onTap: () {
                futureRunScopedModel.setRsvpState(
                    rsvpYes.value, isHareNo.value, -1, widget.futureRun);

                addThisDeviceUserToPackList();
              },
            ),
            SpeedDialChild(
              child: const ImageIcon(AssetImage('images/icons/hare_icon.png'),
                  color: Colors.purple),
              backgroundColor: Colors.white,
              label: 'I will hare',
              labelStyle: const TextStyle(fontSize: 18.0),
              onTap: () {
                _promptForHare(widget.futureRun.hareList)
                    .then<dynamic>((bool willHare) {
                  if (willHare) {
                    futureRunScopedModel.setRsvpState(
                        rsvpYes.value, isHareYes.value, -1, widget.futureRun);

                    addThisDeviceUserToPackList();
                  }
                });
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: Column(
          children: <Widget>[
            PreferredSize(
              preferredSize: const Size.fromHeight(120.0),
              child: Padding(
                padding: const EdgeInsets.only(
                    top: 0, left: 0, right: 0, bottom: 15),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: 50.0,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColorLight,
                    borderRadius: const BorderRadius.all(Radius.circular(0.0)),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                      child: TabBar(
                        labelStyle: const TextStyle(
                            fontFamily: 'AvenirNextCondensedMedium',
                            fontStyle: FontStyle.normal,
                            fontSize: 18.0,
                            height: 1.0),
                        unselectedLabelStyle: const TextStyle(
                            fontFamily: 'AvenirNextCondensedMedium',
                            fontStyle: FontStyle.normal,
                            fontSize: 18.0,
                            height: 1.0),
                        isScrollable: true,
                        unselectedLabelColor: Colors.black,
                        labelColor: Colors.white,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BubbleTabIndicator(
                          indicatorHeight: 40.0,
                          indicatorColor: Theme.of(context).buttonColor,
                          tabBarIndicatorSize: TabBarIndicatorSize.tab,
                        ),
                        tabs: tabs,
                        controller: _tabController,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: List<Widget>.from(
                  <Widget>[
                    buildRunDetailsView(),
                    buildRsvpView(),
                    buildMapView(), 
                  ],
                )..addAll(isAdmin
                    ? List<Widget>.from(<Widget>[
                        Container(
                          // decoration: BoxDecoration(
                          //     color: Theme.of(context).selectedRowColor),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: kiddies()),
                        )
                      ])
                    : List<Widget>.from(<Widget>[])),
                // children: tabs.map((Tab tab) {
                //   return Center(
                //       child: Text(
                //     tab.text,
                //     style: const TextStyle(fontSize: 20.0),
                //   ));
                // }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> kiddies() {
    final List<Widget> kiddies = <Widget>[];

    if (widget.futureRun.mmAuthAllowCheckInAndOut ||
        widget.futureRun.mmAuthAllowEditRsvp) {
      kiddies.add(rsvpRow());
    }

    if (widget.futureRun.mmAuthAllowCheckInAndOut) {
      kiddies.add(attendenceRow());
    }

    kiddies.add(paymentRow());

    return kiddies;
  }

  Row rsvpRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        !widget.futureRun.mmAuthAllowEditRsvp
            ? Container()
            : Container(
                margin: const EdgeInsets.only(left: 10, right: 10),
                width: 150.0,
                height: 100.0,
                child: RaisedButton(
                  child: const Text(
                    'Check in Pack',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    Navigator.push<dynamic>(
                      context,
                      MaterialPageRoute<dynamic>(
                        builder: (BuildContext context) =>
                            CheckInPackPage(futureRun: widget.futureRun),
                      ),
                    );
                  },
                ),
              ),
        !widget.futureRun.mmAuthAllowHashCash
            ? Container()
            : Container(
                margin: const EdgeInsets.only(left: 10, right: 10),
                width: 150.0,
                height: 100.0,
                child: RaisedButton(
                  child: const Text(
                    'Hash Cash',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    Navigator.push<dynamic>(
                      context,
                      MaterialPageRoute<dynamic>(
                        builder: (BuildContext context) => PaymentReportPage(
                              eventId: widget.futureRun.eventId,
                              currencySymbol: widget.futureRun.currencySymbol,
                              digitsAfterDecimal:
                                  widget.futureRun.digitsAfterDecimal,
                              eventName: widget.futureRun.eventName,
                            ),
                      ),
                    );
                  },
                ),
              ),

        // Container(
        //   width: 150.0,
        //   child: RaisedButton(
        //       child: const Text(
        //         'Edit Run',
        //         style:
        //             TextStyle(color: Colors.white),
        //       ),
        //       onPressed: () {
        //         //int i = 0;
        //       }),
        // ),
      ],
    );
  }

  Row attendenceRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(left: 10, right: 10),
          width: 150.0,
          height: 100.0,
          child: RaisedButton(
            child: const Text(
              'Scan at Run Start',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              Navigator.push<dynamic>(
                context,
                MaterialPageRoute<dynamic>(
                  builder: (BuildContext context) => CheckInScannerPage(
                        kennelShortName: widget.futureRun.kennelShortName,
                        eventId: widget.futureRun.eventId,
                        eventName: widget.futureRun.eventName,
                        eventNumber: widget.futureRun.eventNumber,
                        isRunStart: 1,
                      ),
                ),
              );
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 10, right: 10),
          width: 150.0,
          height: 100.0,
          child: RaisedButton(
            child: const Text(
              'Scan at Run End',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              Navigator.push<dynamic>(
                context,
                MaterialPageRoute<dynamic>(
                  builder: (BuildContext context) => CheckInScannerPage(
                        kennelShortName: widget.futureRun.kennelShortName,
                        eventId: widget.futureRun.eventId,
                        eventName: widget.futureRun.eventName,
                        eventNumber: widget.futureRun.eventNumber,
                        isRunStart: 0,
                      ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Row paymentRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(left: 10, right: 10),
          width: 150.0,
          height: 100.0,
          child: RaisedButton(
              child: const Text(
                'Run Start QR',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(
                        builder: (BuildContext context) => RunStartEndQrCodes(
                              kennelShortName: widget.futureRun.kennelShortName,
                              eventId: widget.futureRun.eventId,
                              eventName: widget.futureRun.eventName,
                              eventNumber: widget.futureRun.eventNumber,
                              eventStartDatetime:
                                  widget.futureRun.eventStartDatetime,
                              isStart: true,
                            )));
              }),
        ),
        Container(
          margin: const EdgeInsets.only(left: 10, right: 10),
          width: 150.0,
          height: 100.0,
          child: RaisedButton(
              child: const Text(
                'Run End QR',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(
                        builder: (BuildContext context) => RunStartEndQrCodes(
                              kennelShortName: widget.futureRun.kennelShortName,
                              eventId: widget.futureRun.eventId,
                              eventName: widget.futureRun.eventName,
                              eventNumber: widget.futureRun.eventNumber,
                              eventStartDatetime:
                                  widget.futureRun.eventStartDatetime,
                              isStart: false,
                            )));
              }),
        ),
      ],
    );
  }

  Future<void> _launchMaps(double lat, double lon) async {
    final String googleWebUrl =
        'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
    //String googleAppUrl = 'comgooglemaps://maps.google.com/maps/place/<name>/@<lat>,<long>,15z/data=<mode-value>';
    final String googleAppUrl = 'comgooglemaps://?q=$lat,$lon';
    final String appleUrl = 'https://maps.apple.com/?sll=$lat,$lon';
    if (await canLaunch('comgooglemaps://')) {
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
    // return Future<void>(() {});((){});
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
      duration: const Duration(seconds: 3),
    ));
  }

  Future<bool> _promptForHare(String hareList) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Will you Hare this run?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Please confirm that you are'),
                const Text('signing up to hare this run'),
                Text(hareList.isEmpty ? '' : 'with ' + hareList),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: const Text('No Thanks!'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            FlatButton(
              child: const Text('Yes, I\'ll Hare!'),
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

// class _Tile extends StatelessWidget {
//   const _Tile(this.source, this.index);

//   final String source;
//   final int index;

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       child: Column(
//         children: <Widget>[
//           Image.network(source),
//           Padding(
//             padding: const EdgeInsets.all(4.0),
//             child: Column(
//               children: <Widget>[
//                 Text(
//                   'Image number $index',
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 const Text(
//                   'Vincent Van Gogh',
//                   style: TextStyle(color: Colors.grey),
//                 ),
//               ],
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }

class RectClipper extends CustomClipper<Rect> {
  RectClipper({@required this.width, @required this.height});

  double width;
  double height;

  @override
  Rect getClip(Size size) {
    final Rect r = const Offset(0.0, 0.0) & Size(width, height - 33);

    // This is where we decide what part of our image is going to be
    // visible. If you try to run the app now, nothing will be shown.
    return r;
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => false;
}
