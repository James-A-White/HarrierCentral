import 'package:harrier_central/imports.dart';

/// Manage a kennel's catalogue (3.1): run packages, memberships,
/// haberdashery. What is on sale, what it costs, and what promotional credit
/// it grants.
///
/// Reads come from the local table — products sync to every phone — so the
/// list is right offline and instant. Writes go to the server and the row
/// comes back on the next sync.
class ProductEditorController extends GetxController {
  ProductEditorController({required this.kennelId, required this.kennelName});

  final String kennelId;
  final String kennelName;

  final ProductService _service = const ProductService();

  final RxBool busy = false.obs;
  final RxString status = ''.obs;
  final RxList<KennelProduct> products = <KennelProduct>[].obs;

  @override
  void onReady() {
    super.onReady();
    unawaited(load());
  }

  Future<void> load() async {
    busy.value = true;
    try {
      products.assignAll(await ProductService.forKennel(kennelId));
    } catch (e, s) {
      BootLogger.logError('[ProductEditorController.load]', e, s);
      status.value = 'The catalogue could not be read.';
    } finally {
      busy.value = false;
    }
  }

  /// Save, then re-read locally. The row itself arrives on the next sync, so
  /// the list is refreshed optimistically from what was just written rather
  /// than waiting for a round trip the user did not ask for.
  Future<bool> save({
    String? productId,
    required int productType,
    required String name,
    required String description,
    required double priceCharged,
    required double promotionalCredit,
    required double unitCost,
    int? runCount,
    required bool isActive,
    String? productDetailsJson,
  }) async {
    busy.value = true;
    status.value = '';
    try {
      final String? id = await _service.save(
        kennelId: kennelId,
        productId: productId,
        productType: productType,
        name: name,
        description: description.isEmpty ? null : description,
        // The phone only writes the "fixed" pricing mode. Member/non-member
        // prices, a choice of amounts, a price per size and deposit-plus-
        // balance are set in the portal, which has the room to edit them
        // properly. Editing such a product here would silently flatten it, so
        // the list marks those read-only instead.
        pricingJson: jsonEncode(<String, dynamic>{
          'mode': 'fixed',
          'price': priceCharged,
          if (unitCost != 0) 'unitCost': unitCost,
          if (promotionalCredit != 0) 'promotionalCredit': promotionalCredit,
          'runsIncluded': ?runCount,
        }),
        productDetailsJson: productDetailsJson,
        isActive: isActive,
      );
      if (id == null) {
        status.value = 'That could not be saved. Please try again.';
        return false;
      }
      // Pull the row straight back rather than waiting for the next boot
      // sync — the editor should show what was just saved. Products only, so
      // it is a small delta.
      await SyncUserDataService().updateFromBackend(
        EnumDataTables.products.flag,
        false,
        batchText: 'product save',
        debugText: 'ProductEditor.save',
      );
      await load();
      return true;
    } catch (e, s) {
      BootLogger.logError('[ProductEditorController.save]', e, s);
      status.value = 'That could not be saved. Please try again.';
      return false;
    } finally {
      busy.value = false;
    }
  }
}

class ProductEditorPage extends StatelessWidget {
  const ProductEditorPage({
    super.key,
    required this.kennelId,
    required this.kennelName,
  });

