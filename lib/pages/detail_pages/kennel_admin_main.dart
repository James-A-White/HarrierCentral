//import 'dart:ui' as ui;
import 'package:geolocator/geolocator.dart';
import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:map_launcher/map_launcher.dart' as maps;

class KennelAdminMainPage extends StatefulWidget {
  const KennelAdminMainPage({super.key, required this.kennelAggregateItem});
  final KennelListAggregate kennelAggregateItem;

  @override
  KennelAdminMainPageState createState() => KennelAdminMainPageState();
}

class KennelAdminMainPageState extends State<KennelAdminMainPage> {
  double _sliderValue = 5.0;
  bool _isLoading = true;

  @override
  void dispose() {
    _saveUserMapPreference.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _saveUserMapPreference.addListener(() {
      setState(() {});
    });

    if ((widget.kennelAggregateItem.kennel.kennelMismanagementTeam == null) ||
        (widget.kennelAggregateItem.kennel.kennelMismanagementTeam!
            .trim()
            .isEmpty)) {
      _mismanagement = null;
    } else {
      _mismanagement =
          widget.kennelAggregateItem.kennel.kennelMismanagementTeam!.contains(
                '\r',
              )
              ? widget.kennelAggregateItem.kennel.kennelMismanagementTeam!
                  .split('\r')
              : widget.kennelAggregateItem.kennel.kennelMismanagementTeam!
                  .split('\n');
    }

    G0<TableModel>().syncKennelAdminService
        .updateFromBackend(
          SyncKennelAdminService.flagsAllData,
          false,
          widget.kennelAggregateItem.kennel.kennelId,
        )
        .then((bool result) {
          _refreshFromTable(true).then((void _) {
            setState(() {
              //final String resultStr = result ? 'successfully' : 'unsuccessfully';
              //print('Event admin data synchronized $resultStr');
              _isLoading = false;
            });
          });
        });

    super.initState();
  }

  final MapController _mapController = MapController();

  final int _flexLeft = 3;
  final int _flexRight = 7;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  KennelMembersList? _kennelMembersList;

  final ValueNotifier<bool> _saveUserMapPreference = ValueNotifier<bool>(false);

  List<String>? _mismanagement;

  List<RunDetailsAggregate> _allRuns = <RunDetailsAggregate>[];

  Future<void> _refreshFromTable(bool forceRefresh) async {
    if (forceRefresh || (_allRuns.isEmpty)) {
      //final Geolocator locator = Geolocator();

      final List<Map<String, dynamic>> results = await QueryRuns.queryRuns(
        EnumRunQueryType.kennelDetailPage,
        EnumRunQueryContext.kennelAdmin,
        kennelId: widget.kennelAggregateItem.kennel.kennelId,
      );

      _allRuns = <RunDetailsAggregate>[];
      for (int i = 0; i < results.length; i++) {
        double? dist;
        if ((results[i]['evtLat'] != null) &&
            (results[i]['evtLon'] != null) &&
            G0<DeviceInfo>().deviceLat != null &&
            G0<DeviceInfo>().deviceLon != null) {
          dist = Geolocator.distanceBetween(
            G0<DeviceInfo>().deviceLat!,
            G0<DeviceInfo>().deviceLon!,
            results[i]['evtLat'],
            results[i]['evtLon'],
          );
        }
        final EventModel eventItem = G0<TableModel>().eventsTableHelper.fromMap(
          results[i],
        );
        final KennelsModel kennelItem = G0<TableModel>().kennelsTableHelper
            .fromMap(results[i]);
        final RunQueryExtensionsModel extensionsItem =
            RunQueryExtensionsModel.fromJsonWithDateSearchText(
              results[i],
              eventItem.eventStartDatetime,
              dist,
            );

        String paymentLinkUrl = '';

        if (((eventItem.eventPaymentUrl ?? '') != '') &&
            ((eventItem.eventPaymentUrlExpires == null) ||
                (eventItem.eventPaymentUrlExpires!.isAfter(DateTime.now())))) {
          paymentLinkUrl = eventItem.eventPaymentUrl!;
        } else if (((kennelItem.kennelPaymentUrl ?? '') != '') &&
            ((kennelItem.kennelPaymentUrlExpires == null) ||
                (kennelItem.kennelPaymentUrlExpires!.isAfter(
                  DateTime.now(),
                )))) {
          paymentLinkUrl = kennelItem.kennelPaymentUrl!;
        }

        // final num julianNow = results[i]['nowJulian'];
        // final num eventJulian = results[i]['eventJulian'];

        //print('Julian now = $julianNow, Event julian = $eventJulian, EventName = ${eventItem.eventName}');

        final RunDetailsAggregate item = RunDetailsAggregate(
          event: eventItem,
          kennel: kennelItem,
          extensions: extensionsItem,
          paymentUrl: paymentLinkUrl,
        );
        _allRuns.add(item);
      }
    }
  }

