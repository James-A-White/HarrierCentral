import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

extension SafeSetStateExtension<T extends StatefulWidget> on State<T> {
  void setStateIfMounted(VoidCallback fn) {
    if (!mounted) return;
    // ignore: invalid_use_of_protected_member
    setState(fn);
  }
}
