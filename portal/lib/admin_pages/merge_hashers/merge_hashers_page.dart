import 'package:hcportal/imports.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Merge accounts (E12.F6) — HC Admin Tools › Merge accounts.
// One person, two accounts: the admin enters the email of the account to
// keep and of the one to merge, sees both side by side with what overlaps,
// and only then merges. The merged account is disabled.
// ---------------------------------------------------------------------------

class MergeHashersController extends GetxController {
  final TextEditingController keepEmail = TextEditingController();
  final TextEditingController mergeEmail = TextEditingController();
  final Rxn<MergePreview> preview = Rxn<MergePreview>();
  final Rxn<Map<String, int>> result = Rxn<Map<String, int>>();
  final RxBool isBusy = false.obs;

  @override
  void onInit() {
    super.onInit();
    // A changed address makes the preview stale: it must be run again.
    keepEmail.addListener(_invalidate);
    mergeEmail.addListener(_invalidate);
  }

  @override
  void onClose() {
    keepEmail.dispose();
    mergeEmail.dispose();
    super.onClose();
  }

  void _invalidate() {
    if (preview.value != null) preview.value = null;
  }

  Future<void> runPreview() async {
    if (isBusy.value) return;
    result.value = null;
    isBusy.value = true;
    preview.value = await previewHasherMerge(keepEmail.text.trim(), mergeEmail.text.trim());
    isBusy.value = false;
  }

  Future<bool> merge() async {
    final p = preview.value;
    if (p == null || isBusy.value) return false;
    isBusy.value = true;
    final moved = await mergeHashers(p.keep.id, p.merge.id);
    isBusy.value = false;
    if (moved == null) return false;
    result.value = moved;
    preview.value = null;
    return true;
  }

  void startOver() {
    keepEmail.clear();
    mergeEmail.clear();
    preview.value = null;
    result.value = null;
  }
}

class MergeHashersPage extends StatelessWidget {
  const MergeHashersPage({super.key});

