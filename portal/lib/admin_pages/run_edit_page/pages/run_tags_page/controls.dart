/// Run Tags Page Controls
///
/// This file defines the UI control configurations for the Run Tags tab.
/// It uses an extension on [RunEditPageController] to keep control
/// initialization organized and separate from the main controller.

part of '../../run_edit_page_controller.dart';

// ---------------------------------------------------------------------------
// Control Initialization Extension
// ---------------------------------------------------------------------------

/// Extension that adds run tags control initialization to the controller.
extension RunTagsControlsExtension on RunEditPageController {
  /// Initializes all UI controls for the Run Tags tab.
  ///
  /// This creates controls for:
  /// - A generic sidebar entry for the tab
  /// - A run tags control that tracks the overall selection state
  void initRunTagsControls() {
    final tabKey = RunTabType.runTags.key;
    const tabIndex = 4;

    _registerRunTagsGenericControl(tabKey, tabIndex);
    _registerRunTagsControl(tabKey, tabIndex);
  }

  // ---------------------------------------------------------------------------
  // Individual Control Registration
  // ---------------------------------------------------------------------------

  /// Registers a generic sidebar entry for the Run Tags tab.
  void _registerRunTagsGenericControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_generic';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.invisible,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: fieldKey,
      sidebarData: const SideBarData(
        'Run Tags',
        FontAwesome.tags,
        'Select tags that describe this run.\n\n'
            'Tags are organized into categories:\n'
            '• Theme (Normal run, Red Dress, Full Moon, etc.)\n'
            '• Restrictions (Men only, Women only, Kids allowed, etc.)\n'
            '• What to bring (Flashlight, Dry clothes, etc.)\n'
            '• Run Type (Pub crawl, Short trail, Long trail, etc.)\n'
            '• Terrain (Shiggy, City, Hills, etc.)\n'
            '• Hares (Live hare, Dead hare, etc.)\n'
            '• Other (On-After, Parking, etc.)',
      ),
      editedFieldValue: null,
      originalFieldValue: null,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Run tags',
      tabIndex: tabIndex,
      updateEditedValue: (_) {},
    );
  }

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
        'Run Tags',
        FontAwesome.tags,
        'Select tags that describe this run\'s characteristics.\n\n'
            'Tags help hashers understand what to expect from the run, such as '
            'terrain type, difficulty level, and special requirements.',
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
    final t1 = originalData.tags1;
    final t2 = originalData.tags2;
    final t3 = originalData.tags3;

    int count = 0;

    for (final tag in RunTag.values) {
      final isSelected = switch (tag.tagsInteger) {
        1 => (t1 & tag.bitMask) != 0,
        2 => (t2 & tag.bitMask) != 0,
        4 => (t3 & tag.bitMask) != 0,
        _ => false,
      };

      if (isSelected) count++;
    }

    return count;
  }
}
