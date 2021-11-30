// @dart=2.11
import 'package:harrier_central/imports.dart';

enum KennelLogoZoomGesture { none, tap, longPress }

class KennelLogo extends StatelessWidget {
  const KennelLogo({
    Key key,
    this.kennelId,
    @required this.kennelLogoUrl,
    @required this.kennelShortName,
    @required this.logoHeight,
    this.zoomGesture = KennelLogoZoomGesture.longPress,
    this.leftPadding,
    this.rightPadding,
  }) : super(key: key);

  final String kennelId;
  final String kennelLogoUrl;
  final String kennelShortName;
  final num logoHeight;
  final num leftPadding;
  final num rightPadding;
  final KennelLogoZoomGesture zoomGesture;

  void _showZoomPage(BuildContext context) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          // final String s =
          //     ((kennelLogoUrl.toLowerCase().contains('avatar') ? 'images/avatars/' : 'images/generic_logos/') + kennelLogoUrl.replaceAll('bundle://', '') + '.png').toLowerCase();
          //print(s);
          return ZoomableImagePage2(
            key: const Key('11126697697'),
            file: null,
            assetImage: kennelLogoUrl.contains('bundle://')
                ? ((kennelLogoUrl.toLowerCase().contains('avatar') ? 'images/avatars/' : 'images/generic_logos/') + kennelLogoUrl.replaceAll('bundle://', '') + '.png')
                    .toLowerCase()
                : null,
            assetImageText: kennelLogoUrl.contains('bundle://') ? kennelShortName : null,

            imageUrl: kennelLogoUrl.contains('bundle://') ? null : kennelLogoUrl, // The imageUrl parameter should not be marked as required
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
    return GestureDetector(
      onTap: (zoomGesture != KennelLogoZoomGesture.tap)
          ? null
          : () {
              _showZoomPage(context);
            },
      onLongPress: (zoomGesture != KennelLogoZoomGesture.longPress)
          ? null
          : () {
              _showZoomPage(context);
            },
      child: Container(
          width: logoHeight,
          height: logoHeight,
          margin: EdgeInsets.only(left: leftPadding ?? 0, right: rightPadding ?? 0),
          child: kennelLogoUrl.contains('bundle://')
              ? Stack(alignment: Alignment.center, children: <Widget>[
                  Image.asset(((kennelLogoUrl.toLowerCase().contains('avatar') ? 'images/avatars/' : 'images/generic_logos/') + kennelLogoUrl.replaceAll('bundle://', '') + '.png')
                      .toLowerCase()),
                  Padding(
                    padding: EdgeInsets.only(left: logoHeight / 6, right: logoHeight / 6),
                    child: AutoSizeText(
                      kennelShortName.toLowerCase().contains('my runs')
                          ? ''
                          : // TODO(James): find a more elegant way of doing this
                          kennelShortName,
                      style: const TextStyle(
                        fontFamily: 'AvenirNextCondensedBold',
                        fontStyle: FontStyle.normal,
                        fontSize: 400.0,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      minFontSize: 1.0,
                    ),
                  ),
                ])
              : CachedNetworkImage(
                  imageUrl: kennelLogoUrl,
                  //errorWidget: (BuildContext context,String url,Exception error) => const  Icon(Icons.error),
                  //errorWidget:  const  Icon(Icons.error),
                  fadeInDuration: const Duration(milliseconds: 0),
                  fit: BoxFit.fitHeight,
                  height: logoHeight),
          alignment: Alignment.centerRight),
    );

    //     Image.network(kennel.kennelLogo,
    //         fit: BoxFit.fitHeight, height: logoHeight),
    // alignment: Alignment.centerRight);
  }
}
