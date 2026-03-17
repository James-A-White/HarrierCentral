// part of 'application_form_ui.dart';

// extension ApplicationForm_UiHelpers on TestFormPageState {
//   RxInt _ensureValidInt(RxInt currentValue, int lowerBound, int upperBound) {
//     if ((currentValue.value < lowerBound) ||
//         (currentValue.value > upperBound)) {
//       return lowerBound.obs;
//     }

//     return currentValue;
//   }

//   Widget _buildTextField({
//     TextEditingController? controller,
//     String label = '',
//     int maxLines = 1,
//     bool isMultiline = false,
//     bool isBold = false,
//     Color? backgroundColor,
//     TextStyle? customStyle,
//     TextInputType inputType = TextInputType.text,
//     FocusNode? focusNode,
//     void Function(String)? onChanged,
//     String? Function(String?)? validator,
//     bool readOnly = false,
//     bool includeOverrideButton = false,
//   }) {
//     return KeepAliveWrapper(
//       child: TextFormField(
//         controller: controller,
//         readOnly: readOnly,
//         focusNode: focusNode,
//         autovalidateMode: AutovalidateMode.onUserInteraction,
//         onChanged: onChanged,
//         validator: validator,
//         decoration: InputDecoration(
//           labelStyle: formHintStyle,
//           hintStyle: formHintStyle,
//           labelText: label,
//           errorStyle: errorSmallRed,
//           floatingLabelStyle: bodyStyleBlack,
//           border: isMultiline
//               ? const OutlineInputBorder()
//               : const UnderlineInputBorder(),
//           filled: backgroundColor != null,
//           fillColor: backgroundColor,
//         ),
//         maxLines: maxLines,
//         style: customStyle ??
//             bodyStyleBlack.copyWith(
//               fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
//             ),
//         keyboardType: inputType,
//       ),
//     );
//   }

//   Widget _buildDoubleFieldWithLookthrough({
//     required String fieldName,
//     required String label,
//     required String defaultLabel,
//     required Rx<double?>? value,
//     required Rx<double> defaultValue,
//     required RxBool overrideDefault,
//     required void Function(String?) onChanged,
//     String? Function(String?)? validator,
//     double width = 400.0,
//   }) {
//     return Obx(
//       () => Row(
//         children: [
//           Checkbox(
//             value: overrideDefault.value,
//             onChanged: (bool? val) {
//               if (val == null) {
//                 overrideDefault.value = !overrideDefault.value;
//               } else {
//                 overrideDefault.value = val;
//               }

//               if (overrideDefault.value == false) {
//                 onChanged(defaultValue.value.toString());
//               }
//             },
//           ),
//           if (overrideDefault.value)
//             SizedBox(
//               width: width,
//               child: TextFormField(
//                 style: bodyStyleBlack,
//                 autovalidateMode: AutovalidateMode.always,
//                 decoration: InputDecoration(
//                   labelText: label,
//                   labelStyle: bodyStyleBlack,
//                   hintStyle: formHintStyle,
//                   errorStyle: errorSmallRed,
//                 ),
//                 focusNode: applicationGetxController.focusNodes[fieldName],
//                 initialValue: value?.value?.toString() ?? '',
//                 keyboardType: const TextInputType.numberWithOptions(
//                   signed: true,
//                   decimal: true,
//                 ),
//                 onChanged: onChanged,
//                 validator: validator,
//               ),
//             )
//           else
//             Text(
//               '$defaultLabel: $defaultValue',
//               style: bodyStyleBlack,
//             ),
//         ],
//       ),
//     );
//   }

//   // Widget _buildIntField({
//   //   required String label,
//   //   required RxInt value,
//   //   required void Function(String) onChanged,
//   // }) {
//   //   return Obx(
//   //     () => TextFormField(
//   //       style: bodyStyleBlack,
//   //       decoration: InputDecoration(
//   //         labelText: label,
//   //         labelStyle: bodyStyleBlack,
//   //         hintStyle: formHintStyle,
//   //       ),
//   //       initialValue: value.value.toString(),
//   //       keyboardType: TextInputType.number,
//   //       onChanged: onChanged,
//   //     ),
//   //   );
//   // }

