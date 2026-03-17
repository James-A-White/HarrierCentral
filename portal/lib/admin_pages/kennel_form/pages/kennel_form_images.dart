// part of '../kennel_form_ui.dart';

// extension Images on KennelFormPage {
//   // ignore: unused_element
//   Widget _buildImages({required int tabIndex}) {
//     {
//       final isSmallScreen = Get.mediaQuery.size.width < 600;

//       return Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Expanded(
//               child: SingleChildScrollView(
//                 child: Column(
//                   children: [
//                     // First row with 3 TextFormFields
//                     if (isSmallScreen)
//                       Column(
//                         children: [
//                           _buildTextField(
//                             controller: formController.cityName,
//                             label: 'Field 1',
//                           ),
//                           const SizedBox(height: 10),
//                           _buildTextField(
//                             controller: formController.cityName,
//                             label: 'Field 2',
//                           ),
//                           const SizedBox(height: 10),
//                           _buildTextField(
//                             controller: formController.cityName,
//                             label: 'Field 3',
//                           ),
//                         ],
//                       )
//                     else
//                       Row(
//                         children: [
//                           Expanded(
//                             child: _buildTextField(
//                               controller: formController.cityName,
//                               label: 'Field 1',
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: _buildTextField(
//                               controller: formController.cityName,
//                               label: 'Field 2',
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: _buildTextField(
//                               controller: formController.cityName,
//                               label: 'Field 3',
//                             ),
//                           ),
//                         ],
//                       ),
//                     const SizedBox(height: 16),
//                     // Second row with 2 TextFormFields (2/3 and 1/3 split)
//                     if (isSmallScreen)
//                       Column(
//                         children: [
//                           _buildTextField(
//                             controller: formController.cityName,
//                             label: 'Field 4',
//                           ),
//                           const SizedBox(height: 10),
//                           _buildTextField(
//                             controller: formController.cityName,
//                             label: 'Field 5',
//                           ),
//                         ],
//                       )
//                     else
//                       Row(
//                         children: [
//                           Expanded(
//                             flex: 2,
//                             child: _buildTextField(
//                               controller: formController.cityName,
//                               label: 'Field 4',
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: _buildTextField(
//                               controller: formController.cityName,
//                               label: 'Field 5',
//                             ),
//                           ),
//                         ],
//                       ),
//                     const SizedBox(height: 16),
//                     // Third row with a multi-line TextFormField
//                     _buildTextField(
//                       controller: formController.cityName,
//                       label: 'Description',
//                       maxLines: 5,
//                       isMultiline: true,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             // Save Button
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: formController.save,
//               child: const Text('Save'),
//             ),
//           ],
//         ),
//       );
//     }
//   }
// }
