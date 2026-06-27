// ignore_for_file: constant_identifier_names, avoid_web_libraries_in_flutter

import 'package:hcportal/admin_pages/checkin_sheet/checkin_sheet_ui.dart';
import 'package:hcportal/admin_pages/kennel_page_new/kennel_page_new_ui.dart';
import 'package:hcportal/admin_pages/kennel_website_page/kennel_website_page_controller.dart';
import 'package:hcportal/admin_pages/kennel_website_page/kennel_website_page_ui.dart';
import 'package:hcportal/admin_pages/run_list_detail_panel.dart';
import 'package:hcportal/admin_pages/run_list_page_controller.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
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


/// A kennel/admin action surfaced in the runs-page nav (left rail on wide
/// screens, overflow menu on narrow).
typedef _BarAction = ({
  String label,
  IconData icon,
  VoidCallback onTap,
  bool isPrimary,
});

class RunListPage extends StatelessWidget {
  RunListPage(
    this.kennel, {
    this.allKennels = const [],
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
            final Widget content;
            if (formController.allEvents.isEmpty &&
                formController.allEventsDetails.isEmpty) {
              content = formController.isLoaded.value
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
            } else if (!formController.isLoaded.value) {
              content = HcCircularProgressIndicator(key: UniqueKey());
            } else {
              content = (formController.isNarrowScreen.value ||
                      formController.displayType.toLowerCase() ==
                          RUN_DISPLAY_TYPE_DETAIL_ONLY)
                  ? _getDetailOnly()
                  : _getFullPageListLayout();
            }

            // Wide screens: persistent left nav rail beside the content.
            // Narrow screens (and the no-kennel case) keep the top app bar.
            if (formController.isNarrowScreen.value || allKennels.isEmpty) {
              return content;
            }
            return Row(
              children: [
                _navRail(),
                const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
                Expanded(child: content),
              ],
            );
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
        kToolbarHeight + (showPicker ? (showKennelSearch ? 147.0 : 97.0) : 1.0),
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
                  Expanded(
                    child: Obx(() {
                      // Narrow screens: drop the redundant "Runs & Events"
                      // label and let the kennel badge truncate, so the row
                      // never overflows before the actions menu.
                      final narrow = formController.isNarrowScreen.value;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!narrow) ...[
                            const Text(
                              'Runs & Events',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Flexible(child: _kennelBadge()),
                        ],
                      );
                    }),
                  ),
                  GetBuilder<RunListPageController>(
                    id: 'appBar',
                    builder: (c) {
                      // Wide screens render the actions in the persistent left
                      // nav rail (see _navRail); narrow screens collapse them
                      // into an overflow menu. The version label lives here so
                      // it is always visible (the app bar never scrolls).
                      // Obx so the Menu reacts to isNarrowScreen flipping true
                      // after first load — GetBuilder alone isn't reactive to it,
                      // which left the Menu button missing on initial open.
                      return Obx(() {
                        final narrow = formController.isNarrowScreen.value;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _versionLabel(),
                              if (narrow) ...[
                                const SizedBox(width: 10),
                                _appBarActionsMenu(_appBarActions(c.kennel)),
                              ],
                            ],
                          ),
                        );
                      });
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
            Flexible(
              child: Text(
                k.kennelName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFB91C1C),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // Always-visible app version. Lives in the app-bar action area (which never
  // scrolls) so it shows on both the wide rail layout and the narrow menu
  // layout. Replaces the version line that used to sit in the removed banner.
  Widget _versionLabel() {
    final v = packageInfo.value?.version ?? '';
    if (v.isEmpty) return const SizedBox.shrink();
    return Text(
      'v$v',
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFF94A3B8),
      ),
    );
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
                              formController.kennelPickerSearchController
                                  .clear();
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
          // ── Logo row ────────────────────────────────────────────────────────
          SizedBox(
            height: 96,
            child: Obx(() {
              final selectedId = formController.selectedKennelId.value;
              final isLoading = !formController.isLoaded.value;
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

              return Stack(
                children: [
                  NotificationListener<ScrollMetricsNotification>(
                    onNotification: (n) {
                      formController.updateKennelPickerOverflow(n.metrics);
                      return false;
                    },
                    child: ListView.separated(
                      controller: formController.kennelPickerScrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(
                        left: 75,
                        right: 75,
                        top: 10,
                        bottom: 10,
                      ),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => _kennelPickerItem(
                        visible[i],
                        selectedId,
                        isLoading: isLoading,
                      ),
                    ),
                  ),
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
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _kennelPickerArrow({required bool isLeft}) {
    return SizedBox(
      width: 56,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: isLeft ? Alignment.centerRight : Alignment.centerLeft,
                  end: isLeft ? Alignment.centerLeft : Alignment.centerRight,
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: 0.94),
                  ],
                  stops: const [0.0, 0.65],
                ),
              ),
            ),
          ),
          Align(
            alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFCBD5E1),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                icon: Icon(
                  isLeft ? Icons.chevron_left : Icons.chevron_right,
                  size: 22,
                  weight: 700,
                ),
                color: const Color(0xFF1E293B),
                splashRadius: 18,
                onPressed: isLeft
                    ? formController.scrollKennelPickerLeft
                    : formController.scrollKennelPickerRight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kennelPickerItem(HasherKennelsModel k, String selectedId,
      {bool isLoading = false}) {
    final isSelected = k.publicKennelId.asUuid == selectedId;
    final canTap = !isSelected && !isLoading;
    double? scrollOffsetAtPointerDown;
    Offset? globalPositionAtPointerDown;

    const maxScrollDeltaForTap = 2.0;
    const maxPointerMoveForTap = 8.0;

    void triggerSelection() {
      if (!canTap) return;
      unawaited(formController.switchKennel(k));
    }

    return Opacity(
      opacity: (!isSelected && isLoading) ? 0.4 : 1.0,
      child: Listener(
        key: ValueKey('kennel-picker-item-${k.publicKennelId.asUuid}'),
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          if (!canTap) return;
          scrollOffsetAtPointerDown =
              formController.kennelPickerScrollController.hasClients
                  ? formController.kennelPickerScrollController.offset
                  : 0.0;
          globalPositionAtPointerDown = event.position;
        },
        onPointerUp: (event) {
          if (!canTap) return;
          if (globalPositionAtPointerDown == null) return;

          final currentOffset =
              formController.kennelPickerScrollController.hasClients
                  ? formController.kennelPickerScrollController.offset
                  : 0.0;

          final movedSinceTapDown =
              (currentOffset - (scrollOffsetAtPointerDown ?? currentOffset))
                  .abs();
          final pointerTravel =
              (event.position - globalPositionAtPointerDown!).distance;

          // Only switch on pointer up when the interaction behaved like a tap:
          // minimal scroll movement and minimal pointer travel.
          if (movedSinceTapDown <= maxScrollDeltaForTap &&
              pointerTravel <= maxPointerMoveForTap) {
            triggerSelection();
          }
          scrollOffsetAtPointerDown = null;
          globalPositionAtPointerDown = null;
        },
        onPointerCancel: (_) {
          scrollOffsetAtPointerDown = null;
          globalPositionAtPointerDown = null;
        },
        child: isSelected ? _selectedKennelPill(k) : _unselectedKennelCircle(k),
      ),
    );
  }

