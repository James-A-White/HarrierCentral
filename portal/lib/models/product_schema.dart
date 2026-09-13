/// The shape of ProductDetailsJson, one schema per product group.
///
/// This file is the single definition of what a product's rules look like.
/// The editor renders its fields from here, the tile summarises from here, and
/// the phone will read the same keys. Adding a rule to a group is one entry in
/// [productSchema] — no new column, no new form code, no migration.
///
/// ## The contract
///
/// Every group's JSON has the SAME shape as itself, and groups differ freely
/// from each other (James, 2026-09-13). Concretely:
///
///   Haberdashery  {"photos":[…],"sizes":["S","M"],"colours":[…],"fabric":"…"}
///   Charity       {"photos":[…],"amounts":[5,10,20],"allowOther":true,…}
///   Trips         {"photos":[…],"startDate":"2026-11-14","capacity":40,…}
///
/// [commonFields] appear in every group. Anything else is the group's own.
///
/// ## What is NOT in here, and why
///
/// Money the server adds up — PriceCharged, PromotionalCredit, UnitCost — stays
/// in typed columns. So do KennelId, ProductType, IsActive and SortOrder. The
/// line is the same one drawn when ProductDetailsJson was introduced: **if the
/// server computes with it, it is a column.** A SUM over JSON cannot use an
/// index, cannot hold DECIMAL precision, and turns the accounting reports into
/// string parsing. RunCount stays a column for the same reason — the
/// promotional-credit rule divides by it.
enum ProductFieldKind { text, multiline, money, integer, boolean, date, textList, moneyList }

class ProductField {
  const ProductField({
    required this.key,
    required this.label,
    required this.kind,
    this.helper,
    this.defaultOn = false,
  });

  final String key;
  final String label;
  final ProductFieldKind kind;
  final String? helper;

  /// Booleans that start true on a NEW product.
  final bool defaultOn;
}

/// Present in every group, so a shop screen can rely on them existing.
const List<ProductField> commonFields = <ProductField>[
  ProductField(
    key: 'photos',
    label: 'Photos',
    kind: ProductFieldKind.textList,
    helper: 'One URL per line. Stored as a JSON array, so a comma or a pipe in '
        'a URL is no longer a problem.',
  ),
];

/// Group-specific rules, keyed by ProductType.
const Map<int, List<ProductField>> productSchema = <int, List<ProductField>>{
  // Memberships. The term is deliberately absent: it lives on HC.Kennel
  // (MembershipRenewalMode + MembershipDurationInMonths) and duplicating it
  // here would let a product claim twelve months on a kennel configured for a
  // shared anniversary.
  2: <ProductField>[],

  // Run packages. RunCount is a column, not a field here.
  4: <ProductField>[
    ProductField(
      key: 'expiryMonths',
      label: 'Expires after (months)',
      kind: ProductFieldKind.integer,
      helper: 'Leave blank for a package that never expires.',
    ),
    ProductField(
      key: 'transferable',
      label: 'Can be given to another hasher',
      kind: ProductFieldKind.boolean,
    ),
  ],

  // Haberdashery.
  3: <ProductField>[
    ProductField(
      key: 'sizes',
      label: 'Sizes',
      kind: ProductFieldKind.textList,
      helper: 'One per line, for example S, M, L, XL, XXL.',
    ),
    ProductField(
      key: 'colours',
      label: 'Colours',
      kind: ProductFieldKind.textList,
      helper: 'One per line. Leave blank if it comes one way only.',
    ),
    ProductField(
      key: 'fabric',
      label: 'Fabric / material',
      kind: ProductFieldKind.text,
    ),
  ],

  // Trips and events.
  5: <ProductField>[
    ProductField(key: 'startDate', label: 'Starts', kind: ProductFieldKind.date),
    ProductField(key: 'endDate', label: 'Ends', kind: ProductFieldKind.date),
    ProductField(key: 'venue', label: 'Venue', kind: ProductFieldKind.text),
    ProductField(
      key: 'capacity',
      label: 'Places available',
      kind: ProductFieldKind.integer,
      helper: 'Not enforced yet — it is shown, not counted down.',
    ),
    ProductField(
      key: 'depositAmount',
      label: 'Deposit',
      kind: ProductFieldKind.money,
      helper: 'What secures a place. The rest is due later.',
    ),
    ProductField(
      key: 'includes',
      label: 'What is included',
      kind: ProductFieldKind.textList,
      helper: 'One per line, for example Coach, Two nights, Saturday dinner.',
    ),
  ],

  // Bar and refreshments.
  6: <ProductField>[
    ProductField(
      key: 'amounts',
      label: 'Set amounts',
      kind: ProductFieldKind.moneyList,
      helper: 'One per line. Leave blank to use the price above only.',
    ),
    ProductField(
      key: 'allowOther',
      label: 'Allow "Other" (any amount)',
      kind: ProductFieldKind.boolean,
    ),
    ProductField(
      key: 'tokenCount',
      label: 'Tokens per purchase',
      kind: ProductFieldKind.integer,
    ),
  ],

  // Charity and donation.
  7: <ProductField>[
    ProductField(
      key: 'amounts',
      label: 'Suggested amounts',
      kind: ProductFieldKind.moneyList,
      helper: 'One per line, for example 5, 10, 20.',
    ),
    ProductField(
      key: 'allowOther',
      label: 'Allow "Other" (donor picks the amount)',
      kind: ProductFieldKind.boolean,
      // A collection asking for one fixed sum is the unusual case.
      defaultOn: true,
    ),
    ProductField(
      key: 'beneficiary',
      label: 'Who it goes to',
      kind: ProductFieldKind.text,
    ),
    ProductField(
      key: 'charityNumber',
      label: 'Registered charity number',
      kind: ProductFieldKind.text,
    ),
  ],
};

