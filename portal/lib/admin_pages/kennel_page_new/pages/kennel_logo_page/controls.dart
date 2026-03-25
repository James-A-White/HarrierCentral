/// Kennel Logo Page Controls
///
/// This file defines the UI control configuration for the Logo tab.

part of '../../kennel_page_new_controller.dart';

// ---------------------------------------------------------------------------
// Control Initialization Extension
// ---------------------------------------------------------------------------

/// Extension that adds kennel logo control initialization to the controller.
extension KennelLogoControlsExtension on KennelPageFormController {
  /// Initializes all UI controls for the Logo tab.
  void initKennelLogoControls() {
    final tabKey = KennelTabType.kennelLogo.key;
    final tabIndex = KennelTabType.kennelLogo.index;

    _registerKennelLogoControl(tabKey, tabIndex);
  }

  // ---------------------------------------------------------------------------
  // Individual Control Registration
  // ---------------------------------------------------------------------------

  void _registerKennelLogoControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_logo';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.imageUpload,
      fileType: DocumentType.kennelLogo,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Kennel Logo',
        FontAwesome5Solid.image,
        'Upload a logo image for your kennel.\n\n'
            'The image must be square and between 400×400 and 800×800 pixels, '
            'and should ideally have a transparent background.\n\n'
            'Accepted formats: PNG, AVIF.',
      ),
      editedFieldValue: editedData.value.kennelLogo,
      originalFieldValue: originalData.kennelLogo,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Kennel logo',
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        if (value != null && value.isNotEmpty) {
          editedData.value = editedData.value.copyWith(kennelLogo: value);
        }
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }
}
