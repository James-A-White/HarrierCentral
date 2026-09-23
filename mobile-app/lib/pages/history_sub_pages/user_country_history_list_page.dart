import 'package:harrier_central/imports.dart';

/// A hasher's runs in one country, with the My Runs / All Runs tab. Stateless
/// over [UserRunHistoryController] (country scope); the list itself is
/// [UserRunHistoryList], shared with the kennel page.
class UserCountryHistoryListPage extends StatelessWidget {
  const UserCountryHistoryListPage({
    super.key,
    required this.countryId,
    required this.countryName,
    required this.appDomain,
    this.hasherId,
    this.hashName,
  });

  final String countryId;
  final String countryName;
  final AppDomainType appDomain;
  final String? hasherId;
  final String? hashName;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<UserRunHistoryController>(
      init: UserRunHistoryController(
        appDomain: appDomain,
        hasherId: hasherId,
        countryId: countryId,
      ),
      tag: UserRunHistoryController.tagFor(
        countryId: countryId,
        hasherId: hasherId,
      ),
      builder: (UserRunHistoryController c) => Stack(
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
                  hashName ?? 'My runs for $countryName',
                  style: ts_appBarTitle,
                ),
              ),
              floatingActionButton: SpeedDial(
                animatedIcon: AnimatedIcons.menu_close,
                animatedIconTheme: const IconThemeData(size: 22.0),
                visible: true,
                curve: Curves.bounceIn,
                overlayColor: Colors.black,
                overlayOpacity: 0.5,
                onOpen: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
                tooltip: 'Speed Dial',
                heroTag: 'speed-dial-hero-tag-234234',
                backgroundColor:
                    Theme.of(context).buttonTheme.colorScheme?.primary ?? hc_red,
                foregroundColor: Colors.white,
                elevation: 8.0,
                shape: const CircleBorder(),
                children: <SpeedDialChild>[
                  SpeedDialChild(
                    child: const Icon(
                      MaterialCommunityIcons.email_plus,
                      color: Colors.white,
                    ),
                    backgroundColor: hc_blue,
                    label: 'Email run counts\r\n(all kennels)',
                    labelStyle: const TextStyle(fontSize: 18.0),
                    onTap: _emailAllKennels,
                  ),
                ],
              ),
              body: Obx(
                () => c.isLoading.value
                    ? const Center(
                        child: HcAppCircularProgressIndicator(
                          key: Key('88230302'),
                        ),
                      )
                    : _buildListView(context, c),
              ),
            ),
          ),
          OfflineModeRibbon(
            lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSync),
            ribbonImage: 'images/icons/offline_mode.png',
            refreshFunction: () => c.update(),
          ),
        ],
      ),
    );
  }

  Future<void> _emailAllKennels() async {
    final Future<Map<String, String>> sending = tableModel
        .hasherEventMapService
        .sendRunCountReportByEmail(
          kennelId: GUID_EMPTY,
          kennelName: 'All of your Hash Kennels',
        );
    if (navigatorKey.currentContext != null) {
      IveCoreUtilities.showInSnackBar(
        navigatorKey.currentContext!,
        'Run count report being processed...',
        durationInSeconds: 10,
      );
    }
    final Map<String, String> result = await sending;
    final BuildContext? ctx = navigatorKey.currentContext;
    // The context is fetched AFTER the await, which is the safe order; the
    // lint cannot see that navigatorKey.currentContext is fresh.
    // ignore: use_build_context_synchronously
    if (ctx != null) ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
    if ((result['result'] != null) &&
        (result['result']!.toLowerCase().startsWith('success'))) {
      await Utilities.showAlert(
        'E-mail successfully sent',
        'Your run count report has been successfully e-mailed to:\r\n\r\n${result['email']}\r\n\r\nIf you do not see it in the next few minutes, check your spam folder.',
        'OK',
      );
    }
  }

  Widget _buildListView(BuildContext context, UserRunHistoryController c) {
    final int tabIndex = c.tabIndex.value;
    return Container(
      decoration: Backgrounds.defaultHcBackgroundLight(),
      padding: const EdgeInsets.only(top: 0.0),
      child: RefreshIndicator(
        onRefresh: c.pullToRefresh,
        displacement: 130.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Container(
              width: 100,
              padding: const EdgeInsets.only(left: 60, right: 60, top: 0.0),
              child: DefaultTabController(
                length: 2,
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  width: 140.0,
                  height: 75.0,
                  // reviewed for 2.0+
                  child: TabBar(
                    labelStyle: ts_tabSelected,
                    unselectedLabelStyle: ts_tabUnselected,
                    isScrollable: false,
                    unselectedLabelColor: Colors.white,
                    labelColor: Colors.white,
                    labelPadding: const EdgeInsets.only(
                      top: 5,
                      left: 0,
                      right: 0,
                    ),
                    indicatorSize: TabBarIndicatorSize.label,
                    indicatorPadding: EdgeInsets.symmetric(
                      horizontal: -5.0,
                      vertical: 13.0,
                    ),
                    indicator: BoxDecoration(
                      color: hc_red,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    tabs: <Tab>[
                      Tab(
                        child: Container(
                          alignment: Alignment.center,
                          width: 120,
                          child: Text(
                            'My Runs',
                            style: ts_numberStyle.copyWith(
                              color: tabIndex == 0
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                      Tab(
                        child: Container(
                          alignment: Alignment.center,
                          width: 120,
                          child: Text(
                            'All Runs',
                            style: ts_numberStyle.copyWith(
                              color: tabIndex == 1
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                    controller: c.tabController,
                  ),
                ),
              ),
            ),
            Expanded(
              child: UserRunHistoryList(
                c: c,
                historicalHaringCount: 0,
                historicalTotalRunCount: 0,
                showCountry: false,
                showKennel: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
