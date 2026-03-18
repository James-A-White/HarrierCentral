// ignore_for_file: constant_identifier_names, avoid_web_libraries_in_flutter

import 'package:badges/badges.dart' as badges;
import 'package:hcportal/admin_pages/checkin_sheet/checkin_sheet_ui.dart';
import 'package:hcportal/admin_pages/kennel_page_new/kennel_page_new_ui.dart';
import 'package:hcportal/admin_pages/run_list_page_controller.dart';
import 'package:hcportal/imports.dart';
import 'package:hcportal/models/email/email_model.dart';
import 'package:hcportal/widgets/run_list_item.dart';

@JS()
external JSObject get globalThis; // Access JavaScript global context

@JS('window.open')
external JSObject? openWindow(String url, String target);

const String TEXT_PAST_RUNS = 'Past runs';
const String TEXT_FUTURE_RUNS = 'Future runs';

const String TEXT_ONE_MONTH = 'One month';
const String TEXT_SIX_MONTHS = 'Six months';
const String TEXT_ONE_YEAR = 'One year';
const String TEXT_ALL_RUNS_EVENTS = 'All runs / events';

final FocusNode _searchFocusNode = FocusNode();
final TextEditingController _searchController = TextEditingController();

class RunListPage extends StatelessWidget {
  RunListPage(
    this.kennel, {
    this.backgroundColor,
    this.textTheme,
    super.key,
  }) : formController = Get.put(
          RunListPageController(
            kennel,
            backgroundColor: backgroundColor ?? 'e0e0e0',
            textTheme: textTheme ?? 'dark',
          ),
        );
  final String? backgroundColor;
  final String? textTheme;
  final HasherKennelsModel kennel;

  final RunListPageController formController;

  final ScrollController _listScrollController = ScrollController();
  final ScrollController _scrollController3 = ScrollController();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        formController.updateSizeWithDebounce(
          constraints.maxWidth,
          constraints.maxHeight,
        );

