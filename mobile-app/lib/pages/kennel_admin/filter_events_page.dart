import 'package:harrier_central/imports.dart';
// ignore: unnecessary_import
import 'package:harrier_central/pages/kennel_admin/filter_events_controller.dart';

export 'package:harrier_central/pages/kennel_admin/filter_events_controller.dart'
    show FilterEventsPageType, FilterEventsController;

class AddEditEventsPage extends StatefulWidget {
  const AddEditEventsPage({
    super.key,
    required this.kennel,
    required this.pageType,
  });

  final KennelListAggregate kennel;
  final FilterEventsPageType pageType;

  @override
  AddEditEventsPageState createState() => AddEditEventsPageState();
}

class AddEditEventsPageState extends State<AddEditEventsPage>
    with TickerProviderStateMixin {
  AddEditEventsPageState();

  late FilterEventsController _controller;
  late TabController _tabController;
  late AnimationController _animationController;

  final List<Tab> _tabs = <Tab>[];
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();

    _controller = Get.put(
      FilterEventsController(kennel: widget.kennel, pageType: widget.pageType),
    );

    _initTabs();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _tabController = TabController(vsync: this, length: _tabs.length);
    _tabController.addListener(() {
      setStateIfMounted(() {});
    });

    unawaited(_animationController.forward());
  }

  void _initTabs() {
    if (_tabs.isEmpty) {
      _tabs.add(const Tab(text: 'Calendar'));
      _tabs.add(const Tab(text: 'List'));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    Get.delete<FilterEventsController>();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
        title: Text(
          'Events for ${widget.kennel.kennel.kennelShortName}',
          style: ts_appBarTitle,
        ),
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const HcAppCircularProgressIndicator(key: Key('9844430132'));
        }
        return _buildListView();
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Main layout
  // ---------------------------------------------------------------------------

  Widget _buildListView() {
    return Obx(() {
      int publishedRunCount = 0;
      if (_controller.publishedRunCountSqlResult.isNotEmpty) {
        publishedRunCount =
            _controller.publishedRunCountSqlResult[0]['publishedRunCount']
                as int;
      }

      return Container(
        decoration: Backgrounds.defaultHcBackgroundLight(),
        padding: const EdgeInsets.only(top: 0.0),
        child: RefreshIndicator(
          onRefresh: _controller.handleRefresh,
          displacement: 130.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              // Kennel header
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
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      height: 75,
                      child: KennelLogo(
                        kennelId: widget.kennel.kennel.kennelId,
                        kennelLogoUrl: widget.kennel.kennel.kennelLogo,
                        kennelShortName: widget.kennel.kennel.kennelShortName,
                        logoHeight: 75.0,
                        rightPadding: 15.0,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          AutoSizeText(
                            widget.kennel.kennel.kennelName,
                            overflow: TextOverflow.ellipsis,
                            minFontSize: 18.0,
                            maxLines: 1,
                            style: ts_titleCondensedBlack,
                            textAlign: TextAlign.left,
                          ),
                          AutoSizeText(
                            widget.pageType == FilterEventsPageType.past
                                ? 'Past run count: ${publishedRunCount.toString()}'
                                : 'Future run count: ${publishedRunCount.toString()}',
                            overflow: TextOverflow.ellipsis,
                            minFontSize: 18.0,
                            maxLines: 1,
                            style: ts_titleCondensedBlack,
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tab bar
              Container(
                height: 50.0,
                decoration: BoxDecoration(
                  color: Colors.yellow.shade100,
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color.fromARGB(70, 0, 0, 0),
                      offset: Offset(0.0, 6.0),
                      blurRadius: 10.0,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 1.0, right: 1.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: TabBar(
                      labelStyle: ts_tabSelected,
                      unselectedLabelStyle: ts_tabUnselected,
                      isScrollable: false,
                      unselectedLabelColor: Colors.black,
                      labelColor: Colors.white,
                      labelPadding: const EdgeInsets.only(top: 5),
                      indicatorPadding: EdgeInsetsGeometry.only(
                        top: 8,
                        bottom: 8,
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: hc_red,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      tabs: _tabs,
                      controller: _tabController,
                    ),
                  ),
                ),
              ),

              // Tab body
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: <Widget>[
                    _calendarView(),
                    Obx(() => _listView(_controller.allEvents.toList())),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Calendar view
  // ---------------------------------------------------------------------------

  Widget _calendarView() {
    return Obx(() {
      final DateTime focused = _controller.focusedDay.value;
      final DateTime selected = _controller.selectedDay.value;

      return Column(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color.fromARGB(70, 0, 0, 0),
                  offset: Offset(0.0, 6.0),
                  blurRadius: 10.0,
                ),
              ],
            ),
            child: Column(
              children: <Widget>[
                const Divider(color: Colors.black, height: 1.0),
                Container(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: TableCalendar<dynamic>(
                    onCalendarCreated: (PageController controller) =>
                        controller,
                    firstDay: DateTime(2010, 1, 1),
                    lastDay: DateTime(2030, 1, 1),
                    focusedDay: focused,
                    calendarFormat: _calendarFormat,
                    rowHeight: 35.0,
                    rangeSelectionMode: RangeSelectionMode.toggledOff,
                    headerStyle: HeaderStyle(
                      rightChevronIcon: const Icon(
                        Icons.chevron_right,
                        color: Colors.black,
                      ),
                      leftChevronIcon: const Icon(
                        Icons.chevron_left,
                        color: Colors.black,
                      ),
                      formatButtonDecoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      formatButtonTextStyle: const TextStyle().copyWith(
                        color: Colors.white,
                      ),
                    ),
                    onFormatChanged: (CalendarFormat format) {
                      setStateIfMounted(() {
                        _calendarFormat = format;
                      });
                    },
                    onPageChanged: (DateTime newFocusedDay) {
                      _controller.focusedDay.value = newFocusedDay;
                    },
                    eventLoader: (DateTime dt) {
                      return _controller.calendarEvents[_controller.toDateOnly(
                                dt,
                              )]
                              as List<dynamic>? ??
                          [];
                    },
                    onDaySelected: _controller.onDaySelected,
                    availableCalendarFormats: const <CalendarFormat, String>{
                      CalendarFormat.month: 'Week',
                      CalendarFormat.twoWeeks: 'Month',
                      CalendarFormat.week: '2 weeks',
                    },
                    calendarStyle: CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: Colors.deepOrange[400],
                      ),
                      todayDecoration: BoxDecoration(
                        color: Colors.deepOrange[200],
                      ),
                      markerDecoration: BoxDecoration(color: Colors.brown[700]),
                      outsideDaysVisible: false,
                    ),
                    calendarBuilders: CalendarBuilders<dynamic>(
                      todayBuilder:
                          (
                            BuildContext context,
                            DateTime date,
                            DateTime focusedDay,
                          ) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                border: Border.all(
                                  color: Colors.black26,
                                  width: 1.0,
                                ),
                              ),
                              width: 100,
                              height: 50,
                              child: Text(
                                '${date.day}',
                                style: const TextStyle().copyWith(
                                  fontSize: 16.0,
                                ),
                              ),
                            );
                          },
                      outsideBuilder:
                          (
                            BuildContext context,
                            DateTime date,
                            DateTime focusedDay,
                          ) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                border: Border.all(
                                  color: Colors.black12,
                                  width: 1.0,
                                ),
                              ),
                              width: 100,
                              height: 50,
                              child: Text(
                                '${date.day}',
                                style: const TextStyle().copyWith(
                                  fontSize: 16.0,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            );
                          },
                      defaultBuilder:
                          (
                            BuildContext context,
                            DateTime date,
                            DateTime focusedDay,
                          ) {
                            final DateTime dateOnly = _controller.toDateOnly(
                              date,
                            );
                            final bool isUpdating = _controller
                                .isDateCurrentlyUpdating(date);
                            final List<LiteEventModel>? events =
                                _controller.calendarEvents[dateOnly];
                            final int eventCount = events?.length ?? 0;

                            Color bgColor;
                            if (eventCount == 0) {
                              bgColor =
                                  dateOnly
                                          .difference(
                                            _controller.toDateOnly(
                                              DateTime.now(),
                                            ),
                                          )
                                          .inDays >=
                                      0
                                  ? Colors.white
                                  : Colors.grey.shade200;
                            } else if (eventCount > 1) {
                              bgColor = Colors.red.shade100;
                            } else {
                              final LiteEventModel evt = events![0];
                              if (evt.isVisible == 0) {
                                bgColor = Colors.grey.shade300;
                              } else if (evt.isCountedRun == 1) {
                                bgColor = Colors.green.shade100;
                              } else {
                                bgColor = Colors.yellow.shade200;
                              }
                            }

                            final bool isFocused =
                                dateOnly == _controller.toDateOnly(focused);

                            return Container(
                              decoration: BoxDecoration(
                                color: bgColor,
                                border: isFocused
                                    ? Border.all(color: hc_red, width: 3.0)
                                    : Border.all(
                                        color: Colors.black26,
                                        width: 1.0,
                                      ),
                              ),
                              width: 100,
                              height: 50,
                              child: Stack(
                                alignment: AlignmentDirectional.center,
                                children: <Widget>[
                                  Positioned(
                                    top: 1.0,
                                    left: 1.0,
                                    child: Text(
                                      '${date.day}',
                                      style: const TextStyle().copyWith(
                                        fontSize: 16.0,
                                        color:
                                            dateOnly
                                                    .difference(
                                                      _controller.toDateOnly(
                                                        DateTime.now(),
                                                      ),
                                                    )
                                                    .inDays >=
                                                0
                                            ? Colors.black
                                            : Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                                  if (isUpdating) ...<Widget>[
                                    Positioned(
                                      right: 1.0,
                                      child: Icon(delayIcon, color: hc_blue),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                      markerBuilder:
                          (
                            BuildContext context,
                            DateTime date,
                            List<dynamic> events,
                          ) {
                            final List<Widget> children = <Widget>[];

                            if (events.isNotEmpty) {
                              if (events.length <= 5) {
                                for (int i = 0; i < events.length; i++) {
                                  children.add(
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 5.0,
                                      ),
                                      child: Icon(
                                        FontAwesome.circle,
                                        size: 8.0,
                                        color: events[i].isVisible == 0
                                            ? Colors.grey
                                            : events[i].isCountedRun == 0
                                            ? hc_red
                                            : hc_blue,
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                children.add(Text(events.length.toString()));
                              }
                            }

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: children,
                            );
                          },
                    ),
                  ),
                ),
                const SizedBox(height: 5.0),

                // Show edit button when there is exactly one event on the
                // selected day and it is not in the past.
                if (_controller
                            .toDateOnly(selected)
                            .difference(_controller.toDateOnly(DateTime.now()))
                            .inDays >=
                        0 &&
                    (_controller
                                .calendarEvents[_controller.toDateOnly(
                                  selected,
                                )]
                                ?.length ??
                            0) ==
                        1) ...<Widget>[_buildEditButton(selected)],
                _buildAddButtons(selected),
              ],
            ),
          ),
          Expanded(child: _listView(_controller.selectedEvents.toList())),
        ],
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Calendar action buttons
  // ---------------------------------------------------------------------------

  Widget _buildEditButton(DateTime selected) {
    return Column(
      children: <Widget>[
        ElevatedButton(
          child: Text('Edit run', style: ts_button),
          onPressed: () async {
            final LiteEventModel? rawEvent = _controller
                .calendarEvents[_controller.toDateOnly(selected)]?[0];
            if (rawEvent != null) {
              final RunAdminAggregate? rda =
                  await CommonQueries.getEventAdminInfoFromLocalCache(
                    rawEvent.eventId,
                    currentUserId,
                  );

              if (rda != null) {
                if (!mounted) return;
                await Navigator.push<dynamic>(
                  context,
                  MaterialPageRoute<dynamic>(
                    builder: (BuildContext context) =>
                        EditRunDetailsPage(false, rda),
                  ),
                );
                await _controller.refreshSqlTablesFromBackend(true);
              }
            }
          },
        ),
        const SizedBox(height: 10.0),
      ],
    );
  }

  Widget _buildAddButtons(DateTime selected) {
    return OverflowBar(
      alignment: MainAxisAlignment.center,
      spacing: 20.0,
      overflowAlignment: OverflowBarAlignment.center,
      children: <Widget>[
        ElevatedButton(
          style: ButtonStyle(
            padding: WidgetStateProperty.all<EdgeInsets>(
              const EdgeInsets.symmetric(horizontal: 15.0),
            ),
          ),
          onPressed: () async {
            final RunAdminAggregate? rda = await CommonQueries.getNewEvent(
              widget.kennel.kennel.kennelId,
              currentUserId,
              selected,
            );

            if (rda != null) {
              if (!mounted) return;
              await Navigator.push<dynamic>(
                context,
                MaterialPageRoute<dynamic>(
                  builder: (BuildContext context) =>
                      EditRunDetailsPage(true, rda),
                ),
              );
            }

            await _controller.refreshSqlTablesFromBackend(true);
            await _controller.refreshEventFromTables(true);
            _controller.refreshList();
          },
          child: Text('Add run', style: ts_button),
        ),
        ElevatedButton(
          style: ButtonStyle(
            padding: WidgetStateProperty.all<EdgeInsets>(
              const EdgeInsets.symmetric(horizontal: 15.0, vertical: 0.0),
            ),
          ),
          onPressed: () async {
            await _controller.showEventPopup(selected, context);
          },
          child: Text('Add run placeholder', style: ts_button),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // List view
  // ---------------------------------------------------------------------------

  Widget _listView(List<LiteEventModel> listEvents) {
    return Obx(() {
      final String updatingId = _controller.itemBeingUpdatedId.value;

      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: listEvents.length,
        padding: const EdgeInsets.only(top: 5),
        separatorBuilder: (BuildContext context, int index) =>
            const Divider(height: 1.0, color: Colors.black45),
        itemBuilder: (BuildContext context, int index) {
          final LiteEventModel event = listEvents[index];
          return Dismissible(
            key: Key(event.eventId),
            confirmDismiss: (DismissDirection direction) async {
              if ((event.appAccessFlags & authCanManageRuns) != 0) {
                final bool isVisible = direction == DismissDirection.endToStart;
                await _controller.updateEvent(
                  eventId: event.eventId,
                  isVisible: isVisible,
                );
              }
              return Future<bool>.value(false);
            },
            background: Container(
              color: ((event.appAccessFlags & authCanManageRuns) == 0)
                  ? Colors.grey[350]
                  : hc_red,
              child: Row(
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(left: 10.0),
                    child: Icon(
                      Ionicons.ios_eye_off,
                      color: Colors.white,
                      size: 35.0,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 15.0),
                    child: Text('Hide event', style: ts_titleMedium),
                  ),
                ],
              ),
            ),
            secondaryBackground: Container(
              color: ((event.appAccessFlags & authCanManageRuns) == 0)
                  ? Colors.grey[350]
                  : Colors.green,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(right: 15.0),
                    child: Icon(
                      Ionicons.ios_eye,
                      color: Colors.white,
                      size: 35.0,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 15.0),
                    child: Text('Show event', style: ts_titleMedium),
                  ),
                ],
              ),
            ),
            onDismissed: (DismissDirection direction) {
              // Intentionally empty — we never actually dismiss.
            },
            child: Stack(
              children: <Widget>[
                if (updatingId == event.eventId) ...<Widget>[
                  const HcAppCircularProgressIndicator(key: Key('5050202')),
                ],
                Opacity(
                  opacity: updatingId == event.eventId ? 0.4 : 1,
                  child: FilterEventListItem(
                    event: event,
                    kennelShortName: widget.kennel.kennel.kennelShortName,
                    mismanagementRoles:
                        widget.kennel.hkm?.mismanagementRoles ?? 0,
                    updateEvent: (dynamic retVal) async {
                      final EnumEventFilterType ft =
                          retVal as EnumEventFilterType;
                      _controller.itemBeingUpdatedId.value = event.eventId;

                      switch (ft) {
                        case eventFilterType_showEvent:
                          await _controller.updateEvent(
                            eventId: event.eventId,
                            isVisible: true,
                          );
                          break;
                        case eventFilterType_hideEvent:
                          await _controller.updateEvent(
                            eventId: event.eventId,
                            isVisible: false,
                          );
                          break;
                        case eventFilterType_countEvent:
                          await _controller.updateEvent(
                            eventId: event.eventId,
                            isCountedRun: true,
                          );
                          break;
                        case eventFilterType_doNotCountEvent:
                          await _controller.updateEvent(
                            eventId: event.eventId,
                            isCountedRun: false,
                          );
                          break;
                        case eventFilterType_setRunNumber:
                          await _controller.setRunNumber(event, context);
                          break;
                        case eventFilterType_refreshOnly:
                          await _controller.refreshSqlTablesFromBackend(false);
                          await _controller.refreshEventFromTables(true);
                          _controller.refreshList();
                          break;
                      }

                      _controller.itemBeingUpdatedId.value = '';
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}
