import 'dart:core';

import 'package:flutter/material.dart';

import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import 'package:harrier_central/util/enums.dart';

class FollowKennelPopup extends StatefulWidget {
  const FollowKennelPopup({@required this.kennelName});

  final String kennelName;

  @override
  _FollowKennelPopupState createState() => _FollowKennelPopupState();
}

class _FollowKennelPopupState extends State<FollowKennelPopup> {
  final FocusNode myFocusNodeFirstName = FocusNode();
  TextEditingController followKennelAmountTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Follow ${widget.kennelName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 350,
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: FlatButton(
              padding: const EdgeInsets.only(top: 8.0, left: 8.0, bottom: 8.0),
              color: Colors.blue[900],
              child: Row(children: <Widget>[
                Stack(alignment: AlignmentDirectional.center, children: <Widget>[Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)), const Icon(FontAwesome.check_circle, color: Colors.green)]),
                const Padding(
                  padding: EdgeInsets.only(left: 10, right: 0),
                  child: Text('Always show runs'),
                ),
              ]),
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).pop(followTypeFollow);
              },
            ),
          ),
          Container(
            width: 350,
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: FlatButton(
              padding: const EdgeInsets.only(top: 8.0, left: 8.0, bottom: 8.0),
              color: Colors.blue[900],
              child: Row(children: <Widget>[
                Stack(alignment: AlignmentDirectional.center, children: <Widget>[Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)), const Icon(FontAwesome.times_circle, color: Colors.red)]),
                const Padding(
                  padding: EdgeInsets.only(left: 10, right: 0),
                  child: Text('Never show runs'),
                ),
              ]),
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).pop(followTypeIgnore);
              },
            ),
          ),
          Container(
            width: 350,
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: FlatButton(
              padding: const EdgeInsets.only(top: 8.0, left: 8.0, bottom: 8.0),
              color: Colors.blue[900],
              child: Row(children: const <Widget>[
                Icon(
                  FontAwesome.star,
                  color: Colors.yellow,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 10, right: 0),
                  child: Text('Show when within 50km'),
                ),
              ]),
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).pop(followTypeAuto);
              },
            ),
          ),
          FlatButton(
            color: Colors.red,
            child: const Text('Cancel'),
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).pop(followTypeCancel);
            },
          ),
        ],
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
