// part of '../application_form_ui.dart';

// extension ApplicationCvs on TestFormPageState {
//   Widget _buildAppCvs({required int tabIndex}) {
//     {
//       // final isMobileScreen =
//       //     formController.screenSize.value == EScreenSize.isMobileScreen;

//       return Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Expanded(
//               child: SingleChildScrollView(
//                 child: Lockable(
//                   lockState: applicationGetxController.tabLocked[tabIndex],
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     children: [
//                       HelperWidgets().categoryLabelWidget('CEO Details'),
//                       const SizedBox(height: 20),
//                       Row(
//                         mainAxisSize: MainAxisSize.min,
//                         mainAxisAlignment: MainAxisAlignment.start,
//                         children: [
//                           SizedBox(
//                               width: 275,
//                               child: Column(
//                                 mainAxisAlignment: MainAxisAlignment.start,
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   ...buildDocumentManagerField(tabIndex,
//                                       '${AppTabKeyEnums.tabCvs.key}_stakeholderImageCeo',
//                                       onUploadComplete: (String fileName) {
//                                     applicationGetxController
//                                         .uiControls[
//                                             '${AppTabKeyEnums.tabCvs.key}_stakeholderImageCeo']!
//                                         .editedValue = BASE_UPLOAD_URL + fileName;
//                                     applicationGetxController.editedData.value =
//                                         applicationGetxController
//                                             .editedData.value!
//                                             .copyWith(
//                                                 applicationPicCeo:
//                                                     BASE_UPLOAD_URL + fileName);
//                                   }, onRemoveDocument: () {
//                                     applicationGetxController
//                                         .uiControls[
//                                             '${AppTabKeyEnums.tabCvs.key}_stakeholderImageCeo']!
//                                         .editedValue = null;
//                                     applicationGetxController.editedData.value =
//                                         applicationGetxController
//                                             .editedData.value!
//                                             .copyWith(applicationPicCeo: null);
//                                   }),
//                                 ],
//                               )),
//                           Container(
//                             color: Colors.black54,
//                             width: 1,
//                             height: 340,
//                           ),
//                           SizedBox(
//                             width: 20,
//                           ),
//                           Expanded(
//                             flex: 3,
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.start,
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 ...buildEditableTextField(tabIndex,
//                                     '${AppTabKeyEnums.tabCvs.key}_stakeholderNameCeo'),
//                                 ...buildEditableTextField(tabIndex,
//                                     '${AppTabKeyEnums.tabCvs.key}_stakeholderEmailCeo'),
//                                 ...buildDocumentManagerField(tabIndex,
//                                     '${AppTabKeyEnums.tabCvs.key}_cvCeo',
//                                     onUploadComplete: (String fileName) {
//                                   applicationGetxController
//                                       .uiControls[
//                                           '${AppTabKeyEnums.tabCvs.key}_cvCeo']!
//                                       .editedValue = BASE_UPLOAD_URL + fileName;
//                                   applicationGetxController.editedData.value =
//                                       applicationGetxController
//                                           .editedData.value!
//                                           .copyWith(
//                                               applicationCvCeo: PdfDocumentModel(
//                                                   pdfDocumentPublicId:
//                                                       UuidValue.fromString(
//                                                           '00000000-0000-0000-0000-000000000000'),
//                                                   fkApplicationPublicId:
//                                                       UuidValue.fromString(
//                                                           '00000000-0000-0000-0000-000000000000'),
//                                                   documentUrl: BASE_UPLOAD_URL +
//                                                       fileName,
//                                                   documentType:
//                                                       DocumentType.cv));
//                                 }, onRemoveDocument: () {
//                                   applicationGetxController
//                                       .uiControls[
//                                           '${AppTabKeyEnums.tabCvs.key}_cvCeo']!
//                                       .editedValue = null;
//                                   applicationGetxController.editedData.value =
//                                       applicationGetxController
//                                           .editedData.value!
//                                           .copyWith(applicationCvCeo: null);
//                                 })
//                               ],
//                             ),
//                           ),
//                           const SizedBox(
//                             width: 30,
//                           ),
//                         ],
//                       ),

//                       //////////  Tech Lead Details
//                       HelperWidgets().categoryLabelWidget('Tech Lead Details'),
//                       const SizedBox(height: 20),
//                       Row(
//                         mainAxisSize: MainAxisSize.min,
//                         mainAxisAlignment: MainAxisAlignment.start,
//                         children: [
//                           SizedBox(
//                               width: 275,
//                               child: Column(
//                                 mainAxisAlignment: MainAxisAlignment.start,
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   ...buildDocumentManagerField(tabIndex,
//                                       '${AppTabKeyEnums.tabCvs.key}_stakeholderImageTech',
//                                       onUploadComplete: (String fileName) {
//                                     applicationGetxController
//                                         .uiControls[
//                                             '${AppTabKeyEnums.tabCvs.key}_stakeholderImageTech']!
//                                         .editedValue = BASE_UPLOAD_URL + fileName;
//                                     applicationGetxController.editedData.value =
//                                         applicationGetxController
//                                             .editedData.value!
//                                             .copyWith(
//                                                 applicationPicTech:
//                                                     BASE_UPLOAD_URL + fileName);
//                                   }, onRemoveDocument: () {
//                                     applicationGetxController
//                                         .uiControls[
//                                             '${AppTabKeyEnums.tabCvs.key}_stakeholderImageTech']!
//                                         .editedValue = null;
//                                     applicationGetxController.editedData.value =
//                                         applicationGetxController
//                                             .editedData.value!
//                                             .copyWith(applicationPicTech: null);
//                                   }),
//                                 ],
//                               )),
//                           Container(
//                             color: Colors.black54,
//                             width: 1,
//                             height: 340,
//                           ),
//                           SizedBox(
//                             width: 20,
//                           ),
//                           Expanded(
//                             flex: 3,
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.start,
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 ...buildEditableTextField(tabIndex,
//                                     '${AppTabKeyEnums.tabCvs.key}_stakeholderNameTech'),
//                                 ...buildEditableTextField(tabIndex,
//                                     '${AppTabKeyEnums.tabCvs.key}_stakeholderEmailTech'),
//                                 ...buildDocumentManagerField(tabIndex,
//                                     '${AppTabKeyEnums.tabCvs.key}_cvTech',
//                                     onUploadComplete: (String fileName) {
//                                   applicationGetxController
//                                       .uiControls[
//                                           '${AppTabKeyEnums.tabCvs.key}_cvTech']!
//                                       .editedValue = BASE_UPLOAD_URL + fileName;
//                                   applicationGetxController.editedData.value =
//                                       applicationGetxController
//                                           .editedData.value!
//                                           .copyWith(
//                                               applicationCvTech: PdfDocumentModel(
//                                                   pdfDocumentPublicId:
//                                                       UuidValue.fromString(
//                                                           '00000000-0000-0000-0000-000000000000'),
//                                                   fkApplicationPublicId:
//                                                       UuidValue.fromString(
//                                                           '00000000-0000-0000-0000-000000000000'),
//                                                   documentUrl: BASE_UPLOAD_URL +
//                                                       fileName,
//                                                   documentType:
//                                                       DocumentType.cv));
//                                 }, onRemoveDocument: () {
//                                   applicationGetxController
//                                       .uiControls[
//                                           '${AppTabKeyEnums.tabCvs.key}_cvTech']!
//                                       .editedValue = null;
//                                   applicationGetxController.editedData.value =
//                                       applicationGetxController
//                                           .editedData.value!
//                                           .copyWith(applicationCvTech: null);
//                                 })
//                               ],
//                             ),
//                           ),
//                           const SizedBox(
//                             width: 30,
//                           ),
//                         ],
//                       ),

//                       //////////  Commercial Lead Details
//                       HelperWidgets()
//                           .categoryLabelWidget('Commercial Lead Details'),
//                       SizedBox(height: 20),
//                       Row(
//                         //mainAxisSize: MainAxisSize.min,
//                         mainAxisAlignment: MainAxisAlignment.start,
//                         children: [
//                           SizedBox(
//                             width: 275,
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.start,
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 ...buildDocumentManagerField(tabIndex,
//                                     '${AppTabKeyEnums.tabCvs.key}_stakeholderImageComm',
//                                     onUploadComplete: (String fileName) {
//                                   applicationGetxController
//                                       .uiControls[
//                                           '${AppTabKeyEnums.tabCvs.key}_stakeholderImageComm']!
//                                       .editedValue = BASE_UPLOAD_URL + fileName;
//                                   applicationGetxController.editedData.value =
//                                       applicationGetxController
//                                           .editedData.value!
//                                           .copyWith(
//                                               applicationPicComm:
//                                                   BASE_UPLOAD_URL + fileName);
//                                 }, onRemoveDocument: () {
//                                   applicationGetxController
//                                       .uiControls[
//                                           '${AppTabKeyEnums.tabCvs.key}_stakeholderImageComm']!
//                                       .editedValue = null;
//                                   applicationGetxController.editedData.value =
//                                       applicationGetxController
//                                           .editedData.value!
//                                           .copyWith(applicationPicComm: null);
//                                 }),
//                               ],
//                             ),
//                           ),
//                           Container(
//                             color: Colors.black54,
//                             width: 1,
//                             height: 340,
//                           ),
//                           SizedBox(
//                             width: 20,
//                           ),
//                           Expanded(
//                             flex: 3,
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.start,
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 ...buildEditableTextField(tabIndex,
//                                     '${AppTabKeyEnums.tabCvs.key}_stakeholderNameComm'),
//                                 ...buildEditableTextField(tabIndex,
//                                     '${AppTabKeyEnums.tabCvs.key}_stakeholderEmailComm'),
//                                 ...buildDocumentManagerField(tabIndex,
//                                     '${AppTabKeyEnums.tabCvs.key}_cvComm',
//                                     onUploadComplete: (String fileName) {
//                                   applicationGetxController
//                                       .uiControls[
//                                           '${AppTabKeyEnums.tabCvs.key}_cvComm']!
//                                       .editedValue = BASE_UPLOAD_URL + fileName;
//                                   applicationGetxController.editedData.value =
//                                       applicationGetxController
//                                           .editedData.value!
//                                           .copyWith(
//                                               applicationCvComm: PdfDocumentModel(
//                                                   pdfDocumentPublicId:
//                                                       UuidValue.fromString(
//                                                           '00000000-0000-0000-0000-000000000000'),
//                                                   fkApplicationPublicId:
//                                                       UuidValue.fromString(
//                                                           '00000000-0000-0000-0000-000000000000'),
//                                                   documentUrl: BASE_UPLOAD_URL +
//                                                       fileName,
//                                                   documentType:
//                                                       DocumentType.cv));
//                                 }, onRemoveDocument: () {
//                                   applicationGetxController
//                                       .uiControls[
//                                           '${AppTabKeyEnums.tabCvs.key}_cvComm']!
//                                       .editedValue = null;
//                                   applicationGetxController.editedData.value =
//                                       applicationGetxController
//                                           .editedData.value!
//                                           .copyWith(applicationCvComm: null);
//                                 })
//                               ],
//                             ),
//                           ),
//                           const SizedBox(
//                             width: 30,
//                           ),
//                         ],
//                       ),

//                       //////////  Administrator Details
//                       HelperWidgets()
//                           .categoryLabelWidget('Project Administrator Details'),
//                       SizedBox(height: 20),
//                       Row(
//                         mainAxisSize: MainAxisSize.min,
//                         mainAxisAlignment: MainAxisAlignment.start,
//                         children: [
//                           SizedBox(
//                               width: 275,
//                               child: Column(
//                                 mainAxisAlignment: MainAxisAlignment.start,
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   ...buildDocumentManagerField(tabIndex,
//                                       '${AppTabKeyEnums.tabCvs.key}_stakeholderImageAdmin',
//                                       onUploadComplete: (String fileName) {
//                                     applicationGetxController
//                                         .uiControls[
//                                             '${AppTabKeyEnums.tabCvs.key}_stakeholderImageAdmin']!
//                                         .editedValue = BASE_UPLOAD_URL + fileName;
//                                     applicationGetxController.editedData.value =
//                                         applicationGetxController
//                                             .editedData.value!
//                                             .copyWith(
//                                                 applicationPicAdmin:
//                                                     BASE_UPLOAD_URL + fileName);
//                                   }, onRemoveDocument: () {
//                                     applicationGetxController
//                                         .uiControls[
//                                             '${AppTabKeyEnums.tabCvs.key}_stakeholderImageAdmin']!
//                                         .editedValue = null;
//                                     applicationGetxController.editedData.value =
//                                         applicationGetxController
//                                             .editedData.value!
//                                             .copyWith(
//                                                 applicationPicAdmin: null);
//                                   }),
//                                 ],
//                               )),
//                           Container(
//                             color: Colors.black54,
//                             width: 1,
//                             height: 340,
//                           ),
//                           SizedBox(
//                             width: 20,
//                           ),
//                           Expanded(
//                             flex: 3,
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.start,
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 ...buildEditableTextField(tabIndex,
//                                     '${AppTabKeyEnums.tabCvs.key}_stakeholderNameAdmin'),
//                                 ...buildEditableTextField(tabIndex,
//                                     '${AppTabKeyEnums.tabCvs.key}_stakeholderEmailAdmin'),
//                                 ...buildDocumentManagerField(tabIndex,
//                                     '${AppTabKeyEnums.tabCvs.key}_cvAdmin',
//                                     onUploadComplete: (String fileName) {
//                                   applicationGetxController
//                                       .uiControls[
//                                           '${AppTabKeyEnums.tabCvs.key}_cvAdmin']!
//                                       .editedValue = BASE_UPLOAD_URL + fileName;
//                                   applicationGetxController.editedData.value =
//                                       applicationGetxController.editedData.value!.copyWith(
//                                           applicationCvAdmin: PdfDocumentModel(
//                                               pdfDocumentPublicId:
//                                                   UuidValue.fromString(
//                                                       '00000000-0000-0000-0000-000000000000'),
//                                               fkApplicationPublicId:
//                                                   UuidValue.fromString(
//                                                       '00000000-0000-0000-0000-000000000000'),
//                                               documentUrl:
//                                                   BASE_UPLOAD_URL + fileName,
//                                               documentType: DocumentType.cv));
//                                 }, onRemoveDocument: () {
//                                   applicationGetxController
//                                       .uiControls[
//                                           '${AppTabKeyEnums.tabCvs.key}_cvAdminapplicationCvAdmin']!
//                                       .editedValue = null;
//                                   applicationGetxController.editedData.value =
//                                       applicationGetxController
//                                           .editedData.value!
//                                           .copyWith(applicationCvAdmin: null);
//                                 })
//                               ],
//                             ),
//                           ),
//                           const SizedBox(
//                             width: 30,
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 70),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Align(
//                   alignment: Alignment.centerLeft,
//                   child: ElevatedButton(
//                     style: defaultButtonStyle,
//                     onPressed: () {
//                       applicationGetxController.tabController.index--;
//                     },
//                     child: Text(
//                       'Back',
//                       style: buttonLabelStyleMedium,
//                     ),
//                   ),
//                 ),
//                 Expanded(child: Container()),
//                 Align(
//                   alignment: Alignment.centerRight,
//                   child: ElevatedButton(
//                     style: defaultButtonStyle,
//                     onPressed: () {
//                       applicationGetxController.tabController.index++;
//                     },
//                     child: Text(
//                       'Next',
//                       style: buttonLabelStyleMedium,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       );
//     }
//   }
// }
