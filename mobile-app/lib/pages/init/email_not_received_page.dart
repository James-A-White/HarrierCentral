import 'package:harrier_central/imports.dart';

class EmailNotReceivedPage extends StatelessWidget {
  const EmailNotReceivedPage({super.key});

  Future<void> _contactUs() async {
    final Uri mailto = Uri(
      scheme: 'mailto',
      path: 'harriercentral@gmail.com',
      queryParameters: <String, String>{
        'subject': 'Account recovery — incorrect email address',
        'body':
            'Hi,\n\nI am trying to recover my Harrier Central account but I did not receive an invite code email. I believe the email address on my account may be incorrect.\n\nMy hash name: \nMy correct email address: \nMy kennel(s): \n\nPlease help me restore access to my account.\n\nThanks',
      },
    );
    if (await canLaunchUrl(mailto)) {
      await launchUrl(mailto);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
        title: Text('Email Not Received', style: ts_appBarTitle),
      ),
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.mail_outline, color: Colors.white70, size: 48),
                const SizedBox(height: 20),
                Text(
                  'Check your spam folder',
                  style: ts_headingVeryLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your invite code email may have been filtered into spam or junk. Please check there before trying anything else.',
                  style: ts_body,
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Still nothing?',
                        style: ts_body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'It\'s possible the email address we have on file for your account is incorrect or out of date. This can happen if you changed your email address after joining Harrier Central.',
                        style: ts_body,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Please contact us with your correct email address and we will help you restore access to your account. Once we\'ve verified your identity we\'ll update your details and send you a fresh invite code.',
                        style: ts_body,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.mail_outline, color: Colors.white),
                    label: Text('Contact Us', style: ts_button),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: themeAppBarBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _contactUs,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.white38),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text('Back to invite code entry', style: ts_button),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
