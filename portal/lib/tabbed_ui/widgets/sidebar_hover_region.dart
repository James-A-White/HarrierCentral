import 'package:hcportal/imports.dart';

/// Wraps a child so sidebar content updates on hover using the control's
/// configured entry/exit keys and inline sidebar data.
class SidebarHoverRegion extends StatelessWidget {
  const SidebarHoverRegion({
    super.key,
    required this.controller,
    required this.uiControl,
    required this.child,
  });

  final TabUiController controller;
  final UiControlDefinition uiControl;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        controller.setSidebarData(
          uiControl.sidebarEntryKey,
          sidebarData: uiControl.sidebarData,
        );
      },
      onExit: (_) {
        controller.setSidebarData(uiControl.sidebarExitKey);
      },
      child: child,
    );
  }
}
