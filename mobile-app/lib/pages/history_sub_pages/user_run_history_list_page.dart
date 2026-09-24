import 'package:harrier_central/imports.dart';

/// A hasher's runs for one kennel, with the kennel's header card and the
/// My Runs / All Runs tab. Stateless over [UserRunHistoryController]; the
/// list itself is [UserRunHistoryList], shared with the country page.
class UserRunHistoryListPage extends StatelessWidget {
  const UserRunHistoryListPage({
    super.key,
    required this.kennelInfo,
    required this.refreshKennelInfo,
    required this.appDomain,
    this.hasherId,
    this.hashName,
  });

  final RunHistoryModel kennelInfo;
  final Function refreshKennelInfo;
  final AppDomainType appDomain;
  final String? hasherId;
  final String? hashName;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<UserRunHistoryController>(
      init: UserRunHistoryController(
        appDomain: appDomain,
        hasherId: hasherId,
        kennelInfo: kennelInfo,
        refreshKennelInfo: refreshKennelInfo,
      ),
      tag: UserRunHistoryController.tagFor(
        kennelId: kennelInfo.kennelId,
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
                title: Obx(() {
                  // Read the Rx before the `??`: when hashName is set the
                  // right-hand side would never run, the Obx would observe
                  // nothing, and GetX throws "improper use" (build 1397).
                  final String shortName =
                      (c.kennel.value ?? kennelInfo).kennelShortName;
                  return Text(
                    hashName ?? 'My runs for $shortName',
                    style: ts_appBarTitle,
                  );
                }),
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
                heroTag: 'speed-dial-hero-tag-4312315',
                backgroundColor:
                    Theme.of(context).buttonTheme.colorScheme?.primary ??
                    hc_red,
                foregroundColor: Colors.white,
                elevation: 8.0,
                shape: const CircleBorder(),
                children: <SpeedDialChild>[
                  SpeedDialChild(
                    child: const Icon(
                      MaterialCommunityIcons.email,
                      color: Colors.white,
                    ),
                    backgroundColor: Colors.teal[800],
                    label: 'Email run counts\r\n(this kennel)',
                    labelStyle: const TextStyle(fontSize: 18.0),
                    onTap: () => _emailRunCounts(
                      kennelId: (c.kennel.value ?? kennelInfo).kennelId,
                      kennelName: (c.kennel.value ?? kennelInfo).kennelName,
                    ),
                  ),
                  SpeedDialChild(
                    child: const Icon(
                      MaterialCommunityIcons.email_plus,
                      color: Colors.white,
                    ),
                    backgroundColor: hc_blue,
                    label: 'Email run counts\r\n(all kennels)',
                    labelStyle: const TextStyle(fontSize: 18.0),
                    onTap: () => _emailRunCounts(
                      kennelId: GUID_EMPTY,
                      kennelName: 'All of your Hash Kennels',
                    ),
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

  Future<void> _emailRunCounts({
    required String kennelId,
    required String kennelName,
  }) async {
    final Future<Map<String, String>> sending = tableModel.hasherEventMapService
        .sendRunCountReportByEmail(kennelId: kennelId, kennelName: kennelName);
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
    final RunHistoryModel k = c.kennel.value ?? kennelInfo;
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
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Color.fromARGB(70, 0, 0, 0),
                    offset: Offset(0.0, 6.0),
                    blurRadius: 10.0,
                  ),
                ],
              ),
              padding: const EdgeInsets.only(
                left: 5,
                top: 5,
                right: 0,
                bottom: 5,
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.only(right: 12.0),
                    height: 90,
                    child: KennelLogo(
                      kennelId: k.kennelId,
                      kennelLogoUrl: k.kennelLogo,
                      kennelShortName: k.kennelShortName,
                      logoHeight: 60.0 * deviceInfo.deviceWidthScaleFactor,
                      leftPadding: 5.0,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        AutoSizeText(
                          k.kennelName,
                          overflow: TextOverflow.ellipsis,
                          minFontSize: 18.0,
                          maxLines: 1,
                          style: ts_boldTitleStyle,
                          textAlign: TextAlign.left,
                        ),
                        AutoSizeText(
                          'My verified run count: ${k.hcRunsThisKennel}',
                          overflow: TextOverflow.ellipsis,
                          minFontSize: 12.0,
                          maxLines: 1,
                          style: ts_numberStyle,
                          textAlign: TextAlign.center,
                        ),
                        AutoSizeText(
                          'My verified haring count: ${k.hcHaringThisKennel}',
                          overflow: TextOverflow.ellipsis,
                          minFontSize: 12.0,
                          maxLines: 1,
                          style: ts_numberStyle,
                          textAlign: TextAlign.center,
                        ),
                        AutoSizeText(
                          'Kennel credit: ${IveCoreUtilities.getFormattedMoney(k.kennelCredit, kennelInfo.digitsAfterDecimal, kennelInfo.currencySymbol)}',
                          overflow: TextOverflow.ellipsis,
                          minFontSize: 12.0,
                          maxLines: 1,
                          style: ts_numberStyle,
                          textAlign: TextAlign.center,
                        ),
                        if (k.historicalTotalRunCount != 0) ...<Widget>[
                          AutoSizeText(
                            'Historical run count: ${k.historicalCountIsEstimate != 0 ? '~' : ''}${k.historicalTotalRunCount}',
                            overflow: TextOverflow.ellipsis,
                            minFontSize: 18.0,
                            maxLines: 1,
                            style: ts_numberStyle,
                            textAlign: TextAlign.center,
                          ),
                          AutoSizeText(
                            'Historical haring count ${k.historicalCountIsEstimate != 0 ? '~' : ''}${k.historicalHaringCount}',
                            overflow: TextOverflow.ellipsis,
                            minFontSize: 18.0,
                            maxLines: 1,
                            style: ts_numberStyle,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 100,
              padding: const EdgeInsets.only(left: 60, right: 60, top: 0.0),
              child: DefaultTabController(
                length: 2,
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  width: 140.0,
                  height: 70.0,
                  // reviewed for 2.0+
                  child: TabBar(
                    labelStyle: ts_tabSelected,
                    unselectedLabelStyle: ts_tabUnselected,
                    isScrollable: false,
                    unselectedLabelColor: Colors.white,
                    labelColor: Colors.white,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelPadding: const EdgeInsets.only(
                      top: 5,
                      left: 0,
                      right: 0,
                    ),
                    indicatorPadding: EdgeInsetsGeometry.only(
                      top: 10,
                      bottom: 10,
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
                historicalHaringCount: k.historicalHaringCount,
                historicalTotalRunCount: k.historicalTotalRunCount,
                showCountry: c.countryCount.value > 1,
                showKennel: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
