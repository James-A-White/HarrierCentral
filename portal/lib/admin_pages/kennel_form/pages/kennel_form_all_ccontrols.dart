// part of '../kennel_form_ui.dart';

// extension AllControls on KennelFormPage {
//   // ignore: unused_element
//   Widget _buildAll({required int tabIndex}) {
//     return Scrollbar(
//       controller: formController.allFieldsTabScrollController,
//       trackVisibility: false,
//       thumbVisibility: false,
//       interactive: true,
//       thickness: 15,
//       child: ListView(
//         controller: formController.allFieldsTabScrollController,
//         children: <Widget>[
//           KeepAliveWrapper(
//             child: TextFormField(
//               style: bodyStyleBlack,
//               decoration: InputDecoration(
//                 labelText: 'Kennel Name',
//                 labelStyle: bodyStyleBlack,
//                 hintStyle: formHintStyle,
//               ),
//               autovalidateMode: AutovalidateMode.onUserInteraction,
//               controller: formController.kennelName,
//               focusNode: formController.focusNodes['kennelName'],
//               onChanged: (value) {
//                 formController.editedData =
//                     formController.editedData?.copyWith(kennelName: value);
//                 if ((value.isEmpty) ||
//                     (value.length < 3) ||
//                     (value.length > 50)) {
//                   formController.kennelNameValid = false;
//                 } else {
//                   formController.kennelNameValid = true;
//                 }
//                 formController.checkIfFormIsDirty(tabIndex: tabIndex);
//               },
//               validator: (value) {
//                 String? result;
//                 if ((value == null) ||
//                     (value.isEmpty) ||
//                     (value.length < 3) ||
//                     (value.length > 50)) {
//                   if ((value == null) ||
//                       (value.isEmpty) ||
//                       (value.length < 3)) {
//                     result =
//                         'You must provide a Kennel name at least 3 characters long';
//                   } else {
//                     result =
//                         'You must provide a Kennel name no more than 50 characters long';
//                   }
//                 }
//                 return result;
//               },
//             ),
//           ),
//           KeepAliveWrapper(
//             child: TextFormField(
//               style: bodyStyleBlack,
//               decoration: InputDecoration(
//                 labelText: 'Kennel Short Name',
//                 labelStyle: bodyStyleBlack,
//                 hintStyle: formHintStyle,
//               ),
//               autovalidateMode: AutovalidateMode.onUserInteraction,
//               focusNode: formController.focusNodes['kennelShortName'],
//               controller: formController.kennelShortName,
//               onChanged: (value) {
//                 formController.editedData =
//                     formController.editedData?.copyWith(kennelShortName: value);
//                 if ((value.isEmpty) ||
//                     (value.length < 3) ||
//                     (value.length > 10)) {
//                   formController.kennelShortNameValid = false;
//                 } else {
//                   formController.kennelShortNameValid = true;
//                 }
//                 formController.checkIfFormIsDirty(tabIndex: tabIndex);
//               },
//               validator: (value) {
//                 //print('field validation called');
//                 String? result;
//                 if ((value == null) ||
//                     (value.isEmpty) ||
//                     (value.length < 3) ||
//                     (value.length > 10)) {
//                   if ((value == null) ||
//                       (value.isEmpty) ||
//                       (value.length < 3)) {
//                     result =
//                         'You must provide a Kennel short name at least 3 characters long';
//                   } else {
//                     result =
//                         'You must provide a Kennel short name no more than 9 characters long';
//                   }
//                 }

//                 return result;
//               },
//             ),
//           ),
//           // Text fields for latitude, longitude, price, etc.
//           // _buildDoubleFieldWithLookthrough(
//           //   fieldName: 'latitude',
//           //   label: '${widget.initialData?.kennelName ?? 'Kennel'} latitude',
//           //   defaultLabel:
//           //       '${widget.initialData?.cityName ?? 'City'} latitude',
//           //   value: formController.latitude,
//           //   defaultValue: formController.defaultLatitude,
//           //   overrideDefault: formController.overrideDefaultLatitude,
//           //   onChanged: (value) {
//           //     if (value == null) {
//           //       formController.latitude = null.obs;
//           //       formController.editedData =
//           //           formController.editedData?.copyWith(latitude: null);
//           //     } else {
//           //       double val = double.tryParse(value) ?? 0.0;
//           //       formController.latitude = val.toDouble().obs;
//           //       formController.editedData = formController.editedData
//           //           ?.copyWith(latitude: val.toDouble());
//           //     }
//           //     formController.checkIfFormIsDirty();
//           //   },
//           // ),

