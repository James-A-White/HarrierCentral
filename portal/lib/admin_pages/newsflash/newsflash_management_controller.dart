import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hcportal/imports.dart';

class NewsflashManagementController extends GetxController {
  final RxList<NewsflashAdminModel> newsflashes = <NewsflashAdminModel>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(loadNewsflashes());
  }

  Future<void> loadNewsflashes() async {
    isLoading.value = true;
    newsflashes.value = await queryNewsflashList();
    isLoading.value = false;
  }

  Future<void> saveNewsflash({
    String? newsflashId,
    required String title,
    required String bodyText,
    String? imageUrl,
    required DateTime startDate,
    DateTime? endDate,
    String? kennelId,
  }) async {
    final ok = await addEditNewsflash(
      newsflashId: newsflashId,
      title: title,
      bodyText: bodyText,
      imageUrl: imageUrl,
      startDate: startDate,
      endDate: endDate,
      kennelId: kennelId,
    );
    if (ok) {
      await loadNewsflashes();
    } else {
      _showError('Failed to save newsflash. Please try again.');
    }
  }

  Future<void> softDelete(String newsflashId) async {
    final ok = await deleteNewsflash(newsflashId);
    if (ok) {
      await loadNewsflashes();
    } else {
      _showError('Failed to delete newsflash. Please try again.');
    }
  }

  Future<List<NewsflashReaderModel>> loadReaders(String newsflashId) async {
    return queryNewsflashReaders(newsflashId);
  }

  void _showError(String message) {
    if (kDebugMode) debugPrint('NewsflashManagementController error: $message');
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFDC2626),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }
}
