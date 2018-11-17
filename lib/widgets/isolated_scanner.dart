import 'package:flutter/material.dart';

class IsolatedScanner extends StatelessWidget {
 final Color color;

 const IsolatedScanner(this.color);

 @override
 Widget build(BuildContext context) {
   return Container(
     color: color,
   );
 }
}