import 'package:hcportal/imports.dart';

const Color _kPageBg = Color(0xFFF1F5F9);
const Color _kBody = Color(0xFF1F2937);
const Color _kMuted = Color(0xFF6B7280);
const Color _kAccent = Color(0xFF1E40AF);
const Color _kDanger = Color(0xFFDC2626);

/// The kennel's product catalogue: run packages, memberships, haberdashery.
///
/// Nothing here deletes. Retiring a product is "Take off sale", because the
/// mobile sync deletes removed rows from every phone, which would orphan the
/// payments made against it.
class ProductsPage extends StatelessWidget {
  const ProductsPage({
    required this.publicKennelId,
    required this.kennelName,
    super.key,
  });

  final String publicKennelId;
  final String kennelName;

  void _ensureController() {
    if (!Get.isRegistered<ProductController>()) {
      Get.put(ProductController(publicKennelId, kennelName));
    }
  }

  @override
  Widget build(BuildContext context) {
    _ensureController();
    final ProductController c = Get.find<ProductController>();

    return Scaffold(
      backgroundColor: _kPageBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back<void>(),
        ),
        title: Text(
          'Products — $kennelName',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: HcButton.primary(
              label: 'Add product',
              icon: Icons.add,
              onPressed: () => _openForm(context, c, null),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (c.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _filterBar(c),
            Expanded(
              child: c.products.isEmpty
                  ? _empty(context, c)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: c.products.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (BuildContext ctx, int i) =>
                          _tile(ctx, c, c.products[i]),
                    ),
            ),
          ],
        );
      }),
    );
  }

  Widget _filterBar(ProductController c) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Row(
      children: <Widget>[
        Switch(
          value: c.activeOnly.value,
          onChanged: (bool v) => unawaited(c.toggleActiveOnly(v)),
        ),
        const SizedBox(width: 8),
        const Text(
          'Only show what is on sale',
          style: TextStyle(fontSize: 14, color: _kBody),
        ),
        const Spacer(),
        Text(
          '${c.products.length} product${c.products.length == 1 ? '' : 's'}',
          style: const TextStyle(fontSize: 13, color: _kMuted),
        ),
      ],
    ),
  );

  Widget _empty(BuildContext context, ProductController c) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(Icons.inventory_2_outlined, size: 48, color: _kMuted),
        const SizedBox(height: 12),
        const Text(
          'Nothing in the catalogue yet.',
          style: TextStyle(fontSize: 16, color: _kBody),
        ),
        const SizedBox(height: 4),
        const Text(
          'Add a run package, a membership or a piece of haberdashery.',
          style: TextStyle(fontSize: 13, color: _kMuted),
        ),
        const SizedBox(height: 16),
        HcButton.primary(
          label: 'Add product',
          icon: Icons.add,
          onPressed: () => _openForm(context, c, null),
        ),
      ],
    ),
  );

  Widget _tile(BuildContext context, ProductController c, ProductModel p) {
    final List<String> sizes = p.sizes;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: p.isActive ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1),
        ),
      ),
      color: p.isActive ? Colors.white : const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              p.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: p.isActive ? _kBody : _kMuted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _chip(productTypeLabel(p.productType), _kAccent),
                          if (!p.isActive) ...<Widget>[
                            const SizedBox(width: 6),
                            _chip('Off sale', _kMuted),
                          ],
                        ],
                      ),
                      if ((p.description ?? '').trim().isNotEmpty) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          p.description!,
                          style: const TextStyle(fontSize: 13, color: _kMuted),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 20,
              runSpacing: 6,
              children: <Widget>[
                _fact('Price', p.priceCharged.toStringAsFixed(2)),
                if (p.promotionalCredit != 0)
                  _fact('Credit', p.promotionalCredit.toStringAsFixed(2)),
                _fact('Cost', p.unitCost.toStringAsFixed(2)),
                _fact('Margin', p.margin.toStringAsFixed(2)),
                if (p.runCount != null) _fact('Runs', '${p.runCount}'),
                if (sizes.isNotEmpty) _fact('Sizes', sizes.join(', ')),
                _fact('Sold', '${p.unitsSold}'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                HcButton.text(
                  label: 'Edit',
                  onPressed: () => _openForm(context, c, p),
                ),
                const SizedBox(width: 8),
                if (p.isActive)
                  HcButton.secondary(
                    label: 'Take off sale',
                    onPressed: () => unawaited(_confirmOffSale(c, p)),
                  )
                else
                  HcButton.secondary(
                    label: 'Put on sale',
                    onPressed: () => unawaited(c.setOnSale(p, true)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color colour) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: colour.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colour),
    ),
  );

  Widget _fact(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(label, style: const TextStyle(fontSize: 11, color: _kMuted)),
      Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _kBody,
        ),
      ),
    ],
  );

  Future<void> _confirmOffSale(ProductController c, ProductModel p) async {
    final bool? ok = await Get.defaultDialog<bool>(
      title: 'Take off sale',
      titleStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          p.hasBeenSold
              ? '${p.name} has sold ${p.unitsSold} '
                    '${p.unitsSold == 1 ? 'unit' : 'units'}. Taking it off sale '
                    'hides it from the shop but keeps it on record, so those '
                    'payments still resolve. It is never deleted.'
              : '${p.name} will no longer be offered. You can put it back on '
                    'sale at any time.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: _kBody),
        ),
      ),
      actions: <Widget>[
        HcButton.secondary(
          label: 'Cancel',
          onPressed: () => Get.back<bool>(result: false),
        ),
        HcButton.destructive(
          label: 'Take off sale',
          onPressed: () => Get.back<bool>(result: true),
        ),
      ],
    );
    if (ok ?? false) await c.setOnSale(p, false);
  }

  void _openForm(
    BuildContext context,
    ProductController c,
    ProductModel? existing,
  ) {
    unawaited(
      Get.dialog<void>(
        Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _ProductForm(controller: c, existing: existing),
          ),
        ),
      ),
    );
  }
}