//           // _buildDoubleFieldWithLookthrough(
//           //   fieldName: 'longitude',
//           //   label: '${widget.initialData?.kennelName ?? 'Kennel'} longitude',
//           //   defaultLabel:
//           //       '${widget.initialData?.cityName ?? 'City'} longitude',
//           //   value: formController.longitude,
//           //   defaultValue: formController.defaultLongitude,
//           //   overrideDefault: formController.overrideDefaultLongitude,
//           //   onChanged: (value) {
//           //     if (value == null) {
//           //       formController.longitude = null.obs;
//           //       formController.editedData =
//           //           formController.editedData?.copyWith(longitude: null);
//           //     } else {
//           //       double val = double.tryParse(value) ?? 0.0;
//           //       formController.longitude = val.toDouble().obs;
//           //       formController.editedData = formController.editedData
//           //           ?.copyWith(longitude: val.toDouble());
//           //     }
//           //     formController.checkIfFormIsDirty();
//           //   },
//           // ),

//           RunTagsUiPage(
//             runTags1: formController.editedData?.defaultRunTags1 ?? 0,
//             runTags2: formController.editedData?.defaultRunTags2 ?? 0,
//             runTags3: formController.editedData?.defaultRunTags3 ?? 0,
//             tagsChanged: (int tags1, int tags2, int tags3) {
//               formController
//                 ..editedData = formController.editedData?.copyWith(
//                   defaultRunTags1: tags1,
//                   defaultRunTags2: tags2,
//                   defaultRunTags3: tags3,
//                 )
//                 ..checkIfFormIsDirty();
//             },
//           ),

//           VisibilityUiPage(
//             visibilityTags1:
//                 formController.editedData?.disseminationAudience ?? 0,
//             tagsChanged: (int tags1) {
//               formController
//                 ..editedData = formController.editedData?.copyWith(
//                   disseminationAudience: tags1,
//                 )
//                 ..checkIfFormIsDirty();
//             },
//           ),

//           TextFormField(
//             style: bodyStyleBlack,
//             decoration: InputDecoration(
//               labelText: 'Kennel Logo',
//               labelStyle: bodyStyleBlack,
//               hintStyle: formHintStyle,
//             ),
//             autovalidateMode: AutovalidateMode.onUserInteraction,
//             controller: formController.kennelLogo,
//             onChanged: (value) {
//               formController
//                 ..editedData =
//                     formController.editedData?.copyWith(kennelLogo: value)
//                 ..checkIfFormIsDirty();
//             },
//           ),
//           TextFormField(
//             style: bodyStyleBlack,
//             decoration: InputDecoration(
//               labelText: 'Kennel Description',
//               labelStyle: bodyStyleBlack,
//               hintStyle: formHintStyle,
//             ),
//             autovalidateMode: AutovalidateMode.onUserInteraction,
//             controller: formController.kennelDescription,
//             onChanged: (value) {
//               formController
//                 ..editedData = formController.editedData
//                     ?.copyWith(kennelDescription: value)
//                 ..checkIfFormIsDirty();
//             },
//             validator: (value) {
//               if ((value == null) || (value.isEmpty)) {
//                 return 'You must provide a Kennel description';
//               }
//               return null;
//             },
//           ),
//           TextFormField(
//             style: bodyStyleBlack,
//             decoration: InputDecoration(
//               labelText: 'City Name',
//               labelStyle: bodyStyleBlack,
//               hintStyle: formHintStyle,
//             ),
//             autovalidateMode: AutovalidateMode.onUserInteraction,
//             controller: formController.cityName,
//             readOnly: true,
//             // onChanged: (value) {
//             //   formController.editedData = formController.editedData?.copyWith(cityName: value);
//             //   formController.checkIfFormIsDirty();
//             // },
//           ),

