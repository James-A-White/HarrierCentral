// @dart=2.11
import 'package:harrier_central/imports.dart';

class CreateNewEventPopup extends StatefulWidget {
  const CreateNewEventPopup(this.title, {Key key}) : super(key: key);

  final String title;

  @override
  _CreateNewEventPopupState createState() => _CreateNewEventPopupState();
}

class _CreateNewEventPopupState extends State<CreateNewEventPopup> {
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
        style: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0, color: Colors.black),
        decoration: const InputDecoration(
          // border: InputBorder.none,
          // icon: Icon(
          //   FontAwesome.money,
          //   color: Colors.white,
          // ),
          hintText: 'Event name',
          hintStyle: TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
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
