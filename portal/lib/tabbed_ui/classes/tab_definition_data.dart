import 'package:hcportal/imports.dart';

class TabDefinitionData {
  const TabDefinitionData({
    required this.key,
    required this.title,
    required this.tabIndex,
    required this.hasCustomTabStatusFunction,
    required this.showTabInSubmitSummary,
    required this.isTabLockable,
    required this.sidebarData,
  });

  final String key;
  final String title;
  final SideBarData sidebarData;
  final int tabIndex;
  final bool hasCustomTabStatusFunction;
  final bool showTabInSubmitSummary;
  final bool isTabLockable;
}
