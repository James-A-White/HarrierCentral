// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hcportal/imports.dart';

// ── Photo status labels ──────────────────────────────────────────────────────

const _kStatusLabels = <int, String>{
  0: 'Private',
  2: 'Shared',
  3: 'Gallery',
  4: 'Home Gallery',
  5: 'Event Cover',
};

// ── Model ────────────────────────────────────────────────────────────────────

class _Photo {
  _Photo({
    required this.photoId,
    required this.blobUrl,
    required this.uploaderDisplayName,
    required this.status,
    required this.createdAt,
    this.deletedAt,
    this.description,
    this.title,
  });

  factory _Photo.fromJson(Map<String, dynamic> json) {
    return _Photo(
      photoId: json['photoId']?.toString() ?? '',
      blobUrl: json['BlobUrl']?.toString() ?? '',
      uploaderDisplayName: json['uploaderDisplayName']?.toString() ?? 'Unknown',
      status: (json['Status'] as num?)?.toInt() ?? 0,
      deletedAt: json['DeletedAt'] != null
          ? DateTime.tryParse(json['DeletedAt'].toString())
          : null,
      createdAt:
          DateTime.tryParse(json['CreatedAt']?.toString() ?? '') ??
          DateTime.now(),
      description: json['Description']?.toString(),
      title: json['Title']?.toString(),
    );
  }

  final String photoId;
  final String blobUrl;
  final String uploaderDisplayName;
  final int status;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final String? description;
  final String? title;

  bool get isPending => deletedAt == null && status < 2;
  bool get isDeleted => deletedAt != null;

  String get statusLabel {
    if (isDeleted) return 'Deleted';
    return _kStatusLabels[status] ?? 'Unknown';
  }
}

// ── Controller ───────────────────────────────────────────────────────────────

class PhotoReviewController extends GetxController {
  PhotoReviewController({required this.publicKennelId, required this.eventId});

  final String publicKennelId;
  final String eventId;

  final photos = <_Photo>[].obs;
  final isLoading = true.obs;
  final errorMessage = Rxn<String>();
  final activeTab = 0.obs;
  final currentIndex = 0.obs;
  final isSaving = false.obs;

  List<_Photo> get pendingPhotos => photos.where((p) => p.isPending).toList();
  List<_Photo> get reviewedPhotos => photos.where((p) => !p.isPending).toList();
  List<_Photo> get tabPhotos =>
      activeTab.value == 0 ? pendingPhotos : reviewedPhotos;

  _Photo? get currentPhoto {
    final list = tabPhotos;
    if (list.isEmpty) return null;
    return list[currentIndex.value.clamp(0, list.length - 1)];
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(_loadPhotos());
  }

  void switchTab(int tab) {
    activeTab.value = tab;
    currentIndex.value = 0;
  }

  void prev() {
    if (currentIndex.value > 0) currentIndex.value--;
  }

  void next() {
    final max = tabPhotos.length - 1;
    if (currentIndex.value < max) currentIndex.value++;
  }

