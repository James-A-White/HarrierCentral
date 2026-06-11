import 'package:harrier_central/imports.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService extends GetxService {
  // Whether the device can reach the internet (Google, MSFT)
  final RxBool hasInternet = false.obs;
  // Whether the HC backend is specifically reachable (checked separately,
  // with a longer timeout to absorb Azure cold-start delays)
  final RxBool backendReachable = false.obs;

  late final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  StreamSubscription<InternetStatus>? _internetStatusSub;
  Timer? _backendDebounceTimer;
  Timer? _backendRetryTimer;
  bool _isCheckingBackend = false;

  static const Duration _backendDebounce = Duration(milliseconds: 500);
  // 12 s: long enough to survive an Azure Functions cold start
  static const Duration _backendTimeout = Duration(milliseconds: 12000);
  // Retry interval when backend is unreachable but internet is up.
  // 5 s is the practical minimum — checkHcServer() itself has a 5 s timeout,
  // so going lower risks overlapping requests; the _isCheckingBackend guard
  // prevents that, but 5 s gives the check time to resolve cleanly first.
  static const Duration _backendRetryInterval = Duration(seconds: 5);

  Future<void> init() async {
    _connectivity = Connectivity();

    // Seed hasInternet from a fast check — no HC server involvement
    final hasNet = await Utilities.checkForInternetConnection();
    hasInternet.value = hasNet;
    if (hasNet) _scheduleBackendCheck();

    // Interface gone → flip offline immediately, no network call needed.
    // Interface appeared/changed → let InternetConnection.onStatusChange handle
    // it; that stream fires independently and does real reachability checks.
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      final anyInterface = results.any((r) => r != ConnectivityResult.none);
      if (!anyInterface) {
        hasInternet.value = false;
        backendReachable.value = false;
        _backendDebounceTimer?.cancel();
        _backendRetryTimer?.cancel();
      }
    });

    // Authoritative internet reachability — general internet check only.
    // HC backend reachability is handled separately via checkHcServer() (SP → DB).
    _internetStatusSub = InternetConnection.createInstance(
      customCheckOptions: [
        InternetCheckOption(uri: Uri.parse(CONNECTION_TEST_GOOGLE_URL)),
        InternetCheckOption(uri: Uri.parse(CONNECTION_TEST_MSFT_URL)),
      ],
    ).onStatusChange.listen((status) {
      final online = status == InternetStatus.connected;
      hasInternet.value = online;
      if (online) {
        _scheduleBackendCheck();
      } else {
        backendReachable.value = false;
        _backendDebounceTimer?.cancel();
        _backendRetryTimer?.cancel();
      }
    });
  }

  // Rate-limited backend check — debounced so rapid reconnect events don't
  // hammer the HC server with back-to-back requests.
  void _scheduleBackendCheck() {
    _backendRetryTimer?.cancel();
    _backendDebounceTimer?.cancel();
    _backendDebounceTimer = Timer(_backendDebounce, _runBackendCheck);
  }

  Future<void> _runBackendCheck() async {
    if (!hasInternet.value || _isCheckingBackend) return;
    _isCheckingBackend = true;
    try {
      final reachable = await Utilities.checkHcServer()
          .timeout(_backendTimeout, onTimeout: () => false);
      backendReachable.value = reachable;
      // Auto-retry every 5 s while internet is up but backend is unreachable —
      // covers Azure cold-start and brief outages without requiring user action.
      if (!reachable) _scheduleBackendRetry();
    } catch (_) {
      backendReachable.value = false;
      _scheduleBackendRetry();
    } finally {
      _isCheckingBackend = false;
    }
  }

  void _scheduleBackendRetry() {
    if (!hasInternet.value) return;
    _backendRetryTimer?.cancel();
    _backendRetryTimer = Timer(_backendRetryInterval, _runBackendCheck);
  }

  // User-initiated recheck (offline ribbon "Try Reconnect").
  // Runs both checks synchronously and returns true only when the HC backend
  // is reachable — i.e. the app can actually do something useful.
  Future<bool> forceRecheck() async {
    final hasNet = await Utilities.checkForInternetConnection();
    hasInternet.value = hasNet;
    if (!hasNet) {
      backendReachable.value = false;
      return false;
    }
    try {
      final reachable = await Utilities.checkHcServer()
          .timeout(_backendTimeout, onTimeout: () => false);
      backendReachable.value = reachable;
      // If still unreachable, keep the retry loop running
      if (!reachable) _scheduleBackendRetry();
      return reachable;
    } catch (_) {
      backendReachable.value = false;
      _scheduleBackendRetry();
      return false;
    }
  }

  // Returns true when the device has internet — used by all service-layer guards.
  // backendReachable is checked separately only where needed (e.g. the ribbon).
  bool isOnline() => hasInternet.value;

  @override
  void onClose() {
    _backendDebounceTimer?.cancel();
    _backendRetryTimer?.cancel();
    unawaited(_connectivitySub?.cancel());
    unawaited(_internetStatusSub?.cancel());
    super.onClose();
  }
}
