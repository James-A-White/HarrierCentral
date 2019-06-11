import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:latlong/latlong.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/data/hc3_services/sync_kennel_admin_service.dart';
import 'package:harrier_central/widgets/kennel_logo.dart';
import 'package:harrier_central/pages/run_admin/event_qr_code_page.dart';
import 'package:harrier_central/data/services/email_reports_service.dart';
import 'package:harrier_central/pages/kennel_admin/filter_events_page.dart';
import 'package:harrier_central/pages/kennel_admin/kennel_members.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/widgets/offline_mode_ribbon.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/widgets/fancy_divider.dart';

class KennelAdminMainPage extends StatefulWidget {
  const KennelAdminMainPage({@required this.kennel});
  final Map<String, dynamic> kennel;

  @override
  KennelAdminMainPageState createState() => KennelAdminMainPageState();
}

class KennelAdminMainPageState extends State<KennelAdminMainPage> {
  num sliderValue;

  @override
  void initState() {
    DBProvider.db.database.then((Database db) async {
      final SyncKennelAdminService cSrv = SyncKennelAdminService();
      cSrv.updateFromBackend(db, SyncKennelAdminService.flagsAllData, false, widget.kennel['kennelId']).then((bool result) {
        //refreshFromTables();
        setState(() {
          final String resultStr = result ? 'successfully' : 'unsuccessfully';
          print('Event admin data synchronized $resultStr');
          //_isLoading = false;
        });
      });
    });

    sliderValue = 5.0;
    isAdmin = (widget.kennel['mismanagementRoleFlags'] & mmAuthAccessKennelAdmin) != 0;
    super.initState();
  }

  MapController mapController = MapController();

  int flexLeft = 3;
  int flexRight = 7;

