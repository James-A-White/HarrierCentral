import 'dart:async';

import 'package:flutter/material.dart';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:scoped_model/scoped_model.dart';

import 'package:harrier_central/data_models/user_run_history_model.dart';
import 'package:harrier_central/data_models/join_event_model.dart';
import 'package:harrier_central/services/user_run_history_scoped_model.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/styles.dart';
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

  UserRunHistoryScopedModel model;

  @override
  void initState() {
    super.initState();
    model = UserRunHistoryScopedModel(kennelId: kennelId);
  }

  int pageIndex = 1;

  @override
  Widget build(BuildContext context) {
    return ScopedModel<UserRunHistoryScopedModel>(
      model: model,
      child: Scaffold(
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
        body: ScopedModelDescendant<UserRunHistoryScopedModel>(
          builder: (BuildContext context, Widget child,
              UserRunHistoryScopedModel model) {
            if ((model.userEventList.isEmpty) && (!model.isLoading)) {
              // TODO(James): Check this statement and make sure the cast to FALSE is correct
              model.getUserEventsFromBackend(true).then((void dummy) {
                myRunCount = model.userEventList
                    .where((UserEventHistoryModel ueh) =>
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
    model.getUserEventsFromBackend(false);
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

    final List<UserEventHistoryModel> list = model.userEventList
        .where((UserEventHistoryModel ueh) =>
            ueh.attendenceState >= attendenceAtHash.value)
        .toList();

    list.sort((UserEventHistoryModel a, UserEventHistoryModel b) =>
        a.eventStartDatetime.compareTo(b.eventStartDatetime));

    for (int i = 0; i < list.length; i++) {
      list[i].totalRunsThisKennel = runCounter;
      runCounter++;
      if (list[i].isHare == isHareYes.value)
      {
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
                        final UserEventHistoryModel userEventHistoryModel =
                            model.userEventList[index];
                        return Dismissible(
                            key: Key(userEventHistoryModel.eventId),
                            confirmDismiss: (DismissDirection direction) {
                              if (userEventHistoryModel.canEditRunAttendence !=
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
                                    if (userEventHistoryModel.attendenceState <
                                        attendenceAtHash.value) {
                                      userEventHistoryModel.isLoading = true;
                                      model
                                          .setRsvpState(
                                              rsvpYes.value,
                                              isHareNo.value,
                                              attendenceAtHash.value,
                                              userEventHistoryModel.eventId)
                                          .then((JoinEventModel result) {
                                        setState(() {
                                          userEventHistoryModel
                                                  .attendenceState =
                                              attendenceAtHash.value;
                                          userEventHistoryModel.isLoading =
                                              false;
                                          myRunCount = model.userEventList
                                              .where(
                                                  (UserEventHistoryModel ueh) =>
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
                                      userEventHistoryModel.isLoading = true;
                                      model
                                          .setRsvpState(
                                              rsvpYes.value,
                                              userEventHistoryModel.isHare ==
                                                      isHareNo.value
                                                  ? isHareYes.value
                                                  : isHareNo.value,
                                              attendenceAtHash.value,
                                              userEventHistoryModel.eventId)
                                          .then((JoinEventModel result) {
                                        setState(() {
                                          userEventHistoryModel.isHare =
                                              userEventHistoryModel.isHare ==
                                                      isHareNo.value
                                                  ? isHareYes.value
                                                  : isHareNo.value;
                                          userEventHistoryModel
                                                  .attendenceState =
                                              attendenceAtHash.value;
                                          userEventHistoryModel.isLoading =
                                              false;
                                          myRunCount = model.userEventList
                                              .where(
                                                  (UserEventHistoryModel ueh) =>
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
                                    if (userEventHistoryModel.attendenceState !=
                                        attendenceNo.value) {
                                      userEventHistoryModel.isLoading = true;
                                      model
                                          .setRsvpState(
                                              rsvpNo.value,
                                              isHareNo.value,
                                              attendenceNo.value,
                                              userEventHistoryModel.eventId)
                                          .then((JoinEventModel result) {
                                        setState(() {
                                          userEventHistoryModel
                                                  .attendenceState =
                                              attendenceNo.value;
                                          userEventHistoryModel.isLoading =
                                              false;

                                          myRunCount = model.userEventList
                                              .where(
                                                  (UserEventHistoryModel ueh) =>
                                                      ueh.attendenceState >=
                                                      attendenceAtHash.value)
                                              .length;
                                        });

                                        updateMyRunCounts();
                                      });
                                      userEventHistoryModel.attendenceState =
                                          attendenceNo.value;
                                    }
                                  }
                                });
                              }
                              return Future<bool>.value(false);
                            },
                            background: userEventHistoryModel
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
                            secondaryBackground: userEventHistoryModel
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
                                : (userEventHistoryModel.attendenceState <
                                            attendenceAtHash.value) ||
                                        ((userEventHistoryModel
                                                    .attendenceState >=
                                                attendenceAtHash.value) &&
                                            (userEventHistoryModel.isHare ==
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
