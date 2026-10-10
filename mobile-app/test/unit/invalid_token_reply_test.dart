import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';

/// The clock-correcting retry (E1.F1.S7) only runs when the reply is
/// recognised as an invalid token. These are the bodies the API really sends
/// (AppApiHC6 strips errorTitle), captured 2026-10-10.
void main() {
  group('ServiceCommon.isInvalidTokenReply', () {
    test('ValidateAppAuth refusal, as the shim returns it', () {
      expect(
        ServiceCommon.isInvalidTokenReply(
          '{"errorType":1,"errorUserMessage":"The access token is invalid. Please check that the clock on your phone is set automatically from Apple or Google.","errorId":"x"}',
        ),
        isTrue,
      );
    });

    test('approveLogin refusal (errorType 11)', () {
      expect(
        ServiceCommon.isInvalidTokenReply(
          '{"errorType":11,"errorUserMessage":"A security check has been activated. Please restart the app.","errorId":"x"}',
        ),
        isTrue,
      );
    });

    test('the old shape with errorTitle still counts', () {
      expect(
        ServiceCommon.isInvalidTokenReply('[[{"errorTitle":"Invalid access token"}]]'),
        isTrue,
      );
    });

    test('other refusals do not', () {
      expect(
        ServiceCommon.isInvalidTokenReply(
          '{"errorType":3,"errorUserMessage":"The device making this request is not registered. Please re-authorise the app.","errorId":"x"}',
        ),
        isFalse,
      );
      expect(
        ServiceCommon.isInvalidTokenReply(
          '{"errorType":13,"errorUserMessage":"The invite code provided was not found in the Harrier Central system.","errorId":"x"}',
        ),
        isFalse,
      );
    });
  });
}