//           TextFormField(
//             style: bodyStyleBlack,
//             decoration: InputDecoration(
//               labelText: 'Region / State Name',
//               labelStyle: bodyStyleBlack,
//               hintStyle: formHintStyle,
//             ),
//             autovalidateMode: AutovalidateMode.onUserInteraction,
//             controller: formController.regionName,
//             onChanged: (value) {
//               formController
//                 ..editedData =
//                     formController.editedData?.copyWith(regionName: value)
//                 ..checkIfFormIsDirty();
//             },
//           ),
//           TextFormField(
//             style: bodyStyleBlack,
//             decoration: InputDecoration(
//               labelText: 'Country Name',
//               labelStyle: bodyStyleBlack,
//               hintStyle: formHintStyle,
//             ),
//             autovalidateMode: AutovalidateMode.onUserInteraction,
//             controller: formController.countryName,
//             onChanged: (value) {
//               formController
//                 ..editedData =
//                     formController.editedData?.copyWith(countryName: value)
//                 ..checkIfFormIsDirty();
//             },
//           ),
//           TextFormField(
//             style: bodyStyleBlack,
//             decoration: InputDecoration(
//               labelText: 'Continent Name',
//               labelStyle: bodyStyleBlack,
//               hintStyle: formHintStyle,
//             ),
//             autovalidateMode: AutovalidateMode.onUserInteraction,
//             controller: formController.continentName,
//             onChanged: (value) {
//               formController
//                 ..editedData =
//                     formController.editedData?.copyWith(continentName: value)
//                 ..checkIfFormIsDirty();
//             },
//           ),
//           TextFormField(
//             style: bodyStyleBlack,
//             decoration: InputDecoration(
//               labelText: 'Google Calendar ID',
//               labelStyle: bodyStyleBlack,
//               hintStyle: formHintStyle,
//             ),
//             autovalidateMode: AutovalidateMode.onUserInteraction,
//             controller: formController.googleCalendarId,
//             onChanged: (value) {
//               formController
//                 ..editedData =
//                     formController.editedData?.copyWith(googleCalendarId: value)
//                 ..checkIfFormIsDirty();
//             },
//           ),
//           TextFormField(
//             style: bodyStyleBlack,
//             decoration: InputDecoration(
//               labelText: 'Mismanagement Team',
//               labelStyle: bodyStyleBlack,
//               hintStyle: formHintStyle,
//             ),
//             autovalidateMode: AutovalidateMode.onUserInteraction,
//             controller: formController.mismanagementTeam,
//             onChanged: (value) {
//               formController
//                 ..editedData = formController.editedData
//                     ?.copyWith(mismanagementTeam: value)
//                 ..checkIfFormIsDirty();
//             },
//           ),
//           TextFormField(
//             style: bodyStyleBlack,
//             decoration: InputDecoration(
//               labelText: 'Website URL',
//               labelStyle: bodyStyleBlack,
//               hintStyle: formHintStyle,
//             ),
//             autovalidateMode: AutovalidateMode.onUserInteraction,
//             controller: formController.kennelWebsiteUrl,
//             onChanged: (value) {
//               formController
//                 ..editedData =
//                     formController.editedData?.copyWith(kennelWebsiteUrl: value)
//                 ..checkIfFormIsDirty();
//             },
//           ),
//           TextFormField(
//             style: bodyStyleBlack,
//             decoration: InputDecoration(
//               labelText: 'Events URL',
//               labelStyle: bodyStyleBlack,
//               hintStyle: formHintStyle,
//             ),
//             autovalidateMode: AutovalidateMode.onUserInteraction,
//             controller: formController.kennelEventsUrl,
//             onChanged: (value) {
//               formController
//                 ..editedData =
//                     formController.editedData?.copyWith(kennelEventsUrl: value)
//                 ..checkIfFormIsDirty();
//             },
//           ),
//           TextFormField(
//             style: bodyStyleBlack,
//             decoration: InputDecoration(
//               labelText: 'HC Events URL',
//               labelStyle: bodyStyleBlack,
//               hintStyle: formHintStyle,
//             ),
//             autovalidateMode: AutovalidateMode.onUserInteraction,
//             controller: formController.kennelHcEventsUrl,
//             onChanged: (value) {
//               formController
//                 ..editedData = formController.editedData
//                     ?.copyWith(kennelHcEventsUrl: value)
//                 ..checkIfFormIsDirty();
//             },
//           ),
//           TextFormField(
//             style: bodyStyleBlack,
//             decoration: InputDecoration(
//               labelText: 'Kennel Cover Photo',
//               labelStyle: bodyStyleBlack,
//               hintStyle: formHintStyle,
//             ),
//             autovalidateMode: AutovalidateMode.onUserInteraction,
//             controller: formController.kennelCoverPhoto,
//             onChanged: (value) {
//               formController
//                 ..editedData =
//                     formController.editedData?.copyWith(kennelCoverPhoto: value)
//                 ..checkIfFormIsDirty();
//             },
//           ),

