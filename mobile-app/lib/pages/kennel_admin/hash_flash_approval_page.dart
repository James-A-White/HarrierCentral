import 'package:harrier_central/imports.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class KennelPendingPhoto {
  const KennelPendingPhoto({
    required this.photoId,
    required this.eventId,
    required this.status,
    required this.blobUrl,
    required this.uploaderDisplayName,
    required this.eventName,
    required this.eventNumber,
    required this.createdAt,
    this.deletedAt,
    this.title,
    this.description,
  });

  final String photoId;
  final String eventId;
  final int status;
  final DateTime? deletedAt;
  final String blobUrl;
  final String uploaderDisplayName;
  final String eventName;
  final int eventNumber;
  final DateTime createdAt;
  final String? title;
  final String? description;

  bool get isDeleted => deletedAt != null;
  bool get isPending => status == 1 && !isDeleted;

  KennelPendingPhoto copyWithDescription(String? newDescription) {
    return KennelPendingPhoto(
      photoId: photoId,
      eventId: eventId,
      status: status,
      deletedAt: deletedAt,
      blobUrl: blobUrl,
      uploaderDisplayName: uploaderDisplayName,
      eventName: eventName,
      eventNumber: eventNumber,
      createdAt: createdAt,
      title: title,
      description: (newDescription == null || newDescription.trim().isEmpty)
          ? null
          : newDescription.trim(),
    );
  }

  factory KennelPendingPhoto.fromJson(Map<String, dynamic> json) {
    return KennelPendingPhoto(
      photoId: normalizeUuid(
        (json['photoId'] ?? json['PhotoId'])?.toString() ?? '',
      ),
      eventId: normalizeUuid(
        (json['EventId'] ?? json['eventId'])?.toString() ?? '',
      ),
      status: (json['Status'] ?? json['status'] as num?)?.toInt() ?? 0,
      deletedAt: () {
        final raw =
            (json['DeletedAt'] ?? json['deletedAt'])?.toString();
        if (raw == null || raw.isEmpty) return null;
        return DateTime.tryParse(raw);
      }(),
      blobUrl: (json['BlobUrl'] ?? json['blobUrl'])?.toString() ?? '',
      uploaderDisplayName:
          json['uploaderDisplayName']?.toString() ?? 'Unknown',
      eventName: json['eventName']?.toString() ?? '',
      eventNumber: (json['eventNumber'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse(
            (json['CreatedAt'] ?? json['createdAt'])?.toString() ?? '',
          ) ??
          DateTime.now(),
      title: (json['Title'] ?? json['title'])?.toString(),
      description: (json['Description'] ?? json['description'])?.toString(),
    );
  }
}

// ---------------------------------------------------------------------------
// Status counts
// ---------------------------------------------------------------------------

class PhotoStatusCounts {
  const PhotoStatusCounts({
    this.pending = 0,
    this.private = 0,
    this.shared = 0,
    this.runGallery = 0,
    this.homeGallery = 0,
    this.eventCover = 0,
    this.deleted = 0,
  });

  final int pending;
  final int private;
  final int shared;
  final int runGallery;
  final int homeGallery;
  final int eventCover;
  final int deleted;

  int get total =>
      pending + private + shared + runGallery + homeGallery + eventCover +
      deleted;

  static PhotoStatusCounts from(List<KennelPendingPhoto> photos) {
    int pending = 0, private = 0, shared = 0, runGallery = 0,
        homeGallery = 0, eventCover = 0, deleted = 0;
    for (final p in photos) {
      if (p.isDeleted) {
        deleted++;
      } else {
        switch (p.status) {
          case 0: private++;
          case 1: pending++;
          case 2: shared++;
          case 3: runGallery++;
          case 4: homeGallery++;
          case 5: eventCover++;
        }
      }
    }
    return PhotoStatusCounts(
      pending: pending,
      private: private,
      shared: shared,
      runGallery: runGallery,
      homeGallery: homeGallery,
      eventCover: eventCover,
      deleted: deleted,
    );
  }
}

// ---------------------------------------------------------------------------
// Queue entry — holds the pending action (mutable so user can change mind)
// ---------------------------------------------------------------------------

class _QueuedAction {
  _QueuedAction({required this.action});
  int action;
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

enum PhotoReviewTab { pending, reviewed }

class PhotoReviewController extends GetxController {
  PhotoReviewController({
    required this.kennelId,
    required this.eventId,
  });

  final String kennelId;
  final String eventId;

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxList<KennelPendingPhoto> allPhotos = <KennelPendingPhoto>[].obs;
  final RxString loadError = ''.obs;
  final Rx<PhotoReviewTab> activeTab = PhotoReviewTab.pending.obs;
  final RxInt currentIndex = 0.obs;
  final RxMap<String, int> decisions = <String, int>{}.obs;

  // Pending writes: photoId → queued action
  final Map<String, _QueuedAction> _queue = {};

  late final PageController pageController = PageController();
  final _service = KennelPhotoService();

  // ── Derived ──────────────────────────────────────────────────────────────

  List<KennelPendingPhoto> get pendingPhotos =>
      (allPhotos.where((p) => p.isPending).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt)));

  List<KennelPendingPhoto> get reviewedPhotos =>
      (allPhotos.where((p) => !p.isPending).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt)));

  List<KennelPendingPhoto> get visiblePhotos =>
      activeTab.value == PhotoReviewTab.pending
          ? pendingPhotos
          : reviewedPhotos;

  PhotoStatusCounts get counts => PhotoStatusCounts.from(allPhotos);

  bool get hasQueuedChanges => _queue.isNotEmpty;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    unawaited(loadPhotos());
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void onPageChanged(int index) {
    currentIndex.value = index;
    _preloadAhead(index + 1);
  }

  void switchTab(PhotoReviewTab tab) {
    if (activeTab.value == tab) return;
    activeTab.value = tab;
    currentIndex.value = 0;
    if (pageController.hasClients) {
      pageController.jumpToPage(0);
    }
    _preloadAhead(0);
  }

  // Precache the next [_preloadCount] photos from [fromIndex] so they are
  // already in Flutter's image cache when the user swipes to them.
  static const int _preloadCount = 3;
  void _preloadAhead(int fromIndex) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    final photos = visiblePhotos;
    final end = (fromIndex + _preloadCount).clamp(0, photos.length);
    for (int i = fromIndex.clamp(0, photos.length); i < end; i++) {
      final url = photos[i].blobUrl;
      if (url.isNotEmpty) {
        precacheImage(NetworkImage(url), ctx);
      }
    }
  }

  int? decisionFor(String photoId) => decisions[photoId];

  void _goToNext() {
    final list = visiblePhotos;
    if (currentIndex.value < list.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // ── Load ─────────────────────────────────────────────────────────────────

  Future<void> loadPhotos() async {
    isLoading.value = true;
    loadError.value = '';
    try {
      final result = await _service.getRunAllPhotos(
        kennelId: kennelId,
        eventId: eventId,
      );
      if (result.startsWith(ERROR_PREFIX)) {
        loadError.value =
            'Could not load photos. Please check your connection and try again.';
        BootLogger.logError('[PhotoReviewController.loadPhotos] server error kennelId=$kennelId eventId=$eventId', result, null);
        allPhotos.clear();
        return;
      }
      final outer = jsonDecode(result) as List<dynamic>;
      if (outer.isEmpty || outer[0] is! List) {
        allPhotos.clear();
        return;
      }
      final rows = outer[0] as List<dynamic>;
      allPhotos.value = rows
          .whereType<Map<String, dynamic>>()
          .map(KennelPendingPhoto.fromJson)
          .toList();
      // If there's nothing left to review, open on the Reviewed tab so the
      // reviewer isn't left staring at an empty pending state.
      if (pendingPhotos.isEmpty && reviewedPhotos.isNotEmpty) {
        activeTab.value = PhotoReviewTab.reviewed;
      }
      _preloadAhead(0);
    } catch (e, s) {
      loadError.value =
          'Could not load photos. Please check your connection and try again.';
      debugPrint('PhotoReviewController.loadPhotos error: $e');
      BootLogger.logError('[PhotoReviewController.loadPhotos] kennelId=$kennelId eventId=$eventId', e, s);
    } finally {
      isLoading.value = false;
    }
  }

  // ── Action (instant, queued) ──────────────────────────────────────────────

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
            'The photo will be hidden from the run. You can restore it '
            'at any time from the Reviewed tab.',
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

    if (isSaving.value) return;

    _enqueue(photoId: photoId, action: action);
    decisions[photoId] = action;

    // Brief pause so the button highlight is visible before advancing.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _goToNext();
  }

  // ── Queue helpers ─────────────────────────────────────────────────────────

  void _enqueue({required String photoId, required int action}) {
    if (_queue.containsKey(photoId)) {
      _queue[photoId]!.action = action;
    } else {
      _queue[photoId] = _QueuedAction(action: action);
    }
  }

  void _revertOptimisticUpdates() {
    _queue.clear();
    decisions.clear();
  }

  // ── Flush ─────────────────────────────────────────────────────────────────

  // All dialogs in _flushQueue use navigatorKey — no BuildContext parameter
  // needed, which avoids context-across-async-gap lint warnings.
  Future<void> _flushQueue() async {
    if (_queue.isEmpty) return;

    final updates = _queue.entries
        .map((e) => <String, dynamic>{
              'photoId': e.key,
              'action': e.value.action,
            })
        .toList();

    isSaving.value = true;
    try {
      final result = await _service.batchUpdatePhotoStatus(
        kennelId: kennelId,
        updates: updates,
      );

      if (result.startsWith(ERROR_PREFIX)) {
        _revertOptimisticUpdates();
        _showFailureDialog();
        return;
      }

      final outer = jsonDecode(result) as List<dynamic>;
      final row = (outer.isNotEmpty && outer[0] is List &&
              (outer[0] as List).isNotEmpty)
          ? (outer[0] as List)[0] as Map<String, dynamic>?
          : null;

      if (row?['success'] != 1 && row?['success'] != true) {
        _revertOptimisticUpdates();
        _showFailureDialog();
        return;
      }

      final failureCount =
          (row?['failureCount'] as num?)?.toInt() ?? 0;
      _queue.clear();
      decisions.clear();
      await loadPhotos();

      if (failureCount > 0) _showPartialFailureDialog(failureCount);
    } catch (e, s) {
      debugPrint('PhotoReviewController._flushQueue error: $e');
      BootLogger.logError('[PhotoReviewController._flushQueue] kennelId=$kennelId eventId=$eventId queueSize=${_queue.length}', e, s);
      _revertOptimisticUpdates();
      _showFailureDialog();
    } finally {
      isSaving.value = false;
    }
  }

  /// Called by PopScope — flushes pending queue then pops the route.
  Future<void> flushAndPop() async {
    if (_queue.isNotEmpty) await _flushQueue();
    Get.back();
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _showFailureDialog() {
    final ctx = navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('Update failed', style: ts_alertDialogTitle),
        content: Text(
          'Your photo selections could not be saved — please check your '
          'connection and try again. All selections have been reverted.',
          style: ts_alertDialogBody,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: hc_red,
              foregroundColor: Colors.white,
            ),
            child: Text('OK', style: ts_button),
          ),
        ],
      ),
    );
  }

  void _showPartialFailureDialog(int failureCount) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text('Some photos not updated', style: ts_alertDialogTitle),
        content: Text(
          '$failureCount photo${failureCount == 1 ? '' : 's'} could not '
          'be updated — they may have been removed by another user. All '
          'other changes were saved successfully.',
          style: ts_alertDialogBody,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: hc_red,
              foregroundColor: Colors.white,
            ),
            child: Text('OK', style: ts_button),
          ),
        ],
      ),
    );
  }

  // ── Caption editing ───────────────────────────────────────────────────────

  /// Flushes any queued status decisions, then saves the caption update.
  /// [newCaption] null or empty clears the existing caption.
  Future<void> editCaption({
    required String photoId,
    required String? newCaption,
  }) async {
    // Flush pending status decisions first — the user paused the rapid flow
    // to edit a caption, so this is the right moment to commit queued actions.
    if (_queue.isNotEmpty) await _flushQueue();

    isSaving.value = true;
    try {
      final trimmed =
          (newCaption == null || newCaption.trim().isEmpty) ? null : newCaption.trim();

      final result = await _service.updatePhotoCaption(
        photoId: photoId,
        description: trimmed,
      );

      if (result.startsWith(ERROR_PREFIX)) {
        _showCaptionFailureDialog();
        return;
      }

      final outer = jsonDecode(result) as List<dynamic>;
      final row = (outer.isNotEmpty &&
              outer[0] is List &&
              (outer[0] as List).isNotEmpty)
          ? (outer[0] as List)[0] as Map<String, dynamic>?
          : null;

      if (row?['success'] != 1 && row?['success'] != true) {
        _showCaptionFailureDialog();
        return;
      }

      // Optimistic local update — no full reload needed.
      final idx = allPhotos.indexWhere((p) => p.photoId == photoId);
      if (idx >= 0) {
        allPhotos[idx] = allPhotos[idx].copyWithDescription(trimmed);
      }
    } catch (e, s) {
      debugPrint('PhotoReviewController.editCaption error: $e');
      BootLogger.logError(
          '[PhotoReviewController.editCaption] photoId=$photoId', e, s);
      _showCaptionFailureDialog();
    } finally {
      isSaving.value = false;
    }
  }

  void _showCaptionFailureDialog() {
    final ctx = navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('Caption not saved', style: ts_alertDialogTitle),
        content: Text(
          'The caption could not be saved. Please check your connection '
          'and try again.',
          style: ts_alertDialogBody,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: hc_red,
              foregroundColor: Colors.white,
            ),
            child: Text('OK', style: ts_button),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class PhotoReviewPage extends StatelessWidget {
  PhotoReviewPage({
    super.key,
    required this.kennelId,
    required this.eventId,
    required this.eventName,
    required this.eventNumber,
    this.kennelLogoUrl,
    this.kennelShortName,
  }) : controller = _freshController(kennelId, eventId);

  final String kennelId;
  final String eventId;
  final String eventName;
  final int? eventNumber;
  final String? kennelLogoUrl;
  final String? kennelShortName;
  final PhotoReviewController controller;

  static PhotoReviewController _freshController(
      String kennelId, String eventId) {
    final tag = 'photo-review-$eventId';
    Get.delete<PhotoReviewController>(tag: tag, force: true);
    return Get.put(
      PhotoReviewController(kennelId: kennelId, eventId: eventId),
      tag: tag,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(controller.flushAndPop());
      },
      child: AppScaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: themeAppBarBackground,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text('Review Photos', style: ts_appBarTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: controller.loadPhotos,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: Obx(() => controller.isSaving.value
                ? const LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white70),
                  )
                : const SizedBox.shrink()),
          ),
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
          if (controller.loadError.value.isNotEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(controller.loadError.value,
                    style: ts_bodyYellow, textAlign: TextAlign.center),
              ),
            );
          }
          return Column(
            children: [
              _RunHeader(page: this),
              _TabPills(controller: controller),
              Expanded(child: _PhotoBody(page: this, context: context)),
            ],
          );
        }),
      ),
    ));
  }
}

