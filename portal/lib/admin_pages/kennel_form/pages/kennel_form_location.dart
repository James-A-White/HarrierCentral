// part of '../kennel_form_ui.dart';

// extension Location on KennelFormPage {
//   Widget _buildLocation({required int tabIndex}) {
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
//                       HelperWidgets().categoryLabelWidget(
//                         'Kennel City, State / Region, and Country (read only)',
//                       ),
//                       if (isSmallScreen)
//                         Column(
//                           children: [
//                             _buildCityField(),
//                             const SizedBox(height: 10),
//                             _buildRegionField(),
//                             const SizedBox(height: 10),
//                             _buildCountryField(),
//                           ],
//                         )
//                       else
//                         Row(
//                           children: [
//                             Expanded(
//                               child: _buildCityField(),
//                             ),
//                             const SizedBox(width: 10),
//                             Expanded(
//                               child: _buildRegionField(),
//                             ),
//                             const SizedBox(width: 10),
//                             Expanded(
//                               child: _buildCountryField(),
//                             ),
//                           ],
//                         ),
//                       const SizedBox(height: 16),

//                       HelperWidgets().categoryLabelWidget('Kennel geolocation'),
//                       if (isSmallScreen)
//                         Column(
//                           children: [
//                             _buildLatitudeField(tabIndex),
//                             const SizedBox(height: 10),
//                             _buildLongitudeField(tabIndex),
//                           ],
//                         )
//                       else
//                         Row(
//                           children: [
//                             Expanded(
//                               child: _buildLatitudeField(tabIndex),
//                             ),
//                             const SizedBox(width: 10),
//                             Expanded(
//                               child: _buildLongitudeField(tabIndex),
//                             ),
//                           ],
//                         ),
//                       const SizedBox(height: 16),

//                       HelperWidgets().categoryLabelWidget('Units of Measure'),
//                       // Second row with 2 TextFormFields (2/3 and 1/3 split)
//                       if (isSmallScreen)
//                         _buildDistancePreference(tabIndex)
//                       else
//                         Row(
//                           children: [
//                             Expanded(
//                               child: _buildDistancePreference(tabIndex),
//                             ),
//                             Expanded(
//                               flex: 2,
//                               child: Container(),
//                             ),
//                           ],
//                         ),
//                       HelperWidgets().categoryLabelWidget('Kennel Pin Color'),
//                       // Second row with 2 TextFormFields (2/3 and 1/3 split)
//                       if (isSmallScreen)
//                         _buildMapPinSelector(tabIndex)
//                       else
//                         Row(
//                           children: [
//                             Expanded(
//                               child: _buildMapPinSelector(tabIndex),
//                             ),
//                             Expanded(
//                               flex: 2,
//                               child: Container(),
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

//   Widget _buildMapPinSelector(int tabIndex) {
//     return _buildImageDropdownField(
//       label: 'Kennel Pin Color',
//       value: _ensureValidInt(formController.kennelPinColor, 0, 8),
//       focusNode: formController.focusNodes['kennelPinColor'],
//       height: 45,
//       width: 45,
//       items: {
//         0: 'Red',
//         1: 'Orange', //'🟧 Orange',
//         2: 'Yellow', //'🟨 Yellow',
//         3: 'Green', //'🟩 Green',
//         4: 'Teal', //'Teal',
//         5: 'Baby_blue', //'🩵 Baby Blue',
//         6: 'Blue', //'🟦 Blue',
//         7: 'Purple', //'🟪 Purple',
//         8: 'Pink', //'🩷 Pink',
//       },
//       updateValue: (int value) {
//         formController
//           ..editedData =
//               formController.editedData!.copyWith(kennelPinColor: value)
//           ..checkIfFormIsDirty(tabIndex: tabIndex);
//       },
//     );
//   }

//   Widget _buildDistancePreference(int tabIndex) {
//     return _buildTextDropdownField(
//       label: 'Distance preference',
//       value: _ensureValidInt(formController.distancePreference, -1, 1),
//       focusNode: formController.focusNodes['distancePreference'],
//       items: {
//         0: 'Kilometers',
//         1: 'Miles',
//         -1: 'Default for country',
//       },
//       updateValue: (int value) {
//         formController
//           ..editedData =
//               formController.editedData!.copyWith(distancePreference: value)
//           ..checkIfFormIsDirty(tabIndex: tabIndex);
//       },
//     );
//   }

