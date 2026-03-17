// part of '../kennel_form_ui.dart';

// extension Other on KennelFormPage {
//   Widget _buildOther({required int tabIndex}) {
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
//                       HelperWidgets().categoryLabelWidget('Run Start'),
//                       if (isSmallScreen)
//                         Column(
//                           children: [
//                             _buildDefaultRunStartTime(tabIndex),
//                             const SizedBox(
//                               height: 10,
//                             ),
//                             _buildDefaultDayOfWeekDropdown(tabIndex),
//                           ],
//                         )
//                       else
//                         Row(
//                           children: [
//                             Expanded(
//                               child: _buildDefaultRunStartTime(tabIndex),
//                             ),
//                             const SizedBox(width: 10),
//                             Expanded(
//                               child: _buildDefaultDayOfWeekDropdown(tabIndex),
//                             ),
//                           ],
//                         ),
//                       HelperWidgets().categoryLabelWidget('Sharing runs'),
//                       if (isSmallScreen)
//                         Column(
//                           children: [
//                             _buildShowOnHashRuns(tabIndex),
//                             const SizedBox(height: 10),
//                             _enableCopyWebLink(tabIndex),
//                           ],
//                         )
//                       else
//                         Row(
//                           children: [
//                             Expanded(
//                               child: _buildShowOnHashRuns(tabIndex),
//                             ),
//                             const SizedBox(width: 10),
//                             Expanded(
//                               child: _enableCopyWebLink(tabIndex),
//                             ),
//                           ],
//                         ),
//                       HelperWidgets().categoryLabelWidget('Integrations'),
//                       const SizedBox(height: 20),
//                       MouseRegion(
//                         onEnter: (event) {
//                           formController.setSidebarData('globalGoogleCalendar');
//                         },
//                         onExit: (event) {
//                           formController.setSidebarData('otherTab');
//                         },
//                         child: Row(
//                           children: [
//                             Expanded(
//                               child:
//                                   _disseminateOnGlobalGoogleCalendar(tabIndex),
//                             ),
//                             const SizedBox(width: 10),
//                             const Expanded(
//                               child: SizedBox(),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 10),
//                       if (isSmallScreen)
//                         Column(
//                           children: [
//                             // _userEditRunAttendence(tabIndex),
//                             // const SizedBox(height: 10),
//                             _buildGoogleCalendarAddresses(tabIndex),
//                             const SizedBox(height: 10),
//                             _disseminateOnGlobalGoogleCalendar(tabIndex),
//                           ],
//                         )
//                       else
//                         MouseRegion(
//                           onEnter: (event) {
//                             formController
//                                 .setSidebarData('googleCalendarIntegration');
//                           },
//                           onExit: (event) {
//                             formController.setSidebarData('otherTab');
//                           },
//                           child: Row(
//                             children: [
//                               Expanded(
//                                 child: _publishToGoogleCalendar(tabIndex),
//                               ),
//                               const SizedBox(width: 10),
//                               Expanded(child: Container()),
//                             ],
//                           ),
//                         ),
//                       const SizedBox(height: 10),
//                       MouseRegion(
//                         onEnter: (event) {
//                           formController
//                               .setSidebarData('googleCalendarIntegration');
//                         },
//                         onExit: (event) {
//                           formController.setSidebarData('otherTab');
//                         },
//                         child: _buildGoogleCalendarAddresses(tabIndex),
//                       ),
//                       const SizedBox(height: 20),
//                       HelperWidgets().categoryLabelWidget('Other'),
//                       if (isSmallScreen)
//                         Column(
//                           children: [
//                             _userEditRunAttendence(tabIndex),
//                             const SizedBox(height: 10),
//                             _buildExcludeFromLeaderboard(tabIndex),
//                           ],
//                         )
//                       else
//                         Row(
//                           children: [
//                             Expanded(
//                               child: _userEditRunAttendence(tabIndex),
//                             ),
//                             const SizedBox(width: 10),
//                             Expanded(
//                               child: _buildExcludeFromLeaderboard(tabIndex),
//                             ),
//                           ],
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       }
//     }
//   }

