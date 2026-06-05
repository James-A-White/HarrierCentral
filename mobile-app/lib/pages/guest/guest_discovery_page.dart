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
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

  static final DateFormat _dateFmt = DateFormat('EEE d MMM, h:mma');

  @override
  Widget build(BuildContext context) {
    final String? dateStr = run.eventStartDatetime != null
        ? _dateFmt.format(run.eventStartDatetime!)
        : null;

    final String locationLine = <String?>[
      run.locationCity,
      run.locationCountry,
    ].where((s) => s != null && s.isNotEmpty).join(', ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              KennelLogo(
                kennelLogoUrl: run.kennelLogo,
                kennelShortName: run.kennelShortName ?? run.kennelName,
                logoHeight: 44,
                zoomGesture: KennelLogoZoomGesture.none,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            run.kennelName,
                            style: ts_body.copyWith(
                              color: Colors.white54,
                              fontSize: 11,
                              letterSpacing: 0.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (run.eventNumber != null && run.eventNumber! > 0)
                          Text(
                            '#${run.eventNumber}',
                            style: ts_body.copyWith(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      run.eventName,
                      style: ts_body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (dateStr != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: ts_body.copyWith(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (locationLine.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 1),
                      Text(
                        locationLine,
                        style: ts_body.copyWith(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
            ],
          ),
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