        return Scaffold(
          appBar: AppBar(
            title:
                Text('Runs and Events for ${formController.kennel.kennelName}'),
            leading: GestureDetector(
              onTap: () {
                Get.back<void>();
              },
              child: const Icon(
                MaterialCommunityIcons.arrow_left,
                color: Colors.black,
              ),
            ),
          ),
          backgroundColor: HexColor(formController.backgroundColor),
          body: Obx(
            () => (formController.allEvents.isEmpty &&
                    formController.allEventsDetails.isEmpty)
                ? Center(
                    child: formController.isLoaded.value
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'No runs found for this Kennel',
                                style: TextStyle(
                                  fontSize: 36,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                              const SizedBox(height: 30),
                              ElevatedButton(
                                //style: ButtonStyle(shadowColor: MaterialStateProperty.all(Colors.transparent), backgroundColor: MaterialStateProperty.all(Colors.transparent)),
                                child: const Text(
                                  'Add your first run!',
                                  style: TextStyle(color: Colors.white),
                                ),
                                onPressed: () async {
                                  if (context.mounted) {
                                    await Get.to<RunEditPage>(
                                      () => RunEditPage(
                                        runData: RunDetailsModel.empty(),
                                        kennelData: formController.kennel,
                                        isAddMode: true,
                                      ),
                                    );
                                    await formController.refreshEvents();
                                  }
                                },
                              ),
                              const SizedBox(height: 30),
                              ElevatedButton(
                                style: ButtonStyle(
                                  backgroundColor:
                                      WidgetStateProperty.all<Color>(
                                    Colors.green.shade800,
                                  ),
                                ),
                                //style: ButtonStyle(shadowColor: MaterialStateProperty.all(Colors.transparent), backgroundColor: MaterialStateProperty.all(Colors.transparent)),
                                child: const Text(
                                  'Edit Kennel',
                                  style: TextStyle(color: Colors.white),
                                ),
                                onPressed: () async {
                                  if (context.mounted) {
                                    final kennel = await _getKennel(
                                      formController.kennel.publicKennelId,
                                    );

                                    if (kennel != null) {
                                      await Get.to<KennelEditPage>(
                                        () => KennelEditPage(
                                          key: UniqueKey(),
                                          kennelData: kennel,
                                        ),
                                      );
                                      // should already be removed, but try again just to make sure
                                      await Get.delete<
                                          KennelPageFormController>(
                                        force: true,
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          )
                        : Text(
                            'Loading runs ...',
                            style: TextStyle(
                              fontSize: 36,
                              color: Colors.blue.shade900,
                            ),
                          ),
                  )
                : Container(
                    // decoration: formController.backgroundColor != null
                    //     ? null
                    //     : formController.textThemeIsLight
                    //         ? Backgrounds.defaultHcBackground()
                    //         : Backgrounds.defaultHcBackgroundLight(),
                    child: formController.isLoaded.value
                        ? (formController.isNarrowScreen.value ||
                                formController.displayType.toLowerCase() ==
                                    RUN_DISPLAY_TYPE_DETAIL_ONLY)
                            ? _getDetailOnly()
                            : _getFullPageListLayout()
                        : HcCircularProgressIndicator(key: UniqueKey()),
                  ),
          ),
        );
      },
    );
  }

  Widget _getDetailOnly() {
    return Column(
      children: <Widget>[
        //if (formController.isNarrowScreen.value) ...<Widget>[const SizedBox(height: 40.0)],
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            controller: _listScrollController,
            child: SafeArea(
              top: false,
              bottom: false,
              child: Builder(
                // This Builder is needed to provide a BuildContext that is "inside"
                // the NestedScrollView, so that sliverOverlapAbsorberHandleFor() can
                // find the NestedScrollView.
                builder: (BuildContext context) {
                  return NestedScrollView(
                    floatHeaderSlivers: true,
                    controller: _listScrollController,
                    headerSliverBuilder:
                        (BuildContext context, bool boxIsScrolled) {
                      return <Widget>[
                        SliverAppBar(
                          backgroundColor:
                              const Color.fromARGB(255, 196, 165, 246),
                          automaticallyImplyLeading: false,
                          bottom: PreferredSize(
                            preferredSize: const Size.fromHeight(120),
                            child: Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                Container(
                                  padding: const EdgeInsets.only(
                                    top: 10,
                                    bottom: 10,
                                  ),
                                  child: Column(
                                    children: <Widget>[
                                      Linkify(
                                        textAlign: TextAlign.center,
                                        maxLines: 4,
                                        text:
                                            'Powered by Harrier Central.\r\nSign your Kennel up for FREE today!\r\nhttps://www.harriercentral.com',
                                        style: TextStyle(
                                          color: formController.textThemeIsLight
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: 18,
                                        ),
                                        linkStyle: TextStyle(
                                          color: formController.textThemeIsLight
                                              ? Colors.yellow
                                              : Colors.blue.shade800,
                                          fontSize: 18,
                                        ),
                                        onOpen: (LinkableElement link) async {
                                          if (Uri.parse(link.url).isAbsolute) {
                                            openWindow(link.url, '_blank');
                                            // js.context.callMethod(
                                            //   'open',
                                            //   <String>[link.url],
                                            // );
                                          } else {
                                            await CoreUtilities.showAlert(
                                              'Unable to open link',
                                              'Harrier Central was unable to open ${link.url}',
                                              'OK',
                                            );
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Version: ${packageInfo.value?.version ?? '<unknown>,'}',
                                        style: footnoteSmall.copyWith(
                                          color: formController.textThemeIsLight
                                              ? Colors.white
                                                  .withValues(alpha: 0.8)
                                              : Colors.black
                                                  .withValues(alpha: 0.8),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          //color: formController.backgroundColor == null ? Colors.transparent : HexColor(formController.backgroundColor!),
                                          color: Colors.white,
                                          border: Border.all(
                                            color: Colors.white,
                                            width:
                                                2, //                   <--- border width here
                                          ),
                                        ),
                                        margin: const EdgeInsets.only(
                                          left: 20,
                                          right: 20,
                                        ),
                                        child: _searchBar(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // TabBar(
                          //   tabs: <Widget>[
                          //     Tab(
                          //       child: Text("Colors"),
                          //     ),
                          //     Tab(
                          //       child: Text("Chats"),
                          //     ),
                          //   ],
                          //   //controller: _tabController,
                          // ),
                        ),
                      ];
                    },
                    body: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount:
                          formController.displayedEventsDetails.length + 1,
                      padding: const EdgeInsets.only(top: 5),
                      separatorBuilder: (BuildContext context, int index) =>
                          const SizedBox(height: 5),
                      itemBuilder: (BuildContext context, int index) {
                        return index ==
                                formController.displayedEventsDetails.length
                            ? const SizedBox(height: 100)
                            : Card(
                                margin: EdgeInsets.only(
                                  right: formController.isNarrowScreen.value
                                      ? 15.0
                                      : 40.0,
                                  left: formController.isNarrowScreen.value
                                      ? 15.0
                                      : 40.0,
                                  top: 30,
                                  bottom: 10,
                                ),
                                elevation: 5,

                                //formController.backgroundColor == null ? Colors.transparent : HexColor(formController.backgroundColor!)
                                //color: index.isEven ? Colors.black26 : Colors.white30,
                                color: formController.textThemeIsLight
                                    ? HexColor.darken(
                                        HexColor(
                                          formController.backgroundColor,
                                        ),
                                      )
                                    : HexColor.lighten(
                                        HexColor(
                                          formController.backgroundColor,
                                        ),
                                      ),
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    color: formController.textThemeIsLight
                                        ? Colors.black38
                                        : Colors.white38,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: _renderRunDetail(
                                  formController.displayedEventsDetails[index],
                                ),
                              );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        // const SizedBox(
        //   height: 5.0,
        // ),
        //const SizedBox(height: 25.0),
      ],
    );
  }

  Widget _searchBar() {
    return SizedBox(
      height: 40,
      //color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: TextField(
                        autocorrect: false,
                        onChanged: (String text) {
                          formController
                            ..searchRunsText = text
                            ..setDisplayedEvents();
                        },
                        focusNode: _searchFocusNode,
                        controller: _searchController,
                        keyboardType: TextInputType.text,
                        style: const TextStyle(
                          fontFamily: 'WorkSansSemiBold',
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        decoration: const InputDecoration(
                          filled: false,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          icon: Icon(
                            FontAwesome.search,
                            color: Colors.black,
                          ),
                          hintText: 'Search...',
                          hintStyle: TextStyle(
                            fontFamily: 'WorkSansSemiBold',
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        textStyle: TextStyle(color: Colors.grey.shade900),
                      ),
                      child: const Text('X'),
                      onPressed: () {
                        _searchController.text = '';
                        formController
                          ..searchRunsText = ''
                          ..setDisplayedEvents();
                      },
                    ),
                  ),
                  const SizedBox(width: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getFullPageListLayout() {
    return Column(
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            //color: formController.backgroundColor == null ? Colors.transparent : HexColor(formController.backgroundColor!),
            color: Colors.white,
            border: Border.all(
              color: Colors.white,
              width: 2, //                   <--- border width here
            ),
          ),
          margin: const EdgeInsets.only(
            left: 10,
            top: 10,
            bottom: 10,
            right: 20,
          ),
          child: _searchBar(),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            children: <Widget>[
              const SizedBox(width: 10),
              SizedBox(
                width: 450,
                child: _runList(),
              ),
              Expanded(
                child: Container(
                  //color: _textThemeIsDark ? Colors.purple.shade900,
                  margin: const EdgeInsets.only(left: 20, right: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: HexColor(formController.backgroundColor),
                    border: Border.all(
                      color: formController.textThemeIsLight
                          ? Colors.white
                          : Colors.blue.shade900,
                      width: 2, //                   <--- border width here
                    ),
                  ),
                  height: 3000,
                  child: Column(
                    children: <Widget>[
                      Expanded(child: _singleRunDetail()),
                      if (formController.eventForSingleEventDetailsView.value
                              .runDetails.publicEventId !=
                          '00000000-0000-0000-0000-000000000000') ...<Widget>[
                        Divider(
                          thickness: 2,
                          color: formController.textThemeIsLight
                              ? Colors.white
                              : Colors.blue.shade900,
                        ),
                        SizedBox(
                          height: 50,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: OverflowBar(
                              alignment: MainAxisAlignment.spaceBetween,
                              spacing: 10,
                              overflowSpacing: 10,
                              children: <Widget>[
                                if (formController.kennel.canManageRuns) ...[
                                  ElevatedButton(
                                    //style: ButtonStyle(shadowColor: MaterialStateProperty.all(Colors.transparent), backgroundColor: MaterialStateProperty.all(Colors.transparent)),
                                    child: Baseline(
                                      baseline: 16,
                                      baselineType: TextBaseline.alphabetic,
                                      child: Text(
                                        'Delete Run',
                                        style: buttonLabelStyleMedium,
                                      ),
                                    ),

                                    onPressed: () async {
                                      final deleteThisRun =
                                          await CoreUtilities.showAlert(
                                                'Delete Run',
                                                'Would you like to delete "${formController.eventForSingleEventDetailsView.value.runDetails.eventName}"?',
                                                'Delete run',
                                                showCancelButton: true,
                                              ) ??
                                              false;
                                      if (deleteThisRun &&
                                          (formController
                                                  .eventForSingleEventDetailsView
                                                  .value
                                                  .runDetails
                                                  .publicEventId !=
                                              null)) {
                                        await formController.deleteEvent(
                                          formController
                                              .eventForSingleEventDetailsView
                                              .value
                                              .runDetails
                                              .publicEventId,
                                        );
                                      }
                                    },
                                  ),
                                ],
                                // if ((formController
                                //             .eventForSingleEventDetailsView
                                //             .value
                                //             .runDetails
                                //             .publicKennelId ==
                                //         '6edc3585-c1f8-4800-b189-23a4036830c9') ||
                                //     (formController
                                //             .eventForSingleEventDetailsView
                                //             .value
                                //             .runDetails
                                //             .publicKennelId
                                //             .toUpperCase() ==
                                //         '934306C8-035A-4AF8-B4FA-A593BC28BF36') ||
                                //     (formController
                                //             .eventForSingleEventDetailsView
                                //             .value
                                //             .runDetails
                                //             .publicKennelId
                                //             .toUpperCase() ==
                                //         'EEAF7B5B-D55A-4A31-B056-3F6C62567441') ||
                                //     (formController
                                //             .eventForSingleEventDetailsView
                                //             .value
                                //             .runDetails
                                //             .publicKennelId
                                //             .toUpperCase() ==
                                //         '03B4004D-5CCB-4BCA-804C-88965C54C7AE')) ...<Widget>[
                                ElevatedButton(
                                  style: ButtonStyle(
                                    backgroundColor:
                                        WidgetStateProperty.all<Color>(
                                      Colors.green.shade800,
                                    ),
                                  ),
                                  child: Baseline(
                                    baseline: 16,
                                    baselineType: TextBaseline.alphabetic,
                                    child: Text(
                                      'Trail Chat',
                                      style: buttonLabelStyleMedium,
                                    ),
                                  ),
                                  onPressed: () async {
                                    await Get.to<ChatSheetPage>(
                                      () => ChatSheetPage(
                                        publicEventId: formController
                                            .eventForSingleEventDetailsView
                                            .value
                                            .runDetails
                                            .publicEventId!,
                                        messageTitle: formController
                                            .eventForSingleEventDetailsView
                                            .value
                                            .runDetails
                                            .eventName,
                                        eventName: formController
                                            .eventForSingleEventDetailsView
                                            .value
                                            .runDetails
                                            .eventName,
                                      ),
                                    );

                                    formController.resetBadgeCount(
                                      formController
                                          .eventForSingleEventDetailsView
                                          .value
                                          .runDetails
                                          .publicEventId!,
                                    );
                                  },
                                ),
                                // ],
                                ElevatedButton(
                                  style: ButtonStyle(
                                    backgroundColor:
                                        WidgetStateProperty.all<Color>(
                                      Colors.green.shade800,
                                    ),
                                  ),
                                  child: Baseline(
                                    baseline: 16,
                                    baselineType: TextBaseline.alphabetic,
                                    child: Text(
                                      'Email',
                                      style: buttonLabelStyleMedium,
                                    ),
                                  ),
                                  onPressed: () async {
                                    //EmailModel? value =
                                    await Get.to<EmailModel>(
                                        EmailPage.new);
                                  },
                                ),

                                if ((formController.kennel.canManageRuns) ||
                                    (formController
                                        .kennel.canManageHashCash)) ...[
                                  ElevatedButton(
                                    child: Baseline(
                                      baseline: 16,
                                      baselineType: TextBaseline.alphabetic,
                                      child: Text(
                                        'Edit Run',
                                        style: buttonLabelStyleMedium,
                                      ),
                                    ),
                                    onPressed: () async {
                                      await Get.to<RunEditPage>(
                                        () => RunEditPage(
                                          runData: formController
                                              .eventForSingleEventDetailsView
                                              .value
                                              .runDetails,
                                          kennelData: formController.kennel,
                                          isAddMode: false,
                                        ),
                                      );
                                      formController
                                          .eventForSingleEventDetailsView
                                          .value = (await querySingleEvent(
                                        formController
                                                .eventForSingleEventDetailsView
                                                .value
                                                .runDetails
                                                .publicEventId ??
                                            '',
                                      ));
                                    },
                                  ),
                                ],

                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 5,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10, right: 20, bottom: 10),
          child: OverflowBar(
            alignment: MainAxisAlignment.end,
            spacing: 10,
            overflowSpacing: 10,
            children: [
              if (formController.kennel.canManageRuns) ...[
                ElevatedButton(
                  child: Baseline(
                    baseline: 16,
                    baselineType: TextBaseline.alphabetic,
                    child: Text(
                      'Add run',
                      style: buttonLabelStyleMedium,
                    ),
                  ),
                  onPressed: () async {
                    var lastRunDate = DateTime.now();

                    for (final run in formController.allEvents) {
                      if (run.eventStartDatetime.isAfter(lastRunDate)) {
                        lastRunDate = run.eventStartDatetime;
                      }
                    }

                    await Get.to<RunEditPage>(
                      () => RunEditPage(
                        runData: RunDetailsModel.empty(),
                        kennelData: formController.kennel,
                        isAddMode: true,
                        lastRunDate: lastRunDate,
                      ),
                    );
                    await formController.refreshEvents();
                  },
                ),
              ],


              if (formController.kennel.canManageMembers ||
                  formController.kennel.canManageHashCash) ...[
                ElevatedButton(
                  child: Baseline(
                    baseline: 16,
                    baselineType: TextBaseline.alphabetic,
                    child: Text(
                      'Manage Hashers',
                      textAlign: TextAlign.center,
                      style: buttonLabelStyleMedium,
                    ),
                  ),
                  onPressed: () async {
                    await Get.to<KennelHashersPage>(
                      () => KennelHashersPage(formController.kennel),
                    );
                  },
                ),
              ],

              if (formController.kennel.canManageMembers ||
                  formController.kennel.canManageHashCash) ...[
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all<Color>(
                      Colors.green.shade800,
                    ),
                  ),
                  child: Baseline(
                    baseline: 16,
                    baselineType: TextBaseline.alphabetic,
                    child: Text(
                      'Print Checkin Sheet',
                      textAlign: TextAlign.center,
                      style: buttonLabelStyleMedium,
                    ),
                  ),
                  onPressed: () async {
                    await Get.to<CheckinSheetPage>(
                      () => CheckinSheetPage(
                        publicKennelId: formController.kennel.publicKennelId,
                        kennelName: formController.kennel.kennelName,
                        kennelLogo: formController.kennel.kennelLogo,
                      ),
                    );
                  },
                ),
              ],

              // if ((formController.publicHasherId.toUpperCase() ==
              //         HC_PORTAL_ADMIN_OPEE) ||
              //     (formController.publicHasherId.toUpperCase() ==
              //             HC_PORTAL_ADMIN_TUNA ||
              //         (formController.publicHasherId.toUpperCase() ==
              //             HC_PORTAL_ADMIN_KILTY))) ...<Widget>[

              if ((formController.kennel.canManageKennel) ||
                  (formController.kennel.canManageHashCash)) ...[
                ElevatedButton(
                  onPressed: () async {
                    final kennel =
                        await _getKennel(formController.kennel.publicKennelId);

                    if (kennel != null) {
                      await Get.to<KennelEditPage>(
                        () => KennelEditPage(
                          key: UniqueKey(),
                          kennelData: kennel,
                        ),
                      );
                      // should already be removed, but try again just to make sure
                      await Get.delete<KennelPageFormController>(
                        force: true,
                      );
                    }
                  },
                  child: Baseline(
                    baseline: 16,
                    baselineType: TextBaseline.alphabetic,
                    child: Text(
                      'Edit Kennel',
                      textAlign: TextAlign.center,
                      style: buttonLabelStyleMedium,
                    ),
                  ),
                ),
              ],
            ],
            // ],
          ),
        ),
        Linkify(
          text:
              'Powered by Harrier Central. Sign your Kennel up for FREE today at https://www.harriercentral.com',
          style: TextStyle(
            color:
                formController.textThemeIsLight ? Colors.white : Colors.black,
            fontSize: 18,
          ),
          linkStyle: TextStyle(
            color: formController.textThemeIsLight
                ? Colors.yellow
                : Colors.blue.shade800,
            fontSize: 18,
          ),
          onOpen: (LinkableElement link) async {
            if (Uri.parse(link.url).isAbsolute) {
              openWindow(link.url, '_blank');
            } else {
              await CoreUtilities.showAlert(
                'Unable to open link',
                'Harrier Central was unable to open ${link.url}',
                'OK',
              );
            }
          },
        ),
        const SizedBox(height: 5),
        Text(
          'Version: ${packageInfo.value?.version ?? '<unknown>'}',
          style: footnoteSmall.copyWith(
            color: formController.textThemeIsLight
                ? Colors.white.withValues(alpha: 0.8)
                : Colors.black.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 5),
      ],
    );
  }

  static const int flexLeft = 30;
  static const int flexRight = 70;

  static const double spaceBetweenColumns = 11;
  static const double spaceBetweenRows = 26;

  //final TabController _tabController = TabController(vsync: this, length: 2);

  Widget _runList() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.brown.shade100,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
              ),
              child: TabBar(
                labelStyle: buttonLabelStyleMedium,
                unselectedLabelStyle: buttonLabelStyleMedium,
                unselectedLabelColor: Colors.black,
                labelColor: Colors.white,
                labelPadding:
                    const EdgeInsets.only(top: 5, left: 20, right: 20),
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BubbleTabIndicator(
                  indicatorHeight: 35,
                  indicatorColor: Colors.red.shade900,
                  tabBarIndicatorSize: TabBarIndicatorSize.tab,
                  indicatorRadius: 20,
                ),
                tabs: const <Tab>[
                  Tab(text: TEXT_FUTURE_RUNS),
                  Tab(text: TEXT_PAST_RUNS),
                ],
                onTap: (int tabIdx) {
                  if (tabIdx == 0) {
                    formController.displayRuns = EDisplayRuns.future;
                  } else {
                    formController.displayRuns = EDisplayRuns.past;
                  }
                  formController.setDisplayedEvents();
                },
                //controller: _tabController,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // ),
          // ),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              controller: _scrollController3,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: formController.displayedEvents.length,
                controller: _scrollController3,
                padding: const EdgeInsets.only(top: 5),
                separatorBuilder: (BuildContext context, int index) =>
                    const Divider(
                  height: 1,
                  color: Colors.black45,
                ),
                //itemExtent: 58.0,
                //shrinkWrap: true,
                itemBuilder: (BuildContext context, int index) {
                  // final chatsCounts =
                  //     box.get(HIVE_CHATS_COUNT) as Map<String, int>?;

                  return GetBuilder<RunListPageController>(
                    id: 'chatCountBadge',
                    builder: (controller) {
                      return badges.Badge(
                        position: badges.BadgePosition.topEnd(top: -5, end: 0),
                        badgeContent: Text(
                          formController.thisEventChatCount[formController
                                  .displayedEvents[index].publicEventId]
                              .toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                        badgeStyle: badges.BadgeStyle(
                          badgeColor: Colors.red.shade800,
                          padding: const EdgeInsets.all(6),
                        ),
                        showBadge: (formController.thisEventChatCount[
                                    formController.displayedEvents[index]
                                        .publicEventId] ??
                                0) !=
                            0,
                        child: RunListItem(
                          event: formController.displayedEvents[index],
                          onTap: () async {
                            formController.eventForSingleEventDetailsView
                                .value = (await querySingleEvent(
                              formController
                                  .displayedEvents[index].publicEventId,
                            ));
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<KennelModel?> _getKennel(String publicKennelId) async {
    KennelModel? rdm;

    final deviceId = box.get(HIVE_DEVICE_ID) as String;
    final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';

    final accessToken = Utilities.generateToken(
      deviceId,
      'hcportal_getKennel',
      paramString: deviceSecret,
    );

    final body = <String, String>{
      'queryType': 'getKennel',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'publicKennelId': publicKennelId,
    };

    final jsonResult = await ServiceCommon.sendHttpPostToHC6Api(body);
    if (!jsonResult.startsWith(ERROR_PREFIX)) {
      final jsonItems = json.decode(jsonResult) as List<dynamic>;
      rdm = KennelModel.fromJson(
        (jsonItems[0] as List<dynamic>)[0] as Map<String, dynamic>,
      );
    }

    return rdm;
  }

  Widget _singleRunDetail() {
    return formController.eventForSingleEventDetailsView.value.runDetails
                .publicEventId ==
            '00000000-0000-0000-0000-000000000000'
        ? IgnorePointer(
            child: Column(
              children: <Widget>[
                const SizedBox(height: 10),
                Text(
                  'NOTE: To scroll the web page, move your cursor out of this scrollable box',
                  textAlign: TextAlign.center,
                  style: footnoteSmall.copyWith(
                    color: formController.textThemeIsLight
                        ? Colors.white.withValues(alpha: 0.8)
                        : Colors.black.withValues(alpha: 0.8),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        MaterialCommunityIcons.arrow_left,
                        color: formController.textThemeIsLight
                            ? Colors.white
                            : Colors.blue.shade900,
                        size: 48,
                      ),
                      const SizedBox(width: 20),
                      Text(
                        'Select a run from\r\nthe list to the left\r\nto see details',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: formController.textThemeIsLight
                              ? Colors.white
                              : Colors.blue.shade900,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'NOTE: To scroll the web page, move your cursor out of this scrollable box',
                  textAlign: TextAlign.center,
                  style: footnoteSmall.copyWith(
                    color: formController.textThemeIsLight
                        ? Colors.white.withValues(alpha: 0.8)
                        : Colors.black.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          )
        : SingleChildScrollView(
            //controller: _scrollController3,
            primary: false,
            child: _renderRunDetail(
              formController.eventForSingleEventDetailsView.value,
            ),
          );
  }

  Widget _renderRunDetail(EventDetailsResult edr) {
    return RunDetailWidget(
      rdm: edr.runDetails,
      participants: edr.participants,
      textThemeIsLight: formController.textThemeIsLight,
      isNarrowScreen: formController.isNarrowScreen.value,
      backgroundColor: formController.backgroundColor,
    );
  }
}
