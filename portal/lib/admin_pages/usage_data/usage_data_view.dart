// // usage_data_page.dart

// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:hcportal/imports.dart';

// class UsageDataPage extends StatelessWidget {
//   const UsageDataPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.isRegistered<UsageDataController>()
//         ? Get.find<UsageDataController>()
//         : Get.put(UsageDataController());

//     return Obx(() => Scaffold(
//           appBar: AppBar(
//             title: const Text('Usage Data'),
//             leading: GestureDetector(
//               onTap: () => Get.back<void>(),
//               child: const Icon(
//                 MaterialCommunityIcons.arrow_left,
//                 color: Colors.black,
//               ),
//             ),
//           ),
//           body: Row(
//             children: <Widget>[
//               Expanded(
//                   flex: 25, child: _recentHasherLogins(context, controller)),
//               const VerticalDivider(color: Colors.grey, thickness: 1, width: 1),
//               Expanded(
//                 flex: 65,
//                 child: Column(
//                   children: <Widget>[
//                     Expanded(flex: 60, child: _appStats(context, controller)),
//                     Expanded(
//                         flex: 20,
//                         child: _integrationStats(context, controller)),
//                     const Divider(color: Colors.grey, height: 1, thickness: 1),
//                     Expanded(flex: 20, child: _newEventsWidget(controller)),
//                   ],
//                 ),
//               ),
//               const VerticalDivider(color: Colors.grey, thickness: 1, width: 1),
//               Expanded(flex: 10, child: _hcVersionColumn(context, controller)),
//             ],
//           ),
//         ));
//   }