// ---------------------------------------------------------------------------
// Run header — kennel logo + event + status counts
// ---------------------------------------------------------------------------

class _RunHeader extends StatelessWidget {
  const _RunHeader({required this.page});
  final PhotoReviewPage page;

  @override
  Widget build(BuildContext context) {
    final runLabel = page.eventNumber != null && page.eventNumber! > 0
        ? 'Run #${page.eventNumber}'
        : page.eventName;

    return Obx(() {
      final c = page.controller.counts;
      return Container(
        color: Colors.black54,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KennelLogo(
              kennelId: page.kennelId,
              kennelLogoUrl: page.kennelLogoUrl,
              kennelShortName: page.kennelShortName ?? '',
              logoHeight: 52,
              leftPadding: 0,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    page.eventName,
                    style: ts_bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    runLabel,
                    style: ts_bodySmall.copyWith(color: Colors.white60),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: [
                      if (c.pending > 0)
                        _CountChip(
                            label: 'Pending',
                            count: c.pending,
                            color: Colors.orange.shade700),
                      _CountChip(
                          label: 'Private',
                          count: c.private,
                          color: Colors.grey.shade600),
                      _CountChip(
                          label: 'Shared',
                          count: c.shared,
                          color: Colors.green.shade600),
                      _CountChip(
                          label: 'Gallery',
                          count: c.runGallery,
                          color: Colors.green.shade700),
                      _CountChip(
                          label: 'Home',
                          count: c.homeGallery,
                          color: Colors.teal.shade600),
                      _CountChip(
                          label: 'Cover',
                          count: c.eventCover,
                          color: Colors.teal.shade800),
                      if (c.deleted > 0)
                        _CountChip(
                            label: 'Deleted',
                            count: c.deleted,
                            color: hc_red),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip(
      {required this.label, required this.count, required this.color});
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count $label',
        style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab pills
// ---------------------------------------------------------------------------

class _TabPills extends StatelessWidget {
  const _TabPills({required this.controller});
  final PhotoReviewController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final active = controller.activeTab.value;
      final pendingCount = controller.pendingPhotos.length;
      final reviewedCount = controller.reviewedPhotos.length;

      return Container(
        color: Colors.black38,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PillButton(
              label: 'Pending ($pendingCount)',
              isSelected: active == PhotoReviewTab.pending,
              onTap: () => controller.switchTab(PhotoReviewTab.pending),
            ),
            const SizedBox(width: 12),
            _PillButton(
              label: 'Reviewed ($reviewedCount)',
              isSelected: active == PhotoReviewTab.reviewed,
              onTap: () => controller.switchTab(PhotoReviewTab.reviewed),
            ),
          ],
        ),
      );
    });
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton(
      {required this.label,
      required this.isSelected,
      required this.onTap});
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? hc_red : Colors.white24,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: ts_bodySmall.copyWith(
            color: Colors.white,
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Photo body — PageView + action panel, or empty state
// ---------------------------------------------------------------------------

class _PhotoBody extends StatelessWidget {
  const _PhotoBody({required this.page, required this.context});
  final PhotoReviewPage page;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final photos = page.controller.visiblePhotos;
      final tab = page.controller.activeTab.value;

      if (photos.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  tab == PhotoReviewTab.pending
                      ? Icons.check_circle_outline
                      : Icons.photo_library_outlined,
                  color: Colors.white54,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  tab == PhotoReviewTab.pending
                      ? 'All photos reviewed for this run.'
                      : 'No reviewed photos yet.',
                  style: ts_bodyYellow,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  tab == PhotoReviewTab.pending
                      ? 'Switch to Reviewed to see previously actioned photos.'
                      : 'Photos you action will appear here.',
                  style: ts_bodySmall.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        children: [
          _PhotoCounter(controller: page.controller),
          Expanded(child: _PhotoPageView(controller: page.controller)),
          _ActionPanel(controller: page.controller, context: context),
        ],
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Counter strip
// ---------------------------------------------------------------------------

class _PhotoCounter extends StatelessWidget {
  const _PhotoCounter({required this.controller});
  final PhotoReviewController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final photos = controller.visiblePhotos;
      if (photos.isEmpty) return const SizedBox.shrink();
      final idx =
          controller.currentIndex.value.clamp(0, photos.length - 1);
      final photo = photos[idx];
      final runLabel = photo.eventNumber > 0
          ? 'Run #${photo.eventNumber}'
          : photo.eventName;
      final decided =
          controller.decisionFor(photo.photoId) != null;

      return Container(
        color: Colors.black54,
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    photo.uploaderDisplayName,
                    style: ts_bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (runLabel.isNotEmpty)
                    Text(runLabel,
                        style: ts_bodySmall.copyWith(
                            color: Colors.white60),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (decided) ...[
              const Icon(Icons.check_circle,
                  color: Colors.greenAccent, size: 14),
              const SizedBox(width: 4),
            ],
            Text(
              '${idx + 1} / ${photos.length}',
              style: ts_bodySmall.copyWith(color: Colors.white70),
            ),
          ],
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Photo PageView
// ---------------------------------------------------------------------------

class _PhotoPageView extends StatelessWidget {
  const _PhotoPageView({required this.controller});
  final PhotoReviewController controller;

  @override
  Widget build(BuildContext context) {
    final photos = controller.visiblePhotos;
    return PageView.builder(
      controller: controller.pageController,
      onPageChanged: controller.onPageChanged,
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return Stack(
          fit: StackFit.expand,
          children: [
            if (photo.blobUrl.isNotEmpty)
              Image.network(
                photo.blobUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) =>
                    progress == null
                        ? child
                        : const Center(
                            child: CircularProgressIndicator(
                                color: Colors.white54)),
                errorBuilder: (context, err, stack) {
                  debugPrint(
                    'PhotoReviewPage: failed to load\n'
                    '  url: ${photo.blobUrl}\n  err: $err',
                  );
                  return const Center(
                    child: Icon(Icons.broken_image,
                        color: Colors.white38, size: 64),
                  );
                },
              )
            else
              const Center(
                child: Icon(Icons.image_not_supported,
                    color: Colors.white38, size: 64),
              ),

            // Soft-deleted overlay — rendered before caption strip so the
            // strip sits on top and remains tappable on deleted photos.
            if (photo.isDeleted)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.45),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline,
                            color: Colors.white54, size: 48),
                        SizedBox(height: 8),
                        Text('Deleted',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),

            // Caption strip — always visible so the reviewer can add or edit
            // captions regardless of whether one exists already.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => unawaited(
                    _showCaptionEditor(context, controller, photo)),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  color: Colors.black.withValues(alpha: 0.65),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: photo.description != null &&
                                photo.description!.isNotEmpty
                            ? Text(
                                photo.description!,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    height: 1.4),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              )
                            : Text(
                                'Add a caption…',
                                style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic),
                              ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.edit_outlined,
                          color: Colors.white54, size: 16),
                    ],
                  ),
                ),
              ),
            ),

            // Status badge — always visible, always colored by action type.
            // Queued decision takes priority over committed status.
            Obx(() {
              final queued = controller.decisionFor(photo.photoId);
              final committed = photo.isDeleted
                  ? photoActionDelete
                  : switch (photo.status) {
                      0 => photoActionKeepPrivate,
                      2 => photoActionShare,
                      3 => photoActionAddToGallery,
                      4 => photoActionAddToHomeGallery,
                      5 => photoActionMakeEventCover,
                      _ => null, // status 1 = pending, no badge until actioned
                    };
              final effective = queued ?? committed;
              if (effective == null) return const SizedBox.shrink();
              final color = _badgeColor(effective);
              return Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: color, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        _actionLabel(effective),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  String _actionLabel(int action) => switch (action) {
        photoActionKeepPrivate => 'Keep Private',
        photoActionDelete => 'Deleted',
        photoActionShare => 'Share on Maps',
        photoActionAddToGallery => 'Run Gallery',
        photoActionAddToHomeGallery => 'Home Page Gallery',
        photoActionMakeEventCover => 'Event Cover Photo',
        _ => 'Actioned',
      };

  Color _badgeColor(int action) => switch (action) {
        photoActionKeepPrivate    => Colors.grey.shade600,
        photoActionDelete         => hc_red,
        photoActionShare          => Colors.green.shade600,
        photoActionAddToGallery   => Colors.green.shade700,
        photoActionAddToHomeGallery => Colors.teal.shade600,
        photoActionMakeEventCover => Colors.teal.shade800,
        _ => Colors.white38,
      };
}

// ---------------------------------------------------------------------------
// Action panel
// ---------------------------------------------------------------------------

class _ActionPanel extends StatelessWidget {
  const _ActionPanel(
      {required this.controller, required this.context});
  final PhotoReviewController controller;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final photos = controller.visiblePhotos;
      if (photos.isEmpty) return const SizedBox.shrink();
      final idx =
          controller.currentIndex.value.clamp(0, photos.length - 1);
      final photo = photos[idx];

      // Queued decision takes priority; fall back to committed status.
      final int? selected = controller.decisionFor(photo.photoId) ??
          (photo.isDeleted
              ? photoActionDelete
              : switch (photo.status) {
                  0 => photoActionKeepPrivate,
                  2 => photoActionShare,
                  3 => photoActionAddToGallery,
                  4 => photoActionAddToHomeGallery,
                  5 => photoActionMakeEventCover,
                  _ => null,
                });

      void act(int action) => controller.actionPhoto(
            photoId: photo.photoId,
            action: action,
            context: context,
          );

      return Container(
        color: Colors.black54,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.lock_outline,
                    label: 'Keep Private',
                    color: Colors.grey.shade600,
                    isSelected: selected == photoActionKeepPrivate,
                    onTap: () => act(photoActionKeepPrivate),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    color: hc_red,
                    isSelected: selected == photoActionDelete,
                    onTap: () => act(photoActionDelete),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  const Expanded(
                      child: Divider(color: Colors.white24, height: 1)),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('Publish as…',
                        style: ts_bodySmall.copyWith(
                            color: Colors.white54,
                            fontStyle: FontStyle.italic)),
                  ),
                  const Expanded(
                      child: Divider(color: Colors.white24, height: 1)),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.people_outline,
                    label: 'Share on Maps',
                    color: Colors.green.shade600,
                    isSelected: selected == photoActionShare,
                    onTap: () => act(photoActionShare),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Run Gallery',
                    color: Colors.green.shade700,
                    isSelected: selected == photoActionAddToGallery,
                    onTap: () => act(photoActionAddToGallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.home_outlined,
                    label: 'Home Page Gallery',
                    color: Colors.teal.shade600,
                    isSelected: selected == photoActionAddToHomeGallery,
                    onTap: () => act(photoActionAddToHomeGallery),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.star_outline,
                    label: 'Event Cover Photo',
                    color: Colors.teal.shade800,
                    isSelected: selected == photoActionMakeEventCover,
                    onTap: () => act(photoActionMakeEventCover),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Caption editor bottom sheet
// ---------------------------------------------------------------------------

Future<void> _showCaptionEditor(
  BuildContext context,
  PhotoReviewController controller,
  KennelPendingPhoto photo,
) async {
  // result == null  → dismissed without action (back / tap outside)
  // result == ''    → Clear tapped, or Save with empty field
  // result == 'txt' → Save tapped with content
  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.grey.shade900,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _CaptionEditorSheet(
      initialCaption: photo.description ?? '',
    ),
  );

  if (result == null) return; // dismissed, no action

  final newCaption = result.isEmpty ? null : result;
  if (newCaption == photo.description) return; // nothing changed

  await controller.editCaption(photoId: photo.photoId, newCaption: newCaption);
}

class _CaptionEditorSheet extends StatefulWidget {
  const _CaptionEditorSheet({required this.initialCaption});
  final String initialCaption;

  @override
  State<_CaptionEditorSheet> createState() => _CaptionEditorSheetState();
}

class _CaptionEditorSheetState extends State<_CaptionEditorSheet> {
  late final TextEditingController _textController;
  int _wordCount = 0;

  static int _countWords(String text) {
    final t = text.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).length;
  }

  String? get _finalCaption {
    final t = _textController.text.trim();
    if (t.isEmpty) return null;
    if (_wordCount <= 200) return t;
    return t.split(RegExp(r'\s+')).take(200).join(' ');
  }

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialCaption);
    _wordCount = _countWords(widget.initialCaption);
    _textController.addListener(() {
      final count = _countWords(_textController.text);
      if (count != _wordCount) setState(() => _wordCount = count);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Caption',
                style: ts_bodySmall.copyWith(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (widget.initialCaption.isNotEmpty)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(''),
                  child: Text('Clear',
                      style:
                          ts_bodySmall.copyWith(color: Colors.redAccent)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _textController,
            maxLines: 5,
            minLines: 2,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Describe this photo…',
              hintStyle:
                  const TextStyle(color: Colors.white38, fontSize: 14),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$_wordCount / 200 words',
              style: TextStyle(
                color:
                    _wordCount > 200 ? Colors.redAccent : Colors.white38,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () =>
                  Navigator.of(context).pop(_finalCaption ?? ''),
              child: Text('Save caption', style: ts_button),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action button widget
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: Colors.white, width: 2)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.check_circle : icon,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: ts_bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: isSelected
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
