// Baseline tests for the three screens affected by Layer 2 (Facebook removal).
//
// BEFORE Layer 2: all 'expect(find.textContaining('Facebook'), findsWidgets)'
//   assertions should PASS — Facebook text is present.
//
// AFTER Layer 2: update those assertions to 'findsNothing' to confirm removal.
// The golden file comparisons will catch any unintended layout changes.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/pages/init/new_account.dart';
import 'package:harrier_central/pages/init/choose_profile_image.dart';
import 'test_helpers.dart';

void main() {
  setUp(() async {
    await setupTestEnvironment();
  });

  tearDown(() {
    tearDownTestEnvironment();
  });

  // ──────────────────────────────────────────────────────────────────────────
  // NewAccountPage — line 256 mentions "Apple or Facebook"
  // ──────────────────────────────────────────────────────────────────────────

  group('NewAccountPage', () {
    // Source-level check: more reliable than widget rendering for this specific
    // text because the AVIF background image has no native codec in test mode.
    // After Layer 2, "or Facebook" is removed from line 256; update to:
    //   expect(source, isNot(contains('Apple or Facebook')));
    test('BASELINE: source contains "Apple or Facebook" text', () {
      final source = File('lib/pages/init/new_account.dart').readAsStringSync();
      // This exact string lives in the "Use Third Party" button label (line 256).
      expect(source, contains('Apple or Facebook'));
    });

    testWidgets('BASELINE: golden — NewAccountPageContent layout',
        (WidgetTester tester) async {
      // Render the content widget directly (avoids AppScaffold's AVIF background
      // which has no native codec in the headless test environment).
      // NewAccountPageContent contains all visible text including "Apple or Facebook".
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
  // ThirdPartyLogin — Facebook button is already commented out.
  // Verify only the Apple option is visible (no Facebook UI).
  // ──────────────────────────────────────────────────────────────────────────

  group('ThirdPartyLogin', () {
    // ThirdPartyLogin uses AppScaffold (AVIF background) so we use a source
    // check instead of widget rendering.
    // This test verifies the 62-line commented-out _facebookLogin() block
    // is still present (as a comment) before Layer 2 cleans it up.
    // After Layer 2: update to expect the method to be GONE entirely.
    test('BASELINE: source has commented-out _facebookLogin method', () {
      final source =
          File('lib/pages/init/third_party_login.dart').readAsStringSync();
      // The Facebook login method is in a comment block (lines 238-299).
      // After Layer 2 this block is deleted, so this test should then check:
      //   expect(source, isNot(contains('_facebookLogin')));
      expect(source, contains('_facebookLogin'));
    });

    // ThirdPartyLogin renders AppScaffold (AVIF background) which has no native
    // codec in the headless test environment. Source checks cover this screen.
  });

  // ──────────────────────────────────────────────────────────────────────────
  // ChooseProfileImage — has fromFacebook enum value and _facebookProfileUrl.
  // Verify the Facebook image source option is present before Layer 2.
  // ──────────────────────────────────────────────────────────────────────────

  group('ChooseProfileImage', () {
    testWidgets('BASELINE: fromFacebook enum exists in SelectedImageTypeEnum',
        (WidgetTester tester) async {
      // Structural check — the enum value exists at compile time.
      // After Layer 2, SelectedImageTypeEnum.fromFacebook is removed;
      // this test will then fail to compile if the removal is incomplete.
      expect(SelectedImageTypeEnum.fromFacebook, isNotNull);
    });

    // ChooseProfileImage also uses AppScaffold (AVIF background).
    // Use source checks to verify the Facebook-specific fields are removed in Layer 2.
    test('BASELINE: source has facebookProfilePhoto and fromFacebook', () {
      final source =
          File('lib/pages/init/choose_profile_image.dart').readAsStringSync();
      // After Layer 2: both of these should be gone.
      // Update to:
      //   expect(source, isNot(contains('facebookProfilePhoto')));
      //   expect(source, isNot(contains('fromFacebook')));
      expect(source, contains('facebookProfilePhoto'));
      expect(source, contains('fromFacebook'));
    });
  });
}
