import 'dart:core';

import 'package:flutter/material.dart';

import 'package:harrier_central/util/enums.dart';

class MultipleChoicePopup extends StatefulWidget {
  const MultipleChoicePopup({
    @required this.title,
    @required this.buttons,
    @required this.cancelButtonTitle,
    @required this.buttonPress,
  });

  final String title;
  final List<Map<String, dynamic>> buttons;
  final String cancelButtonTitle;
  final Function buttonPress;

  @override
  _MultipleChoicePopupState createState() => _MultipleChoicePopupState();
}

class _MultipleChoicePopupState extends State<MultipleChoicePopup> {
  final FocusNode myFocusNodeFirstName = FocusNode();
  TextEditingController followKennelAmountTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(mainAxisSize: MainAxisSize.min, children: getButtons()

          //  <Widget>[

          // ],
          ),
      // actions: <Widget>[
      //   // Padding(
      //   //   padding: const EdgeInsets.only(right: 0.0),
      //   //   child: Container(
      //   //     width: 60.0,
      //   //     child:

      //   FlatButton(
      //     color: Colors.red,
      //     child: const Text('Cancel'),
      //     textColor: Colors.white,
      //     onPressed: () {
      //       Navigator.of(context)
      //           .pop(<String, String>{'type': 'cancel', 'amount': ''});
      //     },
      //   ),

      // ],
    );

    //     Image.network(kennel.kennelLogo,
    //         fit: BoxFit.fitHeight, height: logoHeight),
    // alignment: Alignment.centerRight);
  }

  List<Widget> getButtons() {
    final List<Widget> buttons = <Widget>[];

    for (Map<String, dynamic> btnDef in widget.buttons) {
      final Widget w = Container(
        width: 350,
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
        child: FlatButton(
          padding: const EdgeInsets.only(top: 8.0, left: 8.0, bottom: 8.0),
          color: Colors.blue[900],
          child: Row(children: <Widget>[
            Stack(alignment: AlignmentDirectional.center, children: btnDef['icon']),
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 0),
              child: Text(btnDef['title'].toString()),
            ),
          ]),
          textColor: Colors.white,
          onPressed: () {
            Navigator.of(context).pop();
            widget.buttonPress(btnDef['returnValue']);
          },
        ),
      );

      buttons.add(w);
    }
    buttons.add(
      FlatButton(
        color: Colors.red,
        child: Text(widget.cancelButtonTitle),
        textColor: Colors.white,
        onPressed: () {
          Navigator.of(context).pop(followTypeCancel);
        },
      ),
    );
    return buttons;
  }
}
