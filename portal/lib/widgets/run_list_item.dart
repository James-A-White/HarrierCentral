import 'package:hcportal/imports.dart';
import 'package:intl/intl.dart';

class RunListItem extends StatefulWidget {
  const RunListItem({
    required this.event,
    required this.onTap,
    super.key,
  });

  final RunListModel event;
  final void Function()? onTap;

  @override
  RunListItemState createState() => RunListItemState();
}

class RunListItemState extends State<RunListItem> {
  RunListItemState();

  @override
  void initState() {
    super.initState();
    //_rsvpIcon = Future<Widget>.value(getRsvpWidget(widget.futureRun.rsvpState, widget.futureRun.isHare));
    //WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    //WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   //print('App lifecycle state => ' + state.toString());
  //   super.didChangeAppLifecycleState(state);
  // }

  //Future<Widget> _rsvpIcon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(top: 10),
      color: Colors.white,
      child: InkWell(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.only(top: 5, left: 10),
                    child: Text(
                      widget.event.eventName,
                      style: const TextStyle(
                        fontFamily: 'AvenirNextCondensedDemiBold',
                        fontStyle: FontStyle.normal,
                        fontSize: 17,
                        color: Colors.black,
                        height: 1,
                      ),
                      textAlign: TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              //padding: const EdgeInsets.only(top: 15.0, bottom: 10.0),
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.only(top: 7),
              height: 1,
              color: Colors.grey.shade300,
            ),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 100,
                  child: TextButton(
                    style: ButtonStyle(
                      backgroundColor:
                          WidgetStateProperty.all<Color>(Colors.white),
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            0,
                          ), // Adjust the radius here
                        ),
                      ),
                    ),
                    // splashColor: Theme.of(context).accentColor,
                    // highlightColor: Theme.of(context).accentColor,
                    onPressed: () {
                      widget.onTap?.call();
                    },
                    //padding: const EdgeInsets.only(top: 10.0, left: 4.0, right: 0.0, bottom: 10.0),
                    child: Row(
                      children: <Widget>[
                        KennelLogo(
                          //kennelId: widget.futureRun.kennelId,
                          kennelLogoUrl: widget.event.kennelLogo,
                          kennelShortName: widget.event.kennelShortName,
                          logoHeight: 70.0,
                          leftPadding: 7.0,
                          rightPadding: 7.0,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 6,
                              left: 8,
                              bottom: 6,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              //mainAxisAlignment: MainAxisAlignment.center,
                              //mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                Text(
                                  widget.event.kennelName,
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 130, 0, 0),
                                    fontFamily: 'AvenirNextBold',
                                    fontStyle: FontStyle.normal,
                                    fontSize: 15,
                                    height: 1,
                                  ),
                                  textAlign: TextAlign.left,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  (widget.event.isCountedRun == 1
                                          ? 'Run #${widget.event.eventNumber}, '
                                          : 'Run / Event ') +
                                      (widget.event.daysUntilEvent <= 14
                                          ? widget.event.daysUntilEvent == 0
                                              ? 'TODAY'
                                              : widget.event.daysUntilEvent == 1
                                                  ? 'Tomorrow'
                                                  : widget.event
                                                              .daysUntilEvent ==
                                                          -1
                                                      ? 'Yesterday'
                                                      : widget.event
                                                                  .daysUntilEvent >
                                                              1
                                                          ? 'in ${widget.event.daysUntilEvent} days'
                                                          : '${widget.event.daysUntilEvent.abs()} days ago'
                                          : (widget.event.daysUntilEvent <= 30)
                                              ? 'in ${widget.event.daysUntilEvent ~/ 7.0}${(widget.event.daysUntilEvent ~/ 7.0) == 1 ? ' week' : ' weeks'}'
                                              : widget.event.daysUntilEvent <=
                                                      365
                                                  ? 'in ${widget.event.daysUntilEvent ~/ 30.0}${(widget.event.daysUntilEvent ~/ 30.0) == 1 ? ' month' : ' months'}'
                                                  : 'in ${widget.event.daysUntilEvent ~/ 365.0}${(widget.event.daysUntilEvent ~/ 365.0) == 1 ? ' year' : ' years'}'),
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontFamily: 'AvenirNextDemiBold',
                                    fontStyle: FontStyle.normal,
                                    fontSize: 15,
                                    height: 1,
                                  ),
                                  textAlign: TextAlign.left,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat("E, MMM d 'at' h:mm a")
                                      .format(widget.event.eventStartDatetime),
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontFamily: 'AvenirNextRegular',
                                    fontStyle: FontStyle.normal,
                                    fontSize: 15,
                                    height: 1,
                                  ),
                                  textAlign: TextAlign.left,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.event.eventCityAndCountry,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontFamily: 'AvenirNextRegular',
                                    fontStyle: FontStyle.normal,
                                    fontSize: 15,
                                    height: 1,
                                  ),
                                  textAlign: TextAlign.left,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if ((widget.event.locationOneLineDesc ?? '') !=
                                    '') ...<Widget>[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Location: ${widget.event.locationOneLineDesc!}',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontFamily: 'AvenirNextRegular',
                                      fontStyle: FontStyle.normal,
                                      fontSize: 15,
                                      height: 1,
                                    ),
                                    textAlign: TextAlign.left,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                if ((widget.event.hares ?? '') !=
                                    '') ...<Widget>[
                                  Text(
                                    'Hares: ${widget.event.hares!}',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontFamily: 'AvenirNextRegular',
                                      fontStyle: FontStyle.normal,
                                      fontSize: 15,
                                      height: 1,
                                    ),
                                    textAlign: TextAlign.left,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                if (widget.event.eventGeographicScope >
                                    1) ...<Widget>[
                                  const SizedBox(height: 4),
                                  Text(
                                    SPECIAL_EVENT_STRINGS.keys.elementAt(
                                      widget.event.eventGeographicScope,
                                    ),
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontFamily: 'AvenirNextBold',
                                      fontStyle: FontStyle.normal,
                                      fontSize: 15,
                                      height: 1,
                                    ),
                                    textAlign: TextAlign.left,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
