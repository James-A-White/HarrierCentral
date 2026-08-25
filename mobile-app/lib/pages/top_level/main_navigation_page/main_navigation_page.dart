import 'package:harrier_central/widgets/hc_badges.dart' as badges;
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:harrier_central/imports.dart';
import 'package:harrier_central/pages/top_level/drawer_menu.dart';

class MainNavigationPage extends StatelessWidget {
  const MainNavigationPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Instantiate and bind controller
    final controller = Get.isRegistered<MainNavigationController>()
        ? Get.find<MainNavigationController>()
        : Get.put(MainNavigationController(), permanent: true);

    final locService = Get.isRegistered<LocationService>()
        ? Get.find<LocationService>()
        : null;

    return GetBuilder<MainNavigationController>(
      id: 'AppScaffold',
      builder: (AppScaffoldController) {
        return Scaffold(
          key: controller.ScaffoldKey,
          backgroundColor: Colors.white,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(
              (controller.mainScreenContent.value == MainPageContent.appContent)
                  ? kToolbarHeight
                  : 0,
            ),
            child: Obx(() {
              return AppBar(
                elevation: 3.0,
                backgroundColor: themeAppBarBackground,
                iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
                automaticallyImplyLeading: false,
                leadingWidth: locService?.joinRunTracking.value ?? false
                    ? 140
                    : 80,
                leading: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () =>
                          controller.ScaffoldKey.currentState?.openDrawer(),
                    ),
                    controller.mainScreenReady.value
                        ? GetBuilder<FutureRunListPageController>(
                            id: 'main_nav_page',
                            builder: (badgeController) {
                              return GestureDetector(
                                onTap: () async {
                                  bool forceChatPage = getPage() != 0;
                                  if (forceChatPage ||
                                      (badgeController.runsToDisplay.value !=
                                          RunsToDisplay.unreadChats)) {
                                    badgeController.runsToDisplay.value =
                                        RunsToDisplay.unreadChats;
                                    badgeController.runsTimeScope.value =
                                        RunsTimeScope.all;
                                    // Refresh the unread-chat runs on entry so
                                    // the list isn't stale/empty under a
                                    // non-zero badge. Fire-and-forget: cached
                                    // rows show immediately, the fetch re-runs
                                    // the list UI when it lands.
                                    if (Get.isRegistered<NotificationService>()) {
                                      unawaited(Get.find<NotificationService>()
                                          .getEventChatMessageCounts());
                                    }
                                  } else {
                                    badgeController.runsToDisplay.value =
                                        RunsToDisplay.allRuns;
                                    badgeController.runsTimeScope.value =
                                        RunsTimeScope.future;
                                  }

                                  await setPage(0);
                                  await badgeController.refreshFromTable(true);

                                  // return badgeController
                                  //     .showOnlyEventsWithMessages
                                  //     .value = !(badgeController
                                  //     .showOnlyEventsWithMessages
                                  //     .value);
                                },
                                child: !Get.isRegistered<NotificationService>()
                                    ? SizedBox()
                                    : Obx(() {
                                        var totalChatCount =
                                            Get.find<NotificationService>()
                                                .globalTotalBadgeCount
                                                .value;

                                        return badges.Badge(
                                          position: badges.BadgePosition.topEnd(
                                            top: -10,
                                            end: -17,
                                          ),

                                          badgeContent: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 2,
                                            ),
                                            width: 30,
                                            height: 13,
                                            child: AutoSizeText(
                                              totalChatCount.toString(),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              minFontSize: 10,
                                              maxFontSize: 13,
                                              style: ts_badge,
                                            ),
                                          ),

                                          showBadge: totalChatCount != 0,
                                          child:
                                              // badgeController
                                              //     .showChatBubbleLoading
                                              //     .value
                                              // ? const Icon(Icons.refresh)
                                              // :
                                              const Icon(
                                                Icons.chat_bubble_outline,
                                              ),
                                        );
                                      }),
                              );
                            },
                          )
                        : SizedBox(),

                    controller.mainScreenReady.value
                        ? (!Get.isRegistered<LocationService>() ||
                                  !Get.find<LocationService>()
                                      .joinRunTracking
                                      .value)
                              ? SizedBox()
                              : GestureDetector(
                                  onTap: () async {
                                    var buttons = HashRunPointTypes.values.map((
                                      type,
                                    ) {
                                      return <String, dynamic>{
                                        'title': type.label,
                                        'icon': <Widget>[
                                          Container(
                                            height: 30,
                                            width: 45,
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade800,
                                              shape: BoxShape.rectangle,
                                            ),
                                          ),
                                          Icon(type.iconData),
                                        ],
                                        'returnValue': type.index,
                                      };
                                    }).toList();

                                    final MultipleChoicePopupHc popup =
                                        MultipleChoicePopupHc(
                                          key: const Key('5030202'),
                                          title: 'Trail mark',
                                          buttons: buttons,
                                          cancelButtonTitle: 'Cancel',
                                          cancelButtonReturnValue:
                                              followTypeCancel,
                                        );

                                    var result = await showDialog<dynamic>(
                                      context: context,
                                      barrierDismissible:
                                          false, // user must tap button!
                                      builder: (BuildContext context) {
                                        return popup;
                                      },
                                    );

                                    // Bail if canceled or invalid
                                    if (result == null ||
                                        result == followTypeCancel) {
                                      return;
                                    }
                                    if (result is! int ||
                                        result < 0 ||
                                        result >=
                                            HashRunPointTypes.values.length) {
                                      return;
                                    }

                                    HashRunPointTypes type =
                                        HashRunPointTypes.values[result];

                                    final locationService =
                                        Get.find<LocationService>();
                                    if (type == HashRunPointTypes.customLabel) {
                                      GetPointLabelPopup popup =
                                          GetPointLabelPopup();

                                      if (context.mounted) {
                                        var labelResult =
                                            await showDialog<
                                              Map<String, String>
                                            >(
                                              context: context,
                                              barrierDismissible:
                                                  false, // user must tap button!
                                              builder: (BuildContext context) {
                                                return popup;
                                              },
                                            );
                                        if (labelResult != null) {
                                          if ((labelResult['label'] ?? '')
                                              .isNotEmpty) {
                                            await locationService.markPoint(
                                              type,
                                              label: labelResult['label']!,
                                            );
                                          }
                                        }
                                      }
                                    } else {
                                      await locationService.markPoint(type);
                                    }

                                    // // Delay to ensure overlay is ready
                                    // await Future.delayed(
                                    //   const Duration(milliseconds: 100),
                                    // );

                                    Get.closeAllSnackbars();

                                    if (context.mounted) {
                                      // Use ScaffoldMessenger to avoid missing Overlay issues
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "You've marked a ${type.label}.",
                                            style: ts_snackbar,
                                            textAlign: TextAlign.center,
                                          ),
                                          duration: const Duration(seconds: 5),
                                          backgroundColor: Colors.blue,
                                          behavior: SnackBarBehavior.fixed,
                                          padding: const EdgeInsets.fromLTRB(
                                            16.0,
                                            12.0,
                                            16.0,
                                            kBottomNavigationBarHeight - 15.0,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Obx(() {
                                    final locationService =
                                        Get.find<LocationService>();

                                    // 2. Use the reactive getter to determine the state
                                    final isFresh =
                                        locationService.isLocationFresh;

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        left: 10.0,
                                        bottom: 2.0,
                                      ),
                                      child: Container(
                                        height: 25,
                                        width: 40,
                                        // Use the decoration property
                                        decoration: BoxDecoration(
                                          // Set the shape to circle
                                          borderRadius: BorderRadius.circular(
                                            7,
                                          ), // Rounded corners
                                          // Move the color property inside the decoration
                                          color: isFresh
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                        child: Center(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Text(
                                              locationService
                                                  .locationUpdateCount
                                                  .value
                                                  .toString(),
                                              style: ts_titleCondensed,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                )
                        : SizedBox.shrink(),
                  ],
                ),
                title: AutoSizeText(
                  controller.appBarText.value,
                  style: ts_appBarTitle,
                  maxLines: 1,
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner_sharp),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UserQrCodePage()),
                    ),
                  ),
                ],
              );
            }),
          ),
          body: Stack(
            children: [
              Container(
                decoration: Backgrounds.defaultHcBackground(),
                child: AndroidSafeArea(
                  child: Obx(() {
                    switch (controller.mainScreenContent.value) {
                      case MainPageContent.initial:
                        return const SizedBox.expand();

                      case MainPageContent.splashSequence:
                        return Obx(() {
                          return controller.isLoadingImages.value ||
                                  controller.splashImages.isEmpty
                              ? _SplashLoadingView(controller: controller)
                              : _SplashSequenceSlider(controller: controller);
                        });
                      case MainPageContent.loading:
                        return _getGenericLoadingScreen(controller);
                      default:
                        return Center(
                          child: controller.mainScreenReady.value
                              ? IndexedStack(
                                  index: controller.currentPage.value,
                                  children: [
                                    controller.futureRunsListPage,
                                    controller.kennelsListPage,
                                    controller.runAndKennelMapPage,
                                    controller.historyListPage,
                                    controller.songsPage,
                                  ],
                                )
                              : SizedBox(),
                        );
                    }
                  }),
                ),
              ),
              OfflineModeRibbon(
                lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSync),
                ribbonImage: 'images/icons/offline_mode.png',
                refreshFunction: () => controller.onInitAsync(),
              ),
            ],
          ),

          bottomNavigationBar: AndroidSafeArea(
            child: Obx(() {
              return (controller.mainScreenContent.value ==
                      MainPageContent.appContent)
                  ? CurvedNavigationBar(
                      key: controller.bottomNavigationKey,
                      backgroundColor: Colors.transparent,
                      color: const Color(0xFFF5E6EA),
                      buttonBackgroundColor: themeButtonColors,
                      animationDuration: const Duration(milliseconds: 300),
                      items: [
                        CurvedNavigationBarItem(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Icon(
                              MaterialCommunityIcons.run_fast,
                              color: controller.currentPage.value == 0
                                  ? Colors.white
                                  : themeBackgroundColor,
                            ),
                          ),
                          label: 'Runs',
                        ),
                        CurvedNavigationBarItem(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Icon(
                              FontAwesome.home,
                              color: controller.currentPage.value == 1
                                  ? Colors.white
                                  : themeBackgroundColor,
                            ),
                          ),
                          label: 'Kennels',
                        ),
                        CurvedNavigationBarItem(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Icon(
                              FontAwesome.map,
                              color: controller.currentPage.value == 2
                                  ? Colors.white
                                  : themeBackgroundColor,
                            ),
                          ),
                          label: 'Explore',
                        ),
                        CurvedNavigationBarItem(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Icon(
                              FontAwesome.list_ul,
                              color: controller.currentPage.value == 3
                                  ? Colors.white
                                  : themeBackgroundColor,
                            ),
                          ),
                          label: 'History',
                        ),
                        CurvedNavigationBarItem(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Icon(
                              Icons.music_note,
                              color: controller.currentPage.value == 4
                                  ? Colors.white
                                  : themeBackgroundColor,
                            ),
                          ),
                          label: 'Songs',
                        ),
                      ],
                      index: controller.currentPage.value,
                      onTap: (index) => controller.onTabChanged(index),
                    )
                  : SizedBox();
            }),
          ),
          //drawer: DrawerMenu(ScaffoldKey: controller.ScaffoldKey),
          drawer: DrawerMenu(key: Key('4312134')),
        );
      },
    );
  }

  int getPage() {
    final controller = Get.find<MainNavigationController>();
    return controller.currentPage.value;
  }

  Future<void> setPage(int page) async {
    final controller = Get.find<MainNavigationController>();

    controller.bottomNavigationKey.currentState?.setPage(0);

    final listController = Get.find<FutureRunListPageController>();

    // Re-tapping the runs tab returns to the most-relevant position — the
    // "Past Runs" divider / next run — not the very top (oldest past run).
    if (listController.itemScrollController.isAttached) {
      await listController.itemScrollController.scrollTo(
        index: listController.initialScrollIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Opens the interactive songbook for the RSVP'd event closest to now.
  /// Falls back to browse-only mode if no matching event is found.
  Widget _getGenericLoadingScreen(MainNavigationController controller) {
    return Stack(
      children: [
        Container(
          decoration: Backgrounds.defaultHcBackground(),
          height: Get.height,
          width: Get.width,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AvifImage.asset('images/init/on_on_in_a_sec.avif', height: 140),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Filling Your Mug',
                    style: ts_headingLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Image.asset(
                    'images/other/beer_pour.gif',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    controller.initializationMessage.value,
                    style: ts_headingLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Hand-rolled replacement for the retired `intro_slider` package's
/// "what's new" splash sequence: full-bleed promo images in a PageView
/// with indicator dots and a Prev/Next/Done row inside the existing
/// AndroidSafeArea (edge-to-edge safe by construction).
class _SplashSequenceSlider extends StatelessWidget {
  _SplashSequenceSlider({required this.controller});

  final MainNavigationController controller;
  final PageController _pageController = PageController();

  TextStyle get _navStyle => TextStyle(
        // White on the theme's red buttons (see CLAUDE.md button rule).
        color: Colors.white,
        // Clamped: the raw width factor balloons text on wide screens
        // (Fold) until it wraps inside the buttons.
        fontSize: 18.0 * deviceInfo.deviceWidthScaleFactor,
        fontFamily: 'AvenirNextDemiBold',
      );

  Future<void> _onDonePress() => controller.completeSplashSequence();

  Future<void> _goTo(int page) async {
    await _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final int count = controller.splashImages.length;
    return Obx(() {
      final int page = controller.splashPageIndex.value;
      final bool isLast = page >= count - 1;
      return Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: count,
            onPageChanged: (int i) => controller.splashPageIndex.value = i,
            itemBuilder: (BuildContext context, int i) => Stack(
              children: [
                controller.splashBackground ?? const SizedBox(),
                // BoxFit.contain: the promo art has transparent
                // backgrounds, so letterboxing is invisible and the full
                // height always fits — no cropping on wide screens (Fold).
                SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: controller.splashImages[i],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 10,
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: page > 0
                        ? TextButton(
                            onPressed: () => _goTo(page - 1),
                            child: Text('Prev', style: _navStyle),
                          )
                        : const SizedBox(),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(
                      count,
                      (int i) => Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: i == page
                              ? Colors.orange
                              : const Color.fromARGB(255, 120, 72, 0),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () async =>
                          isLast ? _onDonePress() : _goTo(page + 1),
                      child: Text(isLast ? 'Done' : 'Next', style: _navStyle),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

/// Shown while the version-promo slides download: the bundled copy of the
/// first slide appears instantly (identical art, so the swap to the live
/// deck is seamless) with a wait message — or a Continue escape hatch if
/// the download stalls or fails.
class _SplashLoadingView extends StatelessWidget {
  const _SplashLoadingView({required this.controller});

  final MainNavigationController controller;

  TextStyle get _navStyle => TextStyle(
        // White on the theme's red buttons (see CLAUDE.md button rule).
        color: Colors.white,
        fontSize: 18.0 * deviceInfo.deviceWidthScaleFactor,
        fontFamily: 'AvenirNextDemiBold',
      );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The bundled slide is only correct art for the 3.0 promo deck;
        // other sequences load over the standard background instead.
        if (controller.currentSplashRootName == 'version_3.0')
          SizedBox.expand(
            child: AvifImage.asset(
              'images/promo/version_3.0_1.avif',
              fit: BoxFit.contain,
            ),
          ),
        Positioned(
          left: 8,
          right: 8,
          bottom: 10,
          child: Obx(
            () => controller.splashLoadStalled.value
                ? Center(
                    child: TextButton(
                      // Abandon, not complete: a stalled download must not
                      // mark the promo viewed — it retries next launch.
                      onPressed: controller.abandonSplashSequence,
                      child: Text('Continue', style: _navStyle),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('Please wait while loading…', style: _navStyle),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
