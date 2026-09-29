// The photos of one chat, one at a time (E9.F1.S11, 2026-09-29).
//
// CLAUDE.md: a trail photo is never a dead end — a carousel, opened AT the
// photo clicked, the photo whole at its own aspect ratio (BoxFit.contain),
// on the portal's light hash-foot backdrop with the photo on a dark
// translucent pane.

import 'package:hcportal/imports.dart';

class ChatPhotoCarouselController extends GetxController {
  ChatPhotoCarouselController({required this.urls, required int initialIndex})
    : index = initialIndex.clamp(0, urls.isEmpty ? 0 : urls.length - 1).obs;

  final List<String> urls;
  final RxInt index;
  late final PageController pageController = PageController(
    initialPage: index.value,
  );

  void onPageChanged(int i) => index.value = i;

  void previous() {
    if (index.value <= 0) return;
    unawaited(
      pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      ),
    );
  }

  void next() {
    if (index.value >= urls.length - 1) return;
    unawaited(
      pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      ),
    );
  }

  Future<void> openOriginal() async {
    if (urls.isEmpty) return;
    await launchUrl(Uri.parse(urls[index.value]), webOnlyWindowName: '_blank');
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}

class ChatPhotoCarouselPage extends StatelessWidget {
  ChatPhotoCarouselPage({
    required this.urls,
    required this.initialIndex,
    required this.title,
    super.key,
  });

  final List<String> urls;
  final int initialIndex;
  final String title;

  late final ChatPhotoCarouselController c = Get.put(
    ChatPhotoCarouselController(urls: urls, initialIndex: initialIndex),
    tag: _tag,
  );
  // One controller per opening, so a second opening never inherits the first
  // one's photo list.
  final String _tag = UniqueKey().toString();

  static const _pane = Color(0xB3000000); // black 70% — the photo's pane

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(
            urls.length > 1
                ? '$title — ${c.index.value + 1} of ${urls.length}'
                : title,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Open the original in a new tab',
            icon: const Icon(Icons.open_in_new),
            onPressed: c.openOriginal,
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: Backgrounds.defaultHcBackgroundLight(),
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowLeft): c.previous,
            const SingleActivator(LogicalKeyboardKey.arrowRight): c.next,
          },
          child: Focus(
            autofocus: true,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _pane,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: PageView.builder(
                        controller: c.pageController,
                        onPageChanged: c.onPageChanged,
                        itemCount: urls.length,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.all(16),
                          child: InteractiveViewer(
                            maxScale: 6,
                            child: Center(
                              child: Image.network(
                                urls[i],
                                fit: BoxFit.contain,
                                loadingBuilder: (_, child, progress) =>
                                    progress == null
                                    ? child
                                    : const CircularProgressIndicator(
                                        color: Colors.white70,
                                      ),
                                errorBuilder: (_, _, _) => const Text(
                                  'This photo could not be loaded.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (urls.length > 1) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Obx(
                        () => _arrow(
                          Icons.chevron_left,
                          'Previous photo',
                          c.index.value > 0 ? c.previous : null,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Obx(
                        () => _arrow(
                          Icons.chevron_right,
                          'Next photo',
                          c.index.value < urls.length - 1 ? c.next : null,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _arrow(IconData icon, String tooltip, VoidCallback? onPressed) =>
      Padding(
        padding: const EdgeInsets.all(8),
        child: IconButton.filled(
          tooltip: tooltip,
          iconSize: 32,
          style: IconButton.styleFrom(
            backgroundColor: Colors.black54,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.black12,
            disabledForegroundColor: Colors.white24,
          ),
          icon: Icon(icon),
          onPressed: onPressed,
        ),
      );
}
