import 'package:harrier_central/imports.dart';
import 'package:harrier_central/services/sign_in/apple_sign_in_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AccountQuestionPage extends StatelessWidget {
  const AccountQuestionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        SizedBox(
          height: MediaQuery.sizeOf(context).height,
          width: MediaQuery.sizeOf(context).width,
        ),
        Positioned(
          top: 0,
          left: 0,
          width: MediaQuery.sizeOf(context).width,
          height: MediaQuery.sizeOf(context).height,
          child: AppScaffold(
            appBar: AppBar(
              centerTitle: true,
              backgroundColor: themeAppBarBackground,
              iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
              title: Text('Get Started', style: ts_appBarTitle),
              automaticallyImplyLeading: false,
            ),
            body: Container(
              decoration: Backgrounds.defaultHcBackground(),
              width: MediaQuery.sizeOf(context).width,
              height: MediaQuery.sizeOf(context).height,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 40.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Spacer(),
                      Image.asset(
                        'images/icons/hare_icon.png',
                        height: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Do you already have a\nHarrier Central account?',
                        style: ts_headingVeryLarge,
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                      _AnswerButton(
                        label: 'Yes',
                        description: 'Take me to the invite code screen',
                        onPressed: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const UseInviteCodePage(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _AnswerButton(
                        label: 'No',
                        description: 'Search by hash name',
                        onPressed: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const FindMyAccountPage(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _AnswerButton(
                        label: "I don't know",
                        description: 'Search by hash name',
                        onPressed: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const FindMyAccountPage(),
                          ),
                        ),
                      ),
                      // Sign in with Apple, verified on the server (E1.F1.S8).
                      // iPhone only for now: Apple sign-in on Android needs the
                      // web flow.
                      if (Platform.isIOS) ...<Widget>[
                        const SizedBox(height: 28),
                        const _AppleSignInButton(),
                      ],
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.label,
    required this.description,
    required this.onPressed,
  });

  final String label;
  final String description;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Column(
          children: <Widget>[
            Text(
              label,
              style: ts_button.copyWith(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: ts_button.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Sign in with Apple (E1.F1.S8): busy from the first tap, a second tap is
/// refused, cancelling says nothing. A verified Apple identity gives the
/// account's reset code, and the invite-code page signs the phone in with it.
class AppleSignInController extends GetxController {
  final RxBool busy = false.obs;

  Future<void> signIn(BuildContext context) async {
    if (busy.value) return;
    busy.value = true;
    final NavigatorState nav = Navigator.of(context);
    try {
      final String? code = await AppleSignInService.signInForCode();
      if (isClosed || code == null) return;
      await nav.push<void>(
        MaterialPageRoute<void>(builder: (_) => UseInviteCodePage(initialCode: code)),
      );
    } on AppleSignInException catch (e) {
      await Utilities.showAlert('Sign in with Apple', e.message, 'OK');
    } finally {
      if (!isClosed) busy.value = false;
    }
  }
}

class _AppleSignInButton extends StatelessWidget {
  const _AppleSignInButton();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppleSignInController>(
      init: AppleSignInController(),
      global: false,
      builder: (AppleSignInController c) => Obx(
        () => c.busy.value
            ? const SizedBox(
                height: 50,
                child: Center(child: CircularProgressIndicator(color: Colors.white)),
              )
            : SignInWithAppleButton(
                height: 50,
                style: SignInWithAppleButtonStyle.white,
                onPressed: () => unawaited(c.signIn(context)),
              ),
      ),
    );
  }
}
