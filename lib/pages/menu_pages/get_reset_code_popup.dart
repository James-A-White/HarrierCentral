import 'dart:core';

import 'package:flutter/material.dart';

import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:harrier_central/data/services/get_reset_code_service.dart';
import 'package:harrier_central/data/models/single_result_model.dart';
import 'package:harrier_central/data/services/authorize_device_service.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/preferences.dart';

class GetResetCodePopup extends StatefulWidget {
  const GetResetCodePopup();

  @override
  _GetResetCodePopupState createState() => _GetResetCodePopupState();
}

class _GetResetCodePopupState extends State<GetResetCodePopup> {
  final FocusNode myFocusNodeFirstName = FocusNode();
  TextEditingController getResetCodeTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Get Reset Code'),
      content: TextField(
        onChanged: (String x) {
          setState(() {});
        },
        autofocus: true,
        focusNode: myFocusNodeFirstName,
        controller: getResetCodeTextController,
        keyboardType: TextInputType.text,
        style: const TextStyle(
            fontFamily: 'WorkSansSemiBold',
            fontSize: 16.0,
            color: Colors.black),
        decoration: const InputDecoration(
          border: InputBorder.none,
          icon: Icon(
            FontAwesome.money,
            color: Colors.white,
          ),
          hintText: 'Support Code',
          hintStyle: TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
        ),
      ),
      actions: <Widget>[
        // Padding(
        //   padding: const EdgeInsets.only(right: 0.0),
        //   child: Container(
        //     width: 60.0,
        //     child:

        // FlatButton(
        //   color: Colors.red,
        //   child: const Text('Cancel'),
        //   textColor: Colors.white,
        //   onPressed: () {
        //     Navigator.of(context)
        //         .pop(<String, String>{'type': 'cancel', 'amount': ''});
        //   },
        // ),
        //   ),
        // ),
        // Container(
        //   width: 60.0,
        //child:

        FlatButton(
            color: Colors.blue,
            child: const Text('Done'),
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).pop();
            }),
        // ),
        // Container(
        //   width: 60.0,
        //child:

        FlatButton(
            color: Colors.blue,
            child: const Text('Get code'),
            textColor: Colors.white,
            onPressed: () {
              final GetResetCodeService svc = GetResetCodeService();
              svc
                  .getResetCode('SC:' + getResetCodeTextController.text)
                  .then((SingleResultModel result) {
                setState(() {
                  getResetCodeTextController.text = result.result;
                });
              });

              // Navigator.of(context).pop(<String, String>{
              //   'type': paymentBankTransferOther.value.toString(),
              //   'amount': getResetCodeTextController.text
              // });
            }),

        ((!getResetCodeTextController.text.startsWith('RC:')) ||
                (getResetCodeTextController.text.length != 9))
            ? Container()
            : FlatButton(
                color: Colors.blue,
                child: const Text('Reset device'),
                textColor: Colors.white,
                onPressed: () {
                  if (getResetCodeTextController.text.toUpperCase() ==
                      'RC:CLEARD') {

                    clearAllPrefs();

                    Utilities.showAlert(
                              context,
                              'App Cleared Successful',
                              'Your app has been successfully cleared. Please close and restart the app to start the installation process again.',
                              'OK');
                  } else {
                    final AuthorizeDeviceService srv = AuthorizeDeviceService();
                    final Future<Map<String, String>> apiCall =
                        srv.authorizeDevice(context,
                            getResetCodeTextController.text.toUpperCase());
                    apiCall.then((Map<String, String> result) {
                      if (result != null) {
                        setState(() {
                          getResetCodeTextController.text =
                              getStringPref(StringPrefsEnum.displayName);

                          Utilities.showAlert(
                              context,
                              'App Reset Successful',
                              'Your app has been successfully reset. Please close and restart the app to ensure all data is properly reloaded.',
                              'OK');
                        });
                      }
                    });
                  }
                },
              ),

        // ),
      ],
    );

    //     Image.network(kennel.kennelLogo,
    //         fit: BoxFit.fitHeight, height: logoHeight),
    // alignment: Alignment.centerRight);
  }

  // void _handleRadioValueChange1(int value) {
  //   setState(() {
  //     //widget.selectedValue = value;

  //     // switch (_radioValue1) {
  //     //   case 0:
  //     //     Fluttertoast.showToast(msg: 'Correct !',toastLength: Toast.LENGTH_SHORT);
  //     //     correctScore++;
  //     //     break;
  //     //   case 1:
  //     //     Fluttertoast.showToast(msg: 'Try again !',toastLength: Toast.LENGTH_SHORT);
  //     //     break;
  //     //   case 2:
  //     //     Fluttertoast.showToast(msg: 'Try again !',toastLength: Toast.LENGTH_SHORT);
  //     //     break;
  //     //}
  //   });
  // }
}
