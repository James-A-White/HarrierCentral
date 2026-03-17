// part of '../kennel_form_ui.dart';

// extension RunTags on KennelFormPage {
//   Widget _buildRunTags({required int tabIndex}) {
//     return Scrollbar(
//       controller: formController.allFieldsTabScrollController,
//       trackVisibility: false,
//       thumbVisibility: false,
//       interactive: true,
//       thickness: 15,
//       child: ListView(
//         controller: formController.allFieldsTabScrollController,
//         children: <Widget>[
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
//                 ..checkIfFormIsDirty(tabIndex: tabIndex);
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }
