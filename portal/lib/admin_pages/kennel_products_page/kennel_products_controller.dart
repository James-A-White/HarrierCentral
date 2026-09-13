import 'package:hcportal/imports.dart';

import 'kennel_products_enums.dart';

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

/// The kennel's catalogue, one tab per product group.
///
/// Unlike Edit Kennel and Edit Website, this page is NOT a form. Each tab is a
/// list, and every change is saved the moment its dialog is submitted, through
/// hcportal_addEditProduct. So there is no dirty state, no undo buffer and no
/// page-level Save: the five TabUiController overrides are honest no-ops rather
/// than stubs pretending to do something.
///
/// That is why every tab declares `hasCustomTabStatusFunction: true` — there
/// are no UiControlDefinitions for the base class to compute a status from, and
/// without the flag it would mark every tab incomplete forever.
class KennelProductsController extends TabUiController
    with GetSingleTickerProviderStateMixin {
  KennelProductsController({
    required this.publicKennelId,
    required this.kennelName,
  }) {
    setScreenSize();
  }

  final String publicKennelId;
  final String kennelName;

  // ---------------------------------------------------------------------------
  // Catalogue state
  // ---------------------------------------------------------------------------

  /// Every product for this kennel, of every type. Each tab filters it rather
  /// than fetching its own, so one round trip fills the whole page and the
  /// counts on the tabs are consistent with what the tabs show.
  final RxList<ProductModel> allProducts = <ProductModel>[].obs;
  final RxBool isLoading = true.obs;

  /// Off by default. The portal is where something is taken off sale and put
  /// back on, so it has to be able to see what is off sale.
  final RxBool activeOnly = false.obs;

  Worker? _screenSizeDebouncer;

  @override
  void onInit() {
    super.onInit();
    _initializeTabs();
    _initializeTabStates();
    _initializeScreenSizeListener();
    unawaited(load());
  }

  @override
  void onClose() {
    _screenSizeDebouncer?.dispose();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // Init helpers
  // ---------------------------------------------------------------------------

  void _initializeTabs() {
    initTabs(
      vsync: this,
      tabs: _buildTabDefinitions(),
      tabKeyBuilder: (int i) => KennelProductsTabType.values[i].key,
      tabIndexChangingUpdateIds: const <String>['tabIcons'],
    );
  }

  void _initializeTabStates() {
    initTabStateBundle(
      length: KennelProductsTabType.values.length,
      initiallyEmptyIndex: 0,
      initialLockState: TabLocked.tabUnlocked,
    );
  }

  void _initializeScreenSizeListener() {
    _screenSizeDebouncer = debounce(
      width,
      (_) => setScreenSize(),
      time: const Duration(milliseconds: 50),
    );
  }

  List<TabDefinitionData> _buildTabDefinitions() {
    return KennelProductsTabType.values.map((KennelProductsTabType tab) {
      return TabDefinitionData(
        key: tab.key,
        title: tab.title,
        tabIndex: tab.index,
        hasCustomTabStatusFunction: tab.hasCustomTabStatusFunction,
        showTabInSubmitSummary: tab.showTabInSubmitSummary,
        isTabLockable: tab.isTabLockable,
        sidebarData: SideBarData(tab.title, tab.icon, tab.description),
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Catalogue
  // ---------------------------------------------------------------------------

  /// One kennel's products of one group, on-sale first then sort order.
  List<ProductModel> productsFor(KennelProductsTabType tab) {
    return allProducts
        .where((ProductModel p) => p.productType == tab.productType)
        .toList(growable: false);
  }

  int countFor(KennelProductsTabType tab) => productsFor(tab).length;

  Future<void> load() async {
    isLoading.value = true;
    allProducts.value = await queryKennelProducts(
      publicKennelId,
      activeOnly: activeOnly.value,
    );
    isLoading.value = false;
    update(<String>['tabIcons']);
  }

  Future<void> toggleActiveOnly(bool value) async {
    activeOnly.value = value;
    await load();
  }

  /// Creates or edits one product and reloads. Returns true on success.
  Future<bool> saveProduct({
    String? productId,
    required int productType,
    required String name,
    String? description,
    String? pricingJson,
    String? productDetailsJson,
    String? sourceJson,
    required bool isActive,
    int sortOrder = 0,
  }) async {
    final String? id = await addEditProduct(
      publicKennelId: publicKennelId,
      productId: productId,
      productType: productType,
      name: name,
      description: description,
      pricingJson: pricingJson,
      productDetailsJson: productDetailsJson,
      sourceJson: sourceJson,
      isActive: isActive,
      sortOrder: sortOrder,
    );
    if (id == null) {
      _error('That product could not be saved. Please try again.');
      return false;
    }
    await load();
    return true;
  }

  /// Takes a product off sale, or puts it back.
  ///
  /// This is the ONLY retirement path. A product is never deleted: the mobile
  /// sync removes deleted rows from every phone, which would orphan the
  /// payments made against it.
  Future<void> setOnSale(ProductModel p, bool onSale) async {
    await saveProduct(
      productId: p.productId,
      productType: p.productType,
      name: p.name,
      description: p.description,
      pricingJson: p.pricingJson,
      productDetailsJson: p.productDetailsJson,
      sourceJson: p.sourceJson,
      isActive: onSale,
      sortOrder: p.sortOrder,
    );
  }

  void _error(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFDC2626),
      colorText: Colors.white,
    );
  }

  // ---------------------------------------------------------------------------
  // TabUiController overrides
  //
  // Every change is committed by its own dialog, so there is nothing page-level
  // to make dirty, undo, populate or save. These are deliberately empty.
  // ---------------------------------------------------------------------------

  @override
  void checkIfFormIsDirty() => isFormDirty.value = false;

  @override
  void undoChanges() {}

  @override
  void populateTextControllers() {}

  @override
  Future<void> save(bool showDialog) async {}

  @override
  Future<void> close() async {
    Get.back<void>();
  }
}
