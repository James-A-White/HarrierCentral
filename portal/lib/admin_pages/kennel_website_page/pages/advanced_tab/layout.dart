part of '../../kennel_website_page_ui.dart';

class _AdvancedTabContent extends StatelessWidget {
  const _AdvancedTabContent({required this.controller});

  final KennelWebsiteController controller;

  @override
  Widget build(BuildContext context) {
    final tabKey = KennelWebsiteTabType.advanced.key;

    UiControlDefinition? ctrl(KennelWebsiteAdvancedField f) =>
        controller.uiControls['${tabKey}_${f.name}'];

    final mismgrDescCtrl =
        ctrl(KennelWebsiteAdvancedField.mismanagementDescription);
    final mismgrJsonCtrl =
        ctrl(KennelWebsiteAdvancedField.mismanagementJson);
    final extraMenusCtrl = ctrl(KennelWebsiteAdvancedField.extraMenusJson);
    final contactCtrl = ctrl(KennelWebsiteAdvancedField.contactDetailsJson);

    if (mismgrDescCtrl == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HelperWidgets().categoryLabelWidget('Mis-management Page'),
        const SizedBox(height: 12),
        EditableOverrideTextField(
          controller: controller,
          uiControl: mismgrDescCtrl,
          onChanged: (_) => controller.checkIfFormIsDirty(),
        ),
        const SizedBox(height: 16),
        if (mismgrJsonCtrl != null)
          EditableOverrideTextField(
            controller: controller,
            uiControl: mismgrJsonCtrl,
            onChanged: (_) => controller.checkIfFormIsDirty(),
          ),
        const SizedBox(height: 32),
        HelperWidgets().categoryLabelWidget('Navigation'),
        const SizedBox(height: 12),
        if (extraMenusCtrl != null)
          EditableOverrideTextField(
            controller: controller,
            uiControl: extraMenusCtrl,
            onChanged: (_) => controller.checkIfFormIsDirty(),
          ),
        const SizedBox(height: 32),
        HelperWidgets().categoryLabelWidget('Contact Details'),
        const SizedBox(height: 12),
        if (contactCtrl != null)
          EditableOverrideTextField(
            controller: controller,
            uiControl: contactCtrl,
            onChanged: (_) => controller.checkIfFormIsDirty(),
          ),
      ],
    );
  }
}
