import 'package:hcportal/imports.dart';

/// The kennel's catalogue, for the portal's Products view.
class ProductController extends GetxController {
  ProductController(this.publicKennelId, this.kennelName);

  final String publicKennelId;
  final String kennelName;

  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxBool isLoading = true.obs;

  /// Off by default: the portal is where something gets taken off sale and
  /// put back on, so it has to show what is off sale.
  final RxBool activeOnly = false.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    isLoading.value = true;
    products.value = await queryKennelProducts(
      publicKennelId,
      activeOnly: activeOnly.value,
    );
    isLoading.value = false;
  }

  Future<void> toggleActiveOnly(bool value) async {
    activeOnly.value = value;
    await load();
  }

  /// Saves one product and reloads. Returns true on success.
  Future<bool> save({
    String? productId,
    required int productType,
    required String name,
    String? description,
    required double priceCharged,
    required double promotionalCredit,
    required double unitCost,
    int? runCount,
    String? productDetailsJson,
    String? photoUrls,
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
      priceCharged: priceCharged,
      promotionalCredit: promotionalCredit,
      unitCost: unitCost,
      runCount: runCount,
      productDetailsJson: productDetailsJson,
      photoUrls: photoUrls,
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

  /// Takes a product off sale, or puts it back. This is the only retirement
  /// path: a sold product is never removed, because the sync deletes removed
  /// rows from every phone and that would orphan the payments behind it.
  Future<void> setOnSale(ProductModel p, bool onSale) async {
    await save(
      productId: p.productId,
      productType: p.productType,
      name: p.name,
      description: p.description,
      priceCharged: p.priceCharged,
      promotionalCredit: p.promotionalCredit,
      unitCost: p.unitCost,
      runCount: p.runCount,
      productDetailsJson: p.productDetailsJson,
      photoUrls: p.photoUrls,
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
}
