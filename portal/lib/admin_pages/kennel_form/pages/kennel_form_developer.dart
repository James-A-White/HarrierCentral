// part of '../kennel_form_ui.dart';

// extension Developer on KennelFormPage {
//   Widget _buildLinks({required int tabIndex}) {
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
//                       if (isSmallScreen)
//                         Column(
//                           children: [
//                             HelperWidgets().categoryLabelWidget(
//                               'Links for www.hashruns.org',
//                             ),
//                             _buildOpenWebLinkText(tabIndex),
//                             const SizedBox(
//                               height: 10,
//                             ),
//                             _buildOpenLinkButton(tabIndex),
//                             const SizedBox(
//                               height: 10,
//                             ),
//                             _buildCopyLinkButton(tabIndex),
//                             const SizedBox(
//                               height: 20,
//                             ),
//                             _buildOpenCityWebLinkText(tabIndex),
//                             const SizedBox(
//                               height: 10,
//                             ),
//                             _buildOpenCityLinkButton(tabIndex),
//                             const SizedBox(
//                               height: 10,
//                             ),
//                             _buildCopyCityLinkButton(tabIndex),
//                             const SizedBox(
//                               height: 20,
//                             ),
//                             _buildOpenRegionWebLinkText(tabIndex),
//                             const SizedBox(
//                               height: 10,
//                             ),
//                             _buildOpenRegionLinkButton(tabIndex),
//                             const SizedBox(
//                               height: 10,
//                             ),
//                             _buildCopyRegionLinkButton(tabIndex),
//                             const SizedBox(
//                               height: 20,
//                             ),
//                             _buildOpenCountryWebLinkText(tabIndex),
//                             const SizedBox(
//                               height: 10,
//                             ),
//                             _buildOpenCountryLinkButton(tabIndex),
//                             const SizedBox(
//                               height: 10,
//                             ),
//                             _buildCopyCountryLinkButton(tabIndex),
//                             const SizedBox(
//                               height: 20,
//                             ),
//                             HelperWidgets().categoryLabelWidget(
//                               'Web components',
//                             ),
//                             _buildOpenLeaderboardWebLinkText(tabIndex),
//                             const SizedBox(
//                               height: 10,
//                             ),
//                             _buildOpenLeaderboardLinkButton(tabIndex),
//                             const SizedBox(
//                               height: 10,
//                             ),
//                             _buildCopyLeaderboardLinkButton(tabIndex),
//                             const SizedBox(
//                               height: 10,
//                             ),
//                             _buildCopyLeaderboardIframeButton(tabIndex),
//                             HelperWidgets().categoryLabelWidget(
//                               'Data APIs',
//                             ),
//                             _buildOpenEventsApiWebLinkText(tabIndex),
//                             const SizedBox(
//                               height: 10,
//                             ),
//                             _buildCopyEventsApiLinkButton(tabIndex),
//                             const SizedBox(
//                               height: 10,
//                             ),
//                             _buildOpenEventsApiLinkButton(tabIndex),
//                             const SizedBox(
//                               height: 20,
//                             ),
//                             _buildOpenNextRunApiText(tabIndex),
//                             const SizedBox(
//                               height: 10,
//                             ),
//                             _buildCopyNextRunApiButton(tabIndex),
//                             const SizedBox(
//                               height: 10,
//                             ),
//                             _buildOpenNextRunApiButton(tabIndex),
//                             const SizedBox(
//                               height: 20,
//                             ),
//                             _buildOpenLeaderboardApiText(tabIndex),
//                             const SizedBox(
//                               height: 10,
//                             ),
//                             _buildCopyLeaderboardApiButton(tabIndex),
//                             const SizedBox(
//                               height: 10,
//                             ),
//                             _buildOpenLeaderboardApiButton(tabIndex),
//                           ],
//                         )
//                       else
//                         Column(
//                           children: [
//                             HelperWidgets().categoryLabelWidget(
//                               'Digital identifiers for ${formController.editedData?.kennelName ?? 'your Kennel.'}',
//                             ),
//                             MouseRegion(
//                               onEnter: (event) {
//                                 formController.setSidebarData('publicKennelId');
//                               },
//                               onExit: (event) {
//                                 formController.setSidebarData('developerTab');
//                               },
//                               child: Row(
//                                 children: [
//                                   _buildCopyKennelPublicIdButton(tabIndex),
//                                   const SizedBox(
//                                     width: 30,
//                                   ),
//                                   _buildKennelPublicIdField(tabIndex),
//                                 ],
//                               ),
//                             ),
//                             const SizedBox(height: 20),
//                             MouseRegion(
//                               onEnter: (event) {
//                                 formController.setSidebarData('extApiKey');
//                               },
//                               onExit: (event) {
//                                 formController.setSidebarData('developerTab');
//                               },
//                               child: Row(
//                                 children: [
//                                   _buildCopyExtApiButton(tabIndex),
//                                   const SizedBox(
//                                     width: 10,
//                                   ),
//                                   _buildRegenerateApiKeyButton(),
//                                   const SizedBox(
//                                     width: 30,
//                                   ),
//                                   _buildExtApiKeyField(tabIndex),
//                                 ],
//                               ),
//                             ),
//                             HelperWidgets().categoryLabelWidget(
//                               'Links for www.hashruns.org',
//                             ),
//                             MouseRegion(
//                               onEnter: (event) {
//                                 formController
//                                     .setSidebarData('hashRunsDotOrgKennelLink');
//                               },
//                               onExit: (event) {
//                                 formController.setSidebarData('developerTab');
//                               },
//                               child: Row(
//                                 children: [
//                                   _buildOpenLinkButton(tabIndex),
//                                   const SizedBox(
//                                     width: 10,
//                                   ),
//                                   _buildCopyLinkButton(tabIndex),
//                                   const SizedBox(
//                                     width: 30,
//                                   ),
//                                   _buildOpenWebLinkText(tabIndex),
//                                 ],
//                               ),
//                             ),
//                             const SizedBox(height: 20),
//                             MouseRegion(
//                               onEnter: (event) {
//                                 formController
//                                     .setSidebarData('hashRunsDotOrgCityLink');
//                               },
//                               onExit: (event) {
//                                 formController.setSidebarData('developerTab');
//                               },
//                               child: Row(
//                                 children: [
//                                   _buildOpenCityLinkButton(tabIndex),
//                                   const SizedBox(
//                                     width: 10,
//                                   ),
//                                   _buildCopyCityLinkButton(tabIndex),
//                                   const SizedBox(
//                                     width: 30,
//                                   ),
//                                   _buildOpenCityWebLinkText(tabIndex),
//                                 ],
//                               ),
//                             ),
//                             const SizedBox(height: 20),
//                             MouseRegion(
//                               onEnter: (event) {
//                                 formController
//                                     .setSidebarData('hashRunsDotOrgRegionLink');
//                               },
//                               onExit: (event) {
//                                 formController.setSidebarData('developerTab');
//                               },
//                               child: Row(
//                                 children: [
//                                   _buildOpenRegionLinkButton(tabIndex),
//                                   const SizedBox(
//                                     width: 10,
//                                   ),
//                                   _buildCopyRegionLinkButton(tabIndex),
//                                   const SizedBox(
//                                     width: 30,
//                                   ),
//                                   _buildOpenRegionWebLinkText(tabIndex),
//                                 ],
//                               ),
//                             ),
//                             const SizedBox(height: 20),
//                             MouseRegion(
//                               onEnter: (event) {
//                                 formController.setSidebarData(
//                                   'hashRunsDotOrgCountryLink',
//                                 );
//                               },
//                               onExit: (event) {
//                                 formController.setSidebarData('developerTab');
//                               },
//                               child: Row(
//                                 children: [
//                                   _buildOpenCountryLinkButton(tabIndex),
//                                   const SizedBox(
//                                     width: 10,
//                                   ),
//                                   _buildCopyCountryLinkButton(tabIndex),
//                                   const SizedBox(
//                                     width: 30,
//                                   ),
//                                   _buildOpenCountryWebLinkText(tabIndex),
//                                 ],
//                               ),
//                             ),
//                             HelperWidgets().categoryLabelWidget(
//                               'Web components',
//                             ),
//                             MouseRegion(
//                               onEnter: (event) {
//                                 formController
//                                     .setSidebarData('leaderboardLink');
//                               },
//                               onExit: (event) {
//                                 formController.setSidebarData('developerTab');
//                               },
//                               child: Row(
//                                 children: [
//                                   _buildOpenLeaderboardLinkButton(tabIndex),
//                                   const SizedBox(
//                                     width: 10,
//                                   ),
//                                   _buildCopyLeaderboardLinkButton(tabIndex),
//                                   const SizedBox(
//                                     width: 10,
//                                   ),
//                                   MouseRegion(
//                                     onEnter: (event) {
//                                       formController
//                                           .setSidebarData('iframeDescription');
//                                     },
//                                     onExit: (event) {
//                                       formController
//                                           .setSidebarData('developerTab');
//                                     },
//                                     child: _buildCopyLeaderboardIframeButton(
//                                       tabIndex,
//                                     ),
//                                   ),
//                                   const SizedBox(
//                                     width: 30,
//                                   ),
//                                   _buildOpenLeaderboardWebLinkText(tabIndex),
//                                 ],
//                               ),
//                             ),
//                             HelperWidgets().categoryLabelWidget(
//                               'Data APIs',
//                             ),
//                             MouseRegion(
//                               onEnter: (event) {
//                                 formController.setSidebarData('eventsListApi');
//                               },
//                               onExit: (event) {
//                                 formController.setSidebarData('developerTab');
//                               },
//                               child: Row(
//                                 children: [
//                                   _buildOpenEventsApiLinkButton(tabIndex),
//                                   const SizedBox(
//                                     width: 10,
//                                   ),
//                                   _buildCopyEventsApiLinkButton(tabIndex),
//                                   const SizedBox(
//                                     width: 10,
//                                   ),
//                                   const SizedBox(
//                                     width: 30,
//                                   ),
//                                   _buildOpenEventsApiWebLinkText(tabIndex),
//                                 ],
//                               ),
//                             ),
//                             const SizedBox(height: 20),
//                             MouseRegion(
//                               onEnter: (event) {
//                                 formController.setSidebarData('nextRunApi');
//                               },
//                               onExit: (event) {
//                                 formController.setSidebarData('developerTab');
//                               },
//                               child: Row(
//                                 children: [
//                                   _buildOpenNextRunApiButton(tabIndex),
//                                   const SizedBox(
//                                     width: 10,
//                                   ),
//                                   _buildCopyNextRunApiButton(tabIndex),
//                                   const SizedBox(
//                                     width: 10,
//                                   ),
//                                   const SizedBox(
//                                     width: 30,
//                                   ),
//                                   _buildOpenNextRunApiText(tabIndex),
//                                 ],
//                               ),
//                             ),
//                             const SizedBox(height: 20),
//                             MouseRegion(
//                               onEnter: (event) {
//                                 formController.setSidebarData('leaderboardApi');
//                               },
//                               onExit: (event) {
//                                 formController.setSidebarData('developerTab');
//                               },
//                               child: Row(
//                                 children: [
//                                   _buildOpenLeaderboardApiButton(tabIndex),
//                                   const SizedBox(
//                                     width: 10,
//                                   ),
//                                   _buildCopyLeaderboardApiButton(tabIndex),
//                                   const SizedBox(
//                                     width: 10,
//                                   ),
//                                   const SizedBox(
//                                     width: 30,
//                                   ),
//                                   _buildOpenLeaderboardApiText(tabIndex),
//                                 ],
//                               ),
//                             ),
//                             HelperWidgets().categoryLabelWidget(
//                               'WordPress Toolbox',
//                             ),
//                             MouseRegion(
//                               onEnter: (event) {
//                                 formController
//                                     .setSidebarData('wordpressToolbox');
//                               },
//                               onExit: (event) {
//                                 formController.setSidebarData('developerTab');
//                               },
//                               child: Row(
//                                 children: [
//                                   _buildDownloadWordPressPlugin(tabIndex),
//                                   const SizedBox(
//                                     width: 30,
//                                   ),
//                                   _buildWordPressTxtField(tabIndex),
//                                 ],
//                               ),
//                             ),
//                             const SizedBox(height: 20),
//                             MouseRegion(
//                               onEnter: (event) {
//                                 formController
//                                     .setSidebarData('masterDetailShortcode');
//                               },
//                               onExit: (event) {
//                                 formController.setSidebarData('developerTab');
//                               },
//                               child: Row(
//                                 children: [
//                                   _buildDemoShortcodeMasterDetailButton(
//                                     tabIndex,
//                                   ),
//                                   const SizedBox(
//                                     width: 10,
//                                   ),
//                                   _buildCopytShortcodeMasterDetailButton(
//                                     tabIndex,
//                                   ),
//                                   const SizedBox(
//                                     width: 30,
//                                   ),
//                                   _buildShortcodeMasterDetailText(tabIndex),
//                                 ],
//                               ),
//                             ),
//                             const SizedBox(height: 20),
//                             MouseRegion(
//                               onEnter: (event) {
//                                 formController
//                                     .setSidebarData('galleryShortcode');
//                               },
//                               onExit: (event) {
//                                 formController.setSidebarData('developerTab');
//                               },
//                               child: Row(
//                                 children: [
//                                   _buildDemoShortcodeGalleryButton(tabIndex),
//                                   const SizedBox(
//                                     width: 10,
//                                   ),
//                                   _buildCopytShortcodeGalleryButton(tabIndex),
//                                   const SizedBox(
//                                     width: 30,
//                                   ),
//                                   _buildShortcodeGalleryText(tabIndex),
//                                 ],
//                               ),
//                             ),
//                             const SizedBox(height: 20),
//                             MouseRegion(
//                               onEnter: (event) {
//                                 formController.setSidebarData('tableShortcode');
//                               },
//                               onExit: (event) {
//                                 formController.setSidebarData('developerTab');
//                               },
//                               child: Row(
//                                 children: [
//                                   _buildDemoShortcodeTableButton(tabIndex),
//                                   const SizedBox(
//                                     width: 10,
//                                   ),
//                                   _buildCopytShortcodeTableButton(tabIndex),
//                                   const SizedBox(
//                                     width: 30,
//                                   ),
//                                   _buildShortcodeTableText(tabIndex),
//                                 ],
//                               ),
//                             ),
//                             const SizedBox(height: 20),
//                             MouseRegion(
//                               onEnter: (event) {
//                                 formController
//                                     .setSidebarData('nextRunShortcode');
//                               },
//                               onExit: (event) {
//                                 formController.setSidebarData('developerTab');
//                               },
//                               child: Row(
//                                 children: [
//                                   _buildDemoShortcodeNextRunButton(tabIndex),
//                                   const SizedBox(
//                                     width: 10,
//                                   ),
//                                   _buildCopytShortcodeNextRunButton(tabIndex),
//                                   const SizedBox(
//                                     width: 30,
//                                   ),
//                                   _buildShortcodeNextRunText(tabIndex),
//                                 ],
//                               ),
//                             ),
//                             const SizedBox(height: 20),
//                             MouseRegion(
//                               onEnter: (event) {
//                                 formController
//                                     .setSidebarData('leaderboardShortcode');
//                               },
//                               onExit: (event) {
//                                 formController.setSidebarData('developerTab');
//                               },
//                               child: Row(
//                                 children: [
//                                   _buildDemoShortcodeLeaderboardButton(
//                                     tabIndex,
//                                   ),
//                                   const SizedBox(
//                                     width: 10,
//                                   ),
//                                   _buildCopytShortcodeLeaderboardButton(
//                                     tabIndex,
//                                   ),
//                                   const SizedBox(
//                                     width: 30,
//                                   ),
//                                   _buildShortcodeLeaderboardText(tabIndex),
//                                 ],
//                               ),
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

