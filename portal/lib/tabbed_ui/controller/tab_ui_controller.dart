// ignore_for_file: constant_identifier_names

import 'package:hcportal/imports.dart';

abstract class TabUiController extends GetxController {
  late TabController tabController;
  bool _tabControllerInitialized = false;
  final RxInt currentIndex = 0.obs;
  final List<Rx<TabStatus>> tabStatus = [];
  final List<Rx<TabLocked>> tabLocked = [];
  final List<ControlValidity> tabValidResults = [];

  //final Map<String, UiDefinition<dynamic>> uiDefinitions = {};
  final Map<String, UiControlDefinition> uiControls = {};

  final Map<String, FocusNode> focusNodes = {};
  final Map<String, RxBool> focusStates = {};

  final List<TabDefinitionData> allTabs = [];
  final Rx<EScreenSize> screenSize = EScreenSize.isMobileScreen.obs;
  final RxDouble width = 0.0.obs;
  final RxDouble height = 0.0.obs;
  final Rx<String?> sidebarDescription = Rx<String?>(null);
  final Rx<IconData?> sidebarIcon = Rx<IconData?>(null);
  final Rx<String?> sidebarTitle = Rx<String?>(null);
  final RxBool isFormDirty = false.obs;

  final RxBool allFieldsAreValid = true.obs;

  void initTabStatuses(int length, {int initiallyEmptyIndex = 0}) {
    tabStatus
      ..clear()
      ..addAll(List.generate(length, (_) => TabStatus.unknown.obs));

    if (initiallyEmptyIndex >= 0 && initiallyEmptyIndex < tabStatus.length) {
      tabStatus[initiallyEmptyIndex].value = TabStatus.isEmpty;
    }
  }

  void initTabLocks(int length, {required TabLocked initialState}) {
    tabLocked
      ..clear()
      ..addAll(List.generate(length, (_) => initialState.obs));
  }

  void initTabValidResults(
    int length, {
    ControlValidity initialValidity = ControlValidity.unknown,
  }) {
    tabValidResults
      ..clear()
      ..addAll(List.generate(length, (_) => initialValidity));
  }

  void initTabStateBundle({
    required int length,
    int initiallyEmptyIndex = 0,
    TabLocked? initialLockState,
    ControlValidity initialValidity = ControlValidity.unknown,
  }) {
    initTabStatuses(length, initiallyEmptyIndex: initiallyEmptyIndex);
    initTabValidResults(length, initialValidity: initialValidity);
    if (initialLockState != null) {
      initTabLocks(length, initialState: initialLockState);
    }
  }

  void initTabs({
    required TickerProvider vsync,
    required List<TabDefinitionData> tabs,
    required String Function(int index) tabKeyBuilder,
    VoidCallback? onTabIndexChanging,
    VoidCallback? onTabIndexChanged,
    List<String> tabIndexChangingUpdateIds = const [],
    List<String> tabIndexChangedUpdateIds = const [],
  }) {
    allTabs
      ..clear()
      ..addAll(tabs);

    tabController = TabController(length: tabs.length, vsync: vsync);
    _tabControllerInitialized = true;
    tabController.addListener(() {
      currentIndex.value = tabController.index;
      final key = tabKeyBuilder(tabController.index);
      setSidebarData(key);

      if (tabController.indexIsChanging) {
        onTabIndexChanging?.call();
        for (final id in tabIndexChangingUpdateIds) {
          update([id]);
        }
      } else {
        onTabIndexChanged?.call();
        for (final id in tabIndexChangedUpdateIds) {
          update([id]);
        }
      }
    });

    setSidebarData(tabKeyBuilder(tabController.index));
  }

  void setScreenSize({
    int? mobileBreakpoint,
    int? narrowBreakpoint,
  }) {
    final int mobileWidth = mobileBreakpoint ?? MOBILE_SCREEN_WIDTH;
    final int narrowWidth = narrowBreakpoint ?? NARROW_SCREEN_WIDTH;

    if (Get.mediaQuery.size.width < mobileWidth) {
      screenSize.value = EScreenSize.isMobileScreen;
    } else if (Get.mediaQuery.size.width < narrowWidth) {
      screenSize.value = EScreenSize.isNarrowScreen;
    } else {
      screenSize.value = EScreenSize.isNormalScreen;
    }
  }

  void updateSizeWithDebounce(double newWidth, double newHeight) {
    if (width.value != newWidth) {
      width.value = newWidth;
    }
    if (height.value != newHeight) {
      height.value = newHeight;
    }
  }

