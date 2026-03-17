part of 'package:hcportal/admin_pages/email_page/email_ui_controller.dart';

extension TabDataAdHocEmailUiDefinitions on EmailTabbedUiController {
  void tabAppDetails_buildControls() {
    uiControls['${tabDescription.key}_subject'] = UiControlDefinition(
        controlType: UiControlType.string,
        sidebarEntryKey: '${tabDescription.key}_subject',
        sidebarExitKey: tabDescription.key,
        sidebarData: const SideBarData(
          'Subject',
          MaterialCommunityIcons.format_title,
          'This is the subject line of the email that will be sent to the recipient(s).',
        ),
        editedFieldValue: editedData.value.subject,
        originalFieldValue: originalData.subject,
        globalKey: GlobalKey<FormFieldState<dynamic>>(),
        label: 'Email subject',
        maxStringLength: 100,
        minStringLength: 3,
        textController:
            textEditingController['${tabDescription.key}_subject'] =
                TextEditingController(),
        tabIndex: tabDescription.tabIndex,
        updateEditedValue: (String? value) {
          if (value == null) return;
          editedData.value = editedData.value.copyWith(subject: value);
          uiControls['${tabDescription.key}_subject']?.editedFieldValue = value;
        });

    uiControls['${tabDescription.key}_body'] = UiControlDefinition(
        controlType: UiControlType.string,
        sidebarEntryKey: '${tabDescription.key}_body',
        sidebarExitKey: tabDescription.key,
        sidebarData: const SideBarData(
          'Body',
          Entypo.text,
          'This is the main content of the email that will be sent to the recipient(s).\r\n\r\n You can use the rich text editor to format the text, add links, and more.',
        ),
        editedFieldValue: editedData.value.body,
        originalFieldValue: originalData.body,
        globalKey: GlobalKey<FormFieldState<dynamic>>(),
        label: 'Email body',
        maxStringLength: 100,
        minStringLength: 3,
        maxLines: 5,
        textController:
            textEditingController['${tabDescription.key}_body'] =
                TextEditingController(),
        tabIndex: tabDescription.tabIndex,
        updateEditedValue: (String? value) {
          if (value == null) return;
          editedData.value = editedData.value.copyWith(body: value);
          uiControls['${tabDescription.key}_body']?.editedFieldValue = value;
        });

    uiControls['${tabDescription.key}_int'] = UiControlDefinition(
        controlType: UiControlType.string,
        sidebarEntryKey: '${tabDescription.key}_int',
        sidebarExitKey: tabDescription.key,
        sidebarData: const SideBarData(
          'Int test',
          Entypo.text,
          'This is the main content of the email that will be sent to the recipient(s).\r\n\r\n You can use the rich text editor to format the text, add links, and more.',
        ),
        editedFieldValue: editedData.value.intTest.toString(),
        originalFieldValue: originalData.intTest.toString(),
        globalKey: GlobalKey<FormFieldState<dynamic>>(),
        label: 'Int test',
        regex: r'^[+-]?\d+$',
        regexErrorString: 'Please enter an integer value',
        includeOverrideButton: true,
        textController:
            textEditingController['${tabDescription.key}_int'] =
                TextEditingController(),
        tabIndex: tabDescription.tabIndex,
        updateEditedValue: (String? value) {
          final intValue = int.tryParse(value ?? '');
          if (intValue == null) return;
          editedData.value = editedData.value.copyWith(intTest: intValue);
          uiControls['${tabDescription.key}_int']?.editedFieldValue =
              intValue.toString();
        });
  }
}

class TabDataAdHocEmail extends TabDefinitionData {
  TabDataAdHocEmail()
      : super(
          key: keyValue,
          title: 'Ad hoc Email',
          tabIndex: tabIndexValue,
          isTabLockable: true,
          hasCustomTabStatusFunction: false,
          showTabInSubmitSummary: true,
          sidebarData: const SideBarData(
            'Ad hoc Email',
            MaterialCommunityIcons.notebook_edit,
            'You can use this tab to send ad hoc emails to everyone in the Kennel or only those who are RSVPed to this run.',
          ),
        );

  static const String keyValue = 'sendAdHocEmail';
  static const int tabIndexValue = 0;
}

class EmailPageSendAdHocEmail extends StatelessWidget {
  const EmailPageSendAdHocEmail(
    this.controller,
    this.tabIndex,
    this.fieldName, {
    super.key,
  });

  final int tabIndex;
  final String fieldName;
  final TabUiController controller;

  @override
  Widget build(BuildContext context) {
    final tab = TabDataAdHocEmail();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Lockable(
                lockState: controller.tabLocked[tabIndex],
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HelperWidgets().categoryLabelWidget(tab.title),
                    if (controller.uiControls['${tab.key}_subject'] != null)
                      EditableOverrideTextField(
                        controller: controller,
                        uiControl:
                            controller.uiControls['${tab.key}_subject']!,
                        onChanged: (_) => controller.checkIfFormIsDirty(),
                      ),
                    const SizedBox(height: 16),
                    if (controller.uiControls['${tab.key}_body'] != null)
                      EditableOverrideTextField(
                        controller: controller,
                        uiControl: controller.uiControls['${tab.key}_body']!,
                        onChanged: (_) => controller.checkIfFormIsDirty(),
                      ),
                    const SizedBox(height: 16),
                    if (controller.uiControls['${tab.key}_int'] != null)
                      EditableOverrideTextField(
                        controller: controller,
                        uiControl: controller.uiControls['${tab.key}_int']!,
                        onChanged: (_) => controller.checkIfFormIsDirty(),
                      ),
                    const SizedBox(height: 16),
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
                    controller.tabController.index++;
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
