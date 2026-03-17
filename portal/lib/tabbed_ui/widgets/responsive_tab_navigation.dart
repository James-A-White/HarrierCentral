/// Responsive Tab Navigation Widget
///
/// Provides a responsive navigation system that switches between:
/// - Tab bar (for wide/normal screens)
/// - Hamburger menu dropdown (for narrow and mobile screens)

import 'package:hcportal/imports.dart';

// ---------------------------------------------------------------------------
// Responsive Tab Bar
// ---------------------------------------------------------------------------

/// A responsive tab bar that shows a traditional tab bar on wide screens
/// and a hamburger menu dropdown on narrow/mobile screens.
class ResponsiveTabBar<T extends TabUiController> extends StatelessWidget {
  const ResponsiveTabBar({
    super.key,
    required this.controller,
    required this.formKey,
    this.tabBarColor,
  });

  final T controller;
  final GlobalKey<FormState> formKey;
  final Color? tabBarColor;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isNormalScreen =
          controller.screenSize.value == EScreenSize.isNormalScreen;

      if (isNormalScreen) {
        // Wide screen: Show traditional tab bar
        return _WideScreenTabBar<T>(
          controller: controller,
          formKey: formKey,
          tabBarColor: tabBarColor,
        );
      } else {
        // Narrow/Mobile: Show hamburger menu
        return _HamburgerMenuBar<T>(
          controller: controller,
          formKey: formKey,
          tabBarColor: tabBarColor,
        );
      }
    });
  }
}

// ---------------------------------------------------------------------------
// Wide Screen Tab Bar (Traditional)
// ---------------------------------------------------------------------------

/// Traditional tab bar for wide screens.
class _WideScreenTabBar<T extends TabUiController> extends StatelessWidget {
  const _WideScreenTabBar({
    required this.controller,
    required this.formKey,
    this.tabBarColor,
  });

  final T controller;
  final GlobalKey<FormState> formKey;
  final Color? tabBarColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: tabBarColor ?? Colors.blue.shade600,
      padding: const EdgeInsets.only(top: 10),
      child: Form(
        key: formKey,
        child: TabBar(
          controller: controller.tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.white,
          indicatorSize: TabBarIndicatorSize.label,
          indicator: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
            color: Colors.white,
          ),
          tabs: _buildTabs(),
        ),
      ),
    );
  }

  List<Widget> _buildTabs() {
    return controller.allTabs.map((tab) {
      return TabWithIcon<T>(
        label: tab.title,
        tabIndex: tab.tabIndex,
        controller: controller,
      );
    }).toList();
  }
}

// ---------------------------------------------------------------------------
// Hamburger Menu Bar (For Narrow/Mobile Screens)
// ---------------------------------------------------------------------------

/// Hamburger menu bar for narrow and mobile screens.
/// Shows a dropdown menu to select tabs.
class _HamburgerMenuBar<T extends TabUiController> extends StatelessWidget {
  const _HamburgerMenuBar({
    required this.controller,
    required this.formKey,
    this.tabBarColor,
  });

  final T controller;
  final GlobalKey<FormState> formKey;
  final Color? tabBarColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: tabBarColor ?? Colors.blue.shade600,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Form(
        key: formKey,
        child: Obx(() {
          final currentTab = controller.allTabs[controller.currentIndex.value];
          final currentStatus =
              controller.tabStatus[controller.currentIndex.value].value;

          return Row(
            children: [
              // Hamburger menu button
              _HamburgerMenuButton<T>(
                controller: controller,
                tabBarColor: tabBarColor,
              ),
              const SizedBox(width: 16),
              // Current tab indicator
              Expanded(
                child: _CurrentTabIndicator(
                  title: currentTab.title,
                  status: currentStatus,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hamburger Menu Button
// ---------------------------------------------------------------------------

/// Button that opens the tab selection menu.
class _HamburgerMenuButton<T extends TabUiController> extends StatelessWidget {
  const _HamburgerMenuButton({
    required this.controller,
    this.tabBarColor,
  });

  final T controller;
  final Color? tabBarColor;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      icon: const Icon(
        Icons.menu,
        color: Colors.white,
        size: 28,
      ),
      tooltip: 'Select tab',
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      offset: const Offset(0, 50),
      onSelected: (index) {
        controller.tabController.animateTo(index);
      },
      itemBuilder: (context) => _buildMenuItems(),
    );
  }

  List<PopupMenuEntry<int>> _buildMenuItems() {
    final items = <PopupMenuEntry<int>>[];

    for (var i = 0; i < controller.allTabs.length; i++) {
      final tab = controller.allTabs[i];
      final status = controller.tabStatus[i].value;
      final isSelected = i == controller.currentIndex.value;
      final tabDef = controller.allTabs[i];
      final locked = tabDef.isTabLockable
          ? controller.tabLocked[i].value
          : TabLocked.tabUnlocked;

      items.add(
        PopupMenuItem<int>(
          value: i,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: isSelected
                ? BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: Row(
              children: [
                // Status icon
                SizedBox(
                  width: 28,
                  child: _getStatusIcon(status, locked),
                ),
                const SizedBox(width: 12),
                // Tab title
                Expanded(
                  child: Text(
                    tab.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.blue.shade700 : Colors.black87,
                    ),
                  ),
                ),
                // Selected indicator
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      );

      // Add divider between items (except after last item)
      if (i < controller.allTabs.length - 1) {
        items.add(const PopupMenuDivider(height: 1));
      }
    }

    return items;
  }

  Widget _getStatusIcon(TabStatus status, TabLocked locked) {
    if (locked == TabLocked.tabLocked) {
      return Icon(
        Fontisto.locked,
        size: 18,
        color: Colors.grey.shade600,
      );
    }

    return switch (status) {
      TabStatus.isCompleteAndValid => Icon(
          Entypo.check,
          size: 20,
          color: Colors.green.shade600,
        ),
      TabStatus.isEmpty => Icon(
          Ionicons.square_outline,
          size: 18,
          color: Colors.grey.shade500,
        ),
      TabStatus.isInProgress => Icon(
          AntDesign.form,
          size: 18,
          color: Colors.orange.shade600,
        ),
      TabStatus.isInvalid => Icon(
          FontAwesome.warning,
          size: 18,
          color: Colors.red.shade600,
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

// ---------------------------------------------------------------------------
// Current Tab Indicator
// ---------------------------------------------------------------------------

/// Shows the currently selected tab name and status.
class _CurrentTabIndicator extends StatelessWidget {
  const _CurrentTabIndicator({
    required this.title,
    required this.status,
  });

  final String title;
  final TabStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _getStatusIcon(status),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getStatusIcon(TabStatus status) {
    return switch (status) {
      TabStatus.isCompleteAndValid => Icon(
          Entypo.check,
          size: 20,
          color: Colors.green.shade600,
        ),
      TabStatus.isEmpty => Icon(
          Ionicons.square_outline,
          size: 18,
          color: Colors.grey.shade500,
        ),
      TabStatus.isInProgress => Icon(
          AntDesign.form,
          size: 18,
          color: Colors.orange.shade600,
        ),
      TabStatus.isInvalid => Icon(
          FontAwesome.warning,
          size: 18,
          color: Colors.red.shade600,
        ),
      _ => const SizedBox.shrink(),
    };
  }
}
