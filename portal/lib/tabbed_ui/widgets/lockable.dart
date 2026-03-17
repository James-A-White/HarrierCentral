import 'package:hcportal/imports.dart';

/// Wraps a child widget to disable interaction and apply a grayscale filter
/// when the tab is locked.
class Lockable extends StatelessWidget {
  const Lockable({
    required this.lockState,
    required this.child,
    super.key,
  });

  final Rx<TabLocked> lockState;
  final Widget child;

  static const _grayscaleMatrix = ColorFilter.matrix(<double>[
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    0.5,
    0,
  ]);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLocked = lockState.value == TabLocked.tabLocked;
      return IgnorePointer(
        ignoring: isLocked,
        child: isLocked
            ? ColorFiltered(colorFilter: _grayscaleMatrix, child: child)
            : child,
      );
    });
  }
}