  static const Color _muted = Color(0xFF6B7280);
  static const Color _warnBg = Color(0xFFFEF3C7);
  static const Color _warnText = Color(0xFF92400E);

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
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              children: [
                const Text(
                  'When one person has two accounts, merge them: every run, payment, kennel '
                  'membership, chat message and photo of the second account moves to the first, '
                  'and the second account is disabled and signed out everywhere.',
                  style: TextStyle(color: _muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: c.keepEmail,
                  decoration: const InputDecoration(
                    labelText: 'Email of the account to KEEP',
                    helperText: 'Or paste its hasher id if it has no email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: c.mergeEmail,
                  decoration: const InputDecoration(
                    labelText: 'Email of the account to MERGE into it (then disabled)',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => c.runPreview(),
                ),
                const SizedBox(height: 18),
                Obx(() {
                  final busy = c.isBusy.value;
                  final hasPreview = c.preview.value != null;
                  return Center(
                    child: HcButton.primary(
                      label: hasPreview ? 'Preview again' : 'Preview merge',
                      icon: MaterialCommunityIcons.magnify,
                      loading: busy && !hasPreview,
                      onPressed: c.runPreview,
                    ),
                  );
                }),
                const SizedBox(height: 24),
                Obx(() {
                  final p = c.preview.value;
                  final done = c.result.value;
                  final busy = c.isBusy.value;
                  if (done != null) return _done(c, done);
                  if (p == null) return const SizedBox.shrink();
                  return _previewView(context, c, p, busy);
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _previewView(BuildContext context, MergeHashersController c, MergePreview p, bool busy) {
    final money = NumberFormat('#,##0.00');
    final date = DateFormat('d MMM yyyy');
    String when(String? iso) {
      final d = DateTime.tryParse(iso ?? '');
      return d == null ? '—' : date.format(d.toLocal());
    }

    final rows = <(String, String, String)>[
      ('Hash name', p.keep.hashName, p.merge.hashName),
      ('Name', p.keep.name, p.merge.name),
      ('Email', p.keep.email, p.merge.email),
      ('Home kennel', p.keep.s('HomeKennelName') ?? '—', p.merge.s('HomeKennelName') ?? '—'),
      ('Created', when(p.keep.s('CreatedAt')), when(p.merge.s('CreatedAt'))),
      ('Last login', when(p.keep.s('LastLoginDateTime')), when(p.merge.s('LastLoginDateTime'))),
      ('Signed-in devices', '${p.keep.n('SignedInDevices')}', '${p.merge.n('SignedInDevices')}'),
      ('Kennels followed', '${p.keep.n('KennelsFollowed')}', '${p.merge.n('KennelsFollowed')}'),
      ('Member of', '${p.keep.n('KennelsMember')}', '${p.merge.n('KennelsMember')}'),
      ('Admin of', '${p.keep.n('KennelsAdmin')}', '${p.merge.n('KennelsAdmin')}'),
      ('Runs attended', '${p.keep.n('RunsAttended')}', '${p.merge.n('RunsAttended')}'),
      ('Runs hared', '${p.keep.n('RunsHared')}', '${p.merge.n('RunsHared')}'),
      ('Last run', when(p.keep.s('LastRunLocal')), when(p.merge.s('LastRunLocal'))),
      ('PackTrack trails', '${p.keep.n('Tracks')}', '${p.merge.n('Tracks')}'),
      ('Payments', '${p.keep.n('Payments')} (${money.format(p.keep.d('PaymentsTotal'))})',
          '${p.merge.n('Payments')} (${money.format(p.merge.d('PaymentsTotal'))})'),
      ('Kennel credit', money.format(p.keep.d('CreditTotal')), money.format(p.merge.d('CreditTotal'))),
      ('Chat messages', '${p.keep.n('ChatMessages')}', '${p.merge.n('ChatMessages')}'),
      ('Photos', '${p.keep.n('Photos')}', '${p.merge.n('Photos')}'),
      ('Platform admin', p.keep.n('IsPlatformAdmin') == 1 ? 'Yes' : 'No', p.merge.n('IsPlatformAdmin') == 1 ? 'Yes' : 'No'),
    ];

    final warnings = <String>[
      if (p.n('SharedRuns') > 0)
        '${p.n('SharedRuns')} run(s) are on both accounts (${p.n('SharedRunsBothAttended')} attended on both). '
            'They are combined into one — the run counts once.',
      if (p.n('SharedKennels') > 0)
        '${p.n('SharedKennels')} kennel(s) are on both accounts. The memberships are combined '
            '(roles and admin access kept, the larger historical run count).',
      if (p.n('RunsBothPaid') > 0)
        'Both accounts PAID for ${p.n('RunsBothPaid')} run(s): ${p.overlap['RunsBothPaidList'] ?? ''}. '
            'Both payments are kept — the kennel may want to refund one.',
      if (p.merge.n('SignedInDevices') > 0)
        '${p.merge.display} is signed in on ${p.merge.n('SignedInDevices')} device(s). They will be signed '
            'out and must sign in again with ${p.keep.email.isEmpty ? 'the kept account' : p.keep.email}.',
      if (p.merge.n('IsPlatformAdmin') == 1)
        'The account being merged is a platform admin.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Table(
              columnWidths: const {0: FlexColumnWidth(1.1), 1: FlexColumnWidth(1.5), 2: FlexColumnWidth(1.5)},
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                const TableRow(children: [
                  SizedBox.shrink(),
                  _Head('KEEP', Color(0xFF15803D)),
                  _Head('MERGE → disabled', Color(0xFFDC2626)),
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
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: _warnBg, borderRadius: BorderRadius.circular(8)),
            child: Text(w, style: const TextStyle(color: _warnText, fontSize: 13)),
          ),
        const SizedBox(height: 20),
        Center(
          child: HcButton.destructive(
            label: 'Merge ${p.merge.display} into ${p.keep.display}',
            icon: MaterialCommunityIcons.call_merge,
            loading: busy,
            onPressed: () => _confirm(c, p),
          ),
        ),
      ],
    );
  }

  Future<void> _confirm(MergeHashersController c, MergePreview p) async {
    final ok = await Get.defaultDialog<bool>(
      title: 'Merge these accounts?',
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          'Everything on ${p.merge.display} (${p.merge.email}) moves to ${p.keep.display} '
          '(${p.keep.email}), and ${p.merge.display} is disabled and signed out everywhere. '
          'This cannot be undone from the portal.',
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

  Widget _done(MergeHashersController c, Map<String, int> moved) {
    final lines = <String>[
      '${moved['RunsMoved'] ?? 0} runs moved, ${moved['RunsCombined'] ?? 0} combined',
      '${moved['PaymentsMoved'] ?? 0} payments moved',
      '${moved['KennelsMoved'] ?? 0} kennels moved, ${moved['KennelsCombined'] ?? 0} combined',
      '${moved['ChatMessagesMoved'] ?? 0} chat messages and ${moved['PhotosMoved'] ?? 0} photos moved',
      '${moved['DevicesSignedOut'] ?? 0} devices signed out',
    ];
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(MaterialCommunityIcons.check_circle, color: Color(0xFF15803D), size: 40),
            const SizedBox(height: 8),
            const Text('Accounts merged', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            for (final l in lines) Text(l, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            HcButton.secondary(label: 'Merge another pair', onPressed: c.startOver),
          ],
        ),
      ),
    );
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
      style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          color: bold ? const Color(0xFF374151) : null),
    ),
  );
}
