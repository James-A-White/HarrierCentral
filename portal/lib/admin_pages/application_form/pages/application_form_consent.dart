part of '../application_form_ui.dart';

extension ApplicationConsent on TestFormPage {
  Widget _buildAppConsent({required int tabIndex}) {
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
                      HelperWidgets()
                          .categoryLabelWidget('Agree to Terms and Conditions'),
                      ...buildCheckbox(tabIndex,
                          '${AppTabKeyEnums.tabConsent.key}_agreeTsAndCs}'),
                      HelperWidgets()
                          .categoryLabelWidget('Opt in / opt out choices'),
                      ...buildCheckbox(tabIndex,
                          '${AppTabKeyEnums.tabConsent.key}_optOutToShareWithNations}'),
                      ...buildCheckbox(tabIndex,
                          '${AppTabKeyEnums.tabConsent.key}_optInToReceivePromotions}'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    style: defaultButtonStyle,
                    onPressed: () {
                      applicationGetxController.tabController.index--;
                    },
                    child: Text(
                      'Back',
                      style: buttonLabelStyleMedium,
                    ),
                  ),
                ),
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
