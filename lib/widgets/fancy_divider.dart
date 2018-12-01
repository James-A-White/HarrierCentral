import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class FancyDivider extends StatelessWidget {
  final Color color;

  const FancyDivider({
    @required this.color,
  });

  @override
  Widget build(BuildContext context) {

    HSLColor c1 = HSLColor.fromColor(color);
    HSLColor c2 = HSLColor.fromAHSL(1.0, c1.hue, c1.saturation, 0.95);
    Color colorLight = c2.toColor();

    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: <Color>[
                    colorLight,
                    color,
                  ],
                  begin: FractionalOffset(0.0, 0.0),
                  end: FractionalOffset(1.0, 1.0),
                  stops: <double>[0.0, 1.0],
                  tileMode: TileMode.clamp),
            ),
            width: 100.0,
            height: 1.0,
          ),
         Padding(
            padding: EdgeInsets.only(left: 15.0, right: 15.0),
            child: Icon(FontAwesomeIcons.circle,
                color: this.color, size: 10.0),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: <Color>[
                    color,
                    colorLight,
                  ],
                  begin: FractionalOffset(0.0, 0.0),
                  end: FractionalOffset(1.0, 1.0),
                  stops: <double>[0.0, 1.0],
                  tileMode: TileMode.clamp),
            ),
            width: 100.0,
            height: 1.0,
          ),
        ],
      ),
    );
  }
}