class _ProductForm extends StatefulWidget {
  const _ProductForm({required this.controller, this.existing});

  final ProductController controller;
  final ProductModel? existing;

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

/// A self-contained dialog form: TextEditingControllers and a FormState key,
/// no business logic. This is the one StatefulWidget shape the project allows.
class _ProductFormState extends State<_ProductForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _credit;
  late final TextEditingController _cost;
  late final TextEditingController _runCount;
  late final TextEditingController _sizes;
  late final TextEditingController _photoUrls;
  late final TextEditingController _sourceJson;
  late final TextEditingController _sortOrder;

  late int _type;
  late bool _isActive;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final ProductModel? p = widget.existing;
    _name = TextEditingController(text: p?.name ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(
      text: p == null ? '' : p.priceCharged.toStringAsFixed(2),
    );
    _credit = TextEditingController(
      text: p == null ? '' : p.promotionalCredit.toStringAsFixed(2),
    );
    _cost = TextEditingController(
      text: p == null ? '' : p.unitCost.toStringAsFixed(2),
    );
    _runCount = TextEditingController(text: p?.runCount?.toString() ?? '');
    _sizes = TextEditingController(text: (p?.sizes ?? <String>[]).join(', '));
    _photoUrls = TextEditingController(text: p?.photoUrls ?? '');
    _sourceJson = TextEditingController(text: p?.sourceJson ?? '');
    _sortOrder = TextEditingController(text: '${p?.sortOrder ?? 0}');
    _type = p?.productType ?? 4;
    _isActive = p?.isActive ?? true;
  }

  @override
  void dispose() {
    for (final TextEditingController t in <TextEditingController>[
      _name,
      _description,
      _price,
      _credit,
      _cost,
      _runCount,
      _sizes,
      _photoUrls,
      _sourceJson,
      _sortOrder,
    ]) {
      t.dispose();
    }
    super.dispose();
  }

  double _money(TextEditingController t) =>
      double.tryParse(t.text.trim().replaceAll(',', '.')) ?? 0;

