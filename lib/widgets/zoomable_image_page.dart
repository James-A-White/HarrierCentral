import 'dart:io' as platform;

import 'package:flutter/material.dart';

import 'package:zoomable_image/zoomable_image.dart';

import 'package:harrier_central/util/styles.dart';

class ZoomableImagePage extends StatelessWidget {
  const ZoomableImagePage({this.image, this.pageTitle, this.imageUrl});

  final platform.File image;
  final String pageTitle;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final AppBar appBar = AppBar(
      centerTitle: true,
      backgroundColor: themeAppBarBackground,
      title: Text(
        pageTitle ?? 'Image',
        style: TextStyle(
          color: Colors.white,
        ),
      ),
    );

    return Scaffold(
      //key: scaffoldKey,
      appBar: appBar,
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: image != null
            ? ZoomableImage(
                FileImage(image),
                minScale: 0.1,
                maxScale: 100.0,
                backgroundColor: Colors.transparent,
              )
            : ZoomableImage(
                 NetworkImage(
                      imageUrl,
                      // errorWidget:
                      //     (BuildContext context, String url, Exception error) =>
                      //         const  Icon(Icons.error),
                    ),
                minScale: 0.1,
                maxScale: 100.0,
                backgroundColor: Colors.transparent,
              ),
      ),
    );

    //     Image.network(kennel.kennelLogo,
    //         fit: BoxFit.fitHeight, height: logoHeight),
    // alignment: Alignment.centerRight);
  }
}
