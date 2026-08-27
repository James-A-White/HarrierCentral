import 'package:harrier_central/imports.dart';

/// Outcome of submitting a payment through the outbox.
enum PaymentSubmitStatus {
  /// Server acknowledged it — recorded (or an idempotent replay). Done.
  delivered,

  /// Could not reach the server. The capture is persisted on this phone and
  /// will be retried automatically until acknowledged.
  queued,

  /// The server actively rejected it (validation/auth). NOT queued — the
  /// charge did not happen and retrying would fail identically.
  rejected,
}

class PaymentSubmitOutcome {
  PaymentSubmitOutcome(this.status, this.results, this.entry);

  final PaymentSubmitStatus status;

  /// Sync/adHocData rows when [PaymentSubmitStatus.delivered]; empty otherwise.
  final List<dynamic> results;
  final PendingPayment entry;

  bool get delivered => status == PaymentSubmitStatus.delivered;
  bool get queued => status == PaymentSubmitStatus.queued;
}

/// The payment outbox: every charge is captured to persistent storage BEFORE
/// its first send attempt and stays there until the server acknowledges it.
///
/// Why: venue signal is exactly bad where payments happen (a field, a pub
/// basement). A charge whose response was lost used to be a coin toss —
/// retry and risk a double charge, or don't and risk losing the money.
/// Two halves fix that:
///  - the server (processPayment 1.5.0) treats a resend carrying the same
///    clientPaymentId as an idempotent replay — acknowledged, never
///    re-recorded;
///  - this service persists the capture and retries it until an
///    acknowledgement arrives (app resume, connectivity returning, and a
///    periodic sweep), surviving app restarts in between.
///
/// A server REJECTION (validation/auth) is not queued or retried: the charge
/// never happened, the admin is told, and they re-initiate if appropriate.
class PaymentOutboxService extends GetxService with WidgetsBindingObserver {
  final RxList<PendingPayment> pending = <PendingPayment>[].obs;

  final PaymentsService _paySrv = PaymentsService();
  Timer? _pollTimer;
  bool _flushing = false;
  bool _wasOnline = false;
  int _ticksSinceFlush = 0;

  /// Entries currently mid-send. A flush skips these so a foreground submit
  /// and a background sweep never race the same capture (the server-side
  /// idempotency would make that harmless, but it would double the
  /// notifications).
  final Set<String> _inFlight = <String>{};

  static const Duration _pollInterval = Duration(seconds: 10);
  // A full-interval retry every _fullSweepTicks polls (≈ 60 s) even without
  // a connectivity edge, so a flush that failed mid-way gets another shot.
  static const int _fullSweepTicks = 6;

  int get pendingCount => pending.length;