//           TextFormField(
//             style: bodyStyleBlack,
//             decoration: InputDecoration(
//               labelText: 'Kennel Admin Email List',
//               labelStyle: bodyStyleBlack,
//               hintStyle: formHintStyle,
//             ),
//             autovalidateMode: AutovalidateMode.onUserInteraction,
//             controller: formController.kennelAdminEmailList,
//             onChanged: (value) {
//               formController
//                 ..editedData = formController.editedData
//                     ?.copyWith(kennelAdminEmailList: value)
//                 ..checkIfFormIsDirty();
//             },
//           ),
//           TextFormField(
//             style: bodyStyleBlack,
//             decoration: InputDecoration(
//               labelText: 'Bank Scheme',
//               labelStyle: bodyStyleBlack,
//               hintStyle: formHintStyle,
//             ),
//             autovalidateMode: AutovalidateMode.onUserInteraction,
//             controller: formController.bankScheme,
//             onChanged: (value) {
//               formController
//                 ..editedData =
//                     formController.editedData?.copyWith(bankScheme: value)
//                 ..checkIfFormIsDirty();
//             },
//           ),
//           TextFormField(
//             style: bodyStyleBlack,
//             decoration: InputDecoration(
//               labelText: 'Bank Account Number',
//               labelStyle: bodyStyleBlack,
//               hintStyle: formHintStyle,
//             ),
//             autovalidateMode: AutovalidateMode.onUserInteraction,
//             controller: formController.bankAccountNumber,
//             onChanged: (value) {
//               formController
//                 ..editedData = formController.editedData
//                     ?.copyWith(bankAccountNumber: value)
//                 ..checkIfFormIsDirty();
//             },
//           ),
//           TextFormField(
//             style: bodyStyleBlack,
//             decoration: InputDecoration(
//               labelText: 'Bank Beneficiary',
//               labelStyle: bodyStyleBlack,
//               hintStyle: formHintStyle,
//             ),
//             autovalidateMode: AutovalidateMode.onUserInteraction,
//             controller: formController.bankBeneficiary,
//             onChanged: (value) {
//               formController
//                 ..editedData =
//                     formController.editedData?.copyWith(bankBeneficiary: value)
//                 ..checkIfFormIsDirty();
//             },
//           ),
//           TextFormField(
//             style: bodyStyleBlack,
//             decoration: InputDecoration(
//               labelText: 'Kennel Payment Scheme',
//               labelStyle: bodyStyleBlack,
//               hintStyle: formHintStyle,
//             ),
//             autovalidateMode: AutovalidateMode.onUserInteraction,
//             controller: formController.kennelPaymentScheme,
//             onChanged: (value) {
//               formController
//                 ..editedData = formController.editedData
//                     ?.copyWith(kennelPaymentScheme: value)
//                 ..checkIfFormIsDirty();
//             },
//           ),
//           TextFormField(
//             style: bodyStyleBlack,
//             decoration: InputDecoration(
//               labelText: 'Kennel Payment URL',
//               labelStyle: bodyStyleBlack,
//               hintStyle: formHintStyle,
//             ),
//             autovalidateMode: AutovalidateMode.onUserInteraction,
//             controller: formController.kennelPaymentUrl,
//             onChanged: (value) {
//               formController
//                 ..editedData =
//                     formController.editedData?.copyWith(kennelPaymentUrl: value)
//                 ..checkIfFormIsDirty();
//             },
//           ),

