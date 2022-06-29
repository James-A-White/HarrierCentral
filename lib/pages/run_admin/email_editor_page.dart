// @dart=2.11
import 'package:harrier_central/imports.dart';

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

  TextStyle insertTokenButtonTextStyle = const TextStyle(fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, color: Colors.black, fontSize: 20.0, height: 1.0);

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
                ElevatedButton(
                  onPressed: () {
                    sendEmail(context, '');
                  },
                  child: Text('Quick Send Email', style: textStyleButton),
                ),
                const SizedBox(height: 10),
                const FancyDivider(key: Key('155030392'), innerColor: Colors.white, useTextOr: true),
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
                    SizedBox(
                      width: 115,
                      child: ElevatedButton(
                        onPressed: () {
                          insertText('{my name}');
                        },
                        style: ElevatedButton.styleFrom(primary: Colors.blue.shade300),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Insert\r\nyour name',
                            style: insertTokenButtonTextStyle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 155,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(primary: Colors.blue.shade300),
                        onPressed: () {
                          insertText('{receipient name}');
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Insert recipient name',
                            style: insertTokenButtonTextStyle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    SizedBox(
                      width: 115,
                      child: ElevatedButton(
                        onPressed: () {
                          insertText('{run details}');
                        },
                        style: ElevatedButton.styleFrom(primary: Colors.blue.shade300),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Insert\r\nrun details',
                            style: insertTokenButtonTextStyle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 155,
                      child: ElevatedButton(
                        onPressed: () {
                          insertText('{run description}');
                        },
                        style: ElevatedButton.styleFrom(primary: Colors.blue.shade300),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Insert run\r\ndescription',
                            style: insertTokenButtonTextStyle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setStringPref(StringPrefsEnum.customEmailBody, bodyController.text);
                    sendEmail(context, bodyController.text);
                  },
                  child: Text('Send Email', style: textStyleButton),
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
                //           FancyDivider(key: Key('xxxxxxxx'),innerColor: Colors.white),
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
                //         builder: (BuildContext context) => ZoomableImagePage2(
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
                const SizedBox(width: 40, height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> sendEmail(BuildContext context, String emailBody) async {
    final bool doEmail = await IveCoreUtilities.showAlert(context, 'Email run details', 'Would you like to e-mail the run details to hashers who have signed up for e-mail notifications?', 'OK',
        showCancelButton: true);

    if (doEmail) {
      final Map<String, String> result = await G0<TableModel>().eventsService.sendRunDetailsByEmail(eventId: widget.eventId, emailBody: emailBody);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (result['result'].toLowerCase().startsWith('success')) {
        await IveCoreUtilities.showAlert(context, 'E-mails successfully sent', result['result'], 'OK');
      } else {
        await IveCoreUtilities.showAlert(
            context, 'Error sending emails', 'There was a problem sending run detail e-mails to hashers.\r\n\r\nPlease try again later or contact us at connect@harriercentral.com', 'OK');
      }

      IveCoreUtilities.showInSnackBar(context, _scaffoldKey, 'Run detail emails being sent ..', durationInSeconds: 10);
    }
  }

  void insertText(String textToInsert) {
    final int bo = bodyController.selection.baseOffset + textToInsert.length;
    final String textBefore = bodyController.text.substring(0, bodyController.selection.baseOffset);
    final String textAfter = bodyController.text.substring(bodyController.selection.baseOffset);
    bodyController.text = textBefore + textToInsert + textAfter;
    bodyController.selection = TextSelection.collapsed(offset: bo);
  }
}
