// import 'package:hcportal/imports.dart';

// class SideBarData {
//   const SideBarData(this.title, this.icon, this.description);
//   final String title;
//   final IconData icon;
//   final String description;
// }

// const Map<String, SideBarData> sidebarData = {
//   'kennelName': SideBarData(
//     'Kennel Name',
//     FontAwesome.pencil_square,
//     'The long form of your Kennel\'s name, such as "London Hash House Harriers", should be between 3 and 50 characters and unique throughout the world (if possible).',
//   ),
//   'kennelShortName': SideBarData(
//     'Kennel Abbreviation',
//     Icons.abc,
//     "Your Kennel's abbreviation should be between 3 and 6 characters long (although we support up to 9 characters). It should be unique in your local area, even if there are other Kennels with similar abbreviations in other parts of the world. ",
//   ),
//   'kennelUniqueShortName': SideBarData(
//     'Kennel Unique Abbreviation',
//     Icons.abc,
//     "This is a unique version of your Kennel's short name. It must be unique within the Harrier Central data ecosystem because it is used to form URLs to Web pages specific to your Kennel.",
//   ),
//   'kennelDescription': SideBarData(
//     'Kennel Description',
//     FontAwesome.file_text,
//     'Please provide a short Kennel description. This should include what day and time your group normally runs, how much it costs, and any other relevant information.\r\n\r\nMake it fun so visitors will want to join you!',
//   ),
//   'kennelStatus': SideBarData(
//     'Status',
//     Entypo.switch_icon,
//     'Use this field to set the status of your Kennel.\r\n\r\nIf you set it to "Inactive" it will not appear in the Harrier Central App or on www.hashruns.org, however Kennel admins will still see it on the app.',
//   ),
//   'kennelLatitude': SideBarData(
//     'Latitude',
//     SimpleLineIcons.globe,
//     "If you unselect the checkbox, Harrier Central will use the latitude of the city specified for your Kennel. You can customize your Kennel's location by checking the box and providing a value between -90 and 90. Negative numbers are latitudes in the southern hemisphere.",
//   ),
//   'kennelLongitude': SideBarData(
//     'Longitude',
//     SimpleLineIcons.globe,
//     "If you unselect the checkbox, Harrier Central will use the longitude of the city specified for your Kennel. You can customize your Kennel's location by checking the box and providing a value between -180 and 180. Negative numbers are longitude values west of the prime meridian (e.g., the United States)",
//   ),
//   'kennelAdminEmailList': SideBarData(
//     'Admin Emails',
//     MaterialIcons.contact_mail,
//     'Please provide a comma separated list of emails of administrators of your Kennel.\r\n\r\nWe will use this only to contact you to let you know about changes to the system or if we are experiencing any issues with Harrier Central.',
//   ),
//   'kennelWebsiteUrl': SideBarData(
//     'Website URL',
//     MaterialCommunityIcons.web_box,
//     'If your Kennel has a website, please provide the URL to it here.\r\n\r\nThis will make it easy for Hashers to find your Kennel whether or not you use Harrier Central to post your runs.',
//   ),
//   'cityName': SideBarData(
//     'City',
//     Icons.location_city,
//     'The city that your Kenneel is located in.\r\n\r\nCurrently this is a read only field. If you need to change the city please contact us at harriercentral@gmail.com.',
//   ),
//   'regionName': SideBarData(
//     'State / Region',
//     Foundation.map,
//     'The state, region, or province that your Kenneel is located in.\r\n\r\nCurrently this is a read only field. If you need to change this setting please contact us at harriercentral@gmail.com.',
//   ),
//   'countryName': SideBarData(
//     'Country',
//     Entypo.globe,
//     'The country that your Kenneel is located in.\r\n\r\nCurrently this is a read only field. If you need to change this setting please contact us at harriercentral@gmail.com.',
//   ),
//   'distancePreference': SideBarData(
//     'Distance Preference',
//     MaterialCommunityIcons.ruler_square_compass,
//     'This setting determines if your Kennel will display distances in miles or kilometers.\r\n\r\nIt is probably best to keep this setting on the "Default for the Country" as Harrier Central will select the setting that is appropriate to the location you are in.',
//   ),
//   'kennelPinColor': SideBarData(
//     'Kennel Pin Color',
//     MaterialCommunityIcons.brush,
//     "Here's where you can select the color of the map pins for your Kennel.\r\n\r\nThis is especially important in cities where there is more than one Kennel using Harrier Central. Having different colored pins for different Hash groups makes it easy to identify which runs are yours.",
//   ),
//   'defaultEventPriceForMembers': SideBarData(
//     'Member Price',
//     FontAwesome5Solid.coins,
//     'Here you set the default price of runs for members of your Kennel.\r\n\r\nEvery run can have a different price, but when a run is first created, this value will be used as the default Hash Cash for your Kennel members.',
//   ),
//   'defaultEventPriceForNonMembers': SideBarData(
//     'Non-member Price',
//     FontAwesome5Solid.money_check_alt,
//     'Here you set the default price of runs for those who are not members of your Kennel.\r\n\r\nEvery run can have a different price, but when a run is first created, this value will be used as the default Hash Cash for virgins, visitors, and others.',
//   ),
//   'hashRunsDotOrgKennelLink': SideBarData(
//     'HashRuns.org Kennel Link',
//     Octicons.link,
//     "This link will bring you to our public website for run information www.hashruns.org.\r\n\r\nYour Kennel must be configured to work with HashRuns.org which you can set on the 'Other' tab here.\r\n\r\nYou can open or copy the link with these buttons.",
//   ),
//   'publicKennelId': SideBarData(
//     'Public Kennel ID',
//     MaterialCommunityIcons.fingerprint,
//     "Your Kennel's public ID uniquely identifies your group in Harrier Central and is required for backend interactions.\r\n\r\nThis public value can be shared and viewed without risk.",
//   ),
//   'googleCalendarIntegration': SideBarData(
//     'Google Calendar Integration',
//     FontAwesome.google,
//     'Use this setting to publish run details to Google Calendars. Go to Google calendar, copy the Calendar ID and paste it here.\r\n\r\nYou also must grant harriercentral@gmail.com “Make Changes to Events” permission.\r\n\r\nFor multiple calendars, separate IDs with commas.',
//   ),
//   'globalGoogleCalendar': SideBarData(
//     'Global Google Calendar',
//     FontAwesome.google,
//     "By turning this option on, your run information will be added to Harrier Central's global Google Calendar that lists runs from all over the world.",
//   ),
//   'otherTab': SideBarData(
//     'Other Settings',
//     Ionicons.settings,
//     'This tab contains other settings that may be interesting for you to experiment with',
//   ),
//   'hashRunsDotOrgCityLink': SideBarData(
//     'HashRuns.org City Link',
//     Icons.location_city,
//     "This link will bring you to our public website for run information for your city on www.hashruns.org.\r\n\r\nYour Kennel must be configured to work with HashRuns.org which you can set on the 'Other' tab here.\r\n\r\nYou can open or copy the link with these buttons.",
//   ),
//   'developerTab': SideBarData(
//     'Developer',
//     MaterialCommunityIcons.hammer_wrench,
//     'This page contains useful links that are specific to your Kennel and resources for software developers.\r\n\r\nCheck out our growing set of Application Programming Interfaces (APIs) that give you options to build your own tools using data in our Global Hash database.',
//   ),
//   'hashRunsDotOrgRegionLink': SideBarData(
//     'HashRuns.org state, province, or region link',
//     Foundation.map,
//     "This link will bring you to our public website for run information for all kennels in your state, province or region on www.hashruns.org.\r\n\r\nYour Kennel must be configured to work with HashRuns.org which you can set on the 'Other' tab here.\r\n\r\nYou can open or copy the link with these buttons.",
//   ),
//   'hashRunsDotOrgCountryLink': SideBarData(
//     'HashRuns.org country link',
//     SimpleLineIcons.globe,
//     "This link will bring you to our public website for run information for all kennels in your country on www.hashruns.org.\r\n\r\nYour Kennel must be configured to work with HashRuns.org which you can set on the 'Other' tab here.\r\n\r\nYou can open or copy the link with these buttons.",
//   ),
//   'leaderboardLink': SideBarData(
//     'Leaderboard',
//     Fontisto.list_1,
//     'This link takes you to a web component that can be embedded in your website that has up-to-date run statistics for all members of your Kennel\r\n\r\nYou can embed this component using an <iframe> and let Hashers from your Kennel see, sort, export, and print run statistics',
//   ),
//   'iframeDescription': SideBarData(
//     'What is an <iframe>?',
//     MaterialCommunityIcons.xml,
//     "An <iframe> lets you display content from another website on your own, like embedding a YouTube video or Google Map.\r\n\r\nIt is perfect for adding Harrier Central widgets to your site, showing trails, events, or hash features seamlessly.\r\n\r\nTo use this IFrame, paste this code into one of your website's HTML page.",
//   ),
//   'eventsListApi': SideBarData(
//     'Run List API',
//     MaterialCommunityIcons.xml,
//     "Using this Harrier Central API call, developers can request and receive a Kennel's upcoming run list programmatically.",
//   ),
//   'nextRunApi': SideBarData(
//     'Next Run API',
//     MaterialCommunityIcons.xml,
//     'Using this Harrier Central API call, developers can request full details for the next run of their Kennel.',
//   ),
//   'leaderboardApi': SideBarData(
//     'Leaderboard API',
//     Entypo.trophy,
//     'Using this Harrier Central API call, developers can get a list of run counts for everyone who has run with their Kennel.',
//   ),
//   'wordpressToolbox': SideBarData(
//     'WordPress Toolbox',
//     FontAwesome.wordpress,
//     "Download this WordPress plug-in to enhance your WordPress Hash webpage with live data from Harrier Central.\r\n\r\nChanges to runs made through the portal (and soon the app too) are instantly reflected on your website making Harrier Central your one-stop data platform for all of your Kennel's data.",
//   ),
//   'extApiKey': SideBarData(
//     'API Secret Key',
//     Fontisto.key,
//     'Your API Secret Key gives you access to the Harrier Central platform.\r\n\r\nIt is a unique cryptographically generated complex key that acts as a username and password and should be protected.\r\n\r\nIf you believe that this key has been revealed to untrusted third parties, please regenerate a new one.',
//   ),
//   'masterDetailShortcode': SideBarData(
//     'List/Detail shortcode',
//     MaterialIcons.vertical_split,
//     'Add this shortcode to any WordPress page to embed a list/detail view of past or future runs.\r\n\r\nYou can also add shortcode options to control the styling of the data to match your website.',
//   ),
//   'galleryShortcode': SideBarData(
//     'Gallery shortcode',
//     MaterialIcons.view_comfortable,
//     'Add this shortcode to any WordPress page to embed a gallery view of past or future runs.\r\n\r\nYou can also add shortcode options to control the styling of the data to match your website.',
//   ),
//   'tableShortcode': SideBarData(
//     'Table shortcode',
//     AntDesign.table,
//     'Add this shortcode to any WordPress page to embed a list view of past or future runs.\r\n\r\nYou can also add shortcode options to control the styling of the data to match your website.',
//   ),
//   'nextRunShortcode': SideBarData(
//     'Next Run shortcode',
//     MaterialCommunityIcons.run_fast,
//     'Add this shortcode to any WordPress page to embed the full detail of your next run.\r\n\r\nYou can also add shortcode options to control the styling of the data to match your website.',
//   ),
//   'leaderboardShortcode': SideBarData(
//     'Run counts / leaderboard shortcode',
//     Fontisto.list_1,
//     'Add this shortcode to any WordPress page to embed a table containing your current run counts.\r\n\r\nAbove the table you will find convenient buttons for exporting the data to Excel, CSV, PDF, and for printing',
//   ),
// };

