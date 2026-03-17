/// Location Page Controls
///
/// This file defines the UI control configurations for the Location tab.

part of '../../run_edit_page_controller.dart';

// ---------------------------------------------------------------------------
// Location Button Keys (not enum-based, for button controls)
// ---------------------------------------------------------------------------

/// Keys for location action buttons.
class LocationButtonKey {
  static const String setAddressFromLatLon =
      'location_setAddressFromLatLonButton';
  static const String setLatLonFromMap = 'location_setLatLonFromMapButton';
  static const String centerMapOnLatLon = 'location_centerMapOnLatLonButton';
  static const String copyAddressFromExternal =
      'location_copyAddressFromExternalButton';
  static const String copyLatLonFromExternal =
      'location_copyLatLonFromExternalButton';
}

// ---------------------------------------------------------------------------
// Control Initialization Extension
// ---------------------------------------------------------------------------

/// Extension that adds location control initialization to the controller.
extension LocationControlsExtension on RunEditPageController {
  /// Initializes all UI controls for the Location tab.
  void initLocationControls() {
    final tabKey = RunTabType.location.key;
    const tabIndex = 1;

    // Address fields
    _registerStreetControl(tabKey, tabIndex);
    _registerCityControl(tabKey, tabIndex);
    _registerPostcodeControl(tabKey, tabIndex);
    _registerRegionControl(tabKey, tabIndex);
    _registerCountryControl(tabKey, tabIndex);
    _registerPhoneControl(tabKey, tabIndex);

    // Coordinate fields (required)
    _registerLatitudeControl(tabKey, tabIndex);
    _registerLongitudeControl(tabKey, tabIndex);

    // Action buttons
    _registerSetAddressFromLatLonButton(tabKey, tabIndex);
    _registerSetLatLonFromMapButton(tabKey, tabIndex);
    _registerCenterMapOnLatLonButton(tabKey, tabIndex);
    _registerCopyAddressFromExternalButton(tabKey, tabIndex);
    _registerCopyLatLonFromExternalButton(tabKey, tabIndex);
  }

  // ---------------------------------------------------------------------------
  // Address Field Registration
  // ---------------------------------------------------------------------------

