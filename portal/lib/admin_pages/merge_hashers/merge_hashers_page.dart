import 'package:hcportal/imports.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Merge accounts (E12.F6) — HC Admin Tools › Merge accounts.
//
// One person, several accounts. The admin types one or more hash names
// (comma-separated — two records of one person often carry different names),
// sees every account that has one in a table, and marks ONE row Keep and one
// or more rows Merge (James, 2026-09-28: "we don't need to know the email
// addresses"). Preview shows each Merge account beside the Keep, with what
// overlaps; Merge then folds them into the Keep one at a time, through the
// same hcportal_mergeHashers the two-account version used.
// ---------------------------------------------------------------------------

enum MergeRole { none, keep, merge }

class MergeHashersController extends GetxController {
  final TextEditingController searchText = TextEditingController();
  final RxList<MergeCandidate> candidates = <MergeCandidate>[].obs;
  final RxMap<String, MergeRole> roles = <String, MergeRole>{}.obs;
  final RxBool searched = false.obs;

  /// One preview per Merge account, against the Keep — empty until Preview.
  final RxList<MergePreview> previews = <MergePreview>[].obs;

  /// What each merge moved, in order; filled by [merge].
  final RxList<(String, Map<String, int>)> results = <(String, Map<String, int>)>[].obs;
  final RxBool isBusy = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Changing who is kept or merged makes a preview stale.
    ever(roles, (_) => previews.clear());
  }

  @override
  void onClose() {
    searchText.dispose();
    super.onClose();
  }

  String? get keepId =>
      roles.entries.where((e) => e.value == MergeRole.keep).map((e) => e.key).firstOrNull;
  List<String> get mergeIds =>
      roles.entries.where((e) => e.value == MergeRole.merge).map((e) => e.key).toList();
  int get keepCount => roles.values.where((r) => r == MergeRole.keep).length;

  /// Why Preview is not available, or null when it is.
  String? get previewBlocker {
    if (keepCount == 0) return 'Mark one account Keep';
    if (keepCount > 1) return 'Only one account can be kept — the others merge into it';
    if (mergeIds.isEmpty) return 'Mark one or more accounts Merge';
    return null;
  }

  MergeCandidate? candidate(String id) => candidates.firstWhereOrNull((c) => c.id == id);

  Future<void> search() async {
    final List<String> terms = searchText.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (terms.isEmpty || isBusy.value) return;
    isBusy.value = true;
    results.clear();
    final List<MergeCandidate>? found = await searchHashersForMerge(terms);
    isBusy.value = false;
    if (found == null) return;
    candidates.assignAll(found);
    roles.assignAll({for (final c in found) c.id: MergeRole.none});
    searched.value = true;
  }

  void setRole(String id, MergeRole role) => roles[id] = role;

  Future<void> runPreview() async {
    final String? keep = keepId;
    if (previewBlocker != null || keep == null || isBusy.value) return;
    isBusy.value = true;
    final List<MergePreview> out = <MergePreview>[];
    for (final String m in mergeIds) {
      // The preview SP takes an email OR a hasher id in each box.
      final MergePreview? p = await previewHasherMerge(keep, m);
      if (p == null) {
        isBusy.value = false;
        return;
      }
      out.add(p);
    }
    previews.assignAll(out);
    isBusy.value = false;
  }

  /// Merges every Merge account into the Keep, one at a time; stops at the
  /// first failure (its message is shown by the standard alert), keeping what
  /// already succeeded.
  Future<void> merge() async {
    final String? keep = keepId;
    if (keep == null || previews.isEmpty || isBusy.value) return;
    isBusy.value = true;
    results.clear();
    for (final MergePreview p in previews.toList()) {
      final Map<String, int>? moved = await mergeHashers(keep, p.merge.id);
      if (moved == null) break;
      results.add((p.merge.display, moved));
    }
    isBusy.value = false;
    previews.clear();
    // Search again so the table shows the merged accounts gone.
    await search();
  }
}

class MergeHashersPage extends StatelessWidget {
  const MergeHashersPage({super.key});

