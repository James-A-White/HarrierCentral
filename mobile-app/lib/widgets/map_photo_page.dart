import 'package:harrier_central/imports.dart';
import 'package:photo_view/photo_view_gallery.dart';

class MapPhotoItem {
  const MapPhotoItem({
    required this.imageUrl,
    required this.caption,
    this.uploaderName = '',
    this.uploaderPhotoUrl = '',
    this.photoId,
    this.originalBlobUrl,
    this.kennelId,
    this.kennelSlug,
    this.eventNumber,
  });
  final String imageUrl;
  final String caption;
  final String uploaderName;
  final String uploaderPhotoUrl;

  // Edit support — populated only for own photos when the caller knows the user
  // can edit (Hash Flash / GM / VGM / RA role). Null for others' photos and
  // for the guest gallery.
  final String? photoId;
  /// Original unedited blob URL — always start re-edits from here, never from imageUrl.
  final String? originalBlobUrl;
  final String? kennelId;
  final String? kennelSlug;
  final int? eventNumber;

  bool get isEditable => photoId != null && kennelId != null && kennelSlug != null;

  MapPhotoItem withImageUrl(String newUrl) => MapPhotoItem(
        imageUrl: newUrl,
        caption: caption,
        uploaderName: uploaderName,
        uploaderPhotoUrl: uploaderPhotoUrl,
        photoId: photoId,
        originalBlobUrl: originalBlobUrl,
        kennelId: kennelId,
        kennelSlug: kennelSlug,
        eventNumber: eventNumber,
      );
}

class MapPhotoPage extends StatefulWidget {
  const MapPhotoPage({
    super.key,
    required this.pageTitle,
    required this.photos,
    required this.initialIndex,
    required this.background,
  });

  final String pageTitle;
  final List<MapPhotoItem> photos;
  final int initialIndex;
  final BoxDecoration background;

  @override
  State<MapPhotoPage> createState() => _MapPhotoPageState();
}

class _MapPhotoPageState extends State<MapPhotoPage> {
  late int _currentIndex;
  late final PageController _pageController;
  final ScrollController _scrollController = ScrollController();

  // Mutable local copy — updated when an edit is saved so the gallery
  // immediately reflects the new cropped image.
  late List<MapPhotoItem> _photos;
  bool _isEditing = false;
  final KennelPhotoService _service = KennelPhotoService();

  double _captionTop = 0;
  double _maxCaptionTop = 0;
  // Minimum _captionTop: expansion is capped once all text is visible + buffer.
  // Set after first layout via _checkOverflowAfterFrame; reset to 0 on page change.
  double _minCaptionTop = 0;
  double _screenHeight = 0;
  double _maskOpacity = 0.0;
  bool _hasInitialOverflow = false;
  bool _heightsInitialized = false;

  // Approximate line height for the ts_body style.
  static const double _lineHeight = 22.0;
  static const int _initialLines = 5;
  static const double _captionTopPadding = 16.0;
  // Bottom padding leaves room for the scroll indicator arrow.
  static const double _captionBottomPadding = 40.0;
  // Stop expanding this many px below the bottom of the screen once all text fits.
  static const double _expansionBuffer = 40.0;

  MapPhotoItem get _currentPhoto => _photos[_currentIndex];