// class KennelFormController extends GetxController {
//   KennelFormController(this.originalData) {
//     // Initialize controllers with initial data if available
//     print('KennelFormController initialized ${DateTime.now()}');
//     setScreenSize();
//     if (originalData != null) {
//       setInitialValues();
//     }
//   }

//   // Text controllers for all required fields
//   final kennelName = TextEditingController();
//   final kennelShortName = TextEditingController();
//   final kennelUniqueShortName = TextEditingController();

//   final kennelLogo = TextEditingController();
//   final kennelDescription = TextEditingController();
//   final cityName = TextEditingController();
//   final regionName = TextEditingController();
//   final countryName = TextEditingController();
//   final continentName = TextEditingController();
//   final publishToGoogleCalendarAddresses = TextEditingController();
//   final mismanagementTeam = TextEditingController();
//   final kennelCoverPhoto = TextEditingController();
//   final kennelWebsiteUrl = TextEditingController();
//   final kennelEventsUrl = TextEditingController();
//   final kennelHcEventsUrl = TextEditingController();
//   final extApiKey = TextEditingController();
//   final kennelPublicId = TextEditingController();

//   bool kennelNameValid = true;
//   bool kennelShortNameValid = true;
//   bool kennelUniqueShortNameValid = true;
//   bool kennelLogoValid = true;
//   bool kennelDescriptionValid = true;
//   bool cityNameValid = true;
//   bool regionNameValid = true;
//   bool countryNameValid = true;
//   bool continentNameValid = true;
//   bool googleCalendarAddresses = true;
//   bool mismanagementTeamValid = true;
//   bool websiteUrlValid = true;
//   bool kennelCoverPhotoValid = true;
//   bool kennelWebsiteUrlValid = true;
//   bool kennelEventsUrlValid = true;
//   bool kennelHcEventsUrlValid = true;
//   bool kennelAdminEmailListValid = true;
//   bool kennelLatitudeValid = true;
//   bool kennelLongitudeValid = true;
//   bool defaultEventPriceForMembersValid = true;
//   bool defaultEventPriceForNonMembersValid = true;

