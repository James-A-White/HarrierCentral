import 'package:hcportal/imports.dart';

// ---------------------------------------------------------------------------
// Tab Type Enum
// ---------------------------------------------------------------------------

/// One tab per product group, and one product group per HC.Product.ProductType.
///
/// [productType] is the whole point of this enum: each tab is a filtered view
/// of the same catalogue, and it is also the type stamped on anything created
/// from that tab, so a hasher cannot end up with a shirt filed under
/// memberships.
///
/// Type 1 (a single run) has no tab. A run's price lives on its event, differs
/// for members and non-members, and changes run to run, so it could never be
/// one catalogue row (James, 2026-09-13).
///
/// Every tab sets `hasCustomTabStatusFunction: true`. These tabs are LISTS, not
/// forms: there are no UiControlDefinitions to compute a status from, so the
/// base class must be told to leave their status alone. The Songs tab in Edit
/// Kennel does the same thing for the same reason.
enum KennelProductsTabType {
  memberships(
    key: 'memberships',
    productType: 2,
    title: 'Memberships',
    description: 'Annual or rolling membership of the kennel.\n\n'
        'The membership TERM is not set here. It lives on the kennel itself, '
        'in Edit Kennel, so that one club cannot offer two memberships of '
        'different lengths and leave the expiry maths ambiguous.',
    icon: MaterialCommunityIcons.card_account_details_outline,
    isTabLockable: false,
    hasCustomTabStatusFunction: true,
    showTabInSubmitSummary: false,
  ),

  runPackages(
    key: 'runPackages',
    productType: 4,
    title: 'Run Packages',
    description: 'Several runs paid for up front.\n\n'
        'Put the runs the hasher is buying in Runs included. Put anything you '
        'are giving away on top in Promotional credit — a package sold as '
        '"pay for ten, get eleven" is ten runs and one run of credit.',
    icon: MaterialCommunityIcons.ticket_confirmation_outline,
    isTabLockable: false,
    hasCustomTabStatusFunction: true,
    showTabInSubmitSummary: false,
  ),

  haberdashery(
    key: 'haberdashery',
    productType: 3,
    title: 'Haberdashery',
    description: 'Shirts, mugs, badges and patches.\n\n'
        'Sizes and photos belong on the product. Supplier details stay in the '
        'portal and are never sent to a hasher\'s phone, so the printer\'s '
        'phone number is safe to keep here.',
    icon: MaterialCommunityIcons.tshirt_crew_outline,
    isTabLockable: false,
    hasCustomTabStatusFunction: true,
    showTabInSubmitSummary: false,
  ),

  tripsAndEvents(
    key: 'tripsAndEvents',
    productType: 5,
    title: 'Trips & Events',
    description: 'Weekends away, red dress runs, anniversary dos, coach trips.'
        '\n\nAnything ticketed that is not an ordinary run. Use Unit cost for '
        'what the coach or the venue charges you, so the margin is honest.',
    icon: MaterialCommunityIcons.bus_marker,
    isTabLockable: false,
    hasCustomTabStatusFunction: true,
    showTabInSubmitSummary: false,
  ),

  barAndRefreshments(
    key: 'barAndRefreshments',
    productType: 6,
    title: 'Bar & Refreshments',
    description: 'Beer tokens, food at the on-on, prepaid bar tabs.\n\n'
        'Unit cost is what the bar charges the kennel. Price charged is what '
        'the hasher pays, which for a subsidised bar may well be less.',
    icon: MaterialCommunityIcons.beer_outline,
    isTabLockable: false,
    hasCustomTabStatusFunction: true,
    showTabInSubmitSummary: false,
  ),

  charityAndDonation(
    key: 'charityAndDonation',
    productType: 7,
    title: 'Charity & Donation',
    description: 'Collections that are passed straight on.\n\n'
        'Leave Unit cost at zero only if the kennel keeps nothing. If it '
        'retains a handling share, put the share in Unit cost so the reports '
        'do not credit the kennel with money it gave away.',
    icon: MaterialCommunityIcons.hand_heart_outline,
    isTabLockable: false,
    hasCustomTabStatusFunction: true,
    showTabInSubmitSummary: false,
  );

  const KennelProductsTabType({
    required this.key,
    required this.productType,
    required this.title,
    required this.description,
    required this.icon,
    required this.isTabLockable,
    required this.hasCustomTabStatusFunction,
    required this.showTabInSubmitSummary,
  });

  final String key;

  /// HC.Product.ProductType this tab lists and creates.
  final int productType;

  final String title;
  final String description;
  final IconData icon;
  final bool isTabLockable;
  final bool hasCustomTabStatusFunction;
  final bool showTabInSubmitSummary;

  /// The tab a product belongs in, or null for a type with no tab (today only
  /// type 1, a single run, which is never a catalogue entry).
  static KennelProductsTabType? forProductType(int type) {
    for (final KennelProductsTabType t in KennelProductsTabType.values) {
      if (t.productType == type) return t;
    }
    return null;
  }
}
