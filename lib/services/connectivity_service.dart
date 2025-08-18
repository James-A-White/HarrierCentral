import 'package:harrier_central/imports.dart';

// lib/services/network_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';

/// App-level online/offline status (validated by reachability).
enum NetworkStatus { online, offline }

class NetworkService extends GetxService {
  // Reactive public state
  final Rx<NetworkStatus> status = NetworkStatus.offline.obs;
  final RxSet<ConnectivityResult> interfaces = <ConnectivityResult>{}.obs;

  // Internals
  late final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  StreamSubscription<InternetStatus>? _internetStatusSub;
  final Duration debounce = const Duration(milliseconds: 350);
  Timer? _debounceTimer;

  Future<NetworkService> init() async {
    _connectivity = Connectivity();

    // Seed interface list (new API returns List<ConnectivityResult>)
    final initialInterfaces = await _checkInterfacesSafe();
    _setInterfaces(initialInterfaces);

    // Seed reachability
    final hasNet = await InternetConnection().hasInternetAccess;
    status.value = hasNet ? NetworkStatus.online : NetworkStatus.offline;

    if (hasNet) {
      G0<AppModel>().connectionStatus = EnumConnectionStatus2.connected;
    } else {
      G0<AppModel>().connectionStatus = EnumConnectionStatus2.notConnected;
    }

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
      _setStatusDebounced(
        hasInternet ? NetworkStatus.online : NetworkStatus.offline,
      );
    });

    return this;
  }

  Future<bool> forceRecheck() async {
    final hasInternet = await InternetConnection().hasInternetAccess;
    status.value = hasInternet ? NetworkStatus.online : NetworkStatus.offline;
    if (hasInternet) {
      G0<AppModel>().connectionStatus = EnumConnectionStatus2.connected;
    } else {
      G0<AppModel>().connectionStatus = EnumConnectionStatus2.notConnected;
    }

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
      final hasInternet = await InternetConnection().hasInternetAccess;
      status.value = hasInternet ? NetworkStatus.online : NetworkStatus.offline;
      if (hasInternet) {
        G0<AppModel>().connectionStatus = EnumConnectionStatus2.connected;
      } else {
        G0<AppModel>().connectionStatus = EnumConnectionStatus2.notConnected;
      }
    });
  }

  void _setStatusDebounced(NetworkStatus newStatus) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () {
      status.value = newStatus;
      if (newStatus == NetworkStatus.online) {
        G0<AppModel>().connectionStatus = EnumConnectionStatus2.connected;
      } else {
        G0<AppModel>().connectionStatus = EnumConnectionStatus2.notConnected;
      }
    });
  }

  // Convenience getters
  bool get hasAnyInterface =>
      interfaces.any((r) => r != ConnectivityResult.none);
  bool get isOnline => status.value == NetworkStatus.online;

  @override
  void onClose() {
    _debounceTimer?.cancel();
    _connectivitySub?.cancel();
    _internetStatusSub?.cancel();
    super.onClose();
  }
}