//   final kennelAdminEmailList = TextEditingController();
//   final bankScheme = TextEditingController();
//   final bankAccountNumber = TextEditingController();
//   final bankBic = TextEditingController();
//   final bankBeneficiary = TextEditingController();
//   final kennelPaymentScheme = TextEditingController();
//   final kennelPaymentUrl = TextEditingController();

//   final kennelPaymentScheme2 = TextEditingController();
//   final kennelPaymentUrl2 = TextEditingController();

//   final kennelPaymentScheme3 = TextEditingController();
//   final kennelPaymentUrl3 = TextEditingController();

//   final kennelSearchTags = TextEditingController();

//   final defaultEventPriceForMembersController = TextEditingController();
//   final defaultEventPriceForNonMembersController = TextEditingController();

//   // Reactive variables for non-text fields
//   RxBool excludeFromLeaderboard = false.obs;
//   RxBool canEditRunAttendence = false.obs;
//   RxBool disseminateHashRunsDotOrg = false.obs;
//   RxBool disseminateAllowWebLinks = false.obs;
//   RxBool allowSelfPayment = false.obs;
//   RxBool allowNegativeCredit = false.obs;
//   RxBool publishToGoogleCalendar = false.obs;
//   RxBool disseminateOnGlobalGoogleCalendar = true.obs;

