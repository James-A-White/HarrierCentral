import 'package:hcportal/imports.dart';

class RunTagsUiController extends GetxController {
  RunTagsUiController(
    this.runTags1,
    this.runTags2,
    this.runTags3,
    this.tagsChanged,
  ) {
    tagIdList.clear();

    for (var i = 1; i < 0x80000000; i *= 2) {
      if (runTags1 & i != 0) {
        tagIdList.add(0x100000000 + i);
      }
      if (runTags2 & i != 0) {
        tagIdList.add(0x200000000 + i);
      }
      if (runTags3 & i != 0) {
        tagIdList.add(0x400000000 + i);
      }
    }

    runThemeValues.value = tagIdList
        .where((int element) => runThemeGroup.values.contains(element))
        .toList();
    restrictionsValues.value = tagIdList
        .where((int element) => restrictionsGroup.values.contains(element))
        .toList();
    whatToBringValues.value = tagIdList
        .where((int element) => whatToBringGroup.values.contains(element))
        .toList();
    runTypeValues.value = tagIdList
        .where((int element) => runTypeGroup.values.contains(element))
        .toList();
    terrainValues.value = tagIdList
        .where((int element) => terrainGroup.values.contains(element))
        .toList();
    haresValues.value = tagIdList
        .where((int element) => haresGroup.values.contains(element))
        .toList();
    otherValues.value = tagIdList
        .where((int element) => otherGroup.values.contains(element))
        .toList();
  }
  int runTags1 = 0;
  int runTags2 = 0;
  int runTags3 = 0;
  void Function(int, int, int) tagsChanged;

  final List<int> tagIdList = <int>[];

  RxList<int> runThemeValues = RxList<int>.empty();
  final RxMap<String, int> runThemeGroup = <String, int>{
    TAG_NORMAL_RUN: RUN_TAGS[TAG_NORMAL_RUN]!,
    TAG_RED_DRESS: RUN_TAGS[TAG_RED_DRESS]!,
    TAG_FAMILY_HASH: RUN_TAGS[TAG_FAMILY_HASH]!,
    TAG_FULL_MOON: RUN_TAGS[TAG_FULL_MOON]!,
    TAG_HARRIETTE: RUN_TAGS[TAG_HARRIETTE]!,
    TAG_AGM: RUN_TAGS[TAG_AGM]!,
    TAG_DRINKING_PRACTICE: RUN_TAGS[TAG_DRINKING_PRACTICE]!,
    TAG_HANGOVER_RUN: RUN_TAGS[TAG_HANGOVER_RUN]!,
  }.obs;

  RxList<int> restrictionsValues = RxList<int>.empty();
  final RxMap<String, int> restrictionsGroup = <String, int>{
    TAG_MEN_ONLY: RUN_TAGS[TAG_MEN_ONLY]!,
    TAG_WOMEN_ONLY: RUN_TAGS[TAG_WOMEN_ONLY]!,
    TAG_KIDS_ALLOWED: RUN_TAGS[TAG_KIDS_ALLOWED]!,
    TAG_NO_KIDS_ALLOWED: RUN_TAGS[TAG_NO_KIDS_ALLOWED]!,
    TAG_DOG_FRIENDLY: RUN_TAGS[TAG_DOG_FRIENDLY]!,
    TAG_NO_DOGS_ALLOWED: RUN_TAGS[TAG_NO_DOGS_ALLOWED]!,
  }.obs;

  RxList<int> whatToBringValues = RxList<int>.empty();
  final RxMap<String, int> whatToBringGroup = <String, int>{
    TAG_BRING_CASH_ON_TRAIL: RUN_TAGS[TAG_BRING_CASH_ON_TRAIL]!,
    TAG_BRING_FLASHLIGHT: RUN_TAGS[TAG_BRING_FLASHLIGHT]!,
    TAG_BRING_DRY_CLOTHES: RUN_TAGS[TAG_BRING_DRY_CLOTHES]!,
    TAG_BAG_DROP_AVAILABLE: RUN_TAGS[TAG_BAG_DROP_AVAILABLE]!,
    TAG_NO_BAG_DROP_AVAILABLE: RUN_TAGS[TAG_NO_BAG_DROP_AVAILABLE]!,
    TAG_BRING_DRINKING_VESSEL: RUN_TAGS[TAG_BRING_DRINKING_VESSEL]!,
    TAG_BRING_CHAIR: RUN_TAGS[TAG_BRING_CHAIR]!,
    TAG_DRINK_STOP: RUN_TAGS[TAG_DRINK_STOP]!,
  }.obs;

  RxList<int> runTypeValues = RxList<int>.empty();
  final RxMap<String, int> runTypeGroup = <String, int>{
    TAG_PUB_CRAWL: RUN_TAGS[TAG_PUB_CRAWL]!,
    TAG_A_TO_B_RUN: RUN_TAGS[TAG_A_TO_B_RUN]!,
    TAG_OLD_FARTS_TRAIL: RUN_TAGS[TAG_OLD_FARTS_TRAIL]!,
    TAG_WALKER_TRAIL: RUN_TAGS[TAG_WALKER_TRAIL]!,
    TAG_SHORT_TRAIL: RUN_TAGS[TAG_SHORT_TRAIL]!,
    TAG_MEDIUM_TRAIL: RUN_TAGS[TAG_MEDIUM_TRAIL]!,
    TAG_LONG_TRAIL: RUN_TAGS[TAG_LONG_TRAIL]!,
    TAG_BALLBREAKER_TRAIL: RUN_TAGS[TAG_BALLBREAKER_TRAIL]!,
    TAG_BIKE_HASH: RUN_TAGS[TAG_BIKE_HASH]!,
  }.obs;

