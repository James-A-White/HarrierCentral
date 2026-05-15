import 'package:harrier_central/imports.dart';

class RunAdminController extends GetxController {
  RunAdminController({required this.eventId});

  final String eventId;

  final Rx<RunAdminAggregate?> eventAggregate = Rx<RunAdminAggregate?>(null);
  final RxBool isLoading = true.obs;

  late final String _userId;
  StreamSubscription<DataChangeEvent>? _dataChangeSub;

  @override
  void onInit() {
    super.onInit();
    _userId = getStringPref(StringPrefsEnum.userId) ?? '';
    _dataChangeSub = Get.find<DataChangeService>().stream.listen(_onDataChange);
    unawaited(getRunDetails());
  }

  @override
  void onClose() {
    _dataChangeSub?.cancel();
    super.onClose();
  }

  void _onDataChange(DataChangeEvent event) {
    if (event.type == DataChangeType.runUpdated && event.id.toLowerCase() == eventId.toLowerCase()) {
      unawaited(getRunDetails());
    }
  }

  Future<void> getRunDetails() async {
    isLoading.value = true;
    try {
      await tableModel.syncEventAdminService.updateFromBackend(
        EnumDataTables.eventTableFlags,
        false,
        eventId,
      );

      final RunAdminAggregate? rd =
          await CommonQueries.getEventAdminInfoFromLocalCache(eventId, _userId);

      if (rd != null) {
        eventAggregate.value = rd;
      }
    } catch (e) {
      if (kDebugMode) print('RunAdminController.getRunDetails error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
