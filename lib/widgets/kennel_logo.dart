import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class KennelLogo extends StatelessWidget {
  final String kennelLogoUrl;
  final String kennelShortName;
  final double logoHeight;
  final double leftPadding;

  const KennelLogo({
    @required this.kennelLogoUrl,
    @required this.kennelShortName,
    @required this.logoHeight,
    @required this.leftPadding
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        width: logoHeight,
        height: logoHeight,
        margin: EdgeInsets.only(left: leftPadding),
        child: kennelLogoUrl.contains('bundle://')
            ? Stack(alignment: Alignment.center, children: <Widget>[
                Image.asset('images/generic_logos/' +
                    kennelLogoUrl.replaceAll('bundle://', '') +
                    '.png'),
                Padding(
                  padding: EdgeInsets.only(left: logoHeight/10, right: logoHeight/10),
                  child: AutoSizeText(
                    '$kennelShortName',
                    style: const TextStyle(
                        fontFamily: 'AvenirNextCondensedBold',
                        fontStyle: FontStyle.normal,
                        fontSize: 400.0),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    minFontSize: 1.0,
                  ),
                ),
              ])
            :  CachedNetworkImage(
                imageUrl: kennelLogoUrl,
                errorWidget: (BuildContext context,String url,Exception error) => const Icon(Icons.error),
                //errorWidget:  const Icon(Icons.error),
                fadeInDuration:  Duration(milliseconds: 0),
                fit: BoxFit.fitHeight, height: logoHeight),
                  alignment: Alignment.centerRight);
            
            
        //     Image.network(kennel.kennelLogo,
        //         fit: BoxFit.fitHeight, height: logoHeight),
        // alignment: Alignment.centerRight);
  }
}