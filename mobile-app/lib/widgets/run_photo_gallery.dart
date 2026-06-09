import 'package:harrier_central/imports.dart';

/// A self-contained, pull-to-refresh photo gallery for run photos.
///
/// Pass [loader] as the async function that fetches the photo list —
/// it is called on first build and on each pull-to-refresh gesture.
class RunPhotoGallery extends StatefulWidget {
  const RunPhotoGallery({
    super.key,
    required this.loader,
    required this.eventName,
    this.kennelId,
    this.kennelSlug,
    this.eventNumber,
  });

  final Future<({bool success, List<RunPhotoModel> photos})> Function() loader;
  final String eventName;

  // When provided, own photos get a crop button in the full-screen viewer.
  // Pass these only when the current user has an edit role (Hash Flash / GM /
  // VGM / RA) — the SP enforces the same check server-side.
  final String? kennelId;
  final String? kennelSlug;
  final int? eventNumber;

  @override
  State<RunPhotoGallery> createState() => _RunPhotoGalleryState();
}

class _RunPhotoGalleryState extends State<RunPhotoGallery> {
  bool _isLoading = true;
  bool _hasError = false;
  List<RunPhotoModel> _photos = const <RunPhotoModel>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    final result = await widget.loader();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _hasError = !result.success;
      _photos = result.photos;
    });
  }

  Future<void> _refresh() async {
    final result = await widget.loader();
    if (!mounted) return;
    setState(() {
      if (result.success) {
        _photos = result.photos;
        _hasError = false;
      } else if (_photos.isEmpty) {
        _hasError = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: Backgrounds.defaultHcBackground(),
      child: _isLoading
          ? const Center(
              child: HcAppCircularProgressIndicator(key: Key('rpg_load')),
            )
          : _hasError
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: _photos.isEmpty
                      ? _buildEmpty(context)
                      : _buildGrid(context),
                ),
    );
  }

  Widget _buildError() {
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
            onPressed: _load,
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

  Widget _buildGrid(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1.0,
      ),
      itemCount: _photos.length,
      itemBuilder: (BuildContext context, int index) {
        final RunPhotoModel photo = _photos[index];
        return GestureDetector(
          onTap: () => _openFullScreen(context, photo, index),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              CachedNetworkImage(
                imageUrl: photo.effectiveUrl,
                fit: BoxFit.cover,
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
    RunPhotoModel photo,
    int index,
  ) async {
    final canEdit = widget.kennelId != null && widget.kennelSlug != null;
    final items = _photos
        .map(
          (p) => MapPhotoItem(
            imageUrl: p.effectiveUrl,
            caption: p.displayCaption,
            uploaderName: p.uploaderDisplayName ?? '',
            photoId: (canEdit && p.isOwnPhoto) ? p.photoId : null,
            originalBlobUrl: (canEdit && p.isOwnPhoto) ? p.blobUrl : null,
            kennelId: (canEdit && p.isOwnPhoto) ? widget.kennelId : null,
            kennelSlug: (canEdit && p.isOwnPhoto) ? widget.kennelSlug : null,
            eventNumber: (canEdit && p.isOwnPhoto) ? widget.eventNumber : null,
          ),
        )
        .toList(growable: false);

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MapPhotoPage(
          pageTitle: widget.eventName,
          photos: items,
          initialIndex: index,
          background: Backgrounds.defaultHcBackground(),
        ),
      ),
    );
  }
}
