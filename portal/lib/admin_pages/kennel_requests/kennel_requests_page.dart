import 'package:hcportal/imports.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Kennel requests (E12.F1.S5) — HC Admin Tools › Kennel requests.
// Platform admins with CanEditKennel review the kennels asking to join:
// open one to correct and approve it, or tick several and close them
// together (the spam arrives in bursts).
// ---------------------------------------------------------------------------

class KennelRequestsPage extends StatelessWidget {
  const KennelRequestsPage({super.key});

  static const Color _muted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<KennelRequestsController>(
      init: KennelRequestsController(),
      global: false,
      builder: (c) => Scaffold(
        appBar: AppBar(
          title: const Text('Kennel requests'),
          leading: GestureDetector(
            onTap: () => Get.back<void>(),
            child: const Icon(MaterialCommunityIcons.arrow_left, color: Colors.black),
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(MaterialCommunityIcons.refresh),
              onPressed: c.load,
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                _statusChips(c),
                _selectionBar(c),
                Expanded(child: _list(c)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChips(KennelRequestsController c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Obx(() {
        final current = c.status.value;
        final counts = Map<int, int>.of(c.counts);
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in KennelRequestStatus.values)
              ChoiceChip(
                label: Text('${s.label} (${counts[s.code] ?? 0})', textAlign: TextAlign.center),
                selected: s == current,
                onSelected: (_) => c.showStatus(s),
              ),
          ],
        );
      }),
    );
  }

  /// Shown while requests are ticked: close them all in one go.
  Widget _selectionBar(KennelRequestsController c) {
    return Obx(() {
      final n = c.selected.length;
      final busy = c.isBusy.value;
      final open = c.status.value.code <= 1;
      if (n == 0) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Text('$n selected', textAlign: TextAlign.center),
            if (open) ...[
              HcButton.destructive(
                label: 'Mark as spam',
                loading: busy,
                onPressed: () => c.setSelectedStatus(4),
              ),
              HcButton.secondary(
                label: 'Reject',
                onPressed: busy ? null : () => c.setSelectedStatus(3),
              ),
            ] else
              HcButton.secondary(
                label: 'Reopen',
                loading: busy,
                onPressed: () => c.setSelectedStatus(1),
              ),
            HcButton.text(label: 'Clear', onPressed: c.selected.clear),
          ],
        ),
      );
    });
  }

  Widget _list(KennelRequestsController c) {
    return Obx(() {
      final loading = c.isLoading.value;
      final items = c.requests.toList();
      final selected = c.selected.toSet();
      final status = c.status.value;
      if (loading) return const Center(child: CircularProgressIndicator());
      if (items.isEmpty) {
        return Center(
          child: Text(
            'No ${status.label.toLowerCase()} requests.',
            style: const TextStyle(color: _muted),
            textAlign: TextAlign.center,
          ),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final r = items[i];
          return _RequestTile(
            request: r,
            // An approved request made a kennel: nothing to tick.
            selectable: r.status != 2,
            selected: selected.contains(r.id),
            onToggle: () => c.toggle(r.id),
            // Reload however the page closed (its back arrow or the
            // browser's), so an approval or rejection leaves this list.
            onOpen: () async {
              await Get.to<void>(() => KennelRequestDetailPage(request: r));
              await c.load();
            },
          );
        },
      );
    });
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.request,
    required this.selectable,
    required this.selected,
    required this.onToggle,
    required this.onOpen,
  });

  final KennelRequestModel request;
  final bool selectable;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  static const Color _muted = Color(0xFF6B7280);
  static const Color _warn = Color(0xFFB45309);

  @override
  Widget build(BuildContext context) {
    final r = request;
    final when = r.submittedOn == null ? '' : DateFormat('d MMM yyyy').format(r.submittedOn!.toLocal());
    final place = [
      r.cityName ?? r.cityText,
      r.regionName ?? r.regionText,
      r.countryName ?? r.countryText,
    ].whereType<String>().where((s) => s.isNotEmpty).join(', ');
    final warnings = <String>[
      if (r.similarKennels != null) 'Similar: ${r.similarKennels}',
      if (r.isOpen && !r.locationIsResolved) 'Location to pick',
      if (r.isOpen && !r.shortNameIsValid) 'Short name to fix',
      if (r.existingHashName != null) 'Has an account: ${r.existingHashName}',
    ];

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectable)
                Checkbox(value: selected, onChanged: (_) => onToggle())
              else
                const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${r.kennelName}  ·  ${r.kennelShortName}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [place, r.requesterName, r.email, when].where((s) => s.isNotEmpty).join('  ·  '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: _muted),
                      ),
                      if (warnings.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          warnings.join('  ·  '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: _warn),
                        ),
                      ],
                      if (r.reviewNote != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Note: ${r.reviewNote}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: _muted),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Icon(MaterialCommunityIcons.chevron_right, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
