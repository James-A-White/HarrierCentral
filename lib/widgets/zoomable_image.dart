import 'dart:io' as platform;
import 'package:harrier_central/imports.dart';
import 'package:photo_view/photo_view.dart';

class ZoomableImagePage2 extends StatelessWidget {
  const ZoomableImagePage2({
    super.key,
    this.file,
    required this.pageTitle,
    this.imageUrl,
    this.appBarBackgroundColor,
    this.background,
    this.assetImage,
    this.assetImageText,
    this.margin,
    this.kennelId,
  });

  final platform.File? file;
  final String pageTitle;
  final String? imageUrl;
  final Color? appBarBackgroundColor;
  final BoxDecoration? background;
  final String? assetImage;
  final String? assetImageText;
  final double? margin;
  final String? kennelId;

  @override
  Widget build(BuildContext context) {
    final AppBar appBar = AppBar(
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
        padding: EdgeInsets.all(margin ?? 0.0),
        decoration: background,
        //height: 500.0,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(15.0),
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
                            imageProvider: CachedNetworkImageProvider(imageUrl!),

                            // NetworkImage(
                            //   imageUrl,
                            // ),
                            minScale: 0.1,
                            maxScale: 100.0,
                            backgroundDecoration: background,
                            // backgroundColor: Colors.transparent,
                          )
                        : assetImage != null
                            ? Stack(
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
                                  Padding(
                                    padding: EdgeInsets.only(left: G0<DeviceInfo>().deviceWidth / 6, right: G0<DeviceInfo>().deviceWidth / 6),
                                    child: AutoSizeText(
                                      (assetImageText ?? '').toLowerCase().contains('my runs')
                                          ? ''
                                          : // TODO(James): find a more elegant way of doing this
                                          '${assetImageText ?? ''}'
                                              '',
                                      style: const TextStyle(fontFamily: 'AvenirNextCondensedBold', fontStyle: FontStyle.normal, fontSize: 400.0),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      minFontSize: 1.0,
                                    ),
                                  ),
                                ],
                              )
                            : Container(),
              ),
            ),
            if (kennelId != null) ...<Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: ElevatedButton(
                  child: Text('View Kennel', style: buttonLabelStyleMedium),
                  onPressed: () async {
                    final KennelListAggregate? kennel = await QueryKennels.getSingleKennel(kennelId!);

                    if (kennel != null) {
                      await Navigator.of(navigatorKey.currentContext!).push<dynamic>(
                        MaterialPageRoute<dynamic>(
                          builder: (BuildContext context) => KennelAdminMainPage(kennelAggregateItem: kennel),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
