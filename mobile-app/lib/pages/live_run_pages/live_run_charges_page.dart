import 'package:harrier_central/imports.dart';
import 'package:harrier_central/pages/run_admin/add_down_down_page.dart';
import 'package:harrier_central/pages/run_admin/edit_down_down_page.dart';

class LiveRunChargesPage extends StatefulWidget {
  const LiveRunChargesPage({
    super.key,
    required this.kennelId,
    required this.eventId,
    required this.eventName,
    required this.kennelSlug,
    required this.eventNumber,
  });

  final String kennelId;
  final String eventId;
  final String eventName;
  final String kennelSlug;
  final int eventNumber;

  @override
  State<LiveRunChargesPage> createState() => _LiveRunChargesPageState();
}

class _LiveRunChargesPageState extends State<LiveRunChargesPage> {
  final _service = RunContentService();

  bool _isLoading = true;
  bool _canManageCharges = false;
  List<DownDownModel> _charges = [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    // Gate the add/edit affordances to those who can manage down downs (the
    // server also enforces this; getDownDowns returns nothing to non-managers).
    final kennelAgg = await QueryKennels.getSingleKennel(widget.kennelId);
    _canManageCharges = canAccessFeature(
      KennelFeature.manageDownDowns,
      appAccessFlags: kennelAgg?.hkm?.appAccessFlags ?? 0,
      mismanagementRoles: kennelAgg?.hkm?.mismanagementRoles ?? 0,
      kennelOverrideJson: kennelAgg?.kennel.permissionOverrideJson,
    );
    try {
      final result = await _service.getDownDowns(
        kennelId: widget.kennelId,
        eventId: widget.eventId,
      );
      if (result != null && mounted) {
        final all = result.downDowns;
        for (final dd in all) {
          dd.hashers = result.hashers
              .where((h) => h.downDownId == dd.downDownId)
              .toList();
        }
        setState(() => _charges = all);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Failed to load charges'), backgroundColor: Colors.red.shade700),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _openEditPage(DownDownModel dd) async {
    final saved = await Get.to<bool>(
      () => EditDownDownPage(
        kennelId: widget.kennelId,
        eventId: widget.eventId,
        kennelSlug: widget.kennelSlug,
        eventNumber: widget.eventNumber,
        downDown: dd,
      ),
    );
    if (saved == true && mounted) unawaited(_load());
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: Backgrounds.defaultHcBackground(),
      child: _isLoading
          ? const HcAppCircularProgressIndicator(key: Key('charges_loading'))
          : RefreshIndicator(
              onRefresh: _load,
              child: _charges.isEmpty
                  ? ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(30),
                          child: Center(
                            child: Text(
                              'No charges yet for this run.\nPull to refresh or tap + to add one.',
                              textAlign: TextAlign.center,
                              style: ts_headingLarge.copyWith(color: Colors.white70),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 80, top: 8),
                      itemCount: _charges.length,
                      separatorBuilder: (context, i) => Divider(height: 2, thickness: 1.5, color: Colors.lightBlueAccent.withValues(alpha: 0.7)),
                      itemBuilder: (context, index) {
                        final dd = _charges[index];
                        final names = dd.allChargedNames.join(', ');
                        return _ChargeTile(
                          dd: dd,
                          hasherNames: names,
                          onEdit: () => _openEditPage(dd),
                        );
                      },
                    ),
            ),
    );

    return Stack(
      children: [
        content,
        if (_canManageCharges)
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            backgroundColor: Colors.yellow,
            foregroundColor: Colors.black87,
            onPressed: () async {
              await Get.to(
                () => AddDownDownPage(
                  kennelId: widget.kennelId,
                  eventId: widget.eventId,
                  eventName: widget.eventName,
                ),
              );
              unawaited(_load());
            },
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _ChargeTile extends StatelessWidget {
  const _ChargeTile({
    required this.dd,
    required this.hasherNames,
    required this.onEdit,
  });

  final DownDownModel dd;
  final String hasherNames;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasherNames.isNotEmpty)
                  Text(
                    hasherNames,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.yellow,
                    ),
                  ),
                Text(
                  'by ${dd.createdByDisplayName}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    color: Colors.yellow,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dd.chargeText,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
                if (dd.songChoice != null && dd.songChoice!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Row(
                      children: [
                        const Icon(Icons.music_note, size: 13, color: Colors.white54),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            dd.songChoice!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white54,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (dd.chargePhotoUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        dd.chargePhotoUrl!,
                        height: 120,
                        width: double.infinity,
                        // Decode to the strip height, not the photo's full res.
                        cacheHeight: 360,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 22),
            color: Colors.white54,
            onPressed: onEdit,
            tooltip: 'Edit charge',
          ),
        ],
      ),
    );
  }
}
