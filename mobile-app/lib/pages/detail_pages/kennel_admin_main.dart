//import 'dart:ui' as ui;

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
  // Slider zoom is purely UI — kept local so MapController.move() is called
  // synchronously in onChanged without forcing a controller rebuild.
  double _sliderValue = 5.0;

  late final KennelAdminController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      KennelAdminController(kennelAggregateItem: widget.kennelAggregateItem),
      tag: widget.kennelAggregateItem.kennel.kennelId,
    );
  }

  @override
  void dispose() {
    Get.delete<KennelAdminController>(
      tag: widget.kennelAggregateItem.kennel.kennelId,
    );
    super.dispose();
  }

  static const double _buttonHeight = 53.0;
  static const double _buttonWidth = 270.0;
  static const int _flexLeft = 3;
  static const int _flexRight = 7;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        SizedBox(
          height: MediaQuery.sizeOf(context).height,
          width: MediaQuery.sizeOf(context).width,
        ),
        Positioned(
          top: 0,
          left: 0,
          width: MediaQuery.sizeOf(context).width,
          height: MediaQuery.sizeOf(context).height,
          child: AppScaffold(
            appBar: AppBar(
              centerTitle: true,
              backgroundColor: themeAppBarBackground,
              iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
              title: Text(
                widget.kennelAggregateItem.kennel.kennelShortName,
                style: ts_appBarTitle,
              ),
            ),
            body: Container(
              height: MediaQuery.sizeOf(context).height,
              decoration: Backgrounds.defaultHcBackground(),
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: HcAppCircularProgressIndicator(
                      key: Key('16637721'),
                    ),
                  );
                }
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 30.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        _buildLogoSection(context),
                        const Padding(
                          padding: EdgeInsets.only(top: 50.0, bottom: 25.0),
                          child: FancyDivider(
                            key: Key('16613234'),
                            innerColor: Colors.white,
                          ),
                        ),
                        if (widget.kennelAggregateItem.hkm?.appAccess.isAdmin ??
                            false)
                          _buildAdminFunctions(context),
                        _buildDescriptionSection(),
                        _buildMapAndInfoSection(context),
                        const SizedBox(height: 25.0),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        OfflineModeRibbon(
          lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSync),
          ribbonImage: 'images/icons/offline_mode.png',
          refreshFunction: () {
            setState(() {});
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Logo / cover photo section
  // ---------------------------------------------------------------------------
  Widget _buildLogoSection(BuildContext context) {
    final kennel = widget.kennelAggregateItem.kennel;
    final hasCoverPhoto = ((kennel.kennelCoverPhoto ?? '').isNotEmpty &&
        kennel.kennelCoverPhoto!.startsWith('http'));

    if (hasCoverPhoto) {
      return Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(bottom: 20.0),
            width: MediaQuery.sizeOf(context).width - 40,
            child: Text(
              kennel.kennelName,
              textAlign: TextAlign.center,
              maxLines: 3,
              style: ts_titleLarge,
            ),
          ),
          KennelLogo(
            kennelLogoUrl: kennel.kennelLogo,
            kennelShortName: kennel.kennelShortName,
            logoHeight: 200.0,
            leftPadding: 0.0,
            zoomGesture: KennelLogoZoomGesture.tap,
          ),
          const Padding(
            padding: EdgeInsets.only(top: 45.0, bottom: 15.0),
            child: FancyDivider(
              key: Key('23423413'),
              innerColor: Colors.white,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 5),
            child: GestureDetector(
              onTap: () async {
                await Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => ZoomableImagePage2(
                      key: const Key('51120331'),
                      pageTitle: 'Kennel Cover Photo',
                      imageUrl: kennel.kennelCoverPhoto,
                      appBarBackgroundColor: themeAppBarBackground,
                      background: Backgrounds.defaultHcBackground(),
                      margin: 20.0,
                    ),
                  ),
                );
              },
              child: CachedNetworkImage(
                imageUrl: kennel.kennelCoverPhoto!,
              ),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(bottom: 20.0),
            width: MediaQuery.sizeOf(context).width - 40,
            child: Text(
              kennel.kennelName,
              textAlign: TextAlign.center,
              maxLines: 3,
              style: ts_titleLarge,
            ),
          ),
          KennelLogo(
            kennelLogoUrl: kennel.kennelLogo,
            kennelShortName: kennel.kennelShortName,
            logoHeight: 200.0,
            leftPadding: 0.0,
            zoomGesture: KennelLogoZoomGesture.tap,
          ),
        ],
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Admin functions section
  // ---------------------------------------------------------------------------
  Widget _buildAdminFunctions(BuildContext context) {
    final agg = widget.kennelAggregateItem;
    return Column(
      children: <Widget>[
        Text(
          'Kennel Admin Functions',
          style: ts_headingLarge,
          textAlign: TextAlign.center,
        ),
        if (agg.hkm!.appAccess.canManageRuns)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _adminButton(
                icon: MaterialCommunityIcons.run_fast,
                label: 'Add & Edit\r\nruns',
                onPressed: () async {
                  if (Utilities.isConnected(showDialog: true)) {
                    await Navigator.push<dynamic>(
                      context,
                      MaterialPageRoute<dynamic>(
                        builder: (BuildContext context) => AddEditEventsPage(
                          kennel: agg,
                          pageType: FilterEventsPageType.future,
                        ),
                      ),
                    );
                    unawaited(controller.refreshFromTable(true));
                  }
                },
              ),
              _adminButton(
                icon: MaterialCommunityIcons.playlist_edit,
                label: 'Past\r\nevents',
                onPressed: () async {
                  if (Utilities.isConnected(showDialog: true)) {
                    await Navigator.push<dynamic>(
                      context,
                      MaterialPageRoute<dynamic>(
                        builder: (BuildContext context) => AddEditEventsPage(
                          kennel: agg,
                          pageType: FilterEventsPageType.past,
                        ),
                      ),
                    );
                    unawaited(controller.refreshFromTable(true));
                  }
                },
              ),
            ],
          ),
        if (agg.hkm?.appAccess.canManageRuns ?? false)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _adminButton(
                icon: MaterialCommunityIcons.qrcode,
                iconTopPadding: 4,
                iconSize: 55,
                labelTopPadding: 7,
                label: 'Print QR codes',
                onPressed: () async {
                  await Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(
                      builder: (BuildContext context) => EventQrCodePage(
                        kennelShortName: agg.kennel.kennelShortName,
                        qrContent: agg.kennel.kennelId,
                        runEndPrefix: QR_PREFIX_KENNEL_GENERIC_RUN_END,
                        runStartPrefix: QR_PREFIX_KENNEL_GENERIC_RUN_START,
                        runLink: '',
                        showRunLink: false,
                        title: 'Any ${agg.kennel.kennelShortName} run',
                      ),
                    ),
                  );
                },
              ),
              _adminButton(
                icon: MaterialIcons.location_on,
                iconTopPadding: 4,
                iconSize: 55,
                labelTopPadding: 7,
                label: 'View run locations',
                onPressed: () async {
                  await Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(
                      builder: (BuildContext context) => RunAndKennelMapPage(
                        kennel: agg.kennel,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            if (agg.hkm?.appAccess.canManageRuns ?? false)
              Container(
                margin: const EdgeInsets.only(top: 20, bottom: 15),
                width: 110,
                height: 110,
                child: StyleForConnected(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 0.0),
                    ),
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(right: 2.0),
                          child: Image.asset(
                            'images/icons/excel.png',
                            height: 50.0,
                            width: 50.0,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 10, right: 10, top: 8),
                          child: Text(
                            'Email run stats',
                            textAlign: TextAlign.center,
                            style: ts_buttonLabelMedium,
                          ),
                        ),
                      ],
                    ),
                    onPressed: () async {
                      if (Utilities.isConnected(showDialog: true)) {
                        final EmailReportsService svc = EmailReportsService();
                        if (navigatorKey.currentContext != null) {
                          IveCoreUtilities.showInSnackBar(
                            navigatorKey.currentContext!,
                            'Run stats being processed...',
                            durationInSeconds: 10,
                          );
                        }
                        await svc
                            .sendKennelRunStatsReportByEmail(
                              kennelId: agg.kennel.kennelId,
                              kennelName: agg.kennel.kennelName,
                              digitsAfterDecimal:
                                  agg.extensions.digitsAfterDecimal ?? 2,
                              currencySymbol:
                                  agg.extensions.currencySymbol ?? r'$',
                            )
                            .then((Map<String, String> result) async {
                          ScaffoldMessenger.of(navigatorKey.currentContext!)
                              .hideCurrentSnackBar();
                          if ((result['result'] ?? '')
                              .toLowerCase()
                              .startsWith('success')) {
                            await Utilities.showAlert(
                              'E-mail successfully sent',
                              'Your Kennel run stats report has been successfully e-mailed to:\r\n\r\n${result['email']}\r\n\r\nIf you do not see it in the next few minutes, check your spam folder.',
                              'OK',
                            );
                          }
                        });
                      }
                    },
                  ),
                ),
              ),
            if (agg.hkm?.appAccess.canManageMembers ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 15, bottom: 15),
                child: SizedBox(
                  width: 110,
                  height: 110,
                  child: StyleForConnected(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 0.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          const Padding(
                            padding: EdgeInsets.only(left: 0),
                            child: Icon(
                              Ionicons.md_people,
                              color: Colors.white,
                              size: 60,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 10, right: 10, top: 4),
                            child: Text(
                              'Manage Members',
                              textAlign: TextAlign.center,
                              style: ts_buttonLabelMedium,
                            ),
                          ),
                        ],
                      ),
                      onPressed: () async {
                        if (Utilities.isConnected(showDialog: true)) {
                          final KennelMembersList membersPage =
                              KennelMembersList(kennelListAggregate: agg);
                          await Navigator.push<dynamic>(
                            context,
                            MaterialPageRoute<dynamic>(
                              builder: (BuildContext context) => membersPage,
                            ),
                          );
                          await controller.refreshMismanagement();
                        }
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(top: 50.0, bottom: 25.0),
          child: FancyDivider(
            key: Key('5511334'),
            innerColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _adminButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    double iconSize = 60,
    double iconTopPadding = 0,
    double labelTopPadding = 5,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 15),
      child: SizedBox(
        width: 110,
        height: 110,
        child: StyleForConnected(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.only(top: 8.0, bottom: 0.0),
            ),
            onPressed: onPressed,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(left: 0, top: iconTopPadding),
                  child: Icon(icon, color: Colors.white, size: iconSize),
                ),
                Padding(
                  padding: EdgeInsets.only(
                      left: 10, right: 10, top: labelTopPadding),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: ts_buttonLabelMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Description section
  // ---------------------------------------------------------------------------
  Widget _buildDescriptionSection() {
    final description =
        widget.kennelAggregateItem.kennel.kennelDescription ?? '';
    if (description.isEmpty) return Container();
    return Column(
      children: <Widget>[
        Linkify(
          text: description.replaceAll('\r\n', '\n'),
          style: ts_body,
          linkStyle: ts_bodyYellow,
          onOpen: (LinkableElement link) async {
            if (Utilities.isValidUrl(link.url)) {
              await launchUrl(
                Uri.parse(link.url),
                mode: LaunchMode.externalApplication,
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
          padding: EdgeInsets.only(top: 50.0, bottom: 25.0),
          child: FancyDivider(
            key: Key('11939302'),
            innerColor: Colors.white,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Map, info rows, mismanagement, runs, QR links, buttons
  // ---------------------------------------------------------------------------
  Widget _buildMapAndInfoSection(BuildContext context) {
    final agg = widget.kennelAggregateItem;
    return Column(
      children: <Widget>[
        ConnectedWidget(
          refreshFunction: () => setState(() {}),
          disconnectedChild: Padding(
            padding: const EdgeInsets.only(top: 1, bottom: 30),
            child: Center(
              child: Text(
                'Kennel maps require a connection to the Internet',
                style: ts_headingLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width,
            height: 300,
            child: Center(
              child: agg.extensions.cityLat == null
                  ? const SizedBox()
                  : FlutterMap(
                      mapController: controller.mapController,
                      options: MapOptions(
                        initialCenter: latlng.LatLng(
                          agg.extensions.cityLat!,
                          agg.extensions.cityLon!,
                        ),
                        initialZoom: _sliderValue,
                        minZoom: 1.0,
                        maxZoom: 18.0,
                      ),
                      children: <Widget>[
                        TileLayer(
                          urlTemplate:
                              'http://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                          subdomains: const <String>[
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
                                agg.extensions.cityLat!,
                                agg.extensions.cityLon!,
                              ),
                              child: GestureDetector(
                                onTap: () async {
                                  if (agg.extensions.cityLat != null &&
                                      agg.extensions.cityLon != null) {
                                    final String? mapName = getStringPref(
                                      StringPrefsEnum.mapPreference,
                                    );
                                    if (mapName == null) {
                                      await Utilities.openMapsSheet(
                                        context,
                                        agg.kennel.kennelName,
                                        maps.Coords(
                                          agg.extensions.cityLat!.toDouble(),
                                          agg.extensions.cityLon!.toDouble(),
                                        ),
                                        '',
                                        // Pass a ValueNotifier wrapping the
                                        // observable for the sheet callback.
                                        _saveUserMapPreferenceNotifier,
                                      );
                                    } else {
                                      final List<maps.AvailableMap>
                                          availableMaps =
                                          await maps.MapLauncher.installedMaps;
                                      final maps.AvailableMap activeMap =
                                          availableMaps
                                              .where((maps.AvailableMap map) =>
                                                  map.mapName == mapName)
                                              .first;
                                      await activeMap.showMarker(
                                        coords: maps.Coords(
                                          agg.extensions.cityLat!.toDouble(),
                                          agg.extensions.cityLon!.toDouble(),
                                        ),
                                        title:
                                            activeMap.mapName.contains('Google')
                                                ? ''
                                                : agg.kennel.kennelName,
                                        description: agg.kennel.kennelName,
                                      );
                                    }
                                  }
                                },
                                child: Container(
                                  margin:
                                      const EdgeInsets.only(bottom: 110.0),
                                  child: Stack(
                                    alignment:
                                        AlignmentDirectional.topCenter,
                                    children: <Widget>[
                                      Image.asset(
                                        'images/icons/grey_square_pin.png',
                                      ),
                                      Positioned(
                                        top: 14,
                                        child: KennelLogo(
                                          kennelLogoUrl:
                                              agg.kennel.kennelLogo,
                                          kennelShortName:
                                              agg.kennel.kennelShortName,
                                          logoHeight: 60.0,
                                          leftPadding: 0.0,
                                          zoomGesture:
                                              KennelLogoZoomGesture.none,
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
                if (agg.extensions.cityLat != null) {
                  controller.mapController.move(
                    latlng.LatLng(
                      agg.extensions.cityLat!,
                      agg.extensions.cityLon!,
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
        _infoRow('Location:', agg.extensions.location ?? ''),
        _infoRow(
          'Last run:',
          agg.extensions.lastRunDate != null
              ? DateFormat('E, MMM d,  h:mm a').format(
                  DateTime.parse(
                      agg.extensions.lastRunDate!.substring(0, 19)))
              : '<no run found>',
        ),
        _infoRow(
          'Next run:',
          agg.extensions.nextRunDate != null
              ? DateFormat('E, MMM d,  h:mm a').format(
                  DateTime.parse(
                      agg.extensions.nextRunDate!.substring(0, 19)))
              : '<no run found>',
        ),
        _infoRow(
          'Hash cash:',
          agg.kennel.defaultPriceForMembers <= 0
              ? ''
              : '${IveCoreUtilities.getFormattedMoney(agg.kennel.defaultPriceForMembers, agg.extensions.digitsAfterDecimal ?? 2, agg.extensions.currencySymbol ?? r'$^')}    (members)',
        ),
        _infoRow(
          '',
          agg.kennel.defaultPriceForNonMembers <= 0
              ? ''
              : '${IveCoreUtilities.getFormattedMoney(agg.kennel.defaultPriceForNonMembers, agg.extensions.digitsAfterDecimal ?? 2, agg.extensions.currencySymbol ?? r'$^')}    (non-members)',
        ),

        // Mismanagement — reactive
        Obx(() {
          final mm = controller.mismanagement.value;
          final rawTeam =
              agg.kennel.kennelMismanagementTeam ?? '';
          if (mm == null ||
              rawTeam.trim().isEmpty ||
              rawTeam.toLowerCase().contains('none listed')) {
            return Container();
          }
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const FancyDivider(
                key: Key('55139201'),
                innerColor: Colors.white,
                topMargin: 30.0,
                bottomMargin: 10.0,
              ),
              for (String item in mm) _mmRow(item),
            ],
          );
        }),

        // Upcoming runs — reactive
        Obx(() {
          final runs = controller.allRuns;
          if (runs.isEmpty) return Container();
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const FancyDivider(
                key: Key('11344366'),
                innerColor: Colors.white,
                topMargin: 30.0,
                bottomMargin: 10.0,
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: Text(
                    runs.length == 1 ? 'Next run' : 'Next ${runs.length} runs',
                    style: ts_headingLarge,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              for (RunDetailsAggregate item in runs) _runRow(item),
              const SizedBox(height: 15.0),
            ],
          );
        }),

        const FancyDivider(
          key: Key('123435661'),
          innerColor: Colors.white,
          topMargin: 40.0,
          bottomMargin: 15.0,
        ),

        // QR / links toggle — reactive
        Obx(() {
          return Padding(
            padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              width: _buttonWidth,
              height: _buttonHeight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.only(
                      left: 12.0, top: 8.0, bottom: 8.0),
                ),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 45.0,
                      child: Stack(
                        alignment: AlignmentDirectional.center,
                        children: <Widget>[
                          Container(
                            height: 30,
                            width: 30,
                            decoration: BoxDecoration(
                              color: hc_blue,
                              shape: BoxShape.rectangle,
                            ),
                          ),
                          const Positioned(
                            child: Icon(
                              size: 20,
                              FontAwesome.qrcode,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 200,
                      padding: const EdgeInsets.only(left: 20, right: 0),
                      child: AutoSizeText(
                        controller.showShareQrs.value
                            ? 'Hide Links'
                            : 'Show ${agg.kennel.kennelShortName} Links',
                        style: ts_button,
                        textAlign: TextAlign.left,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                onPressed: () {
                  controller.showShareQrs.value =
                      !controller.showShareQrs.value;
                },
              ),
            ),
          );
        }),

        // QR codes panel — reactive
        Obx(() {
          if (!controller.showShareQrs.value) {
            return const SizedBox.shrink();
          }
          return Column(
            children: <Widget>[
              const SizedBox(height: 20),
              OverflowBar(
                spacing: 80,
                overflowSpacing: 40,
                alignment: MainAxisAlignment.center,
                overflowAlignment: OverflowBarAlignment.center,
                children: <Widget>[
                  QrGroup(
                    context: context,
                    title: 'Next ${agg.kennel.kennelShortName} Run',
                    description: 'next ${agg.kennel.kennelShortName} run',
                    url: controller.nextRunUrlForQr,
                    helpTitle: 'URL for Next Hash',
                    helpText:
                        "Want to know what's next for ${agg.kennel.kennelShortName}?\r\n\r\nThis link always points to the next ${agg.kennel.kennelShortName} Hash run — perfect for bookmarking or sharing with friends!",
                  ),
                  QrGroup(
                    context: context,
                    title: '${agg.kennel.kennelShortName} upcoming Runs',
                    description:
                        '${agg.kennel.kennelName} upcoming runs',
                    url: controller.kennelUrlForQr,
                    helpTitle:
                        'URL for upcoming ${agg.kennel.kennelShortName} runs',
                    helpText:
                        "This link opens a page with all upcoming ${agg.kennel.kennelShortName} runs.\r\n\r\nNavigate to this page and scroll down to see everything that's planned!",
                  ),
                  if (((agg.kennel.kennelWebsiteUrl ?? '').isNotEmpty) &&
                      (agg.kennel.kennelWebsiteUrl!
                          .toLowerCase()
                          .startsWith('http'))) ...<Widget>[
                    QrGroup(
                      context: context,
                      title: '${agg.kennel.kennelShortName} Website',
                      description:
                          '${agg.kennel.kennelShortName} Website',
                      url: agg.kennel.kennelWebsiteUrl!,
                      helpTitle:
                          '${agg.kennel.kennelShortName} Website',
                      helpText:
                          "This link takes you to the ${agg.kennel.kennelName} website — your go-to place for everything about Hashing with ${agg.kennel.kennelShortName}!",
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 40),
            ],
          );
        }),

        // Website button
        if (((agg.kennel.kennelWebsiteUrl ?? '').isNotEmpty) &&
            agg.kennel.kennelWebsiteUrl!.trim().isNotEmpty)
          Column(
            children: <Widget>[
              const FancyDivider(
                key: Key('123435662'),
                innerColor: Colors.white,
                topMargin: 15.0,
                bottomMargin: 30.0,
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                width: _buttonWidth,
                height: _buttonHeight,
                child: StyleForConnected(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.only(
                          left: 12.0, top: 8.0, bottom: 8.0),
                    ),
                    child: Row(
                      children: <Widget>[
                        SizedBox(
                          width: 45.0,
                          child: Stack(
                            alignment: AlignmentDirectional.center,
                            children: <Widget>[
                              Container(
                                height: 30,
                                width: 30,
                                decoration: BoxDecoration(
                                  color: hc_blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const Positioned(
                                child: Icon(
                                  size: 20,
                                  SimpleLineIcons.globe,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 20, right: 0),
                          child: Text('Open website', style: ts_button),
                        ),
                      ],
                    ),
                    onPressed: () async {
                      if (Utilities.isConnected(showDialog: true)) {
                        await launchUrl(
                          Uri.parse(agg.kennel.kennelWebsiteUrl!),
                          mode: LaunchMode.externalApplication,
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
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              width: _buttonWidth,
              height: _buttonHeight,
              child: StyleForConnected(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.only(
                        left: 12.0, top: 8.0, bottom: 8.0),
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
                        padding: const EdgeInsets.only(left: 20, right: 0),
                        child: Text('Run art gallery', style: ts_button),
                      ),
                    ],
                  ),
                  onPressed: () async {
                    final List<Map<String, dynamic>> results =
                        await QueryKennels.queryKennelGallery(
                      agg.kennel.kennelId,
                    );
                    if (!mounted) return;
                    await Navigator.push<void>(
                      navigatorKey.currentContext!,
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            HashRunArtGalleryPage(
                          key: const Key('52233311'),
                          items: results,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              width: _buttonWidth,
              height: _buttonHeight,
              child: StyleForConnected(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.only(
                        left: 12.0, top: 8.0, bottom: 8.0),
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
                        padding: const EdgeInsets.only(left: 20, right: 0),
                        child: Text('Leaderboards', style: ts_button),
                      ),
                    ],
                  ),
                  onPressed: () async {
                    if (!mounted) return;
                    await Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) => GenericWidgetPage(
                          key: const Key('52233311'),
                          widget: Leaderboard(
                            kennelId: agg.kennel.kennelId,
                          ),
                          appBarTitle: 'Get a Life (Leaderboards)',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Row helpers
  // ---------------------------------------------------------------------------
  Widget _infoRow(String label, String value) {
    return Row(
      children: <Widget>[
        const SizedBox(height: 25.0),
        Expanded(
          flex: _flexLeft,
          child: Text(
            label,
            style: ts_listLabelStyle,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: _flexRight,
          child: Text(
            '  $value',
            style: ts_listValueStyle,
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _mmRow(String s) {
    if (s.isEmpty) return Container();
    final List<String> items = s.split('\t');
    if (items.length < 2) return Container();
    return Row(
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

  Widget _runRow(RunDetailsAggregate s) {
    return RunListItem(
      futureRun: s,
      onItemTapped: () async {
        await Navigator.push<dynamic>(
          context,
          MaterialPageRoute<dynamic>(
            builder: (BuildContext context) => RunDetailsPage(futureRun: s),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Bridge: ValueNotifier wrapper so openMapsSheet can toggle saveUserMapPreference
  // ---------------------------------------------------------------------------
  late final ValueNotifier<bool> _saveUserMapPreferenceNotifier =
      _SyncedValueNotifier(controller.saveUserMapPreference);
}

/// A ValueNotifier whose value changes are forwarded to a GetX [RxBool] so
/// that [Utilities.openMapsSheet] (which expects a ValueNotifier) can still
/// update observable state on the controller.
class _SyncedValueNotifier extends ValueNotifier<bool> {
  _SyncedValueNotifier(this._rx) : super(_rx.value);

  final RxBool _rx;

  @override
  set value(bool newValue) {
    super.value = newValue;
    _rx.value = newValue;
  }
}