//   Rx<double?>? latitude;
//   Rx<double?>? longitude;
//   final RxDouble defaultLatitude = 0.0.obs;
//   final RxDouble defaultLongitude = 0.0.obs;
//   final RxDouble defaultEventPriceForMembers = 0.0.obs;
//   final RxDouble defaultEventPriceForNonMembers = 0.0.obs;

//   final RxInt kennelStatus = 0.obs;
//   final RxInt disseminationAudience = 0.obs;
//   final RxInt kennelPinColor = 0.obs;

//   final RxInt defaultRunTags1 = 0.obs;
//   final RxInt defaultRunTags2 = 0.obs;
//   final RxInt defaultRunTags3 = 0.obs;
//   final RxInt membershipDurationInMonths = 0.obs;
//   final RxInt distancePreference = 0.obs;
//   final RxInt websiteControlFlags = 0.obs;
//   final RxDouble kennelPaymentMemberSurcharge = 0.0.obs;
//   final RxDouble kennelPaymentNonMemberSurcharge = 0.0.obs;
//   final RxDouble kennelPaymentMemberSurcharge2 = 0.0.obs;
//   final RxDouble kennelPaymentNonMemberSurcharge2 = 0.0.obs;
//   final RxDouble kennelPaymentMemberSurcharge3 = 0.0.obs;
//   final RxDouble kennelPaymentNonMemberSurcharge3 = 0.0.obs;

