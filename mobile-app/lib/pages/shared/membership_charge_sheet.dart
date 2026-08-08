import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

/// Bottom sheet for charging an annual membership (productType 2).
/// Used from the check-in pack page (event domain, HEM known) and the
/// kennel-admin members list (anchor event resolved from the kennel's most
/// recent run). See docs/membership_payments_plan.md.
///
/// The payment is credit-neutral server-side; on success the member's
/// MembershipExpirationDate advances per the kennel's renewal mode and the
/// sheet reports the new date.
Future<void> showMembershipChargeSheet({
  required BuildContext context,
  required String kennelId,
  required String userId,
  required String displayName,
  String? eventId,
  String? hasherEventMapId,
  AppDomainType appDomainType = AppDomainType.user,
  Future<void> Function()? onCharged,
}) async {
  final String tag = 'membership-charge-$userId';
  final MembershipChargeController controller = Get.put(
    MembershipChargeController(
      kennelId: kennelId,
      userId: userId,
      displayName: displayName,
      anchorEventId: eventId,
      hasherEventMapId: hasherEventMapId,
      appDomainType: appDomainType,
      onCharged: onCharged,
    ),
    tag: tag,
  );

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MembershipChargeSheetBody(controller: controller),
  ).whenComplete(() => Get.delete<MembershipChargeController>(tag: tag));
}

class MembershipChargeController extends GetxController {
  MembershipChargeController({
    required this.kennelId,
    required this.userId,
    required this.displayName,
    required this.anchorEventId,
    required this.hasherEventMapId,
    required this.appDomainType,
    required this.onCharged,
  });

  final String kennelId;
  final String userId;
  final String displayName;
  String? anchorEventId;
  final String? hasherEventMapId;
  final AppDomainType appDomainType;
  final Future<void> Function()? onCharged;

  final RxBool isLoading = true.obs;
  final RxBool isCharging = false.obs;
  final RxnString loadError = RxnString();

  /// Renewal mode: 1=rolling, 2=fixed year, 3=lifetime.
  final RxInt renewalMode = 1.obs;
  final RxInt durationMonths = 12.obs;
  final Rxn<DateTime> periodEndDate = Rxn<DateTime>();
  final RxDouble defaultFee = 0.0.obs;
  final RxnString currencySymbol = RxnString();
  final RxInt digitsAfterDecimal = 2.obs;

  /// The member's expiry as of opening the sheet. Null = never a member.
  final Rxn<DateTime> currentExpiry = Rxn<DateTime>();

  /// Selected payment method — cash / bank transfer / hash credit.
  final RxInt paymentMethod = RxInt(paymentCash.value);

  final TextEditingController feeController = TextEditingController();

  static final DateTime _lifetimeSentinel = DateTime(2999);

  bool get isLifetimeMember {
    final DateTime? e = currentExpiry.value;
    return e != null && !e.isBefore(_lifetimeSentinel);
  }

  bool get isCurrentMember {
    final DateTime? e = currentExpiry.value;
    return e != null && e.isAfter(DateTime.now());
  }

