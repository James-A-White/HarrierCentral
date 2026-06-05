import 'package:harrier_central/imports.dart';

class GuestActionBar extends StatelessWidget {
  const GuestActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        border: const Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const IntroSliderPage(),
                ),
              ),
              child: Text(
                'Create your free account now',
                style: ts_button.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'or',
            style: ts_body.copyWith(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const FindMyAccountPage(),
              ),
            ),
            child: Text(
              'Log In',
              style: ts_body.copyWith(
                color: Colors.white70,
                fontSize: 14,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
