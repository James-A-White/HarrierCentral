import 'package:harrier_central/imports.dart';

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
                        description: 'Create a new account for me',
                        onPressed: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const CreateNewAccountPage(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _AnswerButton(
                        label: "I don't know",
                        description: 'Help me figure it out',
                        onPressed: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const DontKnowAccountPage(),
                          ),
                        ),
                      ),
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
            Text(label, style: ts_button.copyWith(fontSize: 20)),
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
