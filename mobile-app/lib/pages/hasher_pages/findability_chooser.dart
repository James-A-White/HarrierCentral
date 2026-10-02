import 'package:harrier_central/imports.dart';

/// "Can other hashers find you?" (E9.F1.S26) — the wording James approved
/// on 2026-10-02, used in three places that must say the same thing:
///  * the once-only question after launch ([showFindabilityQuestion]),
///  * the step in sign-up ([FindabilitySignupPage]),
///  * Settings › Who can find me ([showFindabilityQuestion] with Cancel).
///
/// Nothing is pre-selected on a first answer and Save stays off until a
/// choice is made: a dismissal is never recorded as a decision.
class FindabilityController extends GetxController {
  FindabilityController({int? initial})
    : scope = RxnInt(
        initial == null ? null : DirectoryVisibility.scopeOf(initial),
      ),
      realName =
          (initial != null && DirectoryVisibility.realNameOf(initial)).obs;

  final RxnInt scope;
  final RxBool realName;
  final RxBool saving = false.obs;
  final RxnString error = RxnString();

  void choose(int s) {
    scope.value = s;
    error.value = null;
  }

  /// Saves; returns the stored value, or null (with [error] set) on failure.
  Future<int?> save() async {
    final int? s = scope.value;
    if (s == null || saving.value) return null;
    saving.value = true;
    error.value = null;
    final int? stored = await HasherDirectoryService.saveMine(
      DirectoryVisibility.compose(s, realName: realName.value),
    );
    if (isClosed) return stored;
    saving.value = false;
    if (stored == null) {
      error.value =
          'That could not be saved. Check your connection and try again.';
    }
    return stored;
  }
}

class FindabilityChooser extends StatelessWidget {
  const FindabilityChooser({
    super.key,
    required this.controller,
    required this.onDark,
    required this.onSaved,
    this.onCancel,
    this.forNewMember = false,
  });

  final FindabilityController controller;

  /// White text for the jungle (sign-up), black for a white dialog.
  final bool onDark;
  final void Function(int value) onSaved;

  /// Settings only: the first answer has no way out but a choice.
  final VoidCallback? onCancel;

  /// Sign-up: a new member is not being told about a change.
  final bool forNewMember;

  @override
  Widget build(BuildContext context) {
    final Color ink = onDark ? Colors.white : Colors.black87;
    final Color soft = onDark ? Colors.white70 : Colors.black54;
    final TextStyle body = (onDark ? ts_body : ts_alertDialogBody).copyWith(
      color: ink,
    );
    final TextStyle small = ts_bodySmall.copyWith(color: soft);

    return Obx(() {
      final int? scope = controller.scope.value;
      final bool realName = controller.realName.value;
      final bool saving = controller.saving.value;
      final String? error = controller.error.value;
      final bool nobody = scope == DirectoryVisibility.nobody;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            'Can other hashers find you?',
            style: (onDark ? ts_headingLarge : ts_alertDialogTitle).copyWith(
              color: ink,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            forNewMember
                ? 'Hashers can look each other up by name to message people '
                      "they've met on trail. Choose who can find you. You can "
                      'change this at any time in Settings.'
                : "You can now look up hashers by name to message people you've "
                      'met on trail. Choose who can find you. You can change '
                      'this at any time in Settings.',
            style: body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          for (final int s in DirectoryVisibility.scopes)
            _option(
              label: DirectoryVisibility.label(s),
              selected: scope == s,
              ink: ink,
              style: body,
              onTap: saving ? null : () => controller.choose(s),
            ),
          const SizedBox(height: 8),
          Opacity(
            opacity: nobody ? 0.4 : 1,
            child: Row(
              children: <Widget>[
                Switch.adaptive(
                  value: realName && !nobody,
                  onChanged: (nobody || saving)
                      ? null
                      : (bool v) => controller.realName.value = v,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Also let them find me by my real name',
                        style: body,
                      ),
                      Text(
                        'Otherwise they can find you only by your hash name '
                        'or home kennel.',
                        style: small,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Being found doesn't let anyone message you. Your message "
            'setting still decides that.',
            style: small,
            textAlign: TextAlign.center,
          ),
          if (error != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              error,
              style: small.copyWith(
                color: onDark ? Colors.orangeAccent : Colors.red.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: <Widget>[
              if (onCancel != null)
                TextButton(
                  onPressed: saving ? null : onCancel,
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: soft),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed: (scope == null || saving)
                    ? null
                    : () async {
                        final int? stored = await controller.save();
                        if (stored != null) onSaved(stored);
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
              ),
            ],
          ),
        ],
      );
    });
  }

  /// A radio row drawn by hand: the stock Radio's groupValue API is
  /// deprecated in this Flutter, and four rows do not need a RadioGroup.
  Widget _option({
    required String label,
    required bool selected,
    required Color ink,
    required TextStyle style,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: <Widget>[
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? hc_red : ink.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: style)),
          ],
        ),
      ),
    );
  }
}

/// The question in a dialog. [required]: the once-only question after
/// launch — no Cancel, no barrier dismiss, Back does nothing. Otherwise
/// (Settings) it opens on the current answer with a Cancel.
Future<int?> showFindabilityQuestion({required bool required, int? current}) {
  final FindabilityController c = FindabilityController(initial: current);
  return Get.dialog<int>(
    PopScope(
      canPop: !required,
      child: AlertDialog(
        backgroundColor: Colors.white,
        content: SingleChildScrollView(
          child: FindabilityChooser(
            controller: c,
            onDark: false,
            onSaved: (int v) {
              hcPop<int>(result: v);
              hcSnack('Saved');
            },
            onCancel: required ? null : () => hcPop<int>(),
          ),
        ),
      ),
    ),
    barrierDismissible: !required,
  ).whenComplete(() => c.onDelete());
}

/// The sign-up step (James, 2026-10-02: a step in sign-up, not only the
/// dialog after launch). Shown once the device is authorised, so the answer
/// can be saved; if the save cannot be made the new member may go on and
/// the question comes back after launch.
class FindabilitySignupPage extends StatelessWidget {
  const FindabilitySignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FindabilityController>(
      init: FindabilityController(),
      global: false,
      dispose: (GetBuilderState<FindabilityController> s) =>
          s.controller?.onDelete(),
      builder: (FindabilityController c) => PopScope(
        canPop: false,
        child: AppScaffold(
          appBar: AppBar(
            backgroundColor: themeAppBarBackground,
            automaticallyImplyLeading: false,
            title: Text('Finding you', style: ts_appBarTitle),
            centerTitle: true,
          ),
          body: DecoratedBox(
            decoration: Backgrounds.defaultHcBackground(),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Obx(() {
                      final bool failed = c.error.value != null;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          FindabilityChooser(
                            controller: c,
                            onDark: true,
                            forNewMember: true,
                            onSaved: (int v) => hcPop<int>(result: v),
                          ),
                          if (failed)
                            TextButton(
                              onPressed: () => hcPop<int>(),
                              child: const Text(
                                'Continue, and ask me later',
                                style: TextStyle(color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
