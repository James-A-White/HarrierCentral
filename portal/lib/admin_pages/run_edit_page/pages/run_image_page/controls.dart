/// Image Page Controls
///
/// This file defines the UI control configurations for the Image tab.

part of '../../run_edit_page_controller.dart';

// ---------------------------------------------------------------------------
// Control Initialization Extension
// ---------------------------------------------------------------------------

/// Extension that adds image control initialization to the controller.
extension ImageControlsExtension on RunEditPageController {
  /// Initializes all UI controls for the Image tab.
  void initImageControls() {
    final tabKey = RunTabType.image.key;
    const tabIndex = 2;

    _registerEventImageControl(tabKey, tabIndex);
  }

  // ---------------------------------------------------------------------------
  // Individual Control Registration
  // ---------------------------------------------------------------------------

  void _registerEventImageControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunImageField.eventImage.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.imageUpload,
      fileType: DocumentType.eventImage,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Event Image',
        FontAwesome5Solid.image,
        'Upload an image for this run.\n\n'
            'This image will be displayed in run listings and on the run '
            'details page. Recommended size is 800x600 pixels or larger.',
      ),
      editedFieldValue: editedData.value.eventImage,
      originalFieldValue: originalData.eventImage,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Event image',
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value.copyWith(eventImage: value);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }
}
