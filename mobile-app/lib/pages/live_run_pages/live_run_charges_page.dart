import 'package:harrier_central/imports.dart';
import 'package:harrier_central/pages/run_admin/add_down_down_page.dart';
import 'package:harrier_central/pages/run_admin/edit_down_down_page.dart';

/// The live run's Charges tab. Stateless over [LiveRunChargesController].
class LiveRunChargesPage extends StatelessWidget {
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

  Future<void> _openEditPage(
    LiveRunChargesController c,
    DownDownModel dd,
  ) async {
    final saved = await Get.to<bool>(
      () => EditDownDownPage(
        kennelId: kennelId,
        eventId: eventId,
        kennelSlug: kennelSlug,
        eventNumber: eventNumber,
        downDown: dd,
      ),
    );
    if (saved == true) unawaited(c.load());
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LiveRunChargesController>(
      init: LiveRunChargesController(kennelId: kennelId, eventId: eventId),
      tag: LiveRunChargesController.tagFor(eventId),
      builder: (LiveRunChargesController c) {
        final content = Container(
          decoration: Backgrounds.defaultHcBackground(),
          child: Obx(() {
            if (c.isLoading.value) {
              return const HcAppCircularProgressIndicator(
                key: Key('charges_loading'),
              );
            }
            final List<DownDownModel> charges = c.charges;
            return RefreshIndicator(
              onRefresh: c.load,
              child: charges.isEmpty
                  ? ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(30),
                          child: Center(
                            child: Text(
                              'No charges yet for this run.\nPull to refresh or tap + to add one.',
                              textAlign: TextAlign.center,
                              style: ts_headingLarge.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 80, top: 8),
                      itemCount: charges.length,
                      separatorBuilder: (context, i) => Divider(
                        height: 2,
                        thickness: 1.5,
                        color: Colors.lightBlueAccent.withValues(alpha: 0.7),
                      ),
                      itemBuilder: (context, index) {
                        final dd = charges[index];
                        final names = dd.allChargedNames.join(', ');
                        return _ChargeTile(
                          dd: dd,
                          hasherNames: names,
                          onEdit: () => unawaited(_openEditPage(c, dd)),
                        );
                      },
                    ),
            );
          }),
        );

        return Stack(
          children: [
            content,
            Obx(() {
              if (!c.canManageCharges.value) return const SizedBox.shrink();
              return Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black87,
                  onPressed: () async {
                    await Get.to(
                      () => AddDownDownPage(
                        kennelId: kennelId,
                        eventId: eventId,
                        eventName: eventName,
                      ),
                    );
                    unawaited(c.load());
                  },
                  child: const Icon(Icons.add),
                ),
              );
            }),
          ],
        );
      },
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
