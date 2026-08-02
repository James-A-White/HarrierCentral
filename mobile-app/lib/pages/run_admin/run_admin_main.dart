import 'package:harrier_central/imports.dart';
import 'package:harrier_central/pages/run_admin/hash_trash_page.dart';
import 'package:harrier_central/pages/run_admin/down_downs_page.dart';

class RunAdminAggregate {
  RunAdminAggregate({
    required this.event,
    required this.extensions,
    required this.kennel,
  });

  final RunDetailQueryExtensions extensions;
  EventModel event;
  final KennelsModel kennel;
}

class RunDetailQueryExtensions {
  RunDetailQueryExtensions({
    required this.appAccessFlags,
    required this.mismanagementRoles,
    required this.digAfterDec,
    required this.curSym,
    required this.curCode,
    required this.memberPrice,
    required this.nonMemberPrice,
    required this.kenlLat,
    required this.kenlLon,
    this.latitude,
    this.longitude,
    this.distancePreference,
    this.distToEvent,
    this.isMapAndDistanceValid,
    this.paymentAmountStr,
    this.paymentUrl,
  });

  final int appAccessFlags;
  final int mismanagementRoles;
  final int digAfterDec;
  final String curSym;
  final String curCode;
  final double memberPrice;
  final double nonMemberPrice;
  final double kenlLat;
  final double kenlLon;
  String? paymentUrl;
  double? distToEvent;
  int? distancePreference;
  double? latitude;
  double? longitude;
  bool? isMapAndDistanceValid;
  String? paymentAmountStr;

  bool isLoading = false;

  static RunDetailQueryExtensions fromMap(Map<String, dynamic> map) {
    return RunDetailQueryExtensions(
      appAccessFlags: map['appAccessFlags'],
      mismanagementRoles: map['mismanagementRoles'],
      digAfterDec: map['digAfterDec'],
      curSym: map['curSym'],
      curCode: map['curCode'],
      memberPrice: map['memberPrice'].toDouble(),
      nonMemberPrice: map['nonMemberPrice'].toDouble(),
      kenlLat: map['kenlLat'].toDouble(),
      kenlLon: map['kenlLon'].toDouble(),
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
    );
  }

  Mismanagement get mismanagement => Mismanagement(mismanagementRoles);
  AppAccess get appAccess => AppAccess(appAccessFlags);
}

class RunAdminPage extends StatelessWidget {
  const RunAdminPage({super.key, required this.eventId, this.isHare = false});

  final String eventId;

  /// True when the current user is a designated hare of THIS run. A hare with no
  /// admin flags still sees this screen, showing only the run-scoped functions
  /// (edit run, receipts, check-in, print QR, take payment) for their own run.
  final bool isHare;

