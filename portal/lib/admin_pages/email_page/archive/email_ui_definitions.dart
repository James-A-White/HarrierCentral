// part of 'email_ui_controller.dart';

// extension UiDefinitions on EmailTabbedUiController {
//   void tabAppDetails_buildControls() {
//     uiControls['${tabDescription.key}_subject'] = UiDefinition(
//         controlType: UiControlType.string,
//         sidebarEntryKey: '${tabDescription.key}_subject',
//         sidebarExitKey: tabDescription.key,
//         editedValue: editedData.value.subject,
//         originalValue: originalData.subject,
//         globalKey: GlobalKey<FormFieldState<dynamic>>(),
//         label: 'Application title',
//         maxStringLength: 100,
//         minStringLength: 3,
//         //includeOverrideButton: false,
//         textController: textEditingController['${tabDescription.key}_subject'] =
//             TextEditingController(),
//         tabIndex: 0,
//         updateEditedValue: (String? value) {
//           editedData.value = editedData.value.copyWith(subject: value!);
//           uiControls['${tabDescription.key}_subject']?.editedValue = value;
//         });

//     uiControls['${tabDescription.key}_body'] = UiDefinition(
//         controlType: UiControlType.string,
//         sidebarEntryKey: '${tabDescription.key}_body',
//         sidebarExitKey: tabDescription.key,
//         editedValue: editedData.value.body,
//         originalValue: originalData.body,
//         globalKey: GlobalKey<FormFieldState<dynamic>>(),
//         label: 'Application body',
//         maxStringLength: 100,
//         minStringLength: 3,
//         //includeOverrideButton: false,
//         textController: textEditingController['${tabDescription.key}_body'] =
//             TextEditingController(),
//         tabIndex: 0,
//         updateEditedValue: (String? value) {
//           editedData.value = editedData.value.copyWith(body: value!);
//           uiControls['${tabDescription.key}_body']?.editedValue = value;
//         });

// //     uiControls['${tabDescription.key}_shortDescription'] =
// //         UiControl(
// //             controlType: UiControlType.string,
// //             sidebarEntryKey:
// //                 '${tabDescription.key}_shortDescription',
// //             sidebarExitKey: tabDescription.key,
// //             editedValue: editedData.value?.shortDescription,
// //             originalValue: originalData.shortDescription,
// //             globalKey: GlobalKey<FormFieldState>(),
// //             label: 'Short description',
// //             maxStringLength: 250,
// //             minStringLength: 50,
// //             maxLines: 3,
// //             includeOverrideButton: false,
// //             textController: textEditingController[
// //                     '${tabDescription.key}_shortDescription'] =
// //                 TextEditingController(),
// //             tabIndex: 0,
// //             updateEditedValue: (String? value) {
// //               editedData.value =
// //                   editedData.value?.copyWith(shortDescription: value!);
// //               uiControls[
// //                       '${tabDescription.key}_shortDescription']
// //                   ?.editedValue = value;
// //             });

// //     uiControls['${tabDescription.key}_applicationImage'] =
// //         UiControl(
// //             controlType: UiControlType.imageUpload,
// //             fileType: DocumentType.applicationImage,
// //             sidebarEntryKey:
// //                 '${tabDescription.key}_applicationImage',
// //             sidebarExitKey: tabDescription.key,
// //             editedValue: editedData.value?.applicationImageUrl,
// //             originalValue: originalData.applicationImageUrl,
// //             globalKey: GlobalKey<FormFieldState>(),
// //             label: 'Image',
// //             tabIndex: 0,
// //             updateEditedValue: (String? value) {
// //               editedData.value =
// //                   editedData.value?.copyWith(shortDescription: value!);
// //               uiControls[
// //                       '${tabDescription.key}_applicationImage']
// //                   ?.editedValue = value;
// //             });