//   final Rx<DateTime> defaultRunStartTime = DateTime.now().obs;
//   final Rx<DateTime> runCountStartDate = DateTime.now().obs;
//   final Rx<DateTime> kennelPaymentUrlExpires = DateTime.now().obs;
//   final Rx<DateTime> kennelPaymentUrlExpires2 = DateTime.now().obs;
//   final Rx<DateTime> kennelPaymentUrlExpires3 = DateTime.now().obs;

//   KennelModel? originalData;
//   KennelModel? editedData;

//   final RxBool overrideDefaultLatitude = true.obs;
//   final RxBool overrideDefaultLongitude = true.obs;

//   final Map<String, FocusNode> focusNodes = {};
//   final Map<String, RxBool> focusStates = {};

//   final ScrollController allFieldsTabScrollController = ScrollController();

//   // Reactive variable to track if form is dirty
//   RxBool isFormDirty = false.obs;

//   RxInt extApiStateUpdater = 0.obs;

//   GlobalKey<FormState> formKey = GlobalKey<FormState>(
//     debugLabel: 'debug = ${DateTime.now().second}',
//   );

//   RxInt currentIndex = 0.obs;

//   Worker? _worker;

//   Rx<EScreenSize> screenSize = EScreenSize.isMobileScreen.obs;
//   int NARROW_SCREEN_WIDTH = 900;
//   int MOBILE_SCREEN_WIDTH = 650;

//   @override
//   void onInit() {
//     super.onInit();

//     _worker = debounce(
//       width,
//       (_) {
//         setScreenSize();
//         //print('debounce width = $width');
//       },
//       time: const Duration(milliseconds: 50),
//     );
//   }

//   void setScreenSize() {
//     if (Get.mediaQuery.size.width < MOBILE_SCREEN_WIDTH) {
//       screenSize.value = EScreenSize.isMobileScreen;
//       //print('size set to mobile');
//     } else if (Get.mediaQuery.size.width < NARROW_SCREEN_WIDTH) {
//       screenSize.value = EScreenSize.isNarrowScreen;
//       //print('size set to narrow');
//     } else {
//       screenSize.value = EScreenSize.isNormalScreen;
//       //print('size set to normal');
//     }
//   }

//   @override
//   void onClose() {
//     _worker?.dispose(); // Dispose the worker manually
//     dispose();
//     super.onClose();
//   }

//   Rx<String?> sidebarTitle = Rx<String?>(null);
//   Rx<IconData?> sidebarIcon = Rx<IconData?>(null);
//   Rx<String?> sidebarDescription = Rx<String?>(null);

//   void setInitialValues() {
//     editedData = originalData!.copyWith();

//     // assume that the data we are loading from the server is already valid
//     kennelNameValid = true;
//     kennelShortNameValid = true;
//     kennelUniqueShortNameValid = true;
//     kennelLogoValid = true;
//     kennelDescriptionValid = true;
//     cityNameValid = true;
//     regionNameValid = true;
//     countryNameValid = true;
//     continentNameValid = true;
//     googleCalendarAddresses = true;
//     mismanagementTeamValid = true;
//     websiteUrlValid = true;
//     kennelCoverPhotoValid = true;
//     kennelWebsiteUrlValid = true;
//     kennelEventsUrlValid = true;
//     kennelHcEventsUrlValid = true;
//     kennelAdminEmailListValid = true;
//     kennelLatitudeValid = true;
//     kennelLongitudeValid = true;
//     defaultEventPriceForMembersValid = true;
//     defaultEventPriceForNonMembersValid = true;

