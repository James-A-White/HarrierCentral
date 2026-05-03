part of '../../kennel_website_page_ui.dart';

class _SeoTabContent extends StatelessWidget {
  const _SeoTabContent({required this.controller});

  final KennelWebsiteController controller;

  @override
  Widget build(BuildContext context) {
    final tabKey = KennelWebsiteTabType.seo.key;

    final titleCtrl =
        controller.uiControls['${tabKey}_${KennelWebsiteSeoField.seoTitle.name}'];
    final descCtrl =
        controller.uiControls['${tabKey}_${KennelWebsiteSeoField.seoDescription.name}'];

    if (titleCtrl == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HelperWidgets().categoryLabelWidget('Search Engine Optimisation'),
        const SizedBox(height: 12),
        EditableOverrideTextField(
          controller: controller,
          uiControl: titleCtrl,
          onChanged: (_) => controller.checkIfFormIsDirty(),
        ),
        const SizedBox(height: 16),
        if (descCtrl != null)
          EditableOverrideTextField(
            controller: controller,
            uiControl: descCtrl,
            onChanged: (_) => controller.checkIfFormIsDirty(),
          ),
      ],
    );
  }
}
