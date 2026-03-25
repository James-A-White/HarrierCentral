/// Kennel Edit Page UI
///
/// This file contains the main UI for editing kennel information.
/// Uses GetX for state management with the [GetView] pattern for cleaner code.
///
/// Structure:
/// - [KennelEditPage] - Main page widget (GetView-based)
/// - Tab content widgets for each section
/// - Extension methods for building widgets (in part files)

import 'package:hcportal/tabbed_ui/widgets/tri_state_checkbox_field.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';

import 'kennel_page_new_enums.dart';
import 'package:hcportal/imports.dart';
import 'pages/kennel_tags_page/run_tags_tab_content.dart';

part 'pages/kennel_info_page/layout.dart';
part 'pages/kennel_location_page/layout.dart';
part 'pages/kennel_other_page/layout.dart';
part 'pages/kennel_developer_page/layout.dart';
part 'pages/kennel_hash_cash_page/layout.dart';
part 'pages/kennel_songs_page/layout.dart';
part 'pages/kennel_logo_page/layout.dart';
part 'pages/kennel_page_new_widgets.dart';

// ---------------------------------------------------------------------------
// Kennel Edit Page
// ---------------------------------------------------------------------------

/// Main page for editing kennel information.
///
/// This page uses [GetView] with [KennelPageFormController] for state management,
/// eliminating the need for a StatefulWidget. The controller is initialized
/// when the page is built and cleaned up when navigation occurs.
class KennelEditPage extends GetView<KennelPageFormController> {
  const KennelEditPage({
    required this.kennelData,
    required this.appAccessFlags,
    super.key,
  });

  /// Initial kennel data to populate the form.
  final KennelModel kennelData;

  /// AppAccessFlags for the current user against this kennel.
  final int appAccessFlags;

  @override
  Widget build(BuildContext context) {
    // Initialize the controller with the kennel data
    _ensureControllerInitialized();

    return GetBuilder<KennelPageFormController>(
      id: 'kennelFormPageBuilder',
      builder: (_) => _KennelFormScaffold(controller: controller),
    );
  }

  /// Ensures the controller is registered before building.
  void _ensureControllerInitialized() {
    if (!Get.isRegistered<KennelPageFormController>()) {
      Get.put(
        KennelPageFormController(kennelData, appAccessFlags: appAccessFlags),
        permanent: true,
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Scaffold Widget
// ---------------------------------------------------------------------------

/// Main scaffold containing the app bar and tab structure.
class _KennelFormScaffold extends StatelessWidget {
  const _KennelFormScaffold({required this.controller});

  final KennelPageFormController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          controller.updateSizeWithDebounce(
            constraints.maxWidth,
            constraints.maxHeight,
          );

          return Scaffold(
            appBar: _buildAppBar(),
            body: _buildBody(),
          );
        },
      ),
    );
  }

  /// Builds the app bar with title and auto-save controls.
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: _BackButton(),
      title: _KennelTitle(controller: controller),
      actions: [_AutoSaveControls(controller: controller)],
    );
  }

  /// Builds the main body with tab bar and tab views.
  Widget _buildBody() {
    return DefaultTabController(
      length: KennelTabType.values.length,
      child: Column(
        children: [
          _KennelTabBar(controller: controller),
          Expanded(child: _KennelTabBarView(controller: controller)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// App Bar Components
// ---------------------------------------------------------------------------

/// Back navigation button.
class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.back<void>(),
      child: const Icon(
        MaterialCommunityIcons.arrow_left,
        color: Colors.black,
      ),
    );
  }
}

/// Page title showing the kennel name being edited.
class _KennelTitle extends StatelessWidget {
  const _KennelTitle({required this.controller});

  final KennelPageFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Text(
        'Editing ${controller.editedData.value.kennelName}',
        style: headingStyleBlack,
      ),
    );
  }
}

/// Auto-save toggle and progress indicator.
class _AutoSaveControls extends StatelessWidget {
  const _AutoSaveControls({required this.controller});

  final KennelPageFormController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Auto-save progress indicator
        SizedBox(
          width: 150,
          child: Obx(() => _buildProgressIndicator()),
        ),
        const SizedBox(width: 20),

        // Auto-save label and toggle
        Text('Auto save', style: headingStyleBlack),
        const SizedBox(width: 10),
        Obx(
          () => Switch(
            value: controller.doAutoSave.value,
            onChanged: (_) => controller.toggleAutoSave(),
          ),
        ),
        const SizedBox(width: 30),
      ],
    );
  }

  /// Builds the appropriate progress indicator based on auto-save state.
  Widget _buildProgressIndicator() {
    if (!controller.doAutoSave.value) {
      return const SizedBox.shrink();
    }

    // Show "Saving..." text when actively saving
    if (controller.autoSaveCounter.value == -1) {
      return Center(
        child: Text(
          'Saving...',
          style: titleStyleBlack.copyWith(color: Colors.blue.shade700),
        ),
      );
    }

    // Show progress bar counting down to next save
    return LinearProgressIndicator(
      minHeight: 15,
      borderRadius: const BorderRadius.all(Radius.circular(5)),
      value: controller.autoSaveCounter.value / AUTOSAVE_PERIOD_IN_SECONDS,
    );
  }
}

