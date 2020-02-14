import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:harrier_central/util/preferences.dart';
import 'package:keyboard_avoider/keyboard_avoider.dart';

import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/widgets/fancy_divider.dart';


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

  //final bool _isLoading = false;

  @override
  void initState() {
    bodyController.text = getStringPref(StringPrefsEnum.customEmailBody) ?? '';
    super.initState();
  }

  TextEditingController bodyController = TextEditingController();

  // Widget _buildCircularProgressIndicator() {
  //   return Center(
  //     child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
  //       Text(
  //         'Uploading receipt details',
  //         style: headingStyle,
  //         textAlign: TextAlign.center,
  //       ),
  //       Container(height: 30),
  //       SpinKitCircle(
  //         size: 75.0,
  //         itemBuilder: (_, int index) {
  //           return DecoratedBox(
  //             decoration: BoxDecoration(
  //               color: index.isEven ? Colors.grey[50] : Theme.of(context).accentColor,
  //             ),
  //           );
  //         },
  //       ),
  //     ]),
  //   );
  // }

  TextStyle headingStyle = const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, color: Colors.yellow, fontSize: 22.0, height: 1.0);

  TextStyle buttonTextStyle = const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 16.0, height: 1.0);

  TextStyle insertTokenButtonTextStyle = const TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.black, fontSize: 16.0, height: 0.8);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<bool> _requestPop() {
    setStringPref(StringPrefsEnum.customEmailBody, bodyController.text);
    return Future<bool>.value(true);
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
    return WillPopScope(
      onWillPop: _requestPop,
      child: Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset: false,
        appBar: appBar,
        body:
        //  _isLoading
        //     ? Container(height: MediaQuery.of(context).size.height - appBar.preferredSize.height, decoration: Backgrounds.defaultHcBackground(), child: _buildCircularProgressIndicator())
        //     : 
            
            Container(
                decoration: Backgrounds.defaultHcBackground(),
                height: MediaQuery.of(context).size.height,
                child: KeyboardAvoider(
                  autoScroll: true,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: 25),
                      RaisedButton(
                        onPressed: () {
                          sendEmail(context, '');
                        },
                        child: Text('Quick Send Email', style: buttonTextStyle),
                      ),
                      const SizedBox(height: 10),
                      const FancyDivider(innerColor: Colors.white, useTextOr: true),
                      const SizedBox(height: 20),
                      Text(
                        'Compose custom email',
                        style: headingStyle,
                        textAlign: TextAlign.center,
                      ),
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20, top: 20),
                        decoration: BoxDecoration(
                          color: Colors.yellow[100],
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child: Form(
                          key: _formKey,
                          //autovalidate: _autoValidate,
                          child: TextField(
                            autocorrect: false,
                            //initialValue: _shortDescription,
                            decoration: const InputDecoration.collapsed(hintText: 'Email body'),
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            minLines: 10,
                            controller: bodyController,
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
                        ),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Container(
                            width: 130,
                            child: RaisedButton(
                              onPressed: () {
                                insertText('{my name}');
                              },
                              color: Colors.blue[300],
                              child: Text(
                                'Insert\r\nYour\r\nname',
                                style: insertTokenButtonTextStyle,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          Container(
                            width: 130,
                            child: RaisedButton(
                              onPressed: () {
                                insertText('{receipient name}');
                              },
                              color: Colors.blue[300],
                              child: Text(
                                'Insert\r\nRecipient\r\nName',
                                style: insertTokenButtonTextStyle,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Container(
                            width: 130,
                            child: RaisedButton(
                              onPressed: () {
                                insertText('{run details}');
                              },
                              color: Colors.blue[300],
                              child: Text(
                                'Insert\r\nRun\r\nDetails',
                                style: insertTokenButtonTextStyle,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          Container(
                            width: 130,
                            child: RaisedButton(
                              onPressed: () {
                                insertText('{run description}');
                              },
                              color: Colors.blue[300],
                              child: Text(
                                'Insert\r\nRun\r\nDescription',
                                style: insertTokenButtonTextStyle,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      RaisedButton(
                        onPressed: () {
                          setStringPref(StringPrefsEnum.customEmailBody, bodyController.text);
                          sendEmail(context, bodyController.text);
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
              ),
      ),
    );
  }

  void sendEmail(BuildContext context, String emailBody) {
    Utilities.showAlert(context, 'Email run details', 'Would you like to e-mail the run details to hashers who have signed up for e-mail notifications?', 'OK', showCancelButton: true).then((bool result) {
      if (result) {
        eventsService.sendRunDetailsByEmail(eventId: widget.eventId, emailBody: emailBody).then((Map<String, String> result) {
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
  }

  void insertText(String textToInsert) {
    final int bo = bodyController.selection.baseOffset + textToInsert.length;
    final String textBefore = bodyController.text.substring(0, bodyController.selection.baseOffset);
    final String textAfter = bodyController.text.substring(bodyController.selection.baseOffset);
    bodyController.text = textBefore + textToInsert + textAfter;
    bodyController.selection = TextSelection.collapsed(offset: bo);
  }
}
