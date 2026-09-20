import 'package:intl/intl.dart';
import 'package:harrier_central/imports.dart';

/// The passkeys that can sign this hasher in, with a Remove on each
/// (E9.F7.S18).
///
/// A section rather than a page, and a widget rather than code inside one:
/// it started on Settings and moved to My Account (James, 2026-09-20,
/// "the only things left in My Account are account related"), and a passkey
/// is plainly an account thing. Keeping it self-contained meant that move
/// was one line in each file rather than a transplant.
class PasskeysController extends GetxController {
  /// null from the service means the call FAILED. An empty list is the
  /// ordinary answer for the many hashers who have never made a passkey, and
  /// must not be drawn as an error — nor a failure drawn as "you have none".
  final RxList<AccountPasskey> passkeys = <AccountPasskey>[].obs;
  final RxBool loading = true.obs;
  final RxBool failed = false.obs;

  /// The row whose Remove-passkey or Sign-out has been tapped once. Both
  /// ask twice: they are the controls here that take access away.
  final RxString confirmingId = ''.obs;
  final RxString confirmingSignOutId = ''.obs;
  final RxString deletingId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    loading.value = true;
    final List<AccountPasskey>? keys =
        await PasskeyManageService.fetchDevices();
    if (isClosed) return;
    failed.value = keys == null;
    passkeys.value = keys ?? <AccountPasskey>[];
    loading.value = false;
  }

  /// Revokes one passkey. The SP hands back what remains, so the list is
  /// replaced from the reply rather than re-fetched — and a failure leaves
  /// the screen exactly as it was.
  Future<void> remove(AccountPasskey key) async {
    if (deletingId.value.isNotEmpty) return;
    deletingId.value = key.deviceId;
    final List<AccountPasskey>? remaining =
        await PasskeyManageService.deletePasskey(key.deviceId);
    if (isClosed) return;
    deletingId.value = '';
    confirmingId.value = '';
    if (remaining == null) {
      Get.snackbar(
        'Not removed',
        'That passkey could not be removed. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    passkeys.value = remaining;
  }

  /// Signs one device out. The server rotates its secret — which is what
  /// actually revokes it — drops its push tokens so it stops buzzing, and
  /// returns the list without it (unless it still holds a passkey).
  Future<void> signOut(AccountPasskey device) async {
    if (deletingId.value.isNotEmpty) return;
    deletingId.value = device.deviceId;
    final List<AccountPasskey>? remaining =
        await PasskeyManageService.signOutDevice(device.deviceId);
    if (isClosed) return;
    deletingId.value = '';
    confirmingSignOutId.value = '';
    if (remaining == null) {
      Get.snackbar(
        'Not signed out',
        'That device could not be signed out. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    passkeys.value = remaining;
  }
}

class PasskeysSection extends StatelessWidget {
  PasskeysSection({super.key});

  final PasskeysController controller = Get.put(PasskeysController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.loading.value) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const FancyDivider(
            key: Key('account_passkeys_divider'),
            innerColor: Colors.white,
            topMargin: 20.0,
            bottomMargin: 10.0,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Passkeys',
              style: ts_headingLarge,
              textAlign: TextAlign.center,
            ),
          ),
          if (controller.failed.value) ...<Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Your devices could not be loaded. A connection is required '
                'to change these settings.',
                style: ts_body,
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: Text('Try again', style: ts_button),
                onPressed: () => unawaited(controller.load()),
              ),
            ),
          ] else if (controller.passkeys.isEmpty) ...<Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
              child: Text(
                'Nothing is signed in to your account but this device.',
                style: ts_body,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
          ] else ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
              child: Text(
                'Everything that can reach your account. Sign out anything '
                'you no longer have, and remove any passkey you do not '
                'recognise.',
                style: ts_body,
                textAlign: TextAlign.center,
              ),
            ),
            for (final AccountPasskey key in controller.passkeys)
              _row(controller, key),
            Padding(
              padding: const EdgeInsets.only(
                left: 8,
                right: 8,
                top: 4,
                bottom: 12,
              ),
              child: Text(
                'Signing a device out takes its access away at once and stops '
                'its notifications. Removing a passkey stops that one-tap '
                'sign-in — the passkey itself stays in the device\'s own '
                'password manager until you delete it there too.',
                style: ts_bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      );
    });
  }

  /// One passkey: what it is, when it last signed in, and a two-tap Remove.
  Widget _row(PasskeysController controller, AccountPasskey key) {
    final bool confirming = controller.confirmingId.value == key.deviceId;
    final bool confirmingSignOut =
        controller.confirmingSignOutId.value == key.deviceId;
    final bool busy = controller.deletingId.value == key.deviceId;

    return Card(
      color: Colors.black.withValues(alpha: 0.28),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  key.isMobile ? Icons.smartphone : Icons.computer,
                  color: Colors.white70,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        key.isThisDevice
                            ? '${key.label} (this device)'
                            : key.label,
                        style: ts_titleMedium,
                      ),
                      Text(
                        <String>[
                          // Version first: with a dozen old installs listed,
                          // it is what tells them apart (James, 2026-09-20).
                          key.versionLabel,
                          if (key.lastLogin == null)
                            'not used yet'
                          else
                            DateFormat(
                              'd MMM yyyy, HH:mm',
                            ).format(key.lastLogin!.toLocal()),
                          if (key.hasPasskey) 'passkey',
                          if (key.isSignedOut) 'signed out',
                        ].join(' · '),
                        style: ts_bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Wrap, not Row: at a large text size these are wider than a
            // phone and a Row overflows.
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: confirming
                  ? <Widget>[
                      ElevatedButton(
                        onPressed: busy
                            ? null
                            : () => unawaited(controller.remove(key)),
                        child: busy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text('Remove passkey', style: ts_button),
                      ),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => controller.confirmingId.value = '',
                        child: Text('Keep', style: ts_button),
                      ),
                    ]
                  : confirmingSignOut
                  ? <Widget>[
                      ElevatedButton(
                        onPressed: busy
                            ? null
                            : () => unawaited(controller.signOut(key)),
                        child: busy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text('Sign it out', style: ts_button),
                      ),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => controller.confirmingSignOutId.value = '',
                        child: Text('Leave it', style: ts_button),
                      ),
                    ]
                  : <Widget>[
                      if (key.hasPasskey)
                        TextButton(
                          onPressed: () =>
                              controller.confirmingId.value = key.deviceId,
                          child: Text('Remove passkey', style: ts_button),
                        ),
                      // Already-signed-out rows are only still here because
                      // they hold a passkey, so they get no second sign-out.
                      if (!key.isSignedOut)
                        TextButton(
                          onPressed: () =>
                              controller.confirmingSignOutId.value =
                                  key.deviceId,
                          child: Text('Sign out', style: ts_button),
                        ),
                    ],
            ),
            if (confirming)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  key.isThisDevice
                      ? 'This will not sign you out — you will just need a code next time.'
                      : 'That device will need an email code to sign in again.',
                  style: ts_bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            if (confirmingSignOut)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  key.isThisDevice
                      ? 'This is the device you are using. It will be signed out and you will have to sign in again.'
                      : 'That device loses access at once and stops receiving your notifications.',
                  style: ts_bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