//   Widget _buildCityField() {
//     return _buildTextField(
//       controller: formController.cityName,
//       label: 'City',
//       readOnly: true,
//       focusNode: formController.focusNodes['cityName'],
//       onChanged: (value) {
//         // formController.editedData =
//         //     formController.editedData?.copyWith(cityName: value);
//         // if (value.length > 250) {
//         //   formController.kennelWebsiteUrlValid = false;
//         // } else {
//         //   formController.kennelWebsiteUrlValid = true;
//         // }
//         // formController.checkIfFormIsDirty(tabIndex: 0);
//       },
//       // validator: (value) {
//       //   String? result;
//       //   if (((value?.length ?? 0) > 250)) {
//       //     result =
//       //         'You must provide a website address no more than 250 characters long';
//       //   }
//       //   return result;
//       // },
//     );
//   }

//   Widget _buildLatitudeField(int tabIndex) {
//     return _buildDoubleFieldWithLookthrough(
//       fieldName: 'kennelLatitude',
//       label: '${initialData.kennelName} latitude',
//       defaultLabel: '${initialData.cityName} latitude',
//       value: formController.latitude,
//       width: 270,
//       defaultValue: formController.defaultLatitude,
//       overrideDefault: formController.overrideDefaultLatitude,
//       onChanged: (value) {
//         if (value == null) {
//           formController
//             ..latitude = null.obs
//             ..editedData = formController.editedData?.copyWith(latitude: null);
//         } else {
//           final val = double.tryParse(value) ?? 0.0;
//           formController
//             ..latitude = val.obs
//             ..editedData = formController.editedData?.copyWith(latitude: val);
//         }

//         final result = _validateLatLong(
//           label: 'Latitude',
//           value: value,
//           lowerBound: -90,
//           upperBound: 90,
//         );

//         formController
//           ..kennelLatitudeValid = (result == null)
//           ..checkIfFormIsDirty(tabIndex: tabIndex);
//       },
//       validator: (value) {
//         return _validateLatLong(
//           label: 'Latitude',
//           value: value,
//           lowerBound: -90,
//           upperBound: 90,
//         );
//       },
//     );
//   }

//   Widget _buildLongitudeField(int tabIndex) {
//     return _buildDoubleFieldWithLookthrough(
//       fieldName: 'kennelLongitude',
//       label: '${initialData.kennelName} longitude',
//       defaultLabel: '${initialData.cityName} longitude',
//       value: formController.longitude,
//       defaultValue: formController.defaultLongitude,
//       width: 270,
//       overrideDefault: formController.overrideDefaultLongitude,
//       onChanged: (value) {
//         if (value == null) {
//           formController
//             ..longitude = null.obs
//             ..editedData = formController.editedData?.copyWith(longitude: null);
//         } else {
//           final val = double.tryParse(value) ?? 0.0;
//           formController
//             ..longitude = val.obs
//             ..editedData = formController.editedData?.copyWith(longitude: val);
//         }

//         final result = _validateLatLong(
//           label: 'Longitude',
//           value: value,
//           lowerBound: -180,
//           upperBound: 180,
//         );

//         formController
//           ..kennelLongitudeValid = (result == null)
//           ..checkIfFormIsDirty(tabIndex: tabIndex);
//       },
//       validator: (value) {
//         return _validateLatLong(
//           label: 'Longitude',
//           value: value,
//           lowerBound: -180,
//           upperBound: 180,
//         );
//       },
//     );
//   }

//   Widget _buildRegionField() {
//     return _buildTextField(
//       controller: formController.regionName,
//       label: 'State / Region',
//       readOnly: true,
//       focusNode: formController.focusNodes['regionName'],
//       onChanged: (value) {
//         // formController.editedData =
//         //     formController.editedData?.copyWith(cityName: value);
//         // if (value.length > 270) {
//         //   formController.kennelWebsiteUrlValid = false;
//         // } else {
//         //   formController.kennelWebsiteUrlValid = true;
//         // }
//         // formController.checkIfFormIsDirty(tabIndex: 0);
//       },
//       // validator: (value) {
//       //   String? result;
//       //   if (((value?.length ?? 0) > 250)) {
//       //     result =
//       //         'You must provide a website address no more than 250 characters long';
//       //   }
//       //   return result;
//       // },
//     );
//   }

//   Widget _buildCountryField() {
//     return _buildTextField(
//       controller: formController.countryName,
//       label: 'Country',
//       readOnly: true,
//       focusNode: formController.focusNodes['countryName'],
//       onChanged: (value) {
//         // formController.editedData =
//         //     formController.editedData?.copyWith(cityName: value);
//         // if (value.length > 250) {
//         //   formController.kennelWebsiteUrlValid = false;
//         // } else {
//         //   formController.kennelWebsiteUrlValid = true;
//         // }
//         // formController.checkIfFormIsDirty(tabIndex: 0);
//       },
//       // validator: (value) {
//       //   String? result;
//       //   if (((value?.length ?? 0) > 250)) {
//       //     result =
//       //         'You must provide a website address no more than 250 characters long';
//       //   }
//       //   return result;
//       // },
//     );
//   }
// }
