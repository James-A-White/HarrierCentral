// // import 'dart:typed_data';
// import 'dart:io';

// import 'application_form_controller.dart';
// import 'application_form_enums.dart';
// import 'application_form_tags_ui.dart';
// import 'package:hcportal/imports.dart';
// import 'package:hcportal/tabbed_ui_new/ui_control.dart';
// import 'package:fleather/fleather.dart';

// import 'package:image/image.dart' as image;
// // import 'package:file_picker/file_picker.dart';
// import 'package:fleather/fleather.dart' as fleather;
// // import 'package:flutter/services.dart';
// // import 'package:image_picker/image_picker.dart';

// // import 'dart:convert';
// // import 'dart:io';

// // import 'package:fleather/fleather.dart';
// // import 'package:flutter/foundation.dart';

// //import 'package:hcportal/widgets/visibility_tags_ui.dart';
// //import 'package:intl/intl.dart';

// part 'application_form_ui_helpers.dart';

// part 'pages/application_form_description.dart';
// part 'pages/application_form_widgets.dart';
// part 'pages/application_form_proposals.dart';
// part 'pages/application_form_proposal_form.dart';
// part 'pages/application_form_cvs.dart';
// part 'pages/application_form_experience_tags.dart';
// part 'pages/application_form_submission.dart';
// part 'pages/application_form_consent.dart';

// class TestFormPage extends StatefulWidget {
//   const TestFormPage({
//     required this.applicationData,
//     super.key,
//   });

//   final ApplicationModel applicationData;

//   @override
//   TestFormPageState createState() => TestFormPageState();
// }

// class TestFormPageState extends State<TestFormPage>
//     with AutomaticKeepAliveClientMixin {
//   @override
//   bool get wantKeepAlive => true; // Retain state across tab changes

//   late ApplicationFormController applicationGetxController;

//   @override
//   void initState() {
//     super.initState();

//     applicationGetxController = Get.put(
//         ApplicationFormController(widget.applicationData),
//         permanent: true);
//   }

//   @override
//   void dispose() {
//     if (Get.isRegistered<ApplicationFormController>()) {
//       unawaited(Get.delete<ApplicationFormController>(force: true));
//     }
//     super.dispose();
//   }

//   //static List<String> pin_colors = <String>['red', 'orange', 'yellow', 'green', 'teal', 'baby_blue', 'blue', 'purple', 'pink'];

//   @override
//   Widget build(BuildContext context) {
//     super.build(context);

//     try {
//       return GetBuilder<ApplicationFormController>(
//           id: 'refreshApplicationFormBuilder',
//           builder: (unusedController) {
//             return Container(
//               color: Colors.white,
//               child: LayoutBuilder(
//                 builder: (context, constraints) {
//                   applicationGetxController.updateSizeWithDebounce(
//                     constraints.maxWidth,
//                     constraints.maxHeight,
//                   );

