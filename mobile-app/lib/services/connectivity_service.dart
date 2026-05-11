import 'package:harrier_central/imports.dart';

// lib/services/network_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';

/// App-level online/offline status (validated by reachability).
enum NetworkStatus { online, offline }

class NetworkService extends GetxService {
  // Reactive public state
  final Rx<NetworkStatus> status = NetworkStatus.online.obs;
  final RxSet<ConnectivityResult> interfaces = <ConnectivityResult>{}.obs;

  // Internals
  late final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  StreamSubscription<InternetStatus>? _internetStatusSub;

  final Duration debounce = const Duration(milliseconds: 5000);
  Timer? _debounceTimer;

  Future<void> init() async {
    _connectivity = Connectivity();

    // Seed reachability
    final hasNet = await Utilities.checkForInternetConnection(false);

    status.value = hasNet ? NetworkStatus.online : NetworkStatus.offline;

    //('1. Status => $hasNet: ${DateTime.now().millisecondsSinceEpoch}');

    // Listen for interface changes
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      _setInterfaces(results);
      _recheckInternetWithDebounce();
    });

    // Listen for real internet reachability (InternetStatus.connected/disconnected)
    _internetStatusSub = InternetConnection().onStatusChange.listen((
      internetStatus,
    ) {
      final hasInternet = internetStatus == InternetStatus.connected;
      // print(
      //   '4. Status => $hasInternet: ${DateTime.now().millisecondsSinceEpoch}',
      // );

      _setStatusDebounced(
        hasInternet ? NetworkStatus.online : NetworkStatus.offline,
      );
    });

    // Seed interface list (new API returns List<ConnectivityResult>)
    final initialInterfaces = await _checkInterfacesSafe();
    _setInterfaces(initialInterfaces);

    if (!hasAnyInterface) {
      status.value = NetworkStatus.offline;
    }

    return;
  }

  Future<bool> forceRecheck() async {
    final hasInternet = await Utilities.checkForInternetConnection(false);
    status.value = hasInternet ? NetworkStatus.online : NetworkStatus.offline;
    // print(
    //   '2. Status => $hasInternet: ${DateTime.now().millisecondsSinceEpoch}',
    // );

    // if (hasInternet) {
    //   appModel.connectionStatus = EnumConnectionStatus2.connected;
    // } else {
    //   appModel.connectionStatus = EnumConnectionStatus2.notConnected;
    // }

    return hasInternet;
  }

  Future<List<ConnectivityResult>> _checkInterfacesSafe() async {
    try {
      return await _connectivity
          .checkConnectivity(); // List<ConnectivityResult>
    } catch (_) {
      return const [ConnectivityResult.none];
    }
  }

  void _setInterfaces(List<ConnectivityResult> list) {
    interfaces
      ..clear()
      ..addAll(list);
  }

  void _recheckInternetWithDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () async {
      final hasInternet = await Utilities.checkForInternetConnection(false);
      status.value = hasInternet ? NetworkStatus.online : NetworkStatus.offline;
      // print(
      //   '3. Status => $hasInternet: ${DateTime.now().millisecondsSinceEpoch}',
      // );

      // if (hasInternet) {
      //   appModel.connectionStatus = EnumConnectionStatus2.connected;
      // } else {
      //   appModel.connectionStatus = EnumConnectionStatus2.notConnected;
      // }
    });
  }

  void _setStatusDebounced(NetworkStatus newStatus) {
    //print('5. Status => $newStatus: ${DateTime.now().millisecondsSinceEpoch}');
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () {
      status.value = newStatus;
      // print(
      //   '6. Status => $newStatus: ${DateTime.now().millisecondsSinceEpoch}',
      // );

      // if (newStatus == NetworkStatus.online) {
      //   appModel.connectionStatus = EnumConnectionStatus2.connected;
      // } else {
      //   appModel.connectionStatus = EnumConnectionStatus2.notConnected;
      // }
    });
  }

  // Convenience getters
  bool get hasAnyInterface =>
      interfaces.any((r) => r != ConnectivityResult.none);
  //bool get isOnline => status.value == NetworkStatus.online;

  bool isOnline() {
    bool isOnline = false;
    isOnline = status.value == NetworkStatus.online;
    return isOnline;
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    unawaited(_connectivitySub?.cancel());
    unawaited(_internetStatusSub?.cancel());
    super.onClose();
  }
}
