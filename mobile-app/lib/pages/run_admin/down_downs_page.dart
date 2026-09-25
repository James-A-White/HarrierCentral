import 'package:harrier_central/imports.dart';
import 'package:harrier_central/pages/run_admin/edit_down_down_page.dart';

/// Run admin's Down Downs list. Stateless over [DownDownsController]; the
/// yes/no dialogs live here because they need a context, the actions there.
class DownDownsPage extends StatelessWidget {
  const DownDownsPage({
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

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String yes,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: ts_alertDialogTitle),
        content: Text(
          'Mark this charge as pending again?',
          style: ts_alertDialogBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeBackgroundColor,
              foregroundColor: Colors.white,
            ),
            child: Text(yes),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _handleCancelTap(
    BuildContext context,
    DownDownsController c,
    DownDownModel dd,
  ) async {
    if (dd.isCancelled) {
      if (await _confirm(
        context,
        title: 'Restore Down Down?',
        yes: 'Yes, restore',
      )) {
        await c.uncancel(dd);
      }
    } else {
      await c.cancel(dd);
    }
  }

  Future<void> _handleCheckTap(
    BuildContext context,
    DownDownsController c,
    DownDownModel dd,
  ) async {
    if (dd.isDone) {
      if (await _confirm(context, title: 'Undo Down Down?', yes: 'Yes, undo')) {
        await c.unmarkDone(dd);
      }
    } else {
      await c.markDone(dd);
    }
  }

  Future<void> _openEditPage(DownDownsController c, DownDownModel dd) async {
    final saved = await Get.to<bool>(
      () => EditDownDownPage(
        kennelId: kennelId,
        eventId: eventId,
        kennelSlug: kennelSlug,
        eventNumber: eventNumber,
        downDown: dd,
        pageTitle: 'Edit Down Down',
      ),
    );
    if (saved == true) unawaited(c.load());
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DownDownsController>(
      init: DownDownsController(kennelId: kennelId, eventId: eventId),
      tag: DownDownsController.tagFor(eventId),
      builder: (DownDownsController c) => AppScaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: themeAppBarBackground,
          iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
          title: Text('Down Downs', style: ts_appBarTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => unawaited(c.load()),
            ),
          ],
        ),
        body: Container(
          decoration: Backgrounds.defaultHcBackground(),
          child: Obx(() {
            if (c.isLoading.value) {
              return const HcAppCircularProgressIndicator(
                key: Key('dd_loading'),
              );
            }
            final List<DownDownModel> downDowns = c.downDowns;
            if (downDowns.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Text(
                    'No Down Downs yet for this run',
                    textAlign: TextAlign.center,
                    style: ts_headingLarge.copyWith(color: Colors.white),
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: downDowns.length,
              separatorBuilder: (context, i) => Divider(
                height: 2,
                thickness: 1.5,
                color: Colors.lightBlueAccent.withValues(alpha: 0.7),
              ),
              itemBuilder: (context, index) {
                final dd = downDowns[index];
                final names = dd.allChargedNames.join(', ');
                return _DownDownTile(
                  dd: dd,
                  hasherNames: names,
                  onCancelTap: () =>
                      unawaited(_handleCancelTap(context, c, dd)),
                  onCheckTap: () => unawaited(_handleCheckTap(context, c, dd)),
                  onEditTap: () => unawaited(_openEditPage(c, dd)),
                  onShareTap: dd.songId != null
                      ? () => unawaited(c.shareSong(dd))
                      : null,
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

class _DownDownTile extends StatelessWidget {
  const _DownDownTile({
    required this.dd,
    required this.hasherNames,
    required this.onCancelTap,
    required this.onCheckTap,
    required this.onEditTap,
    this.onShareTap,
  });

  final DownDownModel dd;
  final String hasherNames;
  final VoidCallback onCancelTap;
  final VoidCallback onCheckTap;
  final VoidCallback onEditTap;
  final VoidCallback? onShareTap;

  @override
  Widget build(BuildContext context) {
    final photo = dd.createdByPhoto;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Creator profile pic — rounded square, 57×57
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 57,
              height: 57,
              color: Colors.white24,
              child: (photo != null && photo.isNotEmpty)
                  ? Image(image: avatarImageProvider(photo), fit: BoxFit.cover)
                  : const Icon(Icons.person, color: Colors.white54, size: 32),
            ),
          ),
          const SizedBox(width: 10),
          // Text content
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
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.music_note,
                          size: 15,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            dd.songChoice!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (onShareTap != null)
                          GestureDetector(
                            onTap: onShareTap,
                            child: const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.ios_share,
                                size: 20,
                                color: Colors.yellow,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Action icons — X + check side by side, edit below
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 38,
                    height: 38,
                    child: Center(
                      child: GestureDetector(
                        onTap: onCancelTap,
                        child: Icon(
                          dd.isCancelled ? Icons.cancel : Icons.cancel_outlined,
                          color: dd.isCancelled
                              ? Colors.redAccent
                              : Colors.lightBlueAccent,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 38,
                    height: 38,
                    child: Center(
                      child: GestureDetector(
                        onTap: onCheckTap,
                        child: Icon(
                          dd.isDone
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          color: dd.isDone
                              ? Colors.yellow
                              : Colors.lightBlueAccent,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: 44,
                height: 30,
                child: Center(
                  child: GestureDetector(
                    onTap: onEditTap,
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Colors.white38,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