  /// Fixed-year mode with a lapsed/unset period cannot sell memberships —
  /// mirror the SP's refusal up front rather than after a round trip.
  bool get fixedYearLapsed {
    if (renewalMode.value != 2) return false;
    final DateTime? end = periodEndDate.value;
    return end == null ||
        end.isBefore(DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day,
        ));
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(_load());
  }

  @override
  void onClose() {
    feeController.dispose();
    super.onClose();
  }

  Future<void> _load() async {
    try {
      final k = tableModel.kennelsTableHelper;
      final List<Map<String, dynamic>> kennelRows = await database.rawQuery(
        'SELECT ${k.colMembershipRenewalMode}, ${k.colMembershipPrice}, '
        '${k.colMembershipDurationInMonths}, ${k.colMembershipPeriodEndDate}, '
        '${k.colCurrencySymbol}, ${k.colDigitsAfterDecimal} '
        'FROM ${EnumDataTables.kennels.commonTableName} '
        'WHERE ${k.colKennelId} = ? LIMIT 1',
        <Object?>[kennelId],
      );
      if (kennelRows.isEmpty) {
        loadError.value = 'Kennel not found on this device — sync and retry.';
        isLoading.value = false;
        return;
      }
      final Map<String, dynamic> kr = kennelRows.first;
      renewalMode.value = (kr[k.colMembershipRenewalMode] as int?) ?? 1;
      durationMonths.value =
          (kr[k.colMembershipDurationInMonths] as int?) ?? 12;
      defaultFee.value =
          ((kr[k.colMembershipPrice] as num?) ?? 0).toDouble();
      currencySymbol.value = kr[k.colCurrencySymbol] as String?;
      digitsAfterDecimal.value = (kr[k.colDigitsAfterDecimal] as num?)?.toInt() ?? 2;
      final String? endText = kr[k.colMembershipPeriodEndDate] as String?;
      periodEndDate.value = endText == null ? null : DateTime.tryParse(endText);

      feeController.text = defaultFee.value.toStringAsFixed(
        digitsAfterDecimal.value,
      );

      await _loadExpiry();

      // Members-list flow: anchor the payment to the kennel's most recent
      // run (Payment.EventId is NOT NULL server-side).
      if (anchorEventId == null) {
        final e = tableModel.eventsTableHelper;
        final List<Map<String, dynamic>> eventRows = await database.rawQuery(
          'SELECT ${e.colEventId} FROM ${EnumDataTables.events.commonTableName} '
          'WHERE ${e.colKennelId} = ? AND ${e.colEventStartDatetimeGmt} <= ? '
          'ORDER BY ${e.colEventStartDatetimeGmt} DESC LIMIT 1',
          <Object?>[kennelId, DateTime.now().toUtc().toIso8601String()],
        );
        if (eventRows.isEmpty) {
          loadError.value =
              'No past run found to anchor the payment to. Sync and retry.';
          isLoading.value = false;
          return;
        }
        anchorEventId = eventRows.first[e.colEventId] as String;
      }

      isLoading.value = false;
    } catch (e, s) {
      BootLogger.logError('[MembershipChargeController._load]', e, s);
      loadError.value = 'Could not load membership details.';
      isLoading.value = false;
    }
  }

  Future<void> _loadExpiry() async {
    final hkm = tableModel.hasherKennelMapTableHelper;
    final List<Map<String, dynamic>> rows = await database.rawQuery(
      'SELECT ${hkm.colMembershipExpirationDate} '
      'FROM ${hkm.getTableName(appDomainType)} '
      'WHERE ${hkm.colUserId} = ? AND ${hkm.colKennelId} = ? LIMIT 1',
      <Object?>[userId, kennelId],
    );
    final String? text = rows.isEmpty
        ? null
        : rows.first[hkm.colMembershipExpirationDate] as String?;
    currentExpiry.value = text == null ? null : DateTime.tryParse(text);
  }

  String formatMoney(double amount) => IveCoreUtilities.getFormattedMoney(
    amount,
    digitsAfterDecimal.value,
    currencySymbol.value ?? '',
  );

  String formatDate(DateTime d) => DateFormat.yMMMd().format(d.toLocal());

  /// What the member's new expiry will read after this charge — mirrors the
  /// SP's computation for preview purposes only (the SP is authoritative).
  String get renewalPreview {
    switch (renewalMode.value) {
      case 3:
        return 'Grants a LIFETIME membership';
      case 2:
        final DateTime? end = periodEndDate.value;
        return end == null
            ? 'Membership year not configured'
            : 'Membership until ${formatDate(end)}';
      default:
        final DateTime now = DateTime.now();
        final DateTime base =
            (isCurrentMember && !isLifetimeMember) ? currentExpiry.value! : now;
        final DateTime next = DateTime(
          base.year, base.month + durationMonths.value, base.day,
        );
        return 'Membership until ${formatDate(next)}';
    }
  }

  String get currentStatusLabel {
    if (isLifetimeMember) return 'Lifetime member';
    final DateTime? e = currentExpiry.value;
    if (e == null) return 'Not a member';
    return e.isAfter(DateTime.now())
        ? 'Member until ${formatDate(e)}'
        : 'Membership LAPSED ${formatDate(e)}';
  }

  Future<void> charge(BuildContext context) async {
    final double? fee = double.tryParse(feeController.text.trim());
    if (fee == null || fee < 0) {
      showHcSnackbar('Enter a valid membership fee.', isError: true);
      return;
    }
    if (isCharging.value) return;
    isCharging.value = true;

    try {
      // A fee differing from the kennel default rides @specialRunPrice,
      // which the SP treats as the membership-fee override.
      final bool overridden = (fee - defaultFee.value).abs() > 0.0001;
      final PaymentsService paySrv = PaymentsService();
      final List<dynamic> results = await paySrv.payForEvent(
        anchorEventId!,
        userId,
        hasherEventMapId,
        paymentMethod.value,
        fee,
        -1, // never touch attendance from a membership charge
        payForRunOnly,
        appDomainType,
        specialRunPrice: overridden ? fee : null,
        productType: productTypeMembership,
      );

      if (results.isEmpty) {
        // Error path already surfaced by the service's error dialog.
        isCharging.value = false;
        return;
      }

      // The SP returns the freshly written expiry in the adHocData rowset.
      final DateTime? newExpiry = DateTime.tryParse(
        (results[0]['newMembershipExpiry'] ?? '').toString(),
      );
      if (newExpiry != null) currentExpiry.value = newExpiry;

      if (onCharged != null) await onCharged!();
      if (newExpiry == null) await _loadExpiry();

      final String until = isLifetimeMember
          ? 'LIFETIME'
          : currentExpiry.value == null
          ? 'updated'
          : formatDate(currentExpiry.value!);
      showHcSnackbar(
        'Membership charged: $displayName — ${formatMoney(fee)} · '
        'valid until $until',
      );
      if (context.mounted) Navigator.of(context).pop();
    } catch (e, s) {
      BootLogger.logError('[MembershipChargeController.charge]', e, s);
      showHcSnackbar(
        'The membership charge did not go through. Please try again.',
        isError: true,
      );
    } finally {
      isCharging.value = false;
    }
  }
}

