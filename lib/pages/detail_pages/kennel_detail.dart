import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:latlong/latlong.dart';

import 'package:harrier_central/widgets/kennel_logo.dart';
import 'package:harrier_central/pages/kennel_admin/kennel_members.dart';
import 'package:harrier_central/pages/kennel_admin/filter_events_page.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/widgets/fancy_divider.dart';
import 'package:url_launcher/url_launcher.dart';

class KennelDetailPage extends StatelessWidget {
  const KennelDetailPage({@required this.kennel});
  final Map<String, dynamic> kennel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        title: Text(
          '${kennel['kennelShortName']}',
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
                ((kennel['kennelCoverPhoto'] ?? '').isNotEmpty && kennel['kennelCoverPhoto'].startsWith('http'))
                    ? Column(mainAxisSize: MainAxisSize.max, children: <Widget>[
                        Row(mainAxisAlignment: MainAxisAlignment.start, mainAxisSize: MainAxisSize.max, children: <Widget>[
                          KennelLogo(
                            kennelLogoUrl: kennel['kennelLogo'],
                            kennelShortName: kennel['kennelShortName'],
                            logoHeight: 80.0,
                            leftPadding: 0.0,
                          ),
                          Container(width: MediaQuery.of(context).size.width - 120, padding: EdgeInsets.only(left: 15.0), child: Text(kennel['kennelName'], maxLines: 3, style: smallTitleStyle))
                          //Container(width: MediaQuery.of(context).size.width - 120, padding: const EdgeInsets.only(left: 15.0), child: Text('Test of a long hash name that will span several lines and then keep going until we get an elipsis', maxLines: 3, overflow:TextOverflow.ellipsis, style: smallTitleStyle))
                        ]),
                        const Padding(
                          padding: EdgeInsets.only(top: 45.0, bottom: 15.0),
                          child: FancyDivider(innerColor: Colors.white),
                        ),
                        Padding(
                            padding: const EdgeInsets.only(top: 20, bottom: 5),
                            child: CachedNetworkImage(
                              imageUrl: kennel['kennelCoverPhoto'],
                              // errorWidget:
                              //     (BuildContext context, String url, Exception error) =>
                              //         const  Icon(Icons.error),
                            )
                            //decoration: BoxDecoration(color: Theme.of(context).selectedRowColor),
                            ),
                      ])
                    : KennelLogo(
                        kennelLogoUrl: kennel['kennelLogo'],
                        kennelShortName: kennel['kennelShortName'],
                        logoHeight: 200.0,
                        leftPadding: 0.0,
                      ),
                const Padding(
                  padding: EdgeInsets.only(top: 50.0, bottom: 25.0),
                  child: FancyDivider(innerColor: Colors.white),
                ),
                (kennel['kennelDescription'] ?? '').isNotEmpty
                    ? Column(
                        children: <Widget>[
                          Text(kennel['kennelDescription'].trim(), style: bodyStyle),
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
                          options: MapOptions(
                            center: LatLng(kennel['latitude'], kennel['longitude']),
                            zoom: 4.0,
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
                                  point: LatLng(kennel['latitude'], kennel['longitude']),
                                  builder: (BuildContext ctx) => GestureDetector(
                                        onTap: () => _launchMaps(kennel['latitude'], kennel['longitude']),
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 110.0),
                                          child: Stack(alignment: AlignmentDirectional.topCenter, children: <Widget>[
                                            Image.asset('images/icons/grey_square_pin.png'),
                                            Positioned(
                                              top: 14,
                                              child: KennelLogo(
                                                kennelLogoUrl: kennel['kennelLogo'],
                                                kennelShortName: kennel['kennelShortName'],
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
                                    const Padding(
                  padding: EdgeInsets.only(top: 50.0, bottom: 25.0),
                  child: FancyDivider(innerColor: Colors.white),
                ),
                  ],
                ),
                Container(
                  width: 150.0,
                  child: RaisedButton(
                    child: const Text(
                      'Members',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () {
                      // Navigator.push<dynamic>(
                      //   context,
                      //   MaterialPageRoute<dynamic>(
                      //     builder: (BuildContext context) => KennelMembersList(
                      //           kennel: kennel
                      //         ),
                      //   ),
                      // );
                    },
                  ),
                ),
                Container(
                  width: 150.0,
                  child: RaisedButton(
                    child: const Text(
                      'Filter Events',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () {
                      // Navigator.push<dynamic>(
                      //   context,
                      //   MaterialPageRoute<dynamic>(
                      //     builder: (BuildContext context) => FilterEventsPage(
                      //           kennel: kennel
                      //         ),
                      //   ),
                      // );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
