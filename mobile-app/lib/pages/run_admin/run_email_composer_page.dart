import 'package:harrier_central/imports.dart';

/// Save and send → Email: the composer (E9.F6.S7). Stateless over
/// [RunEmailComposerController]. Pops with the recipient count on send.
class RunEmailComposerPage extends StatelessWidget {
  const RunEmailComposerPage({
    super.key,
    required this.eventAggregate,
    required this.emailContext,
  });

  final RunAdminAggregate eventAggregate;
  final RunEmailContext emailContext;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RunEmailComposerController>(
      init: RunEmailComposerController(
        eventAggregate: eventAggregate,
        context: emailContext,
      ),
      tag: RunEmailComposerController.tagFor(eventAggregate.event.eventId),
      builder: (RunEmailComposerController c) => AppScaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: themeAppBarBackground,
          iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
          title: Text('Email the run', style: ts_appBarTitle),
        ),
        body: DecoratedBox(
          decoration: Backgrounds.defaultHcBackground(),
          child: Obx(() => _body(context, c)),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, RunEmailComposerController c) {
    final bool busy = c.isDrafting.value || c.isSending.value;
    final int n = emailContext.recipientCount;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  emailContext.title,
                  style: ts_titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${emailContext.when}\n${emailContext.where}',
                  style: ts_body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: c.instruction,
                  enabled: !busy,
                  maxLength: 300,
                  style: ts_body,
                  decoration: _deco(
                    'Anything to add? (optional)',
                    hint: 'e.g. make it a funny Halloween story · write it in French',
                  ),
                ),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: busy ? null : c.draft,
                    icon: const Icon(Icons.auto_awesome, color: Colors.white),
                    label: Text(
                      c.subject.text.isEmpty ? 'Write it for me' : 'Rewrite',
                      style: ts_button,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (c.isDrafting.value)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: <Widget>[
                  HcAppCircularProgressIndicator(key: Key('runemail-drafting')),
                  SizedBox(height: 12),
                  Text(
                    'Writing the email…',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (c.draftError.value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        c.draftError.value,
                        style: const TextStyle(color: Colors.amberAccent),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  TextField(
                    controller: c.subject,
                    enabled: !c.isSending.value,
                    maxLength: 150,
                    style: ts_body,
                    decoration: _deco('Subject'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: c.body,
                    enabled: !c.isSending.value,
                    minLines: 8,
                    maxLines: 30,
                    maxLength: 6000,
                    style: ts_body,
                    decoration: _deco('Your message'),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'The run\'s date, venue, hares, price and the ✅ I\'m in / '
                    '❌ Can\'t make it buttons are added under your message '
                    'automatically, so they are always right.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          if (c.isSending.value)
            const HcAppCircularProgressIndicator(key: Key('runemail-sending'))
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: busy || n == 0 ? null : c.send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hc_red,
                  disabledBackgroundColor: Colors.grey,
                  disabledForegroundColor: Colors.white70,
                ),
                child: Text(
                  n == 0
                      ? 'Nobody has run emails on'
                      : 'Send to $n ${n == 1 ? 'member' : 'members'}',
                  style: ts_button,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _card(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.28),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white24),
    ),
    child: child,
  );

  InputDecoration _deco(String label, {String? hint}) => InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: const TextStyle(color: Colors.white70),
    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
    counterStyle: const TextStyle(color: Colors.white38),
    filled: true,
    fillColor: Colors.white,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.white60),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.white),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.white24),
    ),
  );
}
