import 'package:harrier_central/imports.dart';

class DontKnowAccountPage extends StatelessWidget {
  const DontKnowAccountPage({super.key});

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
              title: Text('Not Sure?', style: ts_appBarTitle),
            ),
            body: Container(
              decoration: Backgrounds.defaultHcBackground(),
              width: MediaQuery.sizeOf(context).width,
              height: MediaQuery.sizeOf(context).height,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28.0,
                    vertical: 32.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'How to find out',
                        style: ts_headingVeryLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'You may already have a Harrier Central account if any of the following apply:',
                        style: ts_body,
                      ),
                      const SizedBox(height: 16),
                      _BulletPoint(
                        text:
                            "You've used Harrier Central on another device before.",
                      ),
                      _BulletPoint(
                        text:
                            'Your kennel mis-management team mentioned setting up an account for you.',
                      ),
                      _BulletPoint(
                        text:
                            "You've received an invite code from your kennel.",
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'What to do',
                        style: ts_headingLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Ask your kennel mis-management team. They will be able to tell you whether an account already exists for you and, if so, provide you with an invite code to connect to it.',
                        style: ts_body,
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const UseInviteCodePage(),
                            ),
                          ),
                          child: Text(
                            'I have an invite code',
                            style: ts_button,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const CreateNewAccountPage(),
                            ),
                          ),
                          child: Text(
                            "I definitely don't have an account",
                            style: ts_button,
                          ),
                        ),
                      ),
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

class _BulletPoint extends StatelessWidget {
  const _BulletPoint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('•  ', style: ts_body),
          Expanded(child: Text(text, style: ts_body)),
        ],
      ),
    );
  }
}