//   Widget _buildKennelPublicIdField(int tabIndex) {
//     return Expanded(
//       child: _buildTextField(
//         controller: formController.kennelPublicId,
//         //focusNode: formController.focusNodes['kennelWebsiteUrl'],
//         label: 'Public Kennel ID',
//         readOnly: true,
//       ),
//     );
//   }

//   Widget _buildCopyKennelPublicIdButton(int tabIndex) {
//     return _buildButton(
//       formController.originalData!.kennelPublicId.toString(),
//       ButtonAction.copy,
//       linkFullTitle:
//           'The public ID for ${formController.originalData!.kennelName}\r\n\r\nhas been copied to your clipboard.',
//     );
//   }

//   Widget _buildDemoShortcodeNextRunButton(int tabIndex) {
//     return Obx(() {
//       return _buildButton(
//         'https://harriercentral.com/nextrun?apikey=${formController.editedData!.extApiKey}&publickennelid=${formController.editedData!.kennelPublicId}',
//         stateUpdater: formController.extApiStateUpdater.value,
//         ButtonAction.demo,
//       );
//     });
//   }

//   Widget _buildCopytShortcodeLeaderboardButton(int tabIndex) {
//     return Obx(() {
//       return _buildButton(
//         '[harrier_leaderboard bgcolor="#f0f8ff" fontfamily="Georgia, serif" fontcolor="#000000" apikey="${formController.editedData!.extApiKey}" publickennelid="${formController.editedData!.kennelPublicId}"]',
//         ButtonAction.copy,
//         stateUpdater: formController.extApiStateUpdater.value,
//         linkFullTitle:
//             "The WordPress shortcode for ${formController.originalData!.kennelName}'s\r\n\r\next run has been copied to your clipboard.",
//       );
//     });
//   }