//     // text fields
//     excludeFromLeaderboard.value = originalData!.excludeFromLeaderboard == 1;
//     kennelName.text = originalData!.kennelName;
//     kennelShortName.text = originalData!.kennelShortName;
//     kennelUniqueShortName.text = originalData!.kennelUniqueShortName;
//     kennelLogo.text = originalData!.kennelLogo;
//     kennelDescription.text = originalData!.kennelDescription;
//     cityName.text = originalData!.cityName;
//     regionName.text = originalData!.regionName;
//     countryName.text = originalData!.countryName;
//     continentName.text = originalData!.continentName;
//     publishToGoogleCalendarAddresses.text =
//         originalData!.publishToGoogleCalendarAddresses ?? '';
//     mismanagementTeam.text = originalData!.mismanagementTeam ?? '';
//     kennelCoverPhoto.text = originalData!.kennelCoverPhoto ?? '';
//     kennelWebsiteUrl.text = originalData!.kennelWebsiteUrl ?? '';
//     kennelEventsUrl.text = originalData!.kennelEventsUrl ?? '';
//     kennelHcEventsUrl.text = originalData!.kennelHcEventsUrl ?? '';
//     kennelAdminEmailList.text = originalData!.kennelAdminEmailList ?? '';
//     bankScheme.text = originalData!.bankScheme ?? '';
//     bankAccountNumber.text = originalData!.bankAccountNumber ?? '';
//     bankBic.text = originalData!.bankBic ?? '';
//     bankBeneficiary.text = originalData!.bankBeneficiary ?? '';
//     kennelPaymentScheme.text = originalData!.kennelPaymentScheme ?? '';
//     kennelPaymentUrl.text = originalData!.kennelPaymentUrl ?? '';

//     kennelPaymentScheme2.text = originalData!.kennelPaymentScheme2 ?? '';
//     kennelPaymentUrl2.text = originalData!.kennelPaymentUrl2 ?? '';

//     kennelPaymentScheme3.text = originalData!.kennelPaymentScheme3 ?? '';
//     kennelPaymentUrl3.text = originalData!.kennelPaymentUrl3 ?? '';

//     extApiKey.text = originalData!.extApiKey;
//     kennelPublicId.text = originalData!.kennelPublicId.toString();
//     kennelSearchTags.text = originalData!.kennelSearchTags ?? '';

//     // boolean switches
//     excludeFromLeaderboard.value = originalData!.excludeFromLeaderboard == 1;
//     canEditRunAttendence.value = originalData!.canEditRunAttendence == 1;
//     disseminateHashRunsDotOrg.value =
//         originalData!.disseminateHashRunsDotOrg != 0;
//     disseminateOnGlobalGoogleCalendar.value =
//         originalData!.disseminateOnGlobalGoogleCalendar != 0;
//     disseminateAllowWebLinks.value =
//         originalData!.disseminateAllowWebLinks != 0;
//     publishToGoogleCalendar.value = originalData!.publishToGoogleCalendar != 0;
//     allowSelfPayment.value = originalData!.allowSelfPayment == 1;
//     allowNegativeCredit.value = originalData!.allowNegativeCredit == 1;

//     // dropdown lists
//     kennelStatus.value = originalData!.kennelStatus;
//     disseminationAudience.value = originalData!.disseminationAudience;
//     kennelPinColor.value = originalData!.kennelPinColor;
//     distancePreference.value = originalData!.distancePreference ?? -1;

//     // double fields
//     latitude = originalData!.latitude.obs;
//     longitude = originalData!.longitude.obs;
//     defaultLatitude.value = originalData!.defaultLatitude ?? 0.0;
//     defaultLongitude.value = originalData!.defaultLongitude ?? 0.0;

