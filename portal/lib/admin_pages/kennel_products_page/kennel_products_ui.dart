import 'package:hcportal/imports.dart';

import 'kennel_products_controller.dart';
import 'kennel_products_enums.dart';

const Color _kBody = Color(0xFF1F2937);
const Color _kMuted = Color(0xFF6B7280);
const Color _kAccent = Color(0xFF1E40AF);
const Color _kDanger = Color(0xFFDC2626);
const Color _kLine = Color(0xFFE2E8F0);

// ---------------------------------------------------------------------------
// Entry widget
// ---------------------------------------------------------------------------

/// Kennel Products: the catalogue, one tab per product group.
///
/// Sits alongside Edit Kennel and Edit Website as its own tab group. There are
/// no `part` files for the tabs, unlike those two, because every group renders
/// identically and differs only by which ProductType it lists. Twelve
/// near-identical files would be twelve places to fix one bug.
class KennelProductsEditPage extends GetView<KennelProductsController> {
  const KennelProductsEditPage({
    required this.publicKennelId,
    required this.kennelName,
    super.key,
  });

  final String publicKennelId;
  final String kennelName;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<KennelProductsController>()) {
      Get.put(
        KennelProductsController(
          publicKennelId: publicKennelId,
          kennelName: kennelName,
        ),
        permanent: true,
      );
    }
    return GetBuilder<KennelProductsController>(
      id: 'productsPageBuilder',
      builder: (_) => _ProductsScaffold(controller: controller),
    );
  }
}

// ---------------------------------------------------------------------------
// Scaffold
// ---------------------------------------------------------------------------

class _ProductsScaffold extends StatelessWidget {
  const _ProductsScaffold({required this.controller});

  final KennelProductsController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          controller.updateSizeWithDebounce(
            constraints.maxWidth,
            constraints.maxHeight,
          );
          return Scaffold(appBar: _buildAppBar(), body: _buildBody());
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: GestureDetector(
        onTap: () => Get.back<void>(),
        child: const Icon(
          MaterialCommunityIcons.arrow_left,
          color: Colors.black,
        ),
      ),
      title: Text(
        'Products — ${controller.kennelName}',
        style: headingStyleBlack,
      ),
      actions: <Widget>[
        Obx(
          () => Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: <Widget>[
                Switch(
                  value: controller.activeOnly.value,
                  onChanged: (bool v) =>
                      unawaited(controller.toggleActiveOnly(v)),
                ),
                const SizedBox(width: 6),
                const Text(
                  'On sale only',
                  style: TextStyle(fontSize: 13, color: _kBody),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return DefaultTabController(
      length: KennelProductsTabType.values.length,
      child: TabRailScaffold(
        controller: controller,
        railColor: railColorKennelProducts,
        narrowTabBar: ResponsiveTabBar<KennelProductsController>(
          controller: controller,
          formKey: GlobalKey<FormState>(debugLabel: 'productsNavKey'),
          tabBarColor: railColorKennelProducts,
        ),
        tabBarView: TabBarView(
          controller: controller.tabController,
          children: _buildTabBodies(),
        ),
      ),
    );
  }

  List<Widget> _buildTabBodies() {
    return KennelProductsTabType.values.map((KennelProductsTabType tab) {
      return TabPageStandardLayout(
        title: tab.title,
        icon: tab.icon,
        description: tab.description,
        formController: controller,
        showCloseTabGroupButton: true,
        tabLocked: controller.tabLocked[tab.index],
        handlesOwnScrolling: true,
        child: _ProductGroupTab(controller: controller, tab: tab),
      );
    }).toList();
  }
}

// ---------------------------------------------------------------------------
// One product group
// ---------------------------------------------------------------------------

class _ProductGroupTab extends StatelessWidget {
  const _ProductGroupTab({required this.controller, required this.tab});

  final KennelProductsController controller;
  final KennelProductsTabType tab;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final List<ProductModel> items = controller.productsFor(tab);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
            child: Row(
              children: <Widget>[
                Text(
                  items.isEmpty
                      ? 'Nothing here yet'
                      : '${items.length} '
                            '${items.length == 1 ? 'product' : 'products'}',
                  style: const TextStyle(fontSize: 13, color: _kMuted),
                ),
                const Spacer(),
                HcButton.primary(
                  label: 'Add ${tab.title.toLowerCase()}',
                  icon: Icons.add,
                  onPressed: () => _openForm(context, null),
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            _empty()
          else
            ...items.map((ProductModel p) => _tile(context, p)),
        ],
      );
    });
  }

  Widget _empty() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Column(
      children: <Widget>[
        Icon(tab.icon, size: 42, color: _kMuted),
        const SizedBox(height: 12),
        Text(
          'No ${tab.title.toLowerCase()} in the catalogue.',
          style: const TextStyle(fontSize: 15, color: _kBody),
        ),
        const SizedBox(height: 4),
        const Text(
          'Add one and it reaches every phone on the next sync.',
          style: TextStyle(fontSize: 13, color: _kMuted),
        ),
      ],
    ),
  );

