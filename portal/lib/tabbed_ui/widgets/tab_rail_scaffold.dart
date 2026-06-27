import 'package:hcportal/imports.dart';

/// Responsive tab layout shared by the admin editors.
///
/// - **Wide screens:** a [VerticalTabRail] down the left + the content.
/// - **Narrow/mobile:** the editor's existing [narrowTabBar] (a
///   [ResponsiveTabBar] hamburger, or a plain horizontal `TabBar`) above the
///   content — i.e. each editor keeps whatever it did before on small screens.
///
/// [tabBarView] is the shared content (a `TabBarView`) for both layouts.
/// [groups] is forwarded to the rail to draw hairline dividers between tab
/// groups (kennel editor only); leave null for a flat rail.
class TabRailScaffold<T extends TabUiController> extends StatelessWidget {
  const TabRailScaffold({
    super.key,
    required this.controller,
    required this.railColor,
    required this.tabBarView,
    required this.narrowTabBar,
    this.groups,
  });

  final T controller;
  final Color railColor;
  final Widget tabBarView;
  final Widget narrowTabBar;
  final List<List<int>>? groups;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isWide =
          controller.screenSize.value == EScreenSize.isNormalScreen;
      if (isWide) {
        return Row(
          children: [
            VerticalTabRail<T>(
              controller: controller,
              railColor: railColor,
              groups: groups,
            ),
            Expanded(child: tabBarView),
          ],
        );
      }
      return Column(
        children: [
          narrowTabBar,
          Expanded(child: tabBarView),
        ],
      );
    });
  }
}