  Widget _selectedKennelPill(HasherKennelsModel k) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: const LinearGradient(
          colors: [Color(0xFF134E4A), Color(0xFF0D9488)],
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          KennelLogo(
            kennelLogoUrl: k.kennelLogo,
            kennelShortName: k.kennelShortName,
            logoHeight: 52,
            leftPadding: 0,
            rightPadding: 0,
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              k.kennelName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _unselectedKennelCircle(HasherKennelsModel k) {
    return KennelLogo(
      kennelLogoUrl: k.kennelLogo,
      kennelShortName: k.kennelShortName,
      logoHeight: 72,
      leftPadding: 0,
      rightPadding: 0,
    );
  }

  /// Narrow-screen overflow menu: the app-bar actions as a single ⋮ button.
  /// The kennel/admin actions for the current kennel, gated by permissions.
  /// Shared by the left nav rail (wide) and the overflow menu (narrow).
  List<_BarAction> _appBarActions(HasherKennelsModel k) {
    return [
      if (k.isAdmin) ...[
        if (k.canManageMembers || k.canManageHashCash) ...[
          (
            label: 'Print Check-in',
            icon: Icons.fact_check_outlined,
            isPrimary: false,
            onTap: () async {
              await Get.to<CheckinSheetPage>(
                () => CheckinSheetPage(
                  publicKennelId: k.publicKennelId,
                  kennelName: k.kennelName,
                  kennelLogo: k.kennelLogo,
                ),
              );
            },
          ),
          (
            label: 'Manage Hashers',
            icon: Icons.groups_outlined,
            isPrimary: false,
            onTap: () async {
              await Get.to<KennelHashersPage>(() => KennelHashersPage(k));
            },
          ),
        ],
        if (k.canManageKennel || k.canManageHashCash)
          (
            label: 'Edit Kennel',
            icon: Icons.settings_outlined,
            isPrimary: false,
            onTap: () async {
              final kennel = await _getKennel(k.publicKennelId);
              if (kennel != null) {
                await Get.to<KennelEditPage>(
                  () => KennelEditPage(
                    key: UniqueKey(),
                    kennelData: kennel,
                    appAccessFlags: k.appAccessFlags,
                    canEditKennelStatus: formController.canEditKennel,
                  ),
                );
                await Get.delete<KennelPageFormController>(force: true);
              }
            },
          ),
        if (k.canManagePublicWebContent || k.isAdmin) ...[
          (
            label: 'Edit Website',
            icon: Icons.language_outlined,
            isPrimary: false,
            onTap: () async {
              final websiteData = await _getKennelWebsite(k.publicKennelId);
              if (websiteData != null) {
                await Get.to<KennelWebsiteEditPage>(
                  () => KennelWebsiteEditPage(
                    key: UniqueKey(),
                    websiteData: websiteData,
                    publicKennelId: k.publicKennelId,
                    kennelName: k.kennelName,
                    kennelUniqueShortName: k.kennelUniqueShortName,
                  ),
                );
                await Get.delete<KennelWebsiteController>(force: true);
              }
            },
          ),
          (
            label: 'Design Website',
            icon: Icons.brush_outlined,
            isPrimary: false,
            onTap: () => _openWebsiteDesigner(k.kennelUniqueShortName),
          ),
        ],
        if (k.canManageRuns)
          (
            label: '+ Add Run',
            icon: Icons.add_circle_outline,
            isPrimary: true,
            onTap: () async {
              var lastRunDate = DateTime.now();
              for (final run in formController.allEvents) {
                if (run.eventStartDatetime.isAfter(lastRunDate)) {
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
      ],
      if (formController.hasAnyPlatformAdminPrivilege)
        (
          label: 'HC Admin Tools',
          icon: Icons.admin_panel_settings_outlined,
          isPrimary: false,
          onTap: () async {
            await Get.to<HcAdminToolsPage>(
              () => HcAdminToolsPage(
                allKennels: allKennels,
                canViewMonitor: formController.canViewMonitor,
                canManageNewsflash: formController.canManageNewsflash,
              ),
            );
          },
        ),
      (
        label: 'Log out',
        icon: Icons.logout,
        isPrimary: false,
        onTap: () async {
          await box.clear();
          web.window.location.reload();
        },
      ),
    ];
  }

  /// Persistent left navigation rail (wide screens): kennel context header +
  /// the kennel/admin actions as nav items.
  Widget _navRail() {
    return GetBuilder<RunListPageController>(
      id: 'appBar',
      builder: (c) {
        final k = c.kennel;
        final actions = _appBarActions(k);
        return Container(
          width: 232,
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    KennelLogo(
                      kennelLogoUrl: k.kennelLogo,
                      kennelShortName: k.kennelShortName,
                      logoHeight: 28,
                      leftPadding: 0,
                      rightPadding: 8,
                    ),
                    Expanded(
                      child: Text(
                        k.kennelName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [for (final a in actions) _navItem(a)],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _navItem(_BarAction a) {
    final color =
        a.isPrimary ? const Color(0xFFB91C1C) : const Color(0xFF334155);
    return ListTile(
      dense: true,
      leading: Icon(a.icon, size: 20, color: color),
      title: Text(
        a.label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: a.isPrimary ? FontWeight.w700 : FontWeight.w500,
          color: color,
        ),
      ),
      onTap: a.onTap,
    );
  }

  Widget _appBarActionsMenu(List<_BarAction> actions) {
    return PopupMenuButton<int>(
      tooltip: 'Menu',
      color: Colors.white,
      position: PopupMenuPosition.under,
      // A labelled pill reads as a button far more clearly than a bare kebab.
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF1D4ED8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu, size: 18, color: Colors.white),
            SizedBox(width: 6),
            Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      onSelected: (i) => actions[i].onTap(),
      itemBuilder: (context) => [
        for (var i = 0; i < actions.length; i++)
          PopupMenuItem<int>(
            value: i,
            child: Row(
              children: [
                Icon(
                  actions[i].icon,
                  size: 18,
                  color: actions[i].isPrimary
                      ? const Color(0xFFB91C1C)
                      : const Color(0xFF475569),
                ),
                const SizedBox(width: 12),
                Text(
                  actions[i].label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        actions[i].isPrimary ? FontWeight.w700 : FontWeight.w500,
                    color: actions[i].isPrimary
                        ? const Color(0xFFB91C1C)
                        : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _appBarBtn(
    String label, {
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: isPrimary ? const Color(0xFFB91C1C) : Colors.white,
        foregroundColor: isPrimary ? Colors.white : const Color(0xFF475569),
        side: BorderSide(
          color: isPrimary ? const Color(0xFFB91C1C) : const Color(0xFFE2E8F0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              formController.kennel.canManageHashCash) ...[
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
                      appAccessFlags: formController.kennel.appAccessFlags,
                      canEditKennelStatus: formController.canEditKennel,
                    ),
                  );
                  await Get.delete<KennelPageFormController>(
                    force: true,
                  );
                }
              },
            ),
            const SizedBox(height: 16),
          ],
          if (formController.kennel.canManagePublicWebContent ||
              formController.kennel.isAdmin) ...[
            _appBarBtn(
              'Edit Website',
              onPressed: () async {
                final websiteData = await _getKennelWebsite(
                  formController.kennel.publicKennelId,
                );
                if (websiteData != null) {
                  await Get.to<KennelWebsiteEditPage>(
                    () => KennelWebsiteEditPage(
                      key: UniqueKey(),
                      websiteData: websiteData,
                      publicKennelId: formController.kennel.publicKennelId,
                      kennelName: formController.kennel.kennelName,
                      kennelUniqueShortName:
                          formController.kennel.kennelUniqueShortName,
                    ),
                  );
                  await Get.delete<KennelWebsiteController>(force: true);
                }
              },
            ),
            const SizedBox(height: 16),
            _appBarBtn(
              'Design Website',
              onPressed: () => _openWebsiteDesigner(
                formController.kennel.kennelUniqueShortName,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _getDetailOnly() {
    // Fixed header (toggle + search) above a plain scrolling list. The previous
    // NestedScrollView/SliverAppBar floating header swallowed taps on the
    // toggle, so it's kept out of the slivers and pinned here where gestures
    // are reliable — and it stays visible while the list scrolls.
    return Column(
      children: <Widget>[
        Container(
          color: const Color(0xFFF1F5F9),
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          child: Column(
            children: <Widget>[
              _futurePastToggle(),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                margin: const EdgeInsets.only(left: 20, right: 20),
                child: _searchBar(),
              ),
            ],
          ),
        ),
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            controller: _listScrollController,
            child: SafeArea(
              top: false,
              bottom: false,
              child: NotificationListener<ScrollNotification>(
                // Lazy-load older past runs as the user nears the bottom.
                // loadMorePastRuns() self-guards (past mode only, not already
                // loading, more available), so firing often is harmless.
                onNotification: (ScrollNotification n) {
                  if (n.metrics.pixels >= n.metrics.maxScrollExtent - 400) {
                    unawaited(formController.loadMorePastRuns());
                  }
                  return false;
                },
                child: ListView.separated(
                  controller: _listScrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: formController.displayedEventsDetails.length + 1,
                  padding: const EdgeInsets.only(top: 5),
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(height: 5),
                  itemBuilder: (BuildContext context, int index) {
                    return index == formController.displayedEventsDetails.length
                        ? _pastListFooter()
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
                          color: formController.textThemeIsLight
                              ? HexColor.darken(
                                  HexColor(formController.backgroundColor),
                                )
                              : HexColor.lighten(
                                  HexColor(formController.backgroundColor),
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
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Footer below the runs list: shows a spinner while older past runs are being
  // lazy-loaded; otherwise just bottom spacing.
  Widget _pastListFooter() {
    return Obx(() {
      if (formController.isLoadingMorePast.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        );
      }
      return const SizedBox(height: 100);
    });
  }

  // Future / Past segmented toggle for the narrow (phone) layout. The wide
  // layout has this as a TabBar in _runList(); narrow had no way to switch, so
  // a kennel with only past runs (or a user wanting history) was stuck.
  Widget _futurePastToggle() {
    final isFuture = formController.displayRuns != EDisplayRuns.past;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: _toggleSegment(
              TEXT_FUTURE_RUNS,
              selected: isFuture,
              onTap: () => _setDisplayRuns(EDisplayRuns.future),
            ),
          ),
          Expanded(
            child: _toggleSegment(
              TEXT_PAST_RUNS,
              selected: !isFuture,
              onTap: () => _setDisplayRuns(EDisplayRuns.past),
            ),
          ),
        ],
      ),
    );
  }

  void _setDisplayRuns(EDisplayRuns which) {
    formController.displayRuns = which;
    formController.tabController.animateTo(which == EDisplayRuns.future ? 0 : 1);
    formController.setDisplayedEvents();
  }

  Widget _toggleSegment(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.red.shade900 : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
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
              focusNode: formController.searchFocusNode,
              controller: formController.searchController,
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
          if (formController.searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                formController.searchController.text = '';
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
                .eventForSingleEventDetailsView.value.runDetails.publicEventId;
            return Scrollbar(
              thumbVisibility: true,
              controller: _scrollController3,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: formController.displayedEvents.length,
                controller: _scrollController3,
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final event = formController.displayedEvents[index];
                  final isSelected = selectedId == event.publicEventId;
                  return GetBuilder<RunListPageController>(
                    id: 'chatCountBadge',
                    builder: (controller) {
                      final canEdit = formController.kennel.canManageRuns ||
                          formController.kennel.canManageHashCash;
                      return RunListItem(
                        event: event,
                        isSelected: isSelected,
                        chatCount: formController
                                .thisEventChatCount[event.publicEventId] ??
                            0,
                        onTap: () async {
                          formController.eventForSingleEventDetailsView.value =
                              await querySingleEvent(event.publicEventId);
                        },
                        onEdit: canEdit
                            ? () => _editRunFromList(event.publicEventId)
                            : null,
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

  // Opens the run editor straight from a list card's "Edit" button. Fetches the
  // full run details (the editor needs the rich RunDetailsModel, not the lighter
  // list model), then mirrors the detail panel's post-edit refresh so the list
  // and any open detail view reflect the changes.
  Future<void> _editRunFromList(String publicEventId) async {
    final edr = await querySingleEvent(publicEventId);
    await Get.to<RunEditPage>(
      () => RunEditPage(
        runData: edr.runDetails,
        kennelData: formController.kennel,
        isAddMode: false,
      ),
    );
    unawaited(formController.refreshEvents());
    formController.eventForSingleEventDetailsView.value =
        await querySingleEvent(publicEventId);
  }

  Future<KennelModel?> _getKennel(String publicKennelId) async {
    KennelModel? rdm;

    final deviceId = box.get(HIVE_DEVICE_ID) as String;
    final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';

    final accessToken = Utilities.generateToken(
      deviceId,
      'hcportal_getKennel',
      paramString: '$deviceSecret:$publicKennelId',
    );

    final body = <String, String>{
      'queryType': 'getKennel',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'publicKennelId': publicKennelId,
    };

    final result = await ServiceCommon.sendHttpPostToHC6Api(body);
    if (kDebugMode) debugPrint(result is ApiError
        ? 'SP 11 [getKennel] called — FAILED'
        : 'SP 11 [getKennel] called — success');
    if (result case ApiSuccess(:final body)) {
      final jsonItems = json.decode(body) as List<dynamic>;
      rdm = KennelModel.fromJson(
        (jsonItems[0] as List<dynamic>)[0] as Map<String, dynamic>,
      );
    }

    return rdm;
  }

  Future<KennelWebsiteModel?> _getKennelWebsite(String publicKennelId) async {
    final deviceId = box.get(HIVE_DEVICE_ID) as String;
    final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';

    final accessToken = Utilities.generateToken(
      deviceId,
      'hcportal_getKennelWebsite',
      paramString: '$deviceSecret:$publicKennelId',
    );

    final body = <String, String>{
      'queryType': 'getKennelWebsite',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'publicKennelId': publicKennelId,
    };

    final result = await ServiceCommon.sendHttpPostToHC6Api(body);
    if (kDebugMode) debugPrint(result is ApiError
        ? 'SP [getKennelWebsite] called — FAILED'
        : 'SP [getKennelWebsite] called — success');
    if (result case ApiSuccess(:final body)) {
      final jsonItems = json.decode(body) as List<dynamic>;
      final rows = jsonItems[0] as List<dynamic>;
      if (rows.isNotEmpty) {
        return KennelWebsiteModel.fromJson(rows[0] as Map<String, dynamic>);
      }
    }

    return null;
  }

  Future<void> _openWebsiteDesigner(String kennelSlug) async {
    final deviceId = box.get(HIVE_DEVICE_ID) as String;
    final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';

    final accessToken = Utilities.generateToken(
      deviceId,
      'hcportal_generateWebAdminToken',
      paramString: deviceSecret,
    );

    final body = <String, String>{
      'queryType': 'generateWebAdminToken',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'kennelSlug': kennelSlug,
    };

    final webTokenResult = await ServiceCommon.sendHttpPostToHC6Api(body);
    if (webTokenResult is ApiError) {
      if (kDebugMode) debugPrint('SP [generateWebAdminToken] — FAILED');
      return;
    }
    final decoded = json.decode((webTokenResult as ApiSuccess).body) as List<dynamic>;
    final rows = (decoded[0] as List<dynamic>);
    if (rows.isEmpty) return;

    final row = rows[0] as Map<String, dynamic>;
    // Error envelope check
    if ((row['Success'] as int?) == 0) {
      final msg = row['ErrorMessage'] as String? ?? 'Unable to open designer.';
      await CoreUtilities.showAlert('Design Website', msg, 'OK');
      return;
    }

    final token = row['Token'] as String?;
    if (token == null || token.isEmpty) return;

    final isLocal = web.window.location.href.contains('localhost');
    final base = isLocal ? 'http://localhost:3000' : 'https://www.hashruns.org';
    final url = '$base/$kennelSlug/admin/layout?token=$token';
    await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
  }

  Widget _renderRunDetail(EventDetailsResult edr) {
    final canEdit = formController.kennel.canManageRuns ||
        formController.kennel.canManageHashCash;
    return RunDetailWidget(
      rdm: edr.runDetails,
      participants: edr.participants,
      textThemeIsLight: formController.textThemeIsLight,
      isNarrowScreen: formController.isNarrowScreen.value,
      backgroundColor: formController.backgroundColor,
      onEdit: canEdit
          ? () => _editRunFromList(edr.runDetails.publicEventId ?? '')
          : null,
    );
  }
}