  @override
  Widget build(BuildContext context) {
    final RunAdminController controller = Get.put(
      RunAdminController(eventId: eventId),
      tag: eventId,
    );

    return AppScaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
        title: Text('Run Admin', style: ts_appBarTitle),
      ),
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        height: MediaQuery.sizeOf(context).height,
        width: MediaQuery.sizeOf(context).width,
        padding: const EdgeInsets.only(left: 20, right: 20),
        child: AndroidSafeArea(
          child: ConnectedWidget(
            refreshFunction: controller.getRunDetails,
            showConnectButton: true,
            disconnectedChild: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Text(
                  'Run admin functions require a connection to the Internet',
                  style: ts_headingLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            child: Obx(() {
              if (controller.isLoading.value) {
                return const HcAppCircularProgressIndicator(
                  key: Key('16093026'),
                );
              }
              final aggregate = controller.eventAggregate.value;
              if (aggregate == null) return Container();
              return SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 20),
                      child: AutoSizeText(
                        aggregate.event.eventName,
                        style: ts_titleLarge,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ),
                    const FancyDivider(
                      key: Key('66103920'),
                      innerColor: Colors.white,
                      topMargin: 20.0,
                      bottomMargin: 5.0,
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const double spacing = 12.0;
                        final double btnSize =
                            (constraints.maxWidth - 2 * spacing) / 3;
                        return TextScaleFactorClamper(
                          textScaleFactor: deviceInfo.textClamp15,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _buildSections(
                              context,
                              controller,
                              aggregate,
                              btnSize,
                              spacing,
                              isHare,
                            ),
                          ),
                        );
                      },
                    ),
                    const FancyDivider(
                      key: Key('669190022'),
                      innerColor: Colors.white,
                      topMargin: 35.0,
                      bottomMargin: 5.0,
                    ),
                    RunDetails(
                      aggregate.event,
                      aggregate.kennel,
                      aggregate.extensions.digAfterDec,
                      aggregate.extensions.curSym,
                      aggregate.extensions.distancePreference ?? 0,
                      aggregate.extensions.distToEvent,
                      aggregate.extensions.paymentUrl ?? '',
                      false,
                      aggregate.extensions.isMapAndDistanceValid ?? false,
                      eventUrlWithKennelBackup:
                          aggregate.event.eventUrl ??
                          aggregate.kennel.kennelEventsUrl,
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSections(
    BuildContext context,
    RunAdminController controller,
    RunAdminAggregate aggregate,
    double btnSize,
    double spacing,
    bool isHare,
  ) {
    // Permission gating mirrors the server (HC6.CheckKennelPermission): a button
    // shows when the user's mismanagement ROLE or app-access FLAG grants the
    // feature (or they're super-admin). See /hc-authorizations.
    final int aaFlags = aggregate.extensions.appAccessFlags;
    final int mmFlags = aggregate.extensions.mismanagementRoles;
    bool can(KennelFeature f) => canAccessFeature(
      f,
      appAccessFlags: aaFlags,
      mismanagementRoles: mmFlags,
      isHareOfEvent: isHare,
      kennelOverrideJson: aggregate.kennel.permissionOverrideJson,
    );

    // ── On the Day ──────────────────────────────────────────────────
    final dayButtons = <Widget>[
      if (can(KennelFeature.manageAttendance)) ...<Widget>[
        _buildButton(
          label: 'Manual\r\ncheck in',
          iconAsset: 'images/icons/check_in_pack_icon.png',
          size: btnSize,
          onPressed: () async {
            await Get.to(
              () => CheckInPackPage(controllerTag: aggregate.event.eventId),
              binding: BindingsBuilder(() {
                Get.put(
                  CheckInPackController(aggregate),
                  tag: aggregate.event.eventId,
                  permanent: false,
                );
              }),
            );
            unawaited(
              tableModel.syncUserDataService.updateFromBackend(
                EnumDataTables.hashers.flag,
                false,
                debugText: 'RunAdmin: sync hashers on check-in page exit',
              ),
            );
          },
        ),
        _buildButton(
          label: 'Scan to\r\ncheck in',
          iconAsset: 'images/icons/qr_scanner_phone_icon.png',
          size: btnSize,
          onPressed: () async {
            await Navigator.push<dynamic>(
              context,
              MaterialPageRoute<dynamic>(
                builder: (BuildContext context) =>
                    CheckInScannerPage(eventAggregate: aggregate),
              ),
            );
          },
        ),
      ],
    ];

    if (can(KennelFeature.viewPaymentReport)) {
      dayButtons.add(
        _buildButton(
          label: 'Hash\r\ncash',
          iconAsset: 'images/icons/hash_cash_icon.png',
          size: btnSize,
          onPressed: () async {
            await Navigator.push<dynamic>(
              context,
              MaterialPageRoute<dynamic>(
                builder: (BuildContext context) =>
                    PaymentReportPage(eventAggregate: aggregate),
              ),
            );
          },
        ),
      );
    }

    if (can(KennelFeature.awardList)) {
      dayButtons.add(
        _buildButton(
          label: 'Award\r\nlist',
          iconAsset: 'images/icons/run_awards.png',
          size: btnSize,
          onPressed: () async {
            await Navigator.push<dynamic>(
              context,
              MaterialPageRoute<dynamic>(
                builder: (BuildContext context) =>
                    DrinksList(eventAggregate: aggregate),
              ),
            );
          },
        ),
      );
    }

    if (can(KennelFeature.manageDownDowns)) {
      dayButtons.add(
        _buildButton(
          label: 'Down\r\nDowns',
          iconAsset: 'images/icons/beer_mug.png',
          size: btnSize,
          onPressed: () async {
            if (Utilities.isConnected(showDialog: true)) {
              await Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => DownDownsPage(
                    kennelId: aggregate.kennel.kennelId,
                    eventId: aggregate.event.eventId,
                    eventName: aggregate.event.eventName,
                    kennelSlug: aggregate.kennel.kennelUniqueShortName,
                    eventNumber: aggregate.event.absoluteEventNumber ?? 0,
                  ),
                ),
              );
            }
          },
        ),
      );
    }

    // ── Before the Off ──────────────────────────────────────────────
    final planButtons = <Widget>[];

    // Edit run details goes first so it sits on the far left of the row.
    if (can(KennelFeature.createEditRuns)) {
      planButtons.add(
        _buildButton(
          label: 'Edit run\r\ndetails',
          iconAsset: 'images/icons/edit_run_icon.png',
          size: btnSize,
          onPressed: () async {
            await Navigator.push<dynamic>(
              context,
              MaterialPageRoute<dynamic>(
                builder: (BuildContext context) =>
                    EditRunDetailsPage(false, aggregate),
              ),
            );
          },
        ),
      );
    }

    if (can(KennelFeature.manageReceipts)) {
      planButtons.add(
        _buildButton(
          label: 'Manage\r\nreceipts',
          iconAsset: 'images/icons/receipt_icon.png',
          size: btnSize,
          onPressed: () async {
            await Navigator.push<dynamic>(
              context,
              MaterialPageRoute<dynamic>(
                builder: (BuildContext context) =>
                    ReceiptsList(eventAggregate: aggregate),
              ),
            );
          },
        ),
      );
    }

    if (can(KennelFeature.printQrCodes)) {
      planButtons.add(
        _buildButton(
          label: 'Print QR\r\ncodes',
          iconAsset: 'images/icons/print_qr_icon.png',
          size: btnSize,
          onPressed: () async {
            await Navigator.push<dynamic>(
              context,
              MaterialPageRoute<dynamic>(
                builder: (BuildContext context) => EventQrCodePage(
                  kennelShortName: aggregate.kennel.kennelShortName,
                  qrContent: aggregate.event.publicEventId,
                  title: aggregate.event.eventName,
                  runStartPrefix: QR_PREFIX_SPECIFIC_RUN_START,
                  runEndPrefix: QR_PREFIX_SPECIFIC_RUN_END,
                  runLink: QR_PREFIX_HASHRUNS_DOT_ORG_RUN_LINK,
                  showRunLink: true,
                  eventStartDatetime: aggregate.event.eventStartDatetime,
                  kennelWebsiteUrl: aggregate.kennel.kennelWebsiteUrl,
                ),
              ),
            );
          },
        ),
      );
    }

    // ── The Write-Up ────────────────────────────────────────────────
    final writeUpButtons = <Widget>[];

    if (can(KennelFeature.reviewPhotos)) {
      writeUpButtons.add(
        _buildButton(
          label: 'Review\r\nPhotos',
          iconAsset: 'images/icons/android_camera.png',
          size: btnSize,
          onPressed: () async {
            if (Utilities.isConnected(showDialog: true)) {
              await Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => PhotoReviewPage(
                    kennelId: aggregate.kennel.kennelId,
                    eventId: aggregate.event.eventId.asUuid,
                    eventName: aggregate.event.eventName,
                    eventNumber: aggregate.event.absoluteEventNumber,
                    kennelSlug: aggregate.kennel.kennelUniqueShortName,
                    kennelLogoUrl: aggregate.kennel.kennelLogo,
                    kennelShortName: aggregate.kennel.kennelShortName,
                  ),
                ),
              );
            }
          },
        ),
      );
    }