  static const double _buttonHeight = 53.0;
  static const double _buttonWidth = 270.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
        ),
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
              iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
              title: Text(
                widget.kennelAggregateItem.kennel.kennelShortName,
                style: ts_appBarTitle,
              ),
            ),
            body:
                _isLoading
                    ? const Center(
                      child: HcCircularProgressIndicator(key: Key('16637721')),
                    )
                    : Container(
                      height: MediaQuery.of(context).size.height,
                      decoration: Backgrounds.defaultHcBackground(),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 20,
                            right: 20,
                            top: 30.0,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              ((widget
                                                  .kennelAggregateItem
                                                  .kennel
                                                  .kennelCoverPhoto ??
                                              '')
                                          .isNotEmpty &&
                                      widget
                                          .kennelAggregateItem
                                          .kennel
                                          .kennelCoverPhoto!
                                          .startsWith('http'))
                                  ? Column(
                                    mainAxisSize: MainAxisSize.max,
                                    children: <Widget>[
                                      Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 20.0,
                                        ),
                                        width:
                                            MediaQuery.of(context).size.width -
                                            40,
                                        child: Text(
                                          widget
                                              .kennelAggregateItem
                                              .kennel
                                              .kennelName,
                                          textAlign: TextAlign.center,
                                          maxLines: 3,
                                          style: ts_titleLarge,
                                        ),
                                      ),
                                      KennelLogo(
                                        //kennelId: widget.kennelAggregateItem.kennel.kennelId,
                                        kennelLogoUrl:
                                            widget
                                                .kennelAggregateItem
                                                .kennel
                                                .kennelLogo,
                                        kennelShortName:
                                            widget
                                                .kennelAggregateItem
                                                .kennel
                                                .kennelShortName,
                                        logoHeight: 200.0,
                                        leftPadding: 0.0,
                                        zoomGesture: KennelLogoZoomGesture.tap,
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.only(
                                          top: 45.0,
                                          bottom: 15.0,
                                        ),
                                        child: FancyDivider(
                                          key: Key('23423413'),
                                          innerColor: Colors.white,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 20,
                                          bottom: 5,
                                        ),
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.push<void>(
                                              context,
                                              MaterialPageRoute<void>(
                                                builder:
                                                    (
                                                      BuildContext context,
                                                    ) => ZoomableImagePage2(
                                                      key: const Key(
                                                        '51120331',
                                                      ),
                                                      pageTitle:
                                                          'Kennel Cover Photo',
                                                      imageUrl:
                                                          widget
                                                              .kennelAggregateItem
                                                              .kennel
                                                              .kennelCoverPhoto,
                                                      appBarBackgroundColor:
                                                          themeAppBarBackground,
                                                      background:
                                                          Backgrounds.defaultHcBackground(),
                                                      margin: 20.0,
                                                    ),
                                              ),
                                            );
                                          },
                                          child: CachedNetworkImage(
                                            imageUrl:
                                                widget
                                                    .kennelAggregateItem
                                                    .kennel
                                                    .kennelCoverPhoto!,
                                            // errorWidget:
                                            //     (BuildContext context, String url, Exception error) =>
                                            //         const  Icon(Icons.error),
                                          ),
                                        ),
                                        //decoration: BoxDecoration(color: Theme.of(context).selectedRowColor),
                                      ),
                                    ],
                                  )
                                  : Column(
                                    children: <Widget>[
                                      Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 20.0,
                                        ),
                                        width:
                                            MediaQuery.of(context).size.width -
                                            40,
                                        child: Text(
                                          widget
                                              .kennelAggregateItem
                                              .kennel
                                              .kennelName,
                                          textAlign: TextAlign.center,
                                          maxLines: 3,
                                          style: ts_titleLarge,
                                        ),
                                      ),

                                      // Stack(
                                      //   children: [
                                      //     // Shadow layer
                                      //     Positioned(
                                      //       top: 8,
                                      //       left: 8,
                                      //       child: ImageFiltered(
                                      //         imageFilter: ui.ImageFilter.blur(
                                      //           sigmaX: 9,
                                      //           sigmaY: 9,
                                      //         ),
                                      //         child: ColorFiltered(
                                      //           colorFilter:
                                      //               const ColorFilter.mode(
                                      //                 Colors.black,
                                      //                 BlendMode.srcIn,
                                      //               ),
                                      //           child: KennelLogo(
                                      //             //kennelId: widget.kennelAggregateItem.kennel.kennelId,
                                      //             kennelLogoUrl:
                                      //                 widget
                                      //                     .kennelAggregateItem
                                      //                     .kennel
                                      //                     .kennelLogo,
                                      //             kennelShortName:
                                      //                 widget
                                      //                     .kennelAggregateItem
                                      //                     .kennel
                                      //                     .kennelShortName,
                                      //             logoHeight: 200.0,
                                      //             leftPadding: 0.0,
                                      //             zoomGesture:
                                      //                 KennelLogoZoomGesture.tap,
                                      //           ),
                                      //         ),
                                      //       ),
                                      //     ),
                                      //     // Foreground image
                                      //     KennelLogo(
                                      //       //kennelId: widget.kennelAggregateItem.kennel.kennelId,
                                      //       kennelLogoUrl:
                                      //           widget
                                      //               .kennelAggregateItem
                                      //               .kennel
                                      //               .kennelLogo,
                                      //       kennelShortName:
                                      //           widget
                                      //               .kennelAggregateItem
                                      //               .kennel
                                      //               .kennelShortName,
                                      //       logoHeight: 200.0,
                                      //       leftPadding: 0.0,
                                      //       zoomGesture:
                                      //           KennelLogoZoomGesture.tap,
                                      //     ),
                                      //   ],
                                      // ),
                                      KennelLogo(
                                        //kennelId: widget.kennelAggregateItem.kennel.kennelId,
                                        kennelLogoUrl:
                                            widget
                                                .kennelAggregateItem
                                                .kennel
                                                .kennelLogo,
                                        kennelShortName:
                                            widget
                                                .kennelAggregateItem
                                                .kennel
                                                .kennelShortName,
                                        logoHeight: 200.0,
                                        leftPadding: 0.0,
                                        zoomGesture: KennelLogoZoomGesture.tap,
                                      ),
                                    ],
                                  ),
                              const Padding(
                                padding: EdgeInsets.only(
                                  top: 50.0,
                                  bottom: 25.0,
                                ),
                                child: FancyDivider(
                                  key: Key('16613234'),
                                  innerColor: Colors.white,
                                ),
                              ),
                              if (widget
                                      .kennelAggregateItem
                                      .hkm
                                      ?.appAccess
                                      .isAdmin ??
                                  false)
                                Column(
                                  children: <Widget>[
                                    Text(
                                      'Kennel Admin Functions',
                                      style: ts_headingLarge,
                                      textAlign: TextAlign.center,
                                    ),
                                    if (widget
                                        .kennelAggregateItem
                                        .hkm!
                                        .appAccess
                                        .canManageRuns)
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: <Widget>[
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 15,
                                              bottom: 15,
                                            ),
                                            child: SizedBox(
                                              width: 110,
                                              height: 110,
                                              child: Connection2.styleForConnected(
                                                G0<AppModel>().connectionStatus,
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 8.0,
                                                          bottom: 0.0,
                                                        ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: <Widget>[
                                                      const Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                              left: 0,
                                                            ),
                                                        child: Icon(
                                                          MaterialCommunityIcons
                                                              .run_fast,
                                                          color: Colors.white,
                                                          size: 60,
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              left: 10,
                                                              right: 10,
                                                              top: 5,
                                                            ),
                                                        child: Text(
                                                          'Add & Edit\r\nruns',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style:
                                                              ts_buttonLabelMedium,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  onPressed: () {
                                                    if (Connection2.checkForConnection(
                                                      G0<AppModel>()
                                                          .connectionStatus,
                                                    )) {
                                                      Navigator.push<dynamic>(
                                                        context,
                                                        MaterialPageRoute<
                                                          dynamic
                                                        >(
                                                          builder:
                                                              (
                                                                BuildContext
                                                                context,
                                                              ) => AddEditEventsPage(
                                                                kennel:
                                                                    widget
                                                                        .kennelAggregateItem,
                                                                pageType:
                                                                    FilterEventsPageType
                                                                        .future,
                                                              ),
                                                        ),
                                                      ).then((void _) {
                                                        _refreshFromTable(
                                                          true,
                                                        ).then((void _) {
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
                                            padding: const EdgeInsets.only(
                                              top: 15,
                                              bottom: 15,
                                            ),
                                            child: SizedBox(
                                              width: 110,
                                              height: 110,
                                              child: Connection2.styleForConnected(
                                                G0<AppModel>().connectionStatus,
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 8.0,
                                                          bottom: 0.0,
                                                        ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: <Widget>[
                                                      const Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                              left: 0,
                                                            ),
                                                        child: Icon(
                                                          MaterialCommunityIcons
                                                              .playlist_edit,
                                                          color: Colors.white,
                                                          size: 60,
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              left: 10,
                                                              right: 10,
                                                              top: 5,
                                                            ),
                                                        child: Text(
                                                          'Past\r\nevents',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style:
                                                              ts_buttonLabelMedium,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  onPressed: () {
                                                    if (Connection2.checkForConnection(
                                                      G0<AppModel>()
                                                          .connectionStatus,
                                                    )) {
                                                      Navigator.push<dynamic>(
                                                        context,
                                                        MaterialPageRoute<
                                                          dynamic
                                                        >(
                                                          builder:
                                                              (
                                                                BuildContext
                                                                context,
                                                              ) => AddEditEventsPage(
                                                                kennel:
                                                                    widget
                                                                        .kennelAggregateItem,
                                                                pageType:
                                                                    FilterEventsPageType
                                                                        .past,
                                                              ),
                                                        ),
                                                      ).then((void _) {
                                                        _refreshFromTable(
                                                          true,
                                                        ).then((void _) {
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
                                    if (widget
                                            .kennelAggregateItem
                                            .hkm
                                            ?.appAccess
                                            .canManageMembers ??
                                        false)
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: <Widget>[
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 15,
                                              bottom: 15,
                                            ),
                                            child: SizedBox(
                                              width: 110,
                                              height: 110,
                                              child: Connection2.styleForConnected(
                                                G0<AppModel>().connectionStatus,
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 8.0,
                                                          bottom: 0.0,
                                                        ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: <Widget>[
                                                      const Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                              left: 0,
                                                            ),
                                                        child: Icon(
                                                          Ionicons.md_people,
                                                          color: Colors.white,
                                                          size: 60,
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              left: 10,
                                                              right: 10,
                                                              top: 4,
                                                            ),
                                                        child: Text(
                                                          'Manage Members',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style:
                                                              ts_buttonLabelMedium,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  onPressed: () {
                                                    if (Connection2.checkForConnection(
                                                      G0<AppModel>()
                                                          .connectionStatus,
                                                    )) {
                                                      _kennelMembersList =
                                                          KennelMembersList(
                                                            kennelListAggregate:
                                                                widget
                                                                    .kennelAggregateItem,
                                                          );
                                                      Navigator.push<dynamic>(
                                                        context,
                                                        MaterialPageRoute<
                                                          dynamic
                                                        >(
                                                          builder:
                                                              (
                                                                BuildContext
                                                                context,
                                                              ) =>
                                                                  _kennelMembersList ??
                                                                  Container(),
                                                        ),
                                                      ).then((void _) async {
                                                        final KennelListAggregate?
                                                        kennelAggregate =
                                                            await QueryKennels.getSingleKennel(
                                                              widget
                                                                  .kennelAggregateItem
                                                                  .kennel
                                                                  .kennelId,
                                                            );

                                                        setState(() {
                                                          if ((kennelAggregate
                                                                      ?.kennel
                                                                      .kennelMismanagementTeam ==
                                                                  null) ||
                                                              (kennelAggregate!
                                                                  .kennel
                                                                  .kennelMismanagementTeam!
                                                                  .trim()
                                                                  .isEmpty)) {
                                                            _mismanagement =
                                                                null;
                                                          } else {
                                                            _mismanagement =
                                                                kennelAggregate
                                                                        .kennel
                                                                        .kennelMismanagementTeam!
                                                                        .contains(
                                                                          '\r',
                                                                        )
                                                                    ? kennelAggregate
                                                                        .kennel
                                                                        .kennelMismanagementTeam!
                                                                        .split(
                                                                          '\r',
                                                                        )
                                                                    : kennelAggregate
                                                                        .kennel
                                                                        .kennelMismanagementTeam!
                                                                        .split(
                                                                          '\n',
                                                                        );
                                                          }
                                                        });
                                                      });
                                                    }
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),

                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 15,
                                              bottom: 15,
                                            ),
                                            child: SizedBox(
                                              width: 110,
                                              height: 110,
                                              child: Connection2.styleForConnected(
                                                G0<AppModel>().connectionStatus,
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 8.0,
                                                          bottom: 0.0,
                                                        ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: <Widget>[
                                                      const Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                              left: 0,
                                                              top: 4,
                                                            ),
                                                        child: Icon(
                                                          MaterialCommunityIcons
                                                              .email_newsletter,
                                                          color: Colors.white,
                                                          size: 55,
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              left: 10,
                                                              right: 10,
                                                              top: 7,
                                                            ),
                                                        child: Text(
                                                          'Email invite codes',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style:
                                                              ts_buttonLabelMedium,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  onPressed: () async {
                                                    if (Connection2.checkForConnection(
                                                      G0<AppModel>()
                                                          .connectionStatus,
                                                    )) {
                                                      final bool?
                                                      isPreviewBool =
                                                          await _promptForSending(
                                                            context,
                                                          );

                                                      if (isPreviewBool !=
                                                          null) {
                                                        IveCoreUtilities.showInSnackBar(
                                                          navigatorKey
                                                              .currentContext!,
                                                          _scaffoldKey,
                                                          'Invite codes being sent...',
                                                          durationInSeconds: 10,
                                                        );

                                                        final EmailReportsService
                                                        svc =
                                                            EmailReportsService();
                                                        final Map<
                                                          String,
                                                          String
                                                        >
                                                        result = await svc
                                                            .sendKennelInvitesByEmail(
                                                              kennelId:
                                                                  widget
                                                                      .kennelAggregateItem
                                                                      .kennel
                                                                      .kennelId,
                                                              kennelName:
                                                                  widget
                                                                      .kennelAggregateItem
                                                                      .kennel
                                                                      .kennelName,
                                                              isPreview:
                                                                  isPreviewBool
                                                                      ? 'Yes'
                                                                      : 'No',
                                                            );

                                                        ScaffoldMessenger.of(
                                                          navigatorKey
                                                              .currentContext!,
                                                        ).hideCurrentSnackBar();

                                                        await Utilities.showAlert(
                                                          (result['result'] ??
                                                                      '')
                                                                  .toLowerCase()
                                                                  .startsWith(
                                                                    'fail',
                                                                  )
                                                              ? 'Failed'
                                                              : 'Success',
                                                          (result['result'] ??
                                                              ''),
                                                          'OK',
                                                        );
                                                      }
                                                    }
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),

                                          // Padding(
                                          //   padding: const EdgeInsets.only(top: 15, bottom: 15),
                                          //   child: Container(
                                          //     width: 110,
                                          //     height: 110,
                                          //     child: Connection2.styleForConnected(
                                          //       G0<AppModel>().connectionStatus,
                                          //       ElevatedButton(
                                          //         style: ElevatedButton.styleFrom(
                                          //           padding: const EdgeInsets.only(top: 8.0, bottom: 0.0),
                                          //         ),
                                          //         child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                                          //           const Padding(
                                          //             padding: EdgeInsets.only(left: 0),
                                          //             child: Icon(MaterialCommunityIcons.run_fast, color: Colors.white, size: 60),
                                          //           ),
                                          //           Padding(
                                          //             padding: const EdgeInsets.only(left: 10, right: 10, top: 5),
                                          //             child: Text(
                                          //               'Add & Edit\r\nruns',
                                          //               textAlign: TextAlign.center,
                                          //               style: buttonLabelStyleSmall,
                                          //             ),
                                          //           ),
                                          //         ]),
                                          //         onPressed: () {
                                          //           if (Connection2.checkForConnection(context, G0<AppModel>().connectionStatus)) {
                                          //             Navigator.push<dynamic>(
                                          //               context,
                                          //               MaterialPageRoute<dynamic>(
                                          //                 builder: (BuildContext context) => AddEditEventsPage(
                                          //                   kennel: widget.kennelAggregateItem,
                                          //                   pageType: FilterEventsPageType.future,
                                          //                 ),
                                          //               ),
                                          //             ).then((void _) {
                                          //               _refreshFromTable(true).then((void _) {
                                          //                 setState(() {});
                                          //               });
                                          //             });
                                          //           }
                                          //         },
                                          //       ),
                                          //     ),
                                          //   ),
                                          // ),
                                        ],
                                      ),
                                    if (widget
                                            .kennelAggregateItem
                                            .hkm
                                            ?.appAccess
                                            .canManageRuns ??
                                        false)
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: <Widget>[
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 15,
                                              bottom: 15,
                                            ),
                                            child: SizedBox(
                                              width: 110,
                                              height: 110,
                                              child: Connection2.styleForConnected(
                                                G0<AppModel>().connectionStatus,
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 8.0,
                                                          bottom: 0.0,
                                                        ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: <Widget>[
                                                      const Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                              left: 0,
                                                              top: 4,
                                                            ),
                                                        child: Icon(
                                                          MaterialCommunityIcons
                                                              .qrcode,
                                                          color: Colors.white,
                                                          size: 55,
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              left: 10,
                                                              right: 10,
                                                              top: 7,
                                                            ),
                                                        child: Text(
                                                          'Print QR codes',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style:
                                                              ts_buttonLabelMedium,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  onPressed: () {
                                                    Navigator.push<dynamic>(
                                                      context,
                                                      MaterialPageRoute<
                                                        dynamic
                                                      >(
                                                        builder:
                                                            (
                                                              BuildContext
                                                              context,
                                                            ) => EventQrCodePage(
                                                              kennelShortName:
                                                                  widget
                                                                      .kennelAggregateItem
                                                                      .kennel
                                                                      .kennelShortName,
                                                              qrContent:
                                                                  widget
                                                                      .kennelAggregateItem
                                                                      .kennel
                                                                      .kennelId,
                                                              runEndPrefix:
                                                                  QR_PREFIX_KENNEL_GENERIC_RUN_END,
                                                              runStartPrefix:
                                                                  QR_PREFIX_KENNEL_GENERIC_RUN_START,
                                                              runLink: '',
                                                              showRunLink:
                                                                  false,
                                                              title:
                                                                  'Any ${widget.kennelAggregateItem.kennel.kennelShortName} run',
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 15,
                                              bottom: 15,
                                            ),
                                            child: SizedBox(
                                              width: 110,
                                              height: 110,
                                              child: Connection2.styleForConnected(
                                                G0<AppModel>().connectionStatus,
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 8.0,
                                                          bottom: 0.0,
                                                        ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: <Widget>[
                                                      const Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                              left: 0,
                                                              top: 4,
                                                            ),
                                                        child: Icon(
                                                          MaterialIcons
                                                              .location_on,
                                                          color: Colors.white,
                                                          size: 55,
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              left: 10,
                                                              right: 10,
                                                              top: 7,
                                                            ),
                                                        child: Text(
                                                          'View run locations',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style:
                                                              ts_buttonLabelMedium,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  onPressed: () {
                                                    Navigator.push<dynamic>(
                                                      context,
                                                      MaterialPageRoute<
                                                        dynamic
                                                      >(
                                                        builder:
                                                            (
                                                              BuildContext
                                                              context,
                                                            ) => RunAndKennelMapPage(
                                                              kennel:
                                                                  widget
                                                                      .kennelAggregateItem
                                                                      .kennel,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (widget
                                            .kennelAggregateItem
                                            .hkm
                                            ?.appAccess
                                            .canManageRuns ??
                                        false)
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: <Widget>[
                                          Container(
                                            margin: const EdgeInsets.only(
                                              top: 20,
                                              bottom: 15,
                                            ),
                                            width: 110,
                                            height: 110,
                                            child: Connection2.styleForConnected(
                                              G0<AppModel>().connectionStatus,
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 8.0,
                                                        bottom: 0.0,
                                                      ),
                                                ),
                                                child: Column(
                                                  children: <Widget>[
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            right: 2.0,
                                                          ),
                                                      child: Image.asset(
                                                        'images/icons/excel.png',
                                                        height: 50.0,
                                                        width: 50.0,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            left: 10,
                                                            right: 10,
                                                            top: 8,
                                                          ),
                                                      child: Text(
                                                        'Email run stats',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style:
                                                            ts_buttonLabelMedium,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                onPressed: () {
                                                  if (Connection2.checkForConnection(
                                                    G0<AppModel>()
                                                        .connectionStatus,
                                                  )) {
                                                    final EmailReportsService
                                                    svc = EmailReportsService();
                                                    svc
                                                        .sendKennelRunStatsReportByEmail(
                                                          kennelId:
                                                              widget
                                                                  .kennelAggregateItem
                                                                  .kennel
                                                                  .kennelId,
                                                          kennelName:
                                                              widget
                                                                  .kennelAggregateItem
                                                                  .kennel
                                                                  .kennelName,
                                                          digitsAfterDecimal:
                                                              widget
                                                                  .kennelAggregateItem
                                                                  .extensions
                                                                  .digitsAfterDecimal ??
                                                              2,
                                                          currencySymbol:
                                                              widget
                                                                  .kennelAggregateItem
                                                                  .extensions
                                                                  .currencySymbol ??
                                                              r'$',
                                                        )
                                                        .then((
                                                          Map<String, String>
                                                          result,
                                                        ) {
                                                          ScaffoldMessenger.of(
                                                            navigatorKey
                                                                .currentContext!,
                                                          ).hideCurrentSnackBar();

                                                          if ((result['result'] ??
                                                                  '')
                                                              .toLowerCase()
                                                              .startsWith(
                                                                'success',
                                                              )) {
                                                            Utilities.showAlert(
                                                              'E-mail successfully sent',
                                                              'Your Kennel run stats report has been successfully e-mailed to:\r\n\r\n${result['email']}\r\n\r\nIf you do not see it in the next few minutes, check your spam folder.',
                                                              'OK',
                                                            );
                                                          }
                                                        });

                                                    IveCoreUtilities.showInSnackBar(
                                                      context,
                                                      _scaffoldKey,
                                                      'Run stats being processed...',
                                                      durationInSeconds: 10,
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    const Padding(
                                      padding: EdgeInsets.only(
                                        top: 50.0,
                                        bottom: 25.0,
                                      ),
                                      child: FancyDivider(
                                        key: Key('5511334'),
                                        innerColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              (widget
                                              .kennelAggregateItem
                                              .kennel
                                              .kennelDescription ??
                                          '')
                                      .isNotEmpty
                                  ? Column(
                                    children: <Widget>[
                                      Linkify(
                                        text: widget
                                            .kennelAggregateItem
                                            .kennel
                                            .kennelDescription
                                            .toString()
                                            .replaceAll('\r\n', '\n'),
                                        style: ts_body,
                                        linkStyle: ts_bodyYellow,
                                        onOpen: (LinkableElement link) async {
                                          if (Utilities.isValidUrl(link.url)) {
                                            await launchUrl(
                                              Uri.parse(link.url),
                                              mode:
                                                  LaunchMode
                                                      .externalApplication,
                                            );
                                          } else {
                                            await Utilities.showAlert(
                                              'Unable to open link',
                                              'Harrier Central was unable to open ${link.url}',
                                              'OK',
                                            );
                                          }
                                        },
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.only(
                                          top: 50.0,
                                          bottom: 25.0,
                                        ),
                                        child: FancyDivider(
                                          key: Key('11939302'),
                                          innerColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  )
                                  : Container(),
                              Column(
                                children: <Widget>[
                                  ConnectedWidget(
                                    refreshFunction: () {
                                      setState(() {});
                                    },
                                    //showConnectButton: true,
                                    disconnectedChild: Padding(
                                      padding: const EdgeInsets.only(
                                        top: 1,
                                        bottom: 30,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Kennel maps require a connection to the Internet',
                                          style: ts_headingLarge,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width,
                                      height: 300,
                                      //padding: const EdgeInsets.all(20.0),
                                      child: Center(
                                        // Map
                                        child:
                                            (widget
                                                        .kennelAggregateItem
                                                        .extensions
                                                        .cityLat ==
                                                    null)
                                                ? const SizedBox()
                                                : FlutterMap(
                                                  mapController: _mapController,
                                                  options: MapOptions(
                                                    //interactive: false,
                                                    initialCenter: latlng.LatLng(
                                                      widget
                                                          .kennelAggregateItem
                                                          .extensions
                                                          .cityLat!,
                                                      widget
                                                          .kennelAggregateItem
                                                          .extensions
                                                          .cityLon!,
                                                    ),
                                                    initialZoom: _sliderValue,
                                                    minZoom: 1.0,
                                                    maxZoom: 18.0,
                                                  ),
                                                  children: <Widget>[
                                                    TileLayer(
                                                      urlTemplate:
                                                          //'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                                          'http://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                                                      //subdomains: ['a', 'b', 'c']),
                                                      subdomains:
                                                          const <String>[
                                                            'mt0',
                                                            'mt1',
                                                            'mt2',
                                                            'mt3',
                                                          ],
                                                    ),
                                                    MarkerLayer(
                                                      markers: <Marker>[
                                                        Marker(
                                                          width: 240.0,
                                                          height: 240.0,
                                                          point: latlng.LatLng(
                                                            widget
                                                                .kennelAggregateItem
                                                                .extensions
                                                                .cityLat!,
                                                            widget
                                                                .kennelAggregateItem
                                                                .extensions
                                                                .cityLon!,
                                                          ),
                                                          child: GestureDetector(
                                                            onTap: () async {
                                                              if ((widget
                                                                          .kennelAggregateItem
                                                                          .extensions
                                                                          .cityLat !=
                                                                      null) &&
                                                                  (widget
                                                                          .kennelAggregateItem
                                                                          .extensions
                                                                          .cityLon !=
                                                                      null)) {
                                                                final String?
                                                                mapName = getStringPref(
                                                                  StringPrefsEnum
                                                                      .mapPreference,
                                                                );

                                                                if (mapName ==
                                                                    null) {
                                                                  await Utilities.openMapsSheet(
                                                                    context,
                                                                    widget
                                                                        .kennelAggregateItem
                                                                        .kennel
                                                                        .kennelName,
                                                                    maps.Coords(
                                                                      widget
                                                                          .kennelAggregateItem
                                                                          .extensions
                                                                          .cityLat!
                                                                          .toDouble(),
                                                                      widget
                                                                          .kennelAggregateItem
                                                                          .extensions
                                                                          .cityLon!
                                                                          .toDouble(),
                                                                    ),
                                                                    '',
                                                                    _saveUserMapPreference,
                                                                  );
                                                                } else {
                                                                  final List<
                                                                    maps.AvailableMap
                                                                  >
                                                                  availableMaps =
                                                                      await maps
                                                                          .MapLauncher
                                                                          .installedMaps;
                                                                  final maps.AvailableMap
                                                                  activeMap =
                                                                      availableMaps
                                                                          .where(
                                                                            (
                                                                              maps.AvailableMap
                                                                              map,
                                                                            ) =>
                                                                                map.mapName ==
                                                                                mapName,
                                                                          )
                                                                          .first;

                                                                  // BUG in plugin - doesn't work when sending a title with Google maps
                                                                  activeMap.showMarker(
                                                                    coords: maps.Coords(
                                                                      widget
                                                                          .kennelAggregateItem
                                                                          .extensions
                                                                          .cityLat!
                                                                          .toDouble(),
                                                                      widget
                                                                          .kennelAggregateItem
                                                                          .extensions
                                                                          .cityLon!
                                                                          .toDouble(),
                                                                    ),
                                                                    title:
                                                                        activeMap.mapName.contains(
                                                                              'Google',
                                                                            )
                                                                            ? ''
                                                                            : widget.kennelAggregateItem.kennel.kennelName,
                                                                    description:
                                                                        widget
                                                                            .kennelAggregateItem
                                                                            .kennel
                                                                            .kennelName,
                                                                  );
                                                                }
                                                              }
                                                            },
                                                            child: Container(
                                                              margin:
                                                                  const EdgeInsets.only(
                                                                    bottom:
                                                                        110.0,
                                                                  ),
                                                              child: Stack(
                                                                alignment:
                                                                    AlignmentDirectional
                                                                        .topCenter,
                                                                children: <
                                                                  Widget
                                                                >[
                                                                  Image.asset(
                                                                    'images/icons/grey_square_pin.png',
                                                                  ),
                                                                  Positioned(
                                                                    top: 14,
                                                                    child: KennelLogo(
                                                                      //kennelId: widget.kennelAggregateItem.kennel.kennelId,
                                                                      kennelLogoUrl:
                                                                          widget
                                                                              .kennelAggregateItem
                                                                              .kennel
                                                                              .kennelLogo,
                                                                      kennelShortName:
                                                                          widget
                                                                              .kennelAggregateItem
                                                                              .kennel
                                                                              .kennelShortName,
                                                                      logoHeight:
                                                                          60.0,
                                                                      leftPadding:
                                                                          0.0,
                                                                      zoomGesture:
                                                                          KennelLogoZoomGesture
                                                                              .none,
                                                                    ),
                                                                  ),
                                                                ],
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
                                  ConnectedWidget(
                                    child: Container(
                                      padding: const EdgeInsets.only(top: 10.0),
                                      child: Slider(
                                        value: _sliderValue,
                                        activeColor: Colors.yellow,
                                        inactiveColor: Colors.grey,
                                        min: 1.0,
                                        max: 20.0,
                                        onChanged: (double val) {
                                          if (widget
                                                  .kennelAggregateItem
                                                  .extensions
                                                  .cityLat !=
                                              null) {
                                            _mapController.move(
                                              latlng.LatLng(
                                                widget
                                                    .kennelAggregateItem
                                                    .extensions
                                                    .cityLat!,
                                                widget
                                                    .kennelAggregateItem
                                                    .extensions
                                                    .cityLon!,
                                              ),
                                              val,
                                            );

                                            setState(() {
                                              _sliderValue = val;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: <Widget>[
                                      const SizedBox(height: 25.0),
                                      Expanded(
                                        flex: _flexLeft,
                                        child: Text(
                                          'Location:',
                                          style: ts_listLabelStyle,
                                          textAlign: TextAlign.right,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Expanded(
                                        flex: _flexRight,
                                        child: Text(
                                          '  ${widget.kennelAggregateItem.extensions.location ?? ''}',
                                          style: ts_listValueStyle,
                                          textAlign: TextAlign.left,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      const SizedBox(height: 25.0),
                                      Expanded(
                                        flex: _flexLeft,
                                        child: Text(
                                          'Last run:',
                                          style: ts_listLabelStyle,
                                          textAlign: TextAlign.right,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Expanded(
                                        flex: _flexRight,
                                        child: Text(
                                          widget
                                                      .kennelAggregateItem
                                                      .extensions
                                                      .lastRunDate !=
                                                  null
                                              ? '  ${DateFormat('E, MMM d,  h:mm a').format(DateTime.parse(widget.kennelAggregateItem.extensions.lastRunDate!.substring(0, 19)))}'
                                              : '  <no run found>',
                                          style: ts_listValueStyle,
                                          textAlign: TextAlign.left,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      const SizedBox(height: 25.0),
                                      Expanded(
                                        flex: _flexLeft,
                                        child: Text(
                                          'Next run:',
                                          style: ts_listLabelStyle,
                                          textAlign: TextAlign.right,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Expanded(
                                        flex: _flexRight,
                                        child: Text(
                                          widget
                                                      .kennelAggregateItem
                                                      .extensions
                                                      .nextRunDate !=
                                                  null
                                              ? '  ${DateFormat('E, MMM d,  h:mm a').format(DateTime.parse(widget.kennelAggregateItem.extensions.nextRunDate!.substring(0, 19)))}'
                                              : '  <no run found>',
                                          style: ts_listValueStyle,
                                          textAlign: TextAlign.left,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      const SizedBox(height: 25.0),
                                      Expanded(
                                        flex: _flexLeft,
                                        child: Text(
                                          'Hash cash:',
                                          style: ts_listLabelStyle,
                                          textAlign: TextAlign.right,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Expanded(
                                        flex: _flexRight,
                                        child: Text(
                                          widget
                                                      .kennelAggregateItem
                                                      .kennel
                                                      .defaultPriceForMembers <=
                                                  0
                                              ? ''
                                              : '  ${IveCoreUtilities.getFormattedMoney(widget.kennelAggregateItem.kennel.defaultPriceForMembers, widget.kennelAggregateItem.extensions.digitsAfterDecimal ?? 2, widget.kennelAggregateItem.extensions.currencySymbol ?? r'$^')}    (members)',
                                          style: ts_listValueStyle,
                                          textAlign: TextAlign.left,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      const SizedBox(height: 25.0),
                                      Expanded(
                                        flex: _flexLeft,
                                        child: Text(
                                          '',
                                          style: ts_listLabelStyle,
                                          textAlign: TextAlign.right,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Expanded(
                                        flex: _flexRight,
                                        child: Text(
                                          widget
                                                      .kennelAggregateItem
                                                      .kennel
                                                      .defaultPriceForNonMembers <=
                                                  0
                                              ? ''
                                              : '  ${IveCoreUtilities.getFormattedMoney(widget.kennelAggregateItem.kennel.defaultPriceForNonMembers, widget.kennelAggregateItem.extensions.digitsAfterDecimal ?? 2, widget.kennelAggregateItem.extensions.currencySymbol ?? r'$^')}    (non-members)',
                                          style: ts_listValueStyle,
                                          textAlign: TextAlign.left,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ((widget
                                                      .kennelAggregateItem
                                                      .kennel
                                                      .kennelMismanagementTeam ==
                                                  null) ||
                                              (widget
                                                  .kennelAggregateItem
                                                  .kennel
                                                  .kennelMismanagementTeam!
                                                  .trim()
                                                  .isEmpty) ||
                                              (widget
                                                  .kennelAggregateItem
                                                  .kennel
                                                  .kennelMismanagementTeam!
                                                  .toLowerCase()
                                                  .contains('none listed'))) ||
                                          (_mismanagement == null)
                                      ? Container()
                                      : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          const FancyDivider(
                                            key: Key('55139201'),
                                            innerColor: Colors.white,
                                            topMargin: 30.0,
                                            bottomMargin: 10.0,
                                          ),
                                          for (String item in _mismanagement!)
                                            _mmRow(item),
                                        ],
                                      ),
                                  (_allRuns.isEmpty)
                                      ? Container()
                                      : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: <Widget>[
                                          const FancyDivider(
                                            key: Key('11344366'),
                                            innerColor: Colors.white,
                                            topMargin: 30.0,
                                            bottomMargin: 10.0,
                                          ),
                                          Center(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 15.0,
                                              ),
                                              child: Text(
                                                _allRuns.length == 1
                                                    ? 'Next run'
                                                    : 'Next ${_allRuns.length} runs',
                                                style: ts_headingLarge,
                                                textAlign: TextAlign.right,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          for (RunDetailsAggregate item
                                              in _allRuns)
                                            _runRow(item),
                                          const SizedBox(height: 15.0),
                                        ],
                                      ),
                                  ((widget
                                                  .kennelAggregateItem
                                                  .kennel
                                                  .kennelWebsiteUrl ==
                                              null) ||
                                          (widget
                                              .kennelAggregateItem
                                              .kennel
                                              .kennelWebsiteUrl!
                                              .trim()
                                              .isEmpty))
                                      ? Container()
                                      : Column(
                                        children: <Widget>[
                                          const FancyDivider(
                                            key: Key('123435661'),
                                            innerColor: Colors.white,
                                            topMargin: 30.0,
                                            bottomMargin: 15.0,
                                          ),
                                          Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 20,
                                            ),
                                            width: _buttonWidth,
                                            height: _buttonHeight,
                                            child: Connection2.styleForConnected(
                                              G0<AppModel>().connectionStatus,
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        left: 12.0,
                                                        top: 8.0,
                                                        bottom: 8.0,
                                                      ),
                                                ),
                                                child: Row(
                                                  children: <Widget>[
                                                    SizedBox(
                                                      width: 45.0,
                                                      child: Stack(
                                                        alignment:
                                                            AlignmentDirectional
                                                                .center,
                                                        children: <Widget>[
                                                          Container(
                                                            height: 30,
                                                            width: 30,
                                                            decoration:
                                                                BoxDecoration(
                                                                  color:
                                                                      hc_blue,
                                                                  shape:
                                                                      BoxShape
                                                                          .circle,
                                                                ),
                                                          ),
                                                          const Positioned(
                                                            bottom: 1.4,
                                                            child: Icon(
                                                              SimpleLineIcons
                                                                  .globe,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            left: 20,
                                                            right: 0,
                                                          ),
                                                      child: Text(
                                                        'Open website',
                                                        style: ts_button,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                onPressed: () {
                                                  if (Connection2.checkForConnection(
                                                    G0<AppModel>()
                                                        .connectionStatus,
                                                  )) {
                                                    launchUrl(
                                                      Uri.parse(
                                                        widget
                                                            .kennelAggregateItem
                                                            .kennel
                                                            .kennelWebsiteUrl!,
                                                      ),
                                                      mode:
                                                          LaunchMode
                                                              .externalApplication,
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                  Column(
                                    children: <Widget>[
                                      // const FancyDivider(
                                      //   key: Key('123435661'),
                                      //   innerColor: Colors.white,
                                      //   topMargin: 30.0,
                                      //   bottomMargin: 15.0,
                                      // ),
                                      Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 20,
                                        ),
                                        width: _buttonWidth,
                                        height: _buttonHeight,
                                        child: Connection2.styleForConnected(
                                          G0<AppModel>().connectionStatus,
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.only(
                                                left: 12.0,
                                                top: 8.0,
                                                bottom: 8.0,
                                              ),
                                            ),
                                            child: Row(
                                              children: <Widget>[
                                                SizedBox(
                                                  width: 45.0,
                                                  child: Image.asset(
                                                    'images/icons/painter_palette.png',
                                                    height: 35,
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        left: 20,
                                                        right: 0,
                                                      ),
                                                  child: Text(
                                                    'Run art gallery',
                                                    style: ts_button,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            onPressed: () async {
                                              final List<Map<String, dynamic>>
                                              results =
                                                  await QueryKennels.queryKennelGallery(
                                                    widget
                                                        .kennelAggregateItem
                                                        .kennel
                                                        .kennelId,
                                                  );

                                              if (!mounted) return;
                                              await Navigator.push<void>(
                                                navigatorKey.currentContext!,
                                                MaterialPageRoute<void>(
                                                  builder:
                                                      (BuildContext context) =>
                                                          HashRunArtGalleryPage(
                                                            key: const Key(
                                                              '52233311',
                                                            ),
                                                            items: results,
                                                          ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 20,
                                        ),
                                        width: _buttonWidth,
                                        height: _buttonHeight,
                                        child: Connection2.styleForConnected(
                                          G0<AppModel>().connectionStatus,
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.only(
                                                left: 12.0,
                                                top: 8.0,
                                                bottom: 8.0,
                                              ),
                                            ),
                                            child: Row(
                                              children: <Widget>[
                                                SizedBox(
                                                  width: 45.0,
                                                  child: Image.asset(
                                                    'images/icons/leaderboard_icon.png',
                                                    height: 35,
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        left: 20,
                                                        right: 0,
                                                      ),
                                                  child: Text(
                                                    'Leaderboards',
                                                    style: ts_button,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            onPressed: () async {
                                              if (!mounted) return;
                                              await Navigator.push<void>(
                                                context,
                                                MaterialPageRoute<void>(
                                                  builder:
                                                      (
                                                        BuildContext context,
                                                      ) => GenericWidgetPage(
                                                        key: const Key(
                                                          '52233311',
                                                        ),
                                                        widget: Leaderboard(
                                                          kennelId:
                                                              widget
                                                                  .kennelAggregateItem
                                                                  .kennel
                                                                  .kennelId,
                                                          //kennelId: null,
                                                        ),
                                                        appBarTitle:
                                                            'Get a Life (Leaderboards)',
                                                      ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      if (widget
                                              .kennelAggregateItem
                                              .extensions
                                              .isKennelMember ==
                                          1) ...<Widget>[
                                        const FancyDivider(
                                          key: Key('5203920'),
                                          innerColor: Colors.white,
                                          topMargin: 30.0,
                                          bottomMargin: 25.0,
                                        ),
                                        Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 20,
                                          ),
                                          width: _buttonWidth,
                                          height: _buttonHeight,
                                          child: Connection2.styleForConnected(
                                            G0<AppModel>().connectionStatus,
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                padding: const EdgeInsets.only(
                                                  left: 12.0,
                                                  top: 8.0,
                                                  bottom: 8.0,
                                                ),
                                              ),
                                              child: Row(
                                                children: <Widget>[
                                                  SizedBox(
                                                    width: 45.0,
                                                    child: Image.asset(
                                                      'images/icons/woman_man_profile_icon.png',
                                                      height: 40,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          left: 20,
                                                          right: 0,
                                                        ),
                                                    child: Text(
                                                      'Customize profile',
                                                      style: ts_button,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              onPressed: () async {
                                                if (!mounted) return;

                                                if ((widget
                                                            .kennelAggregateItem
                                                            .extensions
                                                            .originalProfilePhoto !=
                                                        null) &&
                                                    (widget
                                                            .kennelAggregateItem
                                                            .extensions
                                                            .originalDisplayName !=
                                                        null)) {
                                                  await Navigator.push<void>(
                                                    context,
                                                    MaterialPageRoute<void>(
                                                      builder:
                                                          (
                                                            BuildContext
                                                            context,
                                                          ) => GenericWidgetPage(
                                                            key: const Key(
                                                              '52233311',
                                                            ),
                                                            widget: CustomizeProfile(
                                                              originalProfilePhoto:
                                                                  widget
                                                                      .kennelAggregateItem
                                                                      .extensions
                                                                      .originalProfilePhoto!,
                                                              originalDisplayName:
                                                                  widget
                                                                      .kennelAggregateItem
                                                                      .extensions
                                                                      .originalDisplayName!,
                                                              customKennelPhoto:
                                                                  widget
                                                                      .kennelAggregateItem
                                                                      .hkm
                                                                      ?.kennelUserPhoto,
                                                              customKennelHashName:
                                                                  widget
                                                                      .kennelAggregateItem
                                                                      .hkm
                                                                      ?.kennelHashName,
                                                            ),
                                                            appBarTitle:
                                                                'Customize profile',
                                                          ),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
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
          lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSyncAsDate),
          ribbonImage: 'images/icons/offline_mode.png',
          refreshFunction: () {
            setState(() {});
          },
        ),
      ],
    );
  }

  static Future<bool?> _promptForSending(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Send invite codes', style: ts_alertDialogTitle),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'This feature allows you to send Invite Codes to all users in the Harrier Central system that have an account, but have not yet logged in using their mobile device.\r\n\r\nWe recommend that you first test before sending to see if the number of accounts appears correct.',
                  style: ts_alertDialogBody,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: text_button_style,
              child: Text('Cancel', style: ts_button),
              onPressed: () {
                Navigator.of(context).pop(null);
              },
            ),
            TextButton(
              style: text_button_style,
              child: Text('Preview', style: ts_button),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
            TextButton(
              style: text_button_style,
              child: Text('Send', style: ts_button),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _mmRow(String s) {
    if (s.isEmpty) {
      return Container();
    } else {
      final List<String> items = s.split('\t');
      return (items.length < 2)
          ? Container()
          : Row(
            children: <Widget>[
              const SizedBox(height: 25.0),
              Expanded(
                flex: 50,
                child: Text(
                  '${items[0]}:',
                  style: ts_listLabelStyle,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 50,
                child: Text(
                  ' ${items[1]}',
                  style: ts_listValueStyle,
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
    }
  }

  Widget _runRow(RunDetailsAggregate s) {
    return RunListItem(
      futureRun: s,
      currentChatCount: 0,
      onItemTapped: () {
        Navigator.push<dynamic>(
          context,
          MaterialPageRoute<dynamic>(
            builder: (BuildContext context) => RunDetailsPage(futureRun: s),
          ),
        ).then((void _) {
          // _refreshFromBackend(clearLocalTables: false).then((void _) {
          //   setState(() {});
          // });
        });
      },
    );
  }
}
