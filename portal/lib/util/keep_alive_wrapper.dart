import 'package:hcportal/imports.dart';

class KeepAliveWrapper extends StatefulWidget {

  const KeepAliveWrapper({required this.child, super.key});
  final Widget child;

  @override
  KeepAliveWrapperState createState() => KeepAliveWrapperState();
}

class KeepAliveWrapperState extends State<KeepAliveWrapper> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important for AutomaticKeepAliveClientMixin to work
    return widget.child;
  }
}