//   Widget _newEventsWidget(UsageDataController controller) {
//     return CarouselSlider(
//       options: CarouselOptions(height: 130, autoPlay: true),
//       items: controller.newEvents.map((evt) {
//         return Builder(
//           builder: (BuildContext context) {
//             return GestureDetector(
//               onTap: () {
//                 if (evt.publicEventId.isNotEmpty) {
//                   openWindow(
//                     'https://www.hashruns.org/#/RID?publicEventId=${evt.publicEventId}&textTheme=light',
//                     '_blank',
//                   );
//                 }
//               },
//               child: Row(
//                 children: <Widget>[
//                   const VerticalDivider(
//                       color: Colors.grey, thickness: 1, width: 1),
//                   KennelLogo(
//                     kennelLogoUrl: evt.kennelLogo,
//                     kennelShortName: evt.kennelShortName,
//                     logoHeight: 100.0,
//                     leftPadding: 15.0,
//                   ),
//                   Expanded(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: <Widget>[
//                         Expanded(
//                           child: Container(
//                             width: MediaQuery.of(context).size.width,
//                             margin: const EdgeInsets.symmetric(horizontal: 5),
//                             child: AutoSizeText(
//                               '${evt.kennelName} (${evt.kennelShortName})',
//                               style: const TextStyle(
//                                 fontSize: 16,
//                                 fontFamily: 'AvenirNextDemiBold',
//                               ),
//                               maxLines: 1,
//                               maxFontSize: 32,
//                               minFontSize: 5,
//                             ),
//                           ),
//                         ),
//                         Expanded(
//                           child: Container(
//                             width: MediaQuery.of(context).size.width,
//                             margin: const EdgeInsets.symmetric(horizontal: 5),
//                             child: AutoSizeText(
//                               evt.activityLastDay > 0
//                                   ? '[${evt.activityLastDay}] ${evt.eventName}'
//                                   : evt.eventName,
//                               maxLines: 1,
//                               minFontSize: 10,
//                               maxFontSize: 20,
//                               overflow: TextOverflow.ellipsis,
//                               style: TextStyle(
//                                 color: Colors.blue.shade800,
//                                 fontSize: 20,
//                                 fontFamily: 'AvenirNextBold',
//                               ),
//                             ),
//                           ),
//                         ),
//                         Expanded(
//                           child: Container(
//                             width: MediaQuery.of(context).size.width,
//                             margin: const EdgeInsets.symmetric(horizontal: 5),
//                             child: AutoSizeText(
//                               evt.minutesUntilRun > 0
//                                   ? evt.minutesUntilRun < 60
//                                       ? 'Run starts in ${evt.minutesUntilRun} minutes'
//                                       : evt.minutesUntilRun < 1440
//                                           ? 'Run starts in ${evt.minutesUntilRun ~/ 60} hours, ${evt.minutesUntilRun % 60} minutes'
//                                           : 'Run starts in ${evt.minutesUntilRun ~/ 1440} days, ${(evt.minutesUntilRun % 1440) ~/ 60} hours, ${evt.minutesUntilRun % 60} minutes'
//                                   : evt.minutesUntilRun > -60
//                                       ? 'Run started ${-evt.minutesUntilRun} minutes ago'
//                                       : evt.minutesUntilRun > -1440
//                                           ? 'Run started ${(-evt.minutesUntilRun) ~/ 60} hours, ${(-evt.minutesUntilRun) % 60} minutes ago'
//                                           : 'Run started ${(-evt.minutesUntilRun) ~/ 1440} days, ${((-evt.minutesUntilRun) % 1440) ~/ 60} hours, ${(-evt.minutesUntilRun) % 60} minutes ago',
//                               style: const TextStyle(
//                                 fontSize: 20,
//                                 fontFamily: 'AvenirNextDemiBold',
//                               ),
//                               maxLines: 1,
//                               maxFontSize: 32,
//                               minFontSize: 5,
//                             ),
//                           ),
//                         ),
//                         Expanded(
//                           child: Container(
//                             width: MediaQuery.of(context).size.width,
//                             margin: const EdgeInsets.symmetric(horizontal: 5),
//                             child: AutoSizeText(
//                               evt.minutesAgoCreated - 2 > evt.minutesAgoUpdated
//                                   ? evt.minutesAgoUpdated < 60
//                                       ? 'Updated ${evt.minutesAgoUpdated} minutes ago'
//                                       : 'Updated ${evt.minutesAgoUpdated ~/ 60} hours, ${evt.minutesAgoUpdated % 60} minutes ago'
//                                   : evt.minutesAgoCreated < 60
//                                       ? 'Created ${evt.minutesAgoCreated} minutes ago'
//                                       : 'Created ${evt.minutesAgoCreated ~/ 60} hours, ${evt.minutesAgoCreated % 60} minutes ago',
//                               style: const TextStyle(
//                                 fontSize: 20,
//                                 fontFamily: 'AvenirNextDemiBold',
//                               ),
//                               maxLines: 1,
//                               maxFontSize: 32,
//                               minFontSize: 5,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       }).toList(),
//     );
//   }

//   Widget _hcVersionColumn(
//       BuildContext context, UsageDataController controller) {
//     return SingleChildScrollView(
//       primary: false,
//       child: Column(
//         children: controller.hcVersions.map((hcVer) {
//           final value = hcVer.isNotiPhone + hcVer.isiPhone;
//           final lightness = ((((value /
//                               (controller.maxHcVersion.value == 0
//                                   ? 1
//                                   : controller.maxHcVersion.value)) /
//                           2.0) -
//                       0.85)
//                   .abs())
//               .clamp(0.0, 1.0);
//           final textColor = lightness < 0.7 ? Colors.white : Colors.black;
//           return Column(
//             children: [
//               GestureDetector(
//                 onTap: () => controller.getHcVersionDetail(
//                     hcVer.versionNum, hcVer.buildNum, context),
//                 child: Container(
//                   width: 150,
//                   height: 100,
//                   color: HSLColor.fromColor(Colors.purple)
//                       .withLightness(lightness)
//                       .toColor(),
//                   child: Column(
//                     children: [
//                       const SizedBox(height: 6),
//                       AutoSizeText('${hcVer.versionNum}/${hcVer.buildNum}',
//                           style: TextStyle(fontSize: 22, color: textColor),
//                           maxLines: 1),
//                       AutoSizeText(value.toString(),
//                           style: TextStyle(fontSize: 36, color: textColor),
//                           maxLines: 1),
//                       AutoSizeText('${hcVer.isiPhone} / ${hcVer.isNotiPhone}',
//                           style: TextStyle(fontSize: 18, color: textColor),
//                           maxLines: 1),
//                     ],
//                   ),
//                 ),
//               ),
//               const Divider(color: Colors.grey, thickness: 1, height: 1),
//             ],
//           );
//         }).toList(),
//       ),
//     );
//   }

