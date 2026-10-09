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
    final bool busy =
        c.isDrafting.value || c.isSending.value || c.isPreviewing.value;
    // Read inside the Obx so a move on the audience page updates the button.
    final int n =
        emailContext.recipientCount - c.excludeIds.length + c.includeIds.length;
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
                const SizedBox(height: 6),
                Text(
                  c.history,
                  style: TextStyle(
                    color: emailContext.alreadySent
                        ? Colors.amberAccent
                        : Colors.white70,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                _field(
                  c.savedInstruction.isEmpty
                      ? 'Anything to add? (optional)'
                      : '${eventAggregate.kennel.kennelShortName}\'s usual instruction',
                  TextField(
                    controller: c.instruction,
                    enabled: !busy,
                    maxLength: 300,
                    // Grows with the text: two lines to start, up to eight.
                    minLines: 2,
                    maxLines: 8,
                    keyboardType: TextInputType.multiline,
                    style: _fieldText,
                    decoration: _deco(
                      'e.g. make it a funny Halloween story · write it in French',
                    ),
                  ),
                ),
                CheckboxListTile(
                  value: c.saveInstruction.value,
                  onChanged: busy
                      ? null
                      : (bool? v) => c.saveInstruction.value = v ?? false,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  checkColor: Colors.black,
                  activeColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  title: Text(
                    'Save as ${eventAggregate.kennel.kennelShortName}\'s default',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Pre-filled for whoever emails the next run. Tick with the box empty to clear it.',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
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
                  _field(
                    'Subject',
                    TextField(
                      controller: c.subject,
                      enabled: !c.isSending.value,
                      maxLength: 150,
                      // Wraps rather than scrolling off the right; Return
                      // submits (text keyboard), so no line breaks get in.
                      minLines: 1,
                      maxLines: 3,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      style: _fieldText,
                      decoration: _deco(''),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _field(
                    'Your message',
                    TextField(
                      controller: c.body,
                      enabled: !c.isSending.value,
                      minLines: 8,
                      maxLines: 40,
                      maxLength: 6000,
                      keyboardType: TextInputType.multiline,
                      style: _fieldText,
                      decoration: _deco(''),
                    ),
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
          const SizedBox(height: 14),
          // Try it on yourself, and see who it reaches — before it goes.
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: <Widget>[
              ElevatedButton.icon(
                onPressed: busy ? null : c.preview,
                icon: c.isPreviewing.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.mark_email_read_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                label: Text(
                  'Preview to me',
                  style: ts_button,
                  textAlign: TextAlign.center,
                ),
              ),
              ElevatedButton.icon(
                onPressed: c.isSending.value ? null : c.openAudience,
                icon: const Icon(
                  Icons.people_outline,
                  color: Colors.white,
                  size: 18,
                ),
                label: Text(
                  'Who gets it',
                  style: ts_button,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
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

  /// The fields are white, so what is typed in them is dark — the page's
  /// white text styles vanished on them (1452). The caption sits ABOVE the
  /// field, in white on the jungle, never floating onto the white fill.
  static const TextStyle _fieldText = TextStyle(
    color: Colors.black87,
    fontSize: 16,
  );

  Widget _field(String caption, Widget field) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 4),
        child: Text(
          caption,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ),
      field,
    ],
  );

  InputDecoration _deco(String hint) => InputDecoration(
    hintText: hint.isEmpty ? null : hint,
    hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
    counterStyle: const TextStyle(color: Colors.white54),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    isDense: true,
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
