import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

/// Amber banner shown wherever payments are taken while the outbox holds
/// queued (not-yet-acknowledged) payments. Tapping it opens the queue sheet.
/// Renders nothing when the outbox is empty, so it can be mounted
/// unconditionally.
class PaymentOutboxBanner extends StatelessWidget {
  const PaymentOutboxBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<PaymentOutboxService>()) {
      return const SizedBox.shrink();
    }
    final PaymentOutboxService outbox = Get.find<PaymentOutboxService>();
    return Obx(() {
      final int n = outbox.pending.length;
      if (n == 0) return const SizedBox.shrink();
      return Material(
        color: Colors.amber.shade700,
        child: InkWell(
          onTap: () => showPaymentOutboxSheet(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              children: <Widget>[
                const Icon(Icons.cloud_upload, color: Colors.black87, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$n payment${n == 1 ? '' : 's'} saved on this phone, '
                    'waiting to send',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                const Text(
                  'VIEW',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// Bottom sheet listing every queued payment with Send now / discard actions.
Future<void> showPaymentOutboxSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _PaymentOutboxSheetBody(),
  );
}

class _PaymentOutboxSheetBody extends StatelessWidget {
  const _PaymentOutboxSheetBody();

  @override
  Widget build(BuildContext context) {
    final PaymentOutboxService outbox = Get.find<PaymentOutboxService>();
    final DateFormat fmt = DateFormat('EEE HH:mm');
    return Container(
      decoration: BoxDecoration(
        color: hc_sheetGreen,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 20 + MediaQuery.of(context).padding.bottom,
      ),
      child: Obx(() {
        final List<PendingPayment> entries = List<PendingPayment>.of(
          outbox.pending,
        )..sort((a, b) => a.createdAtMs.compareTo(b.createdAtMs));
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Payments waiting to send', style: ts_headingLarge),
            const SizedBox(height: 4),
            Text(
              entries.isEmpty
                  ? 'All payments have reached the server.'
                  : 'These are saved on this phone and send automatically '
                        'when a connection is available. They are NOT on the '
                        'server yet.',
              style: ts_body,
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: entries.length,
                itemBuilder: (BuildContext context, int i) {
                  final PendingPayment e = entries[i];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.schedule_send,
                      color: Colors.amber,
                    ),
                    title: Text(
                      e.displayLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${fmt.format(DateTime.fromMillisecondsSinceEpoch(e.createdAtMs))}'
                      ' · amount ${e.paymentAmount.toStringAsFixed(2)}'
                      '${e.attempts > 0 ? ' · ${e.attempts} attempt${e.attempts == 1 ? '' : 's'}' : ''}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.white70,
                      ),
                      tooltip: 'Discard without sending',
                      onPressed: () => _confirmDiscard(context, outbox, e),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            if (entries.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send, color: Colors.white),
                  label: const Text(
                    'Send now',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () async {
                    if (Utilities.isNotConnected()) {
                      showHcSnackbar(
                        'Still no connection — they will send the moment '
                        'one is available.',
                        isError: true,
                      );
                      return;
                    }
                    await Get.find<PaymentOutboxService>().flush();
                  },
                ),
              ),
          ],
        );
      }),
    );
  }

  Future<void> _confirmDiscard(
    BuildContext context,
    PaymentOutboxService outbox,
    PendingPayment e,
  ) async {
    final bool? confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Discard this payment?'),
        content: Text(
          '${e.displayLabel}\n\nThis payment has NOT been recorded on the '
          'server. Discarding removes it from this phone permanently — the '
          'money will not be recorded anywhere.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Get.back<bool>(result: false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Get.back<bool>(result: true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await outbox.discard(e.clientPaymentId);
    }
  }
}
