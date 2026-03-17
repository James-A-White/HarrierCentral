import 'dart:io' as platform;
import 'package:hcportal/imports.dart';

class ZoomableImagePage2 extends StatelessWidget {
  const ZoomableImagePage2({
    required this.pageTitle, super.key,
    this.file,
    this.imageUrl,
    this.appBarBackgroundColor,
    this.background,
    this.assetImage,
    this.assetImageText,
    this.margin,
    this.kennelId,
  });

  final String pageTitle;

  final platform.File? file;
  final String? imageUrl;
  final Color? appBarBackgroundColor;
  final BoxDecoration? background;
  final String? assetImage;
  final String? assetImageText;
  final num? margin;
  final String? kennelId;

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      centerTitle: true,
      backgroundColor: appBarBackgroundColor,
      title: Text(
        pageTitle,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
    );

    return Scaffold(
      //key: scaffoldKey,
      appBar: appBar,
      body: Container(
        padding: EdgeInsets.all((margin ?? 0.0) + .0),
        decoration: background,
        //height: 500.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: file != null
                    ? PhotoView(
                        imageProvider: FileImage(file!),
                        minScale: 0.1,
                        maxScale: 100.0,
                        backgroundDecoration: background,
                        // backgroundColor: Colors.transparent,
                      )
                    : imageUrl != null
                        ? PhotoView(
                            imageProvider: NetworkImage(imageUrl!),

                            // NetworkImage(
                            //   imageUrl,
                            // ),
                            minScale: 0.1,
                            maxScale: 100.0,
                            backgroundDecoration: background,
                            // backgroundColor: Colors.transparent,
                          )
                        : assetImage == null
                            ? Container()
                            : Stack(
                                alignment: Alignment.center,
                                children: <Widget>[
                                  PhotoView(
                                    imageProvider: AssetImage(
                                      assetImage!,
                                    ),
                                    minScale: 0.1,
                                    maxScale: 100.0,
                                    backgroundDecoration: background,
                                    // backgroundColor: Colors.transparent,
                                  ),
                                  // Padding(
                                  //   padding: EdgeInsets.only(left: G0<DeviceInfo>().deviceWidth / 6, right: G0<DeviceInfo>().deviceWidth / 6),
                                  //   child: AutoSizeText(
                                  //     (assetImageText ?? '').toLowerCase().contains('my runs')
                                  //         ? ''
                                  //         :
                                  //         '${assetImageText ?? ''}'
                                  //             '',
                                  //     style: const TextStyle(fontFamily: 'AvenirNextCondensedBold', fontStyle: FontStyle.normal, fontSize: 400.0),
                                  //     textAlign: TextAlign.center,
                                  //     maxLines: 1,
                                  //     minFontSize: 1.0,
                                  //   ),
                                  // ),
                                ],
                              ),
              ),
            ),
            // if (kennelId != null) ...<Widget>[
            //   Padding(
            //     padding: const EdgeInsets.only(bottom: 20.0),
            //     child: ElevatedButton(
            //       child: Text('View Kennel', style: buttonLabelStyleMedium),
            //       onPressed: () async {
            //         final KennelListAggregate kennel = await QueryKennels.getSingleKennel(kennelId);

            //         await Navigator.of(context).push<dynamic>(
            //           MaterialPageRoute<dynamic>(
            //             builder: (BuildContext context) => KennelAdminMainPage(kennelAggregateItem: kennel),
            //           ),
            //         );
            //       },
            //     ),
            //   ),
            // ],
          ],
        ),
      ),
    );
  }
}