// //     uiControls['${tabProposals.key}_quadChart'] = UiControl(
// //         controlType: UiControlType.pdfUpload,
// //         fileType: DocumentType.quadChart,
// //         sidebarEntryKey: '${tabProposals.key}_quadChart',
// //         sidebarExitKey: '${tabProposals.key}',
// //         editedValue: editedData.value?.quadChart?.documentUrl,
// //         originalValue: originalData.quadChart?.documentUrl,
// //         globalKey: GlobalKey<FormFieldState>(),
// //         maxStringLength: 300,
// //         minStringLength: 20,
// //         label: 'Quad Chart',
// //         regex: BASE_UPLOAD_URL_REGEX,
// //         tabIndex: 1,
// //         updateEditedValue: (String? value) {
// //           editedData.value = editedData.value?.copyWith(
// //               quadChart: editedData.value?.quadChart
// //                   ?.copyWith(documentUrl: value ?? ''));
// //           uiControls['${tabProposals.key}_quadChart']
// //               ?.editedValue = value;
// //         });

// //     uiControls['${tabProposals.key}_proposal'] = UiControl(
// //         controlType: UiControlType.pdfUpload,
// //         fileType: DocumentType.proposal,
// //         sidebarEntryKey: '${tabProposals.key}_proposal',
// //         sidebarExitKey: '${tabProposals.key}',
// //         editedValue: editedData.value?.proposal?.documentUrl,
// //         originalValue: originalData.proposal?.documentUrl,
// //         globalKey: GlobalKey<FormFieldState>(),
// //         maxStringLength: 300,
// //         minStringLength: 20,
// //         label: 'Proposal',
// //         regex: BASE_UPLOAD_URL_REGEX,
// //         tabIndex: 1,
// //         updateEditedValue: (String? value) {
// //           editedData.value = editedData.value?.copyWith(
// //               proposal: editedData.value?.proposal
// //                   ?.copyWith(documentUrl: value ?? ''));
// //           uiControls['${tabProposals.key}_proposal']
// //               ?.editedValue = value;
// //         });

// //     /////////////////   CV Fields   /////////////////

// //     uiControls['${tabCvs.key}_cvCeo'] = UiControl(
// //         controlType: UiControlType.pdfUpload,
// //         fileType: DocumentType.cv,
// //         sidebarEntryKey: '${tabCvs.key}_cvCeo',
// //         sidebarExitKey: '${tabCvs.key}',
// //         editedValue: editedData.value?.applicationCvCeo?.documentUrl,
// //         originalValue: originalData.applicationCvCeo?.documentUrl,
// //         globalKey: GlobalKey<FormFieldState>(),
// //         label: 'CEO CV',
// //         tabIndex: tabCvs.idx,
// //         updateEditedValue: (String? value) {
// //           editedData.value = editedData.value?.copyWith(
// //               proposal: editedData.value?.applicationCvCeo
// //                   ?.copyWith(documentUrl: value ?? ''));
// //           uiControls['${AppTabKeyEnums.tabCvs.key}_cvCeo']?.editedValue = value;
// //         });

// //     uiControls['${AppTabKeyEnums.tabCvs.key}_cvTech'] = UiControl(
// //         controlType: UiControlType.pdfUpload,
// //         fileType: DocumentType.cv,
// //         sidebarEntryKey: '${AppTabKeyEnums.tabCvs.key}_cvTech',
// //         sidebarExitKey: '${AppTabKeyEnums.tabCvs.key}',
// //         editedValue: editedData.value?.applicationCvTech?.documentUrl,
// //         originalValue: originalData.applicationCvTech?.documentUrl,
// //         globalKey: GlobalKey<FormFieldState>(),
// //         label: 'Tech Lead CV',
// //         tabIndex: AppTabKeyEnums.tabCvs.idx,
// //         updateEditedValue: (String? value) {
// //           editedData.value = editedData.value?.copyWith(
// //               proposal: editedData.value?.applicationCvTech
// //                   ?.copyWith(documentUrl: value ?? ''));
// //           uiControls['${AppTabKeyEnums.tabCvs.key}_cvTech']?.editedValue =
// //               value;
// //         });

