import 'package:harrier_central/imports.dart';

class CreateNewEventPopup extends StatefulWidget {
  const CreateNewEventPopup(this.title, {super.key});

  final String title;

  @override
  CreateNewEventPopupState createState() => CreateNewEventPopupState();
}

class CreateNewEventPopupState extends State<CreateNewEventPopup> {
  final FocusNode myFocusNodeFirstName = FocusNode();
  TextEditingController eventNameAmountTextController = TextEditingController();

  @override
  void dispose() {
    myFocusNodeFirstName.dispose();
    eventNameAmountTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title, style: ts_alertDialogTitle),
      content: TextField(
        autofocus: true,
        focusNode: myFocusNodeFirstName,
        controller: eventNameAmountTextController,
        //keyboardType: const TextInputType.
        style: ts_alertDialogBody,
        decoration: InputDecoration(
          // border: InputBorder.none,
          // icon: Icon(
          //   FontAwesome.money,
          //   color: Colors.white,
          // ),
          hintText: 'Event name',
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
          style: text_button_style.copyWith(
            backgroundColor: WidgetStatePropertyAll(hc_blue),
          ),
          child: Text('Add counted run', style: ts_button),
          onPressed: () {
            Navigator.of(context).pop(<String, String>{
              'type': eventFilterType_countEvent.value.toString(),
              'eventName': eventNameAmountTextController.text,
            });
          },
        ),

        TextButton(
          style: text_button_style.copyWith(
            backgroundColor: WidgetStatePropertyAll(hc_blue),
          ),
          child: Text('Add other event', style: ts_button),
          onPressed: () {
            Navigator.of(context).pop(<String, String>{
              'type': eventFilterType_doNotCountEvent.value.toString(),
              'eventName': eventNameAmountTextController.text,
            });
          },
        ),

        TextButton(
          style: text_button_style,
          child: Text('Cancel', style: ts_button),
          onPressed: () {
            Navigator.of(
              context,
            ).pop(<String, String>{'type': 'cancel', 'eventName': ''});
          },
        ),
      ],
    );
  }
}
