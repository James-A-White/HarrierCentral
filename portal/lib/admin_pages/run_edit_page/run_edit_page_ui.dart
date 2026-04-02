/// Run Edit Page UI
///
/// This file contains the main UI for editing run information.
/// Uses GetX for state management with the [GetView] pattern for cleaner code.
///
/// Structure:
/// - [RunEditPage] - Main page widget (GetView-based)
/// - Tab content widgets for each section

import 'package:intl/intl.dart';
import 'package:hcportal/imports.dart';
import 'package:hcportal/admin_pages/kennel_page_new/kennel_page_new_enums.dart';
import 'package:latlng/latlng.dart';
import 'package:map/map.dart' as geo_map;
import 'run_edit_page_enums.dart';
import 'run_edit_page_controller.dart';

part 'pages/run_basic_info_page/layout.dart';
part 'pages/run_location_page/layout.dart';
part 'pages/run_image_page/layout.dart';
part 'pages/run_misc_page/layout.dart';
part 'pages/run_tags_page/layout.dart';
part 'pages/run_other_page/layout.dart';
part 'pages/run_payment_page/layout.dart';

// ---------------------------------------------------------------------------
// Run Edit Page
// ---------------------------------------------------------------------------

/// Main page for editing run information.
///
/// This page uses [GetView] with [RunEditPageController] for state management,
/// eliminating the need for a StatefulWidget.
class RunEditPage extends GetView<RunEditPageController> {
  const RunEditPage({
    required this.runData,
    required this.kennelData,
    this.isAddMode = false,
    this.lastRunDate,
    super.key,
  });

  /// Initial run data to populate the form.
  final RunDetailsModel runData;

  /// Kennel data for context.
  final HasherKennelsModel kennelData;

  /// Whether we are adding a new run (vs editing existing).
  final bool isAddMode;

  /// The date of the last existing run, used to calculate the next run date.
  final DateTime? lastRunDate;

  @override
  Widget build(BuildContext context) {
    _ensureControllerInitialized();

    return GetBuilder<RunEditPageController>(
      id: 'runFormPageBuilder',
      builder: (_) => _RunFormScaffold(controller: controller),
    );
  }

