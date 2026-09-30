import 'package:harrier_central/imports.dart';
import 'package:harrier_central/services/location_service/tracking_preflight.dart';

/// ONE dialog listing everything the pre-flight found (E5.F1.S13), each with
/// its own button to the right settings page, plus "Check again" for when
/// they come back from Settings and "Start anyway", which is always there:
/// a start is never blocked.
///
/// Returns the issues still standing when the runner chose to go on: empty
/// when everything was put right (the dialog closes itself the moment a
/// re-check comes back clean), or the remaining list on "Start anyway".
/// Null means they backed out — do not start.
Future<List<PreflightIssue>?> showTrackingPreflightDialog(
  BuildContext context,
  List<PreflightIssue> found,
) {
  final RxList<PreflightIssue> issues = RxList<PreflightIssue>(found);
  final RxBool checking = false.obs;

  return showDialog<List<PreflightIssue>>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext ctx) {
      Future<void> recheck() async {
        checking.value = true;
        final List<PreflightIssue> now = await TrackingPreflight.check();
        checking.value = false;
        if (!ctx.mounted) return;
        if (now.isEmpty) {
          Navigator.of(ctx).pop(const <PreflightIssue>[]);
          return;
        }
        issues.assignAll(now);
      }

      Widget issueCard(PreflightIssue issue) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: hc_red.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(10),
          color: hc_red.withValues(alpha: 0.06),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: hc_red, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    issue.title,
                    style: ts_alertDialogTitle.copyWith(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(issue.detail, style: ts_alertDialogBody),
            if (issue.action != null) ...[
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: hc_blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  await issue.action!();
                  // A one-tap fix (the tier) is done at once; a Settings
                  // trip needs a re-check when they are back, and the
                  // button is right there.
                  if (issue.kind == PreflightIssueKind.powerSaverTier) {
                    await recheck();
                  }
                },
                child: Text(
                  issue.actionLabel ?? 'Fix',
                  style: ts_button,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      );

      return AlertDialog(
        title: Text(
          'Before you start',
          style: ts_alertDialogTitle,
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Obx(() {
            final List<PreflightIssue> list = issues.toList();
            final bool busy = checking.value;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  list.length == 1
                      ? 'One thing will stop this phone recording a good '
                            'trail:'
                      : '${list.length} things will stop this phone recording '
                            'a good trail:',
                  style: ts_alertDialogBody,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                for (final PreflightIssue i in list) issueCard(i),
                if (busy)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            );
          }),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => unawaited(recheck()),
            style: OutlinedButton.styleFrom(
              foregroundColor: hc_blue,
              side: BorderSide(color: hc_blue),
            ),
            child: Text(
              'Check again',
              style: ts_button.copyWith(color: hc_blue),
              textAlign: TextAlign.center,
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(issues.toList()),
            style: ElevatedButton.styleFrom(
              backgroundColor: hc_red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Start anyway',
              style: ts_button,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    },
  );
}
