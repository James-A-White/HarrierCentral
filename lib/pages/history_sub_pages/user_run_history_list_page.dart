import 'dart:async';

import 'package:flutter/material.dart';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:scoped_model/scoped_model.dart';

import 'package:harrier_central/data/models/lite_event_model.dart';
import 'package:harrier_central/data/models/join_event_model.dart';
import 'package:harrier_central/data/services/event_scoped_model.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/widgets/kennel_logo.dart';
import 'package:harrier_central/widgets/user_event_list_item.dart';

class UserRunHistoryListPage extends StatefulWidget {
  const UserRunHistoryListPage(
      {Key key,
      @required this.kennelId,
      @required this.kennelName,
      @required this.kennelShortName,
      @required this.kennelLogo})
      : super(key: key);

  final String kennelId;
  final String kennelName;
  final String kennelShortName;
  final String kennelLogo;

  @override
  UserRunHistoryPageState createState() =>
      UserRunHistoryPageState(kennelId: kennelId);
}

class UserRunHistoryPageState extends State<UserRunHistoryListPage> {
  UserRunHistoryPageState({@required this.kennelId});

  String kennelId;

  EventsScopedModel model;

  @override
  void initState() {
    super.initState();
    model = EventsScopedModel(kennelId: kennelId);
  }

  int pageIndex = 1;

