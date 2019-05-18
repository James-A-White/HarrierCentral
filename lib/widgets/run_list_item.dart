import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:harrier_central/pages/detail_pages/run_details_page.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/widgets/kennel_logo.dart';
import 'package:harrier_central/pages/top_level/future_run_list_page.dart';

//import 'package:flip_panel/flip_panel.dart';

class RunListItem extends StatefulWidget {
  const RunListItem({Key key, @required this.futureRun}) : super(key: key);

  final FutureRunAggregate futureRun;

  @override
  _RunListItemState createState() => _RunListItemState();
}

class _RunListItemState extends State<RunListItem> with WidgetsBindingObserver {
  _RunListItemState();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('App lifecycle state => ' + state.toString());
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    // return IntrinsicWidth(
    //     child:
    return Card(
        elevation: 4.0,
        margin: const EdgeInsets.only(top: 10.0, left: 0.0, right: 0.0),
        color: Colors.white,
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 5.0, left: 8.0, right: 8.0),
            child: Text(
              widget.futureRun.event.eventName,
              style: const TextStyle(fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 17.0, color: Colors.black, height: 1.0),
              textAlign: TextAlign.left,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Stack(children: <Widget>[
          //   Positioned(top:10.0,
          //   child:FlipClock.reverseCountdown(
          //     //startTime: DateTime.now(),
          //     duration: widget.futureRun.eventStartDatetime
          //         .difference(DateTime.now()),
          //     digitColor: Colors.black,
          //     backgroundColor: Colors.white,
          //     digitSize: 30.0,
          //     width: 20.0,
          //     flipDirection: FlipDirection.down,
          //     borderRadius: const BorderRadius.all(Radius.circular(2.0)),
          //     //onDone: () => print('ih'),
          //   ),),
          // ]),
          Container(
            //padding: const EdgeInsets.only(top: 15.0, bottom: 10.0),
            margin: const EdgeInsets.only(top: 7.0, bottom: 0.0),
            padding: const EdgeInsets.only(top: 7.0, bottom: 0.0),
            height: 1.0,
            color: Colors.grey[300],
          ),
          FlatButton(
            splashColor: Theme.of(context).accentColor,
            highlightColor: Theme.of(context).accentColor,
            onPressed: () {
              Navigator.push<dynamic>(
                this.context,
                MaterialPageRoute<dynamic>(
                  builder: (BuildContext context) => RunDetailsPage(futureRun: widget.futureRun),
                ),
              );
              //   },
              // );
            },
            padding: const EdgeInsets.only(top: 10.0, left: 4.0, right: 10.0, bottom: 10.0),
            child: Stack(
              children: <Widget>[
                widget.futureRun.extensions.hareList == null ? Align(alignment: Alignment.topRight, child: Image(width: 75.0, height: 75.0, fit: BoxFit.fill, image: const AssetImage('images/other/hare_needed_stamp.png'))) : Container(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Stack(alignment: Alignment.center, children: <Widget>[
                      KennelLogo(
                        kennelLogoUrl: widget.futureRun.kennel.kennelLogo,
                        kennelShortName: widget.futureRun.kennel.kennelShortName,
                        logoHeight: 70.0,
                        leftPadding: 10.0,
                      ),
                    ]),
                    Padding(
                      padding: const EdgeInsets.only(top: 3.0, left: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Run #${widget.futureRun.event.eventNumber}, ' +
                                (widget.futureRun.extensions.daysUntilEvent <= 14
                                    ? widget.futureRun.extensions.daysUntilEvent.toInt() == 0 ? 'TODAY' : widget.futureRun.extensions.daysUntilEvent.toInt() == 1 ? 'Tomorrow' : 'in ${widget.futureRun.extensions.daysUntilEvent.toInt().toString()} days'
                                    : (widget.futureRun.extensions.daysUntilEvent <= 30)
                                        ? 'in ' + (widget.futureRun.extensions.daysUntilEvent ~/ 7.0).toString() + ((widget.futureRun.extensions.daysUntilEvent ~/ 7.0) == 1 ? ' week' : ' weeks')
                                        : widget.futureRun.extensions.daysUntilEvent <= 365
                                            ? 'in ' + (widget.futureRun.extensions.daysUntilEvent ~/ 30.0).toString() + ((widget.futureRun.extensions.daysUntilEvent ~/ 30.0) == 1 ? ' month' : ' months')
                                            : 'in ' + (widget.futureRun.extensions.daysUntilEvent ~/ 365.0).toString() + ((widget.futureRun.extensions.daysUntilEvent ~/ 365.0) == 1 ? ' year' : ' years')),
                            style: const TextStyle(color: Colors.black87, fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, fontSize: 15.0, height: 0.85),
                            textAlign: TextAlign.left,
                          ),
                          Text(
                            DateFormat("E, MMM d 'at' h:mm a").format(widget.futureRun.event.eventStartDatetime),
                            style: const TextStyle(color: Colors.black87, fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 15.0, height: 0.85),
                            textAlign: TextAlign.left,
                          ),
                          Text(
                            widget.futureRun.extensions.hareList == null ? 'RSVP to sign up to Hare!' : 'Hares: ' + widget.futureRun.extensions.hareList,
                            style: const TextStyle(color: Colors.black87, fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 15.0, height: 0.85),
                            textAlign: TextAlign.left,
                          ),
                          widget.futureRun.extensions.distToEvent >= 0
                              ? Text(
                                  Utilities.getDistance(widget.futureRun.extensions.distToEvent, context) + ' from here',
                                  style: const TextStyle(color: Colors.black87, fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 15.0, height: 0.85),
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
          )
        ]));
  }
}
