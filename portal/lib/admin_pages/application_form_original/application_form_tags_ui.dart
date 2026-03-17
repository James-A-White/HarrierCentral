// import 'package:hcportal/imports.dart';
// import 'application_form_controller.dart';
// import 'application_form_enums.dart';

// class TagsUiPage extends StatelessWidget {
//   final ApplicationFormController controller;

//   const TagsUiPage({
//     required this.controller,
//     super.key,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: <Widget>[
//         ..._getBody(),
//         const SizedBox(height: 20),
//       ],
//     );
//   }

//   List<Widget> _getBody() {
//     List<Widget> widgets = [];
//     for (var group in AppExperienceGroups.values) {
//       if (group.challengeIdx
//           .contains(controller.editedData.value!.challengeIndex)) {
//         widgets.add(
//             HelperWidgets().categoryLabelWidget(group.label, bottomMargin: 10));

//         widgets.add(
//           Wrap(
//               spacing: 10,
//               runSpacing: 10,
//               children: <Widget>[..._getChips(group)]),
//         );
//       }
//     }
//     return widgets;
//   }

//   List<Widget> _getChips(AppExperienceGroups group) {
//     List<Widget> widgets = [];

//     for (var entry in AppExperienceTags.values) {
//       if (entry.parentKey == group.groupKey) {
//         widgets.add(
//           MouseRegion(
//             onEnter: (event) {
//               controller.setSidebarData(
//                 '',
//                 title: entry.title == 'All Areas'
//                     ? '${group.label}: ${entry.title}'
//                     : entry.title,
//                 shortDescription: entry.description,
//                 icon: entry.icon,
//               );
//             },
//             onExit: (event) {
//               controller.setSidebarData('dunsTab_generic');
//             },
//             child: Obx(() {
//               final bool isSelected =
//                   controller.tagsStatus[entry.key]!.value == 1;
//               return FilterChip(
//                   label: Text(entry.title, style: bodyStyleBlack),
//                   selected: controller.tagsStatus[entry.key]!.value == 1,
//                   selectedColor: Colors.green.shade100,
//                   shape: RoundedRectangleBorder(
//                     side: BorderSide(
//                       color: isSelected ? Colors.green : Colors.grey,
//                       width: isSelected ? 1 : 0.5,
//                     ),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   onSelected: ((controller.tabsSelectedCount.value >=
//                               MAXIMUM_TAGS_ALLOWWED) &&
//                           !isSelected)
//                       ? null
//                       : (bool selected) {
//                           controller.updateTags(
//                             tagSelected: selected,
//                             entryKey: entry.key,
//                           );
//                         });
//             }),
//           ),
//         );
//       }
//     }
//     return widgets;
//   }
// }
