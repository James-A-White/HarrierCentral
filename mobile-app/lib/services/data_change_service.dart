import 'dart:async';
import 'package:get/get.dart';

enum DataChangeType {
  runUpdated,
  runCreated,
  kennelFollowStatusChanged,

  /// A full user-data sync (all common tables) has just completed — e.g. the
  /// returning-user background boot sync. Signals every top-level tab to
  /// re-read from its tables, not just the runs tab. Carries no id.
  fullSyncCompleted,
}

class DataChangeEvent {
  const DataChangeEvent({required this.type, this.id = ''});
  final DataChangeType type;
  final String id;
}

class DataChangeService extends GetxService {
  final StreamController<DataChangeEvent> _controller =
      StreamController<DataChangeEvent>.broadcast();

  Stream<DataChangeEvent> get stream => _controller.stream;

  void notify(DataChangeEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  @override
  void onClose() {
    _controller.close();
    super.onClose();
  }
}
