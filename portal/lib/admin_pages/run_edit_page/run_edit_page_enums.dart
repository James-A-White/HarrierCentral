/// Run Edit Page Enums
///
/// This file contains all enum definitions used in the run editing form.
/// Enums are organized into categories:
/// - Tab types (RunTabType) - defines the tabs in the form
/// - Field enums - defines fields within each tab

import 'package:hcportal/imports.dart';

// ---------------------------------------------------------------------------
// Tab Type Enum
// ---------------------------------------------------------------------------

/// Defines all tabs available in the run editing form.
///
/// Each tab has associated metadata including:
/// - Unique key for identification
/// - Display title and description
/// - Icon for visual representation
/// - Configuration flags for behavior
enum RunTabType {
  /// Basic run information (name, date, description).
  basicInfo(
    key: 'basicInfo',
    title: 'Basic Info',
    description: 'Enter the basic information for this run including the run '
        'name, start date/time, place description, and detailed description.\n\n'
        'If this run was imported from an external source, you can choose '
        'whether to use the external data or edit it locally.',
    icon: MaterialCommunityIcons.notebook_edit,
    isTabLockable: false,
    hasCustomTabStatusFunction: false,
    showTabInSubmitSummary: true,
  ),

  /// Run location details (address, city, region, coordinates).
  location(
    key: 'location',
    title: 'Location',
    description: 'Specify the location details for this run including the '
        'street address, city, region, and country.\n\n'
        'You can also set the latitude and longitude coordinates using the '
        'map or by entering them directly.',
    icon: FontAwesome5Solid.map_pin,
    isTabLockable: false,
    hasCustomTabStatusFunction: false,
    showTabInSubmitSummary: true,
  ),

  /// Event image management.
  image(
    key: 'image',
    title: 'Image',
    description: 'Upload or select an image for this run.\n\n'
        'If this run was imported from an external source, you can choose '
        'to use the external image or upload your own.',
    icon: FontAwesome5Solid.image,
    isTabLockable: false,
    hasCustomTabStatusFunction: false,
    showTabInSubmitSummary: true,
  ),

  /// Miscellaneous run settings.
  misc(
    key: 'misc',
    title: 'Misc',
    description: 'Configure miscellaneous settings for this run including '
        'visibility, run numbering, hares, and publishing options.\n\n'
        'You can also set participation limits and geographic scope.',
    icon: FontAwesome5Solid.sliders_h,
    isTabLockable: false,
    hasCustomTabStatusFunction: false,
    showTabInSubmitSummary: true,
  ),

  /// Run tags and categories.
  runTags(
    key: 'runTags',
    title: 'Run Tags',
    description: 'Select tags that describe this run\'s characteristics.\n\n'
        'Tags help hashers understand what to expect from the run, such as '
        'terrain type, difficulty level, and special requirements.',
    icon: FontAwesome.tags,
    isTabLockable: false,
    hasCustomTabStatusFunction: false,
    showTabInSubmitSummary: true,
  ),

  /// Other run settings (end time, participation, country).
  other(
    key: 'other',
    title: 'Other',
    description: 'Configure additional settings for this run including '
        'the run end time, participation limits, and country selection.\n\n'
        'You can also manage integration settings if this run was imported '
        'from an external source.',
    icon: FontAwesome5Solid.cog,
    isTabLockable: false,
    hasCustomTabStatusFunction: false,
    showTabInSubmitSummary: true,
  ),

  /// Payment and pricing settings.
  payment(
    key: 'payment',
    title: 'Payment',
    description: 'Set pricing options for this run.\n\n'
        'You can use the kennel\'s default pricing or set custom prices '
        'for members and non-members. You can also configure extra charges '
        'for items like dinner or t-shirts.',
    icon: FontAwesome5Solid.money_bill_wave,
    isTabLockable: false,
    hasCustomTabStatusFunction: false,
    showTabInSubmitSummary: true,
  );

  const RunTabType({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.isTabLockable,
    required this.hasCustomTabStatusFunction,
    required this.showTabInSubmitSummary,
  });

  /// Unique identifier for this tab (used in control keys).
  final String key;

  /// Display title shown in the tab bar.
  final String title;

  /// Description shown in the sidebar.
  final String description;

  /// Icon displayed on the tab.
  final IconData icon;

  /// Whether this tab can be locked (e.g., after submission).
  final bool isTabLockable;

  /// Whether this tab has custom status calculation logic.
  final bool hasCustomTabStatusFunction;

  /// Whether this tab appears in the submit summary.
  final bool showTabInSubmitSummary;
}

// ---------------------------------------------------------------------------
// Field Enums
// ---------------------------------------------------------------------------

/// Fields available on the Basic Info tab.
enum RunBasicInfoField {
  /// The run name.
  runName,

  /// Run start date and time.
  runStartDate,

  /// One-line place description.
  placeDescription,

  /// Detailed run description.
  runDescription,
}

/// Fields available on the Location tab.
enum RunLocationField {
  /// Street address.
  street,

  /// City.
  city,

  /// Postal code.
  postcode,

  /// Region/State.
  region,

  /// Country.
  country,

  /// Phone number at location.
  phone,

  /// Latitude coordinate.
  latitude,

  /// Longitude coordinate.
  longitude,
}

/// Fields available on the Image tab.
enum RunImageField {
  /// Event image URL.
  eventImage,
}

/// Fields available on the Misc tab.
enum RunMiscField {
  /// Whether the run is visible.
  isVisible,

  /// Whether this is a counted run.
  isCounted,

  /// Whether this is a promoted event.
  isPromoted,

  /// Geographic scope of the run.
  geographicScope,

  /// Run attendance policy.
  runAttendance,

  /// Whether to auto-number the run.
  autoNumber,

  /// Absolute run number (if not auto-numbered).
  absoluteRunNumber,

  /// Hares for this run.
  hares,

  /// Web publishing settings.
  publishOnHashruns,

  /// Run audience (who can see).
  runAudience,

  /// Allow web link sharing.
  allowWebLink,

  /// Google calendar publishing.
  publishOnGoogleCalendar,
}

/// Fields available on the Other tab.
enum RunOtherField {
  /// Run end date and time.
  runEndDate,

  /// Whether to limit participation.
  limitParticipation,

  /// Minimum participants required.
  minimumParticipation,

  /// Maximum participants allowed.
  maximumParticipation,

  /// Country for statistics.
  country,

  /// Auto-import from external source.
  autoImport,
}

/// Fields available on the Payment tab.
enum RunPaymentField {
  /// Whether to use custom pricing.
  useCustomPrices,

  /// Member price.
  memberPrice,

  /// Non-member price.
  nonMemberPrice,

  /// Whether to use extras pricing.
  useExtrasPrices,

  /// Extras price.
  extrasPrice,

  /// Extras description.
  extrasDescription,

  /// Whether extras require RSVP.
  extrasRsvpRequired,
}
