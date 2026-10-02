import 'package:harrier_central/imports.dart';

/// "Message `name`" from anywhere: a chat message's long-press (E9.F1.S19),
/// the hasher page (E10.F1.S5 / E9.F1.S26). The server answers open /
/// requested / refused / blocked from THEIR direct-message setting and the
/// friendship rows; this only shows what it said, so being findable never
/// means being messageable.
///
/// [onUnblocked] runs after an Unblock from the toast succeeds (the chat
/// re-fetches its threads; other callers have nothing to refresh).
Future<void> messageHasher(
  HcId publicHasherId,
  String name, {
  void Function()? onUnblocked,
}) async {
  String? refusal;
  final DmStartResult? result = await DirectMessageService.start(
    publicHasherId,
    onRefused: (String? why) => refusal = why,
  );

  if (result == null) {
    hcSnack(
      (refusal == null || refusal!.isEmpty)
          ? '$name could not be messaged. Please try again.'
          : refusal!,
      error: true,
      seconds: 5,
    );
    return;
  }

  final String other = result.otherDisplayName;
  switch (result.outcome) {
    case DmOutcome.open:
      final HcId? thread = result.threadId;
      if (thread == null) {
        hcSnack('$other could not be messaged. Please try again.', error: true);
        return;
      }
      await ChatPageController.openDirectMessage(
        threadId: thread,
        otherPublicHasherId: result.otherPublicHasherId,
        otherDisplayName: other,
        otherPhoto: result.otherPhoto,
      );
    case DmOutcome.requested:
      hcSnack(
        "$other will be asked. You'll be told when they accept.",
        seconds: 5,
      );
    case DmOutcome.refused:
      hcSnack("$other isn't accepting messages.", error: true, seconds: 5);
    case DmOutcome.blocked:
      hcSnack(
        "You've blocked $other.",
        error: true,
        seconds: 6,
        actionLabel: 'Unblock',
        onAction: () =>
            unawaited(_unblock(result.otherPublicHasherId, other, onUnblocked)),
      );
    case DmOutcome.declined:
    case DmOutcome.unknown:
      hcSnack('$other could not be messaged right now.', error: true);
  }
}

Future<void> _unblock(
  HcId publicHasherId,
  String name,
  void Function()? onUnblocked,
) async {
  final BlockOutcome outcome = await HasherBlockService.setBlock(
    publicHasherId,
    blocked: false,
  );
  if (!outcome.ok) {
    final String? why = outcome.refusal;
    hcSnack(
      (why == null || why.isEmpty)
          ? '$name could not be unblocked. Please try again.'
          : why,
      error: true,
      seconds: 5,
    );
    return;
  }
  hcSnack('$name unblocked');
  onUnblocked?.call();
}
