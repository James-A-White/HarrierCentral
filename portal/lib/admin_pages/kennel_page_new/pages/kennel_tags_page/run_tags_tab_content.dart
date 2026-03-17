/// Kennel Run Tags Tab Content
///
/// This file defines the UI for the Run Tags tab in the kennel editing form.
/// It displays selectable chips organized by tag groups, similar to the
/// application form tags UI pattern.

import 'package:hcportal/imports.dart';
import '../../kennel_page_new_controller.dart';
import '../../kennel_page_new_enums.dart';

// ---------------------------------------------------------------------------
// Run Tags Tab Content Widget
// ---------------------------------------------------------------------------

/// Content widget for the Kennel Run Tags tab.
///
/// Displays selectable filter chips organized by [RunTagGroup] categories.
/// Each chip represents a [RunTag] that can be toggled on/off.
///
/// Features:
/// - Chips organized by group (Theme, Restrictions, etc.)
/// - Sidebar help integration on hover
/// - Visual feedback for selected state
/// - Reactive updates using GetX
class KennelRunTagsTabContent extends StatelessWidget {
  const KennelRunTagsTabContent({
    required this.controller,
    super.key,
  });

  /// The parent controller for state management and sidebar integration.
  final KennelPageFormController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      primary: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildGroupSections(),
      ),
    );
  }

  /// Builds all tag group sections.
  List<Widget> _buildGroupSections() {
    final widgets = <Widget>[];

    for (final group in RunTagGroup.values) {
      widgets
        ..add(_buildGroupLabel(group.label))
        ..add(_buildChipsWrap(group))
        ..add(const SizedBox(height: 16));
    }

    // Add bottom padding
    widgets.add(const SizedBox(height: 20));

    return widgets;
  }

  /// Builds a group label widget using the standard orange category style.
  Widget _buildGroupLabel(String label) {
    return HelperWidgets().categoryLabelWidget(label, bottomMargin: 10);
  }

  /// Builds a wrap of chips for the given group.
  Widget _buildChipsWrap(RunTagGroup group) {
    final tagsInGroup =
        RunTag.values.where((tag) => tag.parentKey == group.groupKey).toList();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: tagsInGroup.map((tag) => _buildTagChip(tag, group)).toList(),
    );
  }

  /// Builds an individual tag chip.
  Widget _buildTagChip(RunTag tag, RunTagGroup group) {
    return MouseRegion(
      onEnter: (_) => _showSidebarHelp(tag, group),
      onExit: (_) => _hideSidebarHelp(),
      child: Obx(() => _buildFilterChip(tag)),
    );
  }

  /// Shows contextual help in the sidebar.
  void _showSidebarHelp(RunTag tag, RunTagGroup group) {
    controller.setSidebarData(
      '',
      title: '${group.label}: ${tag.title}',
      shortDescription: tag.description,
      icon: tag.icon,
    );
  }

  /// Hides the sidebar help.
  void _hideSidebarHelp() {
    controller.setSidebarData('${KennelTabType.tags.key}_generic');
  }

  /// Builds a custom tag button matching the design mockup.
  ///
  /// Design:
  /// - Unselected: Grey border, white background, icon in green-bordered circle
  /// - Selected: Green border, light green background, checkmark + icon circle
  /// - Text wraps 1-3 lines, all buttons same height
  Widget _buildFilterChip(RunTag tag) {
    final isSelected = controller.runTagSelectionStatus[tag.key]?.value == 1;

    return GestureDetector(
      onTap: () {
        controller.updateRunTags(
          isSelected: !isSelected,
          tagKey: tag.key,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green.shade600 : Colors.grey.shade400,
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Checkmark (only when selected)
            if (isSelected) ...[
              Icon(
                Icons.check,
                size: 24,
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 8),
            ],
            // Icon in circle - fixed size container with centered icon
            SizedBox(
              width: 44,
              height: 44,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.green.shade600,
                    width: 2,
                  ),
                ),
                child: Icon(
                  tag.icon,
                  size: 22,
                  color: _getIconColor(tag),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Text label (1-3 lines)
            Text(
              tag.title,
              style: TextStyle(
                fontFamily: 'AvenirNextBold',
                fontSize: 15,
                height: 1.2,
                color:
                    isSelected ? Colors.green.shade800 : Colors.grey.shade700,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Returns an appropriate color for the tag icon.
  ///
  /// Uses the tag's inherent color where applicable (e.g., red for Red Dress),
  /// otherwise returns a default icon color.
  Color _getIconColor(RunTag tag) {
    // Map specific tags to their thematic colors
    return switch (tag) {
      RunTag.redDress => Colors.red,
      RunTag.fullMoon => Colors.amber.shade600,
      RunTag.familyHash => Colors.blue.shade600,
      RunTag.normalRun => Colors.green.shade600,
      RunTag.harriette => Colors.pink.shade400,
      RunTag.agm => Colors.purple.shade600,
      RunTag.drinkingPractice => Colors.orange.shade700,
      RunTag.hangoverRun => Colors.brown.shade400,
      RunTag.menOnly => Colors.blue.shade700,
      RunTag.womenOnly => Colors.pink.shade600,
      RunTag.kidsAllowed => Colors.lightBlue.shade400,
      RunTag.noKidsAllowed => Colors.red.shade400,
      RunTag.dogFriendly => Colors.brown.shade600,
      RunTag.noDogsAllowed => Colors.red.shade400,
      RunTag.bringFlashlight => Colors.amber.shade600,
      RunTag.waterOnTrail => Colors.blue.shade500,
      RunTag.swimStop => Colors.cyan.shade500,
      RunTag.nightRun => Colors.indigo.shade600,
      RunTag.shiggyRun => Colors.brown.shade500,
      RunTag.cityHash => Colors.blueGrey.shade600,
      RunTag.steepHills => Colors.green.shade700,
      RunTag.bikeHash => Colors.orange.shade600,
      RunTag.charityEvent => Colors.red.shade600,
      RunTag.campingHash => Colors.green.shade800,
      _ => Colors.grey.shade700,
    };
  }
}