//   Widget _buildShortcodeLeaderboardText(int tabIndex) {
//     return Text(
//       'Run counts / Leaderboard Shortcode',
//       style: bodyStyleBlack,
//     );
//   }

//   Widget _buildDemoShortcodeLeaderboardButton(int tabIndex) {
//     return Obx(() {
//       return _buildButton(
//         'https://harriercentral.com/leaderboard?apikey=${formController.editedData!.extApiKey}&publickennelid=${formController.editedData!.kennelPublicId}',
//         stateUpdater: formController.extApiStateUpdater.value,
//         ButtonAction.demo,
//       );
//     });
//   }

//   Widget _buildCopytShortcodeNextRunButton(int tabIndex) {
//     return Obx(() {
//       return _buildButton(
//         '[next_run bgcolor="#f0f8ff" fontfamily="Georgia, serif" fontcolor="#000000" apikey="${formController.editedData!.extApiKey}" publickennelid="${formController.editedData!.kennelPublicId}" showmapbutton="true"]',
//         ButtonAction.copy,
//         stateUpdater: formController.extApiStateUpdater.value,
//         linkFullTitle:
//             "The WordPress shortcode for ${formController.originalData!.kennelName}'s\r\n\r\next run has been copied to your clipboard.",
//       );
//     });
//   }

