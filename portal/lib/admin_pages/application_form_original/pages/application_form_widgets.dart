// part of '../application_form_ui.dart';

// extension ApplicationFormWidgets on TestFormPageState {
//   // this field is here only to allow us to take advantage of some of the
//   // functions avialble for setting tab status and other features associated
//   // with UI controls, but where we don't want to have any user interation
//   List<Widget> buildInvisibleField(
//     int tabIndex,
//     String fieldName,
//   ) {
//     try {
//       if (applicationGetxController.uiControls[fieldName] != null) {
//         //UiControl uiControl = applicationGetxController.uiControls[fieldName]!;
//         return <Widget>[Container()];
//       }
//     } catch (ex) {
//       rethrow;
//     }
//     return <Widget>[Container()]; // should never reach here
//   }

//   List<Widget> buildEditableTextField(
//     int tabIndex,
//     String fieldName,
//   ) {
//     try {
//       if (applicationGetxController.uiControls[fieldName] != null) {
//         UiControl uiControl = applicationGetxController.uiControls[fieldName]!;
//         return <Widget>[
//           MouseRegion(
//             onEnter: (event) {
//               applicationGetxController
//                   .setSidebarData(uiControl.sidebarEntryKey);
//             },
//             onExit: (event) {
//               applicationGetxController
//                   .setSidebarData(uiControl.sidebarExitKey);
//             },
//             child: OverrideTextField(
//               isMultiline: uiControl.maxLines == 1 ? false : true,
//               maxLines: uiControl.maxLines,
//               globalKey: uiControl.globalKey,
//               includeOverrideButton: uiControl.includeOverrideButton,
//               controller: uiControl.textController!,
//               label: uiControl.label,
//               isOverriden: (uiControl.editedValue != null) &&
//                   (uiControl.originalValue != uiControl.editedValue),
//               //focusNode: formController.focusNodes['applicationTitle'],
//               onChanged: (value) {
//                 String? defaultableValue = value;
//                 if (defaultableValue == RESET_TO_ORIGINAL_VALUE) {
//                   defaultableValue = uiControl.originalValue;
//                 }

//                 uiControl.updateEditedValue(defaultableValue);
//                 applicationGetxController.checkIfFormIsDirty();
//                 //printapplicationGetxController.editedData.value);
//               },
//               validator: (value) {
//                 return uiControl.updateValidity().userFeedback;
//               },
//             ),
//           ),
//           const SizedBox(height: 20),
//         ];
//       }
//     } catch (ex) {
//       rethrow;
//     }
//     return <Widget>[Container()]; // should never reach here
//   }

