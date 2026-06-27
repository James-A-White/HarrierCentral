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
  });

  final T controller;
  final double width;
  final Color? railColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: railColor ?? Colors.blue.shade600,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 10),
        itemCount: controller.allTabs.length,
        itemBuilder: (context, i) =>
            _RailItem<T>(controller: controller, tabIndex: i),
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
              // Selected row reads as the active "page" — white tab pulled out
              // of the blue rail, matching the horizontal bar's selected look.
              color: isSelected ? Colors.white : Colors.transparent,
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
