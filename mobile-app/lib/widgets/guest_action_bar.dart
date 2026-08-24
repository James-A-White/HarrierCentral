import 'package:harrier_central/imports.dart';

class GuestActionBar extends StatelessWidget {
  const GuestActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(10, 12, 10, 12 + bottomPadding),
      color: themeAppBarBackground,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.green.shade700,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          // Intro + permission slides run first (each shown only when
          // needed), then hand off to the account search.
          onPressed: () => OnboardingFlowController.start(
            OnboardingDestination.findMyAccount,
          ),
          child: Text(
            'Create your free account or Log In',
            style: ts_button.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
