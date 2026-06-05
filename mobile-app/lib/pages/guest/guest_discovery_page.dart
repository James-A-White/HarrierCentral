import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

class GuestDiscoveryPage extends StatefulWidget {
  const GuestDiscoveryPage({super.key});

  @override
  State<GuestDiscoveryPage> createState() => _GuestDiscoveryPageState();
}

class _GuestDiscoveryPageState extends State<GuestDiscoveryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GuestDiscoveryController _controller =
      Get.put(GuestDiscoveryController());
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging && _tabController.index == 1) {
      _controller.loadPast();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Runs Around the World', style: ts_appBarTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Container(
            color: themeAppBarBackground,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
                  child: Obx(
                    () => TextField(
                      controller: _searchController,
                      style: ts_body,
                      onChanged: _controller.setSearch,
                      decoration: InputDecoration(
                        hintText: 'Search by run, kennel, city, country...',
                        hintStyle: ts_hint,
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.white54),
                        suffixIcon: _controller.searchQuery.value.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.white54,
                                  size: 18,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _controller.setSearch('');
                                },
                              ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  tabs: const <Tab>[
                    Tab(text: 'Upcoming'),
                    Tab(text: 'Past'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: TabBarView(
          controller: _tabController,
          children: <Widget>[
            _RunList(controller: _controller, isFuture: true),
            _RunList(controller: _controller, isFuture: false),
          ],
        ),
      ),
      bottomNavigationBar: const GuestActionBar(),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab body — loading / error / empty / list states
// ---------------------------------------------------------------------------

class _RunList extends StatelessWidget {
  const _RunList({
    required this.controller,
    required this.isFuture,
  });

  final GuestDiscoveryController controller;
  final bool isFuture;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool loading = isFuture
          ? controller.isLoadingUpcoming.value
          : controller.isLoadingPast.value;

      if (loading) {
        return Center(child: HcAppCircularProgressIndicator(key: UniqueKey()));
      }

      final bool error = isFuture
          ? controller.hasErrorUpcoming.value
          : controller.hasErrorPast.value;

      if (error) {
        return _ErrorState(
          onRetry: isFuture ? controller.loadUpcoming : controller.loadPast,
        );
      }

      final List<GuestRunModel> runs =
          isFuture ? controller.filteredUpcoming : controller.filteredPast;

      if (runs.isEmpty) {
        final bool hasQuery = controller.searchQuery.value.trim().isNotEmpty;
        return _EmptyState(
          message: hasQuery
              ? 'No runs match your search.'
              : isFuture
                  ? 'No upcoming runs at the moment.'
                  : 'No runs in the past two months.',
        );
      }

      // Past list has a note appended as a synthetic last item.
      final int itemCount = runs.length + (isFuture ? 0 : 1);

      return RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView.builder(
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 50),
          itemCount: itemCount,
          itemBuilder: (BuildContext context, int index) {
            if (!isFuture && index == runs.length) {
              return const _HistoryNote();
            }
            final GuestRunModel run = runs[index];
            return _GuestRunCard(
              run: run,
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => GuestRunDetailPage(run: run),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Run card
// ---------------------------------------------------------------------------

class _GuestRunCard extends StatelessWidget {
  const _GuestRunCard({required this.run, required this.onTap});

  final GuestRunModel run;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final DateTime? startDt = run.eventStartDatetime;

    // Day offset — same calculation as RunListItem
    int daysOffset = 0;
    if (startDt != null) {
      final DateTime eventDate =
          DateTime.tryParse(startDt.toIso8601String().substring(0, 10)) ??
          startDt;
      final DateTime deviceDate = DateTime.tryParse(
            DateTime.now().toLocal().toIso8601String().substring(0, 10),
          ) ??
          DateTime.now();
      daysOffset = eventDate.difference(deviceDate).inDays;
    }

    final String runLabel =
        (run.isCountedRun && run.eventNumber != null
            ? 'Run #${run.eventNumber}, '
            : 'Run / Event, ') +
        Utilities.describeDayOffset(daysOffset);

    String dateStr = '';
    if (startDt != null) {
      dateStr = startDt.year == DateTime.now().year
          ? DateFormat("E, MMM d 'at' h:mm a").format(startDt)
          : DateFormat("E, MMM d yyyy 'at' h:mm a").format(startDt);
    }

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4.0,
        margin: const EdgeInsets.only(top: 10.0, left: 0.0, right: 0.0),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header: event name
            Padding(
              padding: const EdgeInsets.only(
                left: 10.0,
                right: 10.0,
                top: 8.0,
                bottom: 6.0,
              ),
              child: AutoSizeText(
                run.eventName,
                style: ts_tileText,
                maxLines: 1,
                minFontSize: 18,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(height: 1.0, color: Colors.grey[300]),
            // Optional event image
            if (run.eventImage != null && run.eventImage!.isNotEmpty) ...<Widget>[
              CachedNetworkImage(imageUrl: run.eventImage!),
              Container(height: 1.0, color: Colors.grey[300]),
            ],
            // Body: logo + details
            Padding(
              padding: const EdgeInsets.only(
                top: 10.0,
                bottom: 10.0,
                left: 4.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  KennelLogo(
                    kennelLogoUrl: run.kennelLogo,
                    kennelShortName: run.kennelShortName ?? run.kennelName,
                    logoHeight: 70.0,
                    leftPadding: 7.0,
                    rightPadding: 7.0,
                    zoomGesture: KennelLogoZoomGesture.none,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            run.kennelName,
                            style: ts_titleMediumDarkBlue,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            runLabel,
                            style: ts_titleMediumBlack,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (dateStr.isNotEmpty)
                            Text(
                              dateStr,
                              style: ts_regularMediumBlack,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (run.hares != null && run.hares!.isNotEmpty)
                            Text(
                              'Hares: ${run.hares}',
                              style: ts_regularMediumBlack,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (run.locationOneLineDesc != null &&
                              run.locationOneLineDesc!.isNotEmpty)
                            Text(
                              run.locationOneLineDesc!,
                              style: ts_regularMediumBlack,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error / empty / history note states
// ---------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.wifi_off, color: Colors.white38, size: 48),
            const SizedBox(height: 16),
            Text(
              'Could not load runs.\nPlease check your connection.',
              style: ts_body.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onRetry,
              child: Text('Retry', style: ts_button),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: ts_body.copyWith(color: Colors.white54),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _HistoryNote extends StatelessWidget {
  const _HistoryNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      child: Column(
        children: <Widget>[
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),
          const Icon(Icons.lock_outline, color: Colors.white24, size: 28),
          const SizedBox(height: 8),
          Text(
            'Complete run history is available to registered users.',
            style: ts_body.copyWith(color: Colors.white38, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
