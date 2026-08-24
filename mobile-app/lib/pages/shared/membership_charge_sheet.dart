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

  /// Check-in flow (event domain, real run context): the sheet also offers
  /// the combined "membership + run fee / check in" action — one atomic SP
  /// call records both payments and checks the payer in. A missing HEM is
  /// fine (a virgin buying membership on arrival) — the SP resolves or
  /// creates it. The members-list flow (kennel/user domain, anchor run)
  /// deliberately stays membership-only: there is no run being attended.
  bool get isCheckInFlow => appDomainType == AppDomainType.event;

  /// The run price the combined action would charge — MEMBER pricing (they
  /// are becoming/renewing a member in this very transaction) with the
  /// hasher's kennel discounts applied. Mirrors the SP for display; the SP
  /// is authoritative. Null until loaded.
  final RxnDouble memberRunPrice = RxnDouble();

  /// True when the HEM already carries a live run payment — nothing to
  /// combine, so only the membership-only button shows.
  final RxBool runAlreadyPaid = false.obs;

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

  /// Expiry at or beyond 2100 counts as lifetime — the project-wide
  /// definition (the SP writes 2999 for renewal-mode-3 grants; hand-set
  /// far-future dates count too). Shared with membership_status.dart.
  static final DateTime _lifetimeSentinel = DateTime(2100);

  bool get isLifetimeMember {
    final DateTime? e = currentExpiry.value;
    return e != null && !e.isBefore(_lifetimeSentinel);
  }

  bool get isCurrentMember {
    final DateTime? e = currentExpiry.value;
    return e != null && e.isAfter(DateTime.now());
  }

  /// Fixed-year mode needs a configured end month/day to sell into. It is a
  /// RECURRING annual window (only month/day matter), so it never lapses —
  /// mirror the SP's null-only refusal up front rather than after a round trip.
  bool get fixedYearUnset {
    if (renewalMode.value != 2) return false;
    return periodEndDate.value == null;
  }

  /// The next occurrence of [end]'s month/day on or after today — the shared
  /// renewal anniversary. Day is clamped to the target month's length so a
  /// 29-Feb end lands on 28 Feb in a non-leap year.
  DateTime _nextAnniversary(DateTime end) {
    final DateTime today = DateTime.now();
    DateTime forYear(int y) {
      final int lastDay = DateTime(y, end.month + 1, 0).day;
      return DateTime(y, end.month, end.day > lastDay ? lastDay : end.day);
    }

    final DateTime thisYear = forYear(today.year);
    final DateTime todayDate = DateTime(today.year, today.month, today.day);
    return thisYear.isBefore(todayDate) ? forYear(today.year + 1) : thisYear;
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
      if (isCheckInFlow) await _loadRunContext();

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

  /// Loads what the combined action would charge for the run leg (member
  /// price with this hasher's kennel discounts) and whether the HEM already
  /// has a live run payment. Best-effort: on any failure the combined button
  /// simply doesn't show (memberRunPrice stays null).
  Future<void> _loadRunContext() async {
    try {
      final e = tableModel.eventsTableHelper;
      final k = tableModel.kennelsTableHelper;
      final hkm = tableModel.hasherKennelMapTableHelper;
      final pay = tableModel.paymentsTableHelper;

      final List<Map<String, dynamic>> priceRows = await database.rawQuery(
        '''
        SELECT COALESCE(e.${e.colEventPriceForMembers}, k.${k.colDefaultPriceForMembers},
                        e.${e.colEventPriceForNonMembers}, k.${k.colDefaultPriceForNonMembers}, 0) AS basePrice,
               COALESCE(hkm.${hkm.colDiscountAmount}, 0) AS discountAmount,
               COALESCE(hkm.${hkm.colDiscountPercent}, 0) AS discountPercent
        FROM ${EnumDataTables.events.commonTableName} e
        INNER JOIN ${EnumDataTables.kennels.commonTableName} k
          ON k.${k.colKennelId} = e.${e.colKennelId}
        LEFT OUTER JOIN ${hkm.getTableName(appDomainType)} hkm
          ON hkm.${hkm.colUserId} = ? AND hkm.${hkm.colKennelId} = k.${k.colKennelId}
        WHERE e.${e.colEventId} = ? LIMIT 1
        ''',
        <Object?>[userId, anchorEventId],
      );
      if (priceRows.isNotEmpty) {
        final Map<String, dynamic> row = priceRows.first;
        double price = ((row['basePrice'] as num?) ?? 0).toDouble();
        price -= ((row['discountAmount'] as num?) ?? 0).toDouble();
        price -= price * (((row['discountPercent'] as num?) ?? 0) / 100.0);
        memberRunPrice.value = price < 0 ? 0 : price;
      }

      // No HEM yet (virgin at check-in) ⇒ no run payment can exist.
      if ((hasherEventMapId ?? '').isEmpty) {
        runAlreadyPaid.value = false;
      } else {
        final List<Map<String, dynamic>> payRows = await database.rawQuery(
          'SELECT COUNT(*) AS n FROM ${EnumDataTables.payments.eventTableName} '
          'WHERE ${pay.colHemId} = ? AND ${pay.colCancelledBy} IS NULL '
          'AND COALESCE(${pay.colProductType}, 1) = 1',
          <Object?>[hasherEventMapId],
        );
        runAlreadyPaid.value =
            payRows.isNotEmpty && ((payRows.first['n'] as num?) ?? 0) > 0;
      }
    } catch (e, s) {
      BootLogger.logError('[MembershipChargeController._loadRunContext]', e, s);
      memberRunPrice.value = null;
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
            : 'Membership until ${formatDate(_nextAnniversary(end))}';
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

  /// Charges the membership; with [alsoPayRun] the SP atomically records the
  /// run fee at member pricing (zero ⇒ free member run) and checks the payer
  /// in — one call, all-or-nothing.
  Future<void> charge(BuildContext context, {bool alsoPayRun = false}) async {
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
        // Combined path checks the payer in; membership-only never touches
        // attendance.
        alsoPayRun ? attendenceAtHash.value : -1,
        payForRunOnly,
        appDomainType,
        specialRunPrice: overridden ? fee : null,
        productType: productTypeMembership,
        alsoPayRunFee: alsoPayRun,
      );

      if (results.isEmpty) {
        // Error path already surfaced by the service's error dialog.
        isCharging.value = false;
        return;
      }

      // The SP returns the freshly written expiry in the adHocData rowset,
      // plus what the run leg charged on the combined path.
      final DateTime? newExpiry = DateTime.tryParse(
        (results[0]['newMembershipExpiry'] ?? '').toString(),
      );
      if (newExpiry != null) currentExpiry.value = newExpiry;
      final double? runFee = alsoPayRun
          ? double.tryParse((results[0]['runFeeAmount'] ?? '').toString())
          : null;

      if (onCharged != null) await onCharged!();
      if (newExpiry == null) await _loadExpiry();

      final String until = isLifetimeMember
          ? 'LIFETIME'
          : currentExpiry.value == null
          ? 'updated'
          : formatDate(currentExpiry.value!);
      final String runPart = !alsoPayRun
          ? ''
          : runFee == null || runFee <= 0
          ? ' · checked in (run free)'
          : ' · run fee ${formatMoney(runFee)} · checked in';
      showHcSnackbar(
        'Membership charged: $displayName — ${formatMoney(fee)} · '
        'valid until $until$runPart',
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
        // padding.bottom keeps the action buttons above the Android 15/16
        // edge-to-edge system navigation bar (it collapses to 0 while the
        // keyboard is up, so the two insets never double-pad).
        bottom: 20 +
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom,
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
        // Lifetime members get a statement, not a form — there is nothing
        // to sell them, so no fee field, no payment method, no charge button.
        if (c.isLifetimeMember) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Lifetime membership', style: ts_headingLarge),
              const SizedBox(height: 2),
              Text(c.displayName, style: ts_body),
              const SizedBox(height: 6),
              Text(
                'Lifetime member — there is nothing to charge.',
                style: ts_body.copyWith(
                  color: Colors.greenAccent.shade100,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        }
        if (c.fixedYearUnset) {
          return SizedBox(
            height: 180,
            child: Center(
              child: Text(
                'This kennel\'s membership year is not set up.\n'
                'Set the membership year end in kennel settings first.',
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
                    : Text(
                        _showCombinedButton(c)
                            ? 'Charge membership only'
                            : 'Charge membership',
                      ),
              ),
            ),
            // Check-in flow only: the combined atomic action — membership +
            // run fee (member pricing) + check-in in one SP call. Hidden when
            // the run is already paid (nothing to combine) or the run price
            // could not be loaded.
            if (_showCombinedButton(c)) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hc_red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: c.isCharging.value
                      ? null
                      : () => unawaited(c.charge(context, alsoPayRun: true)),
                  child: Text(
                    (c.memberRunPrice.value ?? 0) <= 0
                        ? 'Membership + check in (run free)'
                        : 'Membership + run fee '
                              '(${c.formatMoney(c.memberRunPrice.value!)})',
                  ),
                ),
              ),
            ],
          ],
        );
      }),
    );
  }

  /// Combined button: check-in flow, run price known, run not already paid.
  bool _showCombinedButton(MembershipChargeController c) =>
      c.isCheckInFlow &&
      c.memberRunPrice.value != null &&
      !c.runAlreadyPaid.value;
}
