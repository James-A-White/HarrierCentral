import 'package:hcportal/imports.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Platform admins (E12.F7) — HC Admin Tools › Platform admins.
//
// HC.PlatformAdmin is the platform's only staff list: who moderates rooms
// and DMs, merges accounts, reads the monitor, shapes permissions. Until
// 2026-09-30 it was seeded by hand in SQL. This screen lists the admins with
// their four capabilities as switches, removes one, and mints a new one by
// finding the person the way Merge accounts does (James, 2026-09-30).
// Only a platform admin with Manage permissions sees the tile.
// ---------------------------------------------------------------------------

class PlatformAdminsController extends GetxController {
  final TextEditingController searchText = TextEditingController();
  final RxList<PlatformAdmin> admins = <PlatformAdmin>[].obs;
  final RxList<MergeCandidate> candidates = <MergeCandidate>[].obs;
  final RxBool searched = false.obs;
  final RxBool isBusy = false.obs;
  final RxBool loaded = false.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  @override
  void onClose() {
    searchText.dispose();
    super.onClose();
  }

  Future<void> load() async {
    final List<PlatformAdmin>? rows = await getPlatformAdmins();
    if (isClosed) return;
    if (rows != null) admins.assignAll(rows);
    loaded.value = true;
  }

  Future<void> search() async {
    final List<String> terms = searchText.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (terms.isEmpty || isBusy.value) return;
    isBusy.value = true;
    final List<MergeCandidate>? found = await searchHashersForMerge(terms);
    if (isClosed) return;
    isBusy.value = false;
    if (found == null) return;
    // People already on the list are not candidates for minting.
    final Set<String> already = admins.map((a) => a.id).toSet();
    candidates.assignAll(found.where((c) => !already.contains(c.id)));
    searched.value = true;
  }

  Future<void> mint(MergeCandidate c) async {
    if (isBusy.value) return;
    isBusy.value = true;
    // A new admin starts with the everyday capabilities; Permissions &
    // admins is handed out deliberately, with its own switch.
    final bool ok = await setPlatformAdmin(
      c.id,
      capabilities: {
        PlatformCapability.viewMonitor: true,
        PlatformCapability.manageNewsflash: true,
        PlatformCapability.editKennel: true,
        PlatformCapability.managePermissions: false,
      },
    );
    if (isClosed) return;
    if (ok) {
      candidates.removeWhere((x) => x.id == c.id);
      await load();
    }
    isBusy.value = false;
  }

  Future<void> toggle(PlatformAdmin a, PlatformCapability cap, bool on) async {
    if (isBusy.value) return;
    isBusy.value = true;
    final bool ok = await setPlatformAdmin(a.id, capabilities: {cap: on});
    if (isClosed) return;
    if (ok) await load();
    isBusy.value = false;
  }

  Future<void> remove(PlatformAdmin a) async {
    if (isBusy.value) return;
    isBusy.value = true;
    final bool ok = await setPlatformAdmin(a.id, removed: true);
    if (isClosed) return;
    if (ok) await load();
    isBusy.value = false;
  }
}

class PlatformAdminsPage extends StatelessWidget {
  const PlatformAdminsPage({super.key});

