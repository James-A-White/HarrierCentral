import 'package:hcportal/imports.dart';

// ---------------------------------------------------------------------------
// Newsflash startup dialog
//
// Shows pending newsflashes one at a time. The full list is received from
// the server and iterated client-side so no additional round trips are
// needed between each newsflash.
// ---------------------------------------------------------------------------

Future<void> showPendingNewsflashes(List<NewsflashModel> newsflashes) async {
  if (newsflashes.isEmpty) return;
  await _showNewsflash(newsflashes, 0);
}

Future<void> _showNewsflash(
    List<NewsflashModel> newsflashes, int index) async {
  if (index >= newsflashes.length) return;
  final nf = newsflashes[index];

  await Get.dialog<void>(
    _NewsflashDialog(
      newsflash: nf,
      onDismissed: () async {
        Get.back<void>();
        await respondToNewsflash(nf.newsflashId, isDismissed: true);
        await _showNewsflash(newsflashes, index + 1);
      },
      onReadLater: () async {
        Get.back<void>();
        await respondToNewsflash(nf.newsflashId, isDismissed: false);
      },
    ),
    barrierDismissible: false,
  );
}

// ---------------------------------------------------------------------------
// Dialog widget
// ---------------------------------------------------------------------------

class _NewsflashDialog extends StatelessWidget {
  const _NewsflashDialog({
    required this.newsflash,
    required this.onDismissed,
    required this.onReadLater,
  });

  final NewsflashModel newsflash;
  final VoidCallback onDismissed;
  final VoidCallback onReadLater;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 400, maxWidth: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image (optional)
            if (newsflash.imageUrl != null && newsflash.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 30, 30, 0),
                child: HcNetworkImage(
                  newsflash.imageUrl!,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (_, error, __) {
                    debugPrint('Newsflash image load error: $error');
                    return const SizedBox.shrink();
                  },
                ),
              ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      newsflash.title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Body
                    Text(
                      newsflash.bodyText,
                      style: const TextStyle(
                        fontSize: 20,
                        height: 1.6,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onReadLater,
                    child: const Text('Read Later'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: onDismissed,
                    child: const Text("I've read it"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
