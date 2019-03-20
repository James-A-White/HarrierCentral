import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FancyDivider extends StatelessWidget {
  final Color innerColor;

  const FancyDivider({
    @required this.innerColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ShapePainter(color: innerColor),
      child: Padding(
        padding: const EdgeInsets.only(top: 0.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Container(
            //   decoration: BoxDecoration(
            //     gradient: LinearGradient(
            //         colors: <Color>[
            //           outerColor,
            //           innerColor,
            //         ],
            //         begin: FractionalOffset(0.0, 0.0),
            //         end: FractionalOffset(1.0, 1.0),
            //         stops: <double>[0.0, 1.0],
            //         tileMode: TileMode.clamp),
            //   ),
            //   width: 100.0,
            //   height: 1.0,
            // ),
            // Padding(
            //   padding: EdgeInsets.only(left: 15.0, right: 15.0),
            //   child: Icon(FontAwesomeIcons.circle,
            //       color: this.innerColor, size: 10.0),
            // ),
            // Container(
            //   decoration: BoxDecoration(
            //     gradient: LinearGradient(
            //         colors: <Color>[
            //           innerColor,
            //           outerColor,
            //         ],
            //         begin: FractionalOffset(0.0, 0.0),
            //         end: FractionalOffset(1.0, 1.0),
            //         stops: <double>[0.0, 1.0],
            //         tileMode: TileMode.clamp),
            //   ),
            //   width: 100.0,
            //   height: 1.0,
            // ),
          ],
        ),
      ),
    );
  }
}

class ShapePainter extends CustomPainter {
  final Color color;

  const ShapePainter({
    @required this.color,
  });

  void paint(Canvas canvas, Size size) {
    num dividerHeight = 1.0;
    num dividerInset = 20.0;
    num dividerGap = 15.0;
    num ballSize = 4.0;

    final paint = Paint();
    // set the color property of the paint
    paint.color = color;
// create a path
    var path = Path();
    path.moveTo((size.width / 2.0) + dividerGap, size.height - dividerHeight);
    path.lineTo(size.width - dividerInset, size.height);
    path.lineTo((size.width / 2.0) + dividerGap, size.height + dividerHeight);
    path.lineTo((size.width / 2.0) + dividerGap, size.height - dividerHeight);
// close the path to form a bounded shape
    path.close();

    // draw the circle on centre of canvas having radius 75.0
    canvas.drawPath(path, paint);

    path.reset();

    path.moveTo((size.width / 2.0) - dividerGap, size.height - dividerHeight);
    path.lineTo(dividerInset, size.height);
    path.lineTo((size.width / 2.0) - dividerGap, size.height + dividerHeight);
    path.lineTo((size.width / 2.0) - dividerGap, size.height - dividerHeight);
// close the path to form a bounded shape
    path.close();

    // draw the circle on centre of canvas having radius 75.0
    canvas.drawPath(path, paint);

    // center of the canvas is (x,y) => (width/2, height/2)
    var center = Offset(size.width / 2, size.height / 2);
    // draw the circle with center having radius 75.0
    canvas.drawCircle(center, ballSize, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
