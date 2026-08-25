import 'package:harrier_central/imports.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:intl/intl.dart';

class MapPhotoItem {
  const MapPhotoItem({
    required this.imageUrl,
    required this.caption,
    this.uploaderName = '',
    this.uploaderPhotoUrl = '',
    this.capturedAt,
    this.latitude,
    this.longitude,
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

  /// When the photo was taken, in UTC (rendered as local time). Null if unknown.
  final DateTime? capturedAt;

  /// Where the photo was taken. Both null when there was no location fix — the
  /// "View on map" button is hidden in that case.
  final double? latitude;
  final double? longitude;

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
        capturedAt: capturedAt,
        latitude: latitude,
        longitude: longitude,
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
    this.run,
  });

  final String pageTitle;
  final List<MapPhotoItem> photos;
  final int initialIndex;
  final BoxDecoration background;

  /// The run these photos belong to. When provided, a "View on map" button in
  /// the info footer opens the PackTrack map centered on where the photo was
  /// taken. Null (e.g. guest gallery, or opened from the map itself) hides it.
  final RunDetailsAggregate? run;

  @override
  State<MapPhotoPage> createState() => _MapPhotoPageState();
}

class _MapPhotoPageState extends State<MapPhotoPage> {
  late int _currentIndex;
  late final PageController _pageController;
  final ScrollController _scrollController = ScrollController();

  // Local working copy of the photo list.
  late List<MapPhotoItem> _photos;

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

  // Height of the always-on info footer (photographer, n-of-m, time, map
  // button), excluding the bottom safe-area inset. The caption panel reserves
  // this much extra space at its bottom so long captions clear the footer.
  static const double _footerHeight = 68.0;

  MapPhotoItem get _currentPhoto => _photos[_currentIndex];

  // Title trimmed to just the run name: drop the "Trail #NNNN - " prefix, then
  // cap at 40 chars with an ellipsis. The "n of m" count moved to the footer.
  String get _displayTitle {
    var name = widget.pageTitle.trim();
    name = name.replaceFirst(
      RegExp(r'^\s*Trail\s*#?\s*\d+\s*[-–—:]\s*', caseSensitive: false),
      '',
    );
    if (name.length > 40) name = '${name.substring(0, 40).trimRight()}…';
    return name;
  }

  @override
  void initState() {
    super.initState();
    _photos = List.of(widget.photos);
    _currentIndex = widget.initialIndex.clamp(0, _photos.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    // Rebuild only when the scroll arrow's visibility actually flips — not on
    // every scroll frame (which re-rendered the whole page + its image pager).
    _scrollController.addListener(_onCaptionScroll);
    _checkOverflowAfterFrame();
  }

  bool _lastShowArrow = false;

  void _onCaptionScroll() {
    final bool show = _showArrow;
    if (show != _lastShowArrow) {
      setState(() => _lastShowArrow = show);
    }
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
          _captionBottomPadding +
          _footerHeight;
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
        // Explicit back button so it's always present regardless of how the
        // page was presented.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: AutoSizeText(
          _displayTitle,
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

          // Prev / next navigation arrows — vertically centered on each side,
          // shown only in a multi-photo set and hidden at the ends. The
          // surrounding Positioned.fill is transparent to touches; only the
          // arrow button itself is tappable, so swipe/zoom still work.
          if (_photos.length > 1) ...[
            Positioned.fill(child: _navArrow(left: true)),
            Positioned.fill(child: _navArrow(left: false)),
          ],


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
              // End above the info footer so caption text never scrolls under
              // it (padding alone doesn't help at the top of the scroll).
              bottom: bottomInset + _footerHeight,
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
                            padding: const EdgeInsets.fromLTRB(
                              24,
                              _captionTopPadding,
                              24,
                              // Panel already ends above the footer; this is just
                              // buffer for the scroll-indicator arrow.
                              _captionBottomPadding,
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

                    // Scroll indicator — down arrow at the bottom of the panel
                    // (which now sits just above the info footer).
                    Positioned(
                      bottom: 6,
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

          // Info footer — always visible, drawn on top of everything. Carries
          // the photographer, the "n of m photos" count, the local capture
          // time, and (when possible) a button to the photo's map location.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildInfoFooter(context, bottomInset),
          ),
        ],
      ),
    );
  }

  // A single side navigation arrow, centered vertically. Returns an empty box
  // at the ends so there's nothing to tap past the first / last photo.
  Widget _navArrow({required bool left}) {
    final bool enabled =
        left ? _currentIndex > 0 : _currentIndex < _photos.length - 1;
    if (!enabled) return const SizedBox.shrink();
    return Align(
      alignment: left ? Alignment.centerLeft : Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Material(
          color: Colors.black.withValues(alpha: 0.4),
          shape: const CircleBorder(),
          child: IconButton(
            icon: Icon(
              left ? Icons.chevron_left : Icons.chevron_right,
              color: Colors.white,
              size: 32,
            ),
            onPressed: () =>
                _navigateTo(left ? _currentIndex - 1 : _currentIndex + 1),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoFooter(BuildContext context, double bottomInset) {
    final photo = _currentPhoto;
    final bool showMap = widget.run != null &&
        photo.latitude != null &&
        photo.longitude != null;

    final metaParts = <String>[
      '${_currentIndex + 1} of ${_photos.length} photo${_photos.length == 1 ? '' : 's'}',
      if (photo.capturedAt != null)
        DateFormat('d MMM, h:mm a').format(photo.capturedAt!.toLocal()),
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(14, 10, 12, bottomInset + 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.0),
            Colors.black.withValues(alpha: 0.6),
            Colors.black.withValues(alpha: 0.75),
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
      child: Row(
        children: [
          // Photographer avatar (bundle:// safe via avatarImageProvider).
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white24,
              image: DecorationImage(
                image: avatarImageProvider(photo.uploaderPhotoUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Name + meta line.
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (photo.uploaderName.isNotEmpty)
                  Text(
                    photo.uploaderName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                  ),
                Text(
                  metaParts.join('  ·  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                ),
              ],
            ),
          ),
          // View on map button.
          if (showMap) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => Get.to<void>(
                () => PackTrackFullScreenMap(
                  run: widget.run!,
                  focusPoint:
                      latlng.LatLng(photo.latitude!, photo.longitude!),
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: hc_red,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Icons.place, size: 18),
              label: const Text('Map', style: TextStyle(fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }
}
