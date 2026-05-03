part of '../../kennel_website_page_controller.dart';

extension AppearanceControlsExtension on KennelWebsiteController {
  void initAppearanceControls() {
    final tabKey = KennelWebsiteTabType.appearance.key;
    const tabIndex = 1;

    _registerThemeModeControl(tabKey, tabIndex);
    _registerPrimaryColorControl(tabKey, tabIndex);
    _registerAccentColorControl(tabKey, tabIndex);
    _registerMenuBackgroundColorControl(tabKey, tabIndex);
    _registerMenuTextColorControl(tabKey, tabIndex);
    _registerScrollBlurControl(tabKey, tabIndex);
    _registerTitleTextColorControl(tabKey, tabIndex);
    _registerBodyTextColorControl(tabKey, tabIndex);
    _registerTextMutedColorControl(tabKey, tabIndex);
    _registerCardBackgroundColorControl(tabKey, tabIndex);
  }

  void _registerThemeModeControl(String tabKey, int tabIndex) {
    final fieldKey =
        '${tabKey}_${KennelWebsiteAppearanceField.themeMode.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.dropdown,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Theme Mode',
        FontAwesome5Solid.adjust,
        'Choose whether your website uses a dark or light colour scheme.\n\n'
            'Dark mode is recommended for most kennel websites as it pairs '
            'well with colourful hero images.',
      ),
      dropdownItems: KennelWebsiteController.themeModeItems,
      editedFieldValue: themeModeIndex.value.toString(),
      originalFieldValue:
          (originalData.themeMode == 'light' ? 1 : 0).toString(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Theme mode',
      tabIndex: tabIndex,
      allowEmpty: false,
      onUndo: () {
        themeModeIndex.value = originalData.themeMode == 'light' ? 1 : 0;
      },
      updateEditedValue: (String? value) {
        if (value == null) return;
        final idx = int.tryParse(value) ?? 0;
        themeModeIndex.value = idx;
        final mode = idx == 1 ? 'light' : 'dark';
        editedData.value = editedData.value.copyWith(themeMode: mode);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  void _registerPrimaryColorControl(String tabKey, int tabIndex) {
    final fieldKey =
        '${tabKey}_${KennelWebsiteAppearanceField.primaryColor.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Primary Colour',
        MaterialCommunityIcons.palette,
        'Your kennel\'s primary brand colour as a CSS hex value '
            '(e.g. #FF5733 or #FF5733FF for 8-digit RGBA).\n\n'
            'This colour is injected as --color-primary and used for '
            'buttons, highlights, and other accent elements.',
      ),
      editedFieldValue: editedData.value.primaryColor,
      originalFieldValue: originalData.primaryColor,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Primary colour (CSS hex)',
      maxStringLength: 25,
      minStringLength: 0,
      maxLines: 1,
      allowEmpty: true,
      textController:
          textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value.copyWith(
            primaryColor: value?.isEmpty == true ? null : value);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  void _registerAccentColorControl(String tabKey, int tabIndex) {
    final fieldKey =
        '${tabKey}_${KennelWebsiteAppearanceField.accentColor.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Accent Colour',
        MaterialCommunityIcons.palette_outline,
        'A secondary brand colour for hover states, secondary buttons, '
            'and other supporting elements (CSS hex).\n\n'
            'Falls back to the primary colour if left empty.',
      ),
      editedFieldValue: editedData.value.accentColor,
      originalFieldValue: originalData.accentColor,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Accent colour (CSS hex, optional)',
      maxStringLength: 25,
      minStringLength: 0,
      maxLines: 1,
      allowEmpty: true,
      textController:
          textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value.copyWith(
            accentColor: value?.isEmpty == true ? null : value);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  void _registerScrollBlurControl(String tabKey, int tabIndex) {
    final fieldKey =
        '${tabKey}_${KennelWebsiteAppearanceField.scrollBlur.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Scroll Blur',
        MaterialCommunityIcons.blur,
        'Blur effect intensity applied to the hero image as the user '
            'scrolls down (0–100).\n\n'
            '0 = no blur. 100 = maximum blur (~40px CSS blur). '
            'The blur reaches its maximum when the hero logo fades out.',
      ),
      editedFieldValue: editedData.value.scrollBlur.toString(),
      originalFieldValue: originalData.scrollBlur.toString(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Scroll blur (0–100)',
      maxStringLength: 3,
      minStringLength: 1,
      maxLines: 1,
      allowEmpty: false,
      textController:
          textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        final v = int.tryParse(value ?? '0') ?? 0;
        final clamped = v.clamp(0, 100);
        editedData.value =
            editedData.value.copyWith(scrollBlur: clamped);
        uiControls[fieldKey]?.editedFieldValue = clamped.toString();
      },
    );
  }