//   List<Widget> buildCheckbox(
//     int tabIndex,
//     String fieldName,
//   ) {
//     try {
//       if (applicationGetxController.uiControls[fieldName] != null) {
//         UiControl uiControl = applicationGetxController.uiControls[fieldName]!;
//         return <Widget>[
//           MouseRegion(
//             onEnter: (event) {
//               applicationGetxController
//                   .setSidebarData(uiControl.sidebarEntryKey);
//             },
//             onExit: (event) {
//               applicationGetxController
//                   .setSidebarData(uiControl.sidebarExitKey);
//             },
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: [
//                 TriStateCheckbox(
//                   tristate: true,
//                   initialValue: uiControl.editedValue == null
//                       ? null
//                       : uiControl.editedValue == '1'
//                           ? true
//                           : false,
//                   onChanged: (value) {
//                     uiControl.updateEditedValue(value == null
//                         ? null
//                         : value
//                             ? '1'
//                             : '0');
//                     applicationGetxController.checkIfFormIsDirty();
//                     //printapplicationGetxController.editedData.value);
//                   },
//                 ),
//                 Text(uiControl.label, style: bodyStyleBlack)
//               ],
//             ),
//           ),
//           const SizedBox(height: 20),
//         ];
//       }
//     } catch (ex) {
//       rethrow;
//     }
//     return <Widget>[Container()]; // should never reach here
//   }

//   List<Widget> buildDocumentManagerField(
//     int tabIndex,
//     String fieldName, {
//     required Function onUploadComplete,
//     required Function onRemoveDocument,
//     String? defaultImageAsset,
//     double? height,
//     double? width,
//   }) {
//     applicationGetxController.uploading[fieldName] ??= false.obs;

//     try {
//       if (applicationGetxController.uiControls[fieldName] != null) {
//         UiControl uiControl = applicationGetxController.uiControls[fieldName]!;

//         bool isImageUpload =
//             (uiControl.controlType == UiControlType.imageUpload);

//         String documentTypeName = uiControl.fileType.fullName;

//         return <Widget>[
//           MouseRegion(
//             onEnter: (event) {
//               applicationGetxController
//                   .setSidebarData(uiControl.sidebarEntryKey);
//             },
//             onExit: (event) {
//               applicationGetxController
//                   .setSidebarData(uiControl.sidebarExitKey);
//             },
//             child: Obx(() {
//               return applicationGetxController.uploading[fieldName]!.value
//                   ? Text(
//                       'Uploading $documentTypeName ...',
//                       style: const TextStyle(fontSize: 30),
//                       textAlign: TextAlign.center,
//                     )
//                   : ((uiControl.editedValue != null))
//                       ? Column(children: <Widget>[
//                           isImageUpload
//                               ? Image.network(
//                                   uiControl.editedValue!,
//                                   //scale: 0.2,
//                                   height: height ?? 200,
//                                   width: width ?? 200,
//                                   loadingBuilder: (
//                                     BuildContext context,
//                                     Widget child,
//                                     ImageChunkEvent? loadingProgress,
//                                   ) {
//                                     if (loadingProgress == null) {
//                                       return child;
//                                     }
//                                     return Center(
//                                       child: CircularProgressIndicator(
//                                         value: loadingProgress
//                                                     .expectedTotalBytes !=
//                                                 null
//                                             ? loadingProgress
//                                                     .cumulativeBytesLoaded /
//                                                 loadingProgress
//                                                     .expectedTotalBytes!
//                                             : null,
//                                       ),
//                                     );
//                                   },
//                                 )
//                               : Image.asset(
//                                   uiControl.fileType.documentPresentAsset,
//                                   width: width ?? 90,
//                                   height: height ?? 110,
//                                 ),
//                           const SizedBox(height: 20),
//                           ElevatedButton(
//                             style: defaultButtonStyle,
//                             onPressed: () {
//                               applicationGetxController
//                                   .uploading[fieldName]!.value = true;
//                               onRemoveDocument();
//                               applicationGetxController
//                                   .checkUiControlValidationStates();
//                               applicationGetxController
//                                   .uploading[fieldName]!.value = false;
//                             },
//                             child: Text(
//                               'Remove $documentTypeName',
//                               style: buttonLabelStyleMedium,
//                             ),
//                           ),
//                         ])
//                       : Column(
//                           children: <Widget>[
//                             Image.asset(
//                               defaultImageAsset ??
//                                   uiControl.fileType.documentNotPresentAsset,
//                               width: width ?? 90,
//                               height: width ?? 110,
//                             ),
//                             const SizedBox(height: 20),
//                             _getUploadButton(
//                               uiControl,
//                               fieldName,
//                               isImageUpload
//                                   ? [
//                                       'png',
//                                       'tga',
//                                       'gif',
//                                       'bmp',
//                                       'ico',
//                                       'webp',
//                                       'psd',
//                                       'pvr',
//                                       'tif',
//                                       'tiff',
//                                       'jpg',
//                                       'jpeg'
//                                     ]
//                                   : ['pdf'],
//                               applicationGetxController
//                                   .editedData.value!.applicationPublicId
//                                   .toString(),
//                               onUploadComplete: (String fileName) {
//                                 onUploadComplete(fileName);
//                               },
//                             ),
//                           ],
//                         );
//             }),
//           ),
//           const SizedBox(height: 20),
//         ];
//       }
//     } catch (ex) {
//       //print'document exception = ${ex}');
//       rethrow;
//     }
//     //print'Did not find $fieldName');
//     return <Widget>[
//       Container(color: Colors.red, width: 50, height: 50)
//     ]; // should never reach here
//   }

//   Widget _getUploadButton(
//     UiControl uiControl,
//     String fieldName,
//     List<String> allowedExtensions,
//     String recordId, {
//     required Function onUploadComplete,
//   }) {
//     return ElevatedButton(
//       style: defaultButtonStyle,
//       onPressed: () async {
//         final result = await FilePicker.platform.pickFiles(
//           type: FileType.custom,
//           allowedExtensions: allowedExtensions,
//           onFileLoading: (p0) {
//             applicationGetxController.uploading[fieldName]!.value = true;
//           },
//         );
//         if (result == null) {
//           // request was cancelled, don't take any action
//         } else if (result.files.first.bytes == null) {
//           await Utilities.showAlert(
//             'File error',
//             'There was an unknown error with the file upload. Please try uploading another file.',
//             'OK',
//           );
//         } else {
//           if ((result.files.first.bytes?.length ?? 3145728) >= 3145728) {
//             await Utilities.showAlert(
//               'File too large',
//               'Please select a file that is smaller than 3Mb',
//               'OK',
//             );
//             result.files.clear();
//           } else {
//             applicationGetxController.uploading[fieldName]!.value = true;

//             final fileBytes8 = result.files.first.bytes!;
//             var fileBytes = List<int>.from(fileBytes8);

//             final fileExtension =
//                 (result.files.first.extension ?? '').toLowerCase();

//             var doProcess = true;

//             if (uiControl.controlType == UiControlType.imageUpload) {
//               // if it's not a JPG / JPEG, convert it to one
//               if ((fileExtension != 'jpg') && (fileExtension != 'jpeg')) {
//                 if ((fileExtension == 'png') ||
//                     (fileExtension == 'tga') ||
//                     (fileExtension == 'gif') ||
//                     (fileExtension == 'bmp') ||
//                     (fileExtension == 'ico') ||
//                     (fileExtension == 'webp') ||
//                     (fileExtension == 'psd') ||
//                     (fileExtension == 'webp') ||
//                     (fileExtension == 'pvr') ||
//                     (fileExtension == 'tif') ||
//                     (fileExtension == 'tiff')) {
//                   try {
//                     final img =
//                         image.decodeImage(Uint8List.fromList(fileBytes));
//                     if (img != null) {
//                       fileBytes = image.encodeJpg(img);
//                     }
//                   } catch (e) {
//                     doProcess = false;
//                     await Utilities.showAlert(
//                       'Error processing image',
//                       'Harrier Central is unable to upload "$fileExtension" files. Please select a JPG, PNG, TIFF, BMP or PSD file',
//                       'OK',
//                     );
//                   }
//                 } else {
//                   doProcess = false;
//                   await Utilities.showAlert(
//                     'Error processing image',
//                     'Harrier Central is unable to upload "$fileExtension" files. Please select a JPG, PNG, TIFF, BMP or PSD file',
//                     'OK',
//                   );
//                 }
//               }
//             }

//             if (doProcess && fileBytes.isNotEmpty) {
//               final fileName = await ServiceCommon.uploadFile(
//                   fileBytes,
//                   // applicationGetxController.editedData.value!.applicationPublicId
//                   //     .toString(),
//                   recordId,
//                   uiControl.fileType.name,
//                   uiControl.controlType);
//               if (fileName.isNotEmpty) {
//                 onUploadComplete(fileName);
//                 applicationGetxController.uploading[fieldName]!.value = false;
//               }
//             }
//           }
//         }

//         applicationGetxController.uploading[fieldName]!.value = false;
//         applicationGetxController.checkIfFormIsDirty();
//       },
//       child: Text('Upload ${uiControl.fileType.fullName}',
//           style: const TextStyle(fontSize: 18)),
//     );
//   }
// }
