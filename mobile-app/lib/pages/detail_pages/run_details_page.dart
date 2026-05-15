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
          _futureRun.extensions.appAccessFlags == 0
              ? Container()
              : IconButton(
                  icon: const Icon(FontAwesome.gear, color: Colors.white),
                  onPressed: () async {
                    final String eventId = _futureRun.event.eventId;
                    await Get.to(
                      () => RunAdminPage(eventId: eventId),
                      binding: BindingsBuilder(() {
                        Get.put(
                          RunAdminController(eventId: eventId),
                          tag: eventId,
                        );
                      }),
                    );

                    final refresh = widget.refreshPage;
                    if (refresh == null || !mounted) return;

                    setState(() => _isUpdating = true);

                    dynamic rda;
                    try {
                      rda = await Future<dynamic>.sync(refresh);
                    } catch (_) {
                      rda = null;
                    }

                    if (!mounted) return;
                    setState(() {
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
            ? Center(child: HcAppCircularProgressIndicator(key: UniqueKey()))
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