  /// Sizes are typed comma separated because that is how a person writes them.
  /// They are STORED as a JSON array, so the comma never has to survive a
  /// round trip. The pipe rule applies to PhotoUrls, which is a delimited
  /// string, not to this.
  String? _detailsJson() {
    final List<String> sizes = _sizes.text
        .split(',')
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toList();
    if (sizes.isEmpty) return null;
    return jsonEncode(<String, dynamic>{'sizes': sizes});
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final bool ok = await widget.controller.save(
      productId: widget.existing?.productId,
      productType: _type,
      name: _name.text.trim(),
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      priceCharged: _money(_price),
      promotionalCredit: _money(_credit),
      unitCost: _money(_cost),
      runCount: int.tryParse(_runCount.text.trim()),
      productDetailsJson: _detailsJson(),
      photoUrls: _photoUrls.text.trim().isEmpty ? null : _photoUrls.text.trim(),
      sourceJson: _sourceJson.text.trim().isEmpty
          ? null
          : _sourceJson.text.trim(),
      isActive: _isActive,
      sortOrder: int.tryParse(_sortOrder.text.trim()) ?? 0,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Get.back<void>();
  }

  @override
  Widget build(BuildContext context) {
    final bool isHaberdashery = _type == 3;
    final bool isRunPackage = _type == 4;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.existing == null ? 'Add product' : 'Edit product',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _kBody,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Type *',
                border: OutlineInputBorder(),
              ),
              items: productTypeLabels.entries
                  .map(
                    (MapEntry<int, String> e) =>
                        DropdownMenuItem<int>(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: (int? v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Name *',
                border: OutlineInputBorder(),
              ),
              validator: (String? v) =>
                  (v ?? '').trim().isEmpty ? 'Give the product a name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(child: _moneyField(_price, 'Price charged *')),
                const SizedBox(width: 10),
                Expanded(child: _moneyField(_credit, 'Promotional credit')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(child: _moneyField(_cost, 'Unit cost')),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _sortOrder,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Sort order',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            if (isRunPackage) ...<Widget>[
              const SizedBox(height: 12),
              TextFormField(
                controller: _runCount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Runs included',
                  helperText: 'How many runs this package is worth',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            if (isHaberdashery) ...<Widget>[
              const SizedBox(height: 12),
              TextFormField(
                controller: _sizes,
                decoration: const InputDecoration(
                  labelText: 'Sizes',
                  helperText: 'Comma separated, for example S, M, L, XL, XXL',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _photoUrls,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Photo URLs',
                helperText: 'Separate several with a pipe: a.jpg|b.jpg',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sourceJson,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Supplier (JSON)',
                helperText:
                    'Kennel admin only, never shown in the app. '
                    '{"supplier":"…","phone":"…"}',
                border: OutlineInputBorder(),
              ),
              validator: (String? v) {
                final String t = (v ?? '').trim();
                if (t.isEmpty) return null;
                try {
                  jsonDecode(t);
                  return null;
                } catch (_) {
                  return 'That is not valid JSON';
                }
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isActive,
              onChanged: (bool v) => setState(() => _isActive = v),
              title: const Text(
                'On sale',
                style: TextStyle(fontSize: 14, color: _kBody),
              ),
              subtitle: const Text(
                'Turn this off to retire it. Products are never deleted, so '
                'past payments still resolve.',
                style: TextStyle(fontSize: 12, color: _kMuted),
              ),
            ),
            if ((widget.existing?.hasBeenSold ?? false)) ...<Widget>[
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  const Icon(Icons.info_outline, size: 16, color: _kDanger),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'This has sold ${widget.existing!.unitsSold} '
                      '${widget.existing!.unitsSold == 1 ? 'unit' : 'units'}. '
                      'Changing the price does not change what was already '
                      'paid.',
                      style: const TextStyle(fontSize: 12, color: _kDanger),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                HcButton.secondary(
                  label: 'Cancel',
                  onPressed: _saving ? null : () => Get.back<void>(),
                ),
                const SizedBox(width: 10),
                HcButton.primary(
                  label: 'Save',
                  loading: _saving,
                  onPressed: _saving ? null : () => unawaited(_submit()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _moneyField(TextEditingController c, String label) => TextFormField(
    controller: c,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
  );
}
