import 'package:harrier_central/imports.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final bool? resizeToAvoidBottomInset;
  final bool? extendBody;

  const AppScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.appBar,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset,
    this.extendBody,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: AndroidSafeArea(child: body),
      bottomNavigationBar: bottomNavigationBar == null
          ? null
          : AndroidSafeArea(child: bottomNavigationBar!),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: floatingActionButton,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody ?? false,
    );
  }
}
