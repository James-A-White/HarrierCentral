//import 'dart:io' as platform;
import 'package:harrier_central/imports.dart';

class AndroidSafeArea extends StatelessWidget {
  const AndroidSafeArea({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return SafeArea(top: false, child: child);
    } else {
      return child;
    }
  }
}
