// import 'package:hcportal/imports.dart';
// import 'package:intl/intl.dart';

// part 'kennel_form_ui_helpers.dart';
// part 'pages/kennel_form_hash_cash.dart';
// part 'pages/kennel_form_images.dart';
// part 'pages/kennel_form_location.dart';
// part 'pages/kennel_form_other.dart';
// part 'pages/kennel_form_developer.dart';
// part 'pages/kennel_form_required_info.dart';
// part 'pages/kennel_form_run_tags.dart';

// enum ButtonAction { open, copy, download, demo }

// // class KennelFormPage extends StatelessWidget {
// //   KennelFormPage({super.key});

// //   // Safely cast Get.arguments to a Map
// //   final Map<String, dynamic> args = Get.arguments as Map<String, dynamic>;

// //   // Initialize the controller with the provided arguments
// //   late final KennelFormController formController = Get.put(
// //     KennelFormController(args['initialData'] as KennelModel),
// //     permanent: true,
// //   );

// //   late final HasherKennelsModel hasherKennel =
// //       args['hasherKennel'] as HasherKennelsModel;
// //   late final KennelModel initialData = args['initialData'] as KennelModel;

// class KennelFormPage extends StatelessWidget {
//   KennelFormPage({
//     required this.initialData,
//     required this.hasherKennel,
//     super.key,
//   });

//   final KennelModel initialData;
//   final HasherKennelsModel hasherKennel;

//   // Safely cast Get.arguments to a Map
//   // final Map<String, dynamic> args = Get.arguments as Map<String, dynamic>;

//   // Initialize the controller with the provided arguments
//   late final KennelFormController formController = Get.put(
//     KennelFormController(initialData),
//     permanent: true,
//   );

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         formController.updateSizeWithDebounce(
//           constraints.maxWidth,
//           constraints.maxHeight,
//         );

//         return Scaffold(
//           appBar: AppBar(
//             title:
//                 Text('Editing ${formController.editedData?.kennelName ?? ''}'),
//             leading: GestureDetector(
//               onTap: () async {
//                 await Get.delete<KennelFormController>(
//                   force: true,
//                 );
//                 Get.back<void>(
//                   closeOverlays: true,
//                 );
//               },
//               child: const Icon(
//                 MaterialCommunityIcons.arrow_left,
//                 color: Colors.black,
//               ),
//             ),
//           ),
//           body: DefaultTabController(
//             length: (hasherKennel.isSuperAdmin || hasherKennel.canManageKennel)
//                 ? formController.NUM_TABS
//                 : 1,
//             child: Builder(
//               builder: (context) {
//                 final tabController = DefaultTabController.of(context);
//                 tabController.addListener(() {
//                   formController.currentIndex.value = tabController.index;
//                   formController.sidebarDescription.value = null;
//                   formController.sidebarTitle.value = null;
//                   formController.sidebarIcon.value = null;
//                 });

//                 return Column(
//                   children: <Widget>[
//                     Container(
//                       color: Colors.blue.shade600,
//                       padding: const EdgeInsets.only(top: 10),
//                       child: Form(
//                         key: formController.formKey,
//                         child: TabBar(
//                           labelColor: Colors.redAccent,
//                           unselectedLabelColor: Colors.white,
//                           indicatorSize: TabBarIndicatorSize.label,
//                           indicator: const BoxDecoration(
//                             borderRadius: BorderRadius.only(
//                               topLeft: Radius.circular(10),
//                               topRight: Radius.circular(10),
//                             ),
//                             color: Colors.white,
//                           ),
//                           tabs: <Widget>[
//                             if (hasherKennel.isSuperAdmin ||
//                                 hasherKennel.canManageKennel) ...[
//                               _buildTabWidget('Kennel Info', 0),
//                               _buildTabWidget('Location', 1),
//                               _buildTabWidget('Run Tags', 2),
//                               _buildTabWidget('Other', 3),
//                               _buildTabWidget('Developer', 4),
//                               _buildTabWidget('Hash Cash', 5),
//                             ],
//                             if ((!hasherKennel.isSuperAdmin &&
//                                     !hasherKennel.canManageKennel) &&
//                                 hasherKennel.canManageHashCash) ...[
//                               _buildTabWidget('Hash Cash', 0),
//                             ],
//                           ],
//                         ),
//                       ),
//                     ),
//                     Expanded(
//                       child: TabBarView(
//                         children: <Widget>[
//                           if (hasherKennel.isSuperAdmin ||
//                               hasherKennel.canManageKennel) ...[
//                             TabPageStandardLayoutOld(
//                               tabLocked: TabLocked.tabUnlocked.obs,
//                               title: 'Required Info',
//                               icon: Icons.home,
//                               description:
//                                   'Here you will find all of the required fields for your Kennel.',
//                               formController: formController,
//                               child: _buildRequiredInfo(tabIndex: 0),
//                             ),
//                             TabPageStandardLayoutOld(
//                               tabLocked: TabLocked.tabUnlocked.obs,
//                               title: 'Location & Map',
//                               icon: Ionicons.globe,
//                               description:
//                                   'This screen gives you the option to provide an exact geolocation for your Kennel.',
//                               formController: formController,
//                               child: _buildLocation(tabIndex: 1),
//                             ),
//                             TabPageStandardLayoutOld(
//                               tabLocked: TabLocked.tabUnlocked.obs,
//                               title: 'Run Tags',
//                               icon: FontAwesome.tag,
//                               description:
//                                   'Use this screen to set default run tags for ${formController.editedData?.kennelName ?? 'your Kennel'}.',
//                               formController: formController,
//                               child: _buildRunTags(tabIndex: 2),
//                             ),
//                             TabPageStandardLayoutOld(
//                               tabLocked: TabLocked.tabUnlocked.obs,
//                               title: 'Other Settings',
//                               icon: Ionicons.settings_sharp,
//                               description:
//                                   'Additional items you can set for your Kennel.',
//                               formController: formController,
//                               child: _buildOther(tabIndex: 3),
//                             ),
//                             TabPageStandardLayoutOld(
//                               tabLocked: TabLocked.tabUnlocked.obs,
//                               title: 'Developer',
//                               icon: MaterialCommunityIcons.hammer_wrench,
//                               description:
//                                   'Useful links specific to your Kennel and developer resources.',
//                               formController: formController,
//                               child: _buildLinks(tabIndex: 4),
//                             ),
//                           ],
//                           TabPageStandardLayoutOld(
//                             tabLocked: TabLocked.tabUnlocked.obs,
//                             title: 'Hash Cash',
//                             icon: FontAwesome5Solid.money_bill_wave,
//                             description:
//                                 'Set default run prices and payment platform options.',
//                             formController: formController,
//                             child: _buildHashCash(tabIndex: 5),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 );
//               },
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
