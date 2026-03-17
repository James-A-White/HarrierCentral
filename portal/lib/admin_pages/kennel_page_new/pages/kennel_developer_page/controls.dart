/// Kennel Developer Page Controls
///
/// This file defines the UI control configurations for the Kennel Developer tab.
/// Since the Developer tab contains read-only information (IDs, links, APIs),
/// it doesn't require user input validation and will always show as valid.

part of '../../kennel_page_new_controller.dart';

// ---------------------------------------------------------------------------
// Control Initialization Extension
// ---------------------------------------------------------------------------

/// Extension that adds kennel developer control initialization.
extension KennelDeveloperControlsExtension on KennelPageFormController {
  /// Initializes controls for the Kennel Developer tab.
  ///
  /// The Developer tab is informational only and doesn't have editable fields.
  /// We register sidebar data controls for each section.
  void initKennelDeveloperControls() {
    final tabKey = KennelTabType.developer.key;
    final tabIndex = KennelTabType.developer.index;

    // ---------------------------------------------------------------------------
    // Generic Tab Sidebar (default when not hovering on a specific item)
    // ---------------------------------------------------------------------------
    uiControls['${tabKey}_generic'] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: '${tabKey}_generic',
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Developer',
        MaterialCommunityIcons.hammer_wrench,
        'This page contains useful links that are specific to your Kennel and '
            'resources for software developers.\r\n\r\n'
            'Check out our growing set of Application Programming Interfaces (APIs) '
            'that give you options to build your own tools using data in our '
            'Global Hash database.',
      ),
      editedFieldValue: 'valid',
      originalFieldValue: 'valid',
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Developer Tab',
      readonly: true,
      includeOverrideButton: false,
      tabIndex: tabIndex,
      updateEditedValue: (_) {},
    );

    // ---------------------------------------------------------------------------
    // Digital Identifiers Section
    // ---------------------------------------------------------------------------
    uiControls['developer_publicKennelId'] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: 'developer_publicKennelId',
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Public Kennel ID',
        MaterialCommunityIcons.fingerprint,
        "Your Kennel's public ID uniquely identifies your group in Harrier Central "
            'and is required for backend interactions.\r\n\r\n'
            'This public value can be shared and viewed without risk.',
      ),
      editedFieldValue: 'valid',
      originalFieldValue: 'valid',
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Public Kennel ID',
      readonly: true,
      includeOverrideButton: false,
      tabIndex: tabIndex,
      updateEditedValue: (_) {},
    );

    uiControls['developer_extApiKey'] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: 'developer_extApiKey',
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'API Secret Key',
        Fontisto.key,
        'Your API Secret Key gives you access to the Harrier Central platform.\r\n\r\n'
            'It is a unique cryptographically generated complex key that acts as a '
            'username and password and should be protected.\r\n\r\n'
            'If you believe that this key has been revealed to untrusted third parties, '
            'please regenerate a new one.',
      ),
      editedFieldValue: 'valid',
      originalFieldValue: 'valid',
      globalKey: GlobalKey<FormFieldState>(),
      label: 'API Secret Key',
      readonly: true,
      includeOverrideButton: false,
      tabIndex: tabIndex,
      updateEditedValue: (_) {},
    );

    // ---------------------------------------------------------------------------
    // HashRuns.org Links Section
    // ---------------------------------------------------------------------------
    uiControls['developer_hashRunsKennel'] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: 'developer_hashRunsKennel',
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'HashRuns.org Kennel Link',
        Octicons.link,
        "This link will bring you to our public website for run information "
            "www.hashruns.org.\r\n\r\n"
            "Your Kennel must be configured to work with HashRuns.org which you "
            "can set on the 'Other' tab here.\r\n\r\n"
            'You can open or copy the link with these buttons.',
      ),
      editedFieldValue: 'valid',
      originalFieldValue: 'valid',
      globalKey: GlobalKey<FormFieldState>(),
      label: 'HashRuns.org Kennel Link',
      readonly: true,
      includeOverrideButton: false,
      tabIndex: tabIndex,
      updateEditedValue: (_) {},
    );

    uiControls['developer_hashRunsCity'] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: 'developer_hashRunsCity',
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'HashRuns.org City Link',
        Icons.location_city,
        "This link will bring you to our public website for run information "
            "for your city on www.hashruns.org.\r\n\r\n"
            "Your Kennel must be configured to work with HashRuns.org which you "
            "can set on the 'Other' tab here.\r\n\r\n"
            'You can open or copy the link with these buttons.',
      ),
      editedFieldValue: 'valid',
      originalFieldValue: 'valid',
      globalKey: GlobalKey<FormFieldState>(),
      label: 'HashRuns.org City Link',
      readonly: true,
      includeOverrideButton: false,
      tabIndex: tabIndex,
      updateEditedValue: (_) {},
    );

    uiControls['developer_hashRunsRegion'] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: 'developer_hashRunsRegion',
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'HashRuns.org Region Link',
        Foundation.map,
        "This link will bring you to our public website for run information "
            "for all kennels in your state, province or region on www.hashruns.org.\r\n\r\n"
            "Your Kennel must be configured to work with HashRuns.org which you "
            "can set on the 'Other' tab here.\r\n\r\n"
            'You can open or copy the link with these buttons.',
      ),
      editedFieldValue: 'valid',
      originalFieldValue: 'valid',
      globalKey: GlobalKey<FormFieldState>(),
      label: 'HashRuns.org Region Link',
      readonly: true,
      includeOverrideButton: false,
      tabIndex: tabIndex,
      updateEditedValue: (_) {},
    );

    uiControls['developer_hashRunsCountry'] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: 'developer_hashRunsCountry',
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'HashRuns.org Country Link',
        SimpleLineIcons.globe,
        "This link will bring you to our public website for run information "
            "for all kennels in your country on www.hashruns.org.\r\n\r\n"
            "Your Kennel must be configured to work with HashRuns.org which you "
            "can set on the 'Other' tab here.\r\n\r\n"
            'You can open or copy the link with these buttons.',
      ),
      editedFieldValue: 'valid',
      originalFieldValue: 'valid',
      globalKey: GlobalKey<FormFieldState>(),
      label: 'HashRuns.org Country Link',
      readonly: true,
      includeOverrideButton: false,
      tabIndex: tabIndex,
      updateEditedValue: (_) {},
    );

    // ---------------------------------------------------------------------------
    // Web Components Section
    // ---------------------------------------------------------------------------
    uiControls['developer_leaderboard'] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: 'developer_leaderboard',
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Leaderboard',
        Fontisto.list_1,
        'This link takes you to a web component that can be embedded in your '
            'website that has up-to-date run statistics for all members of your Kennel.\r\n\r\n'
            'You can embed this component using an <iframe> and let Hashers from '
            'your Kennel see, sort, export, and print run statistics.',
      ),
      editedFieldValue: 'valid',
      originalFieldValue: 'valid',
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Leaderboard',
      readonly: true,
      includeOverrideButton: false,
      tabIndex: tabIndex,
      updateEditedValue: (_) {},
    );

    // ---------------------------------------------------------------------------
    // Data APIs Section
    // ---------------------------------------------------------------------------
    uiControls['developer_eventsApi'] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: 'developer_eventsApi',
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Run List API',
        MaterialCommunityIcons.xml,
        "Using this Harrier Central API call, developers can request and receive "
            "a Kennel's upcoming run list programmatically.",
      ),
      editedFieldValue: 'valid',
      originalFieldValue: 'valid',
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Run List API',
      readonly: true,
      includeOverrideButton: false,
      tabIndex: tabIndex,
      updateEditedValue: (_) {},
    );

    uiControls['developer_nextRunApi'] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: 'developer_nextRunApi',
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Next Run API',
        MaterialCommunityIcons.xml,
        'Using this Harrier Central API call, developers can request full details '
            'for the next run of their Kennel.',
      ),
      editedFieldValue: 'valid',
      originalFieldValue: 'valid',
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Next Run API',
      readonly: true,
      includeOverrideButton: false,
      tabIndex: tabIndex,
      updateEditedValue: (_) {},
    );

    uiControls['developer_leaderboardApi'] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: 'developer_leaderboardApi',
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Leaderboard API',
        Entypo.trophy,
        'Using this Harrier Central API call, developers can get a list of run '
            'counts for everyone who has run with their Kennel.',
      ),
      editedFieldValue: 'valid',
      originalFieldValue: 'valid',
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Leaderboard API',
      readonly: true,
      includeOverrideButton: false,
      tabIndex: tabIndex,
      updateEditedValue: (_) {},
    );

    // ---------------------------------------------------------------------------
    // WordPress Toolbox Section
    // ---------------------------------------------------------------------------
    uiControls['developer_wordpressPlugin'] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: 'developer_wordpressPlugin',
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'WordPress Toolbox',
        FontAwesome.wordpress,
        "Download this WordPress plug-in to enhance your WordPress Hash webpage "
            "with live data from Harrier Central.\r\n\r\n"
            "Changes to runs made through the portal (and soon the app too) are "
            "instantly reflected on your website making Harrier Central your "
            "one-stop data platform for all of your Kennel's data.",
      ),
      editedFieldValue: 'valid',
      originalFieldValue: 'valid',
      globalKey: GlobalKey<FormFieldState>(),
      label: 'WordPress Plugin',
      readonly: true,
      includeOverrideButton: false,
      tabIndex: tabIndex,
      updateEditedValue: (_) {},
    );

    uiControls['developer_shortcodeMasterDetail'] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: 'developer_shortcodeMasterDetail',
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'List/Detail Shortcode',
        MaterialIcons.vertical_split,
        'Add this shortcode to any WordPress page to embed a list/detail view '
            'of past or future runs.\r\n\r\n'
            'You can also add shortcode options to control the styling of the '
            'data to match your website.',
      ),
      editedFieldValue: 'valid',
      originalFieldValue: 'valid',
      globalKey: GlobalKey<FormFieldState>(),
      label: 'List/Detail Shortcode',
      readonly: true,
      includeOverrideButton: false,
      tabIndex: tabIndex,
      updateEditedValue: (_) {},
    );

    uiControls['developer_shortcodeGallery'] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: 'developer_shortcodeGallery',
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Gallery Shortcode',
        MaterialIcons.view_comfortable,
        'Add this shortcode to any WordPress page to embed a gallery view '
            'of past or future runs.\r\n\r\n'
            'You can also add shortcode options to control the styling of the '
            'data to match your website.',
      ),
      editedFieldValue: 'valid',
      originalFieldValue: 'valid',
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Gallery Shortcode',
      readonly: true,
      includeOverrideButton: false,
      tabIndex: tabIndex,
      updateEditedValue: (_) {},
    );

    uiControls['developer_shortcodeTable'] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: 'developer_shortcodeTable',
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Table Shortcode',
        AntDesign.table,
        'Add this shortcode to any WordPress page to embed a list view '
            'of past or future runs.\r\n\r\n'
            'You can also add shortcode options to control the styling of the '
            'data to match your website.',
      ),
      editedFieldValue: 'valid',
      originalFieldValue: 'valid',
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Table Shortcode',
      readonly: true,
      includeOverrideButton: false,
      tabIndex: tabIndex,
      updateEditedValue: (_) {},
    );

    uiControls['developer_shortcodeNextRun'] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: 'developer_shortcodeNextRun',
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Next Run Shortcode',
        MaterialCommunityIcons.run_fast,
        'Add this shortcode to any WordPress page to embed the full detail '
            'of your next run.\r\n\r\n'
            'You can also add shortcode options to control the styling of the '
            'data to match your website.',
      ),
      editedFieldValue: 'valid',
      originalFieldValue: 'valid',
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Next Run Shortcode',
      readonly: true,
      includeOverrideButton: false,
      tabIndex: tabIndex,
      updateEditedValue: (_) {},
    );

    uiControls['developer_shortcodeLeaderboard'] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: 'developer_shortcodeLeaderboard',
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Leaderboard Shortcode',
        Fontisto.list_1,
        'Add this shortcode to any WordPress page to embed a table containing '
            'your current run counts.\r\n\r\n'
            'Above the table you will find convenient buttons for exporting '
            'the data to Excel, CSV, PDF, and for printing.',
      ),
      editedFieldValue: 'valid',
      originalFieldValue: 'valid',
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Leaderboard Shortcode',
      readonly: true,
      includeOverrideButton: false,
      tabIndex: tabIndex,
      updateEditedValue: (_) {},
    );

    // Ensure this tab always shows as valid (checkbox icon)
    tabStatus[tabIndex].value = TabStatus.isCompleteAndValid;
  }
}