  final String kennelId;
  final String kennelName;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProductEditorController>(
      init: ProductEditorController(kennelId: kennelId, kennelName: kennelName),
      global: false,
      builder: (ProductEditorController c) {
        return AppScaffold(
          appBar: AppBar(
            backgroundColor: themeAppBarBackground,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text('Products', style: ts_appBarTitle),
            actions: <Widget>[
              IconButton(
                tooltip: 'Add a product',
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () => _edit(context, c, null),
              ),
            ],
          ),
          body: DecoratedBox(
            decoration: Backgrounds.defaultHcBackground(),
            child: Obx(() {
              if (c.busy.value && c.products.isEmpty) {
                return const SweepMessage(
                  text: 'Reading the catalogue…',
                  spinner: true,
                );
              }
              if (c.products.isEmpty) {
                return const SweepMessage(
                  text:
                      'No products yet.\n\nAdd a run package, a membership or '
                      'a piece of haberdashery with the + button above.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                itemCount: c.products.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (BuildContext _, int i) =>
                    _row(context, c, c.products[i]),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _row(
    BuildContext context,
    ProductEditorController c,
    KennelProduct p,
  ) {
    final double? headline = p.headlinePrice;
    final String money = headline == null
        // A mode with no single price, such as a collection offering a choice.
        // Naming the mode is honest; inventing a number is not.
        ? productPricingModeLabel(p.pricingMode)
        : p.promotionalCredit > 0
        ? '${headline.toStringAsFixed(2)}  +  '
              '${p.promotionalCredit.toStringAsFixed(2)} credit'
        : headline.toStringAsFixed(2);
    return InkWell(
      onTap: () => _edit(context, c, p),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          color: Colors.black.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    p.name,
                    style: ts_titleMedium.copyWith(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    productTypeLabel(p.productType),
                    style: ts_body.copyWith(fontSize: 13, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    money,
                    style: ts_body.copyWith(
                      fontSize: 14,
                      color: p.promotionalCredit > 0
                          ? Colors.lightBlueAccent
                          : Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (!p.isActive)
                    Text(
                      'Not on sale',
                      style: ts_body.copyWith(
                        fontSize: 13,
                        color: Colors.orangeAccent,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    ProductEditorController c,
    KennelProduct? existing,
  ) async {
    final bool? saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => _ProductForm(controller: c, existing: existing),
      ),
    );
    if (saved == true) await c.load();
  }
}

/// One product's details. A separate page rather than a dialog: there are
/// seven fields and a dialog at a large text size cannot hold them.
class _ProductForm extends StatefulWidget {
  const _ProductForm({required this.controller, this.existing});

  final ProductEditorController controller;
  final KennelProduct? existing;

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.existing?.description ?? '',
  );
  late final TextEditingController _price = TextEditingController(
    text: (widget.existing?.headlinePrice ?? 0).toStringAsFixed(2),
  );
  late final TextEditingController _promo = TextEditingController(
    text: (widget.existing?.promotionalCredit ?? 0).toStringAsFixed(2),
  );
  late final TextEditingController _cost = TextEditingController(
    text: ((widget.existing?.pricing['unitCost'] as num?)?.toDouble() ?? 0)
        .toStringAsFixed(2),
  );
  late final TextEditingController _runs = TextEditingController(
    text: widget.existing?.runsIncluded?.toString() ?? '',
  );
  late int _type = widget.existing?.productType ?? productTypeRunPackage.value;
  late bool _isActive = widget.existing?.isActive ?? true;
  bool _saving = false;

  @override
  void dispose() {
    for (final TextEditingController t in <TextEditingController>[
      _name,
      _description,
      _price,
      _promo,
      _cost,
      _runs,
    ]) {
      t.dispose();
    }
    super.dispose();
  }

  double _money(TextEditingController t) =>
      double.tryParse(t.text.trim().replaceAll(',', '.')) ?? 0;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        backgroundColor: themeAppBarBackground,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.existing == null ? 'New product' : 'Edit product',
          style: ts_appBarTitle,
        ),
      ),
      body: DecoratedBox(
        decoration: Backgrounds.defaultHcBackground(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _field(_name, 'Name', hint: '11-run package'),
              _field(_description, 'Description (optional)', lines: 2),
              const SizedBox(height: 8),
              _typePicker(),
              const SizedBox(height: 8),
              _field(_price, 'Price charged', money: true),
              _field(
                _promo,
                'Promotional credit granted',
                money: true,
                help:
                    'Credit on top of the cash. Pay 70, get 7 here, and the '
                    'hasher ends up with 77 to spend. Leave at 0 for an '
                    'ordinary sale.',
              ),
              _field(
                _cost,
                'What it costs the kennel',
                money: true,
                help:
                    'For the accounts. Zero for a run; a real figure for a '
                    'shirt.',
              ),
              if (_type == productTypeRunPackage.value)
                _field(_runs, 'How many runs', number: true),
              const SizedBox(height: 4),
              SwitchListTile(
                value: _isActive,
                onChanged: (bool v) => setState(() => _isActive = v),
                title: Text('On sale', style: ts_body.copyWith(fontSize: 16)),
                subtitle: Text(
                  // The rule, said out loud where someone might otherwise
                  // look for a delete button.
                  'Turn this off to retire a product. It is never deleted, so '
                  'payments already made against it still make sense.',
                  style: ts_body.copyWith(fontSize: 13, color: Colors.white),
                ),
                activeThumbColor: Colors.lightBlueAccent,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Save', style: ts_button),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typePicker() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text('Kind', style: ts_body.copyWith(fontSize: 14)),
      const SizedBox(height: 6),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: productTypeChoices
            .map((c) {
              final bool selected = c.type.value == _type;
              return ChoiceChip(
                label: Text(c.label),
                selected: selected,
                onSelected: (_) => setState(() => _type = c.type.value),
              );
            })
            .toList(growable: false),
      ),
    ],
  );

  Widget _field(
    TextEditingController c,
    String label, {
    String? hint,
    String? help,
    bool money = false,
    bool number = false,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          controller: c,
          maxLines: lines,
          keyboardType: money
              ? const TextInputType.numberWithOptions(decimal: true)
              : (number ? TextInputType.number : TextInputType.text),
          style: ts_body.copyWith(fontSize: 16),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            labelStyle: ts_body.copyWith(fontSize: 14),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.35),
            border: const OutlineInputBorder(),
          ),
        ),
        if (help != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              help,
              style: ts_body.copyWith(fontSize: 12, color: Colors.white),
            ),
          ),
      ],
    ),
  );

  Future<void> _save() async {
    final String name = _name.text.trim();
    if (name.isEmpty) {
      await Utilities.showAlert(
        'Name needed',
        'Give the product a name.',
        'OK',
      );
      return;
    }
    setState(() => _saving = true);
    final bool ok = await widget.controller.save(
      productId: widget.existing?.productId,
      productType: _type,
      name: name,
      description: _description.text.trim(),
      priceCharged: _money(_price),
      promotionalCredit: _money(_promo),
      unitCost: _money(_cost),
      runCount: _type == productTypeRunPackage.value
          ? int.tryParse(_runs.text.trim())
          : null,
      isActive: _isActive,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      await Utilities.showAlert(
        'Not saved',
        widget.controller.status.value.isEmpty
            ? 'That could not be saved. Please try again.'
            : widget.controller.status.value,
        'OK',
      );
    }
  }
}