// ---------------------------------------------------------------------------
// Tab Bar Components
// ---------------------------------------------------------------------------

/// Tab bar with styled tabs for each kennel section.
/// Uses ResponsiveTabBar to switch between tab bar (wide) and hamburger menu
/// (narrow/mobile).
class _KennelTabBar extends StatelessWidget {
  const _KennelTabBar({required this.controller});

  final KennelPageFormController controller;

  @override
  Widget build(BuildContext context) {
    return ResponsiveTabBar<KennelPageFormController>(
      controller: controller,
      formKey: controller.formKey,
      tabBarColor: Colors.blue.shade600,
    );
  }
}

/// Tab bar view containing all tab content pages.
class _KennelTabBarView extends StatelessWidget {
  const _KennelTabBarView({required this.controller});

  final KennelPageFormController controller;

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: controller.tabController,
      children: _buildTabBodies(),
    );
  }

  /// Generates tab body widgets wrapped in standard layout.
  List<Widget> _buildTabBodies() {
    return KennelTabType.values.map((tab) {
      final isKennelInfoTab = tab == KennelTabType.kennelInfo;
      return TabPageStandardLayout(
        title: tab.title,
        icon: tab.icon,
        description: tab.description,
        formController: controller,
        showCloseTabGroupButton: true,
        tabLocked: controller.tabLocked[tab.index],
        handlesOwnScrolling: tab == KennelTabType.songs || isKennelInfoTab,
        child: _buildTabContent(tab),
      );
    }).toList();
  }

  /// Returns the appropriate content widget for each tab.
  Widget _buildTabContent(KennelTabType tab) {
    switch (tab) {
      case KennelTabType.kennelInfo:
        return KennelInfoTabContent(controller: controller);
      case KennelTabType.kennelLocation:
        return KennelLocationTabContent(controller: controller);
      case KennelTabType.tags:
        return KennelRunTagsTabContent(controller: controller);
      case KennelTabType.other:
        return KennelOtherTabContent(controller: controller);
      case KennelTabType.developer:
        return KennelDeveloperTabContent(controller: controller);
      case KennelTabType.hashCash:
        return KennelHashCashTabContent(controller: controller);
      case KennelTabType.songs:
        return KennelSongsTabContent(controller: controller);
      case KennelTabType.kennelLogo:
        return KennelLogoTabContent(controller: controller);
    }
  }
}

// ---------------------------------------------------------------------------
// Tab Content Widgets
// ---------------------------------------------------------------------------

/// Content widget for the Kennel Info tab.
///
/// Displays form fields for basic kennel information including:
/// - Kennel name and abbreviations
/// - Description
/// - Contact information
/// - Website URL
class KennelInfoTabContent extends StatelessWidget {
  const KennelInfoTabContent({required this.controller, super.key});

  final KennelPageFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isMobileScreen =
          controller.screenSize.value == EScreenSize.isMobileScreen;

      // Get the description control to check expandToFillSpace
      final descControlKey =
          '${KennelTabType.kennelInfo.key}_${KennelInfoField.kennelDescription.name}';
      final descControl = controller.uiControls[descControlKey];
      final shouldExpand = descControl?.expandToFillSpace ?? false;
      final minHeight = descControl?.minHeight ?? 150.0;

      // Top widgets above the description
      final topWidgets = <Widget>[
        HelperWidgets().categoryLabelWidget('Basic Kennel Information'),
        RowColumn(
          isRow: !isMobileScreen,
          rowFlexValues: const [2, 1, 1],
          rowLeftPaddingValues: const [0.0, 20.0, 20.0],
          children: [
            _buildTextField(KennelInfoField.kennelName),
            _buildTextField(KennelInfoField.kennelShortName),
            _buildTextField(KennelInfoField.kennelUniqueShortName),
          ],
        ),
      ];

      // Bottom widgets below the description
      final bottomWidgets = <Widget>[
        // Contact Section
        HelperWidgets().categoryLabelWidget('Contact Information'),
        _buildTextField(
          KennelInfoField.kennelAdminEmailList,
          topPadding: 20,
        ),

        // Website Section
        HelperWidgets().categoryLabelWidget('Website Address'),
        _buildTextField(KennelInfoField.kennelWebsiteUrl),
      ];

      final lockState = controller.tabLocked[KennelTabType.kennelInfo.index];

