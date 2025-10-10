import 'package:flutter/material.dart';

import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:harrier_central/util/styles.dart';

class HcAppCircularProgressIndicator extends StatelessWidget {
  const HcAppCircularProgressIndicator({
    this.color1,
    this.color2,
    this.size,
    required Key key,
  }) : super(key: key);

  final Color? color1;
  final Color? color2;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SpinKitCircle(
        size: size ?? 75.0,
        itemBuilder: (_, int index) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: index.isEven
                  ? (color1 ?? themeAppBarBackground)
                  : (color2 ?? Colors.grey.shade400),
            ),
          );
        },
      ),
    );
  }
}