//   Widget _buildShortcodeNextRunText(int tabIndex) {
//     return Text(
//       'Next Run Shortcode',
//       style: bodyStyleBlack,
//     );
//   }

//   Widget _buildShortcodeTableText(int tabIndex) {
//     return Text(
//       'Runs Table Shortcode',
//       style: bodyStyleBlack,
//     );
//   }

//   Widget _buildDemoShortcodeTableButton(int tabIndex) {
//     return Obx(() {
//       return _buildButton(
//         'https://harriercentral.com/demogridpast?apikey=${formController.editedData!.extApiKey}&publickennelid=${formController.editedData!.kennelPublicId}',
//         stateUpdater: formController.extApiStateUpdater.value,
//         ButtonAction.demo,
//       );
//     });
//   }

//   Widget _buildCopytShortcodeTableButton(int tabIndex) {
//     return Obx(() {
//       return _buildButton(
//         '[harrier_grid timeframe="past" bgcolor="#f0f8ff" fontfamily="Georgia, serif" fontcolor="#000000" apikey="${formController.editedData!.extApiKey}" publickennelid="${formController.editedData!.kennelPublicId}" columns="3" hidedescription="true" showmapbutton="true"]',
//         ButtonAction.copy,
//         stateUpdater: formController.extApiStateUpdater.value,
//         linkFullTitle:
//             'The WordPress shortcode for a ${formController.originalData!.kennelName}\r\n\r\ntable view of runs has been copied to your clipboard.',
//       );
//     });
//   }

