import 'package:harrier_central/imports.dart';

class LiveRunService extends GetxService {
  static LiveRunService ensure() {
    if (Get.isRegistered<LiveRunService>()) {
      return Get.find<LiveRunService>();
    }
    return Get.put(LiveRunService());
  }

  final RxnString activeRunEventId = RxnString();
  final RxnString activeRunName = RxnString();

  bool get hasActiveRun => activeRunEventId.value != null;

  bool isActive(String eventId) => activeRunEventId.value == eventId;

  void startRun({required String eventId, String? eventName}) {
    activeRunEventId.value = eventId;
    activeRunName.value = eventName;
  }

  void clearRun() {
    activeRunEventId.value = null;
    activeRunName.value = null;
  }
}
