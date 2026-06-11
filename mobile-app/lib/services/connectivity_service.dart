import 'package:harrier_central/imports.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService extends GetxService {
  // Whether the device can reach the internet (Google/MSFT probe)
  final RxBool hasInternet = false.obs;
  // Whether the HC backend is fully reachable (API → hcapp_checkConnection SP → DB).
  // True at boot once backend responds, and assumed true whenever internet is up
  // (99.99% uptime). Explicitly set false only when checkHcServer() fails.
  final RxBool backendReachable = false.obs;

  late final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  // Active only while offline — polls Google/MSFT so recovery is detected within
  // ~5s without any HC backend traffic.
  StreamSubscription<InternetStatus>? _recoveryWatcherSub;
  Timer? _debounceTimer;
  Timer? _periodicCheckTimer;
  bool _isChecking = false;

  static const Duration _checkDebounce = Duration(milliseconds: 500);
  // Per-attempt timeout for boot polling, forceRecheck, and API failure checks.
  static const Duration _backendCheckTimeout = Duration(seconds: 10);
  // Boot retries: 3 × 10s = 30s max to handle Azure cold starts.
  static const int _bootMaxAttempts = 3;
  // Watchdog interval — Google/MSFT only, no HC backend traffic.
  static const Duration _periodicCheckInterval = Duration(seconds: 30);

  Future<void> init() async {
    _connectivity = Connectivity();

    // Boot: poll HC backend to trigger Azure cold start and wait for it to respond.
    await _bootCheck();

    // 30s watchdog — Google/MSFT only.
    _periodicCheckTimer = Timer.periodic(
      _periodicCheckInterval,
      (_) => _runInternetCheck(),
    );

    // Interface gone → offline immediately, no network call needed.
    // Interface appeared → debounced Google/MSFT check.
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      final anyInterface = results.any((r) => r != ConnectivityResult.none);
      if (!anyInterface) {
        hasInternet.value = false;
        backendReachable.value = false;
        _debounceTimer?.cancel();
        _startRecoveryWatcher();
      } else {
        _scheduleCheck();
      }
    });
  }

  // Polls HC backend at boot to trigger Azure cold start.
  // Retries up to _bootMaxAttempts before falling back to an internet check.
  Future<void> _bootCheck() async {
    final interfaces = await _connectivity.checkConnectivity();
    if (!interfaces.any((r) => r != ConnectivityResult.none)) {
      _startRecoveryWatcher();
      return;
    }

    for (int i = 0; i < _bootMaxAttempts; i++) {
      final ok = await Utilities.checkHcServer()
          .timeout(_backendCheckTimeout, onTimeout: () => false);
      if (ok) {
        hasInternet.value = true;
        backendReachable.value = true;
        return;
      }
    }

    // All backend attempts failed — check if general internet is available.
    final internetOk = await Utilities.checkForInternetConnection();
    hasInternet.value = internetOk;
    backendReachable.value = false;
    if (!internetOk) _startRecoveryWatcher();
  }

  void _scheduleCheck() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_checkDebounce, _runInternetCheck);
  }

  // Google/MSFT check — no HC backend traffic.
  // If internet is reachable, assumes the HC backend is also up (99.99% uptime).
  // If not, starts the recovery watcher so restoration is detected quickly.
  Future<void> _runInternetCheck() async {
    if (_isChecking) return;
    _isChecking = true;
    try {
      final internetOk = await Utilities.checkForInternetConnection();
      hasInternet.value = internetOk;
      if (internetOk) {
        backendReachable.value = true;
        _stopRecoveryWatcher();
      } else {
        backendReachable.value = false;
        _startRecoveryWatcher();
      }
    } finally {
      _isChecking = false;
    }
  }

  // Full end-to-end backend check (API → SP → DB). Falls back to Google/MSFT
  // if the backend doesn't respond, to distinguish "backend specifically down"
  // from "no internet". No guard — callers manage entry.
  Future<void> _runBackendCheck() async {
    final backendOk = await Utilities.checkHcServer()
        .timeout(_backendCheckTimeout, onTimeout: () => false);
    if (backendOk) {
      hasInternet.value = true;
      backendReachable.value = true;
      _stopRecoveryWatcher();
    } else {
      final internetOk = await Utilities.checkForInternetConnection();
      hasInternet.value = internetOk;
      backendReachable.value = false;
      if (!internetOk) _startRecoveryWatcher();
    }
  }

  // Called by service_common.dart when an API call fails unexpectedly.
  // Updates both signals so the ribbon shows the appropriate state.
  Future<void> handleApiFailure() async {
    if (_isChecking) return;
    _isChecking = true;
    try {
      await _runBackendCheck();
    } finally {
      _isChecking = false;
    }
  }

  // User-initiated recheck (offline ribbon "Try Reconnect").
  // Always runs unconditionally — bypasses the _isChecking guard.
  Future<bool> forceRecheck() async {
    _debounceTimer?.cancel();
    _stopRecoveryWatcher();
    await _runBackendCheck();
    return backendReachable.value;
  }

  void _startRecoveryWatcher() {
    if (_recoveryWatcherSub != null) return;
    _recoveryWatcherSub = InternetConnection.createInstance(
      customCheckOptions: [
        InternetCheckOption(uri: Uri.parse(CONNECTION_TEST_GOOGLE_URL)),
        InternetCheckOption(uri: Uri.parse(CONNECTION_TEST_MSFT_URL)),
      ],
    ).onStatusChange.listen((status) {
      if (status == InternetStatus.connected) {
        _stopRecoveryWatcher();
        _scheduleCheck();
      }
    });
  }

  void _stopRecoveryWatcher() {
    _recoveryWatcherSub?.cancel();
    _recoveryWatcherSub = null;
  }

  // Returns true when the device has internet — used by service-layer guards.
  bool isOnline() => hasInternet.value;

  @override
  void onClose() {
    _debounceTimer?.cancel();
    _periodicCheckTimer?.cancel();
    _stopRecoveryWatcher();
    unawaited(_connectivitySub?.cancel());
    super.onClose();
  }
}