//   Widget _buildGoogleCalendarAddresses(int tabIndex) {
//     return _buildTextField(
//       controller: formController.publishToGoogleCalendarAddresses,
//       label: 'Google Calendar IDs',
//       customStyle: bodyStyleBlack,
//       isMultiline: true,
//       maxLines: 3,
//       inputType: TextInputType.multiline,
//       focusNode: formController.focusNodes['googleCalendarAddresses'],
//       onChanged: (value) {
//         formController.editedData = formController.editedData
//             ?.copyWith(publishToGoogleCalendarAddresses: value);
//         if ((value.isNotEmpty && value.length < 12) || (value.length > 500)) {
//           formController.googleCalendarAddresses = false;
//         } else {
//           formController.googleCalendarAddresses = true;
//         }
//         formController.checkIfFormIsDirty(tabIndex: tabIndex);
//       },
//       validator: (value) {
//         //print('field validation called');
//         String? result;

//         if (value == null) return null;
//         if (((value.isNotEmpty && value.length < 12)) || (value.length > 500)) {
//           result =
//               'You must provide a valid Google calendar ID (usually the email address associated with the Google account)';
//         }

//         return result;
//       },
//     );
//   }

//   Widget _buildExcludeFromLeaderboard(int tabIndex) {
//     return Obx(
//       () => SwitchListTile(
//         title: Text('Exclude from Leaderboard', style: bodyStyleBlack),
//         value: formController.excludeFromLeaderboard.value,
//         onChanged: (val) {
//           formController.excludeFromLeaderboard.value = val;
//           formController
//             ..editedData = formController.editedData
//                 ?.copyWith(excludeFromLeaderboard: val ? 1 : 0)
//             ..checkIfFormIsDirty(tabIndex: tabIndex);
//         },
//       ),
//     );
//   }

//   Widget _buildShowOnHashRuns(int tabIndex) {
//     return Obx(
//       () => SwitchListTile(
//         title: Text('Show runs on Hashruns.org', style: bodyStyleBlack),
//         value: formController.disseminateHashRunsDotOrg.value,
//         onChanged: (val) {
//           formController.disseminateHashRunsDotOrg.value = val;
//           formController
//             ..editedData = formController.editedData
//                 ?.copyWith(disseminateHashRunsDotOrg: val ? 5 : 0)
//             ..checkIfFormIsDirty(tabIndex: tabIndex);
//         },
//       ),
//     );
//   }

//   Widget _enableCopyWebLink(int tabIndex) {
//     return Obx(
//       () => SwitchListTile(
//         title: Text('Enable copy web link', style: bodyStyleBlack),
//         value: formController.disseminateAllowWebLinks.value,
//         onChanged: (val) {
//           formController.disseminateAllowWebLinks.value = val;
//           formController
//             ..editedData = formController.editedData
//                 ?.copyWith(disseminateAllowWebLinks: val ? 1 : 0)
//             ..checkIfFormIsDirty(tabIndex: tabIndex);
//         },
//       ),
//     );
//   }

//   Widget _publishToGoogleCalendar(int tabIndex) {
//     return Obx(
//       () => SwitchListTile(
//         title: Text('Publish To Google Calendars', style: bodyStyleBlack),
//         value: formController.publishToGoogleCalendar.value,
//         onChanged: (val) {
//           formController.publishToGoogleCalendar.value = val;
//           formController
//             ..editedData = formController.editedData
//                 ?.copyWith(publishToGoogleCalendar: val ? 1 : 0)
//             ..checkIfFormIsDirty(tabIndex: tabIndex);
//         },
//       ),
//     );
//   }

