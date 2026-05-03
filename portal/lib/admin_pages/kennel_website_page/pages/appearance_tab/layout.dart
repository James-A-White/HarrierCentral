part of '../../kennel_website_page_ui.dart';

class _AppearanceTabContent extends StatelessWidget {
  const _AppearanceTabContent({required this.controller});

  final KennelWebsiteController controller;

  @override
  Widget build(BuildContext context) {
    final tabKey = KennelWebsiteTabType.appearance.key;

    UiControlDefinition? ctrl(KennelWebsiteAppearanceField f) =>
        controller.uiControls['${tabKey}_${f.name}'];

    final themeCtrl = ctrl(KennelWebsiteAppearanceField.themeMode);
    final primaryCtrl = ctrl(KennelWebsiteAppearanceField.primaryColor);
    final accentCtrl = ctrl(KennelWebsiteAppearanceField.accentColor);
    final menuBgCtrl = ctrl(KennelWebsiteAppearanceField.menuBackgroundColor);
    final menuTextCtrl = ctrl(KennelWebsiteAppearanceField.menuTextColor);
    final blurCtrl = ctrl(KennelWebsiteAppearanceField.scrollBlur);
    final titleColorCtrl = ctrl(KennelWebsiteAppearanceField.titleTextColor);
    final bodyColorCtrl = ctrl(KennelWebsiteAppearanceField.bodyTextColor);
    final mutedColorCtrl = ctrl(KennelWebsiteAppearanceField.textMutedColor);
    final cardBgCtrl = ctrl(KennelWebsiteAppearanceField.cardBackgroundColor);
    final btnPrimaryCtrl = ctrl(KennelWebsiteAppearanceField.buttonPrimaryColor);
    final btnCancelCtrl = ctrl(KennelWebsiteAppearanceField.buttonCancelColor);
    final btnSecondaryCtrl =
        ctrl(KennelWebsiteAppearanceField.buttonSecondaryColor);
    final runCardColorCtrl = ctrl(KennelWebsiteAppearanceField.runCardColor);

    if (themeCtrl == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HelperWidgets().categoryLabelWidget('Theme'),
        const SizedBox(height: 12),
        EditableDropdownField(
          controller: controller,
          uiControl: themeCtrl,
          value: controller.themeModeIndex,
          items: KennelWebsiteController.themeModeItems,
        ),
        const SizedBox(height: 32),
        HelperWidgets().categoryLabelWidget('Brand Colours'),
        const SizedBox(height: 12),
        if (primaryCtrl != null)
          EditableColorField(
            controller: controller,
            uiControl: primaryCtrl,
            onChanged: (_) => controller.checkIfFormIsDirty(),
          ),
        const SizedBox(height: 16),
        if (accentCtrl != null)
          EditableColorField(
            controller: controller,
            uiControl: accentCtrl,
            onChanged: (_) => controller.checkIfFormIsDirty(),
          ),
        const SizedBox(height: 32),
        HelperWidgets().categoryLabelWidget('Navigation'),
        const SizedBox(height: 12),
        if (menuBgCtrl != null)
          EditableColorField(
            controller: controller,
            uiControl: menuBgCtrl,
            enableAlpha: true,
            onChanged: (_) => controller.checkIfFormIsDirty(),
          ),
        const SizedBox(height: 16),
        if (menuTextCtrl != null)
          EditableColorField(
            controller: controller,
            uiControl: menuTextCtrl,
            onChanged: (_) => controller.checkIfFormIsDirty(),
          ),
        const SizedBox(height: 32),
        HelperWidgets().categoryLabelWidget('Scroll Effect'),
        const SizedBox(height: 12),
        if (blurCtrl != null)
          EditableOverrideTextField(
            controller: controller,
            uiControl: blurCtrl,
            onChanged: (_) => controller.checkIfFormIsDirty(),
          ),
        const SizedBox(height: 32),
        HelperWidgets().categoryLabelWidget('Text Colours'),
        const SizedBox(height: 12),
        if (titleColorCtrl != null)
          EditableColorField(
            controller: controller,
            uiControl: titleColorCtrl,
            onChanged: (_) => controller.checkIfFormIsDirty(),
          ),
        const SizedBox(height: 16),
        if (bodyColorCtrl != null)
          EditableColorField(
            controller: controller,
            uiControl: bodyColorCtrl,
            onChanged: (_) => controller.checkIfFormIsDirty(),
          ),
        const SizedBox(height: 16),
        if (mutedColorCtrl != null)
          EditableColorField(
            controller: controller,
            uiControl: mutedColorCtrl,
            enableAlpha: true,
            onChanged: (_) => controller.checkIfFormIsDirty(),
          ),
        const SizedBox(height: 32),
        HelperWidgets().categoryLabelWidget('Surfaces'),
        const SizedBox(height: 12),
        if (cardBgCtrl != null)
          EditableColorField(
            controller: controller,
            uiControl: cardBgCtrl,
            enableAlpha: true,
            onChanged: (_) => controller.checkIfFormIsDirty(),
          ),
        const SizedBox(height: 16),
        if (btnPrimaryCtrl != null)
          EditableColorField(
            controller: controller,
            uiControl: btnPrimaryCtrl,
            enableAlpha: true,
            onChanged: (_) => controller.checkIfFormIsDirty(),
          ),
        const SizedBox(height: 16),
        if (btnCancelCtrl != null)
          EditableColorField(
            controller: controller,
            uiControl: btnCancelCtrl,
            enableAlpha: true,
            onChanged: (_) => controller.checkIfFormIsDirty(),
          ),
        const SizedBox(height: 16),
        if (btnSecondaryCtrl != null)
          EditableColorField(
            controller: controller,
            uiControl: btnSecondaryCtrl,
            enableAlpha: true,
            onChanged: (_) => controller.checkIfFormIsDirty(),
          ),
        const SizedBox(height: 16),
        if (runCardColorCtrl != null)
          EditableColorField(
            controller: controller,
            uiControl: runCardColorCtrl,
            enableAlpha: true,
            onChanged: (_) => controller.checkIfFormIsDirty(),
          ),
      ],
    );
  }
}
