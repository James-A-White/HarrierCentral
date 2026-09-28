import 'package:hcportal/imports.dart';

enum KennelLogoZoomGesture { none, tap, longPress }

class KennelLogo extends StatelessWidget {
  const KennelLogo({
    required this.kennelLogoUrl, required this.kennelShortName, super.key,
    this.logoHeight,
    this.zoomGesture = KennelLogoZoomGesture.longPress,
    this.leftPadding,
    this.rightPadding,
  });

  final String kennelLogoUrl;
  final String kennelShortName;
  final num? logoHeight;
  final num? leftPadding;
  final num? rightPadding;
  final KennelLogoZoomGesture zoomGesture;

  /// A generic coin stored as an image URL (…/generic-logos/C-030.png), the
  /// form new kennels get since 2026-09-28. Captures the coin code.
  static final RegExp _coinUrl = RegExp(
    r'/generic-logos/(C-[A-Za-z0-9]+)\.png$',
    caseSensitive: false,
  );

  /// The bundled coin image — from `bundle://C-NNN` or a coin URL — or null
  /// for a kennel's own logo. A coin is blank artwork: the kennel's short
  /// name is written on it, as it always was for `bundle://` (James,
  /// 2026-09-28).
  String? get _coinAsset {
    if (kennelLogoUrl.contains('bundle://')) {
      return 'images/generic_logos/${kennelLogoUrl.replaceAll('bundle://', '')}.png'.toLowerCase();
    }
    final String? code = _coinUrl.firstMatch(kennelLogoUrl)?.group(1);
    return code == null ? null : 'images/generic_logos/$code.png'.toLowerCase();
  }

  // void _showZoomPage(BuildContext context) {
  //   Navigator.push<void>(
  //     context,
  //     MaterialPageRoute<void>(
  //       builder: (BuildContext context) {
  //         // final String s =
  //         //     ((kennelLogoUrl.toLowerCase().contains('avatar') ? 'images/avatars/' : 'images/generic_logos/') + kennelLogoUrl.replaceAll('bundle://', '') + '.png').toLowerCase();
  //         //print(s);
  //         return ZoomableImagePage2(
  //           key: UniqueKey(),
  //           file: null,
  //           assetImage: kennelLogoUrl.contains('bundle://')
  //               ? ((kennelLogoUrl.toLowerCase().contains('avatar') ? 'images/avatars/' : 'images/generic_logos/') + kennelLogoUrl.replaceAll('bundle://', '') + '.png')
  //                   .toLowerCase()
  //               : null,
  //           assetImageText: kennelLogoUrl.contains('bundle://') ? kennelShortName : null,

  //           imageUrl: kennelLogoUrl.contains('bundle://') ? null : kennelLogoUrl, // The imageUrl parameter should not be marked as required
  //           pageTitle: 'Kennel logo',
  //           appBarBackgroundColor: themeAppBarBackground,
  //           background: Backgrounds.defaultHcBackground(),
  //         );
  //       },
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // onTap: (zoomGesture != KennelLogoZoomGesture.tap)
      //     ? null
      //     : () {
      //         _showZoomPage(context);
      //       },
      // onLongPress: (zoomGesture != KennelLogoZoomGesture.longPress)
      //     ? null
      //     : () {
      //         _showZoomPage(context);
      //       },
      child: Container(
        width: (logoHeight ?? 10000.0) + .0,
        height: (logoHeight ?? 10000.0) + .0,
        margin: EdgeInsets.only(left: (leftPadding ?? 0.0) + .0, right: (rightPadding ?? 0.0) + .0),
        child: _coinAsset != null
            ? Stack(alignment: Alignment.center, children: <Widget>[
                Image.asset(_coinAsset!, fit: BoxFit.fill,
                    errorBuilder: (_, _, _) => const SizedBox.shrink()),
                FractionallySizedBox(
                  widthFactor: .55,
                  child: AutoSizeText(
                    kennelShortName.toLowerCase().contains('my runs')
                        ? ''
                        : // TO DO(James): find a more elegant way of doing this
                        kennelShortName,
                    style: const TextStyle(
                      fontFamily: 'AvenirNextCondensedBold',
                      fontStyle: FontStyle.normal,
                      fontSize: 400,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    minFontSize: 1,
                  ),
                ),
              ],)
            : HcNetworkImage(
                kennelLogoUrl,
                width: (logoHeight ?? 10000.0) + .0,
                height: (logoHeight ?? 10000.0) + .0,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
      ),
    );

    //     Image.network(kennel.kennelLogo,
    //         fit: BoxFit.fitHeight, height: logoHeight),
    // alignment: Alignment.centerRight);
  }
}
