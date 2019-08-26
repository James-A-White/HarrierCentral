import 'dart:async';
import 'dart:io' as platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:harrier_central/data/hc3_services/narrow_event_service.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/widgets/fancy_divider.dart';
import 'package:harrier_central/widgets/zoomable_image_page.dart';
import 'package:harrier_central/data/hc3_services/receipts_service.dart';

// import 'package:harrier_central/widgets/user_details_ui.dart';
// import 'package:harrier_central/widgets/fancy_divider.dart';

class EmailEditorPage extends StatefulWidget {
  const EmailEditorPage({Key key, this.eventId}) : super(key: key);

  final String eventId;

  @override
  EmailEditorPageState createState() => EmailEditorPageState();
}

class EmailEditorPageState extends State<EmailEditorPage> {
  // String firstName = getStringPref(StringPrefsEnum.firstName);
  // String lastName = getStringPref(StringPrefsEnum.lastName);
  // String email = getStringPref(StringPrefsEnum.email);
  // String hashName = getStringPref(StringPrefsEnum.hashName);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;

  String _shortDescription;
  String _receiptAmount;

  platform.File _imageFromCamera;
  platform.File _imageFromCache;

  bool _isLoading = false;

  CachedNetworkImage receiptImageFromWeb;

  @override
  void initState() {
    // if (widget.receiptItem != null) {
    //   _imageFromCamera = null;
    //   receiptImageFromWeb = CachedNetworkImage(imageUrl: widget.receiptItem['imageUrl'], fadeInDuration: const Duration(milliseconds: 0));
    //   DefaultCacheManager().getSingleFile(widget.receiptItem['imageUrl']).then((platform.File file) {
    //     _imageFromCache = file;
    //   });
    //   _shortDescription = widget.receiptItem['receiptShortDesc'];
    //   _receiptAmount = widget.receiptItem['receiptAmount'].toString();
    // }
    super.initState();
  }

