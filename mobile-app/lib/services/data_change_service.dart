import 'dart:async';
import 'package:get/get.dart';

enum DataChangeType { runUpdated, runCreated, kennelFollowStatusChanged }

class DataChangeEvent {
  const DataChangeEvent({required this.type, required this.id});
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
