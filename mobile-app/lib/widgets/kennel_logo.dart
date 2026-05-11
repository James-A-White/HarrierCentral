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

  bool get _isBundleImage => kennelLogoUrl?.contains('bundle://') ?? false;

  String? get _assetImagePath {
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
            assetImageText: _isBundleImage ? kennelShortName : null,
            imageUrl: _isBundleImage ? null : kennelLogoUrl,
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
        child: _isBundleImage
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
