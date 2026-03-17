part of '../application_form_ui.dart';

extension ApplicationProposals on TestFormPage {
  Widget _buildAppProposals({required int tabIndex}) {
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
                    children: [
                      HelperWidgets().categoryLabelWidget('Upload Proposals'),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...buildDocumentManagerField(tabIndex,
                              '${AppTabKeyEnums.tabProposals.key}_quadChart',
                              onUploadComplete: (String fileName) {
                            applicationGetxController
                                .uiControls[
                                    '${AppTabKeyEnums.tabProposals.key}_quadChart']!
                                .editedFieldValue = BASE_UPLOAD_URL + fileName;
                            applicationGetxController.editedData.value =
                                applicationGetxController.editedData.value!.copyWith(
                                    quadChart: PdfDocumentModel(
                                        pdfDocumentPublicId: UuidValue.fromString(
                                            '00000000-0000-0000-0000-000000000000'),
                                        fkApplicationPublicId: UuidValue.fromString(
                                            '00000000-0000-0000-0000-000000000000'),
                                        documentUrl: BASE_UPLOAD_URL + fileName,
                                        documentType: DocumentType.quadChart));
                            applicationGetxController.uiControls[
                                    '${AppTabKeyEnums.tabProposals.key}_quadChart']!
                                .updateValidity();
                          }, onRemoveDocument: () {
                            applicationGetxController
                                .uiControls[
                                    '${AppTabKeyEnums.tabProposals.key}_quadChart']!
                                .editedFieldValue = null;
                            applicationGetxController.editedData.value =
                                applicationGetxController.editedData.value!
                                    .copyWith(quadChart: null);
                            // applicationGetxController.uiControls[
                            //         '${AppTabKeyEnums.tabProposals.key}_quadChart']!
                            //     .updateValidity();
                          }),
                          const SizedBox(
                            width: 30,
                          ),
                          ...buildDocumentManagerField(tabIndex,
                              '${AppTabKeyEnums.tabProposals.key}_proposal',
                              onUploadComplete: (String fileName) {
                            applicationGetxController
                                .uiControls[
                                    '${AppTabKeyEnums.tabProposals.key}_proposal']!
                                .editedFieldValue = BASE_UPLOAD_URL + fileName;
                            applicationGetxController.editedData.value =
                                applicationGetxController.editedData.value!.copyWith(
                                    proposal: PdfDocumentModel(
                                        pdfDocumentPublicId: UuidValue.fromString(
                                            '00000000-0000-0000-0000-000000000000'),
                                        fkApplicationPublicId: UuidValue.fromString(
                                            '00000000-0000-0000-0000-000000000000'),
                                        documentUrl: BASE_UPLOAD_URL + fileName,
                                        documentType: DocumentType.proposal));
                            applicationGetxController.uiControls[
                                    '${AppTabKeyEnums.tabProposals.key}_proposal']!
                                .updateValidity();
                          }, onRemoveDocument: () {
                            applicationGetxController
                                .uiControls[
                                    '${AppTabKeyEnums.tabProposals.key}_proposal']!
                                .editedFieldValue = null;
                            applicationGetxController.editedData.value =
                                applicationGetxController.editedData.value!
                                    .copyWith(proposal: null);
                            applicationGetxController.uiControls[
                                    '${AppTabKeyEnums.tabProposals.key}_proposal']!
                                .updateValidity();
                          })
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
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

// if ((_uploadedImage != '<null>') &&
//               ((_uploadedImage ?? _rdm.eventImage) != null)) ...<Widget>[
//             const SizedBox(height: 30),
//             Expanded(
//               child: _uploadingPhoto
//                   ? const Text(
//                       'Uploading image ...',
//                       style: TextStyle(fontSize: 30),
//                       textAlign: TextAlign.center,
//                     )
//                   : Image.network(
//                       (_uploadedImage ?? _rdm.eventImage)!,
//                       scale: 0.2,
//                       loadingBuilder: (
//                         BuildContext context,
//                         Widget child,
//                         ImageChunkEvent? loadingProgress,
//                       ) {
//                         if (loadingProgress == null) {
//                           return child;
//                         }
//                         return Center(
//                           child: CircularProgressIndicator(
//                             value: loadingProgress.expectedTotalBytes != null
//                                 ? loadingProgress.cumulativeBytesLoaded /
//                                     loadingProgress.expectedTotalBytes!
//                                 : null,
//                           ),
//                         );
//                       },
//                     ),
//             ),
//           ],
//           const SizedBox(height: 20),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: <Widget>[
//               ElevatedButton(
//                 style: ButtonStyle(
//                   backgroundColor:
//                       WidgetStateProperty.all<Color>(Colors.red.shade900),
//                   foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
//                 ),
//                 onPressed: () async {
//                   setState(() {
//                     _uploadedImage = '<null>';
//                   });
//                 },
//                 child:
//                     const Text('Remove Image', style: TextStyle(fontSize: 18)),
//               ),
//               const SizedBox(width: 40),
//               ElevatedButton(
//                 style: ButtonStyle(
//                   backgroundColor:
//                       WidgetStateProperty.all<Color>(Colors.red.shade900),
//                   foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
//                 ),
//                 onPressed: () async {
//                   final result = await FilePicker.platform.pickFiles();
//                   if (result == null) {
//                     // request was cancelled, don't take any action
//                   } else if (result.files.first.bytes == null) {
//                     await IveCoreUtilities.showAlert(
//                       navigatorKey.currentContext!,
//                       'File error',
//                       'There was an unknown error with the file upload. Please try uploading another file.',
//                       'OK',
//                     );
//                   } else {
//                     if ((result.files.first.bytes?.length ?? 3145728) >=
//                         3145728) {
//                       await IveCoreUtilities.showAlert(
//                         navigatorKey.currentContext!,
//                         'File too large',
//                         'Please select a file that is smaller than 3MB',
//                         'OK',
//                       );
//                       result.files.clear();
//                     } else {
//                       setState(() {
//                         _uploadingPhoto = true;
//                       });

//                       final fileBytes8 =
//                           result.files.first.bytes ?? Uint8List(0);
//                       var fileBytes = List<int>.from(fileBytes8);

//                       final fileExtension =
//                           (result.files.first.extension ?? '').toLowerCase();

//                       var doProcess = true;

//                       // if it's not a JPG / JPEG, convert it to one
//                       if ((fileExtension != 'jpg') &&
//                           (fileExtension != 'jpeg')) {
//                         if ((fileExtension == 'png') ||
//                             (fileExtension == 'tga') ||
//                             (fileExtension == 'gif') ||
//                             (fileExtension == 'bmp') ||
//                             (fileExtension == 'ico') ||
//                             (fileExtension == 'webp') ||
//                             (fileExtension == 'psd') ||
//                             (fileExtension == 'webp') ||
//                             (fileExtension == 'pvr') ||
//                             (fileExtension == 'tif') ||
//                             (fileExtension == 'tiff')) {
//                           try {
//                             final img = image
//                                 .decodeImage(Uint8List.fromList(fileBytes));
//                             if (img != null) {
//                               fileBytes = image.encodeJpg(img);
//                             }
//                           } catch (e) {
//                             doProcess = false;
//                             await IveCoreUtilities.showAlert(
//                               navigatorKey.currentContext!,
//                               'Error processing image',
//                               'Harrier Central is unable to upload "$fileExtension" files. Please select a JPG, PNG, TIFF, BMP or PSD file',
//                               'OK',
//                             );
//                           }
//                         } else {
//                           doProcess = false;
//                           await IveCoreUtilities.showAlert(
//                             navigatorKey.currentContext!,
//                             'Error processing image',
//                             'Harrier Central is unable to upload "$fileExtension" files. Please select a JPG, PNG, TIFF, BMP or PSD file',
//                             'OK',
//                           );
//                         }
//                       }

//                       if (doProcess && fileBytes.isNotEmpty) {
//                         final filename = await _upload(
//                           fileBytes,
//                           _rdm.publicEventId ?? _rdm.publicKennelId,
//                         );
//                         if (filename.isNotEmpty) {
//                           setState(() {
//                             _uploadedImage = BASE_EVENT_IMAGE_URL + filename;
//                           });
//                         }
//                       }
//                     }
//                   }

//                   setState(() {
//                     _uploadingPhoto = false;
//                   });
//                 },
//                 child:
//                     const Text('Select Image', style: TextStyle(fontSize: 18)),
//               ),
//             ],
//           ),
//         ],