class MembershipChargeSheetBody extends StatelessWidget {
  const MembershipChargeSheetBody({super.key, required this.controller});

  final MembershipChargeController controller;

  Widget _methodChip(String label, int value) {
    return Obx(
      () => ChoiceChip(
        label: Text(label),
        selected: controller.paymentMethod.value == value,
        onSelected: (_) => controller.paymentMethod.value = value,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Container(
      decoration: BoxDecoration(
        color: hc_sheetGreen,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Obx(() {
        if (c.isLoading.value) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final String? error = c.loadError.value;
        if (error != null) {
          return SizedBox(
            height: 160,
            child: Center(
              child: Text(error, textAlign: TextAlign.center, style: ts_body),
            ),
          );
        }
        if (c.isLifetimeMember) {
          return SizedBox(
            height: 160,
            child: Center(
              child: Text(
                '${c.displayName} is already a lifetime member.',
                textAlign: TextAlign.center,
                style: ts_body,
              ),
            ),
          );
        }
        if (c.fixedYearLapsed) {
          return SizedBox(
            height: 180,
            child: Center(
              child: Text(
                'This kennel\'s membership year has ended or is not set up.\n'
                'Update the membership period in kennel settings first.',
                textAlign: TextAlign.center,
                style: ts_body,
              ),
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Annual membership', style: ts_headingLarge),
            const SizedBox(height: 2),
            Text(c.displayName, style: ts_body),
            const SizedBox(height: 6),
            Text(
              c.currentStatusLabel,
              style: ts_body.copyWith(
                // Lightened for the dark jungle background.
                color: c.isCurrentMember
                    ? Colors.greenAccent.shade100
                    : Colors.red.shade200,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: c.feeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: 'Membership fee',
                labelStyle: const TextStyle(color: Colors.black54),
                prefixText: c.currencySymbol.value ?? '',
                prefixStyle: const TextStyle(color: Colors.black),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: <Widget>[
                _methodChip('Cash', paymentCash.value),
                _methodChip('Bank transfer', paymentBankTransfer.value),
                _methodChip('Hash Credit', paymentHashCredit.value),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              c.renewalPreview,
              style: ts_body.copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: c.isCharging.value
                    ? null
                    : () => unawaited(c.charge(context)),
                child: c.isCharging.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Charge membership'),
              ),
            ),
          ],
        );
      }),
    );
  }
}
