import 'package:flutter/material.dart';

class FancyDivider extends StatelessWidget {
  const FancyDivider({@required this.innerColor, this.useTextOr = false, this.topMargin = 0.0, this.bottomMargin = 0.0});

  final Color innerColor;
  final bool useTextOr;
  final num topMargin;
  final num bottomMargin;

  @override
  Widget build(BuildContext context) {
    return 
    Container(
      margin: EdgeInsets.only(top:topMargin,bottom:bottomMargin),
      child: CustomPaint(
        painter: ShapePainter(color: innerColor, useTextOr: useTextOr),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            useTextOr
                ? const Text('or',
                    style: TextStyle(
                        fontFamily: 'AvenirNextDemiBold',
                        fontStyle: FontStyle.normal,
                        fontSize: 18.0,
                        color: Colors.white))
                : Container(),
          ],
        ),
      ),
    );
  }
}

class ShapePainter extends CustomPainter {
  const ShapePainter({@required this.color, this.useTextOr});

  final Color color;
  final bool useTextOr;

  @override
  void paint(Canvas canvas, Size size) {
    const num yOffset = -11;
    const num dividerHeight = 1.0;
    const num dividerInset = 20.0;
    const num dividerGap = 15.0;
    const num ballSize = 4.0;

    final Paint paint = Paint();
    // set the color property of the paint
    paint.color = color;
// create a path
    final Path path = Path();
    path.moveTo(
        (size.width / 2.0) + dividerGap, size.height - dividerHeight + yOffset);
    path.lineTo(size.width - dividerInset, size.height + yOffset);
    path.lineTo(
        (size.width / 2.0) + dividerGap, size.height + dividerHeight + yOffset);
    path.lineTo(
        (size.width / 2.0) + dividerGap, size.height - dividerHeight + yOffset);
// close the path to form a bounded shape
    path.close();

    // draw the circle on centre of canvas having radius 75.0
    canvas.drawPath(path, paint);

    path.reset();

    path.moveTo(
        (size.width / 2.0) - dividerGap, size.height - dividerHeight + yOffset);
    path.lineTo(dividerInset, size.height + yOffset);
    path.lineTo(
        (size.width / 2.0) - dividerGap, size.height + dividerHeight + yOffset);
    path.lineTo(
        (size.width / 2.0) - dividerGap, size.height - dividerHeight + yOffset);
// close the path to form a bounded shape
    path.close();

    // draw the circle on centre of canvas having radius 75.0
    canvas.drawPath(path, paint);

    if (useTextOr) {
    } else {
      // center of the canvas is (x,y) => (width/2, height/2)
      final Offset center = Offset(size.width / 2, (size.height / 2) + yOffset);
      // draw the circle with center having radius 75.0
      canvas.drawCircle(center, ballSize, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