// //     uiControls['${AppTabKeyEnums.tabCvs.key}_cvAdmin'] = UiControl(
// //         controlType: UiControlType.pdfUpload,
// //         fileType: DocumentType.cv,
// //         sidebarEntryKey: '${AppTabKeyEnums.tabCvs.key}_cvAdmin',
// //         sidebarExitKey: '${AppTabKeyEnums.tabCvs.key}',
// //         editedValue: editedData.value?.applicationCvAdmin?.documentUrl,
// //         originalValue: originalData.applicationCvAdmin?.documentUrl,
// //         globalKey: GlobalKey<FormFieldState>(),
// //         label: 'Project Administrator CV',
// //         tabIndex: AppTabKeyEnums.tabCvs.idx,
// //         updateEditedValue: (String? value) {
// //           editedData.value = editedData.value?.copyWith(
// //               proposal: editedData.value?.applicationCvAdmin
// //                   ?.copyWith(documentUrl: value ?? ''));
// //           uiControls['${AppTabKeyEnums.tabCvs.key}_cvAdmin']?.editedValue =
// //               value;
// //         });

// //     uiControls['${AppTabKeyEnums.tabCvs.key}_cvComm'] = UiControl(
// //         controlType: UiControlType.pdfUpload,
// //         fileType: DocumentType.cv,
// //         sidebarEntryKey: '${AppTabKeyEnums.tabCvs.key}_cvComm',
// //         sidebarExitKey: '${AppTabKeyEnums.tabCvs.key}',
// //         editedValue: editedData.value?.applicationCvComm?.documentUrl,
// //         originalValue: originalData.applicationCvComm?.documentUrl,
// //         globalKey: GlobalKey<FormFieldState>(),
// //         label: 'Commercial Lead CV',
// //         tabIndex: AppTabKeyEnums.tabCvs.idx,
// //         updateEditedValue: (String? value) {
// //           editedData.value = editedData.value?.copyWith(
// //               proposal: editedData.value?.applicationCvComm
// //                   ?.copyWith(documentUrl: value ?? ''));
// //           uiControls['${AppTabKeyEnums.tabCvs.key}_cvComm']?.editedValue =
// //               value;
// //         });

// // /////////////////   Stakeholder Images   /////////////////

// //     uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderImageCeo'] = UiControl(
// //         controlType: UiControlType.imageUpload,
// //         fileType: DocumentType.stakeholderImage,
// //         sidebarEntryKey: '${AppTabKeyEnums.tabCvs.key}_stakeholderImageCeo',
// //         sidebarExitKey: '${AppTabKeyEnums.tabCvs.key}',
// //         editedValue: editedData.value?.applicationPicCeo,
// //         originalValue: originalData.applicationPicCeo,
// //         globalKey: GlobalKey<FormFieldState>(),
// //         label: 'CEO Image',
// //         tabIndex: AppTabKeyEnums.tabCvs.idx,
// //         updateEditedValue: (String? value) {
// //           editedData.value =
// //               editedData.value?.copyWith(applicationPicCeo: value!);
// //           uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderImageCeo']
// //               ?.editedValue = value;
// //         });

// //     uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderImageComm'] = UiControl(
// //         controlType: UiControlType.imageUpload,
// //         fileType: DocumentType.stakeholderImage,
// //         sidebarEntryKey: '${AppTabKeyEnums.tabCvs.key}_stakeholderImageComm',
// //         sidebarExitKey: '${AppTabKeyEnums.tabCvs.key}',
// //         editedValue: editedData.value?.applicationPicComm,
// //         originalValue: originalData.applicationPicComm,
// //         globalKey: GlobalKey<FormFieldState>(),
// //         label: 'Commercial Lead Image',
// //         tabIndex: AppTabKeyEnums.tabCvs.idx,
// //         updateEditedValue: (String? value) {
// //           editedData.value =
// //               editedData.value?.copyWith(applicationPicComm: value!);
// //           uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderImageComm']
// //               ?.editedValue = value;
// //         });

// //     uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderImageAdmin'] =
// //         UiControl(
// //             controlType: UiControlType.imageUpload,
// //             fileType: DocumentType.stakeholderImage,
// //             sidebarEntryKey:
// //                 '${AppTabKeyEnums.tabCvs.key}_stakeholderImageAdmin',
// //             sidebarExitKey: '${AppTabKeyEnums.tabCvs.key}',
// //             editedValue: editedData.value?.applicationPicAdmin,
// //             originalValue: originalData.applicationPicAdmin,
// //             globalKey: GlobalKey<FormFieldState>(),
// //             label: 'Project Administrator Image',
// //             tabIndex: AppTabKeyEnums.tabCvs.idx,
// //             updateEditedValue: (String? value) {
// //               editedData.value =
// //                   editedData.value?.copyWith(applicationPicAdmin: value!);
// //               uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderImageAdmin']
// //                   ?.editedValue = value;
// //             });

