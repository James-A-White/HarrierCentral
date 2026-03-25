/// Kennel Page Enums
///
/// This file contains all enum definitions used in the kennel editing form.
/// Enums are organized into categories:
/// - Tab types (KennelTabType) - defines the tabs in the form
/// - Field enums - defines fields within each tab
/// - Form types (AppFormTypes) - defines form sections with word limits

import 'package:hcportal/imports.dart';

// ---------------------------------------------------------------------------
// Tab Type Enum
// ---------------------------------------------------------------------------

/// Defines all tabs available in the kennel editing form.
///
/// Each tab has associated metadata including:
/// - Unique key for identification
/// - Display title and description
/// - Icon for visual representation
/// - Configuration flags for behavior
enum KennelTabType {
  /// Basic kennel information (name, description, contacts).
  kennelInfo(
    key: 'kennelInfo',
    title: 'Description',
    description: 'Please provide a title, description and optional image '
        'for this kennel.\n\nAlthough the image is not required, having a '
        'compelling visual reference will help visitors identify your kennel.',
    icon: MaterialCommunityIcons.notebook_edit,
    isTabLockable: true,
    hasCustomTabStatusFunction: false,
    showTabInSubmitSummary: true,
  ),

  /// Kennel location details (city, region, country, coordinates).
  kennelLocation(
    key: 'kennelLocation',
    title: 'Location',
    description: 'Use this tab to provide location details for your kennel.\n\n'
        'Providing accurate location information helps users find and connect '
        'with your kennel more easily.',
    icon: FontAwesome5Solid.map_pin,
    isTabLockable: true,
    hasCustomTabStatusFunction: false,
    showTabInSubmitSummary: true,
  ),

  /// Experience and category tags.
  tags(
    key: 'tags',
    title: 'Run Tags',
    description: 'Select tags that describe your kennel\'s focus areas and '
        'expertise.\n\nThese tags help users find kennels that match their '
        'interests and needs.',
    icon: FontAwesome.tags,
    isTabLockable: true,
    hasCustomTabStatusFunction: false,
    showTabInSubmitSummary: true,
  ),

  /// Other settings (sharing, integrations, preferences).
  other(
    key: 'other',
    title: 'Other',
    description: 'Additional items you can set for your Kennel.\n\n'
        'Configure default run times, sharing options, calendar integrations, '
        'and other miscellaneous settings.',
    icon: FontAwesome5Solid.cog,
    isTabLockable: true,
    hasCustomTabStatusFunction: false,
    showTabInSubmitSummary: true,
  ),

  /// Developer tools and API access.
  developer(
    key: 'developer',
    title: 'Developer',
    description:
        'Access developer tools, API keys, and integration options.\n\n'
        'Use these resources to integrate your kennel data with external '
        'websites and applications.',
    icon: FontAwesome5Solid.code,
    isTabLockable: true,
    hasCustomTabStatusFunction: true,
    showTabInSubmitSummary: false,
  ),

  /// Hash cash and payment settings.
  hashCash(
    key: 'hashCash',
    title: 'Hash Cash',
    description: 'Set default run prices and payment platform options.\n\n'
        'Configure pricing for members and non-members, and manage '
        'payment-related settings.',
    icon: FontAwesome5Solid.money_bill_wave,
    isTabLockable: true,
    hasCustomTabStatusFunction: false,
    showTabInSubmitSummary: true,
  ),

  /// Songs management — select and add songs for this kennel.
  songs(
    key: 'songs',
    title: 'Songs',
    description: 'Manage your kennel\'s song library.\n\n'
        'Select songs from the global catalogue to add to your kennel, '
        'view lyrics and details, or contribute new songs.',
    icon: FontAwesome5Solid.music,
    isTabLockable: false,
    hasCustomTabStatusFunction: true,
    showTabInSubmitSummary: false,
  ),

  /// Kennel logo upload.
  kennelLogo(
    key: 'kennelLogo',
    title: 'Logo',
    description: 'Upload a logo image for your kennel.\n\n'
        'This image is displayed on the Harrier Central map and in run listings. '
        'A square image with a transparent background works best.',
    icon: FontAwesome5Solid.image,
    isTabLockable: true,
    hasCustomTabStatusFunction: false,
    showTabInSubmitSummary: true,
  );