//           TextFormField(
//             style: bodyStyleBlack,
//             decoration: InputDecoration(
//               labelText: 'Kennel Payment Scheme 2',
//               labelStyle: bodyStyleBlack,
//               hintStyle: formHintStyle,
//             ),
//             autovalidateMode: AutovalidateMode.onUserInteraction,
//             controller: formController.kennelPaymentScheme2,
//             onChanged: (value) {
//               formController
//                 ..editedData = formController.editedData
//                     ?.copyWith(kennelPaymentScheme2: value)
//                 ..checkIfFormIsDirty();
//             },
//           ),
//           TextFormField(
//             style: bodyStyleBlack,
//             decoration: InputDecoration(
//               labelText: 'Kennel Payment URL 2',
//               labelStyle: bodyStyleBlack,
//               hintStyle: formHintStyle,
//             ),
//             autovalidateMode: AutovalidateMode.onUserInteraction,
//             controller: formController.kennelPaymentUrl2,
//             onChanged: (value) {
//               formController
//                 ..editedData = formController.editedData
//                     ?.copyWith(kennelPaymentUrl2: value)
//                 ..checkIfFormIsDirty();
//             },
//           ),

//           TextFormField(
//             style: bodyStyleBlack,
//             decoration: InputDecoration(
//               labelText: 'Kennel Paynment Scheme 3',
//               labelStyle: bodyStyleBlack,
//               hintStyle: formHintStyle,
//             ),
//             autovalidateMode: AutovalidateMode.onUserInteraction,
//             controller: formController.kennelPaymentScheme3,
//             onChanged: (value) {
//               formController
//                 ..editedData = formController.editedData
//                     ?.copyWith(kennelPaymentScheme3: value)
//                 ..checkIfFormIsDirty();
//             },
//           ),
//           TextFormField(
//             style: bodyStyleBlack,
//             decoration: InputDecoration(
//               labelText: 'Kennel Payment URL 3',
//               labelStyle: bodyStyleBlack,
//               hintStyle: formHintStyle,
//             ),
//             autovalidateMode: AutovalidateMode.onUserInteraction,
//             controller: formController.kennelPaymentUrl3,
//             onChanged: (value) {
//               formController
//                 ..editedData = formController.editedData
//                     ?.copyWith(kennelPaymentUrl3: value)
//                 ..checkIfFormIsDirty();
//             },
//           ),

//           TextFormField(
//             style: bodyStyleBlack,
//             decoration: InputDecoration(
//               labelText: 'External API Key',
//               labelStyle: bodyStyleBlack,
//               hintStyle: formHintStyle,
//             ),
//             autovalidateMode: AutovalidateMode.onUserInteraction,
//             controller: formController.extApiKey,
//             onChanged: (value) {
//               formController
//                 ..editedData =
//                     formController.editedData?.copyWith(extApiKey: value)
//                 ..checkIfFormIsDirty();
//             },
//           ),
//           TextFormField(
//             style: bodyStyleBlack,
//             decoration: InputDecoration(
//               labelText: 'Kennel Search Tags',
//               labelStyle: bodyStyleBlack,
//               hintStyle: formHintStyle,
//             ),
//             autovalidateMode: AutovalidateMode.onUserInteraction,
//             controller: formController.kennelSearchTags,
//             onChanged: (value) {
//               formController
//                 ..editedData =
//                     formController.editedData?.copyWith(kennelSearchTags: value)
//                 ..checkIfFormIsDirty();
//             },
//           ),

//           // Dropdown Fields
//           _buildTextDropdownField(
//             label: 'Kennel Status',
//             value: _ensureValidInt(formController.kennelStatus, 0, 1),
//             items: {
//               0: 'Inactive',
//               1: 'Active',
//             },
//             updateValue: (int value) {
//               formController.editedData =
//                   formController.editedData!.copyWith(kennelStatus: value);
//             },
//           ),