  @override
  void initState() {
    super.initState();
    _photos = List.of(widget.photos);
    _currentIndex = widget.initialIndex.clamp(0, _photos.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    // Rebuild on scroll so the _showArrow getter re-evaluates.
    _scrollController.addListener(() => setState(() {}));
    _checkOverflowAfterFrame();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_heightsInitialized) {
      _heightsInitialized = true;
      final mq = MediaQuery.of(context);
      _screenHeight = mq.size.height;
      final initialHeight = (_initialLines * _lineHeight) +
          _captionTopPadding +
          mq.padding.bottom +
          _captionBottomPadding;
      _maxCaptionTop = (_screenHeight - initialHeight).clamp(0.0, _screenHeight);
      _captionTop = _maxCaptionTop;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _checkOverflowAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final pos = _scrollController.position;
      final contentHeight = pos.viewportDimension + pos.maxScrollExtent;
      setState(() {
        _hasInitialOverflow = pos.maxScrollExtent > 0;
        // Cap expansion: the panel only needs to grow tall enough to show all
        // text plus the bottom buffer. If text already fits at initial height,
        // this matches _maxCaptionTop so the panel won't expand at all.
        // If text is longer than the screen, clamp to 0 (allow full-screen).
        _minCaptionTop =
            (_screenHeight - contentHeight - _expansionBuffer)
                .clamp(0.0, _maxCaptionTop);
      });
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _captionTop = _maxCaptionTop;
      _maskOpacity = 0.0;
      _hasInitialOverflow = false;
      _minCaptionTop = 0; // recalculated in _checkOverflowAfterFrame below
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    _checkOverflowAfterFrame();
  }

  void _navigateTo(int index) {
    if (index < 0 || index >= _photos.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Arrow is visible while there is more caption content the user hasn't seen.
  bool get _showArrow {
    if (!_hasInitialOverflow) return false;
    if (_captionTop > _minCaptionTop) return true;
    if (!_scrollController.hasClients) return true;
    final maxExtent = _scrollController.position.maxScrollExtent;
    if (maxExtent <= 0) return false;
    return _scrollController.offset < maxExtent - 4;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final dy = details.delta.dy;
    setState(() {
      if (dy < 0) {
        // Dragging up: expand container first, then scroll content.
        if (_captionTop > _minCaptionTop) {
          _captionTop =
              (_captionTop + dy).clamp(_minCaptionTop, _maxCaptionTop);
        } else if (_scrollController.hasClients) {
          _scrollController.jumpTo(
            (_scrollController.offset - dy)
                .clamp(0.0, _scrollController.position.maxScrollExtent),
          );
        }
      } else {
        // Dragging down: scroll content back first, then collapse container.
        if (_scrollController.hasClients && _scrollController.offset > 0) {
          _scrollController.jumpTo(
            (_scrollController.offset - dy)
                .clamp(0.0, _scrollController.position.maxScrollExtent),
          );
        } else {
          _captionTop =
              (_captionTop + dy).clamp(_minCaptionTop, _maxCaptionTop);
        }
      }
      _updateMask();
    });
  }

  // Mask fades from 0 → 0.5 over 6 lines of expansion, starting at 3 lines
  // above the initial position. Slow fade so it doesn't feel abrupt.
  void _updateMask() {
    final expanded = _maxCaptionTop - _captionTop;
    final x = expanded - _lineHeight * 3;
    _maskOpacity = (x / (_lineHeight * 6) * 0.5).clamp(0.0, 0.5);
  }

  Future<void> _editPhoto() async {
    final photo = _currentPhoto;
    if (!photo.isEditable || _isEditing) return;
    setState(() => _isEditing = true);
    try {
      // Always start from the original unedited blob so re-edits don't stack.
      final sourceUrl = photo.originalBlobUrl ?? photo.imageUrl;
      final file = await _service.downloadToTempFile(sourceUrl);
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
      );
      if (cropped == null) return; // user cancelled — not an error

      final eventNumber = photo.eventNumber ?? 0;
      final kennelSlug = photo.kennelSlug!;
      final runFolder =
          eventNumber > 0 ? '$kennelSlug-$eventNumber' : 'other';

      final editedUrl = await _service.uploadEditedPhoto(
        croppedFile: File(cropped.path),
        kennelId: photo.kennelId!,
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
        photoId: photo.photoId!,
        kennelId: photo.kennelId!,
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

      // Update the local list — imageUrl shows the crop, originalBlobUrl stays.
      setState(() {
        _photos[_currentIndex] = photo.withImageUrl(editedUrl);
      });
    } catch (e, s) {
      BootLogger.logError('[MapPhotoPage._editPhoto]', e, s);
      Get.snackbar(
        'Edit failed',
        'An unexpected error occurred. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: hc_red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isEditing = false);
    }
  }

  ImageProvider _imageProvider(String url) {
    return url.toLowerCase().endsWith('.avif')
        ? CachedNetworkAvifImageProvider(url)
        : CachedNetworkImageProvider(url);
  }

  // Builds the photo widget for one gallery page. The ColorFiltered overlay
  // uses BlendMode.srcATop so the black tint is applied only to the opaque
  // photo pixels — transparent letterbox areas remain clear and the jungle
  // background decoration shows through unchanged.
  Widget _buildPhotoChild(String imageUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: SizedBox.expand(
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: _maskOpacity),
            BlendMode.srcATop,
          ),
          child: Image(
            image: _imageProvider(imageUrl),
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white54),
                  ),
            errorBuilder: (_, _, _) => const Center(
              child: Icon(Icons.broken_image, color: Colors.white38, size: 64),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_photos.isEmpty) return const SizedBox.shrink();

    final bottomInset = MediaQuery.of(context).padding.bottom;
    final caption = _currentPhoto.caption;

    // Corner radius shrinks to zero as the caption panel fills the screen.
    final cornerRadius = _maxCaptionTop > 0
        ? (_captionTop / _maxCaptionTop).clamp(0.0, 1.0) * 14.0
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
        title: AutoSizeText(
          _photos.length > 1
              ? '${widget.pageTitle} (${_currentIndex + 1} of ${_photos.length})'
              : widget.pageTitle,
          style: ts_appBarTitle,
          textAlign: TextAlign.center,
          minFontSize: 2.0,
          maxLines: 1,
        ),
      ),
      body: Stack(
        children: [
          // Photo gallery — full screen.
          // Each page uses customChild + ColorFiltered(BlendMode.srcATop) so the
          // black overlay dims only the photo pixels. The backgroundDecoration
          // (jungle) shows through the transparent letterbox areas unaffected.
          // PhotoViewGallery handles the 1x-vs-zoomed gesture split automatically.
          Positioned.fill(
            child: PhotoViewGallery(
              pageController: _pageController,
              onPageChanged: _onPageChanged,
              backgroundDecoration: widget.background,
              scrollPhysics: const ClampingScrollPhysics(),
              pageOptions: List.generate(
                _photos.length,
                (i) => PhotoViewGalleryPageOptions.customChild(
                  child: _buildPhotoChild(_photos[i].imageUrl),
                  minScale: 0.1,
                  maxScale: 100.0,
                ),
              ),
            ),
          ),

          // Uploader chip — top-right, just below the AppBar.
          // Hidden when the name is unknown (e.g. hasher not yet synced locally).
          if (_currentPhoto.uploaderName.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: hc_red.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                        image: _currentPhoto.uploaderPhotoUrl.isNotEmpty
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(
                                  _currentPhoto.uploaderPhotoUrl,
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _currentPhoto.uploaderPhotoUrl.isEmpty
                          ? Center(
                              child: Text(
                                _currentPhoto.uploaderName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      _currentPhoto.uploaderName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Crop button — top-left, only for own editable photos.
          if (_currentPhoto.isEditable)
            Positioned(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
              left: 12,
              child: _isEditing
                  ? const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                          color: Colors.white70, strokeWidth: 2.5),
                    )
                  : GestureDetector(
                      onTap: _editPhoto,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.crop,
                            color: Colors.white70, size: 18),
                      ),
                    ),
            ),

          // Caption overlay — a Positioned panel that starts at the bottom and
          // expands upward as the user drags vertically.
          // HitTestBehavior.opaque absorbs all touches in the panel area so they
          // don't reach the gallery. Horizontal swipes with sufficient velocity
          // are forwarded to the page controller for navigation.
          if (caption.isNotEmpty)
            Positioned(
              top: _captionTop,
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: _handleDragUpdate,
                onHorizontalDragEnd: _photos.length > 1
                    ? (details) {
                        final dx = details.velocity.pixelsPerSecond.dx;
                        if (dx.abs() < 300) return;
                        _navigateTo(dx < 0
                            ? _currentIndex + 1
                            : _currentIndex - 1);
                      }
                    : null,
                child: Stack(
                  children: [
                    // Transparent panel — no background fill. The photo mask
                    // (applied inside the gallery via ColorFiltered) provides
                    // contrast. Text shadow handles readability on bright photos.
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(cornerRadius),
                          ),
                        ),
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          // Scroll is driven manually from onVerticalDragUpdate
                          // so that it composes cleanly with the expand gesture.
                          physics: const NeverScrollableScrollPhysics(),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              24,
                              _captionTopPadding,
                              24,
                              bottomInset + _captionBottomPadding,
                            ),
                            child: Text(
                              caption,
                              style: ts_body.copyWith(
                                shadows: const [
                                  Shadow(
                                    color: Colors.black54,
                                    offset: Offset(0, 1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Scroll indicator — down arrow at the bottom of the panel.
                    // Visible while there is more caption content below the
                    // current viewport.
                    Positioned(
                      bottom: bottomInset + 6,
                      left: 0,
                      right: 0,
                      child: AnimatedOpacity(
                        opacity: _showArrow ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: const Center(
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white70,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
