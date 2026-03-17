import 'package:hcportal/imports.dart';

class VisibilityUiController extends GetxController {
  VisibilityUiController(
    this.visibilityTags1,
    this.tagsChanged,
  ) {
    tagIdList.clear();

    for (var i = 1; i < 0x80000000; i *= 2) {
      if (visibilityTags1 & i != 0) {
        tagIdList.add(0x100000000 + i);
      }
    }

    visibilityValues.value = tagIdList
        .where((int element) => group1.values.contains(element))
        .toList();
  }
  int visibilityTags1 = 0;
  void Function(int) tagsChanged;

  final List<int> tagIdList = <int>[];

  RxList<int> visibilityValues = RxList<int>.empty();
  final RxMap<String, int> group1 = <String, int>{
    TAG_VISIBILITY_MISMANAGEMENT: VISIBILTY_TAGS[TAG_VISIBILITY_MISMANAGEMENT]!,
    TAG_VISIBILITY_MEMBERS: VISIBILTY_TAGS[TAG_VISIBILITY_MEMBERS]!,
    TAG_VISIBILITY_FOLLOWERS: VISIBILTY_TAGS[TAG_VISIBILITY_FOLLOWERS]!,
    TAG_VISIBILITY_LOCAL_HASHERS: VISIBILTY_TAGS[TAG_VISIBILITY_LOCAL_HASHERS]!,
    TAG_VISIBILITY_EVERYONE: VISIBILTY_TAGS[TAG_VISIBILITY_EVERYONE]!,
  }.obs;

  // Update the selectedChips value when the form field changes
  void updateSelectedChips(List<int> values, List<int> fields) {
    //selectedChips.value = values;
    for (final field in fields) {
      if (values.contains(field)) {
        if (!tagIdList.contains(field)) {
          tagIdList.add(field);
        }
      } else {
        if (tagIdList.contains(field)) {
          tagIdList.remove(field);
        }
      }
    }

    var tags1 = 0;

    for (var i = 0; i < tagIdList.length; i++) {
      final flag = tagIdList[i];
      if (flag ~/ 4294967296 == 1) {
        tags1 += flag & 0x7fffffff;
      }
    }

    tagsChanged(tags1);
  }
}

class VisibilityUiPage extends StatelessWidget {
  VisibilityUiPage({
    required int visibilityTags1,
    required void Function(int) tagsChanged,
    super.key,
  }) : formController = Get.put(
          VisibilityUiController(
            visibilityTags1,
            tagsChanged,
          ),
        );
  final VisibilityUiController formController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      primary: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          HelperWidgets().categoryLabelWidget('Default Run Visibility'),
          HelperWidgets().chipsWidget(
            'default_run_visibility',
            formController.visibilityValues,
            formController.group1,
            formController,
          ),
        ],
      ),
    );
  }
}