//     defaultEventPriceForMembers.value =
//         originalData!.defaultEventPriceForMembers;
//     defaultEventPriceForNonMembers.value =
//         originalData!.defaultEventPriceForNonMembers;
//     defaultEventPriceForMembersController.text =
//         originalData!.defaultEventPriceForMembers.toString();
//     defaultEventPriceForNonMembersController.text =
//         originalData!.defaultEventPriceForNonMembers.toString();

//     kennelPaymentMemberSurcharge.value =
//         originalData!.kennelPaymentMemberSurcharge ?? 0.0;
//     kennelPaymentNonMemberSurcharge.value =
//         originalData!.kennelPaymentNonMemberSurcharge ?? 0.0;

//     // int fields

//     membershipDurationInMonths.value = originalData!.membershipDurationInMonths;

//     // flag fields
//     disseminationAudience.value = originalData!.disseminationAudience;
//     defaultRunTags1.value = originalData!.defaultRunTags1;
//     defaultRunTags2.value = originalData!.defaultRunTags2;
//     defaultRunTags3.value = originalData!.defaultRunTags3;
//     websiteControlFlags.value = originalData!.websiteControlFlags ?? 0;

//     // datetime fields
//     defaultRunStartTime.value = originalData!.defaultRunStartTime;
//     runCountStartDate.value = originalData!.runCountStartDate ?? DateTime(2000);

//     kennelPaymentUrlExpires.value =
//         originalData!.kennelPaymentUrlExpires ?? DateTime(2000);
//     kennelPaymentUrlExpires2.value =
//         originalData!.kennelPaymentUrlExpires2 ?? DateTime(2000);
//     kennelPaymentUrlExpires3.value =
//         originalData!.kennelPaymentUrlExpires3 ?? DateTime(2000);

//     overrideDefaultLatitude.value = latitude?.value != null;
//     overrideDefaultLongitude.value = longitude?.value != null;

//     clearFields();
//     addFocusField('kennelShortName');
//     addFocusField('kennelUniqueShortName');
//     addFocusField('kennelName');
//     addFocusField('kennelDescription');
//     addFocusField('kennelLatitude');
//     addFocusField('kennelLongitude');
//     addFocusField('kennelStatus');
//     addFocusField('kennelAdminEmailList');
//     addFocusField('kennelWebsiteUrl');
//     addFocusField('cityName');
//     addFocusField('regionName');
//     addFocusField('countryName');
//     addFocusField('distancePreference');
//     addFocusField('kennelPinColor');
//     addFocusField('defaultEventPriceForMembers');
//     addFocusField('defaultEventPriceForNonMembers');
//   }

//   List<RxBool> tabValidResults = List<RxBool>.generate(7, (index) => true.obs);

//   void clearFields() {
//     focusNodes.clear();
//     focusStates.clear();
//   }

//   RxDouble width = 0.0.obs;
//   RxDouble height = 0.0.obs;

//   void updateSizeWithDebounce(double newWidth, double newHeight) {
//     if (width.value != newWidth) {
//       width.value = newWidth;
//     }
//     if (height.value != newHeight) {
//       height.value = newHeight;
//     }
//   }

//   void setSidebarData(String key) {
//     if (sidebarData.containsKey(key)) {
//       sidebarDescription.value = sidebarData[key]!.description;
//       sidebarTitle.value = sidebarData[key]!.title;
//       sidebarIcon.value = sidebarData[key]!.icon;
//     }
//   }

//   void addFocusField(String fieldName) {
//     focusNodes[fieldName] = FocusNode();
//     focusStates[fieldName] = false.obs;

//     focusNodes[fieldName]?.addListener(() {
//       focusStates[fieldName]?.value = focusNodes[fieldName]?.hasFocus ?? false;
//       if ((focusStates[fieldName]?.value ?? false) &&
//           (sidebarData.containsKey(fieldName))) {
//         setSidebarData(fieldName);
//       }