//           _buildTextDropdownField(
//             label: 'Distance preference',
//             value: _ensureValidInt(formController.distancePreference, -1, 1),
//             items: {
//               0: 'Kilometers',
//               1: 'Miles',
//               -1: 'Default for country',
//             },
//             updateValue: (int value) {
//               formController.editedData = formController.editedData!
//                   .copyWith(distancePreference: value);
//             },
//           ),

//           _buildImageDropdownField(
//             label: 'Kennel Pin Color',
//             value: _ensureValidInt(formController.kennelPinColor, 0, 8),
//             height: 45,
//             width: 45,
//             items: {
//               0: 'Red',
//               1: 'Orange', //'🟧 Orange',
//               2: 'Yellow', //'🟨 Yellow',
//               3: 'Green', //'🟩 Green',
//               4: 'Teal', //'Teal',
//               5: 'Baby_blue', //'🩵 Baby Blue',
//               6: 'Blue', //'🟦 Blue',
//               7: 'Purple', //'🟪 Purple',
//               8: 'Pink', //'🩷 Pink',
//             },
//             updateValue: (int value) {
//               formController.editedData =
//                   formController.editedData!.copyWith(kennelPinColor: value);
//             },
//           ),

//           // switches

//           Obx(
//             () => SwitchListTile(
//               title: Text('Exclude from Leaderboard', style: bodyStyleBlack),
//               value: formController.excludeFromLeaderboard.value,
//               onChanged: (val) {
//                 formController.excludeFromLeaderboard.value = val;
//                 formController
//                   ..editedData = formController.editedData
//                       ?.copyWith(excludeFromLeaderboard: val ? 1 : 0)
//                   ..checkIfFormIsDirty();
//               },
//             ),
//           ),

//           Obx(
//             () => SwitchListTile(
//               title: Text('Show runs on Hashruns.org', style: bodyStyleBlack),
//               value: formController.disseminateHashRunsDotOrg.value,
//               onChanged: (val) {
//                 formController.disseminateHashRunsDotOrg.value = val;
//                 formController
//                   ..editedData = formController.editedData
//                       ?.copyWith(disseminateHashRunsDotOrg: val ? 1 : 0)
//                   ..checkIfFormIsDirty();
//               },
//             ),
//           ),

//           Obx(
//             () => SwitchListTile(
//               title: Text('Enable copy web link', style: bodyStyleBlack),
//               value: formController.disseminateAllowWebLinks.value,
//               onChanged: (val) {
//                 formController.disseminateAllowWebLinks.value = val;
//                 formController
//                   ..editedData = formController.editedData
//                       ?.copyWith(disseminateAllowWebLinks: val ? 1 : 0)
//                   ..checkIfFormIsDirty();
//               },
//             ),
//           ),

//           Obx(
//             () => SwitchListTile(
//               title:
//                   Text('User can edit run attendence', style: bodyStyleBlack),
//               value: formController.canEditRunAttendence.value,
//               onChanged: (val) {
//                 formController.canEditRunAttendence.value = val;
//                 formController
//                   ..editedData = formController.editedData
//                       ?.copyWith(canEditRunAttendence: val ? 1 : 0)
//                   ..checkIfFormIsDirty();
//               },
//             ),
//           ),

//           Obx(
//             () => SwitchListTile(
//               title: Text(
//                 'Hasher can mark themselves as paid',
//                 style: bodyStyleBlack,
//               ),
//               value: formController.allowSelfPayment.value,
//               onChanged: (val) {
//                 formController.allowSelfPayment.value = val;
//                 formController
//                   ..editedData = formController.editedData
//                       ?.copyWith(allowSelfPayment: val ? 1 : 0)
//                   ..checkIfFormIsDirty();
//               },
//             ),
//           ),

//           Obx(
//             () => SwitchListTile(
//               title: Text('Allow negative credit', style: bodyStyleBlack),
//               value: formController.allowNegativeCredit.value,
//               onChanged: (val) {
//                 formController.allowNegativeCredit.value = val;
//                 formController
//                   ..editedData = formController.editedData
//                       ?.copyWith(allowNegativeCredit: val ? 1 : 0)
//                   ..checkIfFormIsDirty();
//               },
//             ),
//           ),