// //     uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderImageTech'] = UiControl(
// //         controlType: UiControlType.imageUpload,
// //         fileType: DocumentType.stakeholderImage,
// //         sidebarEntryKey: '${AppTabKeyEnums.tabCvs.key}_stakeholderImageTech',
// //         sidebarExitKey: '${AppTabKeyEnums.tabCvs.key}',
// //         editedValue: editedData.value?.applicationPicTech,
// //         originalValue: originalData.applicationPicTech,
// //         globalKey: GlobalKey<FormFieldState>(),
// //         label: 'Tech Lead Image',
// //         tabIndex: AppTabKeyEnums.tabCvs.idx,
// //         updateEditedValue: (String? value) {
// //           editedData.value =
// //               editedData.value?.copyWith(applicationPicTech: value!);
// //           uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderImageTech']
// //               ?.editedValue = value;
// //         });

// //     /////////////////   Stakeholder Names   /////////////////

// //     uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderNameCeo'] = UiControl(
// //         controlType: UiControlType.string,
// //         sidebarEntryKey: '${AppTabKeyEnums.tabCvs.key}_stakeholderNameCeo',
// //         sidebarExitKey: '${AppTabKeyEnums.tabCvs.key}',
// //         editedValue: editedData.value?.nameCeo,
// //         originalValue: originalData.nameCeo,
// //         globalKey: GlobalKey<FormFieldState>(),
// //         label: 'CEO Name',
// //         textController: textEditingController[
// //                 '${AppTabKeyEnums.tabCvs.key}_stakeholderNameCeo'] =
// //             TextEditingController(),
// //         tabIndex: AppTabKeyEnums.tabCvs.idx,
// //         updateEditedValue: (String? value) {
// //           editedData.value = editedData.value?.copyWith(nameCeo: value!);
// //           uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderNameCeo']
// //               ?.editedValue = value;
// //         });

// //     uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderNameAdmin'] = UiControl(
// //         controlType: UiControlType.string,
// //         sidebarEntryKey: '${AppTabKeyEnums.tabCvs.key}_stakeholderNameAdmin',
// //         sidebarExitKey: '${AppTabKeyEnums.tabCvs.key}',
// //         editedValue: editedData.value?.nameAdmin,
// //         originalValue: originalData.nameAdmin,
// //         globalKey: GlobalKey<FormFieldState>(),
// //         label: 'Project Administrator Name',
// //         textController: textEditingController[
// //                 '${AppTabKeyEnums.tabCvs.key}_stakeholderNameAdmin'] =
// //             TextEditingController(),
// //         tabIndex: AppTabKeyEnums.tabCvs.idx,
// //         updateEditedValue: (String? value) {
// //           editedData.value = editedData.value?.copyWith(nameAdmin: value!);
// //           uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderNameAdmin']
// //               ?.editedValue = value;
// //         });

// //     uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderNameComm'] = UiControl(
// //         controlType: UiControlType.string,
// //         sidebarEntryKey: '${AppTabKeyEnums.tabCvs.key}_stakeholderNameComm',
// //         sidebarExitKey: '${AppTabKeyEnums.tabCvs.key}',
// //         editedValue: editedData.value?.nameComm,
// //         originalValue: originalData.nameComm,
// //         globalKey: GlobalKey<FormFieldState>(),
// //         label: 'Commercial Lead Name',
// //         textController: textEditingController[
// //                 '${AppTabKeyEnums.tabCvs.key}_stakeholderNameComm'] =
// //             TextEditingController(),
// //         tabIndex: AppTabKeyEnums.tabCvs.idx,
// //         updateEditedValue: (String? value) {
// //           editedData.value = editedData.value?.copyWith(nameComm: value!);
// //           uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderNameCeo']
// //               ?.editedValue = value;
// //         });