  const KennelTabType({
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

/// Fields available on the Kennel Info tab.
///
/// These enum values match the field names in [KennelModel] and are used
/// to generate consistent control keys.
enum KennelInfoField {
  /// The full kennel name.
  kennelName,

  /// Short abbreviation (e.g., "LH3").
  kennelShortName,

  /// Globally unique abbreviation for URLs.
  kennelUniqueShortName,

  /// Detailed description of the kennel.
  kennelDescription,

  /// Comma-separated list of admin email addresses.
  kennelAdminEmailList,

  /// External website URL.
  kennelWebsiteUrl,
}

/// Fields available on the Kennel Location tab.
///
/// These enum values match the field names in [KennelModel] and are used
/// to generate consistent control keys.
enum KennelLocationField {
  /// City name (read-only).
  cityName,

  /// Region/state name (read-only).
  regionName,

  /// Country name (read-only).
  countryName,

  /// Default latitude coordinate (editable with override).
  defaultLatitude,

  /// Default longitude coordinate (editable with override).
  defaultLongitude,

  /// Distance unit preference (-1 = country default, 0 = km, 1 = miles).
  distancePreference,

  /// Kennel map pin color (0-8).
  kennelPinColor,
}

// ---------------------------------------------------------------------------
// Form Types Enum
// ---------------------------------------------------------------------------

/// Defines form sections with word count limits.
///
/// Each form type has minimum and maximum word count requirements
/// that are validated during editing.
enum AppFormTypes {
  /// Overview section - captures the main proposal summary.
  formOverivew(
    key: 'formOverview',
    title: 'Overview',
    description: 'This is an overview of your product and proposal. This is '
        'one of the most important areas to focus on as this is where you '
        'can capture the imagination of our evaluation team.\n\nPlease use '
        'this as an opportunity to demonstrate why your company and product '
        'should receive a DIANA contract.',
    icon: FontAwesome5Solid.binoculars,
    minFormWordCount: 1000,
    maxFormWordCount: 1500,
  ),

  /// Technical description of the innovation.
  formTechnical(
    key: 'formTechnical',
    title: 'Technical Description',
    description: 'This section is where you describe the technical innovation '
        'that you are proposing.\n\nPlease make sure to outline how it can '
        'be used for both defence and security and commercial purposes.\n\n'
        'IMPORTANT: Please do not provide any proprietary information here.',
    icon: MaterialCommunityIcons.tools,
    minFormWordCount: 1500,
    maxFormWordCount: 2500,
  ),

  /// Commercial viability and market potential.
  formCommercial(
    key: 'formCommercial',
    title: 'Commercial Viability',
    description: 'This section is where you describe the commercial market '
        'potential of your innovation.\n\nFor example, you can highlight '
        'pathways to commercialization, estimated market sizes, and '
        'partnerships you may have.',
    icon: FontAwesome.shopping_cart,
    minFormWordCount: 1000,
    maxFormWordCount: 2500,
  ),

  /// Project plan and fund allocation.
  formProject(
    key: 'formProject',
    title: 'Project Plan',
    description: 'If you are selected for acceleration, you will be awarded '
        'a contract.\n\nHere\'s where you can tell us how you will use these '
        'funds to further enhance your product and make it more useful.',
    icon: MaterialCommunityIcons.chart_gantt,
    minFormWordCount: 2000,
    maxFormWordCount: 3000,
  );

  const AppFormTypes({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.minFormWordCount,
    required this.maxFormWordCount,
  });

  /// Unique identifier for this form type.
  final String key;

  /// Display title for the form section.
  final String title;

  /// Description/instructions for this form section.
  final String description;

  /// Icon displayed for this form type.
  final IconData icon;

  /// Minimum required word count.
  final int minFormWordCount;

  /// Maximum allowed word count.
  final int maxFormWordCount;
}

// ---------------------------------------------------------------------------
// Legacy Compatibility
// ---------------------------------------------------------------------------

/// Legacy alias for [KennelTabType].
///
/// @deprecated Use [KennelTabType] instead.
typedef AppTabKeyEnums = KennelTabType;

// ---------------------------------------------------------------------------
// Run Tag Groups Enum
// ---------------------------------------------------------------------------

/// Groups for organizing run tags.
///
/// Each group contains related tags that are displayed together in the UI.
/// The bit flag encoding uses three separate integers (tags1, tags2, tags3)
/// with the following prefixes:
/// - 0x100000000: Tags in runTags1
/// - 0x200000000: Tags in runTags2
/// - 0x400000000: Tags in runTags3 (reserved for future use)
enum RunTagGroup {
  /// Run theme tags (normal run, red dress, etc.).
  theme(
    groupKey: 'groupTheme',
    label: 'Theme',
  ),

  /// Restrictions and access tags.
  restrictions(
    groupKey: 'groupRestrictions',
    label: 'Restrictions',
  ),

  /// Items hashers should bring.
  whatToBring(
    groupKey: 'groupWhatToBring',
    label: 'What to Bring',
  ),

  /// Run type and distance options.
  runType(
    groupKey: 'groupRunType',
    label: 'Run Type & Distances',
  ),

  /// Terrain and environment tags.
  terrain(
    groupKey: 'groupTerrain',
    label: 'Terrain',
  ),

  /// Hare-related tags.
  hares(
    groupKey: 'groupHares',
    label: 'Hares',
  ),

  /// Other miscellaneous tags.
  other(
    groupKey: 'groupOther',
    label: 'Other',
  );

  const RunTagGroup({
    required this.groupKey,
    required this.label,
  });

  /// Unique identifier for this group.
  final String groupKey;

  /// Display label for the group.
  final String label;
}

// ---------------------------------------------------------------------------
// Run Tags Enum
// ---------------------------------------------------------------------------

/// Individual run tags with their bit flag values.
///
/// Each tag has:
/// - A unique key for identification
/// - A display title
/// - A description for the sidebar help
/// - A parent group key
/// - An icon
/// - A bit flag value that encodes which tags integer and bit position
///
/// Bit flag encoding:
/// - Upper nibble: 1 = tags1, 2 = tags2, 4 = tags3
/// - Lower 31 bits: The actual bit flag value
enum RunTag {
  // ---------------------------------------------------------------------------
  // Theme Group
  // ---------------------------------------------------------------------------
  normalRun(
    key: 'normalRun',
    title: 'Normal Run',
    description: 'A standard hash run with typical format and activities.',
    parentKey: 'groupTheme',
    icon: FontAwesome5Solid.running,
    bitFlag: 0x100000001,
  ),
  redDress(
    key: 'redDress',
    title: 'Red Dress Run',
    description: 'A special charity run where participants wear red dresses.',
    parentKey: 'groupTheme',
    icon: MaterialCommunityIcons.tshirt_crew,
    bitFlag: 0x100000002,
  ),
  familyHash(
    key: 'familyHash',
    title: 'Family Hash',
    description: 'A family-friendly hash suitable for all ages.',
    parentKey: 'groupTheme',
    icon: FontAwesome5Solid.users,
    bitFlag: 0x200000004,
  ),
  fullMoon(
    key: 'fullMoon',
    title: 'Full Moon Run',
    description: 'A run held during the full moon, often at night.',
    parentKey: 'groupTheme',
    icon: Ionicons.moon,
    bitFlag: 0x100000004,
  ),
  harriette(
    key: 'harriette',
    title: 'Harriette Run',
    description: 'A run organized by or for the Harriettes.',
    parentKey: 'groupTheme',
    icon: FontAwesome5Solid.female,
    bitFlag: 0x100000008,
  ),
  agm(
    key: 'agm',
    title: 'AGM',
    description: 'Annual General Meeting of the hash.',
    parentKey: 'groupTheme',
    icon: FontAwesome5Solid.calendar_check,
    bitFlag: 0x140000000,
  ),
  drinkingPractice(
    key: 'drinkingPractice',
    title: 'Drinking Practice',
    description: 'A social event focused more on drinking than running.',
    parentKey: 'groupTheme',
    icon: FontAwesome5Solid.beer,
    bitFlag: 0x200000200,
  ),
  hangoverRun(
    key: 'hangoverRun',
    title: 'Hangover Run',
    description: 'A relaxed run, typically the morning after a big event.',
    parentKey: 'groupTheme',
    icon: MaterialCommunityIcons.glass_mug_variant,
    bitFlag: 0x200020000,
  ),

  // ---------------------------------------------------------------------------
  // Restrictions Group
  // ---------------------------------------------------------------------------
  menOnly(
    key: 'menOnly',
    title: 'Men Only',
    description: 'This run is restricted to male participants.',
    parentKey: 'groupRestrictions',
    icon: FontAwesome5Solid.male,
    bitFlag: 0x100000010,
  ),
  womenOnly(
    key: 'womenOnly',
    title: 'Women Only',
    description: 'This run is restricted to female participants.',
    parentKey: 'groupRestrictions',
    icon: FontAwesome5Solid.female,
    bitFlag: 0x100000020,
  ),
  kidsAllowed(
    key: 'kidsAllowed',
    title: 'Kids Allowed',
    description: 'Children are welcome on this run.',
    parentKey: 'groupRestrictions',
    icon: FontAwesome5Solid.child,
    bitFlag: 0x100000040,
  ),
  noKidsAllowed(
    key: 'noKidsAllowed',
    title: 'No Kids Allowed',
    description: 'This run is not suitable for children.',
    parentKey: 'groupRestrictions',
    icon: MaterialCommunityIcons.account_child_outline,
    bitFlag: 0x100000080,
  ),
  dogFriendly(
    key: 'dogFriendly',
    title: 'Dog Friendly',
    description: 'Dogs are welcome on this run.',
    parentKey: 'groupRestrictions',
    icon: MaterialCommunityIcons.dog,
    bitFlag: 0x102000000,
  ),
  noDogsAllowed(
    key: 'noDogsAllowed',
    title: 'No Dogs Allowed',
    description: 'Dogs are not permitted on this run.',
    parentKey: 'groupRestrictions',
    icon: MaterialCommunityIcons.dog_side_off,
    bitFlag: 0x200000002,
  ),

  // ---------------------------------------------------------------------------
  // What to Bring Group
  // ---------------------------------------------------------------------------
  bringCashOnTrail(
    key: 'bringCashOnTrail',
    title: 'Bring Cash on Trail',
    description: 'Cash may be needed for purchases during the run.',
    parentKey: 'groupWhatToBring',
    icon: FontAwesome5Solid.money_bill,
    bitFlag: 0x110000000,
  ),
  bringFlashlight(
    key: 'bringFlashlight',
    title: 'Bring Flashlight',
    description: 'A flashlight or headlamp is recommended.',
    parentKey: 'groupWhatToBring',
    icon: MaterialCommunityIcons.flashlight,
    bitFlag: 0x100000100,
  ),
  bringDryClothes(
    key: 'bringDryClothes',
    title: 'Bring Dry Clothes',
    description: 'You may get wet, so bring a change of clothes.',
    parentKey: 'groupWhatToBring',
    icon: MaterialCommunityIcons.tshirt_crew_outline,
    bitFlag: 0x200000008,
  ),
  bagDropAvailable(
    key: 'bagDropAvailable',
    title: 'Bag Drop Available',
    description: 'A bag drop service will be available.',
    parentKey: 'groupWhatToBring',
    icon: FontAwesome5Solid.suitcase,
    bitFlag: 0x120000000,
  ),
  noBagDropAvailable(
    key: 'noBagDropAvailable',
    title: 'No Bag Drop Available',
    description: 'There will be no bag drop service.',
    parentKey: 'groupWhatToBring',
    icon: FontAwesome5Solid.suitcase_rolling,
    bitFlag: 0x200000100,
  ),
  bringDrinkingVessel(
    key: 'bringDrinkingVessel',
    title: 'Bring Drinking Vessel',
    description: 'Bring your own cup or mug for drinks.',
    parentKey: 'groupWhatToBring',
    icon: MaterialCommunityIcons.cup,
    bitFlag: 0x200001000,
  ),
  bringChair(
    key: 'bringChair',
    title: 'Bring a Chair',
    description: 'Consider bringing a camp chair for the circle.',
    parentKey: 'groupWhatToBring',
    icon: MaterialCommunityIcons.seat,
    bitFlag: 0x200002000,
  ),
  drinkStop(
    key: 'drinkStop',
    title: 'Drink Stop',
    description: 'There will be a drink stop during the run.',
    parentKey: 'groupOther',
    icon: FontAwesome5Solid.glass_cheers,
    bitFlag: 0x200008000,
  ),

  // ---------------------------------------------------------------------------
  // Run Type Group
  // ---------------------------------------------------------------------------
  pubCrawl(
    key: 'pubCrawl',
    title: 'Pub Crawl',
    description: 'A run that visits multiple pubs along the trail.',
    parentKey: 'groupRunType',
    icon: FontAwesome5Solid.beer,
    bitFlag: 0x100002000,
  ),
  aToBRun(
    key: 'aToBRun',
    title: 'A-to-B Run',
    description: 'The run starts and ends at different locations.',
    parentKey: 'groupRunType',
    icon: FontAwesome5Solid.route,
    bitFlag: 0x200004000,
  ),
  oldFartsTrail(
    key: 'oldFartsTrail',
    title: 'Short Walk / Old Farts Trail',
    description: 'A shorter, easier trail option.',
    parentKey: 'groupRunType',
    icon: MaterialCommunityIcons.walk,
    bitFlag: 0x200000800,
  ),
  walkerTrail(
    key: 'walkerTrail',
    title: 'Walker Trail',
    description: 'A trail designed for walkers.',
    parentKey: 'groupRunType',
    icon: MaterialCommunityIcons.walk,
    bitFlag: 0x100000400,
  ),
  shortTrail(
    key: 'shortTrail',
    title: 'Short Trail',
    description: 'A shorter than usual trail.',
    parentKey: 'groupRunType',
    icon: MaterialCommunityIcons.run_fast,
    bitFlag: 0x200000010,
  ),
  mediumTrail(
    key: 'mediumTrail',
    title: 'Medium Trail',
    description: 'A medium-length trail.',
    parentKey: 'groupRunType',
    icon: FontAwesome5Solid.running,
    bitFlag: 0x100000800,
  ),
  longTrail(
    key: 'longTrail',
    title: 'Long Run Trail',
    description: 'A longer than usual trail.',
    parentKey: 'groupRunType',
    icon: MaterialCommunityIcons.run,
    bitFlag: 0x100001000,
  ),
  ballbreakerTrail(
    key: 'ballbreakerTrail',
    title: 'Ballbreaker Trail',
    description: 'An extremely challenging trail.',
    parentKey: 'groupRunType',
    icon: MaterialCommunityIcons.weight_lifter,
    bitFlag: 0x200000400,
  ),
  bikeHash(
    key: 'bikeHash',
    title: 'BASH / Bike Hash',
    description: 'A hash on bicycles.',
    parentKey: 'groupRunType',
    icon: FontAwesome5Solid.biking,
    bitFlag: 0x100040000,
  ),

  // ---------------------------------------------------------------------------
  // Terrain Group
  // ---------------------------------------------------------------------------
  shiggyRun(
    key: 'shiggyRun',
    title: 'Shiggy Run',
    description: 'Expect mud, water, and rough terrain.',
    parentKey: 'groupTerrain',
    icon: MaterialCommunityIcons.shoe_print,
    bitFlag: 0x100010000,
  ),
  cityHash(
    key: 'cityHash',
    title: 'City Run',
    description: 'The trail is set in an urban environment.',
    parentKey: 'groupTerrain',
    icon: FontAwesome5Solid.city,
    bitFlag: 0x100080000,
  ),
  steepHills(
    key: 'steepHills',
    title: 'Steep Hills',
    description: 'The trail includes significant elevation changes.',
    parentKey: 'groupTerrain',
    icon: MaterialCommunityIcons.terrain,
    bitFlag: 0x100800000,
  ),
  nightRun(
    key: 'nightRun',
    title: 'Nighttime Run',
    description: 'The run takes place at night.',
    parentKey: 'groupTerrain',
    icon: Ionicons.moon,
    bitFlag: 0x100400000,
  ),
  babyJoggerFriendly(
    key: 'babyJoggerFriendly',
    title: 'Baby Jogger Friendly',
    description: 'The trail is suitable for baby joggers/strollers.',
    parentKey: 'groupTerrain',
    icon: MaterialCommunityIcons.baby_carriage,
    bitFlag: 0x100008000,
  ),
  waterOnTrail(
    key: 'waterOnTrail',
    title: 'Water on Trail',
    description: 'Expect to encounter water crossings.',
    parentKey: 'groupTerrain',
    icon: MaterialCommunityIcons.waves,
    bitFlag: 0x100000200,
  ),
  swimStop(
    key: 'swimStop',
    title: 'Swim Stop',
    description: 'There may be an opportunity to swim.',
    parentKey: 'groupTerrain',
    icon: FontAwesome5Solid.swimmer,
    bitFlag: 0x200010000,
  ),

  // ---------------------------------------------------------------------------
  // Hares Group
  // ---------------------------------------------------------------------------
  liveHare(
    key: 'liveHare',
    title: 'Live Hare',
    description: 'The hare sets the trail while runners follow.',
    parentKey: 'groupHares',
    icon: MaterialCommunityIcons.rabbit,
    bitFlag: 0x100100000,
  ),
  deadHare(
    key: 'deadHare',
    title: 'Dead Hare',
    description: 'The trail is pre-set before the run.',
    parentKey: 'groupHares',
    icon: MaterialCommunityIcons.rabbit,
    bitFlag: 0x100200000,
  ),
  pickUpHash(
    key: 'pickUpHash',
    title: 'Pick-up Hash',
    description: 'Trail is marked as runners go, with no pre-set hare.',
    parentKey: 'groupHares',
    icon: MaterialCommunityIcons.map_marker_question,
    bitFlag: 0x104000000,
  ),
  catchTheHare(
    key: 'catchTheHare',
    title: 'Catch the Hare',
    description: 'Runners try to catch the live hare before they finish.',
    parentKey: 'groupHares',
    icon: MaterialCommunityIcons.target,
    bitFlag: 0x108000000,
  ),

  // ---------------------------------------------------------------------------
  // Other Group
  // ---------------------------------------------------------------------------
  onAfter(
    key: 'onAfter',
    title: 'On After / After Party',
    description: 'There will be a social gathering after the run.',
    parentKey: 'groupOther',
    icon: FontAwesome5Solid.glass_cheers,
    bitFlag: 0x100004000,
  ),
  accessibleByPublicTransport(
    key: 'accessibleByPublicTransport',
    title: 'Accessible by Public Transport',
    description: 'The run start is accessible via public transportation.',
    parentKey: 'groupOther',
    icon: FontAwesome5Solid.bus,
    bitFlag: 0x100020000,
  ),
  charityEvent(
    key: 'charityEvent',
    title: 'Charity Event',
    description: 'This run supports a charitable cause.',
    parentKey: 'groupOther',
    icon: FontAwesome5Solid.hand_holding_heart,
    bitFlag: 0x101000000,
  ),
  parkingAvailable(
    key: 'parkingAvailable',
    title: 'Parking Available',
    description: 'Parking is available at the run start.',
    parentKey: 'groupOther',
    icon: FontAwesome5Solid.parking,
    bitFlag: 0x200000020,
  ),
  noParkingAvailable(
    key: 'noParkingAvailable',
    title: 'No Parking Available',
    description: 'There is no parking at the run start.',
    parentKey: 'groupOther',
    icon: MaterialCommunityIcons.car_off,
    bitFlag: 0x200000040,
  ),
  campingHash(
    key: 'campingHash',
    title: 'Camping Hash',
    description: 'This event includes camping.',
    parentKey: 'groupOther',
    icon: MaterialCommunityIcons.campfire,
    bitFlag: 0x200000080,
  ),
  multiDayEvent(
    key: 'multiDayEvent',
    title: 'Multi-day Event',
    description: 'This event spans multiple days.',
    parentKey: 'groupOther',
    icon: FontAwesome5Solid.calendar_week,
    bitFlag: 0x200000001,
  );

  const RunTag({
    required this.key,
    required this.title,
    required this.description,
    required this.parentKey,
    required this.icon,
    required this.bitFlag,
  });

  /// Unique identifier for this tag.
  final String key;

  /// Display title for the tag.
  final String title;

  /// Description shown in sidebar help.
  final String description;

  /// Key of the parent [RunTagGroup].
  final String parentKey;

  /// Icon for this tag.
  final IconData icon;

  /// Bit flag value encoding the tags integer and bit position.
  ///
  /// Upper nibble indicates which tags integer:
  /// - 1 = defaultRunTags1
  /// - 2 = defaultRunTags2
  /// - 4 = defaultRunTags3 (reserved)
  final int bitFlag;

  /// Returns which tags integer this tag belongs to (1, 2, or 3).
  int get tagsInteger => bitFlag ~/ 0x100000000;

  /// Returns the bit mask for this tag (lower 31 bits).
  int get bitMask => bitFlag & 0x7FFFFFFF;
}