//           _buildDoubleField(
//             label: 'Default Event Price for Members',
//             value: formController.defaultEventPriceForMembers,
//             onChanged: (value) {
//               final price = double.tryParse(value) ?? 0.0;
//               formController.defaultEventPriceForMembers.value = price;
//               formController
//                 ..editedData = formController.editedData
//                     ?.copyWith(defaultEventPriceForMembers: price)
//                 ..checkIfFormIsDirty();
//             },
//           ),
//           _buildDoubleField(
//             label: 'Default Event Price for Non-Members',
//             value: formController.defaultEventPriceForNonMembers,
//             onChanged: (value) {
//               final price = double.tryParse(value) ?? 0.0;
//               formController.defaultEventPriceForNonMembers.value = price;
//               formController
//                 ..editedData = formController.editedData
//                     ?.copyWith(defaultEventPriceForNonMembers: price)
//                 ..checkIfFormIsDirty();
//             },
//           ),

//           _buildDoubleField(
//             label: 'Payment Surcharge for Members',
//             value: formController.kennelPaymentMemberSurcharge,
//             onChanged: (value) {
//               final price = double.tryParse(value) ?? 0.0;
//               formController.kennelPaymentMemberSurcharge.value = price;
//               formController
//                 ..editedData = formController.editedData
//                     ?.copyWith(kennelPaymentMemberSurcharge: price)
//                 ..checkIfFormIsDirty();
//             },
//           ),

//           _buildDoubleField(
//             label: 'Payment Surcharge for Non-Members',
//             value: formController.kennelPaymentNonMemberSurcharge,
//             onChanged: (value) {
//               final price = double.tryParse(value) ?? 0.0;
//               formController.kennelPaymentNonMemberSurcharge.value = price;
//               formController
//                 ..editedData = formController.editedData
//                     ?.copyWith(kennelPaymentNonMemberSurcharge: price)
//                 ..checkIfFormIsDirty();
//             },
//           ),

//           // Date picker for run counts start date
//           Obx(
//             () => ListTile(
//               title: Text('Run count start date', style: bodyStyleBlackSmall),
//               subtitle: Text(
//                 DateFormat.yMMMd()
//                     .add_jm()
//                     .format(formController.runCountStartDate.value),
//                 style: bodyStyleBlack,
//               ),
//               onTap: () async {
//                 final initialTime = DateTime(
//                   formController.runCountStartDate.value.year,
//                   formController.runCountStartDate.value.month,
//                   formController.runCountStartDate.value.day,
//                 );

//                 final pickedDate = await showDatePicker(
//                   context: Get.context!,
//                   initialDate: initialTime,
//                   firstDate: DateTime(2000),
//                   lastDate: DateTime(2100),
//                 );

//                 if (pickedDate != null) {
//                   formController.runCountStartDate.value = pickedDate;
//                   formController
//                     ..editedData = formController.editedData
//                         ?.copyWith(runCountStartDate: pickedDate)
//                     ..checkIfFormIsDirty();
//                 }
//               },
//             ),
//           ),

//           // Time picker for default run start time
//           Obx(
//             () => Theme(
//               data: ThemeData.dark().copyWith(),
//               child: ListTile(
//                 title: Text(
//                   'Default Run Start Time',
//                   style: bodyStyleBlackSmall,
//                 ),
//                 subtitle: Text(
//                   DateFormat.yMMMd()
//                       .add_jm()
//                       .format(formController.defaultRunStartTime.value),
//                   style: bodyStyleBlack,
//                 ),
//                 onTap: () async {
//                   final initialTime = TimeOfDay(
//                     hour: formController.defaultRunStartTime.value.hour,
//                     minute: formController.defaultRunStartTime.value.minute,
//                   );

//                   final pickedTime = await showTimePicker(
//                     context: Get.context!,
//                     initialTime: initialTime,
//                   );

//                   if (pickedTime != null) {
//                     final newRunStartTime = DateTime(
//                       2000,
//                       1,
//                       1,
//                       pickedTime.hour,
//                       pickedTime.minute,
//                     );

//                     formController.defaultRunStartTime.value = newRunStartTime;
//                     formController
//                       ..editedData = formController.editedData
//                           ?.copyWith(defaultRunStartTime: newRunStartTime)
//                       ..checkIfFormIsDirty();
//                   }
//                 },
//               ),
//             ),
//           ),

