part of '../../kennel_website_page_ui.dart';

class _IdentityTabContent extends StatelessWidget {
  const _IdentityTabContent({required this.controller});

  final KennelWebsiteController controller;

  @override
  Widget build(BuildContext context) {
    final tabKey = KennelWebsiteTabType.identity.key;

    final enabledKey = '${tabKey}_${KennelWebsiteIdentityField.enabled.name}';
    final shortcodeKey =
        '${tabKey}_${KennelWebsiteIdentityField.urlShortcode.name}';
    final domainKey =
        '${tabKey}_${KennelWebsiteIdentityField.customDomain.name}';

    final enabledControl = controller.uiControls[enabledKey];
    final shortcodeControl = controller.uiControls[shortcodeKey];
    final domainControl = controller.uiControls[domainKey];

    if (enabledControl == null ||
        shortcodeControl == null ||
        domainControl == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HelperWidgets().categoryLabelWidget('Website Status'),
        const SizedBox(height: 12),
        TriStateCheckboxField(
          controller: controller,
          uiControl: enabledControl,
          onChanged: (_) => controller.checkIfFormIsDirty(),
        ),
        const SizedBox(height: 32),
        HelperWidgets().categoryLabelWidget('URL Settings'),
        const SizedBox(height: 12),
        EditableOverrideTextField(
          controller: controller,
          uiControl: shortcodeControl,
          onChanged: (_) => controller.checkIfFormIsDirty(),
        ),
        const SizedBox(height: 16),
        EditableOverrideTextField(
          controller: controller,
          uiControl: domainControl,
          onChanged: (_) => controller.checkIfFormIsDirty(),
        ),
      ],
    );
  }
}
