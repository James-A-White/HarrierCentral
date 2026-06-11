import 'package:harrier_central/imports.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService extends GetxService {
  // Whether the device can reach the internet (Google/MSFT probe)
  final RxBool hasInternet = false.obs;
  // Whether the HC backend is fully reachable (API → hcapp_checkConnection SP → DB)
  final RxBool backendReachable = false.obs;

  late final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _debounceTimer;
  Timer? _backendRetryTimer;
  bool _isChecking = false;

  // Short timeout for the initial backend check — fail fast on cold start so
  // the internet fallback runs promptly and the retry loop takes over.
  static const Duration _checkDebounce = Duration(milliseconds: 500);
  static const Duration _coldStartTimeout = Duration(seconds: 3);
  // Full timeout for the retry loop — backend may still be warming up.
  static const Duration _retryBackendTimeout = Duration(seconds: 12);
  static const Duration _backendRetryInterval = Duration(seconds: 5);

  Future<void> init() async {
    _connectivity = Connectivity();

    // Seed both signals at boot.
    await _doCheck(_coldStartTimeout);

    // Interface gone → flip offline immediately, no network call needed.
    // Interface appeared → debounced full check.
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      final anyInterface = results.any((r) => r != ConnectivityResult.none);
      if (!anyInterface) {
        hasInternet.value = false;
        backendReachable.value = false;
        _debounceTimer?.cancel();
        _backendRetryTimer?.cancel();
      } else {
        _scheduleCheck();
      }
    });
  }

  void _scheduleCheck() {
    _backendRetryTimer?.cancel();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_checkDebounce, _runConnectivityCheck);
  }

  // Guard wrapper — prevents overlapping background checks.
  Future<void> _runConnectivityCheck({bool longTimeout = false}) async {
    if (_isChecking) return;
    _isChecking = true;
    try {
      await _doCheck(longTimeout ? _retryBackendTimeout : _coldStartTimeout);
    } finally {
      _isChecking = false;
    }
  }

  // Core two-step check. No guard — safe to call directly from forceRecheck().
  //
  // Step 1: full end-to-end backend check (API → hcapp_checkConnection SP → DB).
  //         Happy path — both signals confirmed in one round-trip.
  // Step 2: backend timed out or down — probe Google/MSFT to distinguish
  //         "no internet" from "internet up but backend cold-starting/down".
  Future<void> _doCheck(Duration backendTimeout) async {
    final backendOk = await Utilities.checkHcServer()
        .timeout(backendTimeout, onTimeout: () => false);

    if (backendOk) {
      hasInternet.value = true;
      backendReachable.value = true;
      _backendRetryTimer?.cancel();
      return;
    }

    final internetOk = await Utilities.checkForInternetConnection();
    hasInternet.value = internetOk;
    backendReachable.value = false;
    if (internetOk) _scheduleBackendRetry();
  }

  // Auto-retry while internet is up but backend is unreachable — handles
  // Azure cold starts and brief outages without requiring user action.
  // Stops automatically once backendReachable flips to true.
  void _scheduleBackendRetry() {
    if (!hasInternet.value) return;
    _backendRetryTimer?.cancel();
    _backendRetryTimer = Timer(
      _backendRetryInterval,
      () => _runConnectivityCheck(longTimeout: true),
    );
  }

  // User-initiated recheck (offline ribbon "Try Reconnect").
  // Bypasses the _isChecking guard so it always runs unconditionally.
  Future<bool> forceRecheck() async {
    _debounceTimer?.cancel();
    _backendRetryTimer?.cancel();
    await _doCheck(_retryBackendTimeout);
    return backendReachable.value;
  }

  // Returns true when the device has internet — used by service-layer guards.
  bool isOnline() => hasInternet.value;

  @override
  void onClose() {
    _debounceTimer?.cancel();
    _backendRetryTimer?.cancel();
    unawaited(_connectivitySub?.cancel());
    super.onClose();
  }
}
