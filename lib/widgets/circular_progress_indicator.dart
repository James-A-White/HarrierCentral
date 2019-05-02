import 'package:flutter/material.dart';

import 'package:flutter_spinkit/flutter_spinkit.dart';

class HcCircularProgressIndicator extends StatelessWidget {
  const HcCircularProgressIndicator();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SpinKitCircle(
        size: 75.0,
        itemBuilder: (_, int index) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: index.isEven
                  ? Colors.grey[400]
                  : Theme.of(context).accentColor,
            ),
          );
        },
      ),
    );
  }
}