//   Widget _disseminateOnGlobalGoogleCalendar(int tabIndex) {
//     return Obx(
//       () => SwitchListTile(
//         title: Text(
//           'Publish To Harrier Central Global Google Calendar',
//           style: bodyStyleBlack,
//         ),
//         value: formController.disseminateOnGlobalGoogleCalendar.value,
//         onChanged: (val) {
//           formController.disseminateOnGlobalGoogleCalendar.value = val;
//           formController
//             ..editedData = formController.editedData
//                 ?.copyWith(disseminateOnGlobalGoogleCalendar: val ? 1 : 0)
//             ..checkIfFormIsDirty(tabIndex: tabIndex);
//         },
//       ),
//     );
//   }

//   Widget _userEditRunAttendence(int tabIndex) {
//     return Obx(
//       () => SwitchListTile(
//         title: Text('User can edit run attendence', style: bodyStyleBlack),
//         value: formController.canEditRunAttendence.value,
//         onChanged: (val) {
//           formController.canEditRunAttendence.value = val;
//           formController
//             ..editedData = formController.editedData
//                 ?.copyWith(canEditRunAttendence: val ? 1 : 0)
//             ..checkIfFormIsDirty(tabIndex: tabIndex);
//         },
//       ),
//     );
//   }

//   Widget _buildDefaultDayOfWeekDropdown(int tabIndex) {
//     var dayOfWeek =
//         formController.editedData!.defaultRunStartTime.millisecond ~/ 100;
//     if (dayOfWeek == 0) {
//       dayOfWeek = 1;
//     }

//     return _buildTextDropdownField(
//       label: 'Default day',
//       value: _ensureValidInt(dayOfWeek.obs, 1, 7),
//       focusNode: formController.focusNodes['dayOfWeekPreference'],
//       items: {
//         1: 'Monday',
//         2: 'Tuesday',
//         3: 'Wednesday',
//         4: 'Thursday',
//         5: 'Friday',
//         6: 'Saturday',
//         7: 'Sunday',
//       },
//       updateValue: (int value) {
//         final currentDefaultStartTime =
//             formController.editedData!.defaultRunStartTime;

//         final newRunStartTime = DateTime(
//           1900,
//           1,
//           1,
//           currentDefaultStartTime.hour,
//           currentDefaultStartTime.minute,
//           0,
//           value * 100,
//         );

//         formController
//           ..editedData = formController.editedData!
//               .copyWith(defaultRunStartTime: newRunStartTime)
//           ..checkIfFormIsDirty(tabIndex: tabIndex);
//         // print(formController.editedData!.defaultRunStartTime.toString() +
//         //     '/' +
//         //     formController.originalData!.defaultRunStartTime.toString());
//       },
//     );
//   }

//   Widget _buildDefaultRunStartTime(int tabIndex) {
//     return Obx(
//       () => ListTile(
//         title: Text('Default Run Start Time', style: bodyStyleBlackSmall),
//         subtitle: Text(
//           DateFormat.jm().format(formController.defaultRunStartTime.value),
//           style: bodyStyleBlack,
//         ),
//         onTap: () async {
//           final initialTime = TimeOfDay(
//             hour: formController.defaultRunStartTime.value.hour,
//             minute: formController.defaultRunStartTime.value.minute,
//           );

//           final pickedTime = await showTimePicker(
//             context: Get.context!,
//             initialTime: initialTime,
//           );

//           if (pickedTime != null) {
//             final newRunStartTime = DateTime(
//               1900,
//               1,
//               1,
//               pickedTime.hour,
//               pickedTime.minute,
//               0,
//               formController.defaultRunStartTime.value.millisecond,
//             );

//             formController.defaultRunStartTime.value = newRunStartTime;
//             formController
//               ..editedData = formController.editedData
//                   ?.copyWith(defaultRunStartTime: newRunStartTime)
//               ..checkIfFormIsDirty(tabIndex: tabIndex);
//           }
//         },
//       ),
//     );
//   }
// }
