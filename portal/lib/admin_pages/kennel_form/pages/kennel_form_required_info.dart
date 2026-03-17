// part of '../kennel_form_ui.dart';

// extension RequiredInfo on KennelFormPage {
//   Widget _buildRequiredInfo({required int tabIndex}) {
//     {
//       final isMobileScreen =
//           formController.screenSize.value == EScreenSize.isMobileScreen;

//       return Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Expanded(
//               child: SingleChildScrollView(
//                 child: Column(
//                   children: [
//                     // First row with 3 TextFormFields
//                     // HelperWidgets().categoryLabelWidget('Status'),
//                     // if (isMobileScreen)
//                     //   _buildKennelStatus(tabIndex)
//                     // else
//                     //   Row(
//                     //     children: [
//                     //       Expanded(
//                     //         child: _buildKennelStatus(tabIndex),
//                     //       ),
//                     //       const SizedBox(width: 10),
//                     //       const Expanded(flex: 4, child: SizedBox()),
//                     //     ],
//                     //   ),
//                     // First row with 3 TextFormFields
//                     HelperWidgets().categoryLabelWidget('Basic information'),
//                     // Second row with 2 TextFormFields (2/3 and 1/3 split)
//                     if (isMobileScreen)
//                       Column(
//                         children: [
//                           _buildNameField(tabIndex),
//                           const SizedBox(height: 10),
//                           _buildShortNameField(tabIndex),
//                           const SizedBox(height: 10),
//                           _buildUniqueShortNameField(tabIndex),
//                         ],
//                       )
//                     else
//                       Row(
//                         children: [
//                           Expanded(
//                             flex: 2,
//                             child: _buildNameField(tabIndex),
//                           ),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: _buildShortNameField(tabIndex),
//                           ),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: _buildUniqueShortNameField(tabIndex),
//                           ),
//                         ],
//                       ),
//                     const SizedBox(height: 16),
//                     // Third row with a multi-line TextFormField
//                     _buildDescriptionField(tabIndex),
//                     HelperWidgets().categoryLabelWidget(
//                       'Contact details',
//                       bottomMargin: 15,
//                     ),
//                     _buildKennelAdminField(tabIndex),
//                     HelperWidgets().categoryLabelWidget('Website address'),
//                     if (isMobileScreen)
//                       _buildWebAddressField(tabIndex)
//                     else
//                       Row(
//                         children: [
//                           Expanded(
//                             child: _buildWebAddressField(tabIndex),
//                           ),
//                           const SizedBox(width: 10),
//                           const Expanded(child: SizedBox()),
//                         ],
//                       ),
//                     // First row with 3
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//   }

//   // Widget _buildKennelStatus(int tabIndex) {
//   //   return _buildTextDropdownField(
//   //     label: 'Kennel Status',
//   //     value: _ensureValidInt(formController.kennelStatus, 0, 1),
//   //     focusNode: formController.focusNodes['kennelStatus'],
//   //     items: {
//   //       0: 'Inactive',
//   //       1: 'Active',
//   //     },
//   //     updateValue: (int value) {
//   //       formController
//   //         ..editedData =
//   //             formController.editedData!.copyWith(kennelStatus: value)
//   //         ..checkIfFormIsDirty(tabIndex: tabIndex);
//   //     },
//   //   );
//   // }

//   Widget _buildWebAddressField(int tabIndex) {
//     return _buildTextField(
//       controller: formController.kennelWebsiteUrl,
//       label: 'Website Address',
//       focusNode: formController.focusNodes['kennelWebsiteUrl'],
//       onChanged: (value) {
//         formController.editedData =
//             formController.editedData?.copyWith(kennelWebsiteUrl: value);
//         if (value.length > 100) {
//           formController.kennelWebsiteUrlValid = false;
//         } else {
//           formController.kennelWebsiteUrlValid = true;
//         }
//         formController.checkIfFormIsDirty(tabIndex: tabIndex);
//       },
//       validator: (value) {
//         String? result;
//         if (((value?.length ?? 0) > 100)) {
//           result =
//               'You must provide a website address no more than 100 characters long';
//         }
//         return result;
//       },
//     );
//   }

//   Widget _buildDescriptionField(int tabIndex) {
//     return _buildTextField(
//       controller: formController.kennelDescription,
//       label: 'Description',
//       customStyle: bodyStyleBlack,
//       maxLines: 10,
//       isMultiline: true,
//       inputType: TextInputType.multiline,
//       focusNode: formController.focusNodes['kennelDescription'],
//       onChanged: (value) {
//         formController.editedData =
//             formController.editedData?.copyWith(kennelDescription: value);
//         if ((value.isEmpty) || (value.length < 30) || (value.length > 2000)) {
//           formController.kennelDescriptionValid = false;
//         } else {
//           formController.kennelDescriptionValid = true;
//         }
//         formController.checkIfFormIsDirty(tabIndex: tabIndex);
//       },
//       validator: (value) {
//         //print('field validation called');
//         String? result;
//         if ((value == null) ||
//             (value.isEmpty) ||
//             (value.length < 30) ||
//             (value.length > 2000)) {
//           if ((value == null) || (value.isEmpty) || (value.length < 30)) {
//             result =
//                 'You must provide a Kennel description at least 30 characters long';
//           } else {
//             result =
//                 'You must provide a Kennel description no more than 2000 characters long';
//           }
//         }