  Widget _buildCircularProgressIndicator() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        Text(
          'Uploading receipt details',
          style: headingStyle,
          textAlign: TextAlign.center,
        ),
        Container(height: 30),
        SpinKitCircle(
          size: 75.0,
          itemBuilder: (_, int index) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: index.isEven ? Colors.grey[50] : Theme.of(context).accentColor,
              ),
            );
          },
        ),
      ]),
    );
  }

  TextStyle headingStyle = const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, color: Colors.yellow, fontSize: 22.0, height: 1.0);

  TextStyle buttonTextStyle = const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 16.0, height: 1.0);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget formUi() {
    return Column(
      children: <Widget>[
        TextField(
          autocorrect: false,
          //initialValue: _shortDescription,
          decoration: const InputDecoration(labelText: 'Short description'),
          keyboardType: TextInputType.text,
          maxLines: null,
          // validator: (String arg) {
          //   if (arg.length < 4)
          //     return 'Description must be more than 3 charaters';
          //   else
          //     return null;
          // },
          // onSaved: (String val) {
          //   _shortDescription = val;
          // },
        ),
        
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppBar appBar = AppBar(
      centerTitle: true,
      backgroundColor: themeAppBarBackground,
      title: const Text(
        'Email Editor',
        style: TextStyle(
          color: Colors.white,
        ),
      ),
    );
    return Scaffold(
      key: _scaffoldKey,
      appBar: appBar,
      body: _isLoading
          ? Container(height: MediaQuery.of(context).size.height - appBar.preferredSize.height, decoration: Backgrounds.defaultHcBackground(), child: _buildCircularProgressIndicator())
          : Container(
              decoration: Backgrounds.defaultHcBackground(),
              height: MediaQuery.of(context).size.height,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 25),
                  RaisedButton(
                    onPressed: () {
                Utilities.showAlert(context, 'Email run details', 'Would you like to e-mail the run details to hashers who have signed up for e-mail notifications?', 'OK', showCancelButton: true).then((bool result) {
                  if (result) {
                    NarrowEventsService.sendRunDetailsByEmail(eventId: widget.eventId).then((Map<String, String> result) {
                      _scaffoldKey.currentState?.hideCurrentSnackBar();
                      if (result['result'].toLowerCase().startsWith('success')) {
                        Utilities.showAlert(context, 'E-mails successfully sent', result['result'], 'OK');
                      } else {
                        Utilities.showAlert(context, 'Error sending emails', 'There was a problem sending run detail e-mails to hashers.\r\n\r\nPlease try again later or contact us at connect@harriercentral.com', 'OK');
                      }
                    });
                    Utilities.showInSnackBar(context, _scaffoldKey, 'Run detail emails being sent ..', durationInSeconds: 10);
                  }
                });
                    },
                    child: Text('Quick Send Email', style: buttonTextStyle),
                  ),
                  const SizedBox(height: 10),
                  const FancyDivider(innerColor: Colors.white, useTextOr: true),
                  const SizedBox(height: 20),
                  Text(
                    'Email Body',
                    style: headingStyle,
                    textAlign: TextAlign.center,
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10.0),
                      margin: const EdgeInsets.only(bottom: 20,left:20,right:20,top:20),
                      decoration: BoxDecoration(
                        color: Colors.yellow[100],
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      child: Form(
                        key: _formKey,
                        autovalidate: _autoValidate,
                        child: formUi(),
                      ),
                    ),
                  ),
                  RaisedButton(
                    onPressed: () {
                      // onImageButtonPressed().then((platform.File imageFile) {
                      //   setState(() {
                      //     _imageFromCamera = imageFile;
                      //   });
                      // });
                    },
                    child: Text('Send Email', style: buttonTextStyle),
                  ),
                  //),
                  // Positioned(
                  //   top: 40,
                  //   //bottom: 20,
                  //   width: MediaQuery.of(context).size.width,
                  //   child:
                  // Container(
                  //   padding: const EdgeInsets.all(30.0),
                  //   child: Container(
                  //     child: Center(
                  //       child: Column(
                  //         children: <Widget>[
                  //           Container(
                  //             padding: const EdgeInsets.all(10.0),
                  //             margin: const EdgeInsets.only(bottom: 45),
                  //             decoration: BoxDecoration(
                  //               color: Colors.yellow[100],
                  //               borderRadius: BorderRadius.circular(5.0),
                  //             ),
                  //             child: Form(
                  //               key: _formKey,
                  //               autovalidate: _autoValidate,
                  //               child: formUi(),
                  //             ),
                  //           ),
                  //           const FancyDivider(innerColor: Colors.white),
                  //           const SizedBox(height: 20),

                  //         ],
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  //),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  // GestureDetector(
                  //   onTap: () {
                  //     Navigator.push<void>(
                  //       context,
                  //       MaterialPageRoute<void>(
                  //         builder: (BuildContext context) => ZoomableImagePage(
                  //           image: _imageFromCamera != null ? _imageFromCamera : _imageFromCache,
                  //           pageTitle: 'Zoomable Receipt',
                  //         ),
                  //       ),
                  //     );
                  //   },
                  //   child: _imageFromCamera != null
                  //       ? Container(
                  //           //height: 220,
                  //           color: Colors.white,
                  //           padding: const EdgeInsets.all(10.0),
                  //           margin: const EdgeInsets.only(top: 20, bottom: 30),
                  //           child: Image.file(_imageFromCamera, width: MediaQuery.of(context).size.width))
                  //       : receiptImageFromWeb != null
                  //           ? Container(
                  //               //height: 220,
                  //               color: Colors.white,
                  //               padding: const EdgeInsets.all(10.0),
                  //               margin: const EdgeInsets.only(top: 20, bottom: 30),
                  //               child: receiptImageFromWeb)
                  //           : Container(),
                  // ),
                  Container(width: 40, height: 20),
                ],
              ),
            ),

      // Positioned(
      //   top: 0,
      //   child: Container(
      //     padding: const EdgeInsets.all(12.0),
      //     decoration: BoxDecoration(
      //       // border: new Border.all(width: 1.0, color: Colors.black),
      //       //shape: BoxShape.circle,
      //       color: Colors.yellow[100],
      //       boxShadow: const <BoxShadow>[
      //         BoxShadow(
      //           color: Color.fromARGB(70, 0, 0, 0),
      //           offset: Offset(0.0, 6.0),
      //           blurRadius: 10.0,
      //         ),
      //       ],
      //     ),
      //     width: MediaQuery.of(context).size.width,
      //     height: 60,
      //     child: Container(
      //       padding: const EdgeInsets.only(left: 220),
      //       child: RaisedButton(
      //         onPressed: _uploadReceipt,
      //         child: Text('Save receipt', style: buttonTextStyle),
      //       ),
      //     ),
      //   ),
      // ),
    );
  }
}
