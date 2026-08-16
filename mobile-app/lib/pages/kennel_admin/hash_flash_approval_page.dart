import 'package:harrier_central/imports.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class KennelPendingPhoto {
  const KennelPendingPhoto({
    required this.photoId,
    required this.eventId,
    required this.status,
    this.featured = 0,
    required this.blobUrl,
    this.editedBlobUrl,
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
  /// Orthogonal showcase flag (kennel home page) — not an audience level.
  final int featured;
  final DateTime? deletedAt;
  final String blobUrl;
  /// Hash-Flash-edited crop. Null until the Hash Flash crops the photo.
  /// Always display [effectiveUrl]. Always re-edit from [blobUrl] (original).
  final String? editedBlobUrl;
  final String uploaderDisplayName;
  final String eventName;
  final int eventNumber;
  final DateTime createdAt;
  final String? title;
  final String? description;

  bool get isDeleted => deletedAt != null;
  bool get isPending => status == 1 && !isDeleted;

  /// The URL to display: edited version if available, original otherwise.
  String get effectiveUrl => editedBlobUrl ?? blobUrl;

  KennelPendingPhoto copyWithDescription(String? newDescription) {
    return KennelPendingPhoto(
      photoId: photoId,
      eventId: eventId,
      status: status,
      featured: featured,
      deletedAt: deletedAt,
      blobUrl: blobUrl,
      editedBlobUrl: editedBlobUrl,
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

  KennelPendingPhoto copyWithEditedBlobUrl(String newEditedBlobUrl) {
    return KennelPendingPhoto(
      photoId: photoId,
      eventId: eventId,
      status: status,
      featured: featured,
      deletedAt: deletedAt,
      blobUrl: blobUrl,
      editedBlobUrl: newEditedBlobUrl,
      uploaderDisplayName: uploaderDisplayName,
      eventName: eventName,
      eventNumber: eventNumber,
      createdAt: createdAt,
      title: title,
      description: description,
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
      featured: (json['Featured'] as num?)?.toInt() ?? 0,
      deletedAt: () {
        final raw =
            (json['DeletedAt'] ?? json['deletedAt'])?.toString();
        if (raw == null || raw.isEmpty) return null;
        return DateTime.tryParse(raw);
      }(),
      blobUrl: (json['BlobUrl'] ?? json['blobUrl'])?.toString() ?? '',
      editedBlobUrl: (json['EditedBlobUrl'] ?? json['editedBlobUrl'])?.toString(),
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
    required this.kennelSlug,
    required this.eventNumber,
  });

  final String kennelId;
  final String eventId;
  final String kennelSlug;
  final int eventNumber;

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxBool isEditing = false.obs;
  final RxList<KennelPendingPhoto> allPhotos = <KennelPendingPhoto>[].obs;
  final RxString loadError = ''.obs;
  final Rx<PhotoReviewTab> activeTab = PhotoReviewTab.pending.obs;
  final RxInt currentIndex = 0.obs;
  final RxMap<String, int> decisions = <String, int>{}.obs;

  // ── Grid + multi-select ────────────────────────────────────────────────────
  // The grid IS the multi-select surface: tapping a thumb toggles selection and
  // the bulk bar is always visible. Long-press opens a photo in the carousel.
  final RxBool gridMode = false.obs;
  final RxSet<String> selectedIds = <String>{}.obs;

  // ── Status filter ──────────────────────────────────────────────────────────
  // Set by tapping a header count chip. Holds the [PhotoActionSpec.action] of
  // the rung being shown, or null for "everything in the active tab".
  final Rx<int?> statusFilter = Rx<int?>(null);

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

  List<KennelPendingPhoto> get visiblePhotos {
    final base = activeTab.value == PhotoReviewTab.pending
        ? pendingPhotos
        : reviewedPhotos;
    final action = statusFilter.value;
    if (action == null) return base;
    return base.where((p) => _matchesFilter(p, action)).toList();
  }

  /// Deleted is a DeletedAt stamp rather than a Status rung, so it filters on
  /// [KennelPendingPhoto.isDeleted]; every other chip filters on the Status the
  /// action writes.
  bool _matchesFilter(KennelPendingPhoto photo, int action) =>
      action == photoActionDelete
          ? photo.isDeleted
          : !photo.isDeleted && photo.status == photoActionSpec(action)?.status;

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
    // A status filter belongs to the tab it was set from — carrying it across
    // would land the reviewer on an empty list (a Pending photo has no rung).
    if (activeTab.value == tab && statusFilter.value == null) return;
    activeTab.value = tab;
    statusFilter.value = null;
    _resetPosition();
  }

  /// Tap a header count chip → show only that rung; tap it again to clear.
  void toggleStatusFilter(int action) {
    final next = statusFilter.value == action ? null : action;
    statusFilter.value = next;
    // Only reviewed photos carry a rung, so a filter implies the Reviewed tab.
    if (next != null) activeTab.value = PhotoReviewTab.reviewed;
    _resetPosition();
  }

  void clearStatusFilter() {
    if (statusFilter.value == null) return;
    statusFilter.value = null;
    _resetPosition();
  }

  /// Back to the first photo of whatever is now visible. Multi-selection is
  /// dropped: [bulkAction] works off [selectedIds] directly, so a selection
  /// surviving a filter change could silently action photos the reviewer can
  /// no longer see.
  void _resetPosition() {
    currentIndex.value = 0;
    clearSelection();
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
      final url = photos[i].effectiveUrl;
      if (url.isNotEmpty) {
        precacheImage(NetworkImage(url), ctx);
      }
    }
  }

  int? decisionFor(String photoId) => decisions[photoId];

  // ── Grid + multi-select ────────────────────────────────────────────────────

  /// Warns that the current selection will be discarded (selections are only
  /// processed via the bulk action buttons). Returns true to proceed.
  /// Cancel = default button colour (keeps selection); Switch = secondary.
  Future<bool> _confirmDiscardSelection() async {
    if (selectedIds.isEmpty) return true;
    final ctx = navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return false;
    final proceed = await showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('Photos still selected', style: ts_alertDialogTitle),
        content: Text(
          'You have ${selectedIds.length} selected '
          'photo${selectedIds.length == 1 ? '' : 's'}. Your selections will '
          'not be processed until you make a choice using one of the '
          'buttons.\n\nSwitch to single photo view anyway?',
          style: ts_alertDialogBody,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            // Default button colour — Cancel keeps the selection.
            child: Text('Cancel', style: ts_button),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade600,
              foregroundColor: Colors.white,
            ),
            child: Text('Switch', style: ts_button),
          ),
        ],
      ),
    );
    if (proceed == true) {
      clearSelection();
      return true;
    }
    return false;
  }

  /// Grid ⇄ carousel. Leaving the grid with photos still selected warns first —
  /// selections are only processed via the bulk action buttons.
  Future<void> toggleGridMode() async {
    if (gridMode.value && !await _confirmDiscardSelection()) return;
    gridMode.value = !gridMode.value;
  }

  void clearSelection() => selectedIds.clear();

  bool isSelected(String photoId) => selectedIds.contains(photoId);

  void toggleSelect(String photoId) {
    if (!selectedIds.remove(photoId)) selectedIds.add(photoId);
  }

  void selectAllVisible() {
    selectedIds.addAll(visiblePhotos.map((p) => p.photoId));
  }

  /// Long-press on a grid thumbnail → open it in the swipe view for detailed
  /// review. This also leaves the grid, so an active selection warns first.
  Future<void> openInSwipe(String photoId) async {
    if (!await _confirmDiscardSelection()) return;
    final idx = visiblePhotos.indexWhere((p) => p.photoId == photoId);
    if (idx < 0) return;
    currentIndex.value = idx;
    gridMode.value = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pageController.hasClients) pageController.jumpToPage(idx);
    });
  }

  /// Applies one action to every selected photo, then flushes to the server
  /// (reuses the same queue/batch path as single-photo review).
  Future<void> bulkAction(int action) async {
    if (selectedIds.isEmpty || isSaving.value) return;
    final ids = selectedIds.toList();

    if (action == photoActionDelete) {
      final ctx = navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      final confirmed = await showDialog<bool>(
        context: ctx,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text(
            'Delete ${ids.length} photo${ids.length == 1 ? '' : 's'}?',
            style: ts_alertDialogTitle,
          ),
          content: Text(
            'They will be hidden from the run. You can restore them at any '
            'time from the Reviewed tab.',
            style: ts_alertDialogBody,
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade600,
                foregroundColor: Colors.white,
              ),
              child: Text('Cancel', style: ts_button),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
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

    for (final id in ids) {
      _enqueue(photoId: id, action: action);
      decisions[id] = action;
    }
    clearSelection();
    await _flushQueue();
  }

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
    // Refresh the pending badge on the runs list so it immediately reflects
    // any photos just approved or rejected.
    unawaited(KennelPhotoService()
        .loadPendingPhotoSummary(kennelId, force: true));
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

  // ── Photo editing ─────────────────────────────────────────────────────────

  /// Downloads the original [blobUrl], opens the native crop UI, uploads the
  /// result, and persists it. Always starts from the original — never from
  /// [effectiveUrl] — so re-edits don't compound lossy compressions.
  Future<void> editPhoto({
    required String photoId,
    required String originalBlobUrl,
  }) async {
    if (isEditing.value) return;
    isEditing.value = true;
    try {
      final file = await _service.downloadToTempFile(originalBlobUrl);
      if (file == null) {
        Get.snackbar(
          'Edit failed',
          'Could not download the original photo. Please check your connection.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: hc_red,
          colorText: Colors.white,
        );
        return;
      }

      final cropped = await ImageCropper().cropImage(
        sourcePath: file.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        // Aspect-ratio picker sheet renders empty on iOS 26 — see
        // KennelPhotoService._onEdit.
        uiSettings: [IOSUiSettings(aspectRatioPickerButtonHidden: true)],
      );
      if (cropped == null) return; // user cancelled — not an error

      final runFolder =
          eventNumber > 0 ? '$kennelSlug-$eventNumber' : 'other';
      final editedUrl = await _service.uploadEditedPhoto(
        croppedFile: File(cropped.path),
        kennelId: kennelId,
        kennelSlug: kennelSlug,
        runFolder: runFolder,
      );
      if (editedUrl == null) {
        Get.snackbar(
          'Edit failed',
          'Could not upload the edited photo. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: hc_red,
          colorText: Colors.white,
        );
        return;
      }

      final result = await _service.updateRunPhotoEditedBlob(
        photoId: photoId,
        kennelId: kennelId,
        editedBlobUrl: editedUrl,
      );
      if (result.startsWith(ERROR_PREFIX)) {
        Get.snackbar(
          'Edit failed',
          'The edited photo was uploaded but could not be saved. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: hc_red,
          colorText: Colors.white,
        );
        return;
      }

      final idx = allPhotos.indexWhere((p) => p.photoId == photoId);
      if (idx >= 0) {
        allPhotos[idx] = allPhotos[idx].copyWithEditedBlobUrl(editedUrl);
      }
    } catch (e, s) {
      BootLogger.logError(
          '[PhotoReviewController.editPhoto] photoId=$photoId', e, s);
      Get.snackbar(
        'Edit failed',
        'An unexpected error occurred. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: hc_red,
        colorText: Colors.white,
      );
    } finally {
      isEditing.value = false;
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
    required this.kennelSlug,
    this.kennelLogoUrl,
    this.kennelShortName,
  }) : controller = _freshController(kennelId, eventId, kennelSlug, eventNumber ?? 0);

  final String kennelId;
  final String eventId;
  final String eventName;
  final int? eventNumber;
  final String kennelSlug;
  final String? kennelLogoUrl;
  final String? kennelShortName;
  final PhotoReviewController controller;

  static PhotoReviewController _freshController(
      String kennelId, String eventId, String kennelSlug, int eventNumber) {
    final tag = 'photo-review-$eventId';
    Get.delete<PhotoReviewController>(tag: tag, force: true);
    return Get.put(
      PhotoReviewController(
        kennelId: kennelId,
        eventId: eventId,
        kennelSlug: kennelSlug,
        eventNumber: eventNumber,
      ),
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
              Expanded(child: _PhotoBody(page: this)),
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
      final activeFilter = page.controller.statusFilter.value;
      // Counts keyed by the Status each chip represents, so the chip row can be
      // generated straight from the ladder in [photoActionSpecs].
      final countsByStatus = <int, int>{
        0: c.private,
        2: c.shared,
        3: c.runGallery,
        4: c.homeGallery,
        5: c.eventCover,
      };
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
                  // One chip per ladder rung, in the same order and colours as
                  // the action buttons (see [photoActionSpecs]). Tapping a chip
                  // filters the photos below to that rung; tapping it again
                  // clears the filter. Chips with no photos aren't tappable.
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: [
                      if (c.pending > 0)
                        _CountChip(
                          label: 'Pending',
                          count: c.pending,
                          color: photoPendingColor,
                          // Pending is a whole tab, not a rung filter.
                          onTap: () => page.controller
                              .switchTab(PhotoReviewTab.pending),
                          isDimmed: activeFilter != null,
                        ),
                      for (final spec in photoActionSpecs)
                        if (spec.status != null)
                          _CountChip(
                            label: spec.tagLabel,
                            count: countsByStatus[spec.status] ?? 0,
                            color: spec.color,
                            onTap: (countsByStatus[spec.status] ?? 0) > 0
                                ? () => page.controller
                                    .toggleStatusFilter(spec.action)
                                : null,
                            isActive: activeFilter == spec.action,
                            isDimmed: activeFilter != null &&
                                activeFilter != spec.action,
                          ),
                      if (c.deleted > 0)
                        _CountChip(
                          label: photoActionSpec(photoActionDelete)!.tagLabel,
                          count: c.deleted,
                          color: hc_red,
                          onTap: () => page.controller
                              .toggleStatusFilter(photoActionDelete),
                          isActive: activeFilter == photoActionDelete,
                          isDimmed: activeFilter != null &&
                              activeFilter != photoActionDelete,
                        ),
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
  const _CountChip({
    required this.label,
    required this.count,
    required this.color,
    this.onTap,
    this.isActive = false,
    this.isDimmed = false,
  });
  final String label;
  final int count;
  final Color color;

  /// Null makes the chip a plain badge with no tap target.
  final VoidCallback? onTap;

  /// This chip's filter is the one currently applied.
  final bool isActive;

  /// Some other chip's filter is applied.
  final bool isDimmed;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: isDimmed ? color.withValues(alpha: 0.4) : color,
        borderRadius: BorderRadius.circular(20),
        // Always drawn so activating a chip doesn't reflow the Wrap.
        border: Border.all(
          color: isActive ? Colors.white : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Text(
        '$count $label',
        style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600),
      ),
    );
    if (onTap == null) return chip;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: chip,
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
            const SizedBox(width: 12),
            // Grid ⇄ carousel toggle — lives with the content it switches.
            GestureDetector(
              onTap: () => unawaited(controller.toggleGridMode()),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: controller.gridMode.value ? hc_red : Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  controller.gridMode.value
                      ? Icons.view_carousel_outlined
                      : Icons.grid_view,
                  color: Colors.white,
                  size: 20,
                ),
              ),
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
  const _PhotoBody({required this.page});
  final PhotoReviewPage page;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final photos = page.controller.visiblePhotos;
      final tab = page.controller.activeTab.value;

      if (photos.isEmpty) {
        // A filter emptying the list is a different situation from a genuinely
        // empty tab — say so, and give the reviewer a way back.
        final filterSpec =
            photoActionSpec(page.controller.statusFilter.value);
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  filterSpec != null
                      ? Icons.filter_alt_off_outlined
                      : tab == PhotoReviewTab.pending
                          ? Icons.check_circle_outline
                          : Icons.photo_library_outlined,
                  color: Colors.white54,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  filterSpec != null
                      ? 'No ${filterSpec.tagLabel} photos left.'
                      : tab == PhotoReviewTab.pending
                          ? 'All photos reviewed for this run.'
                          : 'No reviewed photos yet.',
                  style: ts_bodyYellow,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  filterSpec != null
                      ? 'The ${filterSpec.tagLabel} filter is on.'
                      : tab == PhotoReviewTab.pending
                          ? 'Switch to Reviewed to see previously actioned photos.'
                          : 'Photos you action will appear here.',
                  style: ts_bodySmall.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                if (filterSpec != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: page.controller.clearStatusFilter,
                    icon: const Icon(Icons.clear, size: 18),
                    label: Text('Show all photos', style: ts_button),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hc_red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }

      if (page.controller.gridMode.value) {
        return _PhotoGrid(controller: page.controller);
      }

      return Column(
        children: [
          _PhotoCounter(controller: page.controller),
          Expanded(child: _PhotoPageView(controller: page.controller)),
          _ActionPanel(controller: page.controller),
        ],
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Thumbnail grid + multi-select
// ---------------------------------------------------------------------------

/// Short status tag + colour for a photo, shown as a corner chip in the grid.
/// Labels and colours come from [photoActionSpecs] so the grid tag, the
/// carousel badge and the action buttons can never disagree.
({String label, Color color}) _photoStatusTag(KennelPendingPhoto photo) {
  // Deleted stays grey rather than the Delete button's red — in the grid it
  // reads as "hidden", not as a call to action.
  if (photo.isDeleted) return (label: 'Deleted', color: Colors.grey.shade700);
  if (photo.status == 1) return (label: 'Pending', color: photoPendingColor);
  final spec = photoActionSpec(photoActionForStatus(photo.status));
  if (spec == null) return (label: '', color: Colors.black54);
  return (label: spec.tagLabel, color: spec.color);
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({required this.controller});
  final PhotoReviewController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final photos = controller.visiblePhotos;
      return Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.black38,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Text(
              'Tap to select · long-press to open a photo',
              style: ts_bodySmall.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemCount: photos.length,
              itemBuilder: (context, i) {
                final p = photos[i];
                return GestureDetector(
                  onTap: () => controller.toggleSelect(p.photoId),
                  onLongPress: () => controller.openInSwipe(p.photoId),
                  // Per-item Obx: GridView builds items lazily during layout,
                  // OUTSIDE the enclosing Obx's tracking scope — without this
                  // the check indicators never rebuild on selection changes.
                  child: Obx(
                    () => _GridThumb(
                      photo: p,
                      selected: controller.isSelected(p.photoId),
                    ),
                  ),
                );
              },
            ),
          ),
          _BulkActionBar(controller: controller),
        ],
      );
    });
  }
}

