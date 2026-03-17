part of '../application_form_ui.dart';

extension ApplicationSubmission on TestFormPage {
  Icon _getStatusIcon(String key) {
    IconData icon = FontAwesome.question;
    Color color = Colors.grey;
    double size = 25;

    UiControlDefinition? control = applicationGetxController.uiControls[key];
    if (control == null) {
      return Icon(Entypo.dot_single, size: size, color: Colors.transparent);
    }

    switch (control.controlValidity.validity) {
      case ControlValidity.validEmpty:
        icon = Entypo.check;
        color = Colors.grey.shade300;
        break;
      case ControlValidity.valid:
        icon = Entypo.check;
        color = Colors.green.shade700;
        break;
      case ControlValidity.invalid:
        icon = Entypo.cross;
        color = Colors.red.shade700;
        break;
      case ControlValidity.invalidEmpty:
        icon = Entypo.cross;
        color = Colors.red.shade700;
        break;
      case ControlValidity.unknown:
        icon = FontAwesome.question;
        color = Colors.red.shade700;
        break;
    }
    return Icon(icon, color: color, size: size);
  }

  List<Widget> _getValidityIndicatorWidgets() {
    List<String> sortedKeys =
        (applicationGetxController.uiControls.entries.toList()
              ..sort((a, b) => a.value.label.compareTo(b.value.label)))
            .map((entry) => entry.key)
            .toList();

    List<Widget> widgets = [];

    applicationGetxController.checkUiControlValidationStates();

    for (var tabDefinition in AppTabKeyEnums.values) {
      if (!tabDefinition.showTabInSubmitSummary) {
        continue;
      }
      widgets.add(
        HelperWidgets().categoryLabelWidget('Tab: ${tabDefinition.title}'),
      );
      for (var key in sortedKeys) {
        UiControlDefinition? control =
            applicationGetxController.uiControls[key];
        if ((control != null) && (control.tabIndex == tabDefinition.idx)) {
          widgets.add(
            Row(
              children: [
                const SizedBox(
                  width: 40,
                ),
                _getStatusIcon(key),
                const SizedBox(
                  width: 20,
                ),
                Text(control.label, style: headingStyleBlack),
                control.controlValidity.controlIsValid
                    ? Container()
                    : Text('  (${control.controlValidity.userFeedback})',
                        style: footnoteMediumRed),
              ],
            ),
          );
        }
      }
    }

    return widgets;
  }

  Widget _buildAppSubmission({required int tabIndex}) {
    {
      return GetBuilder<ApplicationFormController>(
          id: 'tabIcons',
          builder: (controller) {
            // for (var control in applicationGetxController.uiControls.values) {
            //   ControlValidity validity = control.updateValidity().validity;
            //   if ((validity == ControlValidity.invalid) ||
            //       (validity == ControlValidity.invalidEmpty)) {
            //     isSubmittable = false;
            //     break;
            //   }
            // }

            bool isSubmittable = (applicationGetxController
                .editedData.value!.applicationIsSubmitable);

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  applicationGetxController.originalData.isSubmitted == '1'
                      ? Column(
                          children: [
                            Text(
                              '🎉 Congratulations! Your application has been submitted 🎉',
                              style: titleStyleBlack,
                            ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.center,
                              child: ElevatedButton(
                                style: defaultButtonStyle,
                                onPressed: applicationGetxController.recall,
                                child: Text('Recall Submission',
                                    style: buttonLabelStyleMedium),
                              ),
                            ),
                          ],
                        )
                      : Align(
                          alignment: Alignment.center,
                          child: Container(
                            height: isSubmittable ? 65 : null,
                            width: isSubmittable ? 200 : null,
                            child: ElevatedButton(
                              style: !isSubmittable
                                  ? null
                                  : defaultButtonStyle.copyWith(
                                      backgroundColor:
                                          WidgetStateProperty.all<Color>(
                                              Colors.green.shade800)),
                              onPressed: isSubmittable
                                  ? applicationGetxController.submit
                                  : null,
                              child: Text(
                                'Submit',
                                style: !isSubmittable
                                    ? buttonLabelStyleMedium
                                    : buttonLabelStyleMedium.copyWith(
                                        fontSize: 32,
                                      ),
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(height: 20),
                  const Divider(
                    height: 6,
                    thickness: 2,
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Lockable(
                        lockState:
                            applicationGetxController.tabLocked[tabIndex],
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            ..._getValidityIndicatorWidgets(),
                            const SizedBox(height: 70),
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
                    ],
                  ),
                ],
              ),
            );
          });
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