//   Widget _buildShortcodeGalleryText(int tabIndex) {
//     return Text(
//       'Runs Gallery Shortcode',
//       style: bodyStyleBlack,
//     );
//   }

//   Widget _buildDemoShortcodeGalleryButton(int tabIndex) {
//     return Obx(() {
//       return _buildButton(
//         'https://harriercentral.com/demogallerypast?apikey=${formController.editedData!.extApiKey}&publickennelid=${formController.editedData!.kennelPublicId}',
//         stateUpdater: formController.extApiStateUpdater.value,
//         ButtonAction.demo,
//       );
//     });
//   }

//   Widget _buildCopytShortcodeGalleryButton(int tabIndex) {
//     return Obx(() {
//       return _buildButton(
//         '[harrier_gallery timeframe="past" bgcolor="#f0f8ff" fontfamily="Georgia, serif" fontcolor="#000000" apikey="${formController.editedData!.extApiKey}" publickennelid="${formController.editedData!.kennelPublicId}" columns="3" hidedescription="true" showmapbutton="true"]',
//         ButtonAction.copy,
//         stateUpdater: formController.extApiStateUpdater.value,
//         linkFullTitle:
//             'The WordPress shortcode for a ${formController.originalData!.kennelName}\r\n\r\ngallery view of runs has been copied to your clipboard.',
//       );
//     });
//   }

//   Widget _buildShortcodeMasterDetailText(int tabIndex) {
//     return Text(
//       'List/Detail Shortcode',
//       style: bodyStyleBlack,
//     );
//   }

//   Widget _buildDemoShortcodeMasterDetailButton(int tabIndex) {
//     return Obx(() {
//       return _buildButton(
//         'https://harriercentral.com/demomasterdetailpast?apikey=${formController.editedData!.extApiKey}&publickennelid=${formController.editedData!.kennelPublicId}',
//         stateUpdater: formController.extApiStateUpdater.value,
//         ButtonAction.demo,
//       );
//     });
//   }

//   Widget _buildCopytShortcodeMasterDetailButton(int tabIndex) {
//     return Obx(() {
//       return _buildButton(
//         '[harrier_runs timeframe="past" bgcolor="#f0f8ff" fontfamily="Georgia, serif" fontcolor="#000000" apikey="${formController.editedData!.extApiKey}" publickennelid="${formController.editedData!.kennelPublicId}" showmapbutton="true"]',
//         ButtonAction.copy,
//         stateUpdater: formController.extApiStateUpdater.value,
//         linkFullTitle:
//             'The WordPress shortcode for a ${formController.originalData!.kennelName}\r\n\r\nMaster/Detail view of runs has been copied to your clipboard.',
//       );
//     });
//   }

//   Widget _buildWordPressTxtField(int tabIndex) {
//     return Text(
//       'Harrier Central WordPress Toolbox plug-in (version 0.9 / Dec 31, 2024)',
//       style: bodyStyleBlack,
//     );
//   }

//   Widget _buildDownloadWordPressPlugin(int tabIndex) {
//     return _buildButton(
//       'https://harriercentral.blob.core.windows.net/wordpress-plugin/harrier-central-wordpress-toolbox-0_9.zip',
//       ButtonAction.download,
//       buttonWidth: 200,
//     );
//   }