/// Every field an editor should show for [productType]: the common ones, then
/// the group's own.
List<ProductField> fieldsForType(int productType) => <ProductField>[
  ...commonFields,
  ...(productSchema[productType] ?? const <ProductField>[]),
];

// ---------------------------------------------------------------------------
// Pricing
// ---------------------------------------------------------------------------

/// The shape of PricingJson: how a product arrives at a price.
///
/// ## Why pricing is JSON and not columns (James, 2026-09-13)
///
/// A single PriceCharged column can only express one pricing model, and the
/// real ones are not one model. A shirt may cost more in XXL. A run costs one
/// thing for members and another for guests — which is not hypothetical, eight
/// kennels are doing it in live data. A collection has no price at all, just
/// amounts to choose between. A trip takes a deposit now and the balance later.
///
/// The objection to money-in-JSON is that you cannot SUM it. That objection is
/// wrong HERE, and it is worth being precise about why: **nothing sums the
/// catalogue.** The accounting sums PAYMENTS, and HC.Payment keeps its typed
/// CreditAmount / DebitAmount / PromotionalCredit / PromotionalDebit columns,
/// indexed and DECIMAL, exactly as it does today. The product only has to
/// describe how to reach a number; the payment records the number actually
/// taken. Those are different jobs and only the second one is arithmetic.
///
/// It also means the price a hasher paid in 2024 is preserved on their payment
/// even after the kennel reprices the product, which a join to a live catalogue
/// row could never guarantee.
///
/// ## The modes
///
///   fixed         {"mode":"fixed","price":20}
///   memberTiered  {"mode":"memberTiered","memberPrice":20,"nonMemberPrice":25}
///   choice        {"mode":"choice","amounts":[5,10,20],"allowOther":true}
///   perVariant    {"mode":"perVariant","variantKey":"sizes",
///                  "prices":{"S":20,"XXL":24},"default":20}
///   deposit       {"mode":"deposit","total":150,"deposit":25}
///
/// Any mode may also carry, all optional:
///
///   "unitCost":12          what it costs the kennel to supply
///   "promotionalCredit":7  credit granted on top of the cash
///   "runsIncluded":11      runs a package is worth
///
/// perVariant is what makes per-size pricing possible without a row per size —
/// the trade-off called out when sizes were first put in a list.
enum PricingMode { fixed, memberTiered, choice, perVariant, deposit }

extension PricingModeX on PricingMode {
  String get key => switch (this) {
    PricingMode.fixed => 'fixed',
    PricingMode.memberTiered => 'memberTiered',
    PricingMode.choice => 'choice',
    PricingMode.perVariant => 'perVariant',
    PricingMode.deposit => 'deposit',
  };