  bool isAdmin = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  KennelMembersList kennelMembersList;

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
              '${widget.kennel['kennelShortName']}',
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          body: Container(
            height: MediaQuery.of(context).size.height,
            decoration: Backgrounds.defaultHcBackground(),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 30.0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    ((widget.kennel['kennelCoverPhoto'] ?? '').isNotEmpty && widget.kennel['kennelCoverPhoto'].startsWith('http'))
                        ? Column(mainAxisSize: MainAxisSize.max, children: <Widget>[
                            Row(mainAxisAlignment: MainAxisAlignment.start, mainAxisSize: MainAxisSize.max, children: <Widget>[
                              KennelLogo(
                                kennelLogoUrl: widget.kennel['kennelLogo'],
                                kennelShortName: widget.kennel['kennelShortName'],
                                logoHeight: 80.0,
                                leftPadding: 0.0,
                              ),
                              Container(width: MediaQuery.of(context).size.width - 120, padding: const EdgeInsets.only(left: 15.0), child: Text(widget.kennel['kennelName'], maxLines: 3, style: smallTitleStyle))
                              //Container(width: MediaQuery.of(context).size.width - 120, padding: const EdgeInsets.only(left: 15.0), child: Text('Test of a long hash name that will span several lines and then keep going until we get an elipsis', maxLines: 3, overflow:TextOverflow.ellipsis, style: smallTitleStyle))
                            ]),
                            const Padding(
                              padding: EdgeInsets.only(top: 45.0, bottom: 15.0),
                              child: FancyDivider(innerColor: Colors.white),
                            ),
                            Padding(
                                padding: const EdgeInsets.only(top: 20, bottom: 5),
                                child: CachedNetworkImage(
                                  imageUrl: widget.kennel['kennelCoverPhoto'],
                                  // errorWidget:
                                  //     (BuildContext context, String url, Exception error) =>
                                  //         const  Icon(Icons.error),
                                )
                                //decoration: BoxDecoration(color: Theme.of(context).selectedRowColor),
                                ),
                          ])
                        : Column(
                            children: <Widget>[
                              Container(margin: const EdgeInsets.only(bottom: 20.0), width: MediaQuery.of(context).size.width - 40, child: Text(widget.kennel['kennelName'], textAlign: TextAlign.center, maxLines: 3, style: titleStyle)),
                              //Container(width: MediaQuery.of(context).size.width - 40, child: Text('this is a test of what a long kennel name might look like', textAlign: TextAlign.center, maxLines: 3, style: titleStyle)),
                              KennelLogo(
                                kennelLogoUrl: widget.kennel['kennelLogo'],
                                kennelShortName: widget.kennel['kennelShortName'],
                                logoHeight: 200.0,
                                leftPadding: 0.0,
                              ),
                            ],
                          ),
                    const Padding(
                      padding: EdgeInsets.only(top: 50.0, bottom: 25.0),
                      child: FancyDivider(innerColor: Colors.white),
                    ),
                    (widget.kennel['kennelDescription'] ?? '').isNotEmpty
                        ? Column(
                            children: <Widget>[
                              Linkify(
                                text: widget.kennel['kennelDescription'].toString().replaceAll('\r\n', '\n'),
                                style: bodyStyle,
                                linkStyle: bodyStyleYellow,
                                humanize: true,
                                onOpen: (LinkableElement link) async {
                                  if (await canLaunch(link.url)) {
                                    await launch(link.url);
                                  } else {
                                    Utilities.showAlert(context, 'Unable to open link', 'Harrier Central was unable to open ${link.url}', 'OK');
                                  }
                                },
                              ),
                              const Padding(
                                padding: EdgeInsets.only(top: 50.0, bottom: 25.0),
                                child: FancyDivider(innerColor: Colors.white),
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
                                interactive: false,
                                center: LatLng(widget.kennel['kennelLatitude'], widget.kennel['kennelLongitude']),
                                zoom: sliderValue,
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
                                      point: LatLng(widget.kennel['kennelLatitude'], widget.kennel['kennelLongitude']),
                                      builder: (BuildContext ctx) => GestureDetector(
                                            onTap: () => _launchMaps(widget.kennel['kennelLatitude'], widget.kennel['kennelLongitude']),
                                            child: Container(
                                              margin: const EdgeInsets.only(bottom: 110.0),
                                              child: Stack(alignment: AlignmentDirectional.topCenter, children: <Widget>[
                                                Image.asset('images/icons/grey_square_pin.png'),
                                                Positioned(
                                                  top: 14,
                                                  child: KennelLogo(
                                                    kennelLogoUrl: widget.kennel['kennelLogo'],
                                                    kennelShortName: widget.kennel['kennelShortName'],
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
                              onChanged: (double val) {
                                // setState(() {
                                if (mapController != null) {
                                  mapController.move(LatLng(widget.kennel['kennelLatitude'], widget.kennel['kennelLongitude']), val);
                                }
                                setState(() {
                                  sliderValue = val;
                                });

                                //});
                              }),
                        ),
                        Row(
                          children: <Widget>[
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
                                  '  ' + widget.kennel['location'] ?? '',
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
                                  widget.kennel['lastRunDate'] != null ? '  ' + DateFormat('E, MMM d,  h:mm a').format(DateTime.parse(widget.kennel['lastRunDate'].substring(0, 19))) : '  <no run found>',
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
                                  widget.kennel['nextRunDate'] != null ? '  ' + DateFormat('E, MMM d,  h:mm a').format(DateTime.parse(widget.kennel['nextRunDate'].substring(0, 19))) : '  <no run found>',
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
                                  widget.kennel['defaultPriceForMembers'] == null ? '  <not provided>' : '  ${Utilities.getFormattedMoney(widget.kennel['defaultPriceForMembers'], widget.kennel['digitsAfterDecimal'], widget.kennel['currencySymbol'])}    (members)',
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
                                  widget.kennel['defaultPriceForNonMembers'] == null ? '  <not provided>' : '  ${Utilities.getFormattedMoney(widget.kennel['defaultPriceForNonMembers'], widget.kennel['digitsAfterDecimal'], widget.kennel['currencySymbol'])}    (non-members)',
                                  style: listValueStyle,
                                  textAlign: TextAlign.left,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                flex: flexRight),
                          ],
                        ),
                        ((widget.kennel['kennelWebsiteUrl'] == null) || (widget.kennel['kennelWebsiteUrl'].trim().isEmpty))
                            ? Container()
                            : Container(
                                padding: const EdgeInsets.only(top: 30),
                                width: 180,
                                child: Utilities.styleForConnected(
                                  RaisedButton(
                                    padding: const EdgeInsets.only(top: 8.0, left: 8.0, bottom: 8.0),
                                    child: Row(children: <Widget>[
                                      Stack(
                                          alignment: AlignmentDirectional.center, children: <Widget>[Container(height: 30, width: 30, decoration: BoxDecoration(color: Colors.blue[800], shape: BoxShape.circle)), const Positioned(bottom: 1.4, child: Icon(SimpleLineIcons.globe, color: Colors.white))]),
                                      const Padding(
                                        padding: EdgeInsets.only(left: 20, right: 0),
                                        child: Text('Open website'),
                                      ),
                                    ]),
                                    textColor: Colors.white,
                                    onPressed: () {
                                      if (Utilities.checkForConnection(context)) {
                                        launch(widget.kennel['kennelWebsiteUrl']);
                                      }
                                    },
                                  ),
                                ),
                              ),
                      ],
                    ),
                    !isAdmin
                        ? Container()
                        : Column(
                            children: <Widget>[
                              const Padding(
                                padding: EdgeInsets.only(top: 50.0, bottom: 25.0),
                                child: FancyDivider(innerColor: Colors.white),
                              ),
                              Text(
                                'Kennel Admin Functions',
                                style: headingStyle,
                                textAlign: TextAlign.center,
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 20, bottom: 15),
                                width: 220,
                                height: 50,
                                child: Utilities.styleForConnected(
                                  RaisedButton(
                                    padding: const EdgeInsets.only(top: 8.0, left: 8.0, bottom: 8.0),
                                    child: Row(children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.only(left: 10.0),
                                        child: Image.asset('images/icons/excel.png', height: 30.0, width: 30.0),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.only(left: 20, right: 0),
                                        child: Text('Email run stats'),
                                      ),
                                    ]),
                                    textColor: Colors.white,
                                    onPressed: () {
                                      if (Utilities.checkForConnection(context)) {
                                        final EmailReportsService svc = EmailReportsService();
                                        svc.sendKennelRunStatsReportByEmail(kennelId: widget.kennel['kennelId'], kennelName: widget.kennel['kennelName'], digitsAfterDecimal: widget.kennel['digitsAfterDecimal'], currencySymbol: widget.kennel['currencySymbol']).then((Map<String, String> result) {
                                          _scaffoldKey.currentState?.hideCurrentSnackBar();

                                          if (result['result'].toLowerCase().startsWith('success')) {
                                            Utilities.showAlert(context, 'E-mail successfully sent', 'Your Kennel run stats report has been successfully e-mailed to:\r\n\r\n${result['email']}\r\n\r\nIf you do not see it in the next few minutes, check your spam folder.', 'OK');
                                          }
                                        });

                                        Utilities.showInSnackBar(context, _scaffoldKey, 'Run stats being processed...', durationInSeconds: 10);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 15, bottom: 15),
                                child: Container(
                                  width: 220,
                                  height: 50,
                                  child: Utilities.styleForConnected(
                                    RaisedButton(
                                      padding: const EdgeInsets.only(top: 2.0, left: 8.0, bottom: 8.0),
                                      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: const <Widget>[
                                        Padding(
                                          padding: EdgeInsets.only(left: 10),
                                          child: Icon(Ionicons.md_people, color: Colors.white),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(left: 20, top: 8),
                                          child: Text('Manage Members'),
                                        ),
                                      ]),
                                      textColor: Colors.white,
                                      onPressed: () {
                                        if (Utilities.checkForConnection(context)) {
                                          kennelMembersList = KennelMembersList(kennel: widget.kennel);
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
                              Padding(
                                padding: const EdgeInsets.only(top: 15, bottom: 15),
                                child: Container(
                                  width: 220,
                                  height: 50,
                                  child: Utilities.styleForConnected(
                                    RaisedButton(
                                      padding: const EdgeInsets.only(top: 2.0, left: 8.0, bottom: 8.0),
                                      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: const <Widget>[
                                        Padding(
                                          padding: EdgeInsets.only(left: 10),
                                          child: Icon(MaterialCommunityIcons.filter_variant, color: Colors.white),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(left: 20, top: 8),
                                          child: Text('Edit events'),
                                        ),
                                      ]),
                                      textColor: Colors.white,
                                      onPressed: () {
                                        if (Utilities.checkForConnection(context)) {
                                          Navigator.push<dynamic>(
                                            context,
                                            MaterialPageRoute<dynamic>(
                                              builder: (BuildContext context) => FilterEventsPage(kennel: widget.kennel),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 15, bottom: 15),
                                child: Container(
                                  width: 220,
                                  height: 50,
                                  child: Utilities.styleForConnected(
                                    RaisedButton(
                                      padding: const EdgeInsets.only(top: 2.0, left: 8.0, bottom: 8.0),
                                      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: const <Widget>[
                                        Padding(
                                          padding: EdgeInsets.only(left: 10),
                                          child: Icon(MaterialCommunityIcons.qrcode, color: Colors.white),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(left: 20, top: 8),
                                          child: Text('Print QR codes'),
                                        ),
                                      ]),
                                      textColor: Colors.white,
                                      onPressed: () {
                                        Navigator.push<dynamic>(
                                            context,
                                            MaterialPageRoute<dynamic>(
                                                builder: (BuildContext context) => EventQrCodePage(
                                                    kennelShortName: widget.kennel['kennelShortName'], qrContent: widget.kennel['kennelId'], runEndPrefix: QR_PREFIX_KENNEL_GENERIC_RUN_END, runStartPrefix: QR_PREFIX_KENNEL_GENERIC_RUN_START, title: 'Any ' + widget.kennel['kennelShortName'] + ' run')));
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      const OfflineModeRibbon(),
    ]);
  }

  Future<void> _launchMaps(double lat, double lon) async {
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
