import 'package:harrier_central/imports.dart';

/// State for the live run's Charges tab: the charge list and whether this
/// hasher may add/edit (server-enforced too; getDownDowns returns nothing to
/// non-managers). Migrated from a State on 2026-09-23.
class LiveRunChargesController extends GetxController {
  LiveRunChargesController({required this.kennelId, required this.eventId});

  final String kennelId;
  final String eventId;

  static String tagFor(String eventId) => 'charges-$eventId';

  final RunContentService _service = RunContentService();

  final RxBool isLoading = true.obs;
  final RxBool canManageCharges = false.obs;
  final RxList<DownDownModel> charges = <DownDownModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    isLoading.value = true;
    final kennelAgg = await QueryKennels.getSingleKennel(kennelId);
    if (isClosed) return;
    canManageCharges.value = canAccessFeature(
      KennelFeature.manageDownDowns,
      appAccessFlags: kennelAgg?.hkm?.appAccessFlags ?? 0,
      mismanagementRoles: kennelAgg?.hkm?.mismanagementRoles ?? 0,
      kennelOverrideJson: kennelAgg?.kennel.permissionOverrideJson,
    );
    try {
      final result = await _service.getDownDowns(
        kennelId: kennelId,
        eventId: eventId,
      );
      if (isClosed) return;
      if (result != null) {
        charges.assignAll(DownDownsController.withHashers(result));
      }
    } catch (e, s) {
      BootLogger.logError('[LiveRunCharges.load] eventId=$eventId', e, s);
      if (isClosed) return;
      hcSnack('Failed to load charges', error: true);
    }
    if (isClosed) return;
    isLoading.value = false;
  }
}
