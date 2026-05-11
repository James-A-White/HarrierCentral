import 'package:harrier_central/imports.dart';

class RunNumberPopup extends StatefulWidget {
  const RunNumberPopup({super.key, this.runNumber});

  final int? runNumber;

  @override
  RunNumberPopupState createState() => RunNumberPopupState();
}

class RunNumberPopupState extends State<RunNumberPopup> {
  final FocusNode myFocusNodeFirstName = FocusNode();
  late TextEditingController _runNumberAmountTextController;

  @override
  void initState() {
    super.initState();
    _runNumberAmountTextController = TextEditingController(
      text: widget.runNumber?.toString() ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Set run number', style: ts_alertDialogTitle),
      content: TextField(
        autofocus: true,
        focusNode: myFocusNodeFirstName,
        controller: _runNumberAmountTextController,
        keyboardType: TextInputType.number,
        style: ts_alertDialogBody,
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: const Icon(FontAwesome.money, color: Colors.white),
          hintText: 'Enter run number',
          hintStyle: ts_hint,
        ),
      ),
      actions: <Widget>[
        // Padding(
        //   padding: const EdgeInsets.only(right: 0.0),
        //   child: Container(
        //     width: 60.0,
        //     child:
        TextButton(
          style: TextButton.styleFrom(
            shape: button_shape,
            backgroundColor: hc_red,
          ),
          child: Text('Cancel', style: ts_button),
          onPressed: () {
            Navigator.of(context).pop(<String, String>{'runNumber': 'cancel'});
          },
        ),

        //   ),
        // ),
        // Container(
        //   width: 60.0,
        //child:
        TextButton(
          style: TextButton.styleFrom(
            shape: button_shape,
            backgroundColor: hc_blue,
          ),
          child: Text('Auto number', style: ts_button),
          onPressed: () {
            Navigator.of(context).pop(<String, String>{'runNumber': 'auto'});
          },
        ),

        // ),
        // Container(
        //   width: 60.0,
        //child:
        TextButton(
          style: TextButton.styleFrom(
            shape: button_shape,
            backgroundColor: hc_red,
          ),
          child: Text('OK', style: ts_regular),
          onPressed: () {
            Navigator.of(context).pop(<String, String>{
              'runNumber': _runNumberAmountTextController.text,
            });
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