//       // else {
//       //   sidebarDescription.value = null;
//       //   sidebarTitle.value = null;
//       //   sidebarIcon.value = null;
//       // }
//       print('$fieldName -> ${focusStates[fieldName]?.value}');
//     });
//   }

//   final int NUM_TABS = 6;

//   final RxBool allFieldsAreValid = true.obs;

//   void isTabValid(int index) {
//     //Future.delayed(Duration(milliseconds: 0)).then((_) {
//     switch (index) {
//       // case 0:
//       //   tabValidResults[index].value =
//       //       (!(!kennelNameValid || !kennelShortNameValid));
//       //   break;
//       case 0: // currently required fields
//         tabValidResults[index].value = (!(!kennelNameValid ||
//             !kennelShortNameValid ||
//             !kennelUniqueShortNameValid ||
//             !kennelDescriptionValid ||
//             !kennelWebsiteUrlValid ||
//             !kennelAdminEmailListValid));
//       case 1: // currently Location
//         tabValidResults[index].value =
//             (!(!kennelLatitudeValid || !kennelLongitudeValid));

//       case 2: // currently Hash Cash
//         tabValidResults[index].value = (!(!defaultEventPriceForMembersValid ||
//             !defaultEventPriceForNonMembersValid));
//     }
//     //print(tabValidResults[index].value);
//     for (var i = 0; i < NUM_TABS; i++) {
//       if (tabValidResults[index].value) {
//         if (i == NUM_TABS - 1) {
//           allFieldsAreValid.value = true;
//         }
//         continue;
//       }
//       allFieldsAreValid.value = false;
//     }
//     // });
//   }

//   // Check if any field differs from its initial value
//   void checkIfFormIsDirty({int tabIndex = -1}) {
//     isFormDirty.value = (originalData != editedData);
//     if (tabIndex != -1) {
//       isTabValid(tabIndex);
//     }
//     // print('checkIfFormIsDirty called ${formKey.toString()}');
//     formKey.currentState?.validate();
//   }

//   void undoChanges() {
//     setInitialValues();
//     checkIfFormIsDirty();
//     isTabValid(0);
//   }

//   Future<void> save() async {
//     if (editedData != null) {
//       final accessToken = Utilities.generateToken(
//         box.get(HIVE_HASHER_ID) as String,
//         'hcportal_editKennel',
//         paramString: editedData!.kennelPublicId.uuid,
//       );

//       final bodyParams = <String, dynamic>{
//         'queryType': 'editKennel',
//         'publicHasherId': box.get(HIVE_HASHER_ID) as String,
//         'accessToken': accessToken,
//         'publicKennelId': editedData!.kennelPublicId.uuid,
//       };

//       final editedDataJson = editedData!.toJson();
//       final originalDataJson = originalData!.toJson();
//       final changedData = <String, dynamic>{};

//       editedDataJson.forEach((String key, dynamic value) {
//         if (editedDataJson[key] != originalDataJson[key]) {
//           if ((key.toLowerCase() == 'latitude') ||
//               (key.toLowerCase() == 'longitude')) {
//             changedData[key] = editedDataJson[key] ?? 999;
//           } else {
//             changedData[key] = editedDataJson[key];
//           }
//         }
//       });

//       bodyParams.addAll(changedData);

//       final jsonResult = await ServiceCommon.sendHttpPostToAzureFunctionApi(
//         bodyParams,
//       );

//       if (jsonResult.length > 10) {
//         final items = ((json.decode(jsonResult) as List<dynamic>)[0]
//             as List<dynamic>)[0] as Map<String, dynamic>;
//         final result = items['result'] as String;
//         final resultInt = items['resultCode'] as int;

//         if (resultInt == 1) {
//           originalData = editedData!.copyWith();
//           checkIfFormIsDirty();
//         }

//         await CoreUtilities.showAlert(
//           'Update result',
//           result,
//           'OK',
//         );
//       }
//     }
//   }
// }