  String get label => switch (this) {
    PricingMode.fixed => 'One price',
    PricingMode.memberTiered => 'Member and non-member price',
    PricingMode.choice => 'Choice of amounts',
    PricingMode.perVariant => 'Price per size or variant',
    PricingMode.deposit => 'Deposit then balance',
  };

  String get blurb => switch (this) {
    PricingMode.fixed => 'Everyone pays the same.',
    PricingMode.memberTiered =>
      'Members pay less. Which price applies is decided at the till, from the '
          'hasher\'s membership on the day.',
    PricingMode.choice =>
      'The hasher picks from a list, and may type their own if Other is on.',
    PricingMode.perVariant =>
      'Each size or variant has its own price. Anything not listed falls back '
          'to the default.',
    PricingMode.deposit =>
      'A deposit secures a place and the balance is owed later.',
  };

  /// Which pricing fields this mode asks for.
  List<ProductField> get fields => switch (this) {
    PricingMode.fixed => const <ProductField>[
      ProductField(key: 'price', label: 'Price', kind: ProductFieldKind.money),
    ],
    PricingMode.memberTiered => const <ProductField>[
      ProductField(
        key: 'memberPrice',
        label: 'Member price',
        kind: ProductFieldKind.money,
      ),
      ProductField(
        key: 'nonMemberPrice',
        label: 'Non-member price',
        kind: ProductFieldKind.money,
      ),
    ],
    PricingMode.choice => const <ProductField>[
      ProductField(
        key: 'amounts',
        label: 'Amounts offered',
        kind: ProductFieldKind.moneyList,
        helper: 'One per line.',
      ),
      ProductField(
        key: 'allowOther',
        label: 'Allow "Other" (any amount)',
        kind: ProductFieldKind.boolean,
      ),
    ],
    PricingMode.perVariant => const <ProductField>[
      ProductField(
        key: 'default',
        label: 'Default price',
        kind: ProductFieldKind.money,
        helper: 'Used for any variant with no price of its own.',
      ),
    ],
    PricingMode.deposit => const <ProductField>[
      ProductField(
        key: 'total',
        label: 'Total price',
        kind: ProductFieldKind.money,
      ),
      ProductField(
        key: 'deposit',
        label: 'Deposit',
        kind: ProductFieldKind.money,
        helper: 'What secures a place now.',
      ),
    ],
  };
}

/// Offered on every mode.
const List<ProductField> pricingCommonFields = <ProductField>[
  ProductField(
    key: 'unitCost',
    label: 'Unit cost',
    kind: ProductFieldKind.money,
    helper: 'What it costs the kennel to supply. Drives the margin.',
  ),
  ProductField(
    key: 'promotionalCredit',
    label: 'Promotional credit',
    kind: ProductFieldKind.money,
    helper: 'Credit granted on top of the cash. A package sold as "pay for '
        'ten, get eleven" puts one run of credit here.',
  ),
  ProductField(
    key: 'runsIncluded',
    label: 'Runs included',
    kind: ProductFieldKind.integer,
    helper: 'Run packages only. How many runs the package is worth.',
  ),
];

/// The pricing modes that make sense for each product group. The first is the
/// default for a new product in that group.
const Map<int, List<PricingMode>> pricingModesForType =
    <int, List<PricingMode>>{
  2: <PricingMode>[PricingMode.fixed], // membership
  4: <PricingMode>[PricingMode.fixed], // run package
  3: <PricingMode>[
    PricingMode.fixed,
    PricingMode.perVariant,
    PricingMode.memberTiered,
  ], // haberdashery
  5: <PricingMode>[
    PricingMode.fixed,
    PricingMode.deposit,
    PricingMode.memberTiered,
  ], // trips
  6: <PricingMode>[PricingMode.choice, PricingMode.fixed], // bar
  7: <PricingMode>[PricingMode.choice, PricingMode.fixed], // charity
};

PricingMode defaultPricingModeFor(int productType) =>
    (pricingModesForType[productType] ?? const <PricingMode>[PricingMode.fixed])
        .first;

PricingMode pricingModeFromKey(String? key) => PricingMode.values.firstWhere(
  (PricingMode m) => m.key == key,
  orElse: () => PricingMode.fixed,
);
