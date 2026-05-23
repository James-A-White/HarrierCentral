import 'dart:core';

import 'package:flutter/material.dart';
import 'package:harrier_central/util/text_styles.dart';

class MultipleChoicePopupHc extends StatefulWidget {
  const MultipleChoicePopupHc({
    required Key key,
    required this.title,
    required this.buttons,
    this.otherControls,
    required this.cancelButtonTitle,
    required this.cancelButtonReturnValue,
    //required this.buttonPress,
  }) : super(key: key);

  final String title;
  final List<Map<String, dynamic>> buttons;
  final List<Widget>? otherControls;
  final String cancelButtonTitle;
  final dynamic cancelButtonReturnValue;
  //final Function buttonPress;

  @override
  MultipleChoicePopupStateHc createState() => MultipleChoicePopupStateHc();
}

class MultipleChoicePopupStateHc extends State<MultipleChoicePopupHc> {
  final FocusNode myFocusNodeFirstName = FocusNode();
  TextEditingController followKennelAmountTextController =
      TextEditingController();

  @override
  void dispose() {
    myFocusNodeFirstName.dispose();
    followKennelAmountTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title, style: ts_alertDialogTitle),
      contentPadding: const EdgeInsets.fromLTRB(14, 20, 14, 10),
      content: Column(mainAxisSize: MainAxisSize.min, children: getButtons()),
    );
  }

  List<Widget> getButtons() {
    final List<Widget> buttons = <Widget>[];

    for (final Map<String, dynamic> btnDef in widget.buttons) {
      if (btnDef['title'].toString().isEmpty) {
        continue;
      }
      if (btnDef['returnValue'] == null) {
        double height = 1.0;
        double thickness = 1.0;
        double indent = 0.0;
        double paddingTop = 0.0;
        double paddingBottom = 0.0;

        if (btnDef.containsKey('indent') && btnDef['indent'] is double) {
          indent = btnDef['indent'] as double;
        }

        if (btnDef.containsKey('height') && btnDef['height'] is double) {
          height = btnDef['height'] as double;
        }

        if (btnDef.containsKey('thickness') && btnDef['thickness'] is double) {
          thickness = btnDef['thickness'] as double;
        }

        if (btnDef.containsKey('paddingTop') &&
            btnDef['paddingTop'] is double) {
          paddingTop = btnDef['paddingTop'] as double;
        }

        if (btnDef.containsKey('paddingBottom') &&
            btnDef['paddingBottom'] is double) {
          paddingBottom = btnDef['paddingBottom'] as double;
        }
        final Widget d = Padding(
          padding: EdgeInsets.only(top: paddingTop, bottom: paddingBottom),
          child: Divider(
            color: Colors.black,
            height: height,
            thickness: thickness,
            indent: indent,
            endIndent: indent,
          ),
        );
        buttons.add(d);
        buttons.add(const SizedBox(height: 10.0));
        continue;
      }
      final Widget w = Row(
        children: <Widget>[
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop<dynamic>(btnDef['returnValue']);
              },
              child: Container(
                //padding: EdgeInsets.only(top: 6.0 * deviceHeightScaleFactor, left: 8.0, bottom: 6.0 * deviceHeightScaleFactor),
                color: hc_blue,
                child: Row(
                  children: <Widget>[
                    const SizedBox(width: 8.0),
                    Stack(
                      alignment: AlignmentDirectional.center,
                      children: btnDef['icon'] as List<Widget>,
                    ),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 8.0,
                          top: 16.0,
                          bottom: 10.0,
                        ),
                        child: Text(
                          btnDef['title'].toString(),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'AvenirNextMedium',
                            fontStyle: FontStyle.normal,
                            color: Colors.white,
                            fontSize: 16.0,
                            height: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                //textColor: Colors.white,
              ),
            ),
          ),
        ],
      );

      buttons.add(w);
      buttons.add(const SizedBox(height: 10.0));
    }

    if (widget.otherControls != null) {
      buttons.addAll(widget.otherControls!);
    }

    buttons.add(
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: hc_red,
          textStyle: const TextStyle(color: Colors.white),
        ),
        child: Text(widget.cancelButtonTitle, style: ts_button),
        onPressed: () {
          Navigator.of(context).pop(widget.cancelButtonReturnValue);
        },
      ),
    );
    return buttons;
  }
}