  void _registerStreetControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunLocationField.street.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Street Address',
        FontAwesome5Solid.road,
        'Enter the street address for the run location.\n\n'
            'Include the street number and name. This field is optional for '
            'remote locations where only coordinates are available.',
      ),
      editedFieldValue: editedData.value.locationStreet,
      originalFieldValue: originalData.locationStreet,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Street address',
      maxStringLength: 200,
      minStringLength: 0,
      maxLines: 1,
      includeOverrideButton: false,
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value.copyWith(locationStreet: value);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  void _registerCityControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunLocationField.city.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'City',
        FontAwesome5Solid.city,
        'Enter the city where the run takes place.',
      ),
      editedFieldValue: editedData.value.locationCity,
      originalFieldValue: originalData.locationCity,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'City',
      maxStringLength: 100,
      minStringLength: 0,
      maxLines: 1,
      includeOverrideButton: false,
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value.copyWith(locationCity: value);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  void _registerPostcodeControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunLocationField.postcode.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Postal Code',
        MaterialCommunityIcons.mailbox,
        'Enter the postal/zip code for the run location.',
      ),
      editedFieldValue: editedData.value.locationPostCode,
      originalFieldValue: originalData.locationPostCode,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Postcode',
      maxStringLength: 20,
      minStringLength: 0,
      maxLines: 1,
      includeOverrideButton: false,
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value.copyWith(locationPostCode: value);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  void _registerRegionControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunLocationField.region.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Region / State',
        FontAwesome5Solid.map,
        'Enter the region, state, or province where the run takes place.',
      ),
      editedFieldValue: editedData.value.locationRegion,
      originalFieldValue: originalData.locationRegion,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Region',
      maxStringLength: 100,
      minStringLength: 0,
      maxLines: 1,
      includeOverrideButton: false,
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value.copyWith(locationRegion: value);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  void _registerCountryControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunLocationField.country.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Country',
        FontAwesome5Solid.globe,
        'Enter the country where the run takes place.',
      ),
      editedFieldValue: editedData.value.locationCountry,
      originalFieldValue: originalData.locationCountry,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Country',
      maxStringLength: 100,
      minStringLength: 0,
      maxLines: 1,
      includeOverrideButton: false,
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value.copyWith(locationCountry: value);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  void _registerPhoneControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunLocationField.phone.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Phone Number',
        FontAwesome5Solid.phone,
        'Enter a contact phone number for the location (optional).',
      ),
      editedFieldValue: editedData.value.locationPhoneNumber,
      originalFieldValue: originalData.locationPhoneNumber,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Phone',
      maxStringLength: 30,
      minStringLength: 0,
      maxLines: 1,
      includeOverrideButton: false,
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value =
            editedData.value.copyWith(locationPhoneNumber: value);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Coordinate Field Registration (Required)
  // ---------------------------------------------------------------------------

  void _registerLatitudeControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunLocationField.latitude.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Latitude',
        MaterialCommunityIcons.latitude,
        'Enter the latitude coordinate for the run location.\n\n'
            'Leave empty for runs with no fixed location.\n\n'
            'Value must be between -90 and 90 degrees. Use decimal format '
            '(e.g., 51.5074 for London).',
      ),
      editedFieldValue: formatCoordinate(editedData.value.hcLatitude),
      originalFieldValue: formatCoordinate(originalData.hcLatitude),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Latitude',
      maxStringLength: 20,
      minStringLength: 4,
      allowEmpty: true,
      maxLines: 1,
      includeOverrideButton: false,
      regex: r'^-?([0-8]?\d(\.\d+)?|90(\.0+)?)$',
      regexErrorString: 'Latitude must be between -90 and 90',
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        final lat = double.tryParse(value ?? '');
        editedData.value = editedData.value.copyWith(hcLatitude: lat);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  void _registerLongitudeControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunLocationField.longitude.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Longitude',
        MaterialCommunityIcons.longitude,
        'Enter the longitude coordinate for the run location.\n\n'
            'Leave empty for runs with no fixed location.\n\n'
            'Value must be between -180 and 180 degrees. Use decimal format '
            '(e.g., -0.1278 for London).',
      ),
      editedFieldValue: formatCoordinate(editedData.value.hcLongitude),
      originalFieldValue: formatCoordinate(originalData.hcLongitude),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Longitude',
      maxStringLength: 20,
      minStringLength: 4,
      allowEmpty: true,
      maxLines: 1,
      includeOverrideButton: false,
      regex: r'^-?((1[0-7]\d|0?\d{1,2})(\.\d+)?|180(\.0+)?)$',
      regexErrorString: 'Longitude must be between -180 and 180',
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        final lon = double.tryParse(value ?? '');
        editedData.value = editedData.value.copyWith(hcLongitude: lon);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Button Registration
  // ---------------------------------------------------------------------------

  void _registerSetAddressFromLatLonButton(String tabKey, int tabIndex) {
    uiControls[LocationButtonKey.setAddressFromLatLon] = UiControlDefinition(
      controlType: UiControlType.button,
      sidebarEntryKey: LocationButtonKey.setAddressFromLatLon,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Set Address from Coordinates',
        MaterialCommunityIcons.arrow_up_bold,
        'Use reverse geocoding to automatically populate address fields '
            'based on the current latitude and longitude values.',
      ),
      editedFieldValue: null,
      originalFieldValue: null,
      globalKey: GlobalKey(),
      label: 'Set address from lat/lon',
      tabIndex: tabIndex,
      updateEditedValue: (_) {},
      onPressed: reverseGeocode,
      buttonIcon: MaterialCommunityIcons.arrow_up_bold,
    );
  }

  void _registerSetLatLonFromMapButton(String tabKey, int tabIndex) {
    uiControls[LocationButtonKey.setLatLonFromMap] = UiControlDefinition(
      controlType: UiControlType.button,
      sidebarEntryKey: LocationButtonKey.setLatLonFromMap,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Set Coordinates from Map',
        MaterialCommunityIcons.crosshairs_gps,
        'Set the latitude and longitude to the current map crosshair position.',
      ),
      editedFieldValue: null,
      originalFieldValue: null,
      globalKey: GlobalKey(),
      label: 'Set lat/lon from map',
      tabIndex: tabIndex,
      updateEditedValue: (_) {},
      onPressed: setLatLonFromMap,
      buttonIcon: MaterialCommunityIcons.crosshairs_gps,
    );
  }

  void _registerCenterMapOnLatLonButton(String tabKey, int tabIndex) {
    uiControls[LocationButtonKey.centerMapOnLatLon] = UiControlDefinition(
      controlType: UiControlType.button,
      sidebarEntryKey: LocationButtonKey.centerMapOnLatLon,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Center Map on Coordinates',
        MaterialCommunityIcons.crosshairs,
        'Center the map on the current latitude and longitude values.',
      ),
      editedFieldValue: null,
      originalFieldValue: null,
      globalKey: GlobalKey(),
      label: 'Center map on lat/lon',
      tabIndex: tabIndex,
      updateEditedValue: (_) {},
      onPressed: centerMapOnLatLon,
      buttonIcon: MaterialCommunityIcons.crosshairs,
    );
  }

  void _registerCopyAddressFromExternalButton(String tabKey, int tabIndex) {
    uiControls[LocationButtonKey.copyAddressFromExternal] = UiControlDefinition(
      controlType: UiControlType.button,
      sidebarEntryKey: LocationButtonKey.copyAddressFromExternal,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Copy Address from Integration',
        FontAwesome5Solid.copy,
        'Copy the address from the external integration source to the '
            'Harrier Central fields.',
      ),
      editedFieldValue: null,
      originalFieldValue: null,
      globalKey: GlobalKey(),
      label: 'Copy address from source',
      tabIndex: tabIndex,
      updateEditedValue: (_) {},
      onPressed: copyAddressFromExternal,
      buttonIcon: FontAwesome5Solid.copy,
    );
  }

  void _registerCopyLatLonFromExternalButton(String tabKey, int tabIndex) {
    uiControls[LocationButtonKey.copyLatLonFromExternal] = UiControlDefinition(
      controlType: UiControlType.button,
      sidebarEntryKey: LocationButtonKey.copyLatLonFromExternal,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Copy Coordinates from Integration',
        FontAwesome5Solid.copy,
        'Copy the latitude and longitude from the external integration '
            'source to the Harrier Central fields.',
      ),
      editedFieldValue: null,
      originalFieldValue: null,
      globalKey: GlobalKey(),
      label: 'Copy lat/lon from source',
      tabIndex: tabIndex,
      updateEditedValue: (_) {},
      onPressed: copyLatLonFromExternal,
      buttonIcon: FontAwesome5Solid.copy,
    );
  }
}