//   Widget _integrationStats(
//       BuildContext context, UsageDataController controller) {
//     if (controller.integrationMonitor.length < 3)
//       return const SizedBox.shrink();
//     return Row(
//       children: controller.integrationMonitor.take(3).map((integration) {
//         final bgColor = integration.integrationEnabled == 0
//             ? Colors.grey.shade200
//             : HSLColor.fromColor(
//                 integration.minutesAgo <= integration.interval
//                     ? Colors.green
//                     : Colors.red,
//               )
//                 .withLightness(
//                   1 -
//                       ((integration.minutesAgo / (integration.interval + .0))
//                                       .clamp(0.0, 2.0) -
//                                   1.0)
//                               .abs() *
//                           0.5,
//                 )
//                 .toColor();
//         return Expanded(
//           child: GestureDetector(
//             onTap: () =>
//                 controller.integrationBlockPressed(integration, context),
//             child: Container(
//               height: 170,
//               color: bgColor,
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(integration.integrationAbbreviation,
//                       style: const TextStyle(fontSize: 24)),
//                   Text('${integration.minutesAgo} min',
//                       style: const TextStyle(fontSize: 32)),
//                   Text(
//                       '${integration.recordsRead} read / ${integration.errorCount} errors'),
//                   Text(
//                       '${integration.kennelsSucceeded} Nice / ${integration.kennelsFailed} Naughty'),
//                 ],
//               ),
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }

//   Widget _appStats(BuildContext context, UsageDataController controller) {
//     if (controller.appActivity.isEmpty) return const SizedBox.shrink();

//     List<Widget> rows = [
//       Row(
//         children: const [
//           Expanded(child: Text('')),
//           Expanded(child: Center(child: Text('Hour'))),
//           Expanded(child: Center(child: Text('Day'))),
//           Expanded(child: Center(child: Text('Week'))),
//           Expanded(child: Center(child: Text('Month'))),
//         ],
//       ),
//       const Divider(color: Colors.grey, height: 1, thickness: 1),
//     ];