  static const Color _muted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PlatformAdminsController>(
      init: PlatformAdminsController(),
      global: false,
      builder: (c) => Scaffold(
        appBar: AppBar(
          title: const Text('Platform admins'),
          leading: GestureDetector(
            onTap: () => Get.back<void>(),
            child: const Icon(
              MaterialCommunityIcons.arrow_left,
              color: Colors.black,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  children: [
                    const Text(
                      'Platform admins are Harrier Central staff, not kennel admins: they can moderate '
                      'every chat room and direct message, merge accounts, read the monitor and set '
                      'permission defaults. Each switch is one capability; Permissions & admins is the '
                      'one that lets a person use this screen.',
                      style: TextStyle(color: _muted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    _AdminsTable(c: c),
                    const SizedBox(height: 28),
                    const Text(
                      'Add a platform admin',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: c.searchText,
                      decoration: const InputDecoration(
                        labelText: 'Hash name or real name',
                        helperText:
                            'Several names can be separated by commas. An email or hasher id works too.',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => c.search(),
                    ),
                    const SizedBox(height: 12),
                    Obx(() {
                      final bool busy = c.isBusy.value;
                      return HcButton.primary(
                        label: 'Find accounts',
                        onPressed: busy ? null : c.search,
                      );
                    }),
                    const SizedBox(height: 16),
                    _CandidatesTable(c: c),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminsTable extends StatelessWidget {
  const _AdminsTable({required this.c});
  final PlatformAdminsController c;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final List<PlatformAdmin> rows = c.admins.toList();
      final bool busy = c.isBusy.value;
      if (!c.loaded.value) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final DateFormat date = DateFormat('d MMM yyyy');
      return Card(
        elevation: 1,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 18,
            dataRowMinHeight: 52,
            dataRowMaxHeight: 64,
            columns: [
              const DataColumn(label: Text('Hash name')),
              const DataColumn(label: Text('Name')),
              const DataColumn(label: Text('Home kennel')),
              for (final PlatformCapability cap in PlatformCapability.values)
                DataColumn(label: Text(cap.label)),
              const DataColumn(label: Text('Since')),
              const DataColumn(label: Text('')),
            ],
            rows: [
              for (final PlatformAdmin a in rows)
                DataRow(
                  cells: [
                    DataCell(
                      Text(
                        a.hashName.isEmpty
                            ? '(no hash name)'
                            : a.hashName + (a.isSelf ? '  (you)' : ''),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DataCell(Text(a.name.isEmpty ? '—' : a.name)),
                    DataCell(Text(a.homeKennel.isEmpty ? '—' : a.homeKennel)),
                    for (final PlatformCapability cap
                        in PlatformCapability.values)
                      DataCell(
                        Switch(
                          value: a.has(cap),
                          // The SP refuses these too; greying the switch says why
                          // before the click rather than after.
                          onChanged:
                              busy ||
                                  (a.isSelf &&
                                      cap ==
                                          PlatformCapability.managePermissions)
                              ? null
                              : (v) => c.toggle(a, cap, v),
                        ),
                      ),
                    DataCell(
                      Text(
                        a.since == null ? '—' : date.format(a.since!.toLocal()),
                      ),
                    ),
                    DataCell(
                      a.isSelf
                          ? const Tooltip(
                              message:
                                  'Ask another platform admin to remove you',
                              child: Text(
                                '—',
                                style: TextStyle(
                                  color: PlatformAdminsPage._muted,
                                ),
                              ),
                            )
                          : HcButton.destructive(
                              label: 'Remove',
                              onPressed: busy
                                  ? null
                                  : () => _confirmRemove(context, c, a),
                            ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _confirmRemove(
    BuildContext context,
    PlatformAdminsController c,
    PlatformAdmin a,
  ) async {
    final bool? ok = await Get.defaultDialog<bool>(
      title: 'Remove ${a.display} as a platform admin?',
      content: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          'They keep their account and every kennel role; they lose the platform tools, '
          'the Platform Admins room, and the power to moderate rooms and direct messages.',
          textAlign: TextAlign.center,
        ),
      ),
      actions: [
        HcButton.secondary(
          label: 'Cancel',
          onPressed: () => Get.back(result: false),
        ),
        HcButton.destructive(
          label: 'Remove',
          onPressed: () => Get.back(result: true),
        ),
      ],
    );
    if (ok == true) await c.remove(a);
  }
}

class _CandidatesTable extends StatelessWidget {
  const _CandidatesTable({required this.c});
  final PlatformAdminsController c;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final List<MergeCandidate> rows = c.candidates.toList();
      final bool searched = c.searched.value;
      final bool busy = c.isBusy.value;
      if (!searched) return const SizedBox.shrink();
      if (rows.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'No active account has those names (or they are already platform admins).',
            textAlign: TextAlign.center,
            style: TextStyle(color: PlatformAdminsPage._muted),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
      Card(
        elevation: 1,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 18,
            columns: const [
              DataColumn(label: Text('Hash name')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Home kennel')),
              DataColumn(label: Text('Runs')),
              DataColumn(label: Text('')),
            ],
            rows: [
              for (final MergeCandidate m in rows)
                DataRow(
                  cells: [
                    DataCell(
                      Text(
                        m.hashName.isEmpty ? '(no hash name)' : m.hashName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DataCell(Text(m.name.isEmpty ? '—' : m.name)),
                    DataCell(Text(m.email.isEmpty ? '—' : m.email, style: emailTextStyle(m.email))),
                    DataCell(Text(m.s('HomeKennel') ?? '—')),
                    DataCell(Text('${m.n('RunsAttended')}')),
                    DataCell(
                      HcButton.primary(
                        label: 'Make platform admin',
                        onPressed: busy
                            ? null
                            : () => _confirmMint(context, c, m),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
          // The dark-red note, when an address listed is one we made up.
          GeneratedEmailNote(show: rows.any((MergeCandidate m) => isGeneratedEmail(m.email))),
        ],
      );
    });
  }

  Future<void> _confirmMint(
    BuildContext context,
    PlatformAdminsController c,
    MergeCandidate m,
  ) async {
    final bool? ok = await Get.defaultDialog<bool>(
      title: 'Make ${m.display} a platform admin?',
      content: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          'They will be able to moderate every chat room and direct message, merge accounts, '
          'edit any kennel and read the monitor. Permissions & admins stays off until you '
          'switch it on for them.',
          textAlign: TextAlign.center,
        ),
      ),
      actions: [
        HcButton.secondary(
          label: 'Cancel',
          onPressed: () => Get.back(result: false),
        ),
        HcButton.primary(
          label: 'Make platform admin',
          onPressed: () => Get.back(result: true),
        ),
      ],
    );
    if (ok == true) await c.mint(m);
  }
}
