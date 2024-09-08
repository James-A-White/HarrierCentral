import 'package:harrier_central/imports.dart';

class EmailPopup extends StatefulWidget {
  const EmailPopup({
    super.key,
    this.initialEmailAddress,
  });

  final String? initialEmailAddress;

  @override
  EmailPopupState createState() => EmailPopupState();
}

class EmailPopupState extends State<EmailPopup> {
  final FocusNode myFocusNodeFirstName = FocusNode();
  TextEditingController emailTextController = TextEditingController();

  @override
  void initState() {
    emailTextController.text = widget.initialEmailAddress ?? '';
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
        style: ts_titleMediumBlack,
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: const Icon(
            FontAwesome.envelope,
            color: Colors.white,
          ),
          hintText: 'E-mail address',
          hintStyle: ts_titleMediumBlack,
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