//   Widget _buildExtApiKeyField(int tabIndex) {
//     return Expanded(
//       child: _buildTextField(
//         controller: formController.extApiKey,
//         //focusNode: formController.focusNodes['kennelWebsiteUrl'],
//         label: 'API Secret Key',
//         readOnly: true,
//       ),
//     );
//   }

//   Widget _buildCopyExtApiButton(int tabIndex) {
//     return Obx(() {
//       return _buildButton(
//         formController.originalData!.extApiKey,
//         ButtonAction.copy,
//         stateUpdater: formController.extApiStateUpdater.value,
//         linkFullTitle:
//             'The API Key for ${formController.originalData!.kennelName}\r\n\r\nhas been copied to your clipboard.',
//       );
//     });
//   }

//   Widget _buildOpenWebLinkText(int tabIndex) {
//     return Text(
//       'HashRuns.org link for ${formController.editedData?.kennelName ?? 'your Kennel.'}',
//       style: bodyStyleBlack,
//     );
//   }

//   Widget _buildCopyLinkButton(int tabIndex) {
//     return _buildButton(
//       'https://www.hashruns.org/#/RD?publicKennelIds=${formController.originalData!.kennelPublicId}',
//       ButtonAction.copy,
//       linkTitle: formController.editedData?.kennelName ?? 'your Kennel.',
//     );
//   }

//   Widget _buildOpenLinkButton(int tabIndex) {
//     return _buildButton(
//       'https://www.hashruns.org/#/RD?publicKennelIds=${formController.originalData!.kennelPublicId}',
//       ButtonAction.open,
//     );
//   }

//   Widget _buildOpenCityWebLinkText(int tabIndex) {
//     return Text(
//       'HashRuns.org link for ${formController.editedData?.cityName ?? 'your city.'}',
//       style: bodyStyleBlack,
//     );
//   }

//   Widget _buildCopyCityLinkButton(int tabIndex) {
//     return _buildButton(
//       'https://www.hashruns.org/#/RD?cityIds=${formController.originalData!.cityId}',
//       ButtonAction.copy,
//       linkTitle: formController.editedData?.cityName ?? 'your city.',
//     );
//   }

//   Widget _buildOpenCityLinkButton(int tabIndex) {
//     return _buildButton(
//       'https://www.hashruns.org/#/RD?cityIds=${formController.originalData!.cityId}',
//       ButtonAction.open,
//     );
//   }

//   Widget _buildOpenRegionWebLinkText(int tabIndex) {
//     return Text(
//       'HashRuns.org link for ${formController.editedData?.regionName ?? 'your state, province or region.'}',
//       style: bodyStyleBlack,
//     );
//   }

//   Widget _buildCopyRegionLinkButton(int tabIndex) {
//     return _buildButton(
//       'https://www.hashruns.org/#/RD?regionIds=${formController.originalData!.provinceStateId}',
//       ButtonAction.copy,
//       linkTitle: formController.editedData?.regionName ??
//           'your state, province or region.',
//     );
//   }

//   Widget _buildOpenRegionLinkButton(int tabIndex) {
//     return _buildButton(
//       'https://www.hashruns.org/#/RD?regionIds=${formController.originalData!.provinceStateId}',
//       ButtonAction.open,
//     );
//   }

//   Widget _buildOpenCountryWebLinkText(int tabIndex) {
//     return Text(
//       'HashRuns.org link for ${formController.editedData?.countryName ?? 'your country.'}',
//       style: bodyStyleBlack,
//     );
//   }

//   Widget _buildCopyCountryLinkButton(int tabIndex) {
//     return _buildButton(
//       'https://www.hashruns.org/#/RD?countryIds=${formController.originalData!.countryId}',
//       ButtonAction.copy,
//       linkTitle: formController.editedData?.countryName ?? 'your country.',
//     );
//   }

//   Widget _buildOpenCountryLinkButton(int tabIndex) {
//     return _buildButton(
//       'https://www.hashruns.org/#/RD?countryIds=${formController.originalData!.countryId}',
//       ButtonAction.open,
//     );
//   }

//   Widget _buildOpenLeaderboardWebLinkText(int tabIndex) {
//     return Text('Run Count / Leaderboard web component', style: bodyStyleBlack);
//   }

//   Widget _buildCopyLeaderboardLinkButton(int tabIndex) {
//     return _buildButton(
//       'https://www.harriercentral.com/kennelrunsshort?PublicKennelId=${formController.originalData!.kennelPublicId}&Report=allRuns&NumRecords=500&SortByColNum=4&SortAscending=0&ShowTools=yes',
//       ButtonAction.copy,
//       linkTitle: 'Kennel Leaderboard',
//     );
//   }

