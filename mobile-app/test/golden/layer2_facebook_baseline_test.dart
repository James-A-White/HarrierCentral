// Layer 2 Facebook removal — post-removal verification tests.
// These tests confirm that all Facebook UI/auth references have been removed.
// Screens tested: NewAccountPage, ThirdPartyLogin, ChooseProfileImage.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/pages/init/new_account.dart';
import 'test_helpers.dart';

void main() {
  setUp(() async {
    await setupTestEnvironment();
  });

  tearDown(() {
    tearDownTestEnvironment();
  });

  // ──────────────────────────────────────────────────────────────────────────
  // NewAccountPage — "Apple or Facebook" text was removed from the description
  // ──────────────────────────────────────────────────────────────────────────

  group('NewAccountPage', () {
    test('Layer 2: source no longer contains "Apple or Facebook"', () {
      final source = File('lib/pages/init/new_account.dart').readAsStringSync();
      expect(source, isNot(contains('Apple or Facebook')));
    });

    testWidgets('Layer 2: golden — NewAccountPageContent layout (no Facebook)',
        (WidgetTester tester) async {
      setPhoneSize(tester);
      await tester.pumpWidget(
        TestApp(
          child: const Scaffold(body: NewAccountPageContent()),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      await expectLater(
        find.byType(NewAccountPageContent),
        matchesGoldenFile('goldens/new_account_content.png'),
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // ThirdPartyLogin — _facebookLogin method and block were already removed
  // ──────────────────────────────────────────────────────────────────────────

  group('ThirdPartyLogin', () {
    test('Layer 2: source does not contain _facebookLogin method', () {
      final source =
          File('lib/pages/init/third_party_login.dart').readAsStringSync();
      expect(source, isNot(contains('_facebookLogin')));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // ChooseProfileImage — fromFacebook enum and facebookProfilePhoto already removed
  // ──────────────────────────────────────────────────────────────────────────

  group('ChooseProfileImage', () {
    test('Layer 2: facebookProfilePhoto pref key removed from enums', () {
      final source =
          File('lib/util/enums.dart').readAsStringSync();
      expect(source, isNot(contains('facebookProfilePhoto')));
    });

    test('Layer 2: ThirdPartyLoginType no longer has facebook value', () {
      final source = File('lib/util/enums.dart').readAsStringSync();
      expect(source, isNot(contains('ThirdPartyLoginType { apple, facebook')));
    });

    test('Layer 2: choose_profile_image.dart has no fromFacebook enum value', () {
      final source =
          File('lib/pages/init/choose_profile_image.dart').readAsStringSync();
      expect(source, isNot(contains('fromFacebook')));
    });
  });
}
