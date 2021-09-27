// @dart=2.11
import 'dart:io' as platform;

import 'package:flutter/material.dart';

import 'package:photo_view/photo_view.dart';
import 'package:harrier_central/imports.dart';

class ZoomableImagePage2 extends StatelessWidget {
  const ZoomableImagePage2({
    Key key,
    this.file,
    this.pageTitle,
    this.imageUrl,
    this.appBarBackgroundColor,
    this.background,
    this.assetImage,
    this.assetImageText,
  }) : super(key: key);

  final platform.File file;
  final String pageTitle;
  final String imageUrl;
  final Color appBarBackgroundColor;
  final BoxDecoration background;
  final String assetImage;
  final String assetImageText;

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
          decoration: background,
          child: file != null
              ? PhotoView(
                  imageProvider: FileImage(file),
                  minScale: 0.1,
                  maxScale: 100.0,
                  backgroundDecoration: background,
                  // backgroundColor: Colors.transparent,
                )
              : imageUrl != null
                  ? PhotoView(
                      imageProvider: NetworkImage(
                        imageUrl,
                      ),
                      minScale: 0.1,
                      maxScale: 100.0,
                      backgroundDecoration: background,
                      // backgroundColor: Colors.transparent,
                    )
                  : Stack(alignment: Alignment.center, children: <Widget>[
                      PhotoView(
                        imageProvider: AssetImage(
                          assetImage,
                        ),
                        minScale: 0.1,
                        maxScale: 100.0,
                        backgroundDecoration: background,
                        // backgroundColor: Colors.transparent,
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: G0<DeviceInfo>().deviceWidth / 6, right: G0<DeviceInfo>().deviceWidth / 6),
                        child: AutoSizeText(
                          assetImageText.toLowerCase().contains('my runs')
                              ? ''
                              : // TODO(James): find a more elegant way of doing this
                              '$assetImageText'
                                  '',
                          style: const TextStyle(fontFamily: 'AvenirNextCondensedBold', fontStyle: FontStyle.normal, fontSize: 400.0),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          minFontSize: 1.0,
                        ),
                      ),
                    ])),
    );
  }
}
