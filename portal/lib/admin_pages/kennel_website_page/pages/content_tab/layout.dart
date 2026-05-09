part of '../../kennel_website_page_ui.dart';

class _ContentTabContent extends StatelessWidget {
  const _ContentTabContent({required this.controller});

  final KennelWebsiteController controller;

  @override
  Widget build(BuildContext context) {
    final tabKey = KennelWebsiteTabType.content.key;

    UiControlDefinition? ctrl(KennelWebsiteContentField f) =>
        controller.uiControls['${tabKey}_${f.name}'];

    final titleCtrl = ctrl(KennelWebsiteContentField.titleText);
    final taglineCtrl = ctrl(KennelWebsiteContentField.tagline);

    if (taglineCtrl == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HelperWidgets().categoryLabelWidget('Hero Title'),
        const SizedBox(height: 12),
        if (titleCtrl != null)
          EditableOverrideTextField(
            controller: controller,
            uiControl: titleCtrl,
            onChanged: (_) => controller.checkIfFormIsDirty(),
          ),
        const SizedBox(height: 32),
        HelperWidgets().categoryLabelWidget('Tagline'),
        const SizedBox(height: 12),
        EditableOverrideTextField(
          controller: controller,
          uiControl: taglineCtrl,
          onChanged: (_) => controller.checkIfFormIsDirty(),
        ),
      ],
    );
  }
}
