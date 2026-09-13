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
                // Show what the product ACTUALLY offers. A collection with a
                // choice of amounts has no single price, and printing one
                // would be an invention.
                if (p.headlinePrice == null)
                  _fact(
                    'Amounts',
                    <String>[
                      ...p.suggestedAmounts.map(
                        (double d) => d.toStringAsFixed(2),
                      ),
                      if (p.allowCustomAmount) 'Other',
                    ].join(' · '),
                  )
                else if (p.pricingMode == 'memberTiered')
                  _fact(
                    'Member / guest',
                    '${p.headlinePrice!.toStringAsFixed(2)} / '
                        '${(p.nonMemberPrice ?? 0).toStringAsFixed(2)}',
                  )
                else
                  _fact('Price', p.headlinePrice!.toStringAsFixed(2)),
                if (p.promotionalCredit != 0)
                  _fact('Credit', p.promotionalCredit.toStringAsFixed(2)),
                if (p.unitCost != 0)
                  _fact('Cost', p.unitCost.toStringAsFixed(2)),
                if (p.margin != null && p.unitCost != 0)
                  _fact('Margin', p.margin!.toStringAsFixed(2)),
                if (p.runsIncluded != null) _fact('Runs', '${p.runsIncluded}'),
                if (sizes.isNotEmpty) _fact('Sizes', sizes.join(', ')),
                if (p.photos.isNotEmpty) _fact('Photos', '${p.photos.length}'),
                _fact('Pricing', pricingModeFromKey(p.pricingMode).label),
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
///
/// Every field below the name and description is rendered from
/// product_schema.dart rather than written out here, so a new rule for a group
/// is one entry in that file and needs no change to this widget.
class _ProductFormState extends State<_ProductForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _sortOrder;
  late final TextEditingController _sourceJson;

  /// One controller per schema field, keyed as `<section>.<fieldKey>` so the
  /// pricing and details sections cannot collide on a shared key name.
  final Map<String, TextEditingController> _fields =
      <String, TextEditingController>{};
  final Map<String, bool> _flags = <String, bool>{};

  late PricingMode _mode;
  late bool _isActive;
  bool _saving = false;

  static const String _pricing = 'pricing';
  static const String _details = 'details';

  @override
  void initState() {
    super.initState();
    final ProductModel? p = widget.existing;
    _name = TextEditingController(text: p?.name ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _sortOrder = TextEditingController(text: '${p?.sortOrder ?? 0}');
    _sourceJson = TextEditingController(text: p?.sourceJson ?? '');
    _isActive = p?.isActive ?? true;
    _mode = p == null
        ? defaultPricingModeFor(widget.tab.productType)
        : pricingModeFromKey(p.pricingMode);
    _seed(_pricing, _pricingFields, p?.pricing ?? const <String, dynamic>{});
    _seed(_details, _detailFields, p?.details ?? const <String, dynamic>{});
  }

  List<ProductField> get _pricingFields => <ProductField>[
    ..._mode.fields,
    ...pricingCommonFields,
  ];

  List<ProductField> get _detailFields => fieldsForType(widget.tab.productType);

  /// Build a controller (or a flag) per field from whatever the product holds.
  void _seed(
    String section,
    List<ProductField> fields,
    Map<String, dynamic> from,
  ) {
    for (final ProductField f in fields) {
      final String id = '$section.${f.key}';
      final Object? v = from[f.key];
      if (f.kind == ProductFieldKind.boolean) {
        _flags.putIfAbsent(
          id,
          () => v is bool ? v : (from.containsKey(f.key) ? false : f.defaultOn),
        );
        continue;
      }
      if (_fields.containsKey(id)) continue;
      _fields[id] = TextEditingController(text: _asText(f.kind, v));
    }
  }

  String _asText(ProductFieldKind kind, Object? v) {
    if (v == null) return '';
    return switch (kind) {
      ProductFieldKind.textList => v is List ? v.join('\n') : '$v',
      ProductFieldKind.moneyList => v is List
          ? v
                .map((Object? e) => e is num ? e.toStringAsFixed(2) : '$e')
                .join('\n')
          : '$v',
      ProductFieldKind.money => v is num ? v.toStringAsFixed(2) : '$v',
      _ => '$v',
    };
  }

  @override
  void dispose() {
    for (final TextEditingController t in <TextEditingController>[
      _name,
      _description,
      _sortOrder,
      _sourceJson,
      ..._fields.values,
    ]) {
      t.dispose();
    }
    super.dispose();
  }

  /// Collect one section back into a JSON map, omitting anything left blank so
  /// the stored object holds only what was actually set.
  Map<String, dynamic> _collect(String section, List<ProductField> fields) {
    final Map<String, dynamic> out = <String, dynamic>{};
    for (final ProductField f in fields) {
      final String id = '$section.${f.key}';
      if (f.kind == ProductFieldKind.boolean) {
        if (_flags[id] ?? false) out[f.key] = true;
        continue;
      }
      final String raw = (_fields[id]?.text ?? '').trim();
      if (raw.isEmpty) continue;
      switch (f.kind) {
        case ProductFieldKind.money:
          final double? d = double.tryParse(raw.replaceAll(',', '.'));
          if (d != null) out[f.key] = d;
        case ProductFieldKind.integer:
          final int? i = int.tryParse(raw);
          if (i != null) out[f.key] = i;
        case ProductFieldKind.textList:
          final List<String> l = raw
              .split(RegExp(r'[\n,]'))
              .map((String e) => e.trim())
              .where((String e) => e.isNotEmpty)
              .toList();
          if (l.isNotEmpty) out[f.key] = l;
        case ProductFieldKind.moneyList:
          final List<double> l = raw
              .split(RegExp(r'[\n,]'))
              .map((String e) => double.tryParse(e.trim().replaceAll(',', '.')))
              .whereType<double>()
              .where((double d) => d > 0)
              .toList();
          if (l.isNotEmpty) out[f.key] = l;
        case ProductFieldKind.boolean:
          break;
        case ProductFieldKind.text:
        case ProductFieldKind.multiline:
        case ProductFieldKind.date:
          out[f.key] = raw;
      }
    }
    return out;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final Map<String, dynamic> pricing = <String, dynamic>{
      'mode': _mode.key,
      ..._collect(_pricing, _pricingFields),
    };
    final Map<String, dynamic> details = _collect(_details, _detailFields);

    final bool ok = await widget.controller.saveProduct(
      productId: widget.existing?.productId,
      // The tab decides the type, so nothing can be filed under the wrong
      // group. There is no type picker here on purpose.
      productType: widget.tab.productType,
      name: _name.text.trim(),
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      pricingJson: jsonEncode(pricing),
      productDetailsJson: details.isEmpty ? null : jsonEncode(details),
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
    final List<PricingMode> modes =
        pricingModesForType[widget.tab.productType] ??
        const <PricingMode>[PricingMode.fixed];

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

            _section('Pricing'),
            if (modes.length > 1) ...<Widget>[
              DropdownButtonFormField<PricingMode>(
                initialValue: _mode,
                decoration: const InputDecoration(
                  labelText: 'How it is priced',
                  border: OutlineInputBorder(),
                ),
                items: modes
                    .map(
                      (PricingMode m) => DropdownMenuItem<PricingMode>(
                        value: m,
                        child: Text(m.label),
                      ),
                    )
                    .toList(),
                onChanged: (PricingMode? m) {
                  if (m == null || m == _mode) return;
                  // Seed the new mode's fields before switching, so nothing
                  // already typed is lost and no controller is missing.
                  setState(() {
                    _mode = m;
                    _seed(
                      _pricing,
                      _pricingFields,
                      widget.existing?.pricing ?? const <String, dynamic>{},
                    );
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 4),
                child: Text(
                  _mode.blurb,
                  style: const TextStyle(fontSize: 12, color: _kMuted),
                ),
              ),
            ],
            ..._renderFields(_pricing, _pricingFields),

            if (_detailFields.isNotEmpty) ...<Widget>[
              _section(widget.tab.title),
              ..._renderFields(_details, _detailFields),
            ],

            _section('Admin'),
            TextFormField(
              controller: _sortOrder,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Sort order',
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
              validator: _jsonValidator,
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

  String? _jsonValidator(String? v) {
    final String t = (v ?? '').trim();
    if (t.isEmpty) return null;
    try {
      jsonDecode(t);
      return null;
    } catch (_) {
      return 'That is not valid JSON';
    }
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
    child: Row(
      children: <Widget>[
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: _kMuted,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: _kLine)),
      ],
    ),
  );

  List<Widget> _renderFields(String section, List<ProductField> fields) {
    final List<Widget> out = <Widget>[];
    for (final ProductField f in fields) {
      final String id = '$section.${f.key}';
      if (f.kind == ProductFieldKind.boolean) {
        out.add(
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _flags[id] ?? false,
            onChanged: (bool v) => setState(() => _flags[id] = v),
            title: Text(
              f.label,
              style: const TextStyle(fontSize: 14, color: _kBody),
            ),
            subtitle: f.helper == null
                ? null
                : Text(
                    f.helper!,
                    style: const TextStyle(fontSize: 12, color: _kMuted),
                  ),
          ),
        );
        continue;
      }
      final bool multi =
          f.kind == ProductFieldKind.textList ||
          f.kind == ProductFieldKind.moneyList ||
          f.kind == ProductFieldKind.multiline;
      out.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: _fields[id],
            maxLines: multi ? 3 : 1,
            keyboardType: switch (f.kind) {
              ProductFieldKind.money => const TextInputType.numberWithOptions(
                decimal: true,
              ),
              ProductFieldKind.integer => TextInputType.number,
              _ => TextInputType.text,
            },
            decoration: InputDecoration(
              labelText: f.label,
              helperText: f.helper,
              helperMaxLines: 3,
              hintText: f.kind == ProductFieldKind.date ? 'YYYY-MM-DD' : null,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
      );
    }
    return out;
  }
}
