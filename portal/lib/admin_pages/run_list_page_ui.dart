// ignore_for_file: constant_identifier_names, avoid_web_libraries_in_flutter

import 'package:badges/badges.dart' as badges;
import 'package:hcportal/admin_pages/checkin_sheet/checkin_sheet_ui.dart';
import 'package:hcportal/admin_pages/kennel_page_new/kennel_page_new_ui.dart';
import 'package:hcportal/admin_pages/run_list_detail_panel.dart';
import 'package:hcportal/admin_pages/run_list_page_controller.dart';
import 'package:hcportal/imports.dart';
import 'package:hcportal/widgets/run_list_item.dart';
import 'package:web/web.dart' as web;

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
    this.allKennels = const [],
    this.publicHasherId = '',
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
  final List<HasherKennelsModel> allKennels;
  final String publicHasherId;

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
          backgroundColor: const Color(0xFFF1F5F9),
          appBar: _buildAppBar(context),
          body: Obx(() {
            if (formController.allEvents.isEmpty &&
                formController.allEventsDetails.isEmpty) {
              return formController.isLoaded.value
                  ? _noRunsState(context)
                  : Center(
                      child: Text(
                        'Loading runs …',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    );
            }
            if (!formController.isLoaded.value) {
              return HcCircularProgressIndicator(key: UniqueKey());
            }
            return (formController.isNarrowScreen.value ||
                    formController.displayType.toLowerCase() ==
                        RUN_DISPLAY_TYPE_DETAIL_ONLY)
                ? _getDetailOnly()
                : _getFullPageListLayout();
          }),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final showPicker = allKennels.length > 1;
    final showKennelSearch = allKennels.length > 10;
    return PreferredSize(
      preferredSize: Size.fromHeight(
        kToolbarHeight +
            (showPicker ? (showKennelSearch ? 147.0 : 97.0) : 1.0),
      ),
      child: Material(
        color: Colors.white,
        elevation: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showPicker) _kennelPickerBar(),
            SizedBox(
              height: kToolbarHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (allKennels.isEmpty)
                    GestureDetector(
                      onTap: () => Get.back<void>(),
                      child: const SizedBox(
                        width: 56,
                        child: Icon(
                          MaterialCommunityIcons.arrow_left,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Runs & Events',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _kennelBadge(),
                    ],
                  ),
                  const Spacer(),
                  GetBuilder<RunListPageController>(
                    id: 'appBar',
                    builder: (c) {
                      final k = c.kennel;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (k.isAdmin) ...[
                            if (k.canManageMembers || k.canManageHashCash) ...[
                              _appBarBtn(
                                'Print Check-in',
                                onPressed: () async {
                                  await Get.to<CheckinSheetPage>(
                                    () => CheckinSheetPage(
                                      publicKennelId: k.publicKennelId,
                                      kennelName: k.kennelName,
                                      kennelLogo: k.kennelLogo,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              _appBarBtn(
                                'Manage Hashers',
                                onPressed: () async {
                                  await Get.to<KennelHashersPage>(
                                    () => KennelHashersPage(k),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (k.canManageKennel || k.canManageHashCash) ...[
                              _appBarBtn(
                                'Edit Kennel',
                                onPressed: () async {
                                  final kennel =
                                      await _getKennel(k.publicKennelId);
                                  if (kennel != null) {
                                    await Get.to<KennelEditPage>(
                                      () => KennelEditPage(
                                        key: UniqueKey(),
                                        kennelData: kennel,
                                      ),
                                    );
                                    await Get.delete<KennelPageFormController>(
                                      force: true,
                                    );
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (k.canManageRuns) ...[
                              _appBarBtn(
                                '+ Add Run',
                                isPrimary: true,
                                onPressed: () async {
                                  var lastRunDate = DateTime.now();
                                  for (final run in formController.allEvents) {
                                    if (run.eventStartDatetime
                                        .isAfter(lastRunDate)) {
                                      lastRunDate = run.eventStartDatetime;
                                    }
                                  }
                                  await Get.to<RunEditPage>(
                                    () => RunEditPage(
                                      runData: RunDetailsModel.empty(),
                                      kennelData: k,
                                      isAddMode: true,
                                      lastRunDate: lastRunDate,
                                    ),
                                  );
                                  await formController.refreshEvents();
                                },
                              ),
                              const SizedBox(width: 8),
                            ],
                          ],
                          if ((publicHasherId.toUpperCase() ==
                                  HC_PORTAL_ADMIN_OPEE) ||
                              (publicHasherId.toUpperCase() ==
                                  HC_PORTAL_ADMIN_TUNA)) ...[
                            _appBarBtn(
                              'Monitor',
                              onPressed: () async {
                                await Get.to<UsageDataPage>(UsageDataPage.new);
                              },
                            ),
                            const SizedBox(width: 8),
                          ],
                          _appBarBtn(
                            'Log out',
                            onPressed: () async {
                              await box.clear();
                              web.window.location.reload();
                            },
                          ),
                        ],
                      ),
                    );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
          ],
        ),
      ),
    );
  }

  Widget _kennelBadge() {
    return Obx(() {
      // Track selectedKennelId so the badge updates on kennel switch.
      final _ = formController.selectedKennelId.value;
      final k = formController.kennel;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          border: Border.all(color: const Color(0xFFFECACA)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            KennelLogo(
              kennelLogoUrl: k.kennelLogo,
              kennelShortName: k.kennelShortName,
              logoHeight: 22,
              leftPadding: 0,
              rightPadding: 6,
            ),
            Text(
              k.kennelName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFFB91C1C),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── Kennel picker strip ───────────────────────────────────────────────────
  // Shown at the top of the compound AppBar when the user belongs to > 1 kennel.
  // Uses ALL kennels (not just admin ones). Editing buttons are gated by
  // permissions inside _buildAppBar, so non-admin kennels just show runs.

  Widget _kennelPickerBar() {
    final showSearch = allKennels.length > 10;
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        // ── Logo row ────────────────────────────────────────────────────────
        SizedBox(
          height: 96,
          child: Stack(
            children: [
              // Scrollable logo row
              Obx(() {
                final selectedId = formController.selectedKennelId.value;
                final searchText =
                    formController.kennelPickerSearch.value.toLowerCase();
                final visible = searchText.isEmpty
                    ? allKennels
                    : allKennels
                        .where(
                          (k) => formController.kennelMatchesSearch(
                            k,
                            searchText,
                          ),
                        )
                        .toList();
                final items = [
                  for (var i = 0; i < visible.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _kennelPickerItem(visible[i], selectedId),
                  ],
                ];
                return NotificationListener<ScrollMetricsNotification>(
                  onNotification: (n) {
                    formController.updateKennelPickerOverflow(n.metrics);
                    return false;
                  },
                  child: Align(
                    child: SingleChildScrollView(
                      controller: formController.kennelPickerScrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 10,
                      ),
                      child:
                          Row(mainAxisSize: MainAxisSize.min, children: items),
                    ),
                  ),
                );
              }),
              // Scroll arrows — only visible when content overflows
              Obx(() {
                final hasOverflow =
                    formController.kennelPickerHasOverflow.value;
                final atStart = formController.kennelPickerAtStart.value;
                final atEnd = formController.kennelPickerAtEnd.value;
                if (!hasOverflow) return const SizedBox.shrink();
                return Stack(
                  children: [
                    if (!atStart)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: _kennelPickerArrow(isLeft: true),
                      ),
                    if (!atEnd)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: _kennelPickerArrow(isLeft: false),
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
        // ── Search bar (> 10 kennels only) ──────────────────────────────────
        if (showSearch)
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: TextField(
              controller: formController.kennelPickerSearchController,
              onChanged: formController.filterKennelPicker,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search kennels…',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
                suffixIcon: Obx(
                  () => formController.kennelPickerSearch.value.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          color: const Color(0xFF94A3B8),
                          onPressed: () {
                            formController.kennelPickerSearchController.clear();
                            formController.filterKennelPicker('');
                          },
                        ),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFFB91C1C)),
                ),
              ),
            ),
          ),
      ],
      ),
    );
  }

  Widget _kennelPickerArrow({required bool isLeft}) {
    return Container(
      width: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isLeft ? Alignment.centerRight : Alignment.centerLeft,
          end: isLeft ? Alignment.centerLeft : Alignment.centerRight,
          colors: [Colors.white.withValues(alpha: 0), Colors.white],
          stops: const [0.0, 0.65],
        ),
      ),
      child: Align(
        alignment:
            isLeft ? Alignment.centerLeft : Alignment.centerRight,
        child: IconButton(
          icon: Icon(
            isLeft ? Icons.chevron_left : Icons.chevron_right,
            size: 22,
          ),
          color: const Color(0xFF475569),
          splashRadius: 18,
          onPressed: isLeft
              ? formController.scrollKennelPickerLeft
              : formController.scrollKennelPickerRight,
        ),
      ),
    );
  }

  Widget _kennelPickerItem(HasherKennelsModel k, String selectedId) {
    final isSelected = k.publicKennelId == selectedId;
    return GestureDetector(
      onTap: isSelected ? null : () => formController.switchKennel(k),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? const Color(0xFFFEF2F2) : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xFFB91C1C)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: KennelLogo(
          kennelLogoUrl: k.kennelLogo,
          kennelShortName: k.kennelShortName,
          logoHeight: 76,
          leftPadding: 0,
          rightPadding: 0,
        ),
      ),
    );
  }

  Widget _appBarBtn(
    String label, {
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor:
            isPrimary ? const Color(0xFFB91C1C) : Colors.white,
        foregroundColor:
            isPrimary ? Colors.white : const Color(0xFF475569),
        side: BorderSide(
          color: isPrimary
              ? const Color(0xFFB91C1C)
              : const Color(0xFFE2E8F0),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }

  Widget _noRunsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'No runs found for this Kennel',
            style: TextStyle(fontSize: 28, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 24),
          if (formController.kennel.canManageRuns)
            _appBarBtn(
              '+ Add your first run',
              isPrimary: true,
              onPressed: () async {
                await Get.to<RunEditPage>(
                  () => RunEditPage(
                    runData: RunDetailsModel.empty(),
                    kennelData: formController.kennel,
                    isAddMode: true,
                  ),
                );
                await formController.refreshEvents();
              },
            ),
          const SizedBox(height: 16),
          if (formController.kennel.canManageKennel ||
              formController.kennel.canManageHashCash)
            _appBarBtn(
              'Edit Kennel',
              onPressed: () async {
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
                  await Get.delete<KennelPageFormController>(
                    force: true,
                  );
                }
              },
            ),
        ],
      ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          const Icon(FontAwesome.search, size: 13, color: Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          Expanded(
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
              style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'Search runs…',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.text = '';
                formController
                  ..searchRunsText = ''
                  ..setDisplayedEvents();
              },
              child: const Icon(
                Icons.close,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _getFullPageListLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 400,
          decoration: const BoxDecoration(
            color: Color(0xFFCBD5E1),
            border: Border(right: BorderSide(color: Color(0xFFB0BEC5))),
          ),
          child: _runList(),
        ),
        Expanded(
          child: Container(
            color: const Color(0xFFCBD5E1),
            child: Obx(
              () => RunListDetailPanel(
                edr: formController.eventForSingleEventDetailsView.value,
                controller: formController,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _runList() {
    return Column(
      children: [
        _searchBar(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              controller: formController.tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BubbleTabIndicator(
                indicatorHeight: 35,
                indicatorColor: Colors.red.shade900,
                tabBarIndicatorSize: TabBarIndicatorSize.tab,
                indicatorRadius: 30,
              ),
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF64748B),
              tabs: const [
                Tab(text: TEXT_FUTURE_RUNS),
                Tab(text: TEXT_PAST_RUNS),
              ],
              onTap: (int tabIdx) {
                formController.displayRuns =
                    tabIdx == 0 ? EDisplayRuns.future : EDisplayRuns.past;
                formController.setDisplayedEvents();
              },
            ),
          ),
        ),
          Expanded(
            child: Obx(() {
              final selectedId = formController
                  .eventForSingleEventDetailsView.value
                  .runDetails.publicEventId;
              return Scrollbar(
              thumbVisibility: true,
              controller: _scrollController3,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: formController.displayedEvents.length,
                controller: _scrollController3,
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final event = formController.displayedEvents[index];
                  final isSelected = selectedId == event.publicEventId;
                  return GetBuilder<RunListPageController>(
                    id: 'chatCountBadge',
                    builder: (controller) {
                      return badges.Badge(
                        position:
                            badges.BadgePosition.topEnd(top: -5, end: 0),
                        badgeContent: Text(
                          (formController.thisEventChatCount[
                                      event.publicEventId] ??
                                  0)
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
                                    event.publicEventId] ??
                                0) !=
                            0,
                        child: RunListItem(
                          event: event,
                          isSelected: isSelected,
                          onTap: () async {
                            formController
                                    .eventForSingleEventDetailsView.value =
                                await querySingleEvent(event.publicEventId);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
              );
            }),
          ),
        ],
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