// //     uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderNameTech'] = UiControl(
// //         controlType: UiControlType.string,
// //         sidebarEntryKey: '${AppTabKeyEnums.tabCvs.key}_stakeholderNameTech',
// //         sidebarExitKey: '${AppTabKeyEnums.tabCvs.key}',
// //         editedValue: editedData.value?.nameTech,
// //         originalValue: originalData.nameTech,
// //         globalKey: GlobalKey<FormFieldState>(),
// //         label: 'Tech Lead Name',
// //         textController: textEditingController[
// //                 '${AppTabKeyEnums.tabCvs.key}_stakeholderNameTech'] =
// //             TextEditingController(),
// //         tabIndex: AppTabKeyEnums.tabCvs.idx,
// //         updateEditedValue: (String? value) {
// //           editedData.value = editedData.value?.copyWith(nameTech: value!);
// //           uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderNameTech']
// //               ?.editedValue = value;
// //         });

// // /////////////////   Stakeholder Emails   /////////////////

// //     uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderEmailCeo'] = UiControl(
// //         controlType: UiControlType.string,
// //         sidebarEntryKey: '${AppTabKeyEnums.tabCvs.key}_stakeholderEmailCeo',
// //         sidebarExitKey: '${AppTabKeyEnums.tabCvs.key}',
// //         editedValue: editedData.value?.emailCeo,
// //         originalValue: originalData.emailCeo,
// //         globalKey: GlobalKey<FormFieldState>(),
// //         label: 'CEO Email',
// //         textController: textEditingController[
// //                 '${AppTabKeyEnums.tabCvs.key}_stakeholderEmailCeo'] =
// //             TextEditingController(),
// //         tabIndex: AppTabKeyEnums.tabCvs.idx,
// //         regex: r"^[^\s@]+@[^\s@]+\.[^\s@]+$",
// //         regexErrorString: 'Please enter a valid email address',
// //         updateEditedValue: (String? value) {
// //           editedData.value = editedData.value?.copyWith(emailCeo: value!);
// //           uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderEmailCeo']
// //               ?.editedValue = value;
// //         });

// //     uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderEmailAdmin'] =
// //         UiControl(
// //             controlType: UiControlType.string,
// //             sidebarEntryKey:
// //                 '${AppTabKeyEnums.tabCvs.key}_stakeholderEmailAdmin',
// //             sidebarExitKey: '${AppTabKeyEnums.tabCvs.key}',
// //             editedValue: editedData.value?.emailAdmin,
// //             originalValue: originalData.emailAdmin,
// //             globalKey: GlobalKey<FormFieldState>(),
// //             label: 'Project Administrator Email',
// //             textController: textEditingController[
// //                     '${AppTabKeyEnums.tabCvs.key}_stakeholderEmailAdmin'] =
// //                 TextEditingController(),
// //             tabIndex: AppTabKeyEnums.tabCvs.idx,
// //             regex: r"^[^\s@]+@[^\s@]+\.[^\s@]+$",
// //             regexErrorString: 'Please enter a valid email address',
// //             updateEditedValue: (String? value) {
// //               editedData.value = editedData.value?.copyWith(emailAdmin: value!);
// //               uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderEmailAdmin']
// //                   ?.editedValue = value;
// //             });

// //     uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderEmailComm'] = UiControl(
// //         controlType: UiControlType.string,
// //         sidebarEntryKey: '${AppTabKeyEnums.tabCvs.key}_stakeholderEmailComm',
// //         sidebarExitKey: '${AppTabKeyEnums.tabCvs.key}',
// //         editedValue: editedData.value?.emailComm,
// //         originalValue: originalData.emailComm,
// //         globalKey: GlobalKey<FormFieldState>(),
// //         label: 'Commercial Lead Email',
// //         textController: textEditingController[
// //                 '${AppTabKeyEnums.tabCvs.key}_stakeholderEmailComm'] =
// //             TextEditingController(),
// //         tabIndex: AppTabKeyEnums.tabCvs.idx,
// //         regex: r"^[^\s@]+@[^\s@]+\.[^\s@]+$",
// //         regexErrorString: 'Please enter a valid email address',
// //         updateEditedValue: (String? value) {
// //           editedData.value = editedData.value?.copyWith(emailComm: value!);
// //           uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderEmailComm']
// //               ?.editedValue = value;
// //         });

