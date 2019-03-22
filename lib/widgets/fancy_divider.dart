import 'package:flutter/material.dart';

class FancyDivider extends StatelessWidget {
  const FancyDivider({
    @required this.innerColor,
  });

  final Color innerColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ShapePainter(color: innerColor),
      child: Padding(
        padding: const EdgeInsets.only(top: 0.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
        ),
      ),
    );
  }
}

class ShapePainter extends CustomPainter {
  const ShapePainter({
    @required this.color,
  });

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const num dividerHeight = 1.0;
    const num dividerInset = 20.0;
    const num dividerGap = 15.0;
    const num ballSize = 4.0;

    final Paint paint = Paint();
    // set the color property of the paint
    paint.color = color;
// create a path
    final Path path = Path();
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
    final Offset center = Offset(size.width / 2, size.height / 2);
    // draw the circle with center having radius 75.0
    canvas.drawCircle(center, ballSize, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