//         return result;
//       },
//     );
//   }

//   Widget _buildKennelAdminField(int tabIndex) {
//     return _buildTextField(
//       controller: formController.kennelAdminEmailList,
//       label: 'Admin Email List',
//       customStyle: bodyStyleBlack,
//       maxLines: 2,
//       isMultiline: true,
//       inputType: TextInputType.multiline,
//       focusNode: formController.focusNodes['kennelAdminEmailList'],
//       onChanged: (value) {
//         formController.editedData =
//             formController.editedData?.copyWith(kennelAdminEmailList: value);
//         if ((value.isEmpty) || (value.length < 6) || (value.length > 500)) {
//           formController.kennelAdminEmailListValid = false;
//         } else {
//           formController.kennelAdminEmailListValid = true;
//         }
//         formController.checkIfFormIsDirty(tabIndex: tabIndex);
//       },
//       validator: (value) {
//         //print('field validation called');
//         String? result;
//         if ((value == null) ||
//             (value.isEmpty) ||
//             (value.length < 6) ||
//             (value.length > 500)) {
//           if ((value == null) || (value.isEmpty) || (value.length < 6)) {
//             result =
//                 'You must provide a list of emails at least 6 characters long';
//           } else {
//             result =
//                 'You must provide a list of emails no more than 500 characters long';
//           }
//         }

//         return result;
//       },
//     );
//   }

//   Widget _buildShortNameField(int tabIndex) {
//     return _buildTextField(
//       controller: formController.kennelShortName,
//       label: 'Kennel Abbreviation',
//       focusNode: formController.focusNodes['kennelShortName'],
//       onChanged: (value) {
//         formController.editedData =
//             formController.editedData?.copyWith(kennelShortName: value);
//         if ((value.isEmpty) || (value.length < 3) || (value.length > 10)) {
//           formController.kennelShortNameValid = false;
//         } else {
//           formController.kennelShortNameValid = true;
//         }
//         formController.checkIfFormIsDirty(tabIndex: tabIndex);
//       },
//       validator: (value) {
//         //print('field validation called');
//         String? result;
//         if ((value == null) ||
//             (value.isEmpty) ||
//             (value.length < 3) ||
//             (value.length > 10)) {
//           if ((value == null) || (value.isEmpty) || (value.length < 3)) {
//             result =
//                 'You must provide a Kennel abbreviation at least 3 characters long';
//           } else {
//             result =
//                 'You must provide a Kennel abbreviation no more than 10 characters long';
//           }
//         }

//         return result;
//       },
//     );
//   }

//   Widget _buildUniqueShortNameField(int tabIndex) {
//     return _buildTextField(
//       controller: formController.kennelUniqueShortName,
//       label: 'Kennel Unique Abbreviation',
//       focusNode: formController.focusNodes['kennelUniqueShortName'],
//       onChanged: (value) {
//         formController.editedData =
//             formController.editedData?.copyWith(kennelUniqueShortName: value);
//         if ((value.isEmpty) || (value.length < 3) || (value.length > 10)) {
//           formController.kennelUniqueShortNameValid = false;
//         } else {
//           formController.kennelUniqueShortNameValid = true;
//         }
//         formController.checkIfFormIsDirty(tabIndex: tabIndex);
//       },
//       validator: (value) {
//         //print('field validation called');
//         String? result;
//         if ((value == null) ||
//             (value.isEmpty) ||
//             (value.length < 3) ||
//             (value.length > 10)) {
//           if ((value == null) || (value.isEmpty) || (value.length < 3)) {
//             result =
//                 'You must provide a Kennel abbreviation at least 3 characters long';
//           } else {
//             result =
//                 'You must provide a Kennel abbreviation no more than 10 characters long';
//           }
//         }

//         return result;
//       },
//     );
//   }

//   Widget _buildNameField(int tabIndex) {
//     return _buildTextField(
//       controller: formController.kennelName,
//       label: 'Kennel Name',
//       focusNode: formController.focusNodes['kennelName'],
//       onChanged: (value) {
//         formController.editedData =
//             formController.editedData?.copyWith(kennelName: value);
//         if ((value.isEmpty) || (value.length < 3) || (value.length > 50)) {
//           formController.kennelNameValid = false;
//         } else {
//           formController.kennelNameValid = true;
//         }
//         formController.checkIfFormIsDirty(tabIndex: tabIndex);
//       },
//       validator: (value) {
//         String? result;
//         if ((value == null) ||
//             (value.isEmpty) ||
//             (value.length < 3) ||
//             (value.length > 50)) {
//           if ((value == null) || (value.isEmpty) || (value.length < 3)) {
//             result =
//                 'You must provide a Kennel name at least 3 characters long';
//           } else {
//             result =
//                 'You must provide a Kennel name no more than 50 characters long';
//           }
//         }
//         return result;
//       },
//     );
//   }
// }