//   Widget _buildDoubleField({
//     required String label,
//     required RxDouble value,
//     required void Function(String) onChanged,
//     TextEditingController? controller,
//     FocusNode? focusNode,
//     String? Function(String?)? validator,
//   }) {
//     ////print'$label updated to ${value.value}');
//     return KeepAliveWrapper(
//       child: TextFormField(
//         controller: controller,
//         style: bodyStyleBlack,
//         focusNode: focusNode,
//         autovalidateMode: AutovalidateMode.always,
//         decoration: InputDecoration(
//           labelText: label,
//           labelStyle: bodyStyleBlack,
//           hintStyle: formHintStyle,
//         ),
//         //initialValue: value.value.toString(),
//         keyboardType: TextInputType.number,
//         onChanged: onChanged,
//         validator: validator,
//       ),
//     );
//   }

//   Widget _buildTextDropdownField({
//     required String label,
//     required RxInt value,
//     required Map<int, String> items,
//     required void Function(int) updateValue,
//     FocusNode? focusNode,
//     double width = double.infinity,
//   }) {
//     return Obx(
//       () => Focus(
//         focusNode: focusNode,
//         child: SizedBox(
//           width: width,
//           //alignment: Alignment.centerLeft,
//           child: DropdownButtonFormField<int>(
//             initialValue: value.value,
//             decoration: InputDecoration(
//               labelText: label,
//               labelStyle: bodyStyleBlack,
//               floatingLabelStyle: bodyStyleBlack,
//               hintStyle: formHintStyle,
//               helperStyle: bodyStyleBlack,
//             ),
//             items: items.entries
//                 .map(
//                   (entry) => DropdownMenuItem(
//                     value: entry.key,
//                     child: Text(
//                       entry.value,
//                       style: bodyStyleBlack,
//                     ),
//                   ),
//                 )
//                 .toList(),
//             onChanged: (newValue) {
//               if (newValue != null) {
//                 value.value = newValue;
//                 updateValue(newValue);
//                 applicationGetxController.checkIfFormIsDirty();
//               }
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildImageDropdownField({
//     required String label,
//     required RxInt value,
//     required Map<int, String> items,
//     required double height,
//     required double width,
//     required void Function(int) updateValue,
//     FocusNode? focusNode,
//   }) {
//     return Obx(
//       () => DropdownButtonFormField<int>(
//         initialValue: value.value,
//         decoration: InputDecoration(labelText: label),
//         focusNode: focusNode,
//         items: items.entries
//             .map(
//               (entry) => DropdownMenuItem(
//                 value: entry.key,
//                 child: Row(
//                   children: [
//                     Image.asset(
//                       'images/map_pins/${entry.value.toLowerCase()}/future_run_rsvp_none.png',
//                       width: height,
//                       height: width,
//                     ),
//                     const SizedBox(width: 20),
//                     Text(
//                       entry.value,
//                       style: bodyStyleBlack,
//                     ),
//                   ],
//                 ),
//               ),
//             )
//             .toList(),
//         onChanged: (newValue) {
//           if (newValue != null) {
//             value.value = newValue;
//             updateValue(newValue);
//             applicationGetxController.checkIfFormIsDirty();
//           }
//         },
//       ),
//     );
//   }

//   Widget _buildTabIcons(
//       TabStatus tabStatus, TabLocked tabLocked, Widget label) {
//     if (tabLocked == TabLocked.tabLocked) {
//       if (tabStatus == TabStatus.isCompleteAndValid) {
//         return Row(children: [
//           const Icon(
//             Entypo.check,
//           ),
//           label,
//           const Icon(
//             Fontisto.locked,
//           ),
//         ]);
//       } else {
//         return Row(children: [
//           const Icon(
//             Fontisto.locked,
//           ),
//           label,
//         ]);
//       }
//     } else {
//       switch (tabStatus) {
//         case TabStatus.isCompleteAndValid:
//           return Row(children: [
//             const Icon(
//               Entypo.check,
//             ),
//             label,
//           ]);
//         case TabStatus.isEmpty:
//           return Row(children: [
//             const Icon(
//               Ionicons.square_outline,
//             ),
//             label,
//           ]);
//         case TabStatus.isInProgress:
//           return Row(children: [
//             const Icon(
//               AntDesign.form,
//             ),
//             label,
//           ]);
//         case TabStatus.isInvalid:
//           return Row(children: [
//             const Icon(
//               FontAwesome.warning,
//             ),
//             label,
//           ]);
//         default:
//           return Row(children: [Container()]); // Fallback widget (optional)
//       }
//     }
//   }

//   Widget _buildTabWidget(
//     String label,
//     int tabIndex,
//     ApplicationFormController controller,
//   ) {
//     return Tab(
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           GetBuilder<ApplicationFormController>(
//               id: 'tabIcons',
//               builder: (controller) {
//                 return Obx(() {
//                   return IconTheme(
//                     data: IconThemeData(
//                         color: tabIndex == (controller.tabController.index)
//                             ? Colors.black
//                             : Colors.white,
//                         size: 25),
//                     child: _buildTabIcons(
//                       (applicationGetxController.tabStatus[tabIndex]).value,
//                       AppTabKeyEnums.values[tabIndex].isTabLockable
//                           ? (applicationGetxController.tabLocked[tabIndex])
//                               .value
//                           : TabLocked.tabUnlocked,
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 15.0),
//                         child: Text(
//                           label,
//                           style: controller.currentIndex.value == tabIndex
//                               ? const TextStyle(
//                                   fontFamily: 'AvenirNextBold',
//                                   color: Colors.black,
//                                   //                           color: controller.tabStatus[tabIndex].value
//                                   // ? Colors.black
//                                   // : Colors.red.shade800,
//                                   fontSize: 15,
//                                   //height: 1.5,
//                                 )
//                               : const TextStyle(
//                                   fontFamily: 'AvenirNext',
//                                   color: Colors.white,
//                                   fontSize: 15,
//                                 ),
//                         ),
//                       ),
//                     ),
//                   );
//                 });
//               }),
//         ],
//       ),
//       //),
//     );
//   }

//   String? _validateDouble({
//     required String label,
//     required double lowerBound,
//     required double upperBound,
//     String? value,
//   }) {
//     String? result;

//     if (value == null) {
//       result = 'Please enter ${label.toLowerCase()} as a decimal value.';
//     }

//     double? numericVal;

//     if ((result == null) && (value != null)) {
//       numericVal = double.tryParse(value);
//     }

//     ////print'$value, $numericVal');

//     if ((result == null) && (numericVal == null)) {
//       result = 'Provide a decimal ${label.toLowerCase()}.';
//     }

//     if ((result == null) && (numericVal! < lowerBound)) {
//       result = '$label must be greater than $lowerBound.';
//     }

//     if ((result == null) && (numericVal! > upperBound)) {
//       result = '$label must be less than $upperBound.';
//     }

//     return result;
//   }

//   String? _validateLatLong({
//     required String label,
//     required double lowerBound,
//     required double upperBound,
//     String? value,
//   }) {
//     String? result;

//     if (value == null) {
//       result = 'Provide a decimal ${label.toLowerCase()}.';
//     }

//     double? numericVal;

//     if ((result == null) && (value != null)) {
//       numericVal = double.tryParse(value);
//     }

//     ////print'$value, $numericVal');

//     if ((result == null) && (numericVal == null)) {
//       result = 'Provide a decimal ${label.toLowerCase()}.';
//     }

//     if ((result == null) && (numericVal! < lowerBound)) {
//       result = '$label must be greater than $lowerBound.';
//     }

//     if ((result == null) && (numericVal! > upperBound)) {
//       result = '$label must be less than $upperBound.';
//     }

//     return result;
//   }
// }
