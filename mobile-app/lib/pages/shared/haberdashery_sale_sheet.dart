import 'package:harrier_central/imports.dart';

/// Bottom sheet for selling haberdashery (productType 3) — V1 is a simple
/// amount + free-text description + payment method. A full product catalogue
/// is future work (docs/haberdashery_payments_plan.md).
///
/// Credit-neutral server-side; Hash Credit can pay. Each sale is its own
/// payment row — multiple sales per hasher per run co-exist.
Future<void> showHaberdasherySaleSheet({
  required BuildContext context,
  required String eventId,
  required String kennelId,
  required String userId,
  required String displayName,
  String? hasherEventMapId,
  AppDomainType appDomainType = AppDomainType.event,
  Future<void> Function()? onSold,
}) async {
  final String tag = 'haberdashery-sale-$userId';
  final HaberdasherySaleController controller = Get.put(
    HaberdasherySaleController(
      eventId: eventId,
      kennelId: kennelId,
      userId: userId,
      displayName: displayName,
      hasherEventMapId: hasherEventMapId,
      appDomainType: appDomainType,
      onSold: onSold,
    ),
    tag: tag,
  );

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => HaberdasherySaleSheetBody(controller: controller),
  ).whenComplete(() => Get.delete<HaberdasherySaleController>(tag: tag));
}

class HaberdasherySaleController extends GetxController {
  HaberdasherySaleController({
    required this.eventId,
    required this.kennelId,
    required this.userId,
    required this.displayName,
    required this.hasherEventMapId,
    required this.appDomainType,
    required this.onSold,
  });

  final String eventId;
  final String kennelId;
  final String userId;
  final String displayName;
  final String? hasherEventMapId;
  final AppDomainType appDomainType;
  final Future<void> Function()? onSold;

  final RxBool isSaving = false.obs;
  final RxInt paymentMethod = RxInt(paymentCash.value);
  final RxnString currencySymbol = RxnString();
  final RxInt digitsAfterDecimal = 2.obs;

  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    unawaited(_loadCurrency());
  }

  @override
  void onClose() {
    amountController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  Future<void> _loadCurrency() async {
    try {
      final k = tableModel.kennelsTableHelper;
      final List<Map<String, dynamic>> rows = await database.rawQuery(
        'SELECT ${k.colCurrencySymbol}, ${k.colDigitsAfterDecimal} '
        'FROM ${EnumDataTables.kennels.commonTableName} '
        'WHERE ${k.colKennelId} = ? LIMIT 1',
        <Object?>[kennelId],
      );
      if (rows.isNotEmpty) {
        currencySymbol.value = rows.first[k.colCurrencySymbol] as String?;
        digitsAfterDecimal.value =
            (rows.first[k.colDigitsAfterDecimal] as num?)?.toInt() ?? 2;
      }
    } catch (e, s) {
      BootLogger.logError('[HaberdasherySaleController._loadCurrency]', e, s);
    }
  }

  Future<void> sell(BuildContext context) async {
    final double? amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      showHcSnackbar('Enter a valid amount.', isError: true);
      return;
    }
    final String description = descriptionController.text.trim();
    if (description.isEmpty) {
      showHcSnackbar('Enter what was sold.', isError: true);
      return;
    }
    if (isSaving.value) return;
    isSaving.value = true;

    try {
      // Through the outbox: captured before sending, retried until the
      // server acknowledges (idempotent — same clientPaymentId per retry).
      final PaymentSubmitOutcome outcome =
          await Get.find<PaymentOutboxService>().submit(
            PaymentsService.buildPending(
              eventId: eventId,
              hasherId: userId,
              hasherEventMapId: hasherEventMapId,
              paymentType: paymentMethod.value,
              paymentAmount: amount,
              minimumAttendenceValue: -1, // never touch attendance
              doPayForExtras: payForRunOnly,
              appDomainType: appDomainType,
              specialRunPrice: amount, // sale price = the debit
              productType: productTypeHaberdashery,
              notes: description,
              displayLabel: 'Haberdashery — $displayName ($description)',
            ),
          );

      if (outcome.queued) {
        showHcSnackbar(
          'No connection — the sale to $displayName is saved on this phone '
          'and will send automatically.',
        );
        if (context.mounted) Navigator.of(context).pop();
        isSaving.value = false;
        return;
      }
      final List<dynamic> results = outcome.results;
      if (results.isEmpty) {
        isSaving.value = false;
        return;
      }
      if (onSold != null) await onSold!();

      showHcSnackbar(
        'Sold: $displayName — $description '
        '(${IveCoreUtilities.getFormattedMoney(amount, digitsAfterDecimal.value, currencySymbol.value ?? '')})',
      );
      if (context.mounted) Navigator.of(context).pop();
    } catch (e, s) {
      BootLogger.logError('[HaberdasherySaleController.sell]', e, s);
      showHcSnackbar(
        'The sale did not go through. Please try again.',
        isError: true,
      );
    } finally {
      isSaving.value = false;
    }
  }
}

class HaberdasherySaleSheetBody extends StatelessWidget {
  const HaberdasherySaleSheetBody({super.key, required this.controller});

  final HaberdasherySaleController controller;

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
        bottom:
            20 +
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Sell haberdashery', style: ts_headingLarge),
          const SizedBox(height: 2),
          Text(c.displayName, style: ts_body),
          const SizedBox(height: 14),
          Obx(
            () => TextField(
              controller: c.amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: 'Amount',
                labelStyle: const TextStyle(color: Colors.black54),
                prefixText: c.currencySymbol.value ?? '',
                prefixStyle: const TextStyle(color: Colors.black),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: c.descriptionController,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 500,
            style: const TextStyle(color: Colors.black),
            decoration: const InputDecoration(
              labelText: 'What was sold',
              labelStyle: TextStyle(color: Colors.black54),
              hintText: 'e.g. T-shirt (L), club badge',
              hintStyle: TextStyle(color: Colors.black38),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              counterStyle: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: <Widget>[
              _methodChip('Cash', paymentCash.value),
              _methodChip('Bank transfer', paymentBankTransfer.value),
              _methodChip('Hash Credit', paymentHashCredit.value),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Obx(
              () => ElevatedButton(
                onPressed: c.isSaving.value
                    ? null
                    : () => unawaited(c.sell(context)),
                child: c.isSaving.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Record sale'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