  static const Color _muted = Color(0xFF6B7280);
  static const Color _warnBg = Color(0xFFFEF3C7);
  static const Color _warnText = Color(0xFF92400E);
  static const Color _keepColour = Color(0xFF15803D);
  static const Color _mergeColour = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MergeHashersController>(
      init: MergeHashersController(),
      global: false,
      builder: (c) => Scaffold(
        appBar: AppBar(
          title: const Text('Merge accounts'),
          leading: GestureDetector(
            onTap: () => Get.back<void>(),
            child: const Icon(MaterialCommunityIcons.arrow_left, color: Colors.black),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  children: [
                    const Text(
                      'When one person has several accounts, merge them: every run, payment, kennel '
                      'membership, chat message and photo moves to the account you keep, and the others '
                      'are disabled and signed out everywhere.',
                      style: TextStyle(color: _muted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: c.searchText,
                      decoration: const InputDecoration(
                        labelText: 'Hash names',
                        helperText: 'Separate several with commas, e.g. Smartarse, Smart Arse. '
                            'An email or hasher id works too.',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => c.search(),
                    ),
                    const SizedBox(height: 12),
                    Obx(() {
                      final bool busy = c.isBusy.value;
                      return HcButton.primary(
                        label: 'Find accounts',
                        icon: MaterialCommunityIcons.magnify,
                        loading: busy && c.previews.isEmpty,
                        onPressed: c.search,
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Obx(() => _results(c)),
            Obx(() => _table(c)),
            Obx(() => _previewSection(c)),
          ],
        ),
      ),
    );
  }

  // ── What the last merge did ─────────────────────────────────────────────

  Widget _results(MergeHashersController c) {
    final done = c.results.toList();
    if (done.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(MaterialCommunityIcons.check_circle, color: _keepColour, size: 32),
              const SizedBox(height: 6),
              Text(
                '${done.length == 1 ? 'Account' : '${done.length} accounts'} merged',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              for (final (name, m) in done)
                Text(
                  '$name: ${m['RunsMoved'] ?? 0} runs moved, ${m['RunsCombined'] ?? 0} combined · '
                  '${m['PaymentsMoved'] ?? 0} payments · ${m['KennelsMoved'] ?? 0} kennels moved, '
                  '${m['KennelsCombined'] ?? 0} combined · ${m['DevicesSignedOut'] ?? 0} devices signed out',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── The accounts found ──────────────────────────────────────────────────

  Widget _table(MergeHashersController c) {
    final List<MergeCandidate> rows = c.candidates.toList();
    final Map<String, MergeRole> roles = Map<String, MergeRole>.of(c.roles);
    final bool searched = c.searched.value;
    final bool busy = c.isBusy.value;
    final String? blocker = c.previewBlocker;
    if (!searched) return const SizedBox.shrink();
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('No active account has those names.', textAlign: TextAlign.center, style: TextStyle(color: _muted)),
      );
    }

    final DateFormat date = DateFormat('d MMM yyyy');
    String when(String? iso) {
      final DateTime? d = DateTime.tryParse(iso ?? '');
      return d == null ? 'never' : date.format(d.toLocal());
    }

    Widget cell(String? text, {double width = 140, bool bold = false}) => SizedBox(
      width: width,
      child: Text(
        (text == null || text.isEmpty) ? '—' : text,
        style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w600 : FontWeight.normal),
      ),
    );

    return Column(
      children: [
        Card(
          elevation: 1,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 18,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 88,
              columns: const [
                DataColumn(label: Text('Keep / Merge')),
                DataColumn(label: Text('Hash name')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Kennels followed')),
                DataColumn(label: Text('Last used app')),
                DataColumn(label: Text('Runs')),
                DataColumn(label: Text('Last runs')),
                DataColumn(label: Text('Home kennel')),
                DataColumn(label: Text('Payments')),
                DataColumn(label: Text('Created')),
              ],
              rows: [
                for (final MergeCandidate m in rows)
                  DataRow(
                    color: WidgetStatePropertyAll(switch (roles[m.id]) {
                      MergeRole.keep => const Color(0xFFDCFCE7),
                      MergeRole.merge => const Color(0xFFFEE2E2),
                      _ => null,
                    }),
                    cells: [
                      DataCell(
                        DropdownButton<MergeRole>(
                          value: roles[m.id] ?? MergeRole.none,
                          underline: const SizedBox.shrink(),
                          items: const [
                            DropdownMenuItem(value: MergeRole.none, child: Text('—')),
                            DropdownMenuItem(
                              value: MergeRole.keep,
                              child: Text('Keep', style: TextStyle(color: _keepColour, fontWeight: FontWeight.w600)),
                            ),
                            DropdownMenuItem(
                              value: MergeRole.merge,
                              child: Text('Merge', style: TextStyle(color: _mergeColour, fontWeight: FontWeight.w600)),
                            ),
                          ],
                          onChanged: busy ? null : (r) => c.setRole(m.id, r ?? MergeRole.none),
                        ),
                      ),
                      DataCell(cell(
                        m.hashName.isEmpty ? '(no hash name)' : m.hashName +
                            (m.n('IsPlatformAdmin') == 1 ? ' ★' : ''),
                        bold: true,
                        width: 150,
                      )),
                      DataCell(cell(m.name, width: 130)),
                      DataCell(cell(m.email, width: 200)),
                      DataCell(cell(
                        m.n('KennelsFollowed') == 0
                            ? '0'
                            : '${m.n('KennelsFollowed')}: ${m.s('KennelsFollowedList') ?? ''}',
                        width: 180,
                      )),
                      DataCell(cell(
                        '${when(m.s('LastAppUse'))}${m.n('SignedInDevices') > 0 ? ' · ${m.n('SignedInDevices')} signed in' : ''}',
                        width: 150,
                      )),
                      DataCell(cell('${m.n('RunsAttended')}', width: 50)),
                      DataCell(cell(m.s('RecentRuns')?.replaceAll(' · ', '\n'), width: 240)),
                      DataCell(cell(m.s('HomeKennel'), width: 100)),
                      DataCell(cell('${m.n('Payments')}', width: 70)),
                      DataCell(cell(when(m.s('CreatedAt')), width: 100)),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          blocker ?? 'Ready to preview ${c.mergeIds.length} merge${c.mergeIds.length == 1 ? '' : 's'}.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted),
        ),
        const SizedBox(height: 8),
        HcButton.primary(
          label: 'Preview merge',
          icon: MaterialCommunityIcons.eye,
          loading: busy && c.previews.isEmpty && blocker == null,
          onPressed: blocker == null ? c.runPreview : null,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Preview: each Merge account beside the Keep ─────────────────────────

  Widget _previewSection(MergeHashersController c) {
    final List<MergePreview> ps = c.previews.toList();
    final bool busy = c.isBusy.value;
    if (ps.isEmpty) return const SizedBox.shrink();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final MergePreview p in ps) ...[
              _pairView(p),
              const SizedBox(height: 20),
            ],
            Center(
              child: HcButton.destructive(
                label: ps.length == 1
                    ? 'Merge ${ps.first.merge.display} into ${ps.first.keep.display}'
                    : 'Merge ${ps.length} accounts into ${ps.first.keep.display}',
                icon: MaterialCommunityIcons.call_merge,
                loading: busy,
                onPressed: () => _confirm(c, ps),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pairView(MergePreview p) {
    final NumberFormat money = NumberFormat('#,##0.00');
    final DateFormat date = DateFormat('d MMM yyyy');
    String when(String? iso) {
      final DateTime? d = DateTime.tryParse(iso ?? '');
      return d == null ? '—' : date.format(d.toLocal());
    }

    final rows = <(String, String, String)>[
      ('Hash name', p.keep.hashName, p.merge.hashName),
      ('Email', p.keep.email, p.merge.email),
      ('Last login', when(p.keep.s('LastLoginDateTime')), when(p.merge.s('LastLoginDateTime'))),
      ('Signed-in devices', '${p.keep.n('SignedInDevices')}', '${p.merge.n('SignedInDevices')}'),
      ('Kennels followed', '${p.keep.n('KennelsFollowed')}', '${p.merge.n('KennelsFollowed')}'),
      ('Member / admin of', '${p.keep.n('KennelsMember')} / ${p.keep.n('KennelsAdmin')}',
          '${p.merge.n('KennelsMember')} / ${p.merge.n('KennelsAdmin')}'),
      ('Runs attended (hared)', '${p.keep.n('RunsAttended')} (${p.keep.n('RunsHared')})',
          '${p.merge.n('RunsAttended')} (${p.merge.n('RunsHared')})'),
      ('Payments', '${p.keep.n('Payments')} (${money.format(p.keep.d('PaymentsTotal'))})',
          '${p.merge.n('Payments')} (${money.format(p.merge.d('PaymentsTotal'))})'),
      ('Kennel credit', money.format(p.keep.d('CreditTotal')), money.format(p.merge.d('CreditTotal'))),
      ('Chat messages / photos', '${p.keep.n('ChatMessages')} / ${p.keep.n('Photos')}',
          '${p.merge.n('ChatMessages')} / ${p.merge.n('Photos')}'),
    ];

    final warnings = <String>[
      if (p.n('SharedRuns') > 0)
        '${p.n('SharedRuns')} run(s) are on both accounts — combined into one, counted once.',
      if (p.n('SharedKennels') > 0)
        '${p.n('SharedKennels')} kennel(s) are on both — the memberships are combined.',
      if (p.n('RunsBothPaid') > 0)
        'Both PAID for ${p.n('RunsBothPaid')} run(s): ${p.overlap['RunsBothPaidList'] ?? ''}. '
            'Both payments are kept — the kennel may want to refund one.',
      if (p.merge.n('SignedInDevices') > 0)
        '${p.merge.display} is signed in on ${p.merge.n('SignedInDevices')} device(s); they will be signed '
            'out and must sign in with ${p.keep.email.isEmpty ? 'the kept account' : p.keep.email}.',
      if (p.merge.n('IsPlatformAdmin') == 1) 'The account being merged is a platform admin.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Table(
              columnWidths: const {0: FlexColumnWidth(1.2), 1: FlexColumnWidth(1.5), 2: FlexColumnWidth(1.5)},
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                const TableRow(children: [
                  SizedBox.shrink(),
                  _Head('KEEP', _keepColour),
                  _Head('MERGE → disabled', _mergeColour),
                ]),
                for (final (label, k, m) in rows)
                  TableRow(children: [
                    _Cell(label, bold: true),
                    _Cell(k.isEmpty ? '—' : k),
                    _Cell(m.isEmpty ? '—' : m),
                  ]),
              ],
            ),
          ),
        ),
        for (final w in warnings)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: _warnBg, borderRadius: BorderRadius.circular(8)),
            child: Text(w, style: const TextStyle(color: _warnText, fontSize: 13)),
          ),
      ],
    );
  }

  Future<void> _confirm(MergeHashersController c, List<MergePreview> ps) async {
    final String keep = ps.first.keep.display;
    final String names = ps.map((p) => p.merge.display).join(', ');
    final bool? ok = await Get.defaultDialog<bool>(
      title: 'Merge these accounts?',
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          'Everything on $names moves to $keep, and '
          '${ps.length == 1 ? 'that account is' : 'those ${ps.length} accounts are'} disabled and '
          'signed out everywhere. This cannot be undone from the portal.',
          textAlign: TextAlign.center,
        ),
      ),
      actions: [
        HcButton.secondary(label: 'Cancel', onPressed: () => Get.back(result: false)),
        HcButton.destructive(label: 'Merge', onPressed: () => Get.back(result: true)),
      ],
    );
    if (ok == true) await c.merge();
  }
}

class _Head extends StatelessWidget {
  const _Head(this.text, this.color);
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
    child: Text(text, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
  );
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, {this.bold = false});
  final String text;
  final bool bold;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
        color: bold ? const Color(0xFF374151) : null,
      ),
    ),
  );
}