  @override
  void onInit() {
    super.onInit();
    _load();
    WidgetsBinding.instance.addObserver(this);
    // Retry triggers are POLLED, not event-bound: a 10 s tick that looks up
    // the CURRENT NetworkService and fires on the offline→online edge (plus
    // a periodic full sweep). An `ever()` worker bound to
    // networkService.backendReachable went deaf after in-app restarts —
    // services_init deletes and recreates NetworkService (lazyPut+fenix), so
    // the worker kept listening to the dead instance's Rx and reconnects
    // never triggered a flush.
    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollTick());
    _wasOnline = _isOnlineNow();
    // Anything left over from a previous session gets a shot at boot.
    unawaited(flush());
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.onClose();
  }

  bool _isOnlineNow() =>
      Get.isRegistered<NetworkService>() &&
      Get.find<NetworkService>().isOnline();

  void _pollTick() {
    final bool online = _isOnlineNow();
    final bool cameOnline = online && !_wasOnline;
    _wasOnline = online;
    if (pending.isEmpty || !online) return;
    _ticksSinceFlush++;
    if (cameOnline || _ticksSinceFlush >= _fullSweepTicks) {
      unawaited(flush());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(flush());
  }

  /// Captures [entry] to the persistent outbox, then attempts to send it
  /// right away. The entry is on disk BEFORE the first network attempt, so
  /// even an app kill mid-request cannot lose the charge.
  Future<PaymentSubmitOutcome> submit(PendingPayment entry) async {
    pending.add(entry);
    await _persist();

    _inFlight.add(entry.clientPaymentId);
    final PaymentSendResult result;
    try {
      result = await _paySrv.sendPending(entry);
    } finally {
      _inFlight.remove(entry.clientPaymentId);
    }
    entry.attempts++;

    if (result.delivered) {
      pending.removeWhere(
        (PendingPayment e) => e.clientPaymentId == entry.clientPaymentId,
      );
      await _persist();
      return PaymentSubmitOutcome(
        PaymentSubmitStatus.delivered,
        result.results,
        entry,
      );
    }
    if (result.rejected) {
      // The default error dialog has already shown (no errorCallback was
      // passed for this foreground attempt). Nothing was recorded.
      pending.removeWhere(
        (PendingPayment e) => e.clientPaymentId == entry.clientPaymentId,
      );
      await _persist();
      return PaymentSubmitOutcome(
        PaymentSubmitStatus.rejected,
        const <dynamic>[],
        entry,
      );
    }
    await _persist(); // keep the bumped attempt count
    BootLogger.logBreadcrumb(
      'PaymentOutbox: queued ${entry.displayLabel} '
      '(${entry.clientPaymentId}) — transport failure on first attempt',
    );
    return PaymentSubmitOutcome(
      PaymentSubmitStatus.queued,
      const <dynamic>[],
      entry,
    );
  }

  /// Retries every queued capture, oldest first. Stops at the first
  /// transport failure (the network is down for the rest too). Serialized —
  /// overlapping triggers (resume + connectivity + timer) collapse to one run.
  Future<void> flush() async {
    if (_flushing || pending.isEmpty) return;
    if (Utilities.isNotConnected()) return;
    _flushing = true;
    _ticksSinceFlush = 0;
    try {
      final List<PendingPayment> snapshot = List<PendingPayment>.of(pending)
        ..sort(
          (PendingPayment a, PendingPayment b) =>
              a.createdAtMs.compareTo(b.createdAtMs),
        );
      for (final PendingPayment entry in snapshot) {
        if (_inFlight.contains(entry.clientPaymentId)) continue;
        DbErrorModel? businessError;
        _inFlight.add(entry.clientPaymentId);
        final PaymentSendResult result;
        try {
          result = await _paySrv.sendPending(
            entry,
            // Background retry: capture the server's rejection instead of
            // popping a modal over whatever the user is doing now.
            errorCallback: (DbErrorModel err) async {
              businessError = err;
              return true;
            },
          );
        } finally {
          _inFlight.remove(entry.clientPaymentId);
        }
        entry.attempts++;

        if (result.delivered) {
          pending.removeWhere(
            (PendingPayment e) => e.clientPaymentId == entry.clientPaymentId,
          );
          await _persist();
          BootLogger.logBreadcrumb(
            'PaymentOutbox: delivered ${entry.displayLabel} '
            '(attempt ${entry.attempts})',
          );
          // The response's sync rowsets updated the local payment tables —
          // tell open check-in/report screens to re-read so the delivery is
          // visible immediately.
          if (Get.isRegistered<DataChangeService>()) {
            Get.find<DataChangeService>().notify(
              DataChangeEvent(
                type: DataChangeType.paymentDelivered,
                id: entry.eventId,
              ),
            );
          }
          _notify(
            'Payment sent',
            '${entry.displayLabel} has reached the server.',
            isError: false,
          );
          continue;
        }
        if (result.rejected) {
          pending.removeWhere(
            (PendingPayment e) => e.clientPaymentId == entry.clientPaymentId,
          );
          await _persist();
          BootLogger.logError(
            '[PaymentOutbox]',
            'Server rejected queued payment ${entry.displayLabel} '
                '(${entry.clientPaymentId}): '
                '${businessError?.errorTitle ?? result.rawResponse}',
            null,
          );
          _notify(
            'Payment NOT recorded',
            '${entry.displayLabel} was rejected by the server'
                '${businessError?.errorUserMessage == null ? '' : ': ${businessError!.errorUserMessage}'}. '
                'Please charge it again.',
            isError: true,
          );
          continue;
        }
        // Transport failure — persist the attempt bump and stop; the next
        // trigger (resume / connectivity / sweep) will try again.
        await _persist();
        break;
      }
    } finally {
      _flushing = false;
    }
  }

  /// The queued capture for a specific hasher/HEM on an event, or null.
  /// Lets list rows render a "payment noted, waiting to send" state for
  /// exactly the person who was charged offline. Matches by HEM id when
  /// both sides have one, else by hasher id (captures carry GUID_EMPTY for
  /// whichever of the two the call site didn't know). Reading this inside
  /// an Obx subscribes the row to [pending], so queueing and delivery both
  /// repaint it.
  PendingPayment? queuedFor({
    required String eventId,
    String? hasherId,
    String? hemId,
  }) {
    bool realId(String? v) =>
        v != null &&
        v.isNotEmpty &&
        v.length == GUID_EMPTY.length &&
        v != GUID_EMPTY;
    for (final PendingPayment e in pending) {
      if (normalizeUuid(e.eventId) != normalizeUuid(eventId)) continue;
      if (realId(e.hasherEventMapId) &&
          realId(hemId) &&
          normalizeUuid(e.hasherEventMapId!) == normalizeUuid(hemId!)) {
        return e;
      }
      if (realId(e.hasherId) &&
          realId(hasherId) &&
          normalizeUuid(e.hasherId!) == normalizeUuid(hasherId!)) {
        return e;
      }
    }
    return null;
  }

  /// Discards a queued capture WITHOUT sending it — the payment was never
  /// recorded on the server. Only for the outbox sheet's explicit,
  /// confirmed "discard" action (a mis-tap the admin doesn't want sent).
  Future<void> discard(String clientPaymentId) async {
    final PendingPayment? entry = pending.firstWhereOrNull(
      (PendingPayment e) => e.clientPaymentId == clientPaymentId,
    );
    if (entry == null) return;
    pending.removeWhere(
      (PendingPayment e) => e.clientPaymentId == clientPaymentId,
    );
    await _persist();
    BootLogger.logBreadcrumb(
      'PaymentOutbox: DISCARDED ${entry.displayLabel} ($clientPaymentId) '
      'by user — never sent',
    );
  }

  void _notify(String title, String message, {required bool isError}) {
    if (Get.context == null && Get.overlayContext == null) return;
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError ? hc_red : hc_blue,
      colorText: Colors.white,
      duration: Duration(seconds: isError ? 8 : 4),
    );
  }

  void _load() {
    try {
      final String? raw = getStringPref(StringPrefsEnum.paymentOutboxJson);
      if (raw == null || raw.isEmpty) return;
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      pending.assignAll(
        list
            .whereType<Map<String, dynamic>>()
            .map(PendingPayment.fromJson)
            .toList(),
      );
      if (pending.isNotEmpty) {
        BootLogger.logBreadcrumb(
          'PaymentOutbox: loaded ${pending.length} queued payment(s) from a '
          'previous session',
        );
      }
    } catch (e, s) {
      // A corrupt outbox must not brick payments; log loudly and start empty.
      BootLogger.logError('[PaymentOutbox] load failed', e, s);
    }
  }

  Future<void> _persist() async {
    await setStringPref(
      StringPrefsEnum.paymentOutboxJson,
      pending.isEmpty
          ? null
          : jsonEncode(pending.map((PendingPayment e) => e.toJson()).toList()),
    );
  }
}