//                   return Scaffold(
//                     appBar: AppBar(
//                       actions: <Widget>[
//                         Row(
//                           children: [
//                             SizedBox(
//                               width: 150,
//                               child: Obx(() {
//                                 if (!applicationGetxController
//                                     .doAutoSave.value) {
//                                   return const SizedBox();
//                                 } else if (applicationGetxController
//                                         .autoSaveCounter.value ==
//                                     -1) {
//                                   return Center(
//                                     child: Text('Saving',
//                                         style: titleStyleBlack.copyWith(
//                                           color: Colors.blue.shade700,
//                                         )),
//                                   );
//                                 }
//                                 return LinearProgressIndicator(
//                                     minHeight: 15,
//                                     borderRadius: const BorderRadius.all(
//                                       Radius.circular(5),
//                                     ),
//                                     value: applicationGetxController
//                                             .autoSaveCounter.value /
//                                         AUTOSAVE_PERIOD_IN_SECONDS);
//                               }),
//                             ),
//                             // Obx(
//                             //   () => Text(
//                             //     applicationGetxController.autoSaveCounter.value
//                             //         .toString(),
//                             //     style: headingStyleBlack,
//                             //   ),
//                             // ),
//                             const SizedBox(width: 20),
//                             Text(
//                               'Auto save',
//                               style: headingStyleBlack,
//                             ),
//                             const SizedBox(width: 10),
//                             Obx(
//                               () => Switch(
//                                 value:
//                                     applicationGetxController.doAutoSave.value,
//                                 onChanged: (value) {
//                                   applicationGetxController.doAutoSave.value =
//                                       !applicationGetxController
//                                           .doAutoSave.value;
//                                 },
//                               ),
//                             ),
//                             const SizedBox(
//                               width: 30,
//                             )
//                           ],
//                         )
//                       ],
//                       title: Text(
//                           'Editing ${applicationGetxController.editedData.value?.title ?? ''}',
//                           style: headingStyleBlack),
//                       leading: GestureDetector(
//                         onTap: () {
//                           Get.back<void>();
//                         },
//                         child: const Icon(
//                           MaterialCommunityIcons.arrow_left,
//                           color: Colors.black,
//                         ),
//                       ),
//                     ),
//                     body: DefaultTabController(
//                       // if the user can only manage Hash Cash, give them only that tab.
//                       length: AppTabKeyEnums.values.length,
//                       child: Builder(
//                         builder: (context) {
//                           // if (applicationGetxController.tabController == null) {
//                           //   applicationGetxController.tabController =
//                           //       DefaultTabController.of(context);
//                           //   applicationGetxController.tabController
//                           //       ?.addListener(() {
//                           //     if (applicationGetxController
//                           //             .tabController?.indexIsChanging ==
//                           //         true) {
//                           //       applicationGetxController
//                           //           .checkUiControlValidationStates();
//                           //       applicationGetxController.update(['tabIcons']);
//                           //     }
//                           //   });
//                           // }

//                           return Column(
//                             children: <Widget>[
//                               Container(
//                                 color: Colors.blue.shade600,
//                                 padding: const EdgeInsets.only(top: 10),
//                                 child: Form(
//                                   key: applicationGetxController.formKey,
//                                   child: TabBar(
//                                       controller: applicationGetxController
//                                           .tabController,
//                                       labelColor: Colors.black,
//                                       unselectedLabelColor: Colors.white,
//                                       indicatorSize: TabBarIndicatorSize.label,
//                                       indicator: const BoxDecoration(
//                                         borderRadius: BorderRadius.only(
//                                           topLeft: Radius.circular(10),
//                                           topRight: Radius.circular(10),
//                                         ),
//                                         color: Colors.white,
//                                       ),
//                                       tabs: _getTabs()),
//                                 ),
//                               ),
//                               Expanded(
//                                 child: TabBarView(
//                                   controller:
//                                       applicationGetxController.tabController,
//                                   children: <Widget>[
//                                     // if (widget.userData.isSuperAdmin ||
//                                     //     widget.userData.canManageInnovator ||
//                                     //     true)
//                                     ..._getTabBodies()
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           );
//                         },
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             );
//           });
//     } catch (ex) {
//       //printex);
//     }
//     return Container(color: Colors.amber);
//   }

//   List<Widget> _getTabs() {
//     List<Widget> tabs = [];

//     for (var item in AppTabKeyEnums.values) {
//       tabs.add(
//           _buildTabWidget(item.title, item.idx, applicationGetxController));
//     }
//     return tabs;
//   }

//   Widget _getTabBody(int idx) {
//     Widget body = Container(
//       color: Colors.pink.shade200,
//       height: 300,
//       width: 300,
//     );

//     //print'tab body = $idx');

//     switch (idx) {
//       case 0:
//         body = _buildAppDetails(tabIndex: idx);
//       case 1:
//         body = _buildAppProposals(tabIndex: idx);
//       case 2:
//         body = _buildAppCvs(tabIndex: idx);
//       case 3:
//         body = _buildAppProposalForm(tabIndex: idx);
//       case 4:
//         body = _buildExperienceTags(tabIndex: idx);
//       case 5:
//         body = _buildAppConsent(tabIndex: idx);
//       case 6:
//         body = _buildAppSubmission(tabIndex: idx);
//     }
//     return body;
//   }

