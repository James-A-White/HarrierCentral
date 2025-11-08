import 'package:badges/badges.dart' as badges;
import 'package:fancy_bottom_navigation_2/fancy_bottom_navigation.dart';
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
              if (controller.mainScreenContent.value == MainPageContent.help) {
                return SizedBox.shrink();
              }
              return AppBar(
                elevation: 3.0,
                backgroundColor: themeAppBarBackground,
                iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
                leadingWidth: 90,
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
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
                                onTap: () {
                                  bool forceChatPage = getPage() != 0;
                                  if (forceChatPage ||
                                      (badgeController.runsToDisplay.value !=
                                          RunsToDisplay.unreadChats)) {
                                    badgeController.runsToDisplay.value =
                                        RunsToDisplay.unreadChats;
                                    badgeController.runsTimeScope.value =
                                        RunsTimeScope.all;
                                  } else {
                                    badgeController.runsToDisplay.value =
                                        RunsToDisplay.allRuns;
                                    badgeController.runsTimeScope.value =
                                        RunsTimeScope.future;
                                  }

                                  setPage(0);

                                  // return badgeController
                                  //     .showOnlyEventsWithMessages
                                  //     .value = !(badgeController
                                  //     .showOnlyEventsWithMessages
                                  //     .value);
                                },
                                child: badges.Badge(
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
                                      badgeController.totalNotifications.value
                                          .toString(),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      minFontSize: 10,
                                      maxFontSize: 13,
                                      style: ts_badge,
                                    ),
                                  ),

                                  showBadge:
                                      badgeController
                                          .totalNotifications
                                          .value !=
                                      0,
                                  child:
                                      // badgeController
                                      //     .showChatBubbleLoading
                                      //     .value
                                      // ? const Icon(Icons.refresh)
                                      // :
                                      const Icon(Icons.chat_bubble_outline),
                                ),
                              );
                            },
                          )
                        : SizedBox(),
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
                  IconButton(
                    icon: Icon(
                      controller.isFlipped.value
                          ? Icons.undo
                          : Icons.info_outline,
                    ),
                    onPressed: controller.toggleFlip,
                  ),
                ],
              );
            }),
          ),
          floatingActionButton: Obx(() {
            if (!controller.isFlipped.value) {
              if (controller.currentPage.value == 2) {
                return controller.runAndKennelMapPageKey.currentState
                        ?.getMapFab() ??
                    SizedBox();
              }
              if (controller.currentPage.value == 1) {
                return controller.kennelLocationsPageKey.currentState
                        ?.getKennelFab() ??
                    SizedBox();
              }
            }
            return SizedBox();
          }),

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
                          return controller.isLoadingImages.value
                              ? Center(child: CircularProgressIndicator())
                              : IntroSlider(
                                  isShowSkipBtn: false,
                                  isShowPrevBtn: true,

                                  indicatorConfig: IndicatorConfig(
                                    sizeIndicator: 10,
                                    indicatorWidget: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        color: const Color.fromARGB(
                                          255,
                                          120,
                                          72,
                                          0,
                                        ),
                                      ),
                                    ),
                                    activeIndicatorWidget: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        color: Colors.orange,
                                      ),
                                    ),
                                    spaceBetweenIndicator: 10,
                                    typeIndicatorAnimation:
                                        TypeIndicatorAnimation.sliding,
                                  ),

                                  // wrap each Image in a full-screen box, with BoxFit.cover
                                  listCustomTabs: controller.splashImages.map((
                                    img,
                                  ) {
                                    return Stack(
                                      children: [
                                        controller.splashBackground ??
                                            SizedBox(),
                                        SizedBox.expand(
                                          child: FittedBox(
                                            fit: BoxFit.cover,
                                            child:
                                                img, // your pre-cached Image widget
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                  onDonePress: () async {
                                    // once the Done button is pressed, we now consider this a normal boot
                                    await setStringPref(
                                      StringPrefsEnum.bootType,
                                      BOOT_TYPE_NORMAL,
                                    );

                                    if (Get.isRegistered<
                                      NotificationService
                                    >()) {
                                      await Get.delete<NotificationService>();
                                    }

                                    await Get.putAsync(
                                      () => NotificationService().init(),
                                    ); // Initialize and wait for the notification service

                                    controller.resetNewVersionPromoScreen();
                                  },
                                );
                        });
                      case MainPageContent.loading:
                        return _getGenericLoadingScreen(controller);
                      default:
                        return FlippableBox(
                          key: Key('22342342'),
                          front: Center(
                            child: controller.mainScreenReady.value
                                ? IndexedStack(
                                    index: controller.currentPage.value,
                                    children: [
                                      controller.futureRunsListPage,
                                      controller.kennelsListPage,
                                      controller.runAndKennelMapPage,
                                      controller.historyListPage,
                                    ],
                                  )
                                : SizedBox(),
                          ),

                          back: Swiper(
                            pagination: SwiperCustomPagination(
                              builder:
                                  (
                                    BuildContext context,
                                    SwiperPluginConfig config,
                                  ) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.max,
                                      children: <Widget>[
                                        Expanded(child: Container()),
                                        Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: Align(
                                                alignment:
                                                    Alignment.bottomCenter,
                                                child:
                                                    DotSwiperPaginationBuilder(
                                                      color: Colors.grey,
                                                      activeColor: hc_blue,
                                                      size: 10.0,
                                                      activeSize: 20.0,
                                                    ).build(context, config),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20.0),
                                      ],
                                    );
                                  },
                            ),
                            itemCount: controller
                                .tutorials[controller.currentPage.value]
                                .length,
                            control: SwiperControl(
                              color: hc_red,
                              disableColor: hc_blue,
                            ),
                            itemBuilder: (BuildContext context, int index) {
                              // this configuration of LayoutBuilder is used to center images that do not
                              // overflow the height of the available render area, but align images
                              // to the top of the render space if they will overflow the available space.
                              return LayoutBuilder(
                                builder:
                                    (
                                      BuildContext context,
                                      BoxConstraints constraints,
                                    ) {
                                      return Stack(
                                        clipBehavior: Clip.hardEdge,
                                        fit: StackFit.passthrough,
                                        alignment:
                                            AlignmentDirectional.topCenter,
                                        children: <Widget>[
                                          Positioned(
                                            top: 15.0,
                                            left: 0.0,
                                            right: 0.0,
                                            child: Column(
                                              children: <Widget>[
                                                ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                    minHeight:
                                                        constraints.maxHeight >
                                                            60
                                                        ? constraints
                                                                  .maxHeight -
                                                              60
                                                        : constraints.maxHeight,
                                                  ),
                                                  child: Image.asset(
                                                    controller
                                                        .tutorials[controller
                                                        .currentPage
                                                        .value][index],
                                                    fit: BoxFit.fitWidth,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 0.0,
                                            left: 0.0,
                                            right: 0.0,
                                            child: Container(
                                              height: 60.0,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                              );
                            },
                          ),

                          isFlipped: controller.isFlipped.value,
                        );
                    }
                  }),
                ),
              ),
              OfflineModeRibbon(
                lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSync),
                ribbonImage: 'images/icons/offline_mode.png',
                refreshFunction: () => controller.initialize(),
              ),
            ],
          ),

          bottomNavigationBar: AndroidSafeArea(
            child: Obx(() {
              return (controller.mainScreenContent.value ==
                      MainPageContent.appContent)
                  ? FancyBottomNavigation(
                      key: controller.bottomNavigationKey,
                      circleColor: themeButtonColors,
                      inactiveIconColor: themeBackgroundColor,
                      barBackgroundColor: themeNavBarBackground,
                      tabs: [
                        TabData(
                          iconData: MaterialCommunityIcons.run_fast,
                          title: 'Runs',
                        ),
                        TabData(iconData: FontAwesome.home, title: 'Kennels'),
                        TabData(iconData: FontAwesome.map, title: 'Explore'),
                        TabData(
                          iconData: FontAwesome.list_ul,
                          title: 'History',
                        ),
                      ],
                      initialSelection: 0,
                      //key: controller.bottomNavigationKey,
                      onTabChangedListener: controller.onTabChanged,
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
    return controller.bottomNavigationKey.currentState?.currentSelected ?? -1;
  }

  void setPage(int page) {
    final controller = Get.find<MainNavigationController>();

    controller.bottomNavigationKey.currentState?.setPage(0);

    final listController = Get.find<FutureRunListPageController>();

    listController.scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Container _getGenericLoadingScreen(MainNavigationController controller) {
    return Container(
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
                // height: 250,
                // width: 250,
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
    );
  }
}
