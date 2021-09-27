// @dart=2.11
import 'package:harrier_central/imports.dart';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:intl/intl.dart';

class KennelAdminMainPage extends StatefulWidget {
  const KennelAdminMainPage({@required this.kennelAggregateItem});
  final KennelListAggregate kennelAggregateItem;

  @override
  KennelAdminMainPageState createState() => KennelAdminMainPageState();
}

class KennelAdminMainPageState extends State<KennelAdminMainPage> {
  num sliderValue;
  bool _isLoading = true;

  @override
  void initState() {
    if ((widget.kennelAggregateItem.kennel.kennelMismanagementTeam == null) || (widget.kennelAggregateItem.kennel.kennelMismanagementTeam.trim().isEmpty)) {
      mismanagement = null;
    } else {
      mismanagement = widget.kennelAggregateItem.kennel.kennelMismanagementTeam.contains('\r')
          ? widget.kennelAggregateItem.kennel.kennelMismanagementTeam.split('\r')
          : widget.kennelAggregateItem.kennel.kennelMismanagementTeam.split('\n');
    }

    G0<TableModel>().syncKennelAdminService.updateFromBackend(SyncKennelAdminService.flagsAllData, false, widget.kennelAggregateItem.kennel.kennelId).then((bool result) {
      _refreshFromTable(true).then((void dummy) {
        setState(() {
          final String resultStr = result ? 'successfully' : 'unsuccessfully';
          print('Event admin data synchronized $resultStr');
          _isLoading = false;
        });
      });
    });

    sliderValue = 5.0;
    isAdmin = widget.kennelAggregateItem.hkm.appAccess.isAdmin;
    super.initState();
  }

  MapController mapController = MapController();

  int flexLeft = 3;
  int flexRight = 7;

  bool isAdmin = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  KennelMembersList kennelMembersList;

  List<String> mismanagement;

  List<RunDetailsAggregate> allRuns;