  RxList<int> terrainValues = RxList<int>.empty();
  final RxMap<String, int> terrainGroup = <String, int>{
    TAG_SHIGGY_RUN: RUN_TAGS[TAG_SHIGGY_RUN]!,
    TAG_CITY_HASH: RUN_TAGS[TAG_CITY_HASH]!,
    TAG_STEEP_HILLS: RUN_TAGS[TAG_STEEP_HILLS]!,
    TAG_NIGHT_RUN: RUN_TAGS[TAG_NIGHT_RUN]!,
    TAG_BABY_JOGGER_FRIENDLY: RUN_TAGS[TAG_BABY_JOGGER_FRIENDLY]!,
    TAG_WATER_ON_TRAIL: RUN_TAGS[TAG_WATER_ON_TRAIL]!,
    TAG_SWIM_STOP: RUN_TAGS[TAG_SWIM_STOP]!,
  }.obs;

  RxList<int> haresValues = RxList<int>.empty();
  final RxMap<String, int> haresGroup = <String, int>{
    TAG_LIVE_HARE: RUN_TAGS[TAG_LIVE_HARE]!,
    TAG_DEAD_HARE: RUN_TAGS[TAG_DEAD_HARE]!,
    TAG_PICK_UP_HASH: RUN_TAGS[TAG_PICK_UP_HASH]!,
    TAG_CATCH_THE_HARE: RUN_TAGS[TAG_CATCH_THE_HARE]!,
  }.obs;

  RxList<int> otherValues = RxList<int>.empty();
  final RxMap<String, int> otherGroup = <String, int>{
    TAG_ON_AFTER: RUN_TAGS[TAG_ON_AFTER]!,
    TAG_ACCESSIBLE_BY_PUBLIC_TRANSPORT:
        RUN_TAGS[TAG_ACCESSIBLE_BY_PUBLIC_TRANSPORT]!,
    TAG_CHARITY_EVENT: RUN_TAGS[TAG_CHARITY_EVENT]!,
    TAG_PARKING_AVAILABLE: RUN_TAGS[TAG_PARKING_AVAILABLE]!,
    TAG_NO_PARKING_AVAILABLE: RUN_TAGS[TAG_NO_PARKING_AVAILABLE]!,
    TAG_CAMPING_HASH: RUN_TAGS[TAG_CAMPING_HASH]!,
    TAG_MULTI_DAY_EVENT: RUN_TAGS[TAG_MULTI_DAY_EVENT]!,
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
    var tags2 = 0;
    var tags3 = 0;

    for (var i = 0; i < tagIdList.length; i++) {
      final flag = tagIdList[i];
      if (flag ~/ 4294967296 == 1) {
        tags1 += flag & 0x7fffffff;
      } else if (flag ~/ 4294967296 == 2) {
        tags2 += flag & 0x7fffffff;
      } else if (flag ~/ 4294967296 == 4) {
        tags3 += flag & 0x7fffffff;
      }
    }

    tagsChanged(tags1, tags2, tags3);
  }
}

class RunTagsUiPage extends StatelessWidget {
  RunTagsUiPage({
    required int runTags1,
    required int runTags2,
    required int runTags3,
    required void Function(int, int, int) tagsChanged,
    super.key,
  }) : formController = Get.put(
          RunTagsUiController(
            runTags1,
            runTags2,
            runTags3,
            tagsChanged,
          ),
        );
  final RunTagsUiController formController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      primary: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          HelperWidgets().categoryLabelWidget('Theme', bottomMargin: 10),
          HelperWidgets().chipsWidget(
            'run_tags_theme',
            formController.runThemeValues,
            formController.runThemeGroup,
            formController,
          ),
          HelperWidgets().categoryLabelWidget('Restrictions', bottomMargin: 10),
          HelperWidgets().chipsWidget(
            'run_tags_restrictions',
            formController.restrictionsValues,
            formController.restrictionsGroup,
            formController,
          ),
          HelperWidgets()
              .categoryLabelWidget('What to bring', bottomMargin: 10),
          HelperWidgets().chipsWidget(
            'run_tags_what_to_bring',
            formController.whatToBringValues,
            formController.whatToBringGroup,
            formController,
          ),
          HelperWidgets()
              .categoryLabelWidget('Run Type & Distances', bottomMargin: 10),
          HelperWidgets().chipsWidget(
            'run_tags_run_type',
            formController.runTypeValues,
            formController.runTypeGroup,
            formController,
          ),
          HelperWidgets().categoryLabelWidget('Terrain', bottomMargin: 10),
          HelperWidgets().chipsWidget(
            'run_tags_terrain',
            formController.terrainValues,
            formController.terrainGroup,
            formController,
          ),
          HelperWidgets().categoryLabelWidget('Hares', bottomMargin: 10),
          HelperWidgets().chipsWidget(
            'run_tags_hares',
            formController.haresValues,
            formController.haresGroup,
            formController,
          ),
          HelperWidgets().categoryLabelWidget('Other', bottomMargin: 10),
          HelperWidgets().chipsWidget(
            'run_tags_other',
            formController.otherValues,
            formController.otherGroup,
            formController,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
