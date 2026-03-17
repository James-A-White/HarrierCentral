/// Kennel Location Page Controls
///
/// This file defines the UI control configurations for the Kennel Location tab.
/// It uses an extension on [KennelPageFormController] to keep control
/// initialization organized and separate from the main controller.

part of '../../kennel_page_new_controller.dart';

// ---------------------------------------------------------------------------
// Control Initialization Extension
// ---------------------------------------------------------------------------

/// Extension that adds kennel location control initialization to the controller.
extension KennelLocationControlsExtension on KennelPageFormController {
  /// Initializes all UI controls for the Kennel Location tab.
  ///
  /// This method sets up [UiControlDefinition] instances for each field
  /// on the kennel location tab, including read-only location fields
  /// and editable coordinate fields.
  void initKennelLocationControls() {
    final tabKey = KennelTabType.kennelLocation.key;
    const tabIndex = 1;

    // Read-only location fields
    _registerCityNameControl(tabKey, tabIndex);
    _registerRegionNameControl(tabKey, tabIndex);
    _registerCountryNameControl(tabKey, tabIndex);

    // Editable coordinate fields
    _registerLatitudeControl(tabKey, tabIndex);
    _registerLongitudeControl(tabKey, tabIndex);

    // Preference fields
    _registerDistancePreferenceControl(tabKey, tabIndex);
    _registerKennelPinColorControl(tabKey, tabIndex);
  }

  // ---------------------------------------------------------------------------
  // Read-Only Location Controls
  // ---------------------------------------------------------------------------

