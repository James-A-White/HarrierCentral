/// Kennel Tags Page Controls
///
/// This file defines the UI control configurations for the Kennel Tags tab.
/// It uses an extension on [KennelPageFormController] to keep control
/// initialization organized and separate from the main controller.

part of '../../kennel_page_new_controller.dart';

// ---------------------------------------------------------------------------
// Control Initialization Extension
// ---------------------------------------------------------------------------

/// Extension that adds kennel run tags control initialization to the controller.
extension KennelRunTagsControlsExtension on KennelPageFormController {
  /// Initializes the UI control for the Kennel Tags tab.
  ///
  /// This creates a single [UiControlDefinition] that tracks the overall
  /// tags selection state for tab validation purposes.
  void initKennelRunTagsControls() {
    final tabKey = KennelTabType.tags.key;
    const tabIndex = 4; // Tags tab index

    _registerRunTagsControl(tabKey, tabIndex);
  }

  // ---------------------------------------------------------------------------
  // Run Tags Control
  // ---------------------------------------------------------------------------

  /// Registers the run tags control for tab validation.
  ///
  /// This control tracks whether any tags are selected to determine
  /// the tab's completion status.
  void _registerRunTagsControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_runTags';

    // Calculate initial selected count
    final initialCount = selectedRunTagCount.value;

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.checkbox,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Default Run Tags',
        FontAwesome.tags,
        'Select the default tags that will be applied to new runs '
            'created for this kennel.\n\n'
            'These tags help hashers understand what to expect from your runs '
            'and can be overridden for individual runs.',
      ),
      editedFieldValue: initialCount > 0 ? initialCount.toString() : null,
      originalFieldValue: _getOriginalTagCount().toString(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Run Tags',
      maxLines: 1,
      includeOverrideButton: false,
      tabIndex: tabIndex,
      // Tags are optional, so minStringLength = 0 means valid even if empty
      minStringLength: 0,
      updateEditedValue: (String? value) {
        // Value is updated via updateRunTags method
      },
      onUndo: resetRunTagsToOriginal,
    );
  }

  /// Calculates the number of originally selected tags.
  int _getOriginalTagCount() {
    final tags1 = originalData.defaultRunTags1;
    final tags2 = originalData.defaultRunTags2;
    final tags3 = originalData.defaultRunTags3;

    int count = 0;

    for (final tag in RunTag.values) {
      final isSelected = switch (tag.tagsInteger) {
        1 => (tags1 & tag.bitMask) != 0,
        2 => (tags2 & tag.bitMask) != 0,
        4 => (tags3 & tag.bitMask) != 0,
        _ => false,
      };

      if (isSelected) count++;
    }

    return count;
  }
}