// //     uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderEmailTech'] = UiControl(
// //         controlType: UiControlType.string,
// //         sidebarEntryKey: '${AppTabKeyEnums.tabCvs.key}_stakeholderEmailTech',
// //         sidebarExitKey: '${AppTabKeyEnums.tabCvs.key}',
// //         editedValue: editedData.value?.emailTech,
// //         originalValue: originalData.emailTech,
// //         globalKey: GlobalKey<FormFieldState>(),
// //         label: 'Tech Lead Email',
// //         regex: r"^[^\s@]+@[^\s@]+\.[^\s@]+$",
// //         regexErrorString: 'Please enter a valid email address',
// //         textController: textEditingController[
// //                 '${AppTabKeyEnums.tabCvs.key}_stakeholderEmailTech'] =
// //             TextEditingController(),
// //         tabIndex: AppTabKeyEnums.tabCvs.idx,
// //         updateEditedValue: (String? value) {
// //           editedData.value = editedData.value?.copyWith(emailTech: value!);
// //           uiControls['${AppTabKeyEnums.tabCvs.key}_stakeholderEmailTech']
// //               ?.editedValue = value;
// //         });

// //     uiControls['${AppTabKeyEnums.tabTags.key}_tags'] = UiControl(
// //         controlType: UiControlType.invisible,
// //         sidebarEntryKey: '${AppTabKeyEnums.tabTags.key}',
// //         sidebarExitKey: '${AppTabKeyEnums.tabTags.key}',
// //         editedValue: editedData.value?.tagsValid,
// //         originalValue: originalData.tagsValid,
// //         globalKey: GlobalKey<FormFieldState>(),
// //         label: 'Experience Tags',
// //         regex: r"^true$",
// //         regexErrorString: 'Please ensure you have selected enough tags',
// //         textController:
// //             textEditingController['${AppTabKeyEnums.tabTags.key}_tags'] =
// //                 TextEditingController(),
// //         tabIndex: AppTabKeyEnums.tabTags.idx,
// //         updateEditedValue: (String? value) {
// //           value ??= '';
// //           editedData.value = editedData.value?.copyWith(tagsValid: value);
// //           uiControls['${AppTabKeyEnums.tabTags.key}_tags']?.editedValue = value;
// //         });

// //     uiControls[
// //             '${AppTabKeyEnums.tabForms.key}_${AppFormTypes.formOverivew.key}'] =
// //         UiControl(
// //             controlType: UiControlType.invisible,
// //             sidebarEntryKey: '${AppTabKeyEnums.tabForms.key}',
// //             sidebarExitKey: '${AppTabKeyEnums.tabForms.key}',
// //             editedValue: editedData.value?.formOverviewValid,
// //             originalValue: originalData.formOverviewValid,
// //             globalKey: GlobalKey<FormFieldState>(),
// //             minStringLength: 4,
// //             maxStringLength:
// //                 5, // this control will only hold the values "true,false, or null"
// //             label: AppFormTypes.formOverivew.title,
// //             regex: r"^true$",
// //             regexErrorString:
// //                 'Please ensure you have met the minimum word count',
// //             textController: textEditingController[
// //                     '${AppTabKeyEnums.tabForms.key}_${AppFormTypes.formOverivew.key}'] =
// //                 TextEditingController(),
// //             tabIndex: AppTabKeyEnums.tabForms.idx,
// //             updateEditedValue: (String? value) {
// //               editedData.value =
// //                   editedData.value?.copyWith(formOverviewValid: value!);
// //               uiControls[
// //                       '${AppTabKeyEnums.tabForms.key}_${AppFormTypes.formOverivew.key}']
// //                   ?.editedValue = value;
// //             });

