import 'package:harrier_central/imports.dart';

enum KennelLogoZoomGesture { none, tap, longPress }

class KennelLogo extends StatelessWidget {
  const KennelLogo({
    super.key,
    this.kennelId,
    required this.kennelLogoUrl,
    required this.kennelShortName,
    required this.logoHeight,
    this.zoomGesture = KennelLogoZoomGesture.longPress,
    this.leftPadding,
    this.rightPadding,
  });

  final String? kennelId;
  final String? kennelLogoUrl;
  final String? kennelShortName;
  final double logoHeight;
  final double? leftPadding;
  final double? rightPadding;
  final KennelLogoZoomGesture zoomGesture;

  /// One of Harrier Central's generic coins stored as an image URL —
  /// `…/generic-logos/C-030.png` — which is how new kennels and the 63
  /// kennels moved off `bundle://` on 2026-09-28 carry them. Captures the
  /// coin's code (`C-030`, `C-Default`).
  static final RegExp _coinUrl = RegExp(
    r'/generic-logos/(C-[A-Za-z0-9]+)\.png$',
    caseSensitive: false,
  );

  bool get _isBundleImage => kennelLogoUrl?.contains('bundle://') ?? false;

  /// The coin's code when the logo is a generic coin given as a URL.
  String? get _coinCode => _isBundleImage
      ? null
      : _coinUrl.firstMatch(kennelLogoUrl ?? '')?.group(1);

  /// Drawn from the app's own images, with the kennel's short name written
  /// on it: a `bundle://` logo, or a generic coin given as a URL. A coin is
  /// blank artwork — the short name IS the logo (James, 2026-09-28: "when a
  /// coin is used it should overlay the kennel short name as it did when
  /// bundle was used").
  bool get _isLocalCoin => _isBundleImage || _coinCode != null;

  String? get _assetImagePath {
    final String? coin = _coinCode;
    if (coin != null) return 'images/generic_logos/$coin.png';
    if (!_isBundleImage) return null;
    final basePath = kennelLogoUrl!.toLowerCase().contains('avatar')
        ? 'images/avatars/'
        : 'images/generic_logos/';
    return '$basePath${kennelLogoUrl!.replaceAll('bundle://', '')}.png';
  }

  Future<void> _showZoomPage(BuildContext context) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return ZoomableImagePage2(
            key: const Key('11126697697'),
            file: null,
            assetImage: _assetImagePath,
            assetImageText: _isLocalCoin ? kennelShortName : null,
            imageUrl: _isLocalCoin ? null : kennelLogoUrl,
            pageTitle: 'Kennel logo',
            appBarBackgroundColor: themeAppBarBackground,
            background: Backgrounds.defaultHcBackground(),
            kennelId: kennelId,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if ((kennelLogoUrl ?? '').isEmpty) {
      return const SizedBox();
    }

    return GestureDetector(
      onTap: zoomGesture == KennelLogoZoomGesture.tap
          ? () => _showZoomPage(context)
          : null,
      onLongPress: zoomGesture == KennelLogoZoomGesture.longPress
          ? () => _showZoomPage(context)
          : null,
      child: Container(
        width: logoHeight,
        height: logoHeight,
        margin: EdgeInsets.only(
          left: leftPadding ?? 0,
          right: rightPadding ?? 0,
        ),
        alignment: Alignment.centerRight,
        child: _isLocalCoin
            ? Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(_assetImagePath!),
                  if (!(kennelShortName ?? '').toLowerCase().contains(
                    'my runs',
                  ))
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: logoHeight / 6),
                      child: AutoSizeText(
                        kennelShortName ?? '',
                        style: const TextStyle(
                          fontFamily: 'AvenirNextCondensedBold',
                          fontSize: 400.0,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        minFontSize: 1.0,
                      ),
                    ),
                ],
              )
            : kennelLogoUrl!.toLowerCase().endsWith('.avif')
            ? CachedNetworkAvifImage(
                kennelLogoUrl!,

                fit: BoxFit.fitHeight,
                height: logoHeight,
              )
            : CachedNetworkImage(
                imageUrl: kennelLogoUrl!,
                fadeInDuration: const Duration(milliseconds: 0),
                fit: BoxFit.fitHeight,
                height: logoHeight,
              ),
      ),
    );
  }
}
