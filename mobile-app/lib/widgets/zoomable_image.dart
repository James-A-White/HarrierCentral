import 'dart:io' as platform;
import 'dart:ui' as ui;
import 'package:harrier_central/imports.dart';


class ZoomableImagePage2 extends StatelessWidget {
  const ZoomableImagePage2({
    super.key,
    this.file,
    required this.pageTitle,
    this.imageUrl,
    this.qrCode,
    this.qrColor,
    this.appBarBackgroundColor,
    this.background,
    this.assetImage,
    this.assetImageText,
    this.margin,
    this.kennelId,
    this.infoTitle,
    this.infoText,
  });

  final platform.File? file;
  final String pageTitle;
  final String? imageUrl;
  final String? qrCode;
  final Color? qrColor;
  final Color? appBarBackgroundColor;
  final BoxDecoration? background;
  final String? assetImage;
  final String? assetImageText;
  final double? margin;
  final String? kennelId;
  final String? infoTitle;
  final String? infoText;

  @override
  Widget build(BuildContext context) {
    final AppBar appBar = AppBar(
      centerTitle: true,
      backgroundColor: appBarBackgroundColor,
      iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
      title: AutoSizeText(
        pageTitle,
        style: ts_appBarTitle,
        textAlign: TextAlign.center,
        minFontSize: 2.0,
        maxLines: 1,
      ),
    );

    return AppScaffold(
      //key: ScaffoldKey,
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
                        imageProvider: imageUrl!.toLowerCase().endsWith('.avif')
                            ? CachedNetworkAvifImageProvider(imageUrl!)
                            : CachedNetworkImageProvider(imageUrl!),

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
                            imageProvider: AssetImage(assetImage!),
                            minScale: 0.1,
                            maxScale: 100.0,
                            backgroundDecoration: background,
                            // backgroundColor: Colors.transparent,
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                              left: deviceInfo.deviceWidth / 6,
                              right: deviceInfo.deviceWidth / 6,
                            ),
                            child: AutoSizeText(
                              (assetImageText ?? '').toLowerCase().contains(
                                    'my runs',
                                  )
                                  ? ''
                                  : // TODO(James): find a more elegant way of doing this
                                    '${assetImageText ?? ''}'
                                        '',
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
                        ],
                      )
                    : qrCode != null
                    ? FutureBuilder<ImageProvider>(
                        future: generateQrImageProvider(qrCode!, qrColor),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return PhotoView(
                            imageProvider: snapshot.data!,
                            minScale: 0.1,
                            maxScale: 100.0,
                            backgroundDecoration: background,
                          );
                        },
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            if (((infoTitle ?? '').isNotEmpty) || ((infoText ?? '').isNotEmpty))
              Padding(
                padding: EdgeInsets.fromLTRB(
                    24, 8, 24, MediaQuery.of(context).padding.bottom + 16),
                child: Column(
                  children: <Widget>[
                    if ((infoTitle ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Text(
                          infoTitle!,
                          style: ts_headingLarge,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if ((infoText ?? '').isNotEmpty)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 140),
                        child: SingleChildScrollView(
                          child: Text(
                            infoText!,
                            style: ts_body,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (kennelId != null) ...<Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: ElevatedButton(
                  child: Text('View Kennel', style: ts_button),
                  onPressed: () async {
                    final KennelListAggregate? kennel =
                        await QueryKennels.getSingleKennel(kennelId!);

                    if (kennel == null) return;

                    // Anyone may open a kennel's detail page — it shows info and
                    // upcoming runs to everyone; the admin-functions section and
                    // its data sync are gated internally (KennelAdminController).
                    await Navigator.of(
                      navigatorKey.currentContext!,
                    ).push<dynamic>(
                      MaterialPageRoute<dynamic>(
                        builder: (BuildContext context) =>
                            KennelAdminMainPage(kennelAggregateItem: kennel),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<ImageProvider> generateQrImageProvider(
    String qrData,
    Color? qrColor, {
    double size = 200,
  }) async {
    final painter = QrPainter(
      data: qrData,
      version: QrVersions.auto,
      gapless: true,
      dataModuleStyle: QrDataModuleStyle(
        color: qrColor ?? Colors.black,
        dataModuleShape: QrDataModuleShape.square,
      ),
      eyeStyle: QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: qrColor ?? Colors.black,
      ),
    );

    final uiImage = await painter.toImage(size);
    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return MemoryImage(bytes);
  }
}
