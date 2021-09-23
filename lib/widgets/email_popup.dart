// @dart=2.11
import 'package:harrier_central/imports.dart';

class EmailPopup extends StatefulWidget {
  const EmailPopup({Key key, this.initialEmailAddress}) : super(key: key);

  final String initialEmailAddress;

  @override
  _EmailPopupState createState() => _EmailPopupState();
}

class _EmailPopupState extends State<EmailPopup> {
  final FocusNode myFocusNodeFirstName = FocusNode();
  TextEditingController emailTextController = TextEditingController();

  @override
  void initState() {
    emailTextController.text = widget.initialEmailAddress;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter email address'),
      content: TextField(
        autofocus: true,
        focusNode: myFocusNodeFirstName,
        controller: emailTextController,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0, color: Colors.black),
        decoration: const InputDecoration(
          border: InputBorder.none,
          icon: Icon(
            FontAwesome.envelope,
            color: Colors.white,
          ),
          hintText: 'E-mail address',
          hintStyle: TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
        ),
      ),
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop(<String, String>{'type': 'cancel', 'email': ''});
          },
        ),

        TextButton(
            style: TextButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(<String, String>{'type': paymentCashOtherAmount.value.toString(), 'email': emailTextController.text});
            }),

        // ),
      ],
    );
  }
}