  /// Registers the city name control (read-only).
  void _registerCityNameControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${KennelLocationField.cityName.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'City',
        FontAwesome.pencil_square,
        'The name of the city where your Kennel is located. '
            'It should be between 3 and 50 characters long.',
      ),
      editedFieldValue: editedData.value.cityName,
      originalFieldValue: originalData.cityName,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'City',
      readonly: true,
      maxLines: 1,
      includeOverrideButton: false,
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (_) {
        // Read-only field - no updates allowed
      },
    );
  }

  /// Registers the region/state name control (read-only).
  void _registerRegionNameControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${KennelLocationField.regionName.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Region / State',
        Entypo.text,
        'The name of the region, state, or province where your Kennel '
            'is located.',
      ),
      editedFieldValue: editedData.value.regionName,
      originalFieldValue: originalData.regionName,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Region / State / Province',
      readonly: true,
      maxLines: 1,
      includeOverrideButton: false,
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (_) {
        // Read-only field - no updates allowed
      },
    );
  }

  /// Registers the country name control (read-only).
  void _registerCountryNameControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${KennelLocationField.countryName.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Country',
        Entypo.text,
        'The name of the country where your Kennel is located.',
      ),
      editedFieldValue: editedData.value.countryName,
      originalFieldValue: originalData.countryName,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Country',
      readonly: true,
      maxStringLength: 50,
      minStringLength: 3,
      maxLines: 1,
      includeOverrideButton: false,
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (_) {
        // Read-only field - no updates allowed
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Editable Coordinate Controls
  // ---------------------------------------------------------------------------

  /// Registers the latitude control with override capability.
  void _registerLatitudeControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${KennelLocationField.defaultLatitude.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Latitude',
        Entypo.text,
        'Please provide the latitude coordinate of your Kennel location.',
      ),
      editedFieldValue: editedData.value.latitude?.toStringAsFixed(5),
      originalFieldValue: originalData.latitude?.toStringAsFixed(5),
      lookthroughValue: originalData.defaultLatitude?.toStringAsFixed(5),
      lookthroughLabel: '${originalData.cityName} latitude',
      globalKey: GlobalKey<FormFieldState>(),
      label: '${originalData.kennelName} latitude',
      maxStringLength: 9,
      minStringLength: 4,
      maxLines: 1,
      includeOverrideButton: true,
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      regex: r'^-?([1-8]?[0-9](\.\d+)?|90(\.0+)?)$',
      regexErrorString:
          'Please enter a valid latitude value between -90 and 90',
      updateEditedValue: (String? value) =>
          _handleLatitudeUpdate(fieldKey, value),
    );
  }

  /// Handles latitude value updates with reset-to-default support.
  void _handleLatitudeUpdate(String fieldKey, String? value) {
    if (value == RESET_TO_LOOKTHROUGH_VALUE) {
      // Reset to default value
      editedData.value = editedData.value.copyWith(latitude: 999);
      uiControls[fieldKey]?.editedFieldValue =
          originalData.defaultLatitude?.toStringAsFixed(5);
      return;
    }

    final latitude = double.tryParse(value ?? '');
    if (latitude == null) return;

    // Check if value matches the default
    final defaultValue = originalData.defaultLatitude?.toStringAsFixed(5);
    if (latitude.toStringAsFixed(5) == defaultValue) {
      editedData.value = editedData.value.copyWith(latitude: 999);
    } else {
      editedData.value = editedData.value.copyWith(latitude: latitude);
    }

    uiControls[fieldKey]?.editedFieldValue = latitude.toStringAsFixed(5);
  }

  /// Registers the longitude control with override capability.
  void _registerLongitudeControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${KennelLocationField.defaultLongitude.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Longitude',
        Entypo.text,
        'Please provide the longitude coordinate of your Kennel location.',
      ),
      editedFieldValue: editedData.value.longitude?.toStringAsFixed(5),
      originalFieldValue: originalData.longitude?.toStringAsFixed(5),
      lookthroughValue: originalData.defaultLongitude?.toStringAsFixed(5),
      lookthroughLabel: '${originalData.cityName} longitude',
      globalKey: GlobalKey<FormFieldState>(),
      label: '${originalData.kennelName} longitude',
      maxStringLength: 10,
      minStringLength: 4,
      maxLines: 1,
      includeOverrideButton: true,
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      regex: r'^-?((1[0-7][0-9])|([1-9]?[0-9]))(\.\d+)?$',
      regexErrorString:
          'Please enter a valid longitude value between -180 and 180',
      updateEditedValue: (String? value) =>
          _handleLongitudeUpdate(fieldKey, value),
    );
  }

  /// Handles longitude value updates with reset-to-default support.
  void _handleLongitudeUpdate(String fieldKey, String? value) {
    if (value == RESET_TO_LOOKTHROUGH_VALUE) {
      // Reset to default value
      editedData.value = editedData.value.copyWith(longitude: 999);
      uiControls[fieldKey]?.editedFieldValue =
          originalData.defaultLongitude?.toStringAsFixed(5);
      return;
    }

    final longitude = double.tryParse(value ?? '');
    if (longitude == null) return;

    // Check if value matches the default
    final defaultValue = originalData.defaultLongitude?.toStringAsFixed(5);
    if (longitude.toStringAsFixed(5) == defaultValue) {
      editedData.value = editedData.value.copyWith(longitude: 999);
    } else {
      editedData.value = editedData.value.copyWith(longitude: longitude);
    }

    uiControls[fieldKey]?.editedFieldValue = longitude.toStringAsFixed(5);
  }

  // ---------------------------------------------------------------------------
  // Preference Controls
  // ---------------------------------------------------------------------------

  /// Registers the distance preference control (dropdown).
  void _registerDistancePreferenceControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${KennelLocationField.distancePreference.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.intValue,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Distance Preference',
        MaterialCommunityIcons.ruler_square_compass,
        'This setting determines if your Kennel will display distances in '
            'miles or kilometers.\n\n'
            'It is probably best to keep this setting on the "Default for '
            'the Country" as Harrier Central will select the setting that '
            'is appropriate to the location you are in.',
      ),
      editedFieldValue: editedData.value.distancePreference?.toString(),
      originalFieldValue: originalData.distancePreference?.toString(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Distance preference',
      maxLines: 1,
      includeOverrideButton: false,
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        final intValue = int.tryParse(value ?? '-1') ?? -1;
        distancePreference.value = intValue;
        editedData.value = editedData.value.copyWith(
          distancePreference: intValue,
        );
      },
      onUndo: () {
        distancePreference.value = originalData.distancePreference ?? -1;
      },
    );
  }

  /// Registers the kennel pin color control (image dropdown).
  void _registerKennelPinColorControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${KennelLocationField.kennelPinColor.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.dropdown,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Kennel Pin Color',
        MaterialCommunityIcons.brush,
        "Here's where you can select the color of the map pins for your "
            'Kennel.\n\n'
            'This is especially important in cities where there is more than '
            'one Kennel using Harrier Central. Having different colored pins '
            'for different Hash groups makes it easy to identify which runs '
            'are yours.',
      ),
      editedFieldValue: editedData.value.kennelPinColor.toString(),
      originalFieldValue: originalData.kennelPinColor.toString(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Kennel Pin Color',
      maxLines: 1,
      includeOverrideButton: false,
      tabIndex: tabIndex,
      dropdownItems: const {
        0: 'Red',
        1: 'Orange',
        2: 'Yellow',
        3: 'Green',
        4: 'Teal',
        5: 'Baby_blue',
        6: 'Blue',
        7: 'Purple',
        8: 'Pink',
      },
      updateEditedValue: (String? value) {
        final intValue = int.tryParse(value ?? '0') ?? 0;
        kennelPinColor.value = intValue;
        editedData.value = editedData.value.copyWith(
          kennelPinColor: intValue,
        );
      },
      onUndo: () {
        kennelPinColor.value = originalData.kennelPinColor;
      },
    );
  }
}