// //     uiControls[
// //             '${AppTabKeyEnums.tabForms.key}_${AppFormTypes.formCommercial.key}'] =
// //         UiControl(
// //             controlType: UiControlType.invisible,
// //             sidebarEntryKey: '${AppTabKeyEnums.tabForms.key}',
// //             sidebarExitKey: '${AppTabKeyEnums.tabForms.key}',
// //             editedValue: editedData.value?.formCommercialroposalValid,
// //             originalValue: originalData.formCommercialroposalValid,
// //             globalKey: GlobalKey<FormFieldState>(),
// //             minStringLength: 4,
// //             maxStringLength:
// //                 5, // this control will only hold the values "true,false, or null"
// //             label: AppFormTypes.formCommercial.title,
// //             regex: r"^true$",
// //             regexErrorString:
// //                 'Please ensure you have met the minimum word count',
// //             textController: textEditingController[
// //                     '${AppTabKeyEnums.tabForms.key}_${AppFormTypes.formCommercial.key}'] =
// //                 TextEditingController(),
// //             tabIndex: AppTabKeyEnums.tabForms.idx,
// //             updateEditedValue: (String? value) {
// //               editedData.value = editedData.value
// //                   ?.copyWith(formCommercialroposalValid: value!);
// //               uiControls[
// //                       '${AppTabKeyEnums.tabForms.key}_${AppFormTypes.formCommercial.key}']
// //                   ?.editedValue = value;
// //             });

// //     uiControls[
// //             '${AppTabKeyEnums.tabForms.key}_${AppFormTypes.formProject.key}'] =
// //         UiControl(
// //             controlType: UiControlType.invisible,
// //             sidebarEntryKey: '${AppTabKeyEnums.tabForms.key}',
// //             sidebarExitKey: '${AppTabKeyEnums.tabForms.key}',
// //             editedValue: editedData.value?.formProjectPlanValid,
// //             originalValue: originalData.formProjectPlanValid,
// //             globalKey: GlobalKey<FormFieldState>(),
// //             label: AppFormTypes.formProject.title,
// //             minStringLength: 4,
// //             maxStringLength:
// //                 5, // this control will only hold the values "true,false, or null"
// //             regex: r"^true$",
// //             regexErrorString:
// //                 'Please ensure you have met the minimum word count',
// //             textController: textEditingController[
// //                     '${AppTabKeyEnums.tabForms.key}_${AppFormTypes.formProject.key}'] =
// //                 TextEditingController(),
// //             tabIndex: AppTabKeyEnums.tabForms.idx,
// //             updateEditedValue: (String? value) {
// //               editedData.value =
// //                   editedData.value?.copyWith(formProjectPlanValid: value!);
// //               uiControls[
// //                       '${AppTabKeyEnums.tabForms.key}_${AppFormTypes.formProject.key}']
// //                   ?.editedValue = value;
// //             });

// //     uiControls[
// //             '${AppTabKeyEnums.tabForms.key}_${AppFormTypes.formTechnical.key}'] =
// //         UiControl(
// //             controlType: UiControlType.invisible,
// //             sidebarEntryKey: '${AppTabKeyEnums.tabForms.key}',
// //             sidebarExitKey: '${AppTabKeyEnums.tabForms.key}',
// //             editedValue: editedData.value?.formTechnicalDescriptionValid,
// //             originalValue: originalData.formTechnicalDescriptionValid,
// //             globalKey: GlobalKey<FormFieldState>(),
// //             label: AppFormTypes.formTechnical.title,
// //             minStringLength: 4,
// //             maxStringLength:
// //                 5, // this control will only hold the values "true,false, or null"
// //             regex: r"^true$",
// //             regexErrorString:
// //                 'Please ensure you have met the minimum word count',
// //             textController: textEditingController[
// //                     '${AppTabKeyEnums.tabForms.key}_${AppFormTypes.formTechnical.key}'] =
// //                 TextEditingController(),
// //             tabIndex: AppTabKeyEnums.tabForms.idx,
// //             updateEditedValue: (String? value) {
// //               editedData.value = editedData.value
// //                   ?.copyWith(formTechnicalDescriptionValid: value!);
// //               uiControls[
// //                       '${AppTabKeyEnums.tabForms.key}_${AppFormTypes.formTechnical.key}']
// //                   ?.editedValue = value;
// //             });