//     for (int i = 0; i < controller.appActivity.length; i++) {
//       final data = controller.appActivity[i];
//       rows.add(Column(
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: Container(
//                   color: Colors.yellow.shade100,
//                   padding: const EdgeInsets.all(4),
//                   child: AutoSizeText(
//                     data.dataType,
//                     textAlign: TextAlign.end,
//                     style: const TextStyle(fontSize: 20),
//                     maxLines: 1,
//                     minFontSize: 5,
//                     maxFontSize: 32,
//                   ),
//                 ),
//               ),
//               ..._appStatsCell(
//                   context, controller, i, 0, data.lastHour, data.lastHourComp),
//               ..._appStatsCell(
//                   context, controller, i, 1, data.lastDay, data.lastDayComp),
//               ..._appStatsCell(
//                   context, controller, i, 7, data.lastWeek, data.lastWeekComp),
//               ..._appStatsCell(context, controller, i, -1, data.lastMonth,
//                   data.lastMonthComp),
//             ],
//           ),
//           const Divider(color: Colors.grey, height: 1, thickness: 1),
//         ],
//       ));
//     }

//     return Column(children: rows);
//   }

//   Widget _recentHasherLogins(
//       BuildContext context, UsageDataController controller) {
//     return SingleChildScrollView(
//       primary: false,
//       child: Column(
//         children: controller.recentUsers
//             .map((hcUser) => Column(
//                   children: [
//                     Row(
//                       children: [
//                         if (hcUser.photo.startsWith('https://'))
//                           Expanded(
//                             flex: 30,
//                             child: GestureDetector(
//                               onTap: () async {
//                                 await showDialog<void>(
//                                   context: context,
//                                   builder: (_) =>
//                                       ImageDialog(userPhoto: hcUser.photo),
//                                 );
//                               },
//                               child: Image.network(hcUser.photo),
//                             ),
//                           )
//                         else
//                           Expanded(
//                             flex: 30,
//                             child: hcUser.photo.startsWith('bundle://')
//                                 ? Image.network(
//                                     '${hcUser.photo.replaceAll('bundle://', 'https://harriercentral.blob.core.windows.net/profile-photos/')}.jpg',
//                                   )
//                                 : Container(color: Colors.yellow.shade50),
//                           ),
//                         Expanded(
//                           flex: 100,
//                           child: ColoredBox(
//                             color: HSLColor.fromColor(Colors.orange)
//                                 .withLightness(
//                                   (hcUser.minutesSinceLastLogin / 120.0)
//                                           .clamp(0.0, 0.5) +
//                                       0.5,
//                                 )
//                                 .toColor(),
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 const SizedBox(height: 10),
//                                 AutoSizeText(
//                                   hcUser.userName,
//                                   textAlign: TextAlign.center,
//                                   maxLines: 1,
//                                   maxFontSize: 32,
//                                   minFontSize: 5,
//                                   style: TextStyle(
//                                     fontSize: 22,
//                                     fontFamily: 'AvenirNextCondensedDemiBold',
//                                     height: 0.85,
//                                     color: hcUser.loginCount < 2
//                                         ? Colors.black
//                                         : hcUser.loginCount < 5
//                                             ? Colors.blue.shade800
//                                             : hcUser.loginCount < 8
//                                                 ? Colors.purple
//                                                 : Colors.red.shade900,
//                                   ),
//                                 ),
//                                 if (hcUser.kennelShortName.length > 1)
//                                   AutoSizeText(
//                                     hcUser.kennelShortName,
//                                     maxLines: 1,
//                                     minFontSize: 5,
//                                     maxFontSize: 32,
//                                     style: TextStyle(
//                                       fontFamily: 'AvenirNextCondensedBold',
//                                       color: Colors.red.shade600,
//                                     ),
//                                   ),
//                                 Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     const Expanded(child: SizedBox()),
//                                     if (hcUser.isIphone != -1) ...[
//                                       Expanded(
//                                         child: Icon(
//                                           hcUser.isIphone == 1
//                                               ? MaterialCommunityIcons.apple
//                                               : MaterialIcons.android,
//                                           color: hcUser.isIphone == 1
//                                               ? Colors.red
//                                               : Colors.lightGreen.shade800,
//                                           size: 15,
//                                         ),
//                                       ),
//                                       ColoredBox(
//                                         color: _highlightColor(
//                                             hcUser.highlightPhoneVersion),
//                                         child: AutoSizeText(
//                                           hcUser.systemVersion.trim(),
//                                           minFontSize: 5,
//                                           maxFontSize: 32,
//                                           maxLines: 1,
//                                           style: TextStyle(
//                                             fontFamily:
//                                                 hcUser.highlightPhoneVersion ==
//                                                         1
//                                                     ? 'AvenirNextHeavy'
//                                                     : 'AvenirNextCondensedBold',
//                                             color: Colors.black,
//                                           ),
//                                         ),
//                                       ),
//                                       const Icon(
//                                         MaterialCommunityIcons.arrow_right_bold,
//                                         color: Colors.black,
//                                         size: 15,
//                                       ),
//                                     ],
//                                     ColoredBox(
//                                       color: _highlightColor(
//                                           hcUser.highlightHcVersion),
//                                       child: AutoSizeText(
//                                         hcUser.hcVersion
//                                             .replaceAll('HC Ver: ', ''),
//                                         minFontSize: 5,
//                                         maxFontSize: 32,
//                                         maxLines: 1,
//                                         style: TextStyle(
//                                           fontFamily:
//                                               hcUser.highlightHcVersion == 1
//                                                   ? 'AvenirNextHeavy'
//                                                   : 'AvenirNextCondensedBold',
//                                           color: Colors.black,
//                                         ),
//                                       ),
//                                     ),
//                                     const Expanded(child: SizedBox()),
//                                   ],
//                                 ),
//                                 if (hcUser.hcVersion.length > 1)
//                                   AutoSizeText(
//                                     '${(hcUser.minutesSinceLastLogin ~/ 60) == 0 ? '${hcUser.minutesSinceLastLogin % 60} min ago / ' : '${hcUser.minutesSinceLastLogin ~/ 60}:${(hcUser.minutesSinceLastLogin % 60).toString().padLeft(2, '0')} ago / '}${hcUser.loginCount} login(s)',
//                                     maxLines: 1,
//                                     minFontSize: 5,
//                                     maxFontSize: 32,
//                                   ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const Divider(color: Colors.grey, thickness: 1, height: 1),
//                   ],
//                 ))
//             .toList(),
//       ),
//     );
//   }

//   Color _highlightColor(int highlightLevel) {
//     switch (highlightLevel) {
//       case 0:
//         return Colors.green.shade300;
//       case 1:
//         return Colors.yellow.shade300;
//       case 2:
//         return Colors.orange.shade300;
//       case 3:
//         return Colors.red.shade300;
//       default:
//         return Colors.purple.shade300;
//     }
//   }

//   List<Widget> _appStatsCell(
//     BuildContext context,
//     UsageDataController controller,
//     int id,
//     int days,
//     int value,
//     int comparisonValue,
//   ) {
//     double ratio;
//     if (value == 0 && comparisonValue == 0) {
//       ratio = 0.8;
//     } else if (value >= comparisonValue) {
//       ratio = comparisonValue > 0
//           ? ((((value / comparisonValue) / 10.0).clamp(0.0, 1.0) - 1.0).abs())
//               .clamp(0.5, 1.0)
//           : 0.5;
//     } else {
//       ratio = value > 0
//           ? ((((comparisonValue / value) / 10.0).clamp(0.0, 1.0) - 1.0).abs())
//               .clamp(0.5, 1.0)
//           : 0.5;
//     }

//     final isUpdating = controller.isUpdatingId.value == id &&
//         controller.isUpdatingDays.value == days;

//     return [
//       const VerticalDivider(color: Colors.grey, width: 1, thickness: 1),
//       Expanded(
//         child: GestureDetector(
//           onTap: () async {
//             if (!isUpdating && days >= 0) {
//               controller.isUpdatingId.value = id;
//               controller.isUpdatingDays.value = days;
//               await controller.getCategoryDetail(id, days, context);
//               controller.isUpdatingId.value = -1;
//               controller.isUpdatingDays.value = -1;
//             }
//           },
//           child: ColoredBox(
//             color: isUpdating
//                 ? Colors.grey.shade200
//                 : HSLColor.fromColor(
//                     (value == 0 && comparisonValue == 0)
//                         ? Colors.yellow.shade100
//                         : value >= comparisonValue
//                             ? Colors.green
//                             : Colors.red,
//                   ).withLightness(ratio).toColor(),
//             child: isUpdating
//                 ? const Center(child: CircularProgressIndicator())
//                 : Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       AutoSizeText(
//                         value.toString(),
//                         maxLines: 1,
//                         maxFontSize: 32,
//                         minFontSize: 5,
//                         textAlign: TextAlign.center,
//                         style: const TextStyle(
//                             fontSize: 30, fontFamily: 'AvenirNextBold'),
//                       ),
//                       AutoSizeText(
//                         comparisonValue.toString(),
//                         maxLines: 1,
//                         maxFontSize: 32,
//                         minFontSize: 5,
//                         textAlign: TextAlign.center,
//                         style: const TextStyle(fontSize: 18),
//                       ),
//                     ],
//                   ),
//           ),
//         ),
//       ),
//     ];
//   }
// }