  void _registerTitleTextColorControl(String tabKey, int tabIndex) {
    final fieldKey =
        '${tabKey}_${KennelWebsiteAppearanceField.titleTextColor.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Heading Colour',
        MaterialCommunityIcons.format_color_text,
        'Colour for event names, section headings, and other title text '
            '(8-digit hex #RRGGBBAA recommended).\n\n'
            'Leave empty to use the theme default (#FFFFFFFF).',
      ),
      editedFieldValue: editedData.value.titleTextColor,
      originalFieldValue: originalData.titleTextColor,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Heading text colour (optional)',
      maxStringLength: 25,
      minStringLength: 0,
      maxLines: 1,
      allowEmpty: true,
      textController:
          textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value.copyWith(
            titleTextColor: value?.isEmpty == true ? null : value);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  void _registerBodyTextColorControl(String tabKey, int tabIndex) {
    final fieldKey =
        '${tabKey}_${KennelWebsiteAppearanceField.bodyTextColor.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Body Text Colour',
        MaterialCommunityIcons.format_color_text,
        'Colour for body copy and row-value text '
            '(8-digit hex #RRGGBBAA recommended).\n\n'
            'Leave empty to use the theme default (#FFFFFFFF).',
      ),
      editedFieldValue: editedData.value.bodyTextColor,
      originalFieldValue: originalData.bodyTextColor,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Body text colour (optional)',
      maxStringLength: 25,
      minStringLength: 0,
      maxLines: 1,
      allowEmpty: true,
      textController:
          textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value.copyWith(
            bodyTextColor: value?.isEmpty == true ? null : value);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  void _registerMenuBackgroundColorControl(String tabKey, int tabIndex) {
    final fieldKey =
        '${tabKey}_${KennelWebsiteAppearanceField.menuBackgroundColor.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Nav Background Colour',
        MaterialCommunityIcons.navigation,
        'Background colour of the sticky navigation bar '
            '(8-digit hex #RRGGBBAA recommended).\n\n'
            'The alpha byte controls opacity — e.g. #09090BCC gives 80% '
            'opacity. Leave empty to use the theme default.',
      ),
      editedFieldValue: editedData.value.menuBackgroundColor,
      originalFieldValue: originalData.menuBackgroundColor,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Nav background colour (optional)',
      maxStringLength: 25,
      minStringLength: 0,
      maxLines: 1,
      allowEmpty: true,
      textController:
          textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value.copyWith(
            menuBackgroundColor: value?.isEmpty == true ? null : value);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  void _registerMenuTextColorControl(String tabKey, int tabIndex) {
    final fieldKey =
        '${tabKey}_${KennelWebsiteAppearanceField.menuTextColor.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Nav Text Colour',
        MaterialCommunityIcons.format_color_text,
        'Text colour for the sticky navigation bar — kennel name, '
            'nav links, and icons all inherit this colour.\n\n'
            'Leave empty to use the theme default '
            '(white on dark, near-black on light).',
      ),
      editedFieldValue: editedData.value.menuTextColor,
      originalFieldValue: originalData.menuTextColor,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Nav text colour (optional)',
      maxStringLength: 25,
      minStringLength: 0,
      maxLines: 1,
      allowEmpty: true,
      textController:
          textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value.copyWith(
            menuTextColor: value?.isEmpty == true ? null : value);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  void _registerTextMutedColorControl(String tabKey, int tabIndex) {
    final fieldKey =
        '${tabKey}_${KennelWebsiteAppearanceField.textMutedColor.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Muted Text Colour',
        MaterialCommunityIcons.format_color_text,
        'Colour for secondary / label text such as dates, locations, '
            'and other supporting copy '
            '(8-digit hex #RRGGBBAA recommended).\n\n'
            'Leave empty to use the theme default (#FFFFFF80 — 50% white).',
      ),
      editedFieldValue: editedData.value.textMutedColor,
      originalFieldValue: originalData.textMutedColor,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Muted text colour (optional)',
      maxStringLength: 25,
      minStringLength: 0,
      maxLines: 1,
      allowEmpty: true,
      textController:
          textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value.copyWith(
            textMutedColor: value?.isEmpty == true ? null : value);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  void _registerCardBackgroundColorControl(String tabKey, int tabIndex) {
    final fieldKey =
        '${tabKey}_${KennelWebsiteAppearanceField.cardBackgroundColor.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Card Background Colour',
        MaterialCommunityIcons.card_bulleted_outline,
        'Background colour for cards and panel surfaces '
            '(8-digit hex #RRGGBBAA recommended).\n\n'
            'Leave empty to use the theme default (#FFFFFF0A — 4% white).',
      ),
      editedFieldValue: editedData.value.cardBackgroundColor,
      originalFieldValue: originalData.cardBackgroundColor,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Card background colour (optional)',
      maxStringLength: 25,
      minStringLength: 0,
      maxLines: 1,
      allowEmpty: true,
      textController:
          textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value.copyWith(
            cardBackgroundColor: value?.isEmpty == true ? null : value);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }
}