//   List<Widget> _getTabBodies() {
//     List<Widget> tabs = [];
//     for (var item in AppTabKeyEnums.values) {
//       tabs.add(
//         TabPageStandardLayout(
//           title: item.title,
//           icon: item.icon,
//           description: item.description,
//           formController: applicationGetxController,
//           showCloseApplicationButton: true,
//           tabLocked: applicationGetxController.tabLocked[item.idx],
//           child: _getTabBody(item.idx),
//         ),
//       );
//     }
//     return tabs;
//   }

//   // Widget _embedBuilder(BuildContext context, fleather.EmbedNode node) {
//   //   if (node.value.type == 'icon') {
//   //     final data = node.value.data;
//   //     // Icons.rocket_launch_outlined
//   //     return Icon(
//   //       IconData(int.parse(data['codePoint']), fontFamily: data['fontFamily']),
//   //       color: Color(int.parse(data['color'])),
//   //       size: 18,
//   //     );
//   //   }

//   //   if (node.value.type == 'image') {
//   //     final sourceType = node.value.data['source_type'];
//   //     ImageProvider? image;
//   //     if (sourceType == 'assets') {
//   //       image = AssetImage(node.value.data['source']);
//   //     } else if (sourceType == 'file') {
//   //       image = FileImage(File(node.value.data['source']));
//   //     } else if (sourceType == 'url') {
//   //       image = NetworkImage(node.value.data['source']);
//   //     }
//   //     if (image != null) {
//   //       return Padding(
//   //         // Caret takes 2 pixels, hence not symmetric padding values.
//   //         padding: const EdgeInsets.only(left: 4, right: 2, top: 2, bottom: 2),
//   //         child: Container(
//   //           width: 300,
//   //           height: 300,
//   //           decoration: BoxDecoration(
//   //             image: DecorationImage(image: image, fit: BoxFit.cover),
//   //           ),
//   //         ),
//   //       );
//   //     }
//   //   }

//   //   return fleather.defaultFleatherEmbedBuilder(context, node);
//   // }

//   // void _launchUrl(String? url) async {
//   //   if (url == null) return;
//   //   final uri = Uri.parse(url);
//   //   final canLaunch = await canLaunchUrl(uri);
//   //   if (canLaunch) {
//   //     await launchUrl(uri);
//   //   }
//   // }
// }

// /// This is an example insert rule that will insert a new line before and
// /// after inline image embed.
// class ForceNewlineForInsertsAroundInlineImageRule2 extends fleather.InsertRule {
//   @override
//   fleather.Delta? apply(fleather.Delta document, int index, Object data) {
//     if (data is! String) return null;

//     final iter = fleather.DeltaIterator(document);
//     final previous = iter.skip(index);
//     final target = iter.next();
//     final cursorBeforeInlineEmbed = _isInlineImage(target.data);
//     final cursorAfterInlineEmbed =
//         previous != null && _isInlineImage(previous.data);

//     if (cursorBeforeInlineEmbed || cursorAfterInlineEmbed) {
//       final delta = fleather.Delta()..retain(index);
//       if (cursorAfterInlineEmbed && !data.startsWith('\n')) {
//         delta.insert('\n');
//       }
//       delta.insert(data);
//       if (cursorBeforeInlineEmbed && !data.endsWith('\n')) {
//         delta.insert('\n');
//       }
//       return delta;
//     }
//     return null;
//   }

//   bool _isInlineImage(Object data) {
//     if (data is fleather.EmbeddableObject) {
//       return data.type == 'image' && data.inline;
//     }
//     if (data is Map) {
//       return data[fleather.EmbeddableObject.kTypeKey] == 'image' &&
//           data[fleather.EmbeddableObject.kInlineKey];
//     }
//     return false;
//   }
// }
