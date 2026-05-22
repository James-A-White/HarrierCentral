import 'package:harrier_central/imports.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class KennelPendingPhoto {
  const KennelPendingPhoto({
    required this.photoId,
    required this.blobUrl,
    required this.uploaderDisplayName,
    required this.eventName,
    required this.eventNumber,
    required this.createdAt,
    this.title,
  });

  final String photoId;
  final String blobUrl;
  final String uploaderDisplayName;
  final String eventName;
  final int eventNumber;
  final DateTime createdAt;
  final String? title;

  factory KennelPendingPhoto.fromJson(Map<String, dynamic> json) {
    return KennelPendingPhoto(
      photoId: normalizeUuid(json['photoId']?.toString() ?? ''),
      blobUrl: json['blobUrl']?.toString() ?? '',
      uploaderDisplayName: json['uploaderDisplayName']?.toString() ?? 'Unknown',
      eventName: json['eventName']?.toString() ?? '',
      eventNumber: (json['eventNumber'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      title: json['title']?.toString(),
    );
  }
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

class PhotoReviewController extends GetxController {
  PhotoReviewController({required this.kennelId});

  final String kennelId;

  final RxBool isLoading = true.obs;
  final RxList<KennelPendingPhoto> photos = <KennelPendingPhoto>[].obs;

  final _service = KennelPhotoService();

  @override
  void onInit() {
    super.onInit();
    unawaited(_loadPhotos());
  }

  Future<void> _loadPhotos() async {
    isLoading.value = true;
    try {
      final result = await _service.getKennelPendingPhotos(kennelId: kennelId);
      if (!result.startsWith(ERROR_PREFIX)) {
        final outer = jsonDecode(result) as List<dynamic>;
        final rows = outer[0] as List<dynamic>;
        if (rows.isNotEmpty &&
            rows[0] is Map &&
            (rows[0] as Map).containsKey('photoId')) {
          photos.value = rows
              .map((r) =>
                  KennelPendingPhoto.fromJson(r as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('hash_flash_approval_page: failed to load pending photos: $e');
    }
    isLoading.value = false;
  }

  Future<void> actionPhoto({
    required String photoId,
    required int action,
    required BuildContext context,
  }) async {
    if (action == photoActionDelete) {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text('Delete photo?', style: ts_alertDialogTitle),
          content: Text(
            'This will permanently remove the photo. '
            'Use this only when the photo violates content policies.',
            style: ts_alertDialogBody,
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade600,
                foregroundColor: Colors.white,
              ),
              child: Text('Cancel', style: ts_button),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: hc_red,
                foregroundColor: Colors.white,
              ),
              child: Text('Delete', style: ts_button),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final result = await _service.updatePhotoStatus(
      photoId: photoId,
      action: action,
    );

    if (!result.startsWith(ERROR_PREFIX)) {
      photos.removeWhere((p) => p.photoId == photoId);
    } else {
      Get.snackbar(
        'Error',
        'Could not update the photo. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: hc_red,
        colorText: Colors.white,
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class PhotoReviewPage extends StatelessWidget {
  PhotoReviewPage({
    super.key,
    required this.kennelId,
    required this.kennelName,
  }) : controller = Get.put(
          PhotoReviewController(kennelId: kennelId),
          tag: 'photo-review-$kennelId',
        );

  final String kennelId;
  final String kennelName;
  final PhotoReviewController controller;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Review Photos', style: ts_appBarTitle),
      ),
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: HcAppCircularProgressIndicator(
                  key: Key('photo_review_loading')),
            );
          }

          if (controller.photos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: Colors.white54, size: 64),
                    const SizedBox(height: 16),
                    Text('No photos awaiting review.',
                        style: ts_bodyYellow, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(
                      'Photos shared by members will appear here.',
                      style: ts_bodySmall.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.photos.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final photo = controller.photos[index];
              return _PhotoReviewCard(
                photo: photo,
                onAction: (action) => controller.actionPhoto(
                  photoId: photo.photoId,
                  action: action,
                  context: context,
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card
// ---------------------------------------------------------------------------

class _PhotoReviewCard extends StatelessWidget {
  const _PhotoReviewCard({required this.photo, required this.onAction});

  final KennelPendingPhoto photo;
  final void Function(int action) onAction;

  @override
  Widget build(BuildContext context) {
    final runLabel = photo.eventNumber > 0
        ? 'Run #${photo.eventNumber}'
        : photo.eventName.isNotEmpty
            ? photo.eventName
            : 'Unknown run';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Photo
          if (photo.blobUrl.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: CachedNetworkImage(
                imageUrl: photo.blobUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, err) => const Center(
                  child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Icon(Icons.broken_image,
                          size: 48, color: Colors.grey)),
                ),
              ),
            ),

          // Meta
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(photo.uploaderDisplayName,
                          style: ts_mediumBlackBold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(runLabel,
                          style: ts_smallBlack,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if ((photo.title ?? '').isNotEmpty)
                        Text(photo.title!,
                            style: ts_smallGrey,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Text(_formatDate(photo.createdAt), style: ts_smallGrey),
              ],
            ),
          ),

          const Divider(height: 1),

          // Rejection row
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.lock_outline,
                    label: 'Keep Private',
                    color: Colors.grey.shade600,
                    onTap: () => onAction(photoActionKeepPrivate),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    color: hc_red,
                    onTap: () => onAction(photoActionDelete),
                  ),
                ),
              ],
            ),
          ),

          // Approval section
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
            child: Text('Publish as…',
                style: ts_smallGrey.copyWith(fontStyle: FontStyle.italic)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Column(
              children: [
                _ApprovalOption(
                  icon: Icons.people_outline,
                  label: 'Share with Hash',
                  subtitle: 'Visible to all on run maps',
                  color: Colors.green.shade600,
                  onTap: () => onAction(photoActionShare),
                ),
                const SizedBox(height: 6),
                _ApprovalOption(
                  icon: Icons.photo_library_outlined,
                  label: 'Run Gallery',
                  subtitle: 'Share + appears in run photo gallery',
                  color: Colors.green.shade700,
                  onTap: () => onAction(photoActionAddToGallery),
                ),
                const SizedBox(height: 6),
                _ApprovalOption(
                  icon: Icons.home_outlined,
                  label: 'Home Gallery',
                  subtitle: 'Run gallery + featured on kennel home page',
                  color: Colors.teal.shade600,
                  onTap: () => onAction(photoActionAddToHomeGallery),
                ),
                const SizedBox(height: 6),
                _ApprovalOption(
                  icon: Icons.star_outline,
                  label: 'Event Cover',
                  subtitle: 'Home gallery + set as this run\'s cover photo',
                  color: Colors.teal.shade800,
                  onTap: () => onAction(photoActionMakeEventCover),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}';
}

// ---------------------------------------------------------------------------
// Button widgets
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(label, style: ts_bodySmall),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onTap,
    );
  }
}

class _ApprovalOption extends StatelessWidget {
  const _ApprovalOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onTap,
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: ts_button.copyWith(fontSize: 14)),
                  Text(subtitle,
                      style: ts_bodySmall.copyWith(
                          color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