  Widget _tile(BuildContext context, ProductModel p) {
    final List<String> sizes = p.sizes;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _kLine),
      ),
      color: p.isActive ? Colors.white : const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                if (!p.isActive) ...<Widget>[
                  const SizedBox(width: 8),
                  _chip('Off sale', _kMuted),
                ],
                if (p.hasBeenSold) ...<Widget>[
                  const SizedBox(width: 6),
                  _chip('${p.unitsSold} sold', _kAccent),
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
            const SizedBox(height: 10),
            Wrap(
              spacing: 22,
              runSpacing: 6,
              children: <Widget>[
                // A variable-amount product has no single price, so showing
                // one would be a lie. Show what it actually offers.
                if (p.hasVariableAmount)
                  _fact(
                    'Amounts',
                    <String>[
                      ...p.suggestedAmounts.map(
                        (double d) => d.toStringAsFixed(2),
                      ),
                      if (p.allowCustomAmount) 'Other',
                    ].join(' · '),
                  )
                else
                  _fact('Price', p.priceCharged.toStringAsFixed(2)),
                if (p.promotionalCredit != 0)
                  _fact('Credit', p.promotionalCredit.toStringAsFixed(2)),
                _fact('Cost', p.unitCost.toStringAsFixed(2)),
                _fact('Margin', p.margin.toStringAsFixed(2)),
                if (p.runCount != null) _fact('Runs', '${p.runCount}'),
                if (sizes.isNotEmpty) _fact('Sizes', sizes.join(', ')),
                if (p.photoUrlList.isNotEmpty)
                  _fact('Photos', '${p.photoUrlList.length}'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                HcButton.text(
                  label: 'Edit',
                  onPressed: () => _openForm(context, p),
                ),
                const SizedBox(width: 8),
                if (p.isActive)
                  HcButton.secondary(
                    label: 'Take off sale',
                    onPressed: () => unawaited(_confirmOffSale(p)),
                  )
                else
                  HcButton.secondary(
                    label: 'Put on sale',
                    onPressed: () => unawaited(controller.setOnSale(p, true)),
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

  Future<void> _confirmOffSale(ProductModel p) async {
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
    if (ok ?? false) await controller.setOnSale(p, false);
  }

  void _openForm(BuildContext context, ProductModel? existing) {
    unawaited(
      Get.dialog<void>(
        Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _ProductForm(
              controller: controller,
              tab: tab,
              existing: existing,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add / edit dialog
// ---------------------------------------------------------------------------

class _ProductForm extends StatefulWidget {
  const _ProductForm({
    required this.controller,
    required this.tab,
    this.existing,
  });

  final KennelProductsController controller;
  final KennelProductsTabType tab;
  final ProductModel? existing;

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

/// A self-contained dialog form: text controllers and a form key, no business
/// logic. This is the one StatefulWidget shape the project allows.
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
  late final TextEditingController _amounts;

  late bool _isActive;
  late bool _allowOther;
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
    _amounts = TextEditingController(
      text: (p?.suggestedAmounts ?? <double>[])
          .map((double d) => d.toStringAsFixed(2))
          .join(', '),
    );
    _isActive = p?.isActive ?? true;
    // Default ON for a collection: asking for a fixed donation is the unusual
    // case, so a new charity product lets people choose unless told otherwise.
    _allowOther =
        p?.allowCustomAmount ??
        (widget.tab == KennelProductsTabType.charityAndDonation);
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
      _amounts,
    ]) {
      t.dispose();
    }
    super.dispose();
  }

  double _money(TextEditingController t) =>
      double.tryParse(t.text.trim().replaceAll(',', '.')) ?? 0;

  /// Sizes are typed comma separated because that is how a person writes them,
  /// and STORED as a JSON array, so the comma never has to survive a round
  /// trip. The pipe rule applies to PhotoUrls, which is a delimited string.
  String? _detailsJson() {
    final Map<String, dynamic> out = <String, dynamic>{};

    final List<String> sizes = _sizes.text
        .split(',')
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toList();
    if (sizes.isNotEmpty) out['sizes'] = sizes;

    final List<double> amounts = _amounts.text
        .split(',')
        .map((String s) => double.tryParse(s.trim().replaceAll(',', '.')))
        .whereType<double>()
        .where((double d) => d > 0)
        .toList();
    if (amounts.isNotEmpty) out['amounts'] = amounts;
    if (_allowOther) out['allowOther'] = true;

    return out.isEmpty ? null : jsonEncode(out);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final bool ok = await widget.controller.saveProduct(
      productId: widget.existing?.productId,
      // The tab decides the type, so nothing can be filed under the wrong
      // group. There is no type picker here on purpose.
      productType: widget.tab.productType,
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
    final bool isHaberdashery =
        widget.tab == KennelProductsTabType.haberdashery;
    final bool isRunPackage = widget.tab == KennelProductsTabType.runPackages;
    // A collection has no single price: the hasher picks from suggested
    // amounts or types their own, and the amount lands on the payment.
    final bool isCollection =
        widget.tab == KennelProductsTabType.charityAndDonation;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(widget.tab.icon, size: 20, color: _kAccent),
                const SizedBox(width: 8),
                Text(
                  widget.existing == null
                      ? 'Add to ${widget.tab.title}'
                      : 'Edit ${widget.tab.title.toLowerCase()}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _kBody,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                Expanded(
                  child: _moneyField(
                    _price,
                    isCollection ? 'Default amount' : 'Price charged *',
                  ),
                ),
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
            if (isCollection) ...<Widget>[
              const SizedBox(height: 12),
              TextFormField(
                controller: _amounts,
                decoration: const InputDecoration(
                  labelText: 'Suggested amounts',
                  helperText:
                      'Comma separated, for example 5, 10, 20. Leave blank to '
                      'offer no set amounts.',
                  border: OutlineInputBorder(),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _allowOther,
                onChanged: (bool v) => setState(() => _allowOther = v),
                title: const Text(
                  'Allow "Other"',
                  style: TextStyle(fontSize: 14, color: _kBody),
                ),
                subtitle: const Text(
                  'Let the hasher type their own amount. With this off and no '
                  'suggested amounts, the price above is the only option.',
                  style: TextStyle(fontSize: 12, color: _kMuted),
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
                helperText: 'Portal only, never sent to a phone. '
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
            if (widget.existing?.hasBeenSold ?? false) ...<Widget>[
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