  Future<void> _refreshFromTable(bool forceRefresh) async {
    if (forceRefresh || (allRuns == null) || (allRuns.isEmpty)) {
      //final Geolocator locator = Geolocator();

      final List<Map<String, dynamic>> results =
          await QueryRuns.queryRuns(EnumRunQueryType.kennelDetailPage, EnumRunQueryContext.kennelAdmin, kennelId: widget.kennelAggregateItem.kennel.kennelId);

      allRuns = <RunDetailsAggregate>[];
      for (int i = 0; i < results.length; i++) {
        num dist;
        if ((results[i]['latitude'] != null) && (results[i]['longitude'] != null)) {
          dist = Geolocator.distanceBetween(G0<DeviceInfo>().deviceLat, G0<DeviceInfo>().deviceLon, results[i]['latitude'] + .0, results[i]['longitude'] + .0);
        }
        final EventModel eventItem = G0<TableModel>().eventsTableHelper.fromMap(results[i]);
        final KennelsModel kennelItem = G0<TableModel>().kennelsTableHelper.fromMap(results[i]);
        final RunDetailsQueryExtensions extensionsItem = RunDetailsQueryExtensions.fromMap(results[i], eventItem.eventStartDatetime);
        extensionsItem.distToEvent = dist;

        String paymentLinkUrl = '';

        if (((eventItem.eventPaymentUrl ?? '') != '') && ((eventItem.eventPaymentUrlExpires == null) || (eventItem.eventPaymentUrlExpires.isAfter(DateTime.now())))) {
          paymentLinkUrl = eventItem.eventPaymentUrl;
        } else if (((kennelItem.kennelPaymentUrl ?? '') != '') && ((kennelItem.kennelPaymentUrlExpires == null) || (kennelItem.kennelPaymentUrlExpires.isAfter(DateTime.now())))) {
          paymentLinkUrl = kennelItem.kennelPaymentUrl;
        }

        final num julianNow = results[i]['nowJulian'];
        final num eventJulian = results[i]['eventJulian'];

        print('Julian now = $julianNow, Event julian = $eventJulian, EventName = ${eventItem.eventName}');

        final RunDetailsAggregate item = RunDetailsAggregate(event: eventItem, kennel: kennelItem, extensions: extensionsItem, paymentUrl: paymentLinkUrl);
        allRuns.add(item);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      Container(height: MediaQuery.of(context).size.height, width: MediaQuery.of(context).size.width),
      Positioned(
        top: 0,
        left: 0,
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: themeAppBarBackground,
            title: Text(
              '${widget.kennelAggregateItem.kennel.kennelShortName}',
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          body: _isLoading
              ? Center(
                  child: HcCircularProgressIndicator(key: UniqueKey()),
                )
              : Container(
                  height: MediaQuery.of(context).size.height,
                  decoration: Backgrounds.defaultHcBackground(),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 30.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          ((widget.kennelAggregateItem.kennel.kennelCoverPhoto ?? '').isNotEmpty && widget.kennelAggregateItem.kennel.kennelCoverPhoto.startsWith('http'))
                              ? Column(mainAxisSize: MainAxisSize.max, children: <Widget>[
                                  Container(
                                      margin: const EdgeInsets.only(bottom: 20.0),
                                      width: MediaQuery.of(context).size.width - 40,
                                      child: Text(widget.kennelAggregateItem.kennel.kennelName, textAlign: TextAlign.center, maxLines: 3, style: titleStyle)),
                                  KennelLogo(
                                    kennelLogoUrl: widget.kennelAggregateItem.kennel.kennelLogo,
                                    kennelShortName: widget.kennelAggregateItem.kennel.kennelShortName,
                                    logoHeight: 200.0,
                                    leftPadding: 0.0,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 45.0, bottom: 15.0),
                                    child: FancyDivider(key: UniqueKey(), innerColor: Colors.white),
                                  ),
                                  Padding(
                                      padding: const EdgeInsets.only(top: 20, bottom: 5),
                                      child: CachedNetworkImage(
                                        imageUrl: widget.kennelAggregateItem.kennel.kennelCoverPhoto,
                                        // errorWidget:
                                        //     (BuildContext context, String url, Exception error) =>
                                        //         const  Icon(Icons.error),
                                      )
                                      //decoration: BoxDecoration(color: Theme.of(context).selectedRowColor),
                                      ),
                                ])
                              : Column(
                                  children: <Widget>[
                                    Container(
                                        margin: const EdgeInsets.only(bottom: 20.0),
                                        width: MediaQuery.of(context).size.width - 40,
                                        child: Text(widget.kennelAggregateItem.kennel.kennelName, textAlign: TextAlign.center, maxLines: 3, style: titleStyle)),
                                    KennelLogo(
                                      kennelLogoUrl: widget.kennelAggregateItem.kennel.kennelLogo,
                                      kennelShortName: widget.kennelAggregateItem.kennel.kennelShortName,
                                      logoHeight: 200.0,
                                      leftPadding: 0.0,
                                    ),
                                  ],
                                ),
                          Padding(
                            padding: const EdgeInsets.only(top: 50.0, bottom: 25.0),
                            child: FancyDivider(key: UniqueKey(), innerColor: Colors.white),
                          ),
                          !isAdmin
                              ? Container()
                              : Column(
                                  children: <Widget>[
                                    Text(
                                      'Kennel Admin Functions',
                                      style: headingStyle,
                                      textAlign: TextAlign.center,
                                    ),
                                    Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: <Widget>[
                                      Container(
                                        margin: const EdgeInsets.only(top: 20, bottom: 15),
                                        width: 110,
                                        height: 110,
                                        child: Connection.styleForConnected(
                                          G0<AppModel>().connectionStatus,
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.only(top: 8.0, bottom: 0.0),
                                            ),
                                            child: Column(children: <Widget>[
                                              Padding(
                                                padding: const EdgeInsets.only(right: 2.0),
                                                child: Image.asset('images/icons/excel.png', height: 50.0, width: 50.0),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(left: 10, right: 10, top: 8),
                                                child: Text(
                                                  'Email run stats',
                                                  textAlign: TextAlign.center,
                                                  style: buttonLabelStyleSmall,
                                                ),
                                              ),
                                            ]),
                                            onPressed: () {
                                              if (Connection.checkForConnection(context, G0<AppModel>().connectionStatus)) {
                                                final EmailReportsService svc = EmailReportsService();
                                                svc
                                                    .sendKennelRunStatsReportByEmail(
                                                        kennelId: widget.kennelAggregateItem.kennel.kennelId,
                                                        kennelName: widget.kennelAggregateItem.kennel.kennelName,
                                                        digitsAfterDecimal: widget.kennelAggregateItem.extensions.digitsAfterDecimal,
                                                        currencySymbol: widget.kennelAggregateItem.extensions.currencySymbol)
                                                    .then((Map<String, String> result) {
                                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();

                                                  if (result['result'].toLowerCase().startsWith('success')) {
                                                    IveCoreUtilities.showAlert(
                                                        context,
                                                        'E-mail successfully sent',
                                                        'Your Kennel run stats report has been successfully e-mailed to:\r\n\r\n${result['email']}\r\n\r\nIf you do not see it in the next few minutes, check your spam folder.',
                                                        'OK');
                                                  }
                                                });

                                                IveCoreUtilities.showInSnackBar(context, _scaffoldKey, 'Run stats being processed...', durationInSeconds: 10);
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 15, bottom: 15),
                                        child: Container(
                                          width: 110,
                                          height: 110,
                                          child: Connection.styleForConnected(
                                            G0<AppModel>().connectionStatus,
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                padding: const EdgeInsets.only(top: 8.0, bottom: 0.0),
                                              ),
                                              child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                                                const Padding(
                                                  padding: EdgeInsets.only(left: 0),
                                                  child: Icon(Ionicons.md_people, color: Colors.white, size: 60),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 10, right: 10, top: 4),
                                                  child: Text(
                                                    'Manage Members',
                                                    textAlign: TextAlign.center,
                                                    style: buttonLabelStyleSmall,
                                                  ),
                                                ),
                                              ]),
                                              onPressed: () {
                                                if (Connection.checkForConnection(context, G0<AppModel>().connectionStatus)) {
                                                  kennelMembersList = KennelMembersList(kennelListAggregate: widget.kennelAggregateItem);
                                                  Navigator.push<dynamic>(
                                                    context,
                                                    MaterialPageRoute<dynamic>(
                                                      builder: (BuildContext context) => kennelMembersList,
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ]),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: <Widget>[
                                        Padding(
                                          padding: const EdgeInsets.only(top: 15, bottom: 15),
                                          child: Container(
                                            width: 110,
                                            height: 110,
                                            child: Connection.styleForConnected(
                                              G0<AppModel>().connectionStatus,
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  padding: const EdgeInsets.only(top: 8.0, bottom: 0.0),
                                                ),
                                                child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                                                  const Padding(
                                                    padding: EdgeInsets.only(left: 0),
                                                    child: Icon(MaterialCommunityIcons.playlist_edit, color: Colors.white, size: 60),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 10, right: 10, top: 5),
                                                    child: Text(
                                                      'Past\r\nevents',
                                                      textAlign: TextAlign.center,
                                                      style: buttonLabelStyleSmall,
                                                    ),
                                                  ),
                                                ]),
                                                onPressed: () {
                                                  if (Connection.checkForConnection(context, G0<AppModel>().connectionStatus)) {
                                                    Navigator.push<dynamic>(
                                                      context,
                                                      MaterialPageRoute<dynamic>(
                                                        builder: (BuildContext context) => AddEditEventsPage(
                                                          kennel: widget.kennelAggregateItem,
                                                          pageType: FilterEventsPageType.past,
                                                        ),
                                                      ),
                                                    ).then((void dummy) {
                                                      _refreshFromTable(true).then((void dummy) {
                                                        setState(() {});
                                                      });
                                                    });
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(top: 15, bottom: 15),
                                          child: Container(
                                            width: 110,
                                            height: 110,
                                            child: Connection.styleForConnected(
                                              G0<AppModel>().connectionStatus,
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  padding: const EdgeInsets.only(top: 8.0, bottom: 0.0),
                                                ),
                                                child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                                                  const Padding(
                                                    padding: EdgeInsets.only(left: 0),
                                                    child: Icon(MaterialCommunityIcons.run_fast, color: Colors.white, size: 60),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 10, right: 10, top: 5),
                                                    child: Text(
                                                      'Upcoming\r\nevents',
                                                      textAlign: TextAlign.center,
                                                      style: buttonLabelStyleSmall,
                                                    ),
                                                  ),
                                                ]),
                                                onPressed: () {
                                                  if (Connection.checkForConnection(context, G0<AppModel>().connectionStatus)) {
                                                    Navigator.push<dynamic>(
                                                      context,
                                                      MaterialPageRoute<dynamic>(
                                                        builder: (BuildContext context) => AddEditEventsPage(
                                                          kennel: widget.kennelAggregateItem,
                                                          pageType: FilterEventsPageType.future,
                                                        ),
                                                      ),
                                                    ).then((void dummy) {
                                                      _refreshFromTable(true).then((void dummy) {
                                                        setState(() {});
                                                      });
                                                    });
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: <Widget>[
                                        Padding(
                                          padding: const EdgeInsets.only(top: 15, bottom: 15),
                                          child: Container(
                                            width: 110,
                                            height: 110,
                                            child: Connection.styleForConnected(
                                              G0<AppModel>().connectionStatus,
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  padding: const EdgeInsets.only(top: 8.0, bottom: 0.0),
                                                ),
                                                child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                                                  const Padding(
                                                    padding: EdgeInsets.only(left: 0, top: 4),
                                                    child: Icon(MaterialCommunityIcons.qrcode, color: Colors.white, size: 55),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 10, right: 10, top: 7),
                                                    child: Text(
                                                      'Print QR codes',
                                                      textAlign: TextAlign.center,
                                                      style: buttonLabelStyleSmall,
                                                    ),
                                                  ),
                                                ]),
                                                onPressed: () {
                                                  Navigator.push<dynamic>(
                                                      context,
                                                      MaterialPageRoute<dynamic>(
                                                          builder: (BuildContext context) => EventQrCodePage(
                                                              kennelShortName: widget.kennelAggregateItem.kennel.kennelShortName,
                                                              qrContent: widget.kennelAggregateItem.kennel.kennelId,
                                                              runEndPrefix: QR_PREFIX_KENNEL_GENERIC_RUN_END,
                                                              runStartPrefix: QR_PREFIX_KENNEL_GENERIC_RUN_START,
                                                              title: 'Any ' + widget.kennelAggregateItem.kennel.kennelShortName + ' run')));
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(top: 15, bottom: 15),
                                          child: Container(
                                            width: 110,
                                            height: 110,
                                            child: Connection.styleForConnected(
                                              G0<AppModel>().connectionStatus,
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  padding: const EdgeInsets.only(top: 8.0, bottom: 0.0),
                                                ),
                                                child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                                                  const Padding(
                                                    padding: EdgeInsets.only(left: 0, top: 4),
                                                    child: Icon(MaterialIcons.location_on, color: Colors.white, size: 55),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 10, right: 10, top: 7),
                                                    child: Text(
                                                      'View run locations',
                                                      textAlign: TextAlign.center,
                                                      style: buttonLabelStyleSmall,
                                                    ),
                                                  ),
                                                ]),
                                                onPressed: () {
                                                  Navigator.push<dynamic>(
                                                    context,
                                                    MaterialPageRoute<dynamic>(
                                                      builder: (BuildContext context) => RunLocationsPage(kennel: widget.kennelAggregateItem.kennel),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 50.0, bottom: 25.0),
                                      child: FancyDivider(key: UniqueKey(), innerColor: Colors.white),
                                    ),
                                  ],
                                ),
                          (widget.kennelAggregateItem.kennel.kennelDescription ?? '').isNotEmpty
                              ? Column(
                                  children: <Widget>[
                                    Linkify(
                                      text: widget.kennelAggregateItem.kennel.kennelDescription.toString().replaceAll('\r\n', '\n'),
                                      style: bodyStyle,
                                      linkStyle: bodyStyleYellow,
                                      onOpen: (LinkableElement link) async {
                                        if (await canLaunch(link.url)) {
                                          await launch(link.url);
                                        } else {
                                          IveCoreUtilities.showAlert(context, 'Unable to open link', 'Harrier Central was unable to open ${link.url}', 'OK');
                                        }
                                      },
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 50.0, bottom: 25.0),
                                      child: FancyDivider(key: UniqueKey(), innerColor: Colors.white),
                                    ),
                                  ],
                                )
                              : Container(),
                          Column(
                            children: <Widget>[
                              Container(
                                width: MediaQuery.of(context).size.width,
                                height: 300,
                                //padding: const EdgeInsets.all(20.0),
                                child: Center(
                                  // Map
                                  child: FlutterMap(
                                    mapController: mapController,
                                    options: MapOptions(
                                      //interactive: false,
                                      center: latlng.LatLng(widget.kennelAggregateItem.extensions.cityLat + .0, widget.kennelAggregateItem.extensions.cityLon + .0),
                                      zoom: sliderValue,
                                      minZoom: 1.0,
                                      maxZoom: 18.0,
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
                                            width: 240.0,
                                            height: 240.0,
                                            point: latlng.LatLng(widget.kennelAggregateItem.extensions.cityLat + .0, widget.kennelAggregateItem.extensions.cityLon + .0),
                                            builder: (BuildContext ctx) => GestureDetector(
                                              onTap: () => _launchMaps(widget.kennelAggregateItem.extensions.cityLat, widget.kennelAggregateItem.extensions.cityLat),
                                              child: Container(
                                                margin: const EdgeInsets.only(bottom: 110.0),
                                                child: Stack(alignment: AlignmentDirectional.topCenter, children: <Widget>[
                                                  Image.asset('images/icons/grey_square_pin.png'),
                                                  Positioned(
                                                    top: 14,
                                                    child: KennelLogo(
                                                      kennelLogoUrl: widget.kennelAggregateItem.kennel.kennelLogo,
                                                      kennelShortName: widget.kennelAggregateItem.kennel.kennelShortName,
                                                      logoHeight: 60.0,
                                                      leftPadding: 0.0,
                                                    ),
                                                  ),
                                                ]
                                                    //child: FlutterLogo(colors: Colors.purple),
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: Slider(
                                    value: sliderValue,
                                    activeColor: Colors.yellow,
                                    inactiveColor: Colors.grey,
                                    min: 1.0,
                                    max: 20.0,
                                    onChanged: (num val) {
                                      // setState(() {
                                      if (mapController != null) {
                                        mapController.move(
                                            latlng.LatLng(widget.kennelAggregateItem.extensions.cityLat + .0, widget.kennelAggregateItem.extensions.cityLon + .0), val);
                                      }
                                      setState(() {
                                        sliderValue = val;
                                      });

                                      //});
                                    }),
                              ),
                              Row(
                                children: <Widget>[
                                  const SizedBox(height: 25.0),
                                  Expanded(
                                    child: Text(
                                      'Location:',
                                      style: listLabelStyle,
                                      textAlign: TextAlign.right,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    flex: flexLeft,
                                  ),
                                  Expanded(
                                      child: Text(
                                        '  ' + widget.kennelAggregateItem.extensions.location ?? '',
                                        style: listValueStyle,
                                        textAlign: TextAlign.left,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      flex: flexRight),
                                ],
                              ),
                              Row(
                                children: <Widget>[
                                  const SizedBox(height: 25.0),
                                  Expanded(
                                    child: Text(
                                      'Last run:',
                                      style: listLabelStyle,
                                      textAlign: TextAlign.right,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    flex: flexLeft,
                                  ),
                                  Expanded(
                                      child: Text(
                                        widget.kennelAggregateItem.extensions.lastRunDate != null
                                            ? '  ' + DateFormat('E, MMM d,  h:mm a').format(DateTime.parse(widget.kennelAggregateItem.extensions.lastRunDate.substring(0, 19)))
                                            : '  <no run found>',
                                        style: listValueStyle,
                                        textAlign: TextAlign.left,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      flex: flexRight),
                                ],
                              ),
                              Row(
                                children: <Widget>[
                                  const SizedBox(height: 25.0),
                                  Expanded(
                                    child: Text(
                                      'Next run:',
                                      style: listLabelStyle,
                                      textAlign: TextAlign.right,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    flex: flexLeft,
                                  ),
                                  Expanded(
                                      child: Text(
                                        widget.kennelAggregateItem.extensions.nextRunDate != null
                                            ? '  ' + DateFormat('E, MMM d,  h:mm a').format(DateTime.parse(widget.kennelAggregateItem.extensions.nextRunDate.substring(0, 19)))
                                            : '  <no run found>',
                                        style: listValueStyle,
                                        textAlign: TextAlign.left,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      flex: flexRight),
                                ],
                              ),
                              Row(
                                children: <Widget>[
                                  const SizedBox(height: 25.0),
                                  Expanded(
                                    child: Text(
                                      'Hash cash:',
                                      style: listLabelStyle,
                                      textAlign: TextAlign.right,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    flex: flexLeft,
                                  ),
                                  Expanded(
                                      child: Text(
                                        widget.kennelAggregateItem.kennel.defaultPriceForMembers == null
                                            ? '  <not provided>'
                                            : '  ${IveCoreUtilities.getFormattedMoney(widget.kennelAggregateItem.kennel.defaultPriceForMembers, widget.kennelAggregateItem.extensions.digitsAfterDecimal, widget.kennelAggregateItem.extensions.currencySymbol)}    (members)',
                                        style: listValueStyle,
                                        textAlign: TextAlign.left,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      flex: flexRight),
                                ],
                              ),
                              Row(
                                children: <Widget>[
                                  const SizedBox(height: 25.0),
                                  Expanded(
                                    child: Text(
                                      '',
                                      style: listLabelStyle,
                                      textAlign: TextAlign.right,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    flex: flexLeft,
                                  ),
                                  Expanded(
                                      child: Text(
                                        widget.kennelAggregateItem.kennel.defaultPriceForNonMembers == null
                                            ? '  <not provided>'
                                            : '  ${IveCoreUtilities.getFormattedMoney(widget.kennelAggregateItem.kennel.defaultPriceForNonMembers, widget.kennelAggregateItem.extensions.digitsAfterDecimal, widget.kennelAggregateItem.extensions.currencySymbol)}    (non-members)',
                                        style: listValueStyle,
                                        textAlign: TextAlign.left,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      flex: flexRight),
                                ],
                              ),
                              ((widget.kennelAggregateItem.kennel.kennelMismanagementTeam == null) ||
                                      (widget.kennelAggregateItem.kennel.kennelMismanagementTeam.trim().isEmpty) ||
                                      (widget.kennelAggregateItem.kennel.kennelMismanagementTeam.toLowerCase().contains('none listed')))
                                  ? Container()
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: <Widget>[
                                        FancyDivider(key: UniqueKey(), innerColor: Colors.white, topMargin: 30.0, bottomMargin: 10.0),
                                        for (String item in mismanagement) mmRow(item)
                                      ],
                                    ),
                              ((allRuns == null) || (allRuns.isEmpty))
                                  ? Container()
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: <Widget>[
                                        FancyDivider(key: UniqueKey(), innerColor: Colors.white, topMargin: 30.0, bottomMargin: 10.0),
                                        Center(
                                          child: Padding(
                                            padding: const EdgeInsets.only(bottom: 15.0),
                                            child: Text(
                                              allRuns.length == 1 ? 'Next run' : 'Next ${allRuns.length} runs',
                                              style: headingStyle,
                                              textAlign: TextAlign.right,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        for (RunDetailsAggregate item in allRuns) runRow(item),
                                        const SizedBox(height: 15.0)
                                      ],
                                    ),
                              ((widget.kennelAggregateItem.kennel.kennelWebsiteUrl == null) || (widget.kennelAggregateItem.kennel.kennelWebsiteUrl.trim().isEmpty))
                                  ? Container()
                                  : Column(
                                      children: <Widget>[
                                        FancyDivider(
                                          key: UniqueKey(),
                                          innerColor: Colors.white,
                                          topMargin: 30.0,
                                          bottomMargin: 15.0,
                                        ),
                                        Container(
                                          margin: const EdgeInsets.only(bottom: 20),
                                          width: 180,
                                          child: Connection.styleForConnected(
                                            G0<AppModel>().connectionStatus,
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                padding: const EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8.0),
                                              ),
                                              child: Row(children: <Widget>[
                                                Stack(alignment: AlignmentDirectional.center, children: <Widget>[
                                                  Container(height: 30, width: 30, decoration: BoxDecoration(color: Colors.blue[800], shape: BoxShape.circle)),
                                                  const Positioned(bottom: 1.4, child: Icon(SimpleLineIcons.globe, color: Colors.white))
                                                ]),
                                                const Padding(
                                                  padding: EdgeInsets.only(left: 20, right: 0),
                                                  child: Text('Open website'),
                                                ),
                                              ]),
                                              onPressed: () {
                                                if (Connection.checkForConnection(context, G0<AppModel>().connectionStatus)) {
                                                  launch(widget.kennelAggregateItem.kennel.kennelWebsiteUrl);
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            ],
                          ),
                          const SizedBox(height: 25.0),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
      OfflineModeRibbon(
        showRibbon: G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected,
        lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSyncAsDate),
        ribbonImage: 'images/icons/offline_mode.png',
      ),
    ]);
  }

  Widget mmRow(String s) {
    if ((s == null) || (s.isEmpty)) {
      return Container();
    } else {
      final List<String> items = s.split('\t');
      return ((items == null) || (items.length < 2))
          ? Container()
          : Row(
              children: <Widget>[
                const SizedBox(height: 25.0),
                Expanded(
                  child: Text(
                    items[0] + ':',
                    style: listLabelStyle,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  flex: 4,
                ),
                Expanded(
                    child: Text(
                      ' ' + items[1],
                      style: listValueStyle,
                      textAlign: TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    flex: 6),
              ],
            );
    }
  }

  Widget runRow(RunDetailsAggregate s) {
    return RunListItem(
      futureRun: s,
      onItemTapped: () {
        Navigator.push<dynamic>(
          context,
          MaterialPageRoute<dynamic>(
            builder: (BuildContext context) => RunDetailsPage(futureRun: s),
          ),
        ).then((void dummy) {
          // _refreshFromBackend(clearLocalTables: false).then((void dummy) {
          //   setState(() {});
          // });
        });
      },
    );

    // Padding(
    //   padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
    //   child: Column(
    //     mainAxisAlignment: MainAxisAlignment.center,
    //     crossAxisAlignment: CrossAxisAlignment.center,
    //     mainAxisSize: MainAxisSize.max,
    //     children: <Widget>[
    //       Text(
    //         s.event.eventName.trim(),
    //         style: listValueStyle,
    //         textAlign: TextAlign.center,
    //         maxLines: 3,
    //         overflow: TextOverflow.ellipsis,
    //       ),
    //       //flex: 4,

    //       // Expanded(
    //       //     child: Text(
    //       //       ' ' + items[1],
    //       //       style: listValueStyle,
    //       //       textAlign: TextAlign.left,
    //       //       maxLines: 1,
    //       //       overflow: TextOverflow.ellipsis,
    //       //     ),
    //       //     flex: 6),
    //     ],
    //   ),
    // );
  }

  Future<void> _launchMaps(num lat, num lon) async {
    final String googleWebUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
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
}