//   Widget _buildCopyLeaderboardIframeButton(int tabIndex) {
//     return _buildButton(
//       '<iframe src="https://www.harriercentral.com/kennelrunsshort?PublicKennelId=${formController.originalData!.kennelPublicId}&Report=allRuns&NumRecords=500&SortByColNum=4&SortAscending=0&ShowTools=yes" style="border-width:0" width="650" height="7300" frameborder="0" scrolling="no"></iframe>',
//       ButtonAction.copy,
//       buttonText: 'Copy iframe',
//       buttonWidth: 150,
//       linkFullTitle:
//           'HTML code containing an <iframe> element\r\nwas copied to the clipboard',
//     );
//   }

//   Widget _buildOpenLeaderboardLinkButton(int tabIndex) {
//     return _buildButton(
//       'https://www.harriercentral.com/kennelrunsshort?PublicKennelId=${formController.originalData!.kennelPublicId}&Report=allRuns&NumRecords=500&SortByColNum=4&SortAscending=0&ShowTools=yes',
//       ButtonAction.open,
//     );
//   }

//   Widget _buildOpenEventsApiWebLinkText(int tabIndex) {
//     return Text(
//       'API for ${formController.editedData?.kennelName ?? 'your Kennel.'} future event list',
//       style: bodyStyleBlack,
//     );
//   }

//   Widget _buildCopyEventsApiLinkButton(int tabIndex) {
//     return Obx(() {
//       return _buildButton(
//         '$BASE_API_URL/PublicApi?PublicKennelId=${formController.editedData?.kennelPublicId}&ApiKey=${formController.editedData?.extApiKey}&queryType=getEvents&numberOfRecords=1000&pastOrFuture=future&sortOrder=ASC&fullDetails=0&weeksToDisplay=104',
//         ButtonAction.copy,
//         stateUpdater: formController.extApiStateUpdater.value,
//         linkFullTitle:
//             'Link copied to public data API for events for ${formController.editedData?.kennelName ?? 'your Kennel.'}',
//       );
//     });
//   }

//   Widget _buildOpenEventsApiLinkButton(int tabIndex) {
//     return Obx(() {
//       return _buildButton(
//         '$BASE_API_URL/PublicApi?PublicKennelId=${formController.editedData?.kennelPublicId}&ApiKey=${formController.editedData?.extApiKey}&queryType=getEvents&numberOfRecords=1000&pastOrFuture=future&sortOrder=ASC&fullDetails=0&weeksToDisplay=104',
//         ButtonAction.open,
//         stateUpdater: formController.extApiStateUpdater.value,
//       );
//     });
//   }

//   Widget _buildOpenNextRunApiText(int tabIndex) {
//     return Text(
//       'API call to return next run for ${formController.editedData?.kennelName ?? 'your Kennel.'}',
//       style: bodyStyleBlack,
//     );
//   }

//   Widget _buildCopyNextRunApiButton(int tabIndex) {
//     return Obx(() {
//       return _buildButton(
//         '$BASE_API_URL/PublicApi?PublicKennelId=${formController.editedData?.kennelPublicId}&ApiKey=${formController.editedData?.extApiKey}&queryType=getEvents&numberOfRecords=1&pastOrFuture=future&sortOrder=ASC&fullDetails=1&weeksToDisplay=104',
//         ButtonAction.copy,
//         stateUpdater: formController.extApiStateUpdater.value,
//         linkFullTitle:
//             'Link copied to public data API for events for ${formController.editedData?.kennelName ?? 'your Kennel.'}',
//       );
//     });
//   }

//   Widget _buildOpenNextRunApiButton(int tabIndex) {
//     return Obx(() {
//       return _buildButton(
//         '$BASE_API_URL/PublicApi?PublicKennelId=${formController.editedData?.kennelPublicId}&ApiKey=${formController.editedData?.extApiKey}&queryType=getEvents&numberOfRecords=1&pastOrFuture=future&sortOrder=ASC&fullDetails=1&weeksToDisplay=104',
//         ButtonAction.open,
//         stateUpdater: formController.extApiStateUpdater.value,
//       );
//     });
//   }

//   Widget _buildOpenLeaderboardApiText(int tabIndex) {
//     return Text(
//       'API call to return run counts for ${formController.editedData?.kennelName ?? 'your Kennel.'}',
//       style: bodyStyleBlack,
//     );
//   }

//   Widget _buildCopyLeaderboardApiButton(int tabIndex) {
//     return Obx(() {
//       return _buildButton(
//         '$BASE_API_URL/PublicApi?PublicKennelId=${formController.editedData?.kennelPublicId}&ApiKey=${formController.editedData?.extApiKey}&queryType=getLeaderboard&numberOfRecords=1000',
//         ButtonAction.copy,
//         stateUpdater: formController.extApiStateUpdater.value,
//         linkFullTitle:
//             'Link copied to public data API for run counts for ${formController.editedData?.kennelName ?? 'your Kennel.'}',
//       );
//     });
//   }

