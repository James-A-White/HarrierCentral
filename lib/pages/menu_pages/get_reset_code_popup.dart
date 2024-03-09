import 'package:harrier_central/imports.dart';

class GetResetCodePopup extends StatefulWidget {
  const GetResetCodePopup({
    super.key,
  });

  @override
  GetResetCodePopupState createState() => GetResetCodePopupState();
}

class GetResetCodePopupState extends State<GetResetCodePopup> {
  final FocusNode myFocusNodeFirstName = FocusNode();
  TextEditingController getResetCodeTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Get Invite Code'),
      content: TextField(
        onChanged: (String x) {
          setState(() {});
        },
        autofocus: true,
        focusNode: myFocusNodeFirstName,
        controller: getResetCodeTextController,
        keyboardType: TextInputType.text,
        style: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0, color: Colors.black),
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

        // TextButton(
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

        TextButton(
            style: TextButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text(
              'Reset',
            ),
            onPressed: () {
              clearPrefs();
            }),

        TextButton(
            style: TextButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Done'),
            onPressed: () {
              Navigator.of(context).pop();
            }),
        // ),
        // Container(
        //   width: 60.0,
        //child:

        TextButton(
            style: TextButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Get code'),
            onPressed: () {
              final GetResetCodeService svc = GetResetCodeService();
              svc.getResetCode(QR_PREFIX_USER_SECRET_CODE + getResetCodeTextController.text).then((SingleResultModel? result) {
                setState(() {
                  getResetCodeTextController.text = result!.result ?? '';
                });
              });

              // Navigator.of(context).pop(<String, String>{
              //   'type': paymentBankTransferOther.value.toString(),
              //   'amount': getResetCodeTextController.text
              // });
            }),

        ((!getResetCodeTextController.text.startsWith(QR_PREFIX_USER_RESET_CODE)) || (getResetCodeTextController.text.length != 9))
            ? Container()
            : TextButton(
                style: TextButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Reset device'),
                onPressed: () async {
                  if (getResetCodeTextController.text.toUpperCase() == '${QR_PREFIX_USER_RESET_CODE}CLEAR') {
                    await clearPrefs();
                    await DBProvider.deleteDb(DB_NAME);

                    await Utilities.showAlert('App Cleared Successful', 'Your app has been successfully cleared. Please close and restart the app to start the installation process again.', 'OK');
                  } else {
                    final AuthorizeDeviceService srv = AuthorizeDeviceService();
                    final Future<Map<String, String>> apiCall = srv.authorizeDevice(context, getResetCodeTextController.text.toUpperCase());
                    final Map<String, String> result = await apiCall;
                    if (result.isNotEmpty) {
                      getResetCodeTextController.text = getStringPref(StringPrefsEnum.displayName) ?? '';

                      await Utilities.showAlert('App Reset Successful', 'Your app has been successfully reset. Please close and restart the app to ensure all data is properly reloaded.', 'OK');
                    }
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