class _GridThumb extends StatelessWidget {
  const _GridThumb({
    required this.photo,
    required this.selected,
  });
  final KennelPendingPhoto photo;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tag = _photoStatusTag(photo);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: photo.effectiveUrl,
            fit: BoxFit.cover,
            // 3-column thumbnail grid — decode small, not full-res.
            memCacheWidth: 500,
            placeholder: (_, _) => Container(color: Colors.black26),
            errorWidget: (_, _, _) => Container(
              color: Colors.black26,
              child: const Icon(Icons.broken_image, color: Colors.white38),
            ),
          ),
          if (tag.label.isNotEmpty)
            Positioned(
              left: 4,
              top: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: tag.color.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          // Selection indicator only — no overlay tint, so the photo stays
          // fully visible while selected.
          Positioned(
            right: 4,
            top: 4,
            child: Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? Colors.green : Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulkActionBar extends StatelessWidget {
  const _BulkActionBar({required this.controller});
  final PhotoReviewController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final count = controller.selectedIds.length;
      return Container(
        // Transparent so the jungle background runs to the bottom of the page.
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  '$count selected',
                  style: ts_button.copyWith(color: Colors.white),
                ),
                const Spacer(),
                TextButton(
                  onPressed: controller.selectAllVisible,
                  child: Text('Select all', style: ts_button),
                ),
                // Both buttons carry the themed red background, so without a
                // gap they read as one pill.
                const SizedBox(width: 10),
                TextButton(
                  onPressed: controller.clearSelection,
                  child: Text(
                    'Clear',
                    style: ts_button.copyWith(color: Colors.white70),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            PhotoActionButtonBar(
              onAction: (action) => unawaited(controller.bulkAction(action)),
              // Nothing selected → whole bar greys out. Cover Photo also needs
              // exactly one photo: the SP demotes any previous cover, so a
              // multi-selection would leave an arbitrary winner.
              isEnabled: (spec) => spec.singleTargetOnly
                  ? count == 1
                  : count > 0,
            ),
          ],
        ),
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
            if (photo.effectiveUrl.isNotEmpty)
              Image.network(
                photo.effectiveUrl,
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
                    '  url: ${photo.effectiveUrl}\n  err: $err',
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

            // Crop/edit button — top-left, opposite the status badge.
            Obx(() => Positioned(
              top: 10,
              left: 10,
              child: controller.isEditing.value
                  ? const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                          color: Colors.white70, strokeWidth: 2.5),
                    )
                  : GestureDetector(
                      onTap: () => unawaited(controller.editPhoto(
                        photoId: photo.photoId,
                        originalBlobUrl: photo.blobUrl,
                      )),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.crop,
                            color: Colors.white70, size: 18),
                      ),
                    ),
            )),

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
              // Status 1 = pending → no producing action, so no badge yet.
              final committed = photo.isDeleted
                  ? photoActionDelete
                  : photoActionForStatus(photo.status);
              final spec = photoActionSpec(queued ?? committed);
              if (spec == null) return const SizedBox.shrink();
              final color = spec.color;
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
                        spec.tagLabel,
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
}

// ---------------------------------------------------------------------------
// Action panel
// ---------------------------------------------------------------------------

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({required this.controller});
  final PhotoReviewController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final photos = controller.visiblePhotos;
      if (photos.isEmpty) return const SizedBox.shrink();
      final idx =
          controller.currentIndex.value.clamp(0, photos.length - 1);
      final photo = photos[idx];

      // Queued decision takes priority; fall back to committed status. Every
      // action is a rung of one ladder — mutually exclusive, one tag at a
      // time. To un-feature, pick a lower rung.
      final int? selected = controller.decisionFor(photo.photoId) ??
          (photo.isDeleted
              ? photoActionDelete
              : photoActionForStatus(photo.status));

      return Container(
        color: Colors.black54,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
        child: PhotoActionButtonBar(
          selectedAction: selected,
          dimUnselected: true,
          onAction: (action) => unawaited(controller.actionPhoto(
            photoId: photo.photoId,
            action: action,
            context: context,
          )),
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
                  child: Text('Clear', style: ts_button),
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
