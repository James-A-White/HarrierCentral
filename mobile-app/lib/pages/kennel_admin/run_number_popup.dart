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
  void dispose() {
    myFocusNodeFirstName.dispose();
    _runNumberAmountTextController.dispose();
    super.dispose();
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
        // TextInputType.number still offers a decimal separator on both
        // platforms, which is how "729.5" got typed into a column that only
        // holds whole numbers.
        inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
        style: ts_alertDialogBody,
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: const Icon(FontAwesome.money, color: Colors.white),
          hintText: 'Enter run number',
          hintStyle: ts_hint,
        ),
      ),
      actions: <Widget>[
        //     width: 60.0,
        //     child:
        TextButton(
          style: TextButton.styleFrom(
            shape: button_shape,
            backgroundColor: hc_red,
          ),
          child: Text('Cancel', style: ts_button, textAlign: TextAlign.center),
          onPressed: () {
            Navigator.of(context).pop(<String, String>{'runNumber': 'cancel'});
          },
        ),

        //   width: 60.0,
        //child:
        TextButton(
          style: TextButton.styleFrom(
            shape: button_shape,
            backgroundColor: hc_blue,
          ),
          child: Text('Auto number', style: ts_button, textAlign: TextAlign.center),
          onPressed: () {
            Navigator.of(context).pop(<String, String>{'runNumber': 'auto'});
          },
        ),

        //   width: 60.0,
        //child:
        TextButton(
          style: TextButton.styleFrom(
            shape: button_shape,
            backgroundColor: hc_red,
          ),
          child: Text('OK', style: ts_regular, textAlign: TextAlign.center),
          onPressed: () {
            Navigator.of(context).pop(<String, String>{
              'runNumber': _runNumberAmountTextController.text,
            });
          },
        ),
        // ),
      ],
    );

  }

  //     // switch (_radioValue1) {
  //     //   case 0:
  //     //   case 1:
  //     //   case 2:
}