  /// Ensures the controller is registered before building.
  /// Only creates the controller if it isn't already registered — preserving
  /// state (e.g. isAddMode → false after first save) across widget rebuilds.
  /// GetX disposes the controller automatically when the route is popped,
  /// so a fresh instance is still created on each new navigation to this page.
  void _ensureControllerInitialized() {
    if (!Get.isRegistered<RunEditPageController>()) {
      Get.put(
        RunEditPageController(
          initialData: runData,
          kennelData: kennelData,
          isAddMode: isAddMode,
          lastRunDate: lastRunDate,
        ),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Scaffold Widget
// ---------------------------------------------------------------------------

/// Main scaffold containing the app bar and tab structure.
class _RunFormScaffold extends StatelessWidget {
  const _RunFormScaffold({required this.controller});

  final RunEditPageController controller;

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
      title: _RunTitle(controller: controller),
      actions: [_AutoSaveControls(controller: controller)],
    );
  }

  /// Builds the main body with tab bar and tab views.
  Widget _buildBody() {
    return DefaultTabController(
      length: RunTabType.values.length,
      child: Column(
        children: [
          _RunTabBar(controller: controller),
          Expanded(child: _RunTabBarView(controller: controller)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// App Bar Components
// ---------------------------------------------------------------------------

/// Back navigation button.
class _BackButton extends GetView<RunEditPageController> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => controller.close(),
      child: const Icon(
        MaterialCommunityIcons.arrow_left,
        color: Colors.black,
      ),
    );
  }
}

/// Page title showing the run name being edited.
class _RunTitle extends StatelessWidget {
  const _RunTitle({required this.controller});

  final RunEditPageController controller;

  @override
  Widget build(BuildContext context) {
    // Note: Not using Obx here because isAddMode is a fixed bool (not reactive)
    // and accessing editedData.value only when !isAddMode would cause GetX error
    // in add mode (no observable variables accessed).
    return Text(
      controller.isAddMode
          ? 'Add Run to ${controller.kennelData.kennelName}'
          : 'Editing ${controller.editedData.value.eventName}',
      style: headingStyleBlack,
    );
  }
}

/// Auto-save toggle and progress indicator.
class _AutoSaveControls extends StatelessWidget {
  const _AutoSaveControls({required this.controller});

  final RunEditPageController controller;

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

/// Tab bar with styled tabs for each run section.
class _RunTabBar extends StatelessWidget {
  const _RunTabBar({required this.controller});

  final RunEditPageController controller;

  @override
  Widget build(BuildContext context) {
    return ResponsiveTabBar<RunEditPageController>(
      controller: controller,
      formKey: controller.formKey,
      tabBarColor: Colors.blue.shade600,
    );
  }
}

/// Tab bar view containing all tab content pages.
class _RunTabBarView extends StatelessWidget {
  const _RunTabBarView({required this.controller});

  final RunEditPageController controller;

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: controller.tabController,
      // Disable swipe gestures so they don't interfere with map panning
      physics: const NeverScrollableScrollPhysics(),
      children: _buildTabBodies(),
    );
  }

  /// Generates tab body widgets wrapped in standard layout.
  List<Widget> _buildTabBodies() {
    return RunTabType.values.map((tab) {
      final isLocationTab = tab == RunTabType.location;
      final isBasicInfoTab = tab == RunTabType.basicInfo;
      // Tabs that manage their own scrolling get finite height constraints
      final handlesOwnScrolling = isLocationTab || isBasicInfoTab;
      return TabPageStandardLayout(
        title: tab.title,
        icon: tab.icon,
        description: tab.description,
        formController: controller,
        showCloseTabGroupButton: false,
        tabLocked: controller.tabLocked[tab.index],
        handlesOwnScrolling: handlesOwnScrolling,
        // Location tab has no left/right padding so map goes edge-to-edge
        contentPadding:
            isLocationTab ? const EdgeInsets.only(bottom: 16, top: 0) : null,
        // Location tab has no divider right padding for edge-to-edge map
        dividerRightPadding: isLocationTab ? 0.0 : 20.0,
        child: _buildTabContent(tab),
      );
    }).toList();
  }

  /// Returns the appropriate content widget for each tab.
  Widget _buildTabContent(RunTabType tab) {
    switch (tab) {
      case RunTabType.basicInfo:
        return RunBasicInfoTabContent(controller: controller);
      case RunTabType.location:
        return RunLocationTabContent(controller: controller);
      case RunTabType.image:
        return RunImageTabContent(controller: controller);
      case RunTabType.misc:
        return RunMiscTabContent(controller: controller);
      case RunTabType.runTags:
        return RunTagsTabContent(controller: controller);
      case RunTabType.other:
        return RunOtherTabContent(controller: controller);
      case RunTabType.payment:
        return RunPaymentTabContent(controller: controller);
    }
  }
}

// ---------------------------------------------------------------------------
// Tab Content Widgets
// ---------------------------------------------------------------------------

/// Content widget for the Basic Info tab.
class RunBasicInfoTabContent extends StatelessWidget {
  const RunBasicInfoTabContent({required this.controller, super.key});

  final RunEditPageController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isMobileScreen =
          controller.screenSize.value == EScreenSize.isMobileScreen;

      // Get the run description control to check expandToFillSpace
      final descControlKey =
          '${RunTabType.basicInfo.key}_${RunBasicInfoField.runDescription.name}';
      final descControl = controller.uiControls[descControlKey];
      final shouldExpand = descControl?.expandToFillSpace ?? false;
      final minHeight = descControl?.minHeight ?? 150.0;

      // The non-expanding widgets that go above the description
      final topWidgets = <Widget>[
        // Integration source selector (if applicable)
        if (controller.inboundIntegrationId.value != 0) ...[
          _buildIntegrationSelector(),
          const SizedBox(height: 16),
        ],

        // Basic Information Section
        HelperWidgets().categoryLabelWidget('Basic Run Information'),

        RowColumn(
          isRow: !isMobileScreen,
          rowFlexValues: const [3, 1],
          rowLeftPaddingValues: const [0.0, 20.0],
          children: [
            _buildTextField(RunBasicInfoField.runName),
            _buildDateTimeField(RunBasicInfoField.runStartDate),
          ],
        ),

        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: _buildTextField(RunBasicInfoField.placeDescription)),
            const SizedBox(width: 12),
            _buildLookupButton(),
          ],
        ),

        const SizedBox(height: 16),
      ];

      if (shouldExpand) {
        // Column fills height from Expanded parent; description
        // takes all remaining space but never shrinks below minHeight.
        // If content is too tall, the CustomScrollView lets it scroll.
        return CustomScrollView(
          slivers: [
            // Fixed-height top widgets
            SliverToBoxAdapter(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: topWidgets,
              ),
            ),
            // The description fills remaining space (or minHeight, whichever is larger)
            SliverFillRemaining(
              hasScrollBody: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: _buildTextField(RunBasicInfoField.runDescription,
                    maxLines: null),
              ),
            ),
          ],
        );
      } else {
        // Fallback: plain scrollable column with fixed-size description
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...topWidgets,
              _buildTextField(RunBasicInfoField.runDescription, maxLines: 10),
            ],
          ),
        );
      }
    });
  }

  Widget _buildIntegrationSelector() {
    return Obx(() => Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Source',
                  style: titleStyleBlack,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: controller.useExtRunDetails.value,
                      onChanged: (value) {
                        controller.useExtRunDetails.value = value ?? false;
                        controller.checkIfFormIsDirty();
                      },
                    ),
                    Expanded(
                      child: Text(
                        'Use data from ${INBOUND_DATA_SOURCES[controller.inboundIntegrationId.value]} (read-only)',
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Radio<bool>(
                      value: false,
                      groupValue: controller.useExtRunDetails.value,
                      onChanged: (value) {
                        controller.useExtRunDetails.value = value ?? false;
                        controller.checkIfFormIsDirty();
                      },
                    ),
                    const Expanded(
                      child: Text('Use Harrier Central data (editable)'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
  }

  /// Builds the "Lookup" button that opens the location lookup dialog.
  Widget _buildLookupButton() {
    final uiControl = controller.uiControls[basicInfoLookupButtonKey];
    if (uiControl == null) return const SizedBox.shrink();

    return SidebarHoverRegion(
      controller: controller,
      uiControl: uiControl,
      child: Obx(() => ElevatedButton.icon(
            icon: controller.isLookupLoading.value
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.search, size: 18),
            label: Text(
              controller.isLookupLoading.value ? 'Loading…' : 'Lookup',
              style: textStyleButton,
            ),
            style: defaultButtonStyle,
            onPressed: controller.isLookupLoading.value
                ? null
                : controller.openLocationLookupDialog,
          )),
    );
  }

  Widget _buildTextField(RunBasicInfoField field, {int? maxLines = 1}) {
    final controlKey = '${RunTabType.basicInfo.key}_${field.name}';
    final uiControl = controller.uiControls[controlKey];

    if (uiControl == null) return const SizedBox.shrink();

    final isDisabled = controller.useExtRunDetails.value &&
        controller.inboundIntegrationId.value != 0;

    // When maxLines is null, the field should expand to fill available space
    final shouldExpand = maxLines == null;

    if (isDisabled) {
      // Show read-only field when using external data
      return TextFormField(
        controller: uiControl.textController,
        readOnly: true,
        maxLines: shouldExpand ? null : maxLines,
        expands: shouldExpand,
        textAlignVertical: shouldExpand ? TextAlignVertical.top : null,
        style: bodyStyleBlack.copyWith(color: Colors.grey.shade600),
        decoration: InputDecoration(
          labelText: uiControl.label,
          fillColor: Colors.grey.shade200,
          filled: true,
          alignLabelWithHint: shouldExpand,
          border: shouldExpand ? const OutlineInputBorder() : null,
        ),
      );
    }

    return EditableOverrideTextField(
      controller: controller,
      uiControl: uiControl,
      onChanged: (_) => controller.checkIfFormIsDirty(),
      expandToFill: shouldExpand,
    );
  }

  Widget _buildDateTimeField(RunBasicInfoField field) {
    final controlKey = '${RunTabType.basicInfo.key}_${field.name}';
    final uiControl = controller.uiControls[controlKey];

    if (uiControl == null) return const SizedBox.shrink();

    final isDisabled = controller.useExtRunDetails.value &&
        controller.inboundIntegrationId.value != 0;

    return Obx(() => FormBuilderDateTimePicker(
          name: controlKey,
          enabled: !isDisabled,
          decoration: InputDecoration(
            labelText: uiControl.label,
            fillColor:
                isDisabled ? Colors.grey.shade200 : Colors.yellow.shade100,
            filled: true,
          ),
          initialValue: controller.editedData.value.eventStartDatetime,
          format: DateFormat('EEE, M/d/y h:mm a'),
          onChanged: (value) {
            if (value != null) {
              uiControl.updateEditedValue(value);
              controller.checkIfFormIsDirty();
            }
          },
        ));
  }
}

// RunLocationTabContent is defined in pages/run_location_page/layout.dart

/// Content widget for the Image tab.
class RunImageTabContent extends StatelessWidget {
  const RunImageTabContent({required this.controller, super.key});

  final RunEditPageController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Integration source selector (if applicable)
          if (controller.inboundIntegrationId.value != 0) ...[
            _buildIntegrationSelector(),
            const SizedBox(height: 16),
          ],

          // Image display - centered
          if (!controller.useExtImage.value) ...[
            HelperWidgets().categoryLabelWidget('Event Image'),
            const SizedBox(height: 16),
            Center(child: _buildImageSection(context)),
          ] else ...[
            HelperWidgets().categoryLabelWidget('External Image'),
            const SizedBox(height: 16),
            Center(
              child: ReadOnlyImagePreview(
                imageUrl: controller.originalData.extEventImage,
                emptyMessage: 'No external image available',
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildIntegrationSelector() {
    final sourceName =
        INBOUND_DATA_SOURCES[controller.inboundIntegrationId.value];
    return IntegrationSourceSelector(
      title: 'Image Source',
      useExternalSource: controller.useExtImage,
      externalSourceName: sourceName,
      externalLabel: 'Use image from $sourceName',
      localLabel: 'Use Harrier Central image',
      onChanged: () => controller.checkIfFormIsDirty(),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    final controlKey =
        '${RunTabType.image.key}_${RunImageField.eventImage.name}';
    final uiControl = controller.uiControls[controlKey];

    if (uiControl == null) return const SizedBox.shrink();

    // Initialize uploading state for this field if not already present
    controller.uploadingState[controlKey] ??= false.obs;
    controller.uploadStatusState[controlKey] ??= ''.obs;

    // Calculate size based on available screen space
    // Reserve space for: header (~60), tabs (~50), label (~40),
    // remove button (~80), bottom nav (~80), padding (~90)
    final screenSize = MediaQuery.of(context).size;
    final availableHeight = screenSize.height - 400;
    final availableWidth = screenSize.width - 100; // Side padding

    // Use available dimensions directly - let the image fill the space
    // while BoxFit.contain maintains aspect ratio
    final imageHeight = availableHeight.clamp(150.0, 800.0);
    final imageWidth = availableWidth.clamp(150.0, 1200.0);

    return DocumentManagerField(
      controller: controller,
      uiControl: uiControl,
      fieldName: controlKey,
      recordId: controller.originalData.publicEventId ?? 'new_event',
      uploading: controller.uploadingState[controlKey]!,
      uploadStatus: controller.uploadStatusState[controlKey],
      height: imageHeight,
      width: imageWidth,
      expandToFit: true,
      placeholderText: 'No image\n\nClick to upload',
      filenamePrefix: 'eventImage_',
      onUploadComplete: (String fileName) {
        final fullUrl = BASE_EVENT_IMAGE_URL + fileName;
        uiControl.editedFieldValue = fullUrl;
        controller.editedData.value = controller.editedData.value.copyWith(
          eventImage: fullUrl,
        );
        controller.uploadedImage.value = fullUrl;
        controller.checkIfFormIsDirty();
      },
      onRemoveDocument: () {
        final originalImage = controller.originalData.eventImage;

        // Determine what value to set based on original state:
        // - If original was null (no image in DB): set to null (no API change needed)
        // - If original had a URL (image in DB): set to '<null>' sentinel to tell API to delete it
        final valueToSet =
            (originalImage == null || originalImage.isEmpty) ? null : '<null>';

        uiControl.editedFieldValue = valueToSet;
        controller.editedData.value = controller.editedData.value.copyWith(
          eventImage: valueToSet,
        );
        controller.uploadedImage.value = valueToSet;
      },
      onAfterRemove: () => controller.checkIfFormIsDirty(),
    );
  }
}

/// Content widget for the Misc tab.
class RunMiscTabContent extends StatelessWidget {
  const RunMiscTabContent({required this.controller, super.key});

  final RunEditPageController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isMobileScreen =
          controller.screenSize.value == EScreenSize.isMobileScreen;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visibility Options
          HelperWidgets().categoryLabelWidget('Visibility & Status'),
          RowColumn(
            isRow: !isMobileScreen,
            rowFlexValues: const [1, 1, 1],
            rowLeftPaddingValues: const [0.0, 20.0, 20.0],
            children: [
              _buildCheckbox(RunMiscField.isVisible, 'Is visible'),
              _buildCheckbox(RunMiscField.isCounted, 'Is counted run'),
              _buildCheckbox(RunMiscField.isPromoted, 'Is promoted event'),
            ],
          ),

          // Run Number Section
          HelperWidgets().categoryLabelWidget('Run Number'),
          _buildRunNumberField(),

          // Hares Section
          HelperWidgets().categoryLabelWidget('Hares'),
          _buildTextField(RunMiscField.hares),

          // Publishing Section
          HelperWidgets().categoryLabelWidget('Publishing'),
          _buildPublishingDropdown(
            RunMiscField.publishOnHashruns,
            controller.publishOnHashruns,
          ),
          const SizedBox(height: 10),
          _buildPublishingDropdown(
            RunMiscField.runAudience,
            controller.runAudience,
          ),
          const SizedBox(height: 10),
          _buildPublishingDropdown(
            RunMiscField.allowWebLink,
            controller.allowWebLink,
          ),

          // Attendance Section
          HelperWidgets().categoryLabelWidget('Attendance'),
          _buildPublishingDropdown(
            RunMiscField.runAttendance,
            controller.runAttendance,
          ),
        ],
      );
    });
  }

  Widget _buildPublishingDropdown(RunMiscField field, RxInt value) {
    final controlKey = '${RunTabType.misc.key}_${field.name}';
    final uiControl = controller.uiControls[controlKey];

    if (uiControl == null) return const SizedBox.shrink();

    return SizedBox(
      width: 620,
      child: EditableDropdownField(
        controller: controller,
        uiControl: uiControl,
        value: value,
        items: uiControl.dropdownItems ?? {},
      ),
    );
  }

  Widget _buildCheckbox(RunMiscField field, String label) {
    final controlKey = '${RunTabType.misc.key}_${field.name}';
    final uiControl = controller.uiControls[controlKey];

    if (uiControl == null) return const SizedBox.shrink();

    return Obx(() {
      bool value = false;
      if (field == RunMiscField.isVisible) {
        value = controller.editedData.value.isVisible != 0;
      } else if (field == RunMiscField.isCounted) {
        value = controller.editedData.value.isCountedRun != 0;
      } else if (field == RunMiscField.isPromoted) {
        value = controller.editedData.value.isPromotedEvent != 0;
      } else if (field == RunMiscField.autoNumber) {
        value = controller.autoNumberRuns.value;
      }

      return SidebarHoverRegion(
        controller: controller,
        uiControl: uiControl,
        child: InkWell(
          onTap: () {
            uiControl.updateEditedValue(!value);
            controller.checkIfFormIsDirty();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Transform.scale(
                  scale: 1.3,
                  child: Checkbox(
                    value: value,
                    onChanged: (newValue) {
                      uiControl.updateEditedValue(newValue);
                      controller.checkIfFormIsDirty();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label, style: bodyStyleBlack),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTextField(RunMiscField field, {bool enabled = true}) {
    final controlKey = '${RunTabType.misc.key}_${field.name}';
    final uiControl = controller.uiControls[controlKey];

    if (uiControl == null) return const SizedBox.shrink();

    if (!enabled) {
      // Show read-only field when disabled
      return TextFormField(
        controller: uiControl.textController,
        readOnly: true,
        style: bodyStyleBlack.copyWith(color: Colors.grey.shade600),
        decoration: InputDecoration(
          labelText: uiControl.label,
          fillColor: Colors.grey.shade200,
          filled: true,
        ),
      );
    }

    return EditableOverrideTextField(
      controller: controller,
      uiControl: uiControl,
      onChanged: (_) => controller.checkIfFormIsDirty(),
    );
  }

  /// Builds the run number field with override functionality.
  ///
  /// This field uses the modern EditableOverrideTextField pattern:
  /// - Pencil icon to enable manual entry
  /// - Checkbox to use auto-generated number
  Widget _buildRunNumberField() {
    final controlKey =
        '${RunTabType.misc.key}_${RunMiscField.absoluteRunNumber.name}';
    final uiControl = controller.uiControls[controlKey];

    if (uiControl == null) return const SizedBox.shrink();

    return EditableOverrideTextField(
      controller: controller,
      uiControl: uiControl,
      onChanged: (_) => controller.checkIfFormIsDirty(),
    );
  }
}

/// Content widget for the Run Tags tab.
///
/// Displays selectable filter chips organized by [RunTagGroup] categories.
/// Each chip represents a [RunTag] that can be toggled on/off.
///
/// Features:
/// - Chips organized by group (Theme, Restrictions, etc.)
/// - Sidebar help integration on hover
/// - Visual feedback for selected state
/// - Reactive updates using GetX
class RunTagsTabContent extends StatelessWidget {
  const RunTagsTabContent({required this.controller, super.key});

  final RunEditPageController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      primary: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildGroupSections(),
      ),
    );
  }

  /// Builds all tag group sections.
  List<Widget> _buildGroupSections() {
    final widgets = <Widget>[];

    for (final group in RunTagGroup.values) {
      widgets
        ..add(_buildGroupLabel(group.label))
        ..add(_buildChipsWrap(group))
        ..add(const SizedBox(height: 16));
    }

    // Add bottom padding
    widgets.add(const SizedBox(height: 20));

    return widgets;
  }

  /// Builds a group label widget using the standard orange category style.
  Widget _buildGroupLabel(String label) {
    return HelperWidgets().categoryLabelWidget(label, bottomMargin: 10);
  }

  /// Builds a wrap of chips for the given group.
  Widget _buildChipsWrap(RunTagGroup group) {
    final tagsInGroup =
        RunTag.values.where((tag) => tag.parentKey == group.groupKey).toList();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: tagsInGroup.map((tag) => _buildTagChip(tag, group)).toList(),
    );
  }

  /// Builds an individual tag chip.
  Widget _buildTagChip(RunTag tag, RunTagGroup group) {
    return MouseRegion(
      onEnter: (_) => _showSidebarHelp(tag, group),
      onExit: (_) => _hideSidebarHelp(),
      child: Obx(() => _buildFilterChip(tag)),
    );
  }

  /// Shows contextual help in the sidebar.
  void _showSidebarHelp(RunTag tag, RunTagGroup group) {
    controller.setSidebarData(
      '',
      title: '${group.label}: ${tag.title}',
      shortDescription: tag.description,
      icon: tag.icon,
    );
  }

  /// Hides the sidebar help.
  void _hideSidebarHelp() {
    controller.setSidebarData('${RunTabType.runTags.key}_generic');
  }

  /// Builds a custom tag button matching the design mockup.
  ///
  /// Design:
  /// - Unselected: Grey border, white background, icon in green-bordered circle
  /// - Selected: Green border, light green background, checkmark + icon circle
  /// - Text wraps 1-3 lines, all buttons same height
  Widget _buildFilterChip(RunTag tag) {
    final isSelected = controller.runTagSelectionStatus[tag.key]?.value == 1;

    return GestureDetector(
      onTap: () {
        controller.updateRunTags(
          isSelected: !isSelected,
          tagKey: tag.key,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green.shade600 : Colors.grey.shade400,
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Checkmark (only when selected)
            if (isSelected) ...[
              Icon(
                Icons.check,
                size: 24,
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 8),
            ],
            // Icon in circle - fixed size container with centered icon
            SizedBox(
              width: 44,
              height: 44,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.green.shade600,
                    width: 2,
                  ),
                ),
                child: Icon(
                  tag.icon,
                  size: 22,
                  color: _getIconColor(tag),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Text label (1-3 lines)
            Text(
              tag.title,
              style: TextStyle(
                fontFamily: 'AvenirNextBold',
                fontSize: 15,
                height: 1.2,
                color:
                    isSelected ? Colors.green.shade800 : Colors.grey.shade700,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Returns an appropriate color for the tag icon.
  ///
  /// Uses the tag's inherent color where applicable (e.g., red for Red Dress),
  /// otherwise returns a default icon color.
  Color _getIconColor(RunTag tag) {
    // Map specific tags to their thematic colors
    return switch (tag) {
      RunTag.redDress => Colors.red,
      RunTag.fullMoon => Colors.amber.shade600,
      RunTag.familyHash => Colors.blue.shade600,
      RunTag.normalRun => Colors.green.shade600,
      RunTag.harriette => Colors.pink.shade400,
      RunTag.agm => Colors.purple.shade600,
      RunTag.drinkingPractice => Colors.orange.shade700,
      RunTag.hangoverRun => Colors.brown.shade400,
      RunTag.menOnly => Colors.blue.shade700,
      RunTag.womenOnly => Colors.pink.shade600,
      RunTag.kidsAllowed => Colors.lightBlue.shade400,
      RunTag.noKidsAllowed => Colors.red.shade400,
      RunTag.dogFriendly => Colors.brown.shade600,
      RunTag.noDogsAllowed => Colors.red.shade400,
      RunTag.bringFlashlight => Colors.amber.shade600,
      RunTag.waterOnTrail => Colors.blue.shade500,
      RunTag.swimStop => Colors.cyan.shade500,
      RunTag.nightRun => Colors.indigo.shade600,
      RunTag.shiggyRun => Colors.brown.shade500,
      RunTag.cityHash => Colors.blueGrey.shade600,
      RunTag.steepHills => Colors.green.shade700,
      RunTag.bikeHash => Colors.orange.shade600,
      RunTag.charityEvent => Colors.red.shade600,
      RunTag.campingHash => Colors.green.shade800,
      _ => Colors.grey.shade700,
    };
  }
}

/// Content widget for the Other tab.
class RunOtherTabContent extends StatelessWidget {
  const RunOtherTabContent({required this.controller, super.key});

  final RunEditPageController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isMobileScreen =
          controller.screenSize.value == EScreenSize.isMobileScreen;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // End Time Section
          HelperWidgets().categoryLabelWidget('Run End Time'),
          _buildDateTimeField(RunOtherField.runEndDate),

          // Participation Section
          HelperWidgets().categoryLabelWidget('Participation'),
          _buildCheckbox(
              RunOtherField.limitParticipation, 'Limit participation'),

          if (controller.limitParticipation.value) ...[
            const SizedBox(height: 12),
            RowColumn(
              isRow: !isMobileScreen,
              rowFlexValues: const [1, 1],
              rowLeftPaddingValues: const [0.0, 20.0],
              children: [
                _buildTextField(RunOtherField.minimumParticipation),
                _buildTextField(RunOtherField.maximumParticipation),
              ],
            ),
          ],

          // Country Section
          HelperWidgets().categoryLabelWidget('Country (for statistics)'),
          _buildCountryDropdown(),

          // Integration Section (if applicable)
          if (controller.inboundIntegrationId.value != 0) ...[
            HelperWidgets().categoryLabelWidget('Integration'),
            _buildCheckbox(
              RunOtherField.autoImport,
              'Automatically check ${INBOUND_DATA_SOURCES[controller.inboundIntegrationId.value]} for updates',
            ),
          ],
        ],
      );
    });
  }

  Widget _buildCheckbox(RunOtherField field, String label) {
    final controlKey = '${RunTabType.other.key}_${field.name}';
    final uiControl = controller.uiControls[controlKey];

    if (uiControl == null) return const SizedBox.shrink();

    return Obx(() {
      bool value = false;
      if (field == RunOtherField.limitParticipation) {
        value = controller.limitParticipation.value;
      } else if (field == RunOtherField.autoImport) {
        value = controller.editedData.value.integrationEnabled != 0;
      }

      return SidebarHoverRegion(
        controller: controller,
        uiControl: uiControl,
        child: InkWell(
          onTap: () {
            uiControl.updateEditedValue(!value);
            controller.checkIfFormIsDirty();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Transform.scale(
                  scale: 1.3,
                  child: Checkbox(
                    value: value,
                    onChanged: (newValue) {
                      uiControl.updateEditedValue(newValue);
                      controller.checkIfFormIsDirty();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label, style: bodyStyleBlack),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTextField(RunOtherField field) {
    final controlKey = '${RunTabType.other.key}_${field.name}';
    final uiControl = controller.uiControls[controlKey];

    if (uiControl == null) return const SizedBox.shrink();

    return EditableOverrideTextField(
      controller: controller,
      uiControl: uiControl,
      onChanged: (_) => controller.checkIfFormIsDirty(),
    );
  }

  Widget _buildDateTimeField(RunOtherField field) {
    final controlKey = '${RunTabType.other.key}_${field.name}';
    final uiControl = controller.uiControls[controlKey];

    if (uiControl == null) return const SizedBox.shrink();

    return Obx(() => SizedBox(
          width: 300,
          child: FormBuilderDateTimePicker(
            name: controlKey,
            decoration: InputDecoration(
              labelText: uiControl.label,
              fillColor: Colors.yellow.shade100,
              filled: true,
            ),
            initialValue: controller.editedData.value.eventEndDatetime,
            format: DateFormat('EEE, M/d/y h:mm a'),
            onChanged: (value) {
              uiControl.updateEditedValue(value);
              controller.checkIfFormIsDirty();
            },
          ),
        ));
  }

  Widget _buildCountryDropdown() {
    return Obx(() => SizedBox(
          width: 300,
          child: DropdownButtonFormField<String>(
            value: controller.country.value,
            decoration: InputDecoration(
              labelText: 'Country',
              fillColor: Colors.yellow.shade100,
              filled: true,
            ),
            items: _getCountryItems(),
            onChanged: (value) {
              controller.country.value = value;
              if (value != null) {
                controller.countryId.value = _getCountryIdByName(value);
              }
              controller.checkIfFormIsDirty();
            },
          ),
        ));
  }

  List<DropdownMenuItem<String>> _getCountryItems() {
    final countryList = box.get(HIVE_COUNTRY_LIST);
    if (countryList == null) return [];

    final countryMap = Map<String, String>.from(countryList as Map);
    return countryMap.values
        .map((name) => DropdownMenuItem<String>(
              value: name,
              child: Text(name),
            ))
        .toList();
  }

  String _getCountryIdByName(String countryName) {
    final countryList = box.get(HIVE_COUNTRY_LIST);
    if (countryList == null) return '';

    final countryMap = Map<String, String>.from(countryList as Map);
    return countryMap.entries
        .firstWhere(
          (entry) => entry.value == countryName,
          orElse: () => const MapEntry('', ''),
        )
        .key;
  }
}

/// Content widget for the Payment tab.
class RunPaymentTabContent extends StatelessWidget {
  const RunPaymentTabContent({required this.controller, super.key});

  final RunEditPageController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isMobileScreen =
          controller.screenSize.value == EScreenSize.isMobileScreen;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom Pricing Section
          HelperWidgets().categoryLabelWidget('Payment Options'),
          _buildTextField(RunPaymentField.memberPrice),
          const SizedBox(height: 4),
          _buildTextField(RunPaymentField.nonMemberPrice),

          // Extras Section
          HelperWidgets().categoryLabelWidget('Extra Charges'),
          _buildCheckbox(
            RunPaymentField.useExtrasPrices,
            'This run includes optional extra charges (e.g. dinner, t-shirt)',
          ),

          if (controller.useExtrasPricing.value) ...[
            const SizedBox(height: 12),
            RowColumn(
              isRow: !isMobileScreen,
              rowFlexValues: const [1, 2],
              rowLeftPaddingValues: const [0.0, 20.0],
              children: [
                _buildTextField(RunPaymentField.extrasPrice),
                _buildTextField(RunPaymentField.extrasDescription),
              ],
            ),
            const SizedBox(height: 12),
            _buildCheckbox(
              RunPaymentField.extrasRsvpRequired,
              'Require Hashers to RSVP for extras',
            ),
          ],
        ],
      );
    });
  }

  Widget _buildCheckbox(RunPaymentField field, String label) {
    final controlKey = '${RunTabType.payment.key}_${field.name}';
    final uiControl = controller.uiControls[controlKey];

    if (uiControl == null) return const SizedBox.shrink();

    return Obx(() {
      bool value = false;
      if (field == RunPaymentField.useExtrasPrices) {
        value = controller.useExtrasPricing.value;
      } else if (field == RunPaymentField.extrasRsvpRequired) {
        value = controller.editedData.value.extrasRsvpRequired != 0;
      }

      return SidebarHoverRegion(
        controller: controller,
        uiControl: uiControl,
        child: InkWell(
          onTap: () {
            uiControl.updateEditedValue(!value);
            controller.checkIfFormIsDirty();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Transform.scale(
                  scale: 1.3,
                  child: Checkbox(
                    value: value,
                    onChanged: (newValue) {
                      uiControl.updateEditedValue(newValue);
                      controller.checkIfFormIsDirty();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label, style: bodyStyleBlack),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTextField(RunPaymentField field) {
    final controlKey = '${RunTabType.payment.key}_${field.name}';
    final uiControl = controller.uiControls[controlKey];

    if (uiControl == null) return const SizedBox.shrink();

    return EditableOverrideTextField(
      controller: controller,
      uiControl: uiControl,
      onChanged: (_) => controller.checkIfFormIsDirty(),
    );
  }
}
