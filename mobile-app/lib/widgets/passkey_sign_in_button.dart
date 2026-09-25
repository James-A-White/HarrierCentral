import 'package:harrier_central/imports.dart';

/// "Sign in with my passkey" (E9.F7.S13): the passkey made on hashruns.org
/// signs the hasher into a fresh install with one tap. The web verifies it
/// and answers with an invite code; the invite-code page then takes the
/// app's ordinary authorisation path with that code.
class PasskeySignInButton extends StatefulWidget {
  const PasskeySignInButton({super.key});

  @override
  State<PasskeySignInButton> createState() => _PasskeySignInButtonState();
}

class _PasskeySignInButtonState extends State<PasskeySignInButton> {
  bool _busy = false;

  Future<void> _signIn() async {
    if (_busy) return;
    if (!Utilities.isConnected(showDialog: true)) return;
    setState(() => _busy = true);
    try {
      final String code = await PasskeySignInService().signIn();
      if (!mounted) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => UseInviteCodePage(initialCode: code),
        ),
      );
    } on PasskeySignInException catch (e) {
      await Utilities.showAlert('Passkey sign-in', e.message, 'OK');
    } catch (e) {
      await Utilities.showAlert(
        'Passkey sign-in',
        "That didn't work: $e",
        'OK',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: themeAppBarBackground,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _busy ? null : _signIn,
        icon: _busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.key, color: Colors.white, size: 24),
        label: Text('Sign in with my passkey', style: ts_button, textAlign: TextAlign.center),
      ),
    );
  }
}