    if (can(KennelFeature.writeHashTrash)) {
      writeUpButtons.add(
        _buildButton(
          label: 'Hash\r\nTrash',
          iconAsset: 'images/icons/pencil.png',
          size: btnSize,
          onPressed: () async {
            if (Utilities.isConnected(showDialog: true)) {
              await Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => HashTrashPage(
                    kennelId: aggregate.kennel.kennelId,
                    eventId: aggregate.event.eventId,
                    eventName: aggregate.event.eventName,
                  ),
                ),
              );
            }
          },
        ),
      );
    }

    return [
      _buildSection('On the Day', dayButtons, spacing),
      if (planButtons.isNotEmpty)
        _buildSection('Before On Out', planButtons, spacing),
      if (writeUpButtons.isNotEmpty)
        _buildSection('The Write-Up', writeUpButtons, spacing),
      const SizedBox(height: 8),
    ];
  }

  Widget _buildSection(String title, List<Widget> buttons, double spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 2),
          child: Text(title, style: ts_heading),
        ),
        // Center wrapping so a section that fits in one row (e.g. two buttons)
        // is centered rather than left-aligned. A Wrap only takes the full width
        // once its children wrap to multiple rows; for a single row it shrinks to
        // its content width, so WrapAlignment.center alone can't centre it —
        // hence the surrounding Center to pull it into the middle. Multi-row
        // sections are already full width, so Center is a no-op there and
        // WrapAlignment.center still centres the final partial row.
        Center(
          child: Wrap(
            spacing: spacing,
            runSpacing: 0,
            alignment: WrapAlignment.center,
            children: buttons,
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required String label,
    required String iconAsset,
    required double size,
    required VoidCallback onPressed,
  }) {
    final double iconSize = size * 0.48;
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: SizedBox(
        width: size,
        height: size,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.only(top: 2.0, left: 0.0, bottom: 0.0),
          ),
          onPressed: onPressed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Image.asset(
                  iconAsset,
                  height: iconSize,
                  width: iconSize,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                child: Text(
                  label,
                  style: ts_buttonLabelSmallCompressedLines,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
