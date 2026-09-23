import 'package:harrier_central/imports.dart';

/// A self-contained, pull-to-refresh photo gallery for run photos.
///
/// Pass [loader] as the async function that fetches the photo list —
/// it is called on first build and on each pull-to-refresh gesture.
/// StatelessWidget over [RunPhotoGalleryController]; the controller lives as
/// long as this widget does (GetBuilder's `init` puts it and deletes it on
/// dispose), so a tab that is rebuilt keeps its photos and a tab that is left
/// starts fresh next time.
class RunPhotoGallery extends StatelessWidget {
  const RunPhotoGallery({
    super.key,
    required this.loader,
    required this.eventName,
    this.kennelId,
    this.kennelSlug,
    this.eventNumber,
    this.run,
  });

  final Future<({bool success, List<RunPhotoModel> photos})> Function() loader;
  final String eventName;

  /// The run these photos belong to. When provided, the full-screen viewer gets
  /// a "View on map" button per photo. Null on the guest path (no aggregate).
  final RunDetailsAggregate? run;

  // When provided, own photos get a crop button in the full-screen viewer.
  // Pass these only when the current user has an edit role (Hash Flash / GM /
  // VGM / RA) — the SP enforces the same check server-side.
  final String? kennelId;
  final String? kennelSlug;
  final int? eventNumber;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RunPhotoGalleryController>(
      init: RunPhotoGalleryController(
        loader: loader,
        eventName: eventName,
        run: run,
      ),
      tag: RunPhotoGalleryController.tagFor(run, eventName),
      builder: (RunPhotoGalleryController controller) {
        final body = Container(
          decoration: Backgrounds.defaultHcBackground(),
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: HcAppCircularProgressIndicator(key: Key('rpg_load')),
              );
            }
            if (controller.hasError.value) return _buildError(controller);
            return RefreshIndicator(
              onRefresh: controller.pullToRefresh,
              child: controller.photos.isEmpty
                  ? _buildEmpty(context)
                  : _buildGrid(context, controller),
            );
          }),
        );

        // Importing needs the run for its kennel, number and time window. The
        // guest gallery has no aggregate, so it simply doesn't get the button.
        if (run == null) return body;

        return Stack(
          children: <Widget>[
            Positioned.fill(child: body),
            Positioned(
              right: 16,
              bottom: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  // Finds this run's photos in the roll by time and place,
                  // rather than making the hasher pick them out (E6.F2.S5).
                  FloatingActionButton.extended(
                    heroTag: 'sweep-run-photos',
                    backgroundColor: Colors.white,
                    foregroundColor: hc_blue,
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(
                      'Find my photos',
                      style: ts_button.copyWith(color: hc_blue),
                    ),
                    onPressed: () async {
                      await Navigator.push<dynamic>(
                        context,
                        MaterialPageRoute<dynamic>(
                          builder: (_) => RunPhotoSweepPage(
                            eventId: run!.event.eventId,
                            eventName: eventName,
                          ),
                        ),
                      );
                      // The sweep may have sent photos up; pick them up
                      // without a spinner over what is already showing.
                      unawaited(controller.pullToRefresh());
                    },
                  ),
                  const SizedBox(height: 10),
                  Obx(() {
                    final bool importing = controller.isImporting.value;
                    return FloatingActionButton.extended(
                      heroTag: 'import-run-photos',
                      backgroundColor: hc_blue,
                      foregroundColor: Colors.white,
                      icon: importing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add_photo_alternate),
                      label: Text(
                        importing ? 'Adding…' : 'Add your photos',
                        style: ts_button,
                      ),
                      onPressed: importing
                          ? null
                          : () => unawaited(controller.importFromCameraRoll()),
                    );
                  }),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildError(RunPhotoGalleryController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.cloud_off, color: Colors.white38, size: 48),
          const SizedBox(height: 12),
          Text(
            'Could not load photos',
            style: ts_body.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => unawaited(controller.load()),
            child: Text('Retry', style: ts_button),
          ),
        ],
      ),
    );
  }

  // Empty state must be scrollable so the pull-to-refresh gesture works.
  Widget _buildEmpty(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.photo_camera_outlined,
                color: Colors.white38,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'No photos yet',
                style: ts_headingLarge.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                'Pull down to refresh',
                style: ts_body.copyWith(color: Colors.white38),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, RunPhotoGalleryController controller) {
    // Snapshot inside the caller's Obx so itemCount and itemBuilder agree.
    final List<RunPhotoModel> photos = controller.photos;
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1.0,
      ),
      itemCount: photos.length,
      itemBuilder: (BuildContext context, int index) {
        final RunPhotoModel photo = photos[index];
        return GestureDetector(
          onTap: () => _openFullScreen(context, controller, index),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              CachedNetworkImage(
                imageUrl: photo.effectiveUrl,
                fit: BoxFit.cover,
                // Grid cell is ~1/3 screen — decode a thumbnail, not full-res.
                memCacheWidth: 500,
                placeholder: (context, url) => Container(
                  color: Colors.white10,
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.white10,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white38,
                  ),
                ),
              ),
              // Lock badge for the user's own private photos
              if (photo.isOwnPhoto && photo.status < 2)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: const Icon(
                      Icons.lock_outline,
                      color: Colors.white70,
                      size: 13,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openFullScreen(
    BuildContext context,
    RunPhotoGalleryController controller,
    int index,
  ) async {
    final canEdit = kennelId != null && kennelSlug != null;

    // Resolve each distinct photographer's name + avatar from the local hashers
    // table (same source the map path uses). Own photos fall back to the signed-
    // in user's name.
    final photographers = await controller.resolvePhotographers();

    final items = controller.photos
        .map((p) {
          final uid = normalizeUuid(p.userId ?? '');
          final info = photographers[uid];
          return MapPhotoItem(
            imageUrl: p.effectiveUrl,
            caption: p.displayCaption,
            uploaderName: info?.name ?? (p.uploaderDisplayName ?? ''),
            uploaderPhotoUrl: info?.photo ?? '',
            capturedAt: p.createdAt.year > 1 ? p.createdAt : null,
            latitude: p.latitude,
            longitude: p.longitude,
            photoId: (canEdit && p.isOwnPhoto) ? p.photoId : null,
            originalBlobUrl: (canEdit && p.isOwnPhoto) ? p.blobUrl : null,
            kennelId: (canEdit && p.isOwnPhoto) ? kennelId : null,
            kennelSlug: (canEdit && p.isOwnPhoto) ? kennelSlug : null,
            eventNumber: (canEdit && p.isOwnPhoto) ? eventNumber : null,
            // Their own photo, currently visible to more than just them.
            // No role required — see MapPhotoItem.myPhotoId.
            myPhotoId: (p.isOwnPhoto && p.status >= 2) ? p.photoId : null,
          );
        })
        .toList(growable: false);

    if (!context.mounted || index >= items.length) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MapPhotoPage(
          pageTitle: eventName,
          photos: items,
          initialIndex: index,
          background: Backgrounds.defaultHcBackground(),
          run: run,
        ),
      ),
    );
  }
}