  @override
  Widget build(BuildContext context) {
    return ScopedModel<EventsScopedModel>(
      model: model,
      child: Scaffold(
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
              child: const Icon(MaterialCommunityIcons.email),
              backgroundColor: Colors.teal[800],
              label: 'Email this kennel\'s run history',
              labelStyle: const TextStyle(fontSize: 18.0),
              onTap: () => {
                    model
                        .sendRunCountReportByEmail(
                            kennelId: kennelId, kennelName: widget.kennelName)
                        .then((Map<String, String> result) {
                      if (result['result']
                          .toLowerCase()
                          .startsWith('success')) {
                        Utilities.showAlert(
                            context,
                            'E-mail successfully sent',
                            'Your payment report has been successfully e-mailed to:\r\n\r\n${result['email']}\r\n\r\nIf you do not see it in the next few minutes, check your spam folder.',
                            'OK');
                      }
                    })
                  },
            ),
            SpeedDialChild(
              child: const Icon(MaterialCommunityIcons.email_plus),
              backgroundColor: Colors.blue[900],
              label: 'Email all kennels run history',
              labelStyle: const TextStyle(fontSize: 18.0),
              onTap: () => {
                    model
                        .sendRunCountReportByEmail(
                            kennelId: GUID_EMPTY, kennelName: 'All of your Hash Kennels')
                        .then((Map<String, String> result) {
                      if (result['result']
                          .toLowerCase()
                          .startsWith('success')) {
                        Utilities.showAlert(
                            context,
                            'E-mail successfully sent',
                            'Your payment report has been successfully e-mailed to:\r\n\r\n${result['email']}\r\n\r\nIf you do not see it in the next few minutes, check your spam folder.',
                            'OK');
                      }
                    })
                  },
            ),
          ],
        ),
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: themeAppBarBackground,
          title: Text(
            'My runs for ${widget.kennelShortName}',
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        body: ScopedModelDescendant<EventsScopedModel>(
          builder: (BuildContext context, Widget child,
              EventsScopedModel model) {
            if ((model.userEventList.isEmpty) && (!model.isLoading)) {
              // TODO(James): Check this statement and make sure the cast to FALSE is correct
              model.getUserEventsFromBackend(true,1,0,0).then((void dummy) {
                myRunCount = model.userEventList
                    .where((Event ueh) =>
                        ueh.attendenceState >= attendenceAtHash.value)
                    .length;
              });
            }

            return model.isLoading
                ? _buildCircularProgressIndicator()
                : _buildListView();
          },
        ),
      ),
    );
  }

  Widget _buildCircularProgressIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Future<void> _handleRefresh() async {
    model.clearKennelList();
    model.getUserEventsFromBackend(false,1,0,0);
    //model.notifyListeners();
  }

  static const TextStyle headingStyle = TextStyle(
      fontFamily: 'AvenirNextCondensedDemiBold',
      fontStyle: FontStyle.normal,
      fontSize: 22.0,
      height: 0.6);

  static const TextStyle numberStyle = TextStyle(
    fontFamily: 'AvenirNextCondensedDemiBold',
    fontStyle: FontStyle.normal,
    fontSize: 22.0,
  );

  int myRunCount = 0;

  void updateMyRunCounts() {
    int runCounter = 1;
    int haringCounter = 1;

    final List<Event> list = model.userEventList
        .where((Event ueh) =>
            ueh.attendenceState >= attendenceAtHash.value)
        .toList();

    list.sort((Event a, Event b) =>
        a.eventStartDatetime.compareTo(b.eventStartDatetime));

    for (int i = 0; i < list.length; i++) {
      list[i].totalRunsThisKennel = runCounter;
      runCounter++;
      if (list[i].isHare == isHareYes.value) {
        list[i].totalHaringThisKennel = haringCounter;
        haringCounter++;
      }
    }
  }

  Widget _buildListView() {
    return Container(
      decoration: Backgrounds.defaultHcBackgroundLight(),
      padding: const EdgeInsets.only(top: 0.0),
      child: model.getKennelsCount() == 0
          ? const Center(child: Text('No Kennels available.'))
          : RefreshIndicator(
              onRefresh: () => _handleRefresh(),
              displacement: 130.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Container(
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
                    //color:Color.fromARGB(30, 0, 0, 0),
                    padding: const EdgeInsets.only(
                        left: 5, top: 5, right: 20, bottom: 5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Container(
                          child: AutoSizeText(
                            '${widget.kennelName}',
                            //'Super fucking long text thats sure to overflow and more',
                            //'999',
                            overflow: TextOverflow.ellipsis,
                            minFontSize: 18.0,
                            maxLines: 1,
                            style: numberStyle,
                            textAlign: TextAlign.center,
                          ),
                          //color: Colors.green,
                        ),
                        Container(
                          height: 100,
                          child: KennelLogo(
                            kennelLogoUrl: widget.kennelLogo,
                            kennelShortName: widget.kennelShortName,
                            logoHeight: 100.0,
                            leftPadding: 0.0,
                          ),
                        ),
                        Container(
                          child: AutoSizeText(
                            'My run count: ${myRunCount.toString()}',
                            //'Super fucking long text thats sure to overflow and more',
                            //'999',
                            overflow: TextOverflow.ellipsis,
                            minFontSize: 18.0,
                            maxLines: 1,
                            style: numberStyle,
                            textAlign: TextAlign.center,
                          ),
                          //color: Colors.green,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: model.getKennelsCount(),
                      padding: const EdgeInsets.only(top: 5),
                      separatorBuilder: (BuildContext context, int index) =>
                          const Divider(
                            height: 1.0,
                            color: Colors.black45,
                          ),
                      //itemExtent: 58.0,
                      //shrinkWrap: true,
                      itemBuilder: (BuildContext context, int index) {
                        final Event eventModel =
                            model.userEventList[index];
                        return Dismissible(
                            key: Key(eventModel.eventId),
                            confirmDismiss: (DismissDirection direction) {
                              if (eventModel.canEditRunAttendence !=
                                  0) {
                                setState(() {
                                  // swipe from right to left to indicate that
                                  // the hasher either attended the run as a pack
                                  // member or as a hare
                                  if (direction ==
                                      DismissDirection.endToStart) {
                                    // here, we're going from an attendence state of
                                    // not at the Hash to being at the Hash,
                                    // so assume that the person was not a hare
                                    if (eventModel.attendenceState <
                                        attendenceAtHash.value) {
                                      eventModel.isLoading = true;
                                      model
                                          .setRsvpState(
                                              rsvpYes.value,
                                              isHareNo.value,
                                              attendenceAtHash.value,
                                              eventModel.eventId)
                                          .then((JoinEventModel result) {
                                        setState(() {
                                          eventModel
                                                  .attendenceState =
                                              attendenceAtHash.value;
                                          eventModel.isLoading =
                                              false;
                                          myRunCount = model.userEventList
                                              .where(
                                                  (Event ueh) =>
                                                      ueh.attendenceState >=
                                                      attendenceAtHash.value)
                                              .length;
                                        });

                                        updateMyRunCounts();
                                      });
                                    } else {
                                      // here, the attendence was already at a Hash so we want
                                      // to cycle back and forth from being a hare to not being
                                      // a hare but leave the attendence and rsvp values at Yes
                                      eventModel.isLoading = true;
                                      model
                                          .setRsvpState(
                                              rsvpYes.value,
                                              eventModel.isHare ==
                                                      isHareNo.value
                                                  ? isHareYes.value
                                                  : isHareNo.value,
                                              attendenceAtHash.value,
                                              eventModel.eventId)
                                          .then((JoinEventModel result) {
                                        setState(() {
                                          eventModel.isHare =
                                              eventModel.isHare ==
                                                      isHareNo.value
                                                  ? isHareYes.value
                                                  : isHareNo.value;
                                          eventModel
                                                  .attendenceState =
                                              attendenceAtHash.value;
                                          eventModel.isLoading =
                                              false;
                                          myRunCount = model.userEventList
                                              .where(
                                                  (Event ueh) =>
                                                      ueh.attendenceState >=
                                                      attendenceAtHash.value)
                                              .length;
                                        });

                                        updateMyRunCounts();
                                      });
                                    }
                                  } else {
                                    // swipe from left to right to
                                    // indicate that the hasher did
                                    // not participate in this event
                                    if (eventModel.attendenceState !=
                                        attendenceNo.value) {
                                      eventModel.isLoading = true;
                                      model
                                          .setRsvpState(
                                              rsvpNo.value,
                                              isHareNo.value,
                                              attendenceNo.value,
                                              eventModel.eventId)
                                          .then((JoinEventModel result) {
                                        setState(() {
                                          eventModel
                                                  .attendenceState =
                                              attendenceNo.value;
                                          eventModel.isLoading =
                                              false;

                                          myRunCount = model.userEventList
                                              .where(
                                                  (Event ueh) =>
                                                      ueh.attendenceState >=
                                                      attendenceAtHash.value)
                                              .length;
                                        });

                                        updateMyRunCounts();
                                      });
                                      eventModel.attendenceState =
                                          attendenceNo.value;
                                    }
                                  }
                                });
                              }
                              return Future<bool>.value(false);
                            },
                            background: eventModel
                                        .canEditRunAttendence ==
                                    0
                                ? Container(
                                    color: Colors.grey,
                                    child: Row(children: const <Widget>[
                                      Padding(
                                        padding: EdgeInsets.only(left: 10.0),
                                        child: Icon(FontAwesome.lock,
                                            color: Colors.white, size: 35.0),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(left: 15.0),
                                        child: Text(
                                            // '${Utilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Bank Transfer',
                                            'Run locked',
                                            style: TextStyle(
                                                fontFamily:
                                                    'AvenirNextDemiBold',
                                                fontStyle: FontStyle.normal,
                                                color: Colors.white,
                                                fontSize: 17.0,
                                                height: 1.0)),
                                      )
                                    ]))
                                : Container(
                                    color: Colors.red,
                                    child: Row(children: const <Widget>[
                                      Padding(
                                        padding: EdgeInsets.only(left: 10.0),
                                        child: Icon(FontAwesome.times_circle,
                                            color: Colors.white, size: 35.0),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(left: 15.0),
                                        child: Text(
                                            // '${Utilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Bank Transfer',
                                            'I was not there',
                                            style: TextStyle(
                                                fontFamily:
                                                    'AvenirNextDemiBold',
                                                fontStyle: FontStyle.normal,
                                                color: Colors.white,
                                                fontSize: 17.0,
                                                height: 1.0)),
                                      )
                                    ])),
                            secondaryBackground: eventModel
                                        .canEditRunAttendence ==
                                    0
                                ? Container(
                                    color: Colors.grey,
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: const <Widget>[
                                          Padding(
                                            padding:
                                                EdgeInsets.only(right: 15.0),
                                            child: Icon(FontAwesome.lock,
                                                color: Colors.white,
                                                size: 35.0),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsets.only(right: 15.0),
                                            child: Text(
                                                //'${Utilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Cash',
                                                'Run locked',
                                                style: TextStyle(
                                                    fontFamily:
                                                        'AvenirNextDemiBold',
                                                    fontStyle: FontStyle.normal,
                                                    color: Colors.white,
                                                    fontSize: 17.0,
                                                    height: 1.0)),
                                          )
                                        ]))
                                : (eventModel.attendenceState <
                                            attendenceAtHash.value) ||
                                        ((eventModel
                                                    .attendenceState >=
                                                attendenceAtHash.value) &&
                                            (eventModel.isHare ==
                                                isHareYes.value))
                                    ? Container(
                                        color: Colors.green,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: const <Widget>[
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(right: 15.0),
                                              child: Icon(
                                                  FontAwesome.check_circle,
                                                  color: Colors.white,
                                                  size: 35.0),
                                            ),
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(right: 15.0),
                                              child: Text(
                                                  //'${Utilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Cash',
                                                  'I was at the Hash',
                                                  style: TextStyle(
                                                      fontFamily:
                                                          'AvenirNextDemiBold',
                                                      fontStyle:
                                                          FontStyle.normal,
                                                      color: Colors.white,
                                                      fontSize: 17.0,
                                                      height: 1.0)),
                                            )
                                          ],
                                        ),
                                      )
                                    : Container(
                                        color: Colors.purple,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: const <Widget>[
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(right: 15.0),
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                    left: 2.5, right: 2.5),
                                                child: ImageIcon(
                                                    AssetImage(
                                                        'images/icons/hare_icon.png'),
                                                    color: Colors.white,
                                                    size: 30.0),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(right: 15.0),
                                              child: Text(
                                                  //'${Utilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Cash',
                                                  'I was a Hare',
                                                  style: TextStyle(
                                                      fontFamily:
                                                          'AvenirNextDemiBold',
                                                      fontStyle:
                                                          FontStyle.normal,
                                                      color: Colors.white,
                                                      fontSize: 17.0,
                                                      height: 1.0)),
                                            )
                                          ],
                                        ),
                                      ),
                            onDismissed: (DismissDirection direction) {
                              print(direction.toString() +
                                  ' NOTE: We should never reach this point');
                            },
                            child: UserEventListItem(
                              userEventHistoryModel: model.userEventList[index],
                              kennelShortName: widget.kennelShortName,
                            ));

                        // Container(
                        //   height: 60.0,
                        //   //padding: const EdgeInsets.only(top: 10.0),
                        //   child:

                        // KennelRunHistoryCountListItem(
                        //     kennelRunHistoryCount:
                        //         model.kennelRunCountList[index]);

                        // );
                      },
                    ),
                  ),
                ],
              )),
    );
  }
}
