//import 'dart:io' as platform;
import 'package:harrier_central/imports.dart';

class StyleForConnected extends StatelessWidget {
  const StyleForConnected({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final network = Get.find<NetworkService>();
    return Obx(() {
      if (network.isOnline()) {
        return child;
      }

      return Container(
        foregroundDecoration: BoxDecoration(
          color: Colors.grey.shade100,
          backgroundBlendMode: BlendMode.saturation,
        ),
        child: child,
      );
    });
  }
}
