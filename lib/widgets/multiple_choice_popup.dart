import 'dart:core';

import 'package:flutter/material.dart';

import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/styles.dart';

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
      contentPadding: const EdgeInsets.fromLTRB(14, 20, 14, 10),
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
      if (btnDef['title'].toString().isEmpty) {
        continue;
      }
      final Widget w = Row(children: <Widget>[
        Expanded(
          child: GestureDetector(
            onTap: () {
              widget.buttonPress(btnDef['returnValue']);
              Navigator.of(context).pop<dynamic>(btnDef['returnValue'].value);
            },
            child: Container(
              //padding: EdgeInsets.only(top: 6.0 * deviceHeightScaleFactor, left: 8.0, bottom: 6.0 * deviceHeightScaleFactor),
              color: Colors.blue[900],
              child: Row(children: <Widget>[
                const SizedBox(width: 8.0,),
                Stack(alignment: AlignmentDirectional.center, children: btnDef['icon']),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 16.0, bottom: 10.0),
                    child: Text(
                      btnDef['title'].toString(),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: buttonLabelStyleSmall,
                    ),
                  ),
                ),
              ]),
              //textColor: Colors.white,
            ),
          ),
        )
      ]);

      buttons.add(w);
      buttons.add(const SizedBox(height: 10.0));
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
