import 'package:harrier_central/imports.dart';

class RunDetailsPage extends StatefulWidget {
  const RunDetailsPage({
    super.key,
    required this.futureRun,
    this.refreshPage,
    this.openToTab = RunTab.details,
  });

  final RunDetailsAggregate futureRun;
  final FutureOr<RunDetailsAggregate?> Function()? refreshPage;

  final RunTab openToTab;

  @override
  RunDetailsPageState createState() => RunDetailsPageState();
}

class RunDetailsPageState extends State<RunDetailsPage> {
  late RunDetailsAggregate _futureRun;

  /// True once the run has actually begun.
  ///
  /// A run that has not happened yet cannot have photos, so the photo-review
  /// doorway stays shut until the off. Compared as an INSTANT
  /// (eventStartDatetimeGmt), never the local wall clock — see
  /// /hc-event-datetimes; the raw EventStartDatetime carries a spurious
  /// +00:00 on most rows and would put runs hours out.
  bool get _runHasStarted => DateTime.now().toUtc().isAfter(
    _futureRun.event.eventStartDatetimeGmt.toUtc(),
  );

  @override
  void initState() {
    super.initState();
    _futureRun = widget.futureRun;
    // if (widget.openToChatTab) {}
  }

  @override
  void dispose() {
    //print('Run Details page disposed');
    super.dispose();
  }

  bool _isUpdating = false;
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () async {
            final navigator = Navigator.of(context);
            if (_activeTab == 4) {
              if (Get.isRegistered<NotificationService>()) {
                final controller = Get.find<NotificationService>();
                await controller.markEventMessagesAsViewed(
                  _futureRun.event.publicEventId,
                );
              }
            }
            //print('Run details popped');
            if (!mounted) return;
            navigator.pop(); // or Get.back();
          },
        ),
        actions: <Widget>[
          // Photos doorway — its own entry (derived), so a photo-only role
          // (e.g. Hash Flash) reaches per-run photo review without needing run
          // admin. Shown to anyone who can act in the photos area.
          (!_runHasStarted ||
                  !canEnterArea(
                    PermissionArea.photos,
                    appAccessFlags: _futureRun.extensions.appAccessFlags,
                    mismanagementRoles: _futureRun.extensions.mismanagementRoles,
                    kennelOverrideJson:
                        _futureRun.kennel.permissionOverrideJson,
                  ))
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.photo_library, color: Colors.white),
                  tooltip: 'Review Photos',
                  onPressed: () async {
                    if (Utilities.isConnected(showDialog: true)) {
                      await Get.to<void>(
                        () => PhotoReviewPage(
                          kennelId: _futureRun.kennel.kennelId,
                          eventId: _futureRun.event.eventId.asUuid,
                          eventName: _futureRun.event.eventName,
                          eventNumber: _futureRun.event.absoluteEventNumber,
                          kennelSlug: _futureRun.kennel.kennelUniqueShortName,
                          kennelLogoUrl: _futureRun.kennel.kennelLogo,
                          kennelShortName: _futureRun.kennel.kennelShortName,
                        ),
                      );
                    }
                  },
                ),
          // Show the admin gear only to users the server will actually let into
          // run admin (hcapp_syncEventAdminData) — the GM/VGM/RA/HashFlash/
          // HashCash/HashBank roles or the ManageRuns/ManageHashCash flags — OR a
          // designated hare of this run (run-scoped admin for their own run).
          // Mirrors the SP gate exactly; see /hc-authorizations.
          (!canEnterArea(
            PermissionArea.runAdmin,
            appAccessFlags: _futureRun.extensions.appAccessFlags,
            mismanagementRoles: _futureRun.extensions.mismanagementRoles,
            isHareOfEvent: _futureRun.extensions.isHare == 1,
            kennelOverrideJson: _futureRun.kennel.permissionOverrideJson,
          ))
              ? Container()
              : IconButton(
                  icon: const Icon(FontAwesome.gear, color: Colors.white),
                  onPressed: () async {
                    final String eventId = _futureRun.event.eventId;
                    await Get.to(
                      () => RunAdminPage(
                        eventId: eventId,
                        isHare: _futureRun.extensions.isHare == 1,
                      ),
                      binding: BindingsBuilder(() {
                        Get.put(
                          RunAdminController(eventId: eventId),
                          tag: eventId,
                        );
                      }),
                    );

                    final refresh = widget.refreshPage;
                    if (refresh == null || !mounted) return;

                    setStateIfMounted(() => _isUpdating = true);

                    dynamic rda;
                    try {
                      rda = await Future<dynamic>.sync(refresh);
                    } catch (_) {
                      rda = null;
                    }

                    if (!mounted) return;
                    setStateIfMounted(() {
                      if (rda != null) _futureRun = rda;
                      _isUpdating = false;
                    });
                  },
                ),
        ],
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
        title: Text('Run Details', style: ts_appBarTitle),
      ),
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        height: MediaQuery.sizeOf(context).height,
        child: _isUpdating
            ? const Center(child: HcAppCircularProgressIndicator())
            : RunTabs(
                futureRun: _futureRun,
                openToTab: widget.openToTab,
                relayActiveTab: (int activeTab) {
                  _activeTab = activeTab;
                },
              ),
      ),
    );
  }
}
