import 'package:harrier_central/imports.dart';

class CreateNewEventPopup extends StatefulWidget {
  const CreateNewEventPopup(
    this.title, {
    super.key,
  });

  final String title;

  @override
  CreateNewEventPopupState createState() => CreateNewEventPopupState();
}

class CreateNewEventPopupState extends State<CreateNewEventPopup> {
  final FocusNode myFocusNodeFirstName = FocusNode();
  TextEditingController eventNameAmountTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        autofocus: true,
        focusNode: myFocusNodeFirstName,
        controller: eventNameAmountTextController,
        //keyboardType: const TextInputType.
        style: ts_titleMediumBlack,
        decoration: InputDecoration(
          // border: InputBorder.none,
          // icon: Icon(
          //   FontAwesome.money,
          //   color: Colors.white,
          // ),
          hintText: 'Event name',
          hintStyle: ts_titleMediumBlack,
        ),
      ),
      actions: <Widget>[
        // Padding(
        //   padding: const EdgeInsets.only(right: 0.0),
        //   child: Container(
        //     width: 60.0,
        //     child:

        TextButton(
          style: TextButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop(<String, String>{'type': 'cancel', 'eventName': ''});
          },
        ),

        TextButton(
            style: TextButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Other event'),
            onPressed: () {
              Navigator.of(context).pop(<String, String>{'type': eventFilterType_doNotCountEvent.value.toString(), 'eventName': eventNameAmountTextController.text});
            }),

        TextButton(
            style: TextButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Counted run'),
            onPressed: () {
              Navigator.of(context).pop(<String, String>{'type': eventFilterType_countEvent.value.toString(), 'eventName': eventNameAmountTextController.text});
            }),
      ],
    );
  }
}