// //     uiControls['${AppTabKeyEnums.tabConsent.key}_agreeTsAndCs}'] = UiControl(
// //         controlType: UiControlType.checkbox,
// //         sidebarEntryKey: '${AppTabKeyEnums.tabConsent.key}_termsAndConditions',
// //         sidebarExitKey: '${AppTabKeyEnums.tabConsent.key}',
// //         editedValue: editedData.value?.agreeTsAndCs,
// //         originalValue: originalData.agreeTsAndCs,
// //         globalKey: GlobalKey<FormFieldState>(),
// //         label: 'Accept terms and conditions',
// //         minStringLength: 1,
// //         maxStringLength: 1, // the default value is null for Ts and Cs
// //         regex: r"^1$",
// //         regexErrorString:
// //             'Please ensure you have accepted the Terms and Conditions',
// //         textController: textEditingController[
// //                 '${AppTabKeyEnums.tabConsent.key}_agreeTsAndCs}'] =
// //             TextEditingController(),
// //         tabIndex: AppTabKeyEnums.tabConsent.idx,
// //         updateEditedValue: (String? value) {
// //           String details = '';
// //           if ((value ?? '0') == '0') {
// //             details = '';
// //           } else {
// //             details = '<user name> + ${DateTime.now()}';
// //           }

// //           editedData.value = editedData.value?.copyWith(agreeTsAndCs: value!);
// //           editedData.value =
// //               editedData.value?.copyWith(agreeTsAndCsDetails: details);
// //           uiControls['${AppTabKeyEnums.tabConsent.key}_agreeTsAndCs}']
// //               ?.editedValue = value;
// //         });

// //     //==========

// //     uiControls['${AppTabKeyEnums.tabConsent.key}_optOutToShareWithNations}'] =
// //         UiControl(
// //             controlType: UiControlType.checkbox,
// //             sidebarEntryKey:
// //                 '${AppTabKeyEnums.tabConsent.key}_optOutToShareWithNations',
// //             sidebarExitKey: '${AppTabKeyEnums.tabConsent.key}',
// //             editedValue: editedData.value?.optOutToShareWithNations,
// //             originalValue: originalData.optOutToShareWithNations,
// //             globalKey: GlobalKey<FormFieldState>(),
// //             label:
// //                 'I agree to share our data with NATO nation government users',
// //             minStringLength: 1,
// //             maxStringLength: 1, // the default value is null for Ts and Cs
// //             regex: r"^[1,0]$",
// //             regexErrorString:
// //                 'If you see this message, please contact us as this is an error.',
// //             textController: textEditingController[
// //                     '${AppTabKeyEnums.tabConsent.key}_optOutToShareWithNations}'] =
// //                 TextEditingController(),
// //             tabIndex: AppTabKeyEnums.tabConsent.idx,
// //             updateEditedValue: (String? value) {
// //               editedData.value =
// //                   editedData.value?.copyWith(optOutToShareWithNations: value!);
// //               uiControls[
// //                       '${AppTabKeyEnums.tabConsent.key}_optOutToShareWithNations}']
// //                   ?.editedValue = value;
// //             });

// //     uiControls['${AppTabKeyEnums.tabConsent.key}_optInToReceivePromotions}'] =
// //         UiControl(
// //             controlType: UiControlType.checkbox,
// //             sidebarEntryKey:
// //                 '${AppTabKeyEnums.tabConsent.key}_optInToReceivePromotions',
// //             sidebarExitKey: '${AppTabKeyEnums.tabConsent.key}',
// //             editedValue: editedData.value?.optInToReceivePromotions,
// //             originalValue: originalData.optInToReceivePromotions,
// //             globalKey: GlobalKey<FormFieldState>(),
// //             label: 'I would like to receive information from DIANA partners',
// //             minStringLength: 1,
// //             maxStringLength: 1, // the default value is null for Ts and Cs
// //             regex: r"^[1,0]$",
// //             regexErrorString:
// //                 'If you see this message, please contact us as this is an error.',
// //             textController: textEditingController[
// //                     '${AppTabKeyEnums.tabConsent.key}_optInToReceivePromotions}'] =
// //                 TextEditingController(),
// //             tabIndex: AppTabKeyEnums.tabConsent.idx,
// //             updateEditedValue: (String? value) {
// //               editedData.value =
// //                   editedData.value?.copyWith(optInToReceivePromotions: value!);
// //               uiControls[
// //                       '${AppTabKeyEnums.tabConsent.key}_optInToReceivePromotions}']
// //                   ?.editedValue = value;
// //             });
//   }
// }