//           Obx(
//             () => ListTile(
//               title: Text(
//                 'Kennel Payment URL expiration date',
//                 style: bodyStyleBlackSmall,
//               ),
//               subtitle: Text(
//                 DateFormat.yMMMd()
//                     .add_jm()
//                     .format(formController.kennelPaymentUrlExpires.value),
//                 style: bodyStyleBlack,
//               ),
//               onTap: () async {
//                 final initialDate = DateTime(
//                   formController.kennelPaymentUrlExpires.value.year,
//                   formController.kennelPaymentUrlExpires.value.month,
//                   formController.kennelPaymentUrlExpires.value.day,
//                 );

//                 final pickedDate = await showDatePicker(
//                   context: Get.context!,
//                   initialDate: initialDate,
//                   firstDate: DateTime(2000),
//                   lastDate: DateTime(2100),
//                 );

//                 if (pickedDate != null) {
//                   formController.kennelPaymentUrlExpires.value = pickedDate;
//                   formController
//                     ..editedData = formController.editedData
//                         ?.copyWith(kennelPaymentUrlExpires: pickedDate)
//                     ..checkIfFormIsDirty();
//                 }
//               },
//             ),
//           ),

//           Obx(
//             () => ListTile(
//               title: Text(
//                 'Kennel Payment URL expiration date',
//                 style: bodyStyleBlackSmall,
//               ),
//               subtitle: Text(
//                 DateFormat.yMMMd().add_jm().format(
//                       formController.kennelPaymentUrlExpires2.value,
//                     ),
//                 style: bodyStyleBlack,
//               ),
//               onTap: () async {
//                 final initialDate = DateTime(
//                   formController.kennelPaymentUrlExpires2.value.year,
//                   formController.kennelPaymentUrlExpires2.value.month,
//                   formController.kennelPaymentUrlExpires2.value.day,
//                 );

//                 final pickedDate = await showDatePicker(
//                   context: Get.context!,
//                   initialDate: initialDate,
//                   firstDate: DateTime(2000),
//                   lastDate: DateTime(2100),
//                 );

//                 if (pickedDate != null) {
//                   formController.kennelPaymentUrlExpires2.value = pickedDate;
//                   formController
//                     ..editedData = formController.editedData
//                         ?.copyWith(kennelPaymentUrlExpires2: pickedDate)
//                     ..checkIfFormIsDirty();
//                 }
//               },
//             ),
//           ),

//           Obx(
//             () => ListTile(
//               title: Text(
//                 'Kennel Payment URL expiration date',
//                 style: bodyStyleBlackSmall,
//               ),
//               subtitle: Text(
//                 DateFormat.yMMMd().add_jm().format(
//                       formController.kennelPaymentUrlExpires3.value,
//                     ),
//                 style: bodyStyleBlack,
//               ),
//               onTap: () async {
//                 final initialDate = DateTime(
//                   formController.kennelPaymentUrlExpires3.value.year,
//                   formController.kennelPaymentUrlExpires3.value.month,
//                   formController.kennelPaymentUrlExpires3.value.day,
//                 );

//                 final pickedDate = await showDatePicker(
//                   context: Get.context!,
//                   initialDate: initialDate,
//                   firstDate: DateTime(2000),
//                   lastDate: DateTime(2100),
//                 );

//                 if (pickedDate != null) {
//                   formController.kennelPaymentUrlExpires3.value = pickedDate;
//                   formController
//                     ..editedData = formController.editedData
//                         ?.copyWith(kennelPaymentUrlExpires3: pickedDate)
//                     ..checkIfFormIsDirty();
//                 }
//               },
//             ),
//           ),

//           // Integer fields

//           _buildIntField(
//             label: 'Membership Duration (Months)',
//             value: formController.membershipDurationInMonths,
//             onChanged: (value) {
//               final intVal = int.tryParse(value) ?? 0;
//               formController.membershipDurationInMonths.value = intVal;
//               formController
//                 ..editedData = formController.editedData
//                     ?.copyWith(membershipDurationInMonths: intVal)
//                 ..checkIfFormIsDirty();
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }
