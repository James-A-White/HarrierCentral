part of '../application_form_ui.dart';

extension ApplicationDetails on TestFormPage {
  Widget _buildAppDetails({required int tabIndex}) {
    {
      // final isMobileScreen =
      //     formController.screenSize.value == EScreenSize.isMobileScreen;

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Lockable(
                  lockState: applicationGetxController.tabLocked[tabIndex],
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HelperWidgets().categoryLabelWidget(
                          AppTabKeyEnums.tabDescription.title),
                      ...buildEditableTextField(tabIndex,
                          '${AppTabKeyEnums.tabDescription.key}_title'),
                      ...buildEditableTextField(tabIndex,
                          '${AppTabKeyEnums.tabDescription.key}_shortDescription'),
                      ...buildDocumentManagerField(tabIndex,
                          '${AppTabKeyEnums.tabDescription.key}_applicationImage',
                          height: 400,
                          width: 400,
                          defaultImageAsset:
                              'images/challenge_default_images/${applicationGetxController.editedData.value!.applicationImageAsset}',
                          onUploadComplete: (String fileName) {
                        applicationGetxController
                            .uiControls[
                                '${AppTabKeyEnums.tabDescription.key}_applicationImage']!
                            .editedFieldValue = BASE_UPLOAD_URL + fileName;
                        applicationGetxController.editedData.value =
                            applicationGetxController.editedData.value!
                                .copyWith(
                                    applicationImageUrl:
                                        BASE_UPLOAD_URL + fileName);
                      }, onRemoveDocument: () {
                        applicationGetxController
                            .uiControls[
                                '${AppTabKeyEnums.tabDescription.key}_applicationImage']!
                            .editedFieldValue = null;
                        applicationGetxController.editedData.value =
                            applicationGetxController.editedData.value!
                                .copyWith(applicationImageUrl: null);
                      }),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Container()),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: defaultButtonStyle,
                    onPressed: () {
                      applicationGetxController.tabController.index++;
                    },
                    child: Text(
                      'Next',
                      style: buttonLabelStyleMedium,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }
}
