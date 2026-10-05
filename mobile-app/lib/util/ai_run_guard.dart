import 'package:harrier_central/imports.dart';

/// Runs imported by AI from a kennel's own runs page (inbound integration 6)
/// are kept in step with that page — until someone edits one in Harrier
/// Central. The server then adopts it as a Harrier Central run and the AI
/// stops updating it (nonApi_adoptImportedRun, James 2026-10-05). Every
/// app path that saves an existing run asks here first.
///
/// Asked once per run per app session; a run already confirmed, or one
/// that is not an AI import, passes straight through.
class AiRunGuard {
  AiRunGuard._();

  static const int runsPageIntegrationId = 6;
  static final Set<String> _confirmed = <String>{};

  /// True to go ahead with the save (or delete).
  static Future<bool> confirmEdit({
    required String eventId,
    required int? inboundIntegrationId,
    bool deleting = false,
  }) async {
    if (inboundIntegrationId != runsPageIntegrationId) return true;
    final String key = eventId.toLowerCase();
    if (_confirmed.contains(key)) return true;
    final bool? ok = await Utilities.showAlert(
      deleting
          ? 'Delete this AI-imported run?'
          : 'Stop syncing with the website?',
      deleting
          ? 'This run was imported by AI from the kennel\'s own runs page.\n\n'
                'Deleting it here removes it from Harrier Central for good: '
                'the AI will not bring it back, even if it is still on the website.'
          : 'This run was imported by AI from the kennel\'s own runs page, and '
                'Harrier Central keeps it in step with that page.\n\n'
                'Saving your change makes it a Harrier Central run: the AI will no '
                'longer update it from the website.',
      deleting ? 'Delete' : 'Save anyway',
      showCancelButton: true,
    );
    if (ok != true) return false;
    _confirmed.add(key);
    return true;
  }
}