//   Widget _buildOpenLeaderboardApiButton(int tabIndex) {
//     return Obx(() {
//       return _buildButton(
//         '$BASE_API_URL/PublicApi?PublicKennelId=${formController.editedData?.kennelPublicId}&ApiKey=${formController.editedData?.extApiKey}&queryType=getLeaderboard&numberOfRecords=1000',
//         ButtonAction.open,
//         stateUpdater: formController.extApiStateUpdater.value,
//       );
//     });
//   }

//   Widget _buildRegenerateApiKeyButton() {
//     return SizedBox(
//       width: 170,
//       child: ElevatedButton(
//         child: Baseline(
//           baseline: 16,
//           baselineType: TextBaseline.alphabetic,
//           child: Text(
//             'Regenerate Key',
//             style: buttonLabelStyleMedium,
//           ),
//         ),
//         onPressed: () async {
//           final doUpdateKey = await CoreUtilities.showAlert(
//             'Regenerate API Key',
//             'You are about to generate your Private API Key for ${formController.editedData!.kennelName}.\r\n\r\nThis will require that you replace the current Private API Key in all\r\nof your API calls to continue to access the Harrier Central Platform.\r\n\r\nAre you sure you want to do this?',
//             'Yes',
//             showCancelButton: true,
//             cancelButtonText: 'No',
//           );

//           if (doUpdateKey ?? false) {
//             final publicHasherId = await box.get(HIVE_HASHER_ID) as String;
//             final accessToken = Utilities.generateToken(
//               publicHasherId,
//               'hcportal_regenerateExtApiKey',
//               paramString:
//                   formController.originalData!.kennelPublicId.toString(),
//             );
//             final body = <String, String>{
//               'queryType': 'regenerateExtApiKey',
//               'publicHasherId': publicHasherId,
//               'accessToken': accessToken,
//               'publicKennelId':
//                   formController.originalData!.kennelPublicId.toString(),
//               'currentExtApiKey': formController.originalData!.extApiKey,
//             };

//             final jsonResult =
//                 await ServiceCommon.sendHttpPostToAzureFunctionApi(body);
//             if (jsonResult.length > 10) {
//               final jsonItems = json.decode(jsonResult) as List<dynamic>;
//               final result =
//                   ((jsonItems[0]) as List<dynamic>)[0] as Map<String, dynamic>;
//               final newExtApiKey = result['newExtApiKey'].toString();
//               formController
//                 ..editedData =
//                     formController.editedData?.copyWith(extApiKey: newExtApiKey)
//                 ..originalData = formController.originalData
//                     ?.copyWith(extApiKey: newExtApiKey);
//               formController.extApiKey.text = newExtApiKey;
//               formController.extApiStateUpdater++;

//               await CoreUtilities.showAlert(
//                 'API Key Regenerated',
//                 'A new API key has been generated for ${formController.editedData!.kennelName}.\r\n\r\nPlease copy the new key and replace any previous API Keys\r\n\r\nwith the new one to access the Harrier Central Platform.',
//                 'OK',
//               );
//             }
//           }
//         },
//       ),
//     );
//   }

//   Widget _buildButton(
//     String link,
//     ButtonAction action, {
//     String? linkTitle,
//     String? linkFullTitle,
//     String? buttonText,
//     double? buttonWidth,
//     int?
//         stateUpdater, // this parameter doesn't really do anything other than to fool GetX into updating the values of a button when the state changes
//   }) {
//     return SizedBox(
//       width: buttonWidth ?? 95,
//       child: ElevatedButton(
//         child: Baseline(
//           baseline: 16,
//           baselineType: TextBaseline.alphabetic,
//           child: Text(
//             buttonText ??
//                 (action == ButtonAction.open
//                     ? 'Try it'
//                     : action == ButtonAction.copy
//                         ? 'Copy'
//                         : action == ButtonAction.download
//                             ? 'Download'
//                             : 'Try it'),
//             style: buttonLabelStyleMedium,
//           ),
//         ),
//         onPressed: () async {
//           if ((action == ButtonAction.open) ||
//               (action == ButtonAction.demo) ||
//               (action == ButtonAction.download)) {
//             final url = Uri.parse(link);
//             // if (await canLaunchUrl(url)) {
//             await launchUrl(
//               url,
//               mode: LaunchMode
//                   .externalApplication, // Opens in a new window or browser
//             );
//           } else if (action == ButtonAction.copy) {
//             await Clipboard.setData(ClipboardData(text: link));

//             await CoreUtilities.showAlert(
//               'Link Copied',
//               linkFullTitle ??
//                   (linkTitle == null
//                       ? 'A link was copied to your clipboard'
//                       : 'The link to $linkTitle\r\nwas copied to the clipboard'),
//               'OK',
//             );
//           }
//         },
//       ),
//     );
//   }
// }