      if (shouldExpand) {
        return Lockable(
          lockState: lockState,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: topWidgets,
                ),
              ),
              // Description fills remaining space (or minHeight)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: minHeight),
                          child: _buildTextField(
                            KennelInfoField.kennelDescription,
                            expandToFill: true,
                          ),
                        ),
                      ),
                    ),
                    ...bottomWidgets,
                  ],
                ),
              ),
            ],
          ),
        );
      } else {
        return Lockable(
          lockState: lockState,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...topWidgets,
                _buildTextField(KennelInfoField.kennelDescription,
                    topPadding: 20),
                ...bottomWidgets,
              ],
            ),
          ),
        );
      }
    });
  }

  /// Builds an editable text field for the given field type.
  Widget _buildTextField(
    KennelInfoField field, {
    double topPadding = 0,
    bool expandToFill = false,
  }) {
    final controlKey = '${KennelTabType.kennelInfo.key}_${field.name}';
    final uiControl = controller.uiControls[controlKey];

    if (uiControl == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: EditableOverrideTextField(
        controller: controller,
        uiControl: uiControl,
        onChanged: (_) => controller.checkIfFormIsDirty(),
        expandToFill: expandToFill,
      ),
    );
  }
}

/// Content widget for the Kennel Location tab.
///
/// Displays form fields for kennel location including:
/// - City, Region/State, Country (read-only)
/// - Latitude and Longitude coordinates
class KennelLocationTabContent extends StatelessWidget {
  const KennelLocationTabContent({required this.controller, super.key});

  final KennelPageFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isMobileScreen =
          controller.screenSize.value == EScreenSize.isMobileScreen;

      return Lockable(
        lockState: controller.tabLocked[KennelTabType.kennelLocation.index],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Location Details Section (Read-only)
            HelperWidgets().categoryLabelWidget(
              'Kennel City, State / Region, Country (Read-Only)',
            ),
            RowColumn(
              isRow: !isMobileScreen,
              rowFlexValues: const [1, 1, 1],
              rowLeftPaddingValues: const [0.0, 20.0, 20.0],
              children: [
                _buildTextField(KennelLocationField.cityName),
                _buildTextField(KennelLocationField.regionName),
                _buildTextField(KennelLocationField.countryName),
              ],
            ),

            HelperWidgets().categoryLabelWidget(
              'Kennel Coordinates',
            ),

            // Coordinates Section
            RowColumn(
              isRow: !isMobileScreen,
              rowFlexValues: const [1, 1],
              rowLeftPaddingValues: const [0.0, 20.0],
              children: [
                _buildTextField(KennelLocationField.defaultLatitude),
                _buildTextField(KennelLocationField.defaultLongitude),
              ],
            ),

            HelperWidgets().categoryLabelWidget(
              'Units of Measure',
            ),

            // Distance Preference Dropdown
            Align(
              alignment: Alignment.centerLeft,
              child: _buildDistancePreferenceDropdown(isMobileScreen),
            ),

            HelperWidgets().categoryLabelWidget(
              'Kennel Pin Color',
            ),

            // Kennel Pin Color Dropdown
            Align(
              alignment: Alignment.centerLeft,
              child: _buildKennelPinColorDropdown(isMobileScreen),
            ),
          ],
        ),
      );
    });
  }

  /// Builds the distance preference dropdown.
  Widget _buildDistancePreferenceDropdown(bool isMobileScreen) {
    final controlKey =
        '${KennelTabType.kennelLocation.key}_${KennelLocationField.distancePreference.name}';
    final uiControl = controller.uiControls[controlKey];

    if (uiControl == null) return const SizedBox.shrink();

    return EditableDropdownField<KennelPageFormController>(
      controller: controller,
      uiControl: uiControl,
      value: controller.distancePreference,
      width: isMobileScreen ? double.infinity : 300,
      items: const {
        -1: 'Default for country',
        0: 'Kilometers',
        1: 'Miles',
      },
    );
  }

  /// Builds the kennel pin color dropdown with image icons.
  Widget _buildKennelPinColorDropdown(bool isMobileScreen) {
    final controlKey =
        '${KennelTabType.kennelLocation.key}_${KennelLocationField.kennelPinColor.name}';
    final uiControl = controller.uiControls[controlKey];

    if (uiControl == null) return const SizedBox.shrink();

    return EditableImageDropdownField<KennelPageFormController>(
      controller: controller,
      uiControl: uiControl,
      value: controller.kennelPinColor,
      width: isMobileScreen ? double.infinity : 300,
    );
  }

  /// Builds an editable text field for the given field type.
  Widget _buildTextField(KennelLocationField field) {
    final controlKey = '${KennelTabType.kennelLocation.key}_${field.name}';
    final uiControl = controller.uiControls[controlKey];

    if (uiControl == null) return const SizedBox.shrink();

    return EditableOverrideTextField(
      controller: controller,
      uiControl: uiControl,
      onChanged: (_) => controller.checkIfFormIsDirty(),
    );
  }
}
