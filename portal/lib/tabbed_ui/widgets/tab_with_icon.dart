import 'package:hcportal/imports.dart';

class TabWithIcon<T extends TabUiController> extends StatelessWidget {
  const TabWithIcon({
    super.key,
    required this.label,
    required this.tabIndex,
    required this.controller,
  });

  final String label;
  final int tabIndex;
  final T controller;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Obx(() {
        // Use the reactive currentIndex instead of tabController.index
        final isSelected = tabIndex == controller.currentIndex.value;
        final tabDef = controller.allTabs[tabIndex];
        final status = controller.tabStatus[tabIndex].value;
        final locked = tabDef.isTabLockable
            ? controller.tabLocked[tabIndex].value
            : TabLocked.tabUnlocked;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconTheme(
              data: IconThemeData(
                color: isSelected ? Colors.black : Colors.white,
                size: 25,
              ),
              child: _buildTabContent(status, locked, isSelected),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTabContent(TabStatus status, TabLocked locked, bool isSelected) {
    final labelWidget = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: isSelected ? 'AvenirNextBold' : 'AvenirNext',
          color: isSelected ? Colors.black : Colors.white,
          fontSize: 15,
        ),
      ),
    );

    final icons = <Widget>[];

    // Leading icon based on status
    if (locked != TabLocked.tabLocked) {
      icons.add(_getStatusIcon(status, isSelected));
    } else if (status == TabStatus.isCompleteAndValid) {
      icons.add(const Icon(Entypo.check));
    } else {
      icons.add(const Icon(Fontisto.locked));
    }

    icons.add(labelWidget);

    // Trailing lock icon
    if (locked == TabLocked.tabLocked &&
        status == TabStatus.isCompleteAndValid) {
      icons.add(const Icon(Fontisto.locked));
    }

    return Row(children: icons);
  }

  Widget _getStatusIcon(TabStatus status, bool isSelected) {
    return switch (status) {
      TabStatus.isCompleteAndValid => const Icon(Entypo.check),
      TabStatus.isEmpty => const Icon(Ionicons.square_outline),
      TabStatus.isInProgress => const Icon(AntDesign.form),
      TabStatus.isInvalid => Icon(
          FontAwesome.warning,
          // Red on white (selected), yellow on blue (unselected)
          color: isSelected ? Colors.red : Colors.yellow,
        ),
      _ => const SizedBox.shrink(),
    };
  }
}