  bool refreshTabStatuses({
    bool recomputeControlValidity = true,
    bool log = false,
  }) {
    log = true;
    if (recomputeControlValidity) {
      uiControls.forEach((_, control) => control.updateValidity());
    }

    final int tabCount = allTabs.isNotEmpty ? allTabs.length : tabStatus.length;

    if (tabStatus.length < tabCount) {
      tabStatus
        ..clear()
        ..addAll(List.generate(tabCount, (_) => TabStatus.unknown.obs));
    }

    bool isSubmittable = true;

    for (int i = 0; i < tabCount; i++) {
      final bool hasCustomStatus =
          (allTabs.length > i) ? allTabs[i].hasCustomTabStatusFunction : false;
      if (hasCustomStatus) {
        continue;
      }

      int emptyStatus = 0;
      int validStatus = 0;
      int invalidStatus = 0;
      int total = 0;

      uiControls.forEach((_, control) {
        if (control.tabIndex == i) {
          total++;
          switch (control.controlValidity.validity) {
            case ControlValidity.validEmpty:
              emptyStatus++;
              validStatus++;
              break;
            case ControlValidity.valid:
              validStatus++;
              break;
            case ControlValidity.invalid:
              invalidStatus++;
              isSubmittable = false;
              break;
            case ControlValidity.invalidEmpty:
              emptyStatus++;
              isSubmittable = false;
              break;
            case ControlValidity.unknown:
              break;
          }
        }
      });

      TabStatus newStatus = TabStatus.unknown;

      if (validStatus == total) {
        newStatus = TabStatus.isCompleteAndValid;
      } else if (emptyStatus == total) {
        newStatus = TabStatus.isEmpty;
      } else if (invalidStatus > 0) {
        newStatus = TabStatus.isInvalid;
      } else if (emptyStatus == total) {
        newStatus = TabStatus.isEmpty;
      } else {
        newStatus = TabStatus.isInProgress;
      }

      tabStatus[i].value = newStatus;

    }

    return isSubmittable;
  }

  void gotoTab(int index) {
    if (tabController.length == 0) {
      return;
    }
    tabController.index = index.clamp(0, tabController.length - 1);
  }

  void setAllTabLocks(TabLocked state) {
    for (final rx in tabLocked) {
      rx.value = state;
    }
  }

  void updateSubmitTabStatus(int submitTabIndex, bool isSubmittable) {
    if (submitTabIndex < 0 || submitTabIndex >= tabStatus.length) {
      return;
    }
    tabStatus[submitTabIndex].value =
        isSubmittable ? TabStatus.isCompleteAndValid : TabStatus.isEmpty;
  }

  @override
  void onClose() {
    if (_tabControllerInitialized) {
      tabController.dispose();
    }

    for (final node in focusNodes.values) {
      node.dispose();
    }

    super.onClose();
  }

  void setSidebarData(
    String key, {
    SideBarData? sidebarData,
    String? shortDescription,
    String? title,
    IconData? icon,
  }) {
    if (shortDescription != null) {
      sidebarDescription.value = shortDescription;
      sidebarTitle.value = title;
      sidebarIcon.value = icon;
      return;
    }

    if (sidebarData != null) {
      sidebarDescription.value = sidebarData.description;
      sidebarTitle.value = sidebarData.title;
      sidebarIcon.value = sidebarData.icon;
      return;
    }

    if (key.isBlank ?? false) {
      sidebarDescription.value = '';
      sidebarTitle.value = '';
      sidebarIcon.value = Ionicons.flag;
      return;
    }

    // Check for control-specific sidebar data
    final controlSideBar = uiControls[key]?.sidebarData;
    if (controlSideBar != null) {
      sidebarDescription.value = controlSideBar.description;
      sidebarTitle.value = controlSideBar.title;
      sidebarIcon.value = controlSideBar.icon;
      return;
    }

    // Check for tab-level sidebar data
    // Keys ending in '_generic' should show the tab's sidebar data
    final tabKey =
        key.endsWith('_generic') ? key.replaceAll('_generic', '') : key;
    final tabSideBar =
        allTabs.where((tab) => tab.key == tabKey).firstOrNull?.sidebarData;
    if (tabSideBar != null) {
      sidebarDescription.value = tabSideBar.description;
      sidebarTitle.value = tabSideBar.title;
      sidebarIcon.value = tabSideBar.icon;
      return;
    }

    sidebarDescription.value = '';
    sidebarTitle.value = '';
    sidebarIcon.value = Ionicons.flag;
  }

  void checkIfFormIsDirty();
  void undoChanges();
  void populateTextControllers();
  Future<void> save(bool showDialog);
  Future<void> close();

  static const int MOBILE_SCREEN_WIDTH = 650;
  static const int NARROW_SCREEN_WIDTH = 900;
}
