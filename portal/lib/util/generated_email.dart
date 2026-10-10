import 'package:flutter/material.dart';

/// An address Harrier Central made up for an account that has none (James,
/// 2026-10-10). The email is the account's key, so a hasher without one
/// still needs a unique address; it reaches nobody, and the API never sends
/// to it. Shown in [kGeneratedEmailColor] wherever an address is visible,
/// with a [GeneratedEmailNote] at the bottom of the page.
///
/// THE SAME RULE as HC6.IsGeneratedEmail (db/schema/functions),
/// GeneratedEmail.Is in api/Endpoints/HcEmail.cs and the app's
/// lib/util/generated_email.dart. Change all four together.
bool isGeneratedEmail(String? email) {
  final String e = (email ?? '').trim().toLowerCase();
  if (e.endsWith('@noemail.invalid') || e.startsWith('urc:') || e.startsWith('removed_')) return true;
  if (!e.endsWith('@harriercentral.com')) return false;
  return e.startsWith('anonymous ') || (e.indexOf('@') == 36 && _guid.hasMatch(e.substring(0, 36)));
}

final RegExp _guid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

/// Dark red: a generated address.
const Color kGeneratedEmailColor = Color(0xFF8B0000);

/// [style] for an address, turned dark red when it is generated.
TextStyle? emailTextStyle(String? email, [TextStyle? style]) =>
    isGeneratedEmail(email) ? (style ?? const TextStyle()).copyWith(color: kGeneratedEmailColor) : style;

const String kGeneratedEmailNoteText =
    'Dark red email addresses have been auto-generated and will not be used for sending emails.';

/// The note at the bottom of a page that shows email addresses. Shown only
/// when [show] — pass whether the page has a generated address on it.
class GeneratedEmailNote extends StatelessWidget {
  const GeneratedEmailNote({this.show = true, this.padding = const EdgeInsets.fromLTRB(12, 8, 12, 8), super.key});
  final bool show;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    return Padding(
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.info_outline, size: 16, color: kGeneratedEmailColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              kGeneratedEmailNoteText,
              style: const TextStyle(color: kGeneratedEmailColor, fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}
