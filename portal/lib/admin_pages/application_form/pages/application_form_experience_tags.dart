part of '../application_form_ui.dart';

extension ExperienceTags on TestFormPage {
  Widget _buildExperienceTags({required int tabIndex}) {
    return Padding(
      padding: const EdgeInsets.all(
        16.0,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  'Minimum required = $MINIMUM_TAGS_REQUIRED',
                  style: titleStyleBlack,
                ),
                Text(
                  'Maximum allowed = $MAXIMUM_TAGS_ALLOWWED',
                  style: titleStyleBlack,
                ),
              ],
            ),
          ),
          Obx(
            () => Container(
                padding: const EdgeInsets.only(
                  top: 4,
                  bottom: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      'Selected count = ${applicationGetxController.tabsSelectedCount.value}',
                      style: titleStyleBlack,
                    ),
                    Text(
                        'Remaining count = ${MAXIMUM_TAGS_ALLOWWED - applicationGetxController.tabsSelectedCount.value}',
                        style: titleStyleBlack),
                  ],
                )),
          ),
          const Divider(
            color: Colors.black,
          ),
          Expanded(
            child: Scrollbar(
              controller:
                  applicationGetxController.allFieldsTabScrollController,
              trackVisibility: false,
              thumbVisibility: false,
              interactive: true,
              thickness: 15,
              child: SingleChildScrollView(
                controller:
                    applicationGetxController.allFieldsTabScrollController,
                child: Lockable(
                  lockState: applicationGetxController.tabLocked[tabIndex],
                  child: TagsUiPage(
                    controller: applicationGetxController,
                    tagsStatus: applicationGetxController.tagsStatus,
                    tabsSelectedCount:
                        applicationGetxController.tabsSelectedCount,
                    challengeIndex: applicationGetxController
                        .editedData.value?.challengeIndex,
                    updateTags: ({bool? tagSelected, String? entryKey}) =>
                        applicationGetxController.updateTags(
                      tagSelected: tagSelected,
                      entryKey: entryKey,
                    ),
                  ),
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
