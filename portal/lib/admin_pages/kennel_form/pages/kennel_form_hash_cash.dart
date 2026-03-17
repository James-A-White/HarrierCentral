// part of '../kennel_form_ui.dart';

// extension HashCash on KennelFormPage {
//   Widget _buildHashCash({required int tabIndex}) {
//     {
//       {
//         final isSmallScreen = Get.mediaQuery.size.width < 600;

//         return Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             children: [
//               Expanded(
//                 child: SingleChildScrollView(
//                   child: Column(
//                     children: [
//                       // First row with 3 TextFormFields
//                       HelperWidgets().categoryLabelWidget('Hash Cash'),
//                       if (isSmallScreen)
//                         Column(
//                           children: [
//                             _buildMemberHashCash(tabIndex),
//                             const SizedBox(height: 10),
//                             _buildNonMemberHashCash(tabIndex),
//                           ],
//                         )
//                       else
//                         Row(
//                           children: [
//                             Expanded(
//                               child: _buildMemberHashCash(tabIndex),
//                             ),
//                             const SizedBox(width: 10),
//                             Expanded(
//                               child: _buildNonMemberHashCash(tabIndex),
//                             ),
//                           ],
//                         ),
//                       HelperWidgets().categoryLabelWidget('Payment Settings'),
//                       if (isSmallScreen)
//                         Column(
//                           children: [
//                             _buildAllowNegativeCredit(tabIndex),
//                             const SizedBox(height: 10),
//                             _buildUserCanSelfPay(tabIndex),
//                           ],
//                         )
//                       else
//                         Row(
//                           children: [
//                             Expanded(
//                               child: _buildAllowNegativeCredit(tabIndex),
//                             ),
//                             const SizedBox(width: 10),
//                             Expanded(
//                               child: _buildUserCanSelfPay(tabIndex),
//                             ),
//                           ],
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
//               // Save Button
//             ],
//           ),
//         );
//       }
//     }
//   }

//   Widget _buildAllowNegativeCredit(int tabIndex) {
//     return Obx(
//       () => SwitchListTile(
//         title: Text('Allow negative credit', style: bodyStyleBlack),
//         value: formController.allowNegativeCredit.value,
//         onChanged: (val) {
//           formController.allowNegativeCredit.value = val;
//           formController
//             ..editedData = formController.editedData
//                 ?.copyWith(allowNegativeCredit: val ? 1 : 0)
//             ..checkIfFormIsDirty();
//         },
//       ),
//     );
//   }

//   Widget _buildUserCanSelfPay(int tabIndex) {
//     return Obx(
//       () => SwitchListTile(
//         title:
//             Text('Hasher can mark themselves as paid', style: bodyStyleBlack),
//         value: formController.allowSelfPayment.value,
//         onChanged: (val) {
//           formController.allowSelfPayment.value = val;
//           formController
//             ..editedData = formController.editedData
//                 ?.copyWith(allowSelfPayment: val ? 1 : 0)
//             ..checkIfFormIsDirty();
//         },
//       ),
//     );
//   }

//   Widget _buildMemberHashCash(int tabIndex) {
//     return _buildDoubleField(
//       label: 'Default Event Price for Members',
//       value: formController.defaultEventPriceForMembers,
//       controller: formController.defaultEventPriceForMembersController,
//       focusNode: formController.focusNodes['defaultEventPriceForMembers'],
//       onChanged: (value) {
//         final price = double.tryParse(value) ?? 0.0;
//         formController.defaultEventPriceForMembers.value = price;
//         formController.editedData = formController.editedData
//             ?.copyWith(defaultEventPriceForMembers: price);

//         final result = _validateDouble(
//           label: 'Hash cash',
//           value: value,
//           lowerBound: 0,
//           upperBound: 100000,
//         );

//         formController
//           ..defaultEventPriceForMembersValid = (result == null)
//           ..checkIfFormIsDirty(tabIndex: tabIndex);
//       },
//       validator: (value) {
//         return _validateDouble(
//           label: 'Hash cash',
//           value: value,
//           lowerBound: 0,
//           upperBound: 100000,
//         );
//       },
//     );
//   }

//   Widget _buildNonMemberHashCash(int tabIndex) {
//     return _buildDoubleField(
//       label: 'Default Event Price for Non-members',
//       value: formController.defaultEventPriceForNonMembers,
//       controller: formController.defaultEventPriceForNonMembersController,
//       focusNode: formController.focusNodes['defaultEventPriceForNonMembers'],
//       onChanged: (value) {
//         final price = double.tryParse(value) ?? 0.0;
//         formController.defaultEventPriceForNonMembers.value = price;
//         formController.editedData = formController.editedData
//             ?.copyWith(defaultEventPriceForNonMembers: price);

//         final result = _validateDouble(
//           label: 'Hash cash',
//           value: value,
//           lowerBound: 0,
//           upperBound: 100000,
//         );

//         formController
//           ..defaultEventPriceForNonMembersValid = (result == null)
//           ..checkIfFormIsDirty(tabIndex: tabIndex);
//       },
//       validator: (value) {
//         return _validateDouble(
//           label: 'Hash cash',
//           value: value,
//           lowerBound: 0,
//           upperBound: 100000,
//         );
//       },
//     );
//   }
// }
