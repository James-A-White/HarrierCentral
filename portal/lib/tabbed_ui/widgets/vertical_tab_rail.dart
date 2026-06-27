import 'package:hcportal/imports.dart';

/// A persistent vertical tab rail for wide screens — the left-hand alternative
/// to the horizontal [TabBar] when an editor has many tabs (it scales without
/// clipping or squishing). Drives the same [TabController] as the horizontal
/// bar, so selection stays in sync, and mirrors [TabWithIcon] styling
/// (white-on-blue, black-on-white when selected) with the per-tab validation
/// icons. Each row is independently reactive (its own [Obx]) so status and
/// selection updates repaint correctly inside the lazily-built list.
class VerticalTabRail<T extends TabUiController> extends StatelessWidget {
  const VerticalTabRail({
    super.key,
    required this.controller,
    this.width = 210,
    this.railColor,
    this.groups,
  });

  final T controller;
  final double width;
  final Color? railColor;

  /// Optional grouping: each inner list is tab indices (in display order) for
  /// one group, and a hairline divider is drawn between groups. When null the
  /// rail renders every tab flat in [TabUiController.allTabs] order.
  final List<List<int>>? groups;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (groups != null) {
      for (var g = 0; g < groups!.length; g++) {
        if (g > 0) children.add(const _RailDivider());
        for (final idx in groups![g]) {
          children.add(_RailItem<T>(controller: controller, tabIndex: idx));
        }
      }
    } else {
      for (var i = 0; i < controller.allTabs.length; i++) {
        children.add(_RailItem<T>(controller: controller, tabIndex: i));
      }
    }

    return Container(
      width: width,
      color: railColor ?? Colors.blue.shade600,
      child: ListView(
        padding: const EdgeInsets.only(top: 10),
        children: children,
      ),
    );
  }
}

/// Hairline divider between tab groups.
class _RailDivider extends StatelessWidget {
  const _RailDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Container(
        height: 1,
        color: Colors.white.withValues(alpha: 0.35),
      ),
    );
  }
}

class _RailItem<T extends TabUiController> extends StatelessWidget {
  const _RailItem({required this.controller, required this.tabIndex});

  final T controller;
  final int tabIndex;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isSelected = tabIndex == controller.currentIndex.value;
      final tabDef = controller.allTabs[tabIndex];
      final status = controller.tabStatus[tabIndex].value;
      final locked = tabDef.isTabLockable
          ? controller.tabLocked[tabIndex].value
          : TabLocked.tabUnlocked;

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.tabController.animateTo(tabIndex),
          child: Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              // Selected row reads as the active "page" — pulled out of the blue
              // rail in the off-white content colour (scaffold background) so it
              // blends seamlessly into the content area to its right.
              color: isSelected ? Colors.brown.shade50 : Colors.transparent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
            ),
            child: IconTheme(
              data: IconThemeData(
                color: isSelected ? Colors.black : Colors.white,
                size: 22,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 26,
                    child: Center(child: _statusIcon(status, locked, isSelected)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tabDef.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: isSelected ? 'AvenirNextBold' : 'AvenirNext',
                        color: isSelected ? Colors.black : Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _statusIcon(TabStatus status, TabLocked locked, bool isSelected) {
    if (locked == TabLocked.tabLocked) {
      return status == TabStatus.isCompleteAndValid
          ? const Icon(Entypo.check)
          : const Icon(Fontisto.locked);
    }
    return switch (status) {
      TabStatus.isCompleteAndValid => const Icon(Entypo.check),
      TabStatus.isEmpty => const Icon(Ionicons.square_outline),
      TabStatus.isInProgress => const Icon(AntDesign.form),
      TabStatus.isInvalid => Icon(
          FontAwesome.warning,
          // Red on the white selected row, yellow on the blue rail.
          color: isSelected ? Colors.red : Colors.yellow,
        ),
      _ => const SizedBox.shrink(),
    };
  }
}
