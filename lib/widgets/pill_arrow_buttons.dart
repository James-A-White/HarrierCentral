import 'package:flutter/material.dart';

class PillArrowButtons extends StatelessWidget {
  final VoidCallback onLeftPressed;
  final VoidCallback onRightPressed;

  const PillArrowButtons({
    super.key,
    required this.onLeftPressed,
    required this.onRightPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // LEFT ARROW BUTTON
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.only(
              left: 3,
              right: 3,
              top: 3,
              bottom: 3,
            ), // remove internal padding
            minimumSize: const Size(0, 0), // remove min size constraints
            tapTargetSize: MaterialTapTargetSize.shrinkWrap, // tighter hitbox

            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
            ),
          ),
          onPressed: onLeftPressed,
          child: //const Icon(Icons.arrow_back, color: Colors.white),
          const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        SizedBox(width: 4),
        // RIGHT ARROW BUTTON
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.only(
              left: 3,
              right: 3,
              top: 3,
              bottom: 3,
            ), // remove internal padding
            minimumSize: const Size(0, 0), // remove min size constraints
            tapTargetSize: MaterialTapTargetSize.shrinkWrap, // tighter hitbox

            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            //padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: onRightPressed,
          child: const Icon(Icons.arrow_forward, color: Colors.white),
        ),
      ],
    );
  }
}
