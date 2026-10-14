import 'package:harrier_central/imports.dart';
import 'package:harrier_central/util/social_links.dart';

/// A kennel's social and chat links (E12.F4.S4) as a centred, wrapping row of
/// brand icons on the kennel page. Draws NOTHING for an empty list — the page
/// passes an empty list while loading and on failure, so there is no spinner
/// and no placeholder flash.
///
/// Sits on the dark jungle background: captions are white70, each glyph sits
/// on a white disc so it keeps its brand colour.
class KennelSocialLinksRow extends StatelessWidget {
  const KennelSocialLinksRow({super.key, required this.links});

  final List<SocialLink> links;

  @override
  Widget build(BuildContext context) {
    if (links.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.start,
        spacing: 12,
        runSpacing: 12,
        children: <Widget>[
          for (final SocialLink l in links) _SocialLinkIcon(link: l),
        ],
      ),
    );
  }
}

class _SocialLinkIcon extends StatelessWidget {
  const _SocialLinkIcon({required this.link});

  final SocialLink link;

  static const double _disc = 48;

  Future<void> _onTap() async {
    if (link.opensDialog) {
      await _showWeChatDialog(link);
      return;
    }
    if (!Utilities.isConnected(showDialog: true)) return;
    final Uri? uri = Uri.tryParse(link.url!);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      hcSnack('That link could not be opened.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = link.isMembersOnly
        ? '${link.displayName}, members only'
        : link.displayName;
    final Widget glyph = link.platform == 'signal'
        ? const MessagingPlatformGlyph(MessagingPlatform.signal, size: 26)
        : Icon(
            socialPlatformIcon(link.platform),
            color: socialPlatformColor(link.platform),
            size: 26,
          );
    return Tooltip(
      message: name,
      child: Semantics(
        button: true,
        label: name,
        excludeSemantics: true,
        child: SizedBox(
          width: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  // The ripple is the same-frame acknowledgement of the tap.
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _onTap,
                      child: SizedBox.square(
                        dimension: _disc,
                        child: Center(child: glyph),
                      ),
                    ),
                  ),
                  if (link.isMembersOnly)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white70),
                          ),
                          child: const Icon(
                            Icons.lock,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                link.label ?? socialPlatformLabel(link.platform),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// WeChat groups have no shareable URL: the kennel gives a WeChat ID to add
/// and/or a QR code to scan. The QR is shown whole (BoxFit.contain).
Future<void> _showWeChatDialog(SocialLink link) async {
  final BuildContext? ctx = Get.context;
  if (ctx == null) return;
  final String? handle = link.handle;
  final String? qr = link.qrImageUrl;
  await showDialog<void>(
    context: ctx,
    builder: (BuildContext dialogContext) => AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        link.displayName,
        style: ts_alertDialogTitle,
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            if (handle != null) ...<Widget>[
              Text(
                'WeChat ID',
                style: ts_alertDialogBody,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  SelectableText(
                    handle,
                    style: ts_alertDialogBodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  IconButton(
                    tooltip: 'Copy WeChat ID',
                    icon: const Icon(Icons.copy, color: Colors.black54),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: handle));
                      hcSnack('WeChat ID copied');
                    },
                  ),
                ],
              ),
            ],
            if (qr != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                'Scan in WeChat',
                style: ts_alertDialogBody,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260, maxHeight: 320),
                child: Image.network(
                  qr,
                  fit: BoxFit.contain,
                  loadingBuilder:
                      (
                        BuildContext _,
                        Widget child,
                        ImageChunkEvent? progress,
                      ) => progress == null
                      ? child
                      : const SizedBox(
                          height: 120,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                  errorBuilder: (BuildContext _, Object _, StackTrace? _) =>
                      Text(
                        'The QR code could not be loaded.',
                        style: ts_alertDialogBody,
                        textAlign: TextAlign.center,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text('Close', style: ts_button, textAlign: TextAlign.center),
        ),
      ],
    ),
  );
}
