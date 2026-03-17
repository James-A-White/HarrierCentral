/// Kennel Songs Page Controls
///
/// This file defines the UI control configurations for the Kennel Songs tab.
/// It uses an extension on [KennelPageFormController] to keep control
/// initialization organized and separate from the main controller.

part of '../../kennel_page_new_controller.dart';

// ---------------------------------------------------------------------------
// Control Initialization Extension
// ---------------------------------------------------------------------------

/// Extension that adds kennel songs control initialization to the controller.
extension KennelSongsControlsExtension on KennelPageFormController {
  /// Initializes the UI control for the Kennel Songs tab.
  ///
  /// This creates a [UiControlDefinition] that tracks the overall songs
  /// state for tab validation/status purposes.
  void initKennelSongsControls() {
    final tabKey = KennelTabType.songs.key;
    final tabIndex = KennelTabType.songs.index;

    _registerSongsControl(tabKey, tabIndex);
  }

  // ---------------------------------------------------------------------------
  // Songs Control
  // ---------------------------------------------------------------------------

  /// Registers the songs control for tab status tracking.
  void _registerSongsControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_songList';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.checkbox,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Kennel Songs',
        FontAwesome5Solid.music,
        'Select songs from the global catalogue to add to your kennel.\n\n'
            'Checked songs will be associated with your kennel. '
            'Select a song to view its details on the right panel.',
      ),
      editedFieldValue: '0',
      originalFieldValue: '0',
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Kennel Songs',
      includeOverrideButton: false,
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        // Updated when song selections change
        uiControls[fieldKey]?.editedFieldValue = value;
      },
      onUndo: () {
        // Reset songs to original selection
        resetSongsToOriginal();
      },
    );
  }
}
