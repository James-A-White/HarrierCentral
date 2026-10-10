import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:http/http.dart' as http;
import 'package:hcportal/imports.dart';
import 'package:hcportal/models/new_hasher/new_hasher_model.dart';

enum EKennelGridOptions {
  allFields,
  membership,
  nonAppHashers,
  runCounts,
  notificationAndEmail,
  photos,
  hashCredit,
  addNewMembers,
}

class KennelHashersController extends TabUiController
    with GetSingleTickerProviderStateMixin {
  KennelHashersController(this.kennel);

  final HasherKennelsModel kennel;

  /// Form key for the narrow hamburger tab bar (ResponsiveTabBar requires one).
  final GlobalKey<FormState> hashersFormKey = GlobalKey<FormState>();

  /// The grid views shown as tabs, in display order (gated by permission).
  late final List<EKennelGridOptions> visibleViews;

  /// Search (by hash name or real name). [displayedHashers] is the filtered
  /// subset actually shown — used by the grid rows, the phone cards, and
  /// onGridChanged's row indexing so they all stay in sync.
  final TextEditingController searchController = TextEditingController();
  String searchTerm = '';
  Timer? _searchDebounce;
  final List<KennelHashersModel> displayedHashers = <KennelHashersModel>[];

  /// Cache of the full member set. The SP returns everyone regardless of view,
  /// so we fetch once and filter locally per tab instead of re-hitting the SP
  /// on every view switch. Invalidated after edits / bulk add.
  final List<KennelHashersModel> _allFetched = <KennelHashersModel>[];
  bool _hashersFresh = false;

  bool _matchesSearch(KennelHashersModel h) {
    final q = searchTerm.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      h.hashName,
      h.displayName,
      h.firstName,
      h.lastName,
      '${h.firstName ?? ''} ${h.lastName ?? ''}',
    ].any((s) => (s ?? '').toLowerCase().contains(q));
  }

  void onSearchChanged(String term) {
    searchTerm = term;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      updateTrinaRows();
      gridKey = UniqueKey();
      update();
    });
  }

  void clearSearch() {
    searchController.clear();
    searchTerm = '';
    _searchDebounce?.cancel();
    updateTrinaRows();
    gridKey = UniqueKey();
    update();
  }

  TrinaGridStateManager? stateManager;
  bool isMinorUpdate = false;
  bool isMajorUpdate = false;
  // True while a view's data is being fetched/built. Starts true so the very
  // first render shows a spinner rather than a false "no members" message.
  bool isLoading = true;
  String descriptionText = '';
  String tableHeadingText = '';

  static const double photoRowHeight = 300;
  static const double standardRowHeight = 30;

  final List<TrinaColumn> columns = <TrinaColumn>[];
  Key gridKey = UniqueKey();

  EKennelGridOptions columnsType = EKennelGridOptions.membership;

  final List<TrinaColumn> columnsAll = <TrinaColumn>[
    TrinaColumn(
      title: 'Hasher ID',
      field: 'publicHasherId',
      type: TrinaColumnType.text(),
      hide: true,
    ),
    TrinaColumn(
      title: 'Kennel ID',
      field: 'kennelId',
      type: TrinaColumnType.text(),
      hide: true,
    ),
    TrinaColumn(
      title: 'Display Name',
      field: 'displayName',
      type: TrinaColumnType.text(),
      sort: TrinaColumnSort.ascending,
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Hash Name',
      field: 'hashName',
      type: TrinaColumnType.text(),
    ),
    TrinaColumn(
      title: 'First Name',
      field: 'firstName',
      type: TrinaColumnType.text(),
    ),
    TrinaColumn(
      title: 'Last Name',
      field: 'lastName',
      type: TrinaColumnType.text(),
    ),
    TrinaColumn(
      title: 'Email',
      field: 'eMail',
      type: TrinaColumnType.text(),
      renderer: (TrinaColumnRendererContext rendererContext) {
        final String v = rendererContext.cell.value.toString();
        return Text(v, style: emailTextStyle(v));
      },
    ),
    TrinaColumn(
      title: 'Photo',
      field: 'photo',
      type: TrinaColumnType.text(),
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Invite Code',
      field: 'inviteCode',
      type: TrinaColumnType.text(),
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Is Home Kennel',
      field: 'isHomeKennel',
      type: TrinaColumnType.select(<dynamic>['Yes', 'No']),
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Is Following',
      field: 'isFollowing',
      type: TrinaColumnType.select(<dynamic>['Yes', 'No', 'Auto']),
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Is Member',
      field: 'isMember',
      type: TrinaColumnType.select(<dynamic>['Yes', 'No']),
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Status',
      field: 'status',
      type: TrinaColumnType.select(<dynamic>['Member', 'Following', 'None']),
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Notifications',
      field: 'notifications',
      type: TrinaColumnType.select(<dynamic>[
        'On',
        'Off',
        'Silver Bell',
        '6 hrs before',
      ]),
    ),
    TrinaColumn(
      title: 'Email Alerts',
      field: 'emailAlerts',
      type: TrinaColumnType.select(<dynamic>['Auto', 'On', 'Off']),
    ),
    TrinaColumn(
      title: 'Historic Haring Counts',
      field: 'historicHaring',
      type: TrinaColumnType.number(),
    ),
    TrinaColumn(
      title: 'Historic Total Runs',
      field: 'historicTotalRuns',
      type: TrinaColumnType.number(),
    ),
    TrinaColumn(
      title: 'Haring in HC',
      field: 'trackedHaringInHc',
      type: TrinaColumnType.number(),
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Pack runs in HC',
      field: 'trackedPackRunsInHc',
      type: TrinaColumnType.number(),
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Total Haring',
      field: 'overallTotalHaring',
      type: TrinaColumnType.number(),
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Total Runs',
      field: 'overallTotalRuns',
      type: TrinaColumnType.number(),
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Historic Data is Estimated',
      field: 'historicCountsAreEstimates',
      type: TrinaColumnType.select(<dynamic>['Yes', 'No']),
    ),
    TrinaColumn(
      title: 'Date of Last Run',
      field: 'dateOfLastRun',
      type: TrinaColumnType.date(),
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Membership Expiration Date',
      field: 'membershipExpirationDate',
      type: TrinaColumnType.date(),
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Hash Credit',
      field: 'hashCredit',
      type: TrinaColumnType.number(),
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Last Login Date',
      field: 'lastLoginDateTime',
      type: TrinaColumnType.date(),
      enableEditingMode: false,
    ),
  ];

  final List<TrinaColumn> columnsNotificationAndEmail = <TrinaColumn>[
    TrinaColumn(
      title: 'Display Name',
      field: 'displayName',
      type: TrinaColumnType.text(),
      sort: TrinaColumnSort.ascending,
      enableEditingMode: false,
      width: 300,
    ),
    TrinaColumn(
      title: 'Notifications',
      field: 'notifications',
      // Kennel-level preference — no 'Auto' (auto only applies at the event
      // level, where it falls back to this kennel default). On=1, Off=2,
      // Silver Bell=3 (silent/in-app only), 6 hrs before=4 (push only within
      // the 6-hour window before the run).
      type: TrinaColumnType.select(<dynamic>[
        'On',
        'Off',
        'Silver Bell',
        '6 hrs before',
      ]),
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          rendererContext.cell.value.toString(),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
    TrinaColumn(
      title: 'Email Alerts',
      field: 'emailAlerts',
      type: TrinaColumnType.select(<dynamic>['Auto', 'On', 'Off']),
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          rendererContext.cell.value.toString(),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
  ];

  final List<TrinaColumn> columnsMembership = <TrinaColumn>[
    TrinaColumn(
      title: 'Display Name',
      field: 'displayName',
      type: TrinaColumnType.text(),
      sort: TrinaColumnSort.ascending,
      enableEditingMode: false,
      width: 300,
    ),
    TrinaColumn(
      title: 'Status',
      field: 'status',
      type: TrinaColumnType.select(<dynamic>['Member', 'Following']),
      width: 150,
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          rendererContext.cell.value.toString(),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
    TrinaColumn(
      title: 'Last login to app',
      field: 'lastLoginDateTime',
      type: TrinaColumnType.date(),
      //sort: TrinaColumnSort.ascending,
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Last run',
      field: 'dateOfLastRun',
      type: TrinaColumnType.date(),
      //sort: TrinaColumnSort.ascending,
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Email',
      field: 'eMail',
      type: TrinaColumnType.text(),
      width: 300,
      renderer: (TrinaColumnRendererContext rendererContext) {
        final String v = rendererContext.cell.value.toString();
        return Text(
          v,
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            // Dark red: an address we made up (generated_email.dart).
            color: isGeneratedEmail(v) ? kGeneratedEmailColor : Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
    // TrinaColumn(
    //   title: 'Is Following',
    //   field: 'isFollowing',
    //   type: TrinaColumnType.select(<dynamic>['Yes', 'No']),
    //   enableEditingMode: false,
    //   // renderer: (TrinaColumnRendererContext rendererContext) {
    //   //   return Text(
    //   //     rendererContext.cell.value.toString(),
    //   //     style: TextStyle(
    //   //       fontFamily: 'AvenirNextBold',
    //   //       color: Colors.blue.shade700,
    //   //       fontWeight: FontWeight.bold,
    //   //     ),
    //   //   );
    //   // },
    // ),
  ];

  final List<TrinaColumn> columnsPhoto = <TrinaColumn>[
    // TrinaColumn(
    //   title: 'Hasher ID',
    //   field: 'publicHasherId',
    //   type: TrinaColumnType.text(),
    //   hide: true,
    // ),
    // TrinaColumn(
    //   title: 'Kennel ID',
    //   field: 'kennelId',
    //   type: TrinaColumnType.text(),
    //   hide: true,
    // ),
    TrinaColumn(
      title: 'Display Name',
      field: 'displayName',
      type: TrinaColumnType.text(),
      sort: TrinaColumnSort.ascending,
      enableEditingMode: false,
      width: 400,
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          rendererContext.cell.value.toString(),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 36,
          ),
        );
      },
    ),
    // TrinaColumn(
    //   title: 'Hash Name',
    //   field: 'hashName',
    //   type: TrinaColumnType.text(),
    // ),
    TrinaColumn(
      title: 'Photo',
      field: 'photo',
      minWidth: KennelHashersController.photoRowHeight,
      width: KennelHashersController.photoRowHeight,
      type: TrinaColumnType.text(),
      enableEditingMode: false,
    ),
  ];

  final List<TrinaColumn> columnsHashCredit = <TrinaColumn>[
    // TrinaColumn(
    //   title: 'Hasher ID',
    //   field: 'publicHasherId',
    //   type: TrinaColumnType.text(),
    //   hide: true,
    // ),
    // TrinaColumn(
    //   title: 'Kennel ID',
    //   field: 'kennelId',
    //   type: TrinaColumnType.text(),
    //   hide: true,
    // ),
    TrinaColumn(
      title: 'Display Name',
      field: 'displayName',
      type: TrinaColumnType.text(),
      sort: TrinaColumnSort.ascending,
      enableEditingMode: false,
      width: 300,
    ),

    TrinaColumn(
      title: 'Hash Credit',
      field: 'hashCredit',
      type: TrinaColumnType.number(),
      enableEditingMode: false,
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          ((rendererContext.cell.value as num).toStringAsFixed(2)),
          style: const TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
    TrinaColumn(
      title: 'Discount',
      field: 'discountAmount',
      type: TrinaColumnType.number(format: '#######.00'),
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          (rendererContext.cell.value as num).toStringAsFixed(2),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
    TrinaColumn(
      title: 'Discount %',
      field: 'discountPercent',
      type: TrinaColumnType.number(),
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          (rendererContext.cell.value as num).toStringAsFixed(0),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
    TrinaColumn(
      title: 'Discount description',
      field: 'discountDescription',
      type: TrinaColumnType.text(),
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          rendererContext.cell.value as String,
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
  ];

  final List<TrinaColumn> columnsRunCounts = <TrinaColumn>[
    // TrinaColumn(
    //   title: 'Hasher ID',
    //   field: 'publicHasherId',
    //   type: TrinaColumnType.text(),
    //   enableEditingMode: false,
    //   hide: true,
    // ),
    // TrinaColumn(
    //   title: 'Kennel ID',
    //   field: 'kennelId',
    //   type: TrinaColumnType.text(),
    //   enableEditingMode: false,
    //   hide: true,
    // ),
    TrinaColumn(
      title: 'Display Name',
      field: 'displayName',
      type: TrinaColumnType.text(),
      sort: TrinaColumnSort.ascending,
      enableEditingMode: false,
      width: 300,
    ),

    // TrinaColumn(
    //   title: 'Hash Name',
    //   field: 'hashName',
    //   type: TrinaColumnType.text(),
    //   enableEditingMode: false,
    // ),
    // TrinaColumn(
    //   title: 'First Name',
    //   field: 'firstName',
    //   type: TrinaColumnType.text(),
    //   enableEditingMode: false,
    // ),
    // TrinaColumn(
    //   title: 'Last Name',
    //   field: 'lastName',
    //   type: TrinaColumnType.text(),
    //   enableEditingMode: false,
    // ),
    TrinaColumn(
      title: 'Previous total runs',
      field: 'historicTotalRuns',
      type: TrinaColumnType.number(),
      width: 150,
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          rendererContext.cell.value.toString(),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),

    TrinaColumn(
      title: 'Overall total runs',
      field: 'overallTotalRuns',
      type: TrinaColumnType.number(),
      width: 150,
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Previous haring',
      field: 'historicHaring',
      type: TrinaColumnType.number(),
      width: 150,
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          rendererContext.cell.value.toString(),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
    TrinaColumn(
      title: 'Overall haring',
      field: 'overallTotalHaring',
      type: TrinaColumnType.number(),
      width: 150,
      enableEditingMode: false,
    ),

    // Uncomment for testing

    // TrinaColumn(
    //   title: 'Pack runs in HC',
    //   field: 'trackedPackRunsInHc',
    //   type: TrinaColumnType.number(),
    //   width: 150.0,
    //   enableEditingMode: false,
    // ),
    // TrinaColumn(
    //   title: 'Haring in HC',
    //   field: 'trackedHaringInHc',
    //   type: TrinaColumnType.number(),
    //   width: 150.0,
    //   enableEditingMode: false,
    // ),
    // TrinaColumn(
    //   title: 'Total in HC',
    //   field: 'trackedTotalRunsInHc',
    //   type: TrinaColumnType.number(),
    //   width: 150.0,
    //   enableEditingMode: false,
    // ),

    // TrinaColumn(
    //   title: 'Previous pack runs',
    //   field: 'historicPackRuns',
    //   type: TrinaColumnType.number(),
    //   width: 150.0,
    // ),

    // TrinaColumn(
    //   title: 'Overall pack runs',
    //   field: 'overallTotalPackRuns',
    //   type: TrinaColumnType.number(),
    //   width: 150.0,
    //   enableEditingMode: false,
    // ),
    TrinaColumn(
      title: 'Previous are estimates',
      field: 'historicCountsAreEstimates',
      type: TrinaColumnType.select(<dynamic>['Yes', 'No']),
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          rendererContext.cell.value.toString(),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
  ];

  final List<TrinaColumn> columnsNameAndEmail = <TrinaColumn>[
    TrinaColumn(
      title: 'Display Name',
      field: 'displayName',
      type: TrinaColumnType.text(),
      sort: TrinaColumnSort.ascending,
      enableEditingMode: false,
      width: 300,
    ),
    TrinaColumn(
      title: 'Hash Name',
      field: 'hashName',
      type: TrinaColumnType.text(),
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          rendererContext.cell.value.toString(),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
    TrinaColumn(
      title: 'First Name',
      field: 'firstName',
      type: TrinaColumnType.text(),
      width: 140,
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          rendererContext.cell.value.toString(),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
    TrinaColumn(
      title: 'Last Name',
      field: 'lastName',
      type: TrinaColumnType.text(),
      width: 140,
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          rendererContext.cell.value.toString(),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
    TrinaColumn(
      title: 'Email',
      field: 'eMail',
      type: TrinaColumnType.text(),
      width: 250,
      renderer: (TrinaColumnRendererContext rendererContext) {
        final String v = rendererContext.cell.value.toString();
        return Text(
          v,
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            // Dark red: an address we made up (generated_email.dart).
            color: isGeneratedEmail(v) ? kGeneratedEmailColor : Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
    TrinaColumn(
      title: 'Invite Code',
      field: 'inviteCode',
      type: TrinaColumnType.text(),
      enableEditingMode: false,
    ),
  ];

  final List<TrinaColumn> columnsAddHasher = <TrinaColumn>[
    TrinaColumn(
      title: 'Hash Name',
      field: 'hashName',
      type: TrinaColumnType.text(),
      width: 250,
    ),
    TrinaColumn(
      title: 'First Name',
      field: 'firstName',
      type: TrinaColumnType.text(),
      width: 180,
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          rendererContext.cell.value.toString(),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
    TrinaColumn(
      title: 'Last Name',
      field: 'lastName',
      type: TrinaColumnType.text(),
      width: 180,
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          rendererContext.cell.value.toString(),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
    TrinaColumn(
      title: 'Email',
      field: 'eMail',
      type: TrinaColumnType.text(),
      width: 300,
      renderer: (TrinaColumnRendererContext rendererContext) {
        final cellValue = rendererContext.cell.value.toString();
        var emailValid = true;
        if (cellValue.isNotEmpty) {
          emailValid = EmailValidator.validate(cellValue);
        }
        return Row(
          children: <Widget>[
            if (!emailValid) ...<Widget>[
              const Icon(FontAwesome.warning, size: 20, color: Colors.orange),
              const SizedBox(width: 10),
            ],
            Text(
              cellValue,
              style: TextStyle(
                fontFamily: 'AvenirNextBold',
                color: isGeneratedEmail(cellValue) ? kGeneratedEmailColor : Colors.blue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    ),
    TrinaColumn(
      title: 'Run count',
      field: 'historicTotalRuns',
      type: TrinaColumnType.number(),
      width: 150,
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          rendererContext.cell.value.toString(),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
    TrinaColumn(
      title: 'Haring count',
      field: 'historicHaring',
      type: TrinaColumnType.number(),
      width: 150,
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          rendererContext.cell.value.toString(),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
  ];

  final List<TrinaRow<dynamic>> rows = <TrinaRow<dynamic>>[];

  final List<KennelHashersModel> hashers = <KennelHashersModel>[];
  final List<NewHasherModel> newHashers = <NewHasherModel>[];

  // ── Import from file / Email invite codes (E2.F2.S6, James 2026-10-10) ──

  /// The grid holds rows read from a file: the save then passes
  /// @fromImport = 1 (rows already in the kennel are left alone, a row with
  /// no email is kept, every added hasher gets an invite code).
  bool fromImport = false;

  /// The hashers the last import added (NEW HC USER / NEW MEMBER), for
  /// "Email invite codes" › the hashers just imported.
  final List<String> lastImportedPublicHasherIds = <String>[];

  bool isReadingFile = false;

  /// The admin's answers to "is this the same person?" for the imported
  /// rows, by grid row: { matchPublicHasherId, updateEmail }. A row with no
  /// entry is added as a new hasher.
  final Map<int, Map<String, dynamic>> importMatches = <int, Map<String, dynamic>>{};

  /// Rows that look like a member of this kennel (same first + last name,
  /// or hash name) but carry a different email: ask the admin whether each
  /// is the same person and whether to use the new address. The email can
  /// only be replaced for someone who has never signed in and whose home
  /// kennel this is (2026-09-23 rule) — the SP says which, and bulk-add
  /// checks again on save.
  /// Whether the grid on screen has an Email column with an address we made
  /// up in it: the page then shows the dark-red note under the grid.
  bool get gridShowsGeneratedEmail =>
      columns.any((TrinaColumn col) => col.field == 'eMail') &&
      rows.any((TrinaRow r) => isGeneratedEmail(r.cells['eMail']?.value?.toString()));

  /// A unique address for a hasher with none, in the same shape the SP
  /// makes: hc-<12 hex>@noemail.invalid.
  static String _placeholderEmail() {
    final Random r = Random.secure();
    final String hex = List<String>.generate(12, (_) => r.nextInt(16).toRadixString(16)).join();
    return 'hc-$hex@noemail.invalid';
  }

  Future<void> _reviewNameMatches() async {
    importMatches.clear();
    // Only up to the last row with a name: the grid pads itself with blank
    // rows, and the SP numbers rows by their position in this array.
    final int used = newHashers.lastIndexWhere((NewHasherModel h) =>
            (h.hashName ?? '').trim().isNotEmpty || (h.firstName ?? '').trim().isNotEmpty || (h.lastName ?? '').trim().isNotEmpty) +
        1;
    final String rowsJson = jsonEncode(newHashers
        .take(used)
        .map((NewHasherModel h) => <String, String>{
              'firstName': h.firstName ?? '',
              'lastName': h.lastName ?? '',
              'hashName': h.hashName ?? '',
              'eMail': h.eMail ?? '',
            })
        .toList());
    final ApiResult res = await ServiceCommon.sendHttpPostToHC6Api(<String, dynamic>{
      'queryType': 'matchImportRows',
      'deviceId': box.get(HIVE_DEVICE_ID) as String,
      'accessToken': _kennelToken('hcportal_matchImportRows'),
      'publicKennelId': kennel.publicKennelId,
      'rowsJson': rowsJson,
    });
    if (res is! ApiSuccess) return;
    final List<dynamic> sets = json.decode(res.body) as List<dynamic>;
    if (sets.length < 2 || (sets[0] as List).isEmpty) return;
    if ((sets[0] as List).first['Success'] != 1) return;
    final List<Map<String, dynamic>> cands =
        (sets[1] as List).map((dynamic e) => e as Map<String, dynamic>).toList();
    if (cands.isEmpty) return;

    // 'new' = same person, use the file's email; 'keep' = same person, keep
    // theirs; 'different' = add as a new hasher.
    final Map<int, String> choice = <int, String>{
      for (final Map<String, dynamic> c in cands)
        (c['rowNo'] as num).toInt(): c['canChangeEmail'] == 1 ? 'new' : 'keep',
    };
    String why(Map<String, dynamic> c) => c['signedIn'] == 1
        ? 'They have signed in to Harrier Central, so only they can change their email.'
        : c['emailInUse'] == 1
            ? 'The new address already belongs to another account.'
            : 'Another kennel looks after their details.';

    await Get.dialog<void>(
      StatefulBuilder(
        builder: (BuildContext ctx, void Function(void Function()) setDialog) => AlertDialog(
          title: Text('${cands.length} ${cands.length == 1 ? 'hasher looks' : 'hashers look'} like someone already in ${kennel.kennelShortName}'),
          content: SizedBox(
            width: 640,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text('Same name, different email. Is each the same person?'),
                  const SizedBox(height: 12),
                  for (final Map<String, dynamic> c in cands) ...<Widget>[
                    Builder(builder: (BuildContext _) {
                      final int row = (c['rowNo'] as num).toInt();
                      final NewHasherModel f = newHashers[row];
                      final bool canChange = c['canChangeEmail'] == 1;
                      final String member = [
                        if ((c['hashName'] as String? ?? '').trim().isNotEmpty) (c['hashName'] as String).trim(),
                        '${(c['firstName'] ?? '').toString().trim()} ${(c['lastName'] ?? '').toString().trim()}'.trim(),
                      ].join(' · ');
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('In the file: ${[f.hashName, '${f.firstName ?? ''} ${f.lastName ?? ''}'.trim()].where((String? x) => (x ?? '').isNotEmpty).join(' · ')}  —  ${f.eMail}',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text.rich(TextSpan(children: <InlineSpan>[
                              TextSpan(text: 'In ${kennel.kennelShortName}: $member  —  '),
                              TextSpan(
                                  text: (c['currentEmail'] ?? '').toString(),
                                  style: emailTextStyle((c['currentEmail'] ?? '').toString())),
                            ])),
                            if (!canChange)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(why(c), style: const TextStyle(color: Colors.black54, fontSize: 12)),
                              ),
                            const SizedBox(height: 6),
                            DropdownButton<String>(
                              value: choice[row],
                              isExpanded: true,
                              onChanged: (String? v) => setDialog(() => choice[row] = v!),
                              items: <DropdownMenuItem<String>>[
                                if (canChange)
                                  const DropdownMenuItem<String>(value: 'new', child: Text('Same person — use the new email')),
                                DropdownMenuItem<String>(value: 'keep', child: Text('Same person — keep ${c['currentEmail'] ?? 'their email'}')),
                                const DropdownMenuItem<String>(value: 'different', child: Text('Different people — add as a new hasher')),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  GeneratedEmailNote(
                    show: cands.any((Map<String, dynamic> c) => isGeneratedEmail((c['currentEmail'] ?? '').toString())),
                    padding: const EdgeInsets.only(top: 4),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            HcButton.primary(label: 'Apply', onPressed: () => Get.back<void>()),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    for (final Map<String, dynamic> c in cands) {
      final int row = (c['rowNo'] as num).toInt();
      final String pick = choice[row] ?? 'keep';
      if (pick == 'different') continue;
      importMatches[row] = <String, dynamic>{
        'matchPublicHasherId': c['publicHasherId'],
        'updateEmail': pick == 'new' ? 1 : 0,
      };
    }
  }

  String _kennelToken(String proc) {
    final deviceId = box.get(HIVE_DEVICE_ID) as String;
    final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
    return Utilities.generateToken(
      deviceId,
      proc,
      paramString: '$deviceSecret:${kennel.publicKennelId}',
    );
  }

  Future<Map<String, dynamic>> _postJson(String url, Map<String, dynamic> body) async {
    final http.Response r = await http
        .post(
          Uri.parse(url),
          headers: <String, String>{'content-type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 180));
    Map<String, dynamic> j;
    try {
      j = jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {
      j = <String, dynamic>{};
    }
    if (r.statusCode != 200) {
      throw Exception((j['errorUserMessage'] as String?) ??
          'Harrier Central could not do that just now (${r.statusCode}).');
    }
    return j;
  }

  /// Reads a member list (Excel, CSV, Word or PDF) and puts its people in the
  /// add-hashers grid for the admin to check before saving.
  Future<void> importFromFile() async {
    final FilePickerResult? picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['xlsx', 'xlsm', 'csv', 'tsv', 'txt', 'pdf', 'docx', 'xls', 'doc'],
      withData: true,
    );
    final PlatformFile? file = picked?.files.single;
    if (file == null || file.bytes == null) return;
    isReadingFile = true;
    update();
    try {
      final Map<String, dynamic> j = await _postJson(BASE_ROSTER_IMPORT_URL, <String, dynamic>{
        'deviceId': box.get(HIVE_DEVICE_ID) as String,
        'accessToken': _kennelToken('hcportal_authorizeRosterImport'),
        'publicKennelId': kennel.publicKennelId,
        'fileName': file.name,
        'fileBase64': base64Encode(file.bytes!),
      });
      final List<dynamic> found = (j['rows'] as List<dynamic>?) ?? <dynamic>[];
      if (found.isEmpty) {
        await Utilities.showAlert('Nobody found', 'No people with a name could be read from ${file.name}.', 'OK');
        return;
      }
      newHashers
        ..clear()
        ..addAll(found.map((dynamic e) {
          final m = e as Map<String, dynamic>;
          return NewHasherModel(
            firstName: (m['firstName'] ?? '') as String,
            lastName: (m['lastName'] ?? '') as String,
            hashName: (m['hashName'] ?? '') as String,
            // No address in the file: a unique made-up one, shown in the
            // grid (James, 2026-10-10). The email is the account's key, and
            // .invalid can never be delivered — the invite sender skips it.
            eMail: ((m['eMail'] ?? '') as String).trim().isEmpty ? _placeholderEmail() : (m['eMail'] as String).trim(),
            historicTotalRuns: (m['historicTotalRuns'] as num?)?.toInt() ?? 0,
            historicHaring: (m['historicHaring'] as num?)?.toInt() ?? 0,
          );
        }));
      fromImport = true;
      await setColumnsType(EKennelGridOptions.addNewMembers);
      await _reviewNameMatches();
      final int dropped = (j['dropped'] as num?)?.toInt() ?? 0;
      // Counted on the rows READ, not the grid: the grid pads itself to 100
      // blank rows, which once made "7 read" say "95 without an email".
      final int noEmail = found.where((dynamic e) => (((e as Map<String, dynamic>)['eMail'] ?? '') as String).isEmpty).length;
      await Utilities.showAlert(
        'Read ${found.length} ${found.length == 1 ? 'hasher' : 'hashers'}',
        'Check the grid, correct anything that was misread, then press Save.'
        '${noEmail > 0 ? '~~$noEmail without an email address ${noEmail == 1 ? 'was' : 'were'} given a made-up one ending @noemail.invalid. Replace it if you know the real address; otherwise they are added but cannot be emailed an invite.' : ''}'
        '${dropped > 0 ? '~~$dropped ${dropped == 1 ? 'row was' : 'rows were'} left out: neither a hash name nor a first and last name.' : ''}'
        '${j['truncated'] == true ? '~~The file was very long; only the first part was read.' : ''}',
        'OK',
      );
    } catch (e) {
      await Utilities.showAlert('Import from file', e.toString().replaceFirst('Exception: ', ''), 'OK');
    } finally {
      isReadingFile = false;
      update();
    }
  }

  /// Emails each hasher their invite code from "KENNEL via Harrier
  /// Central": the hashers just imported, or everyone in the kennel who has
  /// never signed in. Shows the counts first; sends only on confirm.
  Future<void> emailInviteCodes() async {
    String scope = lastImportedPublicHasherIds.isNotEmpty ? 'imported' : 'neverLoggedIn';
    final String? chosen = await Get.dialog<String>(
      StatefulBuilder(
        builder: (BuildContext c, void Function(void Function()) setDialog) => AlertDialog(
          title: const Text('Email invite codes'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Each hasher gets their own code, from '
                    '"Your kennel via Harrier Central", with how to get the app.'),
                const SizedBox(height: 12),
                ListTile(
                  enabled: lastImportedPublicHasherIds.isNotEmpty,
                  leading: Icon(scope == 'imported' ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                  onTap: () => setDialog(() => scope = 'imported'),
                  title: Text('The hashers just imported (${lastImportedPublicHasherIds.length})'),
                  subtitle: lastImportedPublicHasherIds.isEmpty ? const Text('Nobody has been imported in this session.') : null,
                ),
                ListTile(
                  leading: Icon(scope == 'neverLoggedIn' ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                  onTap: () => setDialog(() => scope = 'neverLoggedIn'),
                  title: const Text('Everyone in this kennel who has never signed in to the app'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            HcButton.secondary(label: 'Cancel', onPressed: () => Get.back<String>()),
            HcButton.primary(label: 'Next', onPressed: () => Get.back<String>(result: scope)),
          ],
        ),
      ),
    );
    if (chosen == null) return;

    Map<String, dynamic> body() => <String, dynamic>{
      'deviceId': box.get(HIVE_DEVICE_ID) as String,
      'accessToken': _kennelToken('hcportal_getInviteEmailList'),
      'publicKennelId': kennel.publicKennelId,
      'scope': chosen,
      'publicHasherIds': lastImportedPublicHasherIds,
    };
    isMajorUpdate = true;
    update();
    Map<String, dynamic> preview;
    try {
      preview = await _postJson(BASE_INVITE_EMAILS_URL, <String, dynamic>{...body(), 'send': false});
    } catch (e) {
      isMajorUpdate = false;
      update();
      await Utilities.showAlert('Email invite codes', e.toString().replaceFirst('Exception: ', ''), 'OK');
      return;
    }
    isMajorUpdate = false;
    update();

    final int n = (preview['toSend'] as num?)?.toInt() ?? 0;
    final List<String> skipped = <String>[
      if (((preview['skippedRecent'] as num?) ?? 0) > 0) '${preview['skippedRecent']} invited in the last 7 days',
      if (((preview['skippedNoEmail'] as num?) ?? 0) > 0) '${preview['skippedNoEmail']} with no email address',
      if (((preview['skippedUndeliverable'] as num?) ?? 0) > 0) '${preview['skippedUndeliverable']} whose address cannot receive mail',
      if (((preview['skippedNoCode'] as num?) ?? 0) > 0) '${preview['skippedNoCode']} without a code',
    ];
    if (n == 0) {
      await Utilities.showAlert('Nobody to email',
          skipped.isEmpty ? 'There is nobody to send an invite to.' : 'Skipped: ${skipped.join(', ')}.', 'OK');
      return;
    }
    final bool? go = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Send $n ${n == 1 ? 'invite' : 'invites'}?'),
        content: SizedBox(
          width: 440,
          child: Text(skipped.isEmpty ? 'Each gets their own invite code.' : 'Skipped: ${skipped.join(', ')}.'),
        ),
        actions: <Widget>[
          HcButton.secondary(label: 'Cancel', onPressed: () => Get.back<bool>(result: false)),
          HcButton.primary(label: 'Send $n', icon: Icons.send_rounded, onPressed: () => Get.back<bool>(result: true)),
        ],
      ),
    );
    if (go != true) return;
    isMajorUpdate = true;
    update();
    try {
      final Map<String, dynamic> done = await _postJson(BASE_INVITE_EMAILS_URL, <String, dynamic>{...body(), 'send': true});
      final int sent = (done['sent'] as num?)?.toInt() ?? 0;
      await Utilities.showAlert(
        'Invites sent',
        'Sent $sent ${sent == 1 ? 'invite code' : 'invite codes'}.'
        '${done['stoppedEarly'] == true ? '~~The email service asked us to slow down, so it stopped there. Press Email invite codes again later to send the rest — nobody gets two.' : ''}',
        'OK',
      );
    } catch (e) {
      await Utilities.showAlert('Email invite codes', e.toString().replaceFirst('Exception: ', ''), 'OK');
    } finally {
      isMajorUpdate = false;
      update();
    }
  }

  @override
  void onInit() {
    super.onInit();

    visibleViews = <EKennelGridOptions>[
      if (kennel.canManageMembers) ...[
        EKennelGridOptions.addNewMembers,
        EKennelGridOptions.nonAppHashers,
        EKennelGridOptions.membership,
        EKennelGridOptions.runCounts,
        EKennelGridOptions.notificationAndEmail,
        EKennelGridOptions.photos,
      ],
      EKennelGridOptions.hashCredit,
    ];

    initTabs(
      vsync: this,
      tabs: _buildTabDefinitions(),
      tabKeyBuilder: (index) => visibleViews[index].name,
      onTabIndexChanged: _onTabChanged,
    );
    initTabStateBundle(
      length: visibleViews.length,
      initialLockState: TabLocked.tabUnlocked,
    );
    // No per-tab validation on this page → clear the rail/hamburger status icons.
    for (final s in tabStatus) {
      s.value = TabStatus.unknown;
    }

    setScreenSize();
    ever(width, (_) => setScreenSize());

    unawaited(_loadInitialView());
  }

  Future<void> _loadInitialView() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final initialView = kennel.canManageMembers
        ? EKennelGridOptions.membership
        : EKennelGridOptions.hashCredit;
    final initialIndex = visibleViews
        .indexOf(initialView)
        .clamp(0, visibleViews.length - 1);
    if (tabController.index != initialIndex) {
      // Fires the tab listener → _onTabChanged → loads that view.
      tabController.index = initialIndex;
    } else {
      await setColumnsType(visibleViews[initialIndex]);
    }
  }

  // Switches the grid/cards to the view for the newly-selected tab.
  void _onTabChanged() {
    final i = currentIndex.value;
    if (i >= 0 && i < visibleViews.length) {
      unawaited(setColumnsType(visibleViews[i]));
    }
  }

  List<TabDefinitionData> _buildTabDefinitions() {
    return [
      for (var i = 0; i < visibleViews.length; i++)
        TabDefinitionData(
          key: visibleViews[i].name,
          title: viewTitle(visibleViews[i]),
          tabIndex: i,
          hasCustomTabStatusFunction: false,
          showTabInSubmitSummary: false,
          isTabLockable: false,
          sidebarData: SideBarData(
            viewTitle(visibleViews[i]),
            _viewIcon(visibleViews[i]),
            '',
          ),
        ),
    ];
  }

  static String viewTitle(EKennelGridOptions v) {
    switch (v) {
      case EKennelGridOptions.addNewMembers:
        return 'Add new Hashers';
      case EKennelGridOptions.nonAppHashers:
        return 'Non-app Hashers';
      case EKennelGridOptions.membership:
        return 'Membership';
      case EKennelGridOptions.runCounts:
        return 'Run counts';
      case EKennelGridOptions.notificationAndEmail:
        return 'Notifications & Email';
      case EKennelGridOptions.photos:
        return 'Photos';
      case EKennelGridOptions.hashCredit:
        return 'Payment Info';
      case EKennelGridOptions.allFields:
        return 'All fields';
    }
  }

  IconData _viewIcon(EKennelGridOptions v) {
    switch (v) {
      case EKennelGridOptions.addNewMembers:
        return Icons.person_add_alt_1_outlined;
      case EKennelGridOptions.nonAppHashers:
        return Icons.badge_outlined;
      case EKennelGridOptions.membership:
        return Icons.groups_outlined;
      case EKennelGridOptions.runCounts:
        return Icons.directions_run_outlined;
      case EKennelGridOptions.notificationAndEmail:
        return Icons.notifications_outlined;
      case EKennelGridOptions.photos:
        return Icons.photo_library_outlined;
      case EKennelGridOptions.hashCredit:
        return Icons.payments_outlined;
      case EKennelGridOptions.allFields:
        return Icons.table_chart_outlined;
    }
  }

  // ── TabUiController required overrides ──────────────────────────────────────
  // No-ops: this page commits each field immediately via updateHasherField,
  // so there's no form-level save/undo/validation cycle.
  @override
  void checkIfFormIsDirty() {}

  @override
  void undoChanges() {}

  @override
  void populateTextControllers() {}

  @override
  Future<void> save(bool showDialog) async {}

  @override
  Future<void> close() async {
    Get.back<void>();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    super.onClose();
  }

  Future<void> getRowData() async {
    if (!_hashersFresh) {
      await _fetchAllHashers();
    }
    _applyViewFilter();

    isLoading = false;
    update();

    // Refresh the grid in place if it's already mounted. (This previously polled
    // for stateManager up to 100×100ms = 10s. On the phone/card layout the
    // TrinaGrid is never built, so onGridLoaded never fires and stateManager
    // stays null — the loop then waited the FULL 10 seconds on every load. The
    // grid is rebuilt with fresh rows via its changing gridKey anyway, so a
    // one-shot notify is all that's needed.)
    stateManager?.notifyListeners();
  }

  // Fetches the full member/follower set once and caches it. Tab switches then
  // filter the cache (see _applyViewFilter) instead of re-hitting the SP.
  Future<void> _fetchAllHashers() async {
    final deviceId = box.get(HIVE_DEVICE_ID) as String;
    final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
    final accessToken = Utilities.generateToken(
      deviceId,
      'hcportal_getKennelHashers',
      paramString: '$deviceSecret:${kennel.publicKennelId}',
    );

    final body = <String, dynamic>{
      'queryType': 'getKennelHashers',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'publicKennelId': kennel.publicKennelId,
    };

    final apiResult = await ServiceCommon.sendHttpPostToHC6Api(body);
    if (kDebugMode) {
      debugPrint(
        apiResult is ApiError
            ? 'SP 12a (a-b) [getKennelHashers] called — FAILED'
            : 'SP 12a (a-b) [getKennelHashers] called — success',
      );
    }
    _allFetched.clear();
    if (apiResult case ApiSuccess(body: final jsonString)) {
      final decodedJson = json.decode(jsonString) as List<dynamic>;
      final jsonGroup = (decodedJson[0] as List)
          .map<Map<String, dynamic>>((e) => e as Map<String, dynamic>)
          .toList();
      for (final jsonItem in jsonGroup) {
        _allFetched.add(KennelHashersModel.fromJson(jsonItem));
      }
      _hashersFresh = true;
    }
  }

  // Builds the current view's [hashers] list from the cached full set.
  void _applyViewFilter() {
    hashers.clear();
    rows.clear();
    newHashers.clear();
    for (final item in _allFetched) {
      var doAddRow = false;

      if ((columnsType == EKennelGridOptions.nonAppHashers) &&
          item.isHomeKennel.toLowerCase() == 'yes' &&
          item.inviteCode.trim().isNotEmpty) {
        doAddRow = true;
      } else if ((columnsType == EKennelGridOptions.allFields) ||
          (columnsType == EKennelGridOptions.runCounts) ||
          (columnsType == EKennelGridOptions.membership)) {
        doAddRow = true;
      } else if ((columnsType == EKennelGridOptions.photos) &&
          (item.photo.contains('http'))) {
        doAddRow = true;
      } else if (((columnsType == EKennelGridOptions.hashCredit) ||
              (columnsType == EKennelGridOptions.notificationAndEmail)) &&
          item.isMember.toLowerCase() == 'yes') {
        doAddRow = true;
      }

      if (doAddRow) {
        hashers.add(item);
      }
    }

    updateTrinaRows();
  }

  void updateTrinaRows() {
    rows.clear();
    displayedHashers
      ..clear()
      ..addAll(hashers.where(_matchesSearch));

    for (var i = 0; i < displayedHashers.length; i++) {
      final item = displayedHashers[i];
      final pr = TrinaRow<dynamic>(
        cells: <String, TrinaCell>{
          'publicHasherId': TrinaCell(value: item.publicHasherId),
          'publicKennelId': TrinaCell(value: item.publicKennelId),
          'hashName': TrinaCell(value: item.hashName ?? ''),
          'displayName': TrinaCell(value: (item.displayName?.capitalize ?? '')),
          'firstName': TrinaCell(value: item.firstName ?? ''),
          'lastName': TrinaCell(value: item.lastName ?? ''),
          'eMail': TrinaCell(value: item.eMail),
          'photo': TrinaCell(value: item.photo),
          'inviteCode': TrinaCell(value: item.inviteCode),
          'isHomeKennel': TrinaCell(value: item.isHomeKennel),
          'isFollowing': TrinaCell(value: item.isFollowing),
          'isMember': TrinaCell(value: item.isMember),
          'status': TrinaCell(value: item.status),
          'notifications': TrinaCell(value: item.notifications),
          'emailAlerts': TrinaCell(value: item.emailAlerts),
          'historicHaring': TrinaCell(value: item.historicHaring),
          'historicTotalRuns': TrinaCell(value: item.historicTotalRuns),
          'hcHaringCount': TrinaCell(value: item.hcHaringCount),
          'hcTotalRunCount': TrinaCell(value: item.hcTotalRunCount),
          'overallTotalHaring': TrinaCell(
            value: item.historicHaring + item.hcHaringCount,
          ),
          'overallTotalRuns': TrinaCell(
            value: item.historicTotalRuns + item.hcTotalRunCount,
          ),
          'historicCountsAreEstimates': TrinaCell(
            value: item.historicCountsAreEstimates,
          ),
          'dateOfLastRun': TrinaCell(value: item.dateOfLastRun ?? ''),
          'membershipExpirationDate': TrinaCell(
            value: item.membershipExpirationDate,
          ),
          'hashCredit': TrinaCell(value: item.hashCredit),
          'kennelCredit': TrinaCell(value: item.kennelCredit),
          'discountPercent': TrinaCell(value: item.discountPercent),
          'discountAmount': TrinaCell(value: item.discountAmount),
          'discountDescription': TrinaCell(
            value: item.discountDescription ?? '',
          ),
          'lastLoginDateTime': TrinaCell(value: item.lastLoginDateTime ?? ''),
        },
      );

      // print(i.toString() +
      //     ' # ' +
      //     item.trackedPackRunsInHc.toString() +
      //     ' # ' +
      //     item.trackedHaringInHc.toString() +
      //     ' # ' +
      //     item.historicTotalRuns.toString() +
      //     ' # ' +
      //     item.historicHaring.toString() +
      //     ' # ' +
      //     item.overallTotalRuns.toString() +
      //     ' # ' +
      //     item.overallTotalHaring.toString());

      rows.add(pr);
    }
  }

  /// Rows in the add-hashers grid: 100, or more when an import needs them.
  int _gridRows = 100;

  Future<void> prepareGridForAddingNewMembers() async {
    _gridRows = newHashers.length > 100 ? newHashers.length + 10 : 100;
    // fill in any empty records to make sure
    // we have a "full deck" to play with
    while (newHashers.length < 100 || newHashers.length < _gridRows) {
      final n = NewHasherModel(
        firstName: '',
        lastName: '',
        hashName: '',
        eMail: '',
      );

      newHashers.add(n);
    }

    TrinaRow<dynamic> pr;
    for (var i = 0; i < newHashers.length; i++) {
      pr = TrinaRow(
        cells: <String, TrinaCell>{
          'publicHasherId': TrinaCell(),
          'publicKennelId': TrinaCell(),
          'hashName': TrinaCell(value: newHashers[i].hashName),
          'firstName': TrinaCell(value: newHashers[i].firstName),
          'lastName': TrinaCell(value: newHashers[i].lastName),
          'eMail': TrinaCell(value: newHashers[i].eMail),
          'historicHaring': TrinaCell(value: newHashers[i].historicHaring),
          'historicTotalRuns': TrinaCell(
            value: newHashers[i].historicTotalRuns,
          ),
        },
      );

      rows.add(pr);
    }

    var i = 0;

    do {
      if (stateManager != null) {
        stateManager!.notifyListeners();
        break;
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      i++;
    } while (i < 100);

    isLoading = false;
    update();
  }

  Future<void> setColumnsType(EKennelGridOptions columnsType) async {
    isLoading = true;
    update();
    gridKey = UniqueKey();
    this.columnsType = columnsType;
    rows.clear();
    columns.clear();
    switch (columnsType) {
      case EKennelGridOptions.allFields:
        columns.addAll(columnsAll);
        descriptionText = 'The full monty!';
        tableHeadingText = 'All fields';
      case EKennelGridOptions.hashCredit:
        columns.addAll(columnsHashCredit);
        descriptionText =
            'This view allows you to see and edit payment related information for Kennel members. Discounts can be applied as either absolute amounts or percentages';
        tableHeadingText = 'Payment';
      case EKennelGridOptions.nonAppHashers:
        columns.addAll(columnsNameAndEmail);
        descriptionText =
            'You can edit names and email addresses and also see invite codes for Hashers that you have entered into the system. As a security measure, as soon as a Hasher has installed the app, you will no longer be able to update this information as they will be able to do this directly through their own app.';
        tableHeadingText = 'Names and Email Address';
      case EKennelGridOptions.notificationAndEmail:
        columns.addAll(columnsNotificationAndEmail);
        descriptionText =
            'You can view and edit the notification and email settings for members of your Kennel.';
        tableHeadingText = 'Notification and Email Preferences';
      case EKennelGridOptions.membership:
        columns.addAll(columnsMembership);
        descriptionText =
            'You can view people following your Kennel as well as Kennel members. You can change the membership status of Hashers, but only they can change whether or not they are following your Kennel.';
        tableHeadingText = 'Membership and Following Status';
      case EKennelGridOptions.photos:
        columns.addAll(columnsPhoto);
        descriptionText = 'Smile for the camera!';
        tableHeadingText = 'Profile Photos';
        columns[1].renderer = (TrinaColumnRendererContext context) {
          if (hashers[context.rowIdx].photo.contains('http')) {
            return HcNetworkImage(
              hashers[context.rowIdx].photo,
              height: 200,
              width: 200,
              errorBuilder: (_, _, _) => const SizedBox(
                height: 200,
                width: 200,
                child: Icon(Icons.person, color: Colors.grey),
              ),
            );
          } else {
            return Container();
          }
        };
      case EKennelGridOptions.runCounts:
        descriptionText =
            "This view allows you to set the number of times a Hasher has run before using Harrier Central (previous runs). The app will add this number to it's automatically generated run count information. You can indicate whether these previous run counts are based on actual data or are estimates. You can also sort the grid by clicking on the column header. To copy and paste, select a cell and then hold the shift key down while selecting another cell to define a cell range to copy.";
        tableHeadingText = 'Run Counts';
        columns.addAll(columnsRunCounts);
      case EKennelGridOptions.addNewMembers:
        descriptionText =
            "This view makes it easy to add new Hashers to Harrier Central. Once created, these new accounts will be visible on the 'name and email' view";
        tableHeadingText = 'Add New Kennel Members';
        columns.addAll(columnsAddHasher);
        columns[0].renderer = (TrinaColumnRendererContext context) {
          return Row(
            children: <Widget>[
              Icon(
                newHashers[context.rowIdx].addHasherStatus ==
                        BULK_IMPORT_RESPONSE_ERROR
                    ? MaterialCommunityIcons.close_box
                    : FontAwesome.check_square,
                size: 20,
                color: newHashers[context.rowIdx].addHasherStatus == null
                    ? Colors.white
                    : newHashers[context.rowIdx].addHasherStatus ==
                          BULK_IMPORT_RESPONSE_NO_CHANGE
                    ? Colors.grey.shade300
                    : newHashers[context.rowIdx].addHasherStatus ==
                          BULK_IMPORT_RESPONSE_NEW_MEMBER
                    ? Colors.blue.shade700
                    : newHashers[context.rowIdx].addHasherStatus ==
                          BULK_IMPORT_RESPONSE_NEW_HC_USER
                    ? Colors.green
                    : newHashers[context.rowIdx].addHasherStatus ==
                          BULK_IMPORT_RESPONSE_UPDATE_RUN_COUNTS
                    ? Colors.purple.shade500
                    : Colors.red.shade900,
              ),
              const SizedBox(width: 10),
              Text(
                ((context.cell.value as String?) ?? '').isNotEmpty
                    ? (context.cell.value as String? ?? '')
                    : (newHashers[context.rowIdx].hashName ?? ''),
                style: TextStyle(
                  fontFamily: 'AvenirNextBold',
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );

          // if ((context.rowIdx != null) && (_hashers.length > context.rowIdx )) {
          //   return Image.network(_hashers[context.rowIdx].photo, height: 200.0, width: 200.0);
          // } else {
          //   return Container();
          // }
        };
    }

    if (columnsType == EKennelGridOptions.addNewMembers) {
      await prepareGridForAddingNewMembers();
    } else {
      await getRowData();
    }
  }

  Future<void> onGridChanged(TrinaGridOnChangedEvent event) async {
    // this trick to embed the setState in a Delay eliminates problems when the widget tree is rebuilding
    Future.delayed(Duration.zero, () {
      isMinorUpdate = true;
      update();
    });

    if (columnsType != EKennelGridOptions.addNewMembers) {
      final field = event.column.field;
      final newValue = event.value.toString();
      // Resolve the hasher by the row's own id, NOT by event.rowIdx: the
      // grid sorts client-side (the Display Name header on the Membership
      // tab), so a row index into the unsorted list is another hasher's.
      final String publicHasherId =
          event.row.cells['publicHasherId']?.value?.toString() ?? '';
      final KennelHashersModel? hasher = displayedHashers
          .where((h) => h.publicHasherId == publicHasherId)
          .firstOrNull;
      if (hasher == null) {
        _editFeedback(
          "Couldn't find that hasher — reload the page.",
          isError: true,
        );
      } else if (field == 'eMail' &&
          (newValue == '<hidden>' ||
              event.oldValue?.toString() == '<hidden>')) {
        // A non-member's email is shown as a placeholder; typing over it
        // would send the placeholder to the server as their address.
        _editFeedback(
          'Their email is hidden because they are not a member of this '
          'kennel; it cannot be edited here.',
          isError: true,
        );
        _revertGrid();
      } else if (editableHasherFields.contains(field)) {
        await updateHasherField(hasher, field, newValue);
      }
    }

    // this trick to embed the setState in a Delay eliminates problems when the widget tree is rebuilding
    Future.delayed(Duration.zero, () {
      isMinorUpdate = false;
      update();
    });
  }

  // Fields the server accepts for a single-field update (shared by the grid and
  // the phone card list).
  static const Set<String> editableHasherFields = {
    'firstName',
    'lastName',
    'hashName',
    'eMail',
    'status',
    'emailAlerts',
    'notifications',
    'historicTotalRuns',
    'discountAmount',
    'discountPercent',
    'discountDescription',
    'historicCountsAreEstimates',
    'historicHaring',
  };

  // Persists a single field change for one hasher via updateKennelHasher. Used
  // by both the desktop grid (onGridChanged) and the phone card editors so the
  // save path is identical.
  Future<void> updateHasherField(
    KennelHashersModel hasher,
    String field,
    String newValue,
  ) async {
    final deviceId = box.get(HIVE_DEVICE_ID) as String;
    final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
    final accessToken = Utilities.generateToken(
      deviceId,
      'hcportal_updateKennelHasher',
      paramString: '$deviceSecret:${hasher.publicHasherId}',
    );

    final body = <String, dynamic>{
      'queryType': 'updateKennelHasher',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'hasherBeingEditedPublicId': hasher.publicHasherId,
      'publicKennelId': hasher.publicKennelId,
      field: newValue,
    };

    final hasherResult = await ServiceCommon.sendHttpPostToHC6Api(body);
    if (kDebugMode) {
      debugPrint(
        hasherResult is ApiError
            ? 'SP 20 [updateKennelHasher] called — FAILED'
            : 'SP 20 [updateKennelHasher] called — success',
      );
    }
    // The grid used to swallow every answer: a refused edit stayed on screen
    // as if saved, and a transport failure said nothing (Kilty, 2026-09-23).
    if (hasherResult is ApiError) {
      _editFeedback(
        "Couldn't save — check your connection and try again.",
        isError: true,
      );
      _revertGrid();
      return;
    }
    if (hasherResult case ApiSuccess(:final body)) {
      final jsonItems = json.decode(body) as List<dynamic>;
      final Map<String, dynamic>? first =
          (jsonItems.isNotEmpty && (jsonItems[0] as List<dynamic>).isNotEmpty)
          ? (jsonItems[0] as List<dynamic>)[0] as Map<String, dynamic>
          : null;
      // The SP's refusals come back as {Success: 0, ErrorMessage}.
      if (first != null && first['Success'] == 0) {
        _editFeedback(
          first['ErrorMessage'] as String? ?? "The change wasn't saved.",
          isError: true,
        );
        _revertGrid();
        return;
      }
      _applyLocalEdit(hasher.publicHasherId, field, newValue);
      _editFeedback('Saved.');
      if (jsonItems.isNotEmpty) {
        final item = first ?? <String, dynamic>{};
        if (item['hkmId'] != null) {
          final idx = hashers.indexWhere(
            (h) => h.publicHasherId == hasher.publicHasherId,
          );
          if (idx >= 0) {
            hashers[idx] = hashers[idx].copyWith(
              historicHaring: item['HistoricalHaringCount'] as int,
              historicTotalRuns: item['HistoricalTotalRunCount'] as int,
              hcHaringCount: item['HcHaringCount'] as int,
              hcTotalRunCount: item['HcTotalRunCount'] as int,
            );
            updateTrinaRows();
            gridKey = UniqueKey();
            update();
          }
        }
      }
    }
    // A field changed server-side → cache is stale; next view load refetches.
    _hashersFresh = false;
  }

  /// Keep the local model in step with a saved personal-detail edit, so a
  /// search or view switch (which rebuild the rows from the model) does not
  /// snap the cell back to the old value until the next fetch.
  void _applyLocalEdit(String publicHasherId, String field, String value) {
    final int idx = hashers.indexWhere(
      (h) => h.publicHasherId == publicHasherId,
    );
    if (idx < 0) return;
    final KennelHashersModel h = hashers[idx];
    hashers[idx] = switch (field) {
      'eMail' => h.copyWith(eMail: value),
      'firstName' => h.copyWith(firstName: value),
      'lastName' => h.copyWith(lastName: value),
      'hashName' => h.copyWith(hashName: value),
      _ => h,
    };
  }

  /// Rebuild the rows from the model, which still holds the pre-edit value.
  void _revertGrid() {
    updateTrinaRows();
    gridKey = UniqueKey();
    update();
  }

  void _editFeedback(String message, {bool isError = false}) {
    Get.snackbar(
      isError ? 'Not saved' : 'Members',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError
          ? const Color(0xFFDC2626)
          : const Color(0xFF15803D),
      colorText: Colors.white,
      duration: Duration(seconds: isError ? 6 : 2),
    );
  }

  void onGridLoaded(TrinaGridOnLoadedEvent event) {
    stateManager = event.stateManager;
  }

  Future<void> saveBulkHashers() async {
    stateManager!.setCurrentCell(rows[98].cells['firstName'], 0);
    stateManager!.setCurrentCell(rows[99].cells['firstName'], 0);
    stateManager!.gridFocusNode.unfocus(
      disposition: UnfocusDisposition.previouslyFocusedChild,
    );
    isMajorUpdate = true;
    update();

    await Future<void>.delayed(const Duration(seconds: 2));

    final newHasherList = <NewHasherModel?>[];
    // An import also sends each row's "same person?" answer.
    final List<Map<String, dynamic>> importRows = <Map<String, dynamic>>[];
    final Set<String> seenKeys = <String>{};
    for (var i = 0; i < rows.length; i++) {
      final pr = rows[i];
      final firstName = pr.cells['firstName']?.value?.toString() ?? '';
      final lastName = pr.cells['lastName']?.value?.toString() ?? '';
      var hashName = pr.cells['hashName']?.value?.toString() ?? '';
      final email = pr.cells['eMail']?.value?.toString() ?? '';
      final historicTotalRuns =
          (pr.cells['historicTotalRuns']?.value ?? 0) as int;
      final historicHaring = (pr.cells['historicHaring']?.value ?? 0) as int;

      //print('first name = ' + firstName + ', row = ' + i.toString());
      //print('email = ' + email + ', row = ' + i.toString());
      if (fromImport) {
        // An import keeps a row with no email (it gets a placeholder) but
        // needs a hash name or a first and last name.
        if (hashName.trim().isEmpty && (firstName.trim().isEmpty || lastName.trim().isEmpty)) {
          continue;
        }
      } else if ((firstName.isEmpty) || (email.isEmpty)) {
        continue;
      }

      if (hashName.isEmpty) {
        hashName = 'Just $firstName';
      }
      final String key = email.isNotEmpty ? 'e:${email.toLowerCase()}' : 'n:${hashName.toLowerCase()}|${firstName.toLowerCase()}|${lastName.toLowerCase()}';

      final nh = NewHasherModel(
        firstName: firstName,
        lastName: lastName,
        hashName: hashName,
        eMail: email,
        publicKennelId: kennel.publicKennelId,
        historicTotalRuns: historicTotalRuns,
        historicHaring: historicHaring,
      );
      // make sure duplicates are not sent to the server (by email, or by
      // name for an imported row that has none)
      if (seenKeys.add(key)) {
        newHasherList.add(nh);
        if (fromImport) {
          importRows.add(<String, dynamic>{...nh.toJson(), ...?importMatches[i]});
        }
      }
    }

    if (newHasherList.isNotEmpty) {
      final newHasherJson = fromImport ? jsonEncode(importRows) : jsonEncode(newHasherList);
      //print(newHasherJson);

      final deviceId = box.get(HIVE_DEVICE_ID) as String;
      final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
      final accessToken = Utilities.generateToken(
        deviceId,
        'hcportal_bulkAddHashers',
        paramString: '$deviceSecret:${kennel.publicKennelId}',
      );

      final body = <String, dynamic>{
        'queryType': 'bulkAddHashers',
        'deviceId': deviceId,
        'accessToken': accessToken,
        'publicKennelId': kennel.publicKennelId,
        'newHasherJson': newHasherJson,
        if (fromImport) 'fromImport': 1,
      };
      final bulkResult = await ServiceCommon.sendHttpPostToHC6Api(body);
      if (kDebugMode) {
        debugPrint(
          bulkResult is ApiError
              ? 'SP 3 [bulkAddHashers] called — FAILED'
              : 'SP 3 [bulkAddHashers] called — success',
        );
      }

      newHashers.clear();

      if (bulkResult is! ApiSuccess) return;
      final decodedJson = json.decode(bulkResult.body) as List<dynamic>;
      final jsonGroup = (decodedJson[0] as List)
          .map<Map<String, dynamic>>((e) => e as Map<String, dynamic>)
          .toList();
      for (final item in jsonGroup) {
        final hasher = NewHasherModel.fromJson(item);
        newHashers.add(hasher);
      }

      if (fromImport) {
        // What the import did, and who the invite button should write to.
        int added = 0, linked = 0, already = 0, countsUpdated = 0, emailUpdated = 0, emailKept = 0, noEmail = 0, failed = 0;
        lastImportedPublicHasherIds.clear();
        for (final NewHasherModel h in newHashers) {
          switch (h.addHasherStatus) {
            case 'NEW HC USER':
              added++;
            case 'NEW MEMBER':
              linked++;
            case 'ALREADY IN KENNEL':
              already++;
            case 'RUN COUNTS UPDATED':
              already++;
              countsUpdated++;
            case 'EMAIL UPDATED':
              already++;
              emailUpdated++;
            case 'EMAIL NOT CHANGED':
              already++;
              emailKept++;
            case 'ERROR':
              failed++;
          }
          if ((h.addHasherStatus == 'NEW HC USER' || h.addHasherStatus == 'NEW MEMBER') &&
              (h.publicHasherId ?? '').isNotEmpty) {
            lastImportedPublicHasherIds.add(h.publicHasherId!);
            if (isGeneratedEmail(h.eMail)) noEmail++;
          }
        }
        fromImport = false;
        importMatches.clear();
        unawaited(Utilities.showAlert(
          'Import saved',
          '$added new ${added == 1 ? 'hasher' : 'hashers'} added; $linked existing '
          '${linked == 1 ? 'account' : 'accounts'} linked to ${kennel.kennelShortName}.'
          '${already > 0 ? '~~$already ${already == 1 ? 'hasher is' : 'hashers are'} already in this kennel — nothing changed but their previous run counts${countsUpdated > 0 ? ' (updated for $countsUpdated)' : ''}.' : ''}'
          '${emailUpdated > 0 ? '~~$emailUpdated email ${emailUpdated == 1 ? 'address' : 'addresses'} updated.' : ''}'
          '${emailKept > 0 ? '~~$emailKept email ${emailKept == 1 ? 'address was' : 'addresses were'} not changed: they have signed in, or the address belongs to another account.' : ''}'
          '${noEmail > 0 ? '~~$noEmail without an email address cannot be emailed an invite.' : ''}'
          '${failed > 0 ? '~~$failed ${failed == 1 ? 'row' : 'rows'} could not be added.' : ''}'
          '~~Everyone added has an invite code. Press Email invite codes to send them.',
          'OK',
        ));
      }

      await prepareGridForAddingNewMembers();
    }
    // New members were added → other views must refetch to include them.
    _hashersFresh = false;
    isMajorUpdate = false;
    update();
  }
}

class KennelHashersPage extends StatelessWidget {
  const KennelHashersPage(this.kennel, {super.key});

  final HasherKennelsModel kennel;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<KennelHashersController>(
      init: KennelHashersController(kennel),
      builder: (c) => Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          title: Text(
            'Kennel Members and Followers for ${c.kennel.kennelName}',
          ),
          leading: GestureDetector(
            onTap: () => Get.back<void>(),
            child: const Icon(
              MaterialCommunityIcons.arrow_left,
              color: Colors.black,
            ),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            c.updateSizeWithDebounce(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            // Same infra as the editors: vertical rail (wide) / hamburger
            // (narrow) drives the selected view; content sits beside/below it.
            return TabRailScaffold<KennelHashersController>(
              controller: c,
              railColor: railColorKennelHashers,
              narrowTabBar: ResponsiveTabBar<KennelHashersController>(
                controller: c,
                formKey: c.hashersFormKey,
                tabBarColor: railColorKennelHashers,
              ),
              tabBarView: _KennelHashersContent(controller: c),
            );
          },
        ),
      ),
    );
  }
}

// Content shown beside the rail (wide) / below the hamburger (narrow): the
// heading plus the data grid (wide) or member card list (narrow) for the
// currently selected view.
class _KennelHashersContent extends StatelessWidget {
  const _KennelHashersContent({required this.controller});

  final KennelHashersController controller;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<KennelHashersController>(
      builder: (c) => Obx(() {
        final useCards =
            c.screenSize.value != EScreenSize.isNormalScreen &&
            c.columnsType != EKennelGridOptions.addNewMembers;
        return Container(
          color: const Color(0xFFF1F5F9),
          padding: EdgeInsets.fromLTRB(
            useCards ? 10 : 16,
            12,
            useCards ? 10 : 16,
            8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // The description is no longer shown inline on any screen size —
              // it lives behind the (i) info button on the heading bar below
              // (James' request).
              Container(
                color: Colors.blue.shade900,
                width: double.infinity,
                height: useCards ? 38 : 44,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 36),
                    Expanded(
                      child: Center(
                        child: Text(
                          c.tableHeadingText +
                              ((c.isMinorUpdate || c.isMajorUpdate)
                                  ? ' (Updating)'
                                  : ''),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'AvenirNextBold',
                            fontSize: useCards ? 16 : 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 36,
                      child: c.descriptionText.isEmpty
                          ? null
                          : IconButton(
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              tooltip: 'About this view',
                              icon: const Icon(
                                Icons.info_outline,
                                color: Colors.white,
                                size: 22,
                              ),
                              onPressed: () => _showInfoDialog(context, c),
                            ),
                    ),
                  ],
                ),
              ),
              if (c.columnsType != EKennelGridOptions.addNewMembers)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: TextField(
                    controller: c.searchController,
                    onChanged: c.onSearchChanged,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search by name or hash name…',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: c.searchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: c.clearSearch,
                            ),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: useCards
                    ? _buildMemberCards(c)
                    : Stack(
                        children: <Widget>[
                          TrinaGrid(
                            configuration: TrinaGridConfiguration(
                              style: TrinaGridStyleConfig(
                                rowHeight:
                                    c.columnsType == EKennelGridOptions.photos
                                    ? KennelHashersController.photoRowHeight
                                    : KennelHashersController.standardRowHeight,
                              ),
                            ),
                            key: c.gridKey,
                            columns: c.columns,
                            rows: c.rows,
                            onChanged: (event) async {
                              await c.onGridChanged(event);
                            },
                            onLoaded: (event) {
                              c.onGridLoaded(event);
                            },
                          ),
                          if (c.isMajorUpdate || c.isLoading) ...<Widget>[
                            Container(
                              color: Colors.white70,
                              height: 10000,
                              width: 10000,
                            ),
                            Center(
                              child: SpinKitCircle(color: Colors.red.shade900),
                            ),
                          ],
                        ],
                      ),
              ),
              GeneratedEmailNote(show: !useCards && c.gridShowsGeneratedEmail),
              if (c.columnsType ==
                  EKennelGridOptions.addNewMembers) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: OverflowBar(
                    alignment: MainAxisAlignment.end,
                    spacing: 10,
                    children: <Widget>[
                      // E2.F2.S6: a member list in any form → the grid, and
                      // invite codes emailed from the kennel.
                      HcButton.secondary(
                        label: c.isReadingFile ? 'Reading the file…' : 'Import from file',
                        icon: Icons.upload_file,
                        onPressed: c.isReadingFile ? null : c.importFromFile,
                      ),
                      HcButton.secondary(
                        label: 'Email invite codes',
                        icon: Icons.forward_to_inbox,
                        onPressed: c.isReadingFile ? null : c.emailInviteCodes,
                      ),
                      ElevatedButton(
                        child: const Text(
                          'Save',
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        onPressed: () async {
                          await c.saveBulkHashers();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  void _showInfoDialog(BuildContext context, KennelHashersController c) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(KennelHashersController.viewTitle(c.columnsType)),
          content: SingleChildScrollView(
            child: Text(
              c.descriptionText,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          ),
          actions: [
            HcButton.secondary(
              label: 'Close',
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SpinKitCircle(color: Colors.red.shade900, size: 40),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildMemberCards(KennelHashersController c) {
    final list = c.displayedHashers;
    if (c.isLoading || c.isMajorUpdate) {
      return _loadingState('Loading members…');
    }
    if (list.isEmpty) {
      return Center(
        child: Text(
          c.searchTerm.trim().isNotEmpty
              ? 'No matches for "${c.searchTerm.trim()}"'
              : 'No members to show',
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _MemberCard(
        key: ValueKey('${list[i].publicHasherId}_${c.columnsType.name}'),
        hasher: list[i],
        view: c.columnsType,
        controller: c,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Phone member card — shows the current view's fields for one member, edited
// inline. Saves each field via the controller's per-field updateHasherField,
// the same path the desktop grid uses.
// ---------------------------------------------------------------------------

class _MemberCard extends StatefulWidget {
  const _MemberCard({
    required this.hasher,
    required this.view,
    required this.controller,
    super.key,
  });

  final KennelHashersModel hasher;
  final EKennelGridOptions view;
  final KennelHashersController controller;

  @override
  State<_MemberCard> createState() => _MemberCardState();
}

class _MemberCardState extends State<_MemberCard> {
  final Map<String, TextEditingController> _ctrls = {};
  final Map<String, String> _committed = {};

  TextEditingController _ctrlFor(String field, String initial) =>
      _ctrls.putIfAbsent(field, () => TextEditingController(text: initial));

  @override
  void dispose() {
    for (final ctrl in _ctrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _save(String field, String value) =>
      widget.controller.updateHasherField(widget.hasher, field, value);

  String get _title {
    final h = widget.hasher;
    final dn = (h.displayName ?? '').trim();
    if (dn.isNotEmpty) return dn;
    final hn = (h.hashName ?? '').trim();
    if (hn.isNotEmpty) return hn;
    final full = '${h.firstName ?? ''} ${h.lastName ?? ''}'.trim();
    return full.isNotEmpty ? full : '(no name)';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          ..._fieldsForView(),
        ],
      ),
    );
  }

  List<Widget> _fieldsForView() {
    final h = widget.hasher;
    switch (widget.view) {
      case EKennelGridOptions.membership:
        return [
          _dropdown('status', 'Membership', h.status, const [
            'Member',
            'Following',
            'None',
          ]),
          _readonly('Following', h.isFollowing),
        ];
      case EKennelGridOptions.nonAppHashers:
        return [
          _text('firstName', 'First name', h.firstName ?? ''),
          _text('lastName', 'Last name', h.lastName ?? ''),
          _text('hashName', 'Hash name', h.hashName ?? ''),
          _text(
            'eMail',
            'Email',
            h.eMail,
            keyboardType: TextInputType.emailAddress,
            style: emailTextStyle(h.eMail),
          ),
          _readonly('Invite code', h.inviteCode),
          if (isGeneratedEmail(h.eMail)) const GeneratedEmailNote(padding: EdgeInsets.only(top: 4)),
        ];
      case EKennelGridOptions.notificationAndEmail:
        return [
          _dropdown('notifications', 'Notifications', h.notifications, const [
            'On',
            'Off',
            'Silver Bell',
            '6 hrs before',
          ]),
          _dropdown('emailAlerts', 'Email alerts', h.emailAlerts, const [
            'Auto',
            'On',
            'Off',
          ]),
        ];
      case EKennelGridOptions.runCounts:
        return [
          _text(
            'historicTotalRuns',
            'Previous runs',
            '${h.historicTotalRuns}',
            keyboardType: TextInputType.number,
          ),
          _text(
            'historicHaring',
            'Previous harings',
            '${h.historicHaring}',
            keyboardType: TextInputType.number,
          ),
          _readonly('App runs', '${h.hcTotalRunCount}'),
          _readonly('App harings', '${h.hcHaringCount}'),
        ];
      case EKennelGridOptions.photos:
        return [_photo(h.photo)];
      case EKennelGridOptions.hashCredit:
        return [
          _text(
            'discountAmount',
            'Discount amount',
            '${h.discountAmount}',
            keyboardType: TextInputType.number,
          ),
          _text(
            'discountPercent',
            'Discount percent',
            '${h.discountPercent}',
            keyboardType: TextInputType.number,
          ),
          _text(
            'discountDescription',
            'Discount description',
            h.discountDescription ?? '',
          ),
        ];
      case EKennelGridOptions.addNewMembers:
      case EKennelGridOptions.allFields:
        return const [];
    }
  }

  Widget _fieldRow(String label, Widget field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          field,
        ],
      ),
    );
  }

  Widget _text(
    String field,
    String label,
    String initial, {
    TextInputType? keyboardType,
    TextStyle? style,
  }) {
    final ctrl = _ctrlFor(field, initial);
    _committed.putIfAbsent(field, () => initial);
    void commit() {
      final v = ctrl.text.trim();
      if (v != _committed[field]) {
        _committed[field] = v;
        unawaited(_save(field, v));
      }
    }

    return _fieldRow(
      label,
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: style,
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
        onEditingComplete: commit,
        onSubmitted: (_) => commit(),
        onTapOutside: (_) {
          FocusManager.instance.primaryFocus?.unfocus();
          commit();
        },
      ),
    );
  }

  Widget _dropdown(
    String field,
    String label,
    String value,
    List<String> options,
  ) {
    final current = options.contains(value) ? value : null;
    return _fieldRow(
      label,
      DropdownButtonFormField<String>(
        initialValue: current,
        isExpanded: true,
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
        items: [
          for (final o in options) DropdownMenuItem(value: o, child: Text(o)),
        ],
        onChanged: (nv) {
          if (nv != null && nv != value) {
            unawaited(_save(field, nv));
            setState(() {});
          }
        },
      ),
    );
  }

  Widget _readonly(String label, String value) {
    return _fieldRow(
      label,
      Text(
        value.trim().isEmpty ? '—' : value,
        style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
      ),
    );
  }

  Widget _photo(String url) {
    if (!url.contains('http')) {
      return _readonly('Photo', 'No photo');
    }
    return _fieldRow(
      'Photo',
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: HcNetworkImage(
          url,
          height: 160,
          width: 160,
          errorBuilder: (_, _, _) =>
              const Icon(Icons.person, size: 80, color: Colors.grey),
        ),
      ),
    );
  }
}
