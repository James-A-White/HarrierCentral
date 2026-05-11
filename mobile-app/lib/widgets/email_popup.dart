import 'package:harrier_central/imports.dart';

class EmailPopup extends StatefulWidget {
  const EmailPopup({super.key, this.initialEmailAddress});

  final String? initialEmailAddress;

  @override
  EmailPopupState createState() => EmailPopupState();
}

class EmailPopupState extends State<EmailPopup> {
  final FocusNode myFocusNodeFirstName = FocusNode();
  TextEditingController emailTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    emailTextController.text = widget.initialEmailAddress ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Enter email address', style: ts_alertDialogTitle),
      content: TextField(
        autofocus: true,
        focusNode: myFocusNodeFirstName,
        controller: emailTextController,
        keyboardType: TextInputType.emailAddress,
        style: ts_alertDialogBody,
        decoration: InputDecoration(
          border: InputBorder.none,
          // icon: const Icon(
          //   FontAwesome.envelope,
          //   color: Colors.white,
          // ),
          hintText: 'E-mail address',
          hintStyle: ts_hint,
        ),
      ),
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(
            shape: button_shape,
            backgroundColor: hc_red,
          ),
          child: Text('Cancel', style: ts_button),
          onPressed: () {
            Navigator.of(
              context,
            ).pop(<String, String>{'type': 'cancel', 'email': ''});
          },
        ),

        TextButton(
          style: TextButton.styleFrom(
            shape: button_shape,
            backgroundColor: hc_blue,
          ),
          child: Text('OK', style: ts_button),
          onPressed: () {
            Navigator.of(context).pop(<String, String>{
              'type': paymentCashOtherAmount.value.toString(),
              'email': emailTextController.text,
            });
          },
        ),

        // ),
      ],
    );
  }
}