  Future<void> _loadPhotos({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    errorMessage.value = null;
    try {
      final deviceId = box.get(HIVE_DEVICE_ID) as String;
      final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
      final accessToken = Utilities.generateToken(
        deviceId,
        'hcportal_getRunAllPhotos',
        paramString: deviceSecret,
      );
      final body = <String, dynamic>{
        'queryType': 'getRunAllPhotos',
        'deviceId': deviceId,
        'accessToken': accessToken,
        'publicKennelId': publicKennelId,
        'eventId': eventId,
      };
      final result = await ServiceCommon.sendHttpPostToHC6Api(body);
      if (result.startsWith(ERROR_PREFIX)) {
        errorMessage.value = 'Failed to load photos.';
        return;
      }
      final outer = jsonDecode(result) as List<dynamic>;
      final rows = outer[0] as List<dynamic>;
      photos.value = rows
          .map((r) => _Photo.fromJson(r as Map<String, dynamic>))
          .where((p) => p.photoId.isNotEmpty && p.blobUrl.isNotEmpty)
          .toList();
    } catch (e) {
      errorMessage.value = 'Failed to load photos.';
      if (kDebugMode) debugPrint('[PhotoReviewController] _loadPhotos error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> applyAction(_Photo photo, int action) async {
    if (isSaving.value) return;
    isSaving.value = true;
    final removedIdx = tabPhotos.indexOf(photo);
    try {
      final deviceId = box.get(HIVE_DEVICE_ID) as String;
      final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
      final accessToken = Utilities.generateToken(
        deviceId,
        'hcportal_batchUpdatePhotoStatus',
        paramString: deviceSecret,
      );
      final updates =
          jsonEncode([{'photoId': photo.photoId, 'action': action}]);
      final body = <String, dynamic>{
        'queryType': 'batchUpdatePhotoStatus',
        'deviceId': deviceId,
        'accessToken': accessToken,
        'publicKennelId': publicKennelId,
        'updates': updates,
      };
      final result = await ServiceCommon.sendHttpPostToHC6Api(body);
      if (result.startsWith(ERROR_PREFIX)) {
        Get.snackbar(
          'Error',
          'Failed to update photo status.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      await _loadPhotos(silent: true);
      final newList = tabPhotos;
      currentIndex.value =
          newList.isEmpty ? 0 : removedIdx.clamp(0, newList.length - 1);
    } catch (e) {
      Get.snackbar(
        'Error',
        'An unexpected error occurred.',
        snackPosition: SnackPosition.BOTTOM,
      );
      if (kDebugMode) debugPrint('[PhotoReviewController] applyAction error: $e');
    } finally {
      isSaving.value = false;
    }
  }
}

// ── Page ─────────────────────────────────────────────────────────────────────

class PhotoReviewPage extends StatelessWidget {
  PhotoReviewPage({
    required this.publicKennelId,
    required this.eventId,
    required this.eventName,
    required this.kennelShortName,
    this.eventNumber,
    this.kennelLogo,
    super.key,
  });

  final String publicKennelId;
  final String eventId;
  final String eventName;
  final String kennelShortName;
  final int? eventNumber;
  final String? kennelLogo;

  late final PhotoReviewController _controller = _freshController();

  PhotoReviewController _freshController() {
    final tag = 'photo-review-$eventId';
    if (Get.isRegistered<PhotoReviewController>(tag: tag)) {
      unawaited(Get.delete<PhotoReviewController>(tag: tag, force: true));
    }
    return Get.put(
      PhotoReviewController(publicKennelId: publicKennelId, eventId: eventId),
      tag: tag,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _appBar(),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_controller.errorMessage.value != null) {
          return _errorState();
        }
        return Column(
          children: [
            _tabHeader(),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Expanded(
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  return constraints.maxWidth > 700
                      ? _wideLayout()
                      : _narrowLayout();
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────────

  AppBar _appBar() {
    final eventLabel = eventNumber != null
        ? '$eventName  #$eventNumber'
        : eventName;
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      foregroundColor: const Color(0xFF0F172A),
      titleSpacing: 0,
      title: Row(
        children: [
          if (kennelLogo != null && kennelLogo!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: HcNetworkImage(
                  kennelLogo!,
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  kennelShortName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w400,
                    height: 1.2,
                  ),
                ),
                Text(
                  'Photo Review — $eventLabel',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Color(0xFFE2E8F0)),
      ),
    );
  }

  // ── Tab header ─────────────────────────────────────────────────────────────

  Widget _tabHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Obx(() {
        return Row(
          children: [
            _tabPill('Pending', _controller.pendingPhotos.length, 0),
            const SizedBox(width: 8),
            _tabPill('Reviewed', _controller.reviewedPhotos.length, 1),
          ],
        );
      }),
    );
  }

  Widget _tabPill(String label, int count, int tabIndex) {
    return Obx(() {
      final active = _controller.activeTab.value == tabIndex;
      return GestureDetector(
        onTap: () => _controller.switchTab(tabIndex),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1D4ED8) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? const Color(0xFF1D4ED8)
                  : const Color(0xFFCBD5E1),
            ),
          ),
          child: Text(
            '$label  $count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: active ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      );
    });
  }

  // ── Layouts ────────────────────────────────────────────────────────────────

  Widget _wideLayout() {
    return Obx(() {
      final photo = _controller.currentPhoto;
      if (photo == null) return _emptyTab();
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _photoPane(photo)),
          const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
          SizedBox(
            width: 280,
            child: SingleChildScrollView(child: _actionPane(photo)),
          ),
        ],
      );
    });
  }

  Widget _narrowLayout() {
    return Obx(() {
      final photo = _controller.currentPhoto;
      if (photo == null) return _emptyTab();
      return SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 300, child: _photoPane(photo)),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            _actionPane(photo),
          ],
        ),
      );
    });
  }

  // ── Photo pane ─────────────────────────────────────────────────────────────

  Widget _photoPane(_Photo photo) {
    return Obx(() {
      final list = _controller.tabPhotos;
      final idx = _controller.currentIndex.value;
      return Container(
        color: const Color(0xFF0F172A),
        child: Stack(
          children: [
            Positioned.fill(
              child: HcNetworkImage(
                photo.blobUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white38,
                    size: 48,
                  ),
                ),
              ),
            ),
            if (photo.description != null && photo.description!.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 48,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  color: Colors.black.withValues(alpha: 0.65),
                  child: Text(
                    photo.description!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left,
                          color: Colors.white, size: 22),
                      onPressed: idx > 0 ? _controller.prev : null,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                    Text(
                      '${idx + 1} of ${list.length}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right,
                          color: Colors.white, size: 22),
                      onPressed: idx < list.length - 1
                          ? _controller.next
                          : null,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── Action pane ────────────────────────────────────────────────────────────

  Widget _actionPane(_Photo photo) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _metaRow(Icons.person_outline, photo.uploaderDisplayName),
          const SizedBox(height: 6),
          _metaRow(Icons.schedule, _formatDate(photo.createdAt)),
          const SizedBox(height: 8),
          _statusBadge(photo),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),
          _actionBtn(
            'Delete',
            Icons.delete_outline,
            _BtnStyle.danger,
            () => _controller.applyAction(photo, 1),
          ),
          const SizedBox(height: 8),
          _actionBtn(
            'Keep Private',
            Icons.lock_outline,
            _BtnStyle.secondary,
            () => _controller.applyAction(photo, 2),
          ),
          const SizedBox(height: 8),
          _actionBtn(
            'Approve (Share)',
            Icons.check_circle_outline,
            _BtnStyle.success,
            () => _controller.applyAction(photo, 3),
          ),
          const SizedBox(height: 8),
          _actionBtn(
            'Gallery',
            Icons.photo_library_outlined,
            _BtnStyle.primary,
            () => _controller.applyAction(photo, 4),
          ),
          const SizedBox(height: 8),
          _actionBtn(
            'Home Gallery',
            Icons.home_outlined,
            _BtnStyle.primary,
            () => _controller.applyAction(photo, 5),
          ),
          const SizedBox(height: 8),
          _actionBtn(
            'Event Cover',
            Icons.star_outline,
            _BtnStyle.primary,
            () => _controller.applyAction(photo, 6),
          ),
        ],
      ),
    );
  }

  // ── Shared widgets ─────────────────────────────────────────────────────────

  Widget _metaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(_Photo photo) {
    final (bg, fg) = _statusColors(photo);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          photo.statusLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: fg,
          ),
        ),
      ),
    );
  }

  (Color, Color) _statusColors(_Photo photo) {
    if (photo.isDeleted) {
      return (const Color(0xFFFEE2E2), const Color(0xFFB91C1C));
    }
    return switch (photo.status) {
      0 => (const Color(0xFFF1F5F9), const Color(0xFF475569)),
      2 => (const Color(0xFFDCFCE7), const Color(0xFF15803D)),
      3 || 4 || 5 => (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)),
      _ => (const Color(0xFFF1F5F9), const Color(0xFF475569)),
    };
  }

  Widget _actionBtn(
    String label,
    IconData icon,
    _BtnStyle style,
    VoidCallback onPressed,
  ) {
    return Obx(() {
      final saving = _controller.isSaving.value;
      final (bg, fg, border) = switch (style) {
        _BtnStyle.danger => (
            const Color(0xFFFEF2F2),
            const Color(0xFFB91C1C),
            const Color(0xFFFCA5A5),
          ),
        _BtnStyle.secondary => (
            Colors.white,
            const Color(0xFF374151),
            const Color(0xFFE2E8F0),
          ),
        _BtnStyle.success => (
            const Color(0xFFF0FDF4),
            const Color(0xFF15803D),
            const Color(0xFF86EFAC),
          ),
        _BtnStyle.primary => (
            const Color(0xFFEFF6FF),
            const Color(0xFF1D4ED8),
            const Color(0xFFBFDBFE),
          ),
      };
      return TextButton(
        style: TextButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(double.infinity, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        onPressed: saving ? null : onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon, size: 16),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
      );
    });
  }

  Widget _emptyTab() {
    final isPending = _controller.activeTab.value == 0;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPending
                ? Icons.check_circle_outline
                : Icons.photo_library_outlined,
            size: 48,
            color: const Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 12),
          Text(
            isPending
                ? 'No photos pending review'
                : 'No reviewed photos yet',
            style: const TextStyle(fontSize: 15, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          Text(
            _controller.errorMessage.value ?? 'Failed to load photos.',
            style: const TextStyle(fontSize: 15, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDate(DateTime dt) {
    return '${dt.day} ${_months[dt.month - 1]} ${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ── Button style ──────────────────────────────────────────────────────────────

enum _BtnStyle { danger, secondary, success, primary }
