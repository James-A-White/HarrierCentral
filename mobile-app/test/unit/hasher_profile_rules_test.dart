import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';

/// The profile page's dirty check and reply matching, pure since 2026-09-23.
void main() {
  final HashersModel loaded = HashersModel.empty().copyWith(
    firstName: 'James',
    lastName: 'White',
    hashName: 'Opee',
    dispPref: 1,
    photo: 'https://x/photo.jpg',
  );

  bool dirty({
    String firstName = 'James',
    String lastName = 'White',
    String hashName = 'Opee',
    String emailField = 'j@x',
    String? storedEmail = 'j@x',
    bool follower = false,
    int pref = 1,
    String photo = 'https://x/photo.jpg',
    String runs = '0',
    String hared = '0',
    int? histRuns,
    int? histHared,
    bool? estimateWidget = false,
    bool? estimate,
  }) => HasherProfileController.computeDirty(
    hasher: loaded,
    firstName: firstName,
    lastName: lastName,
    hashName: hashName,
    emailField: emailField,
    storedEmail: storedEmail,
    addAsKennelFollower: follower,
    nameDisplayPreference: pref,
    newPhoto: photo,
    previousRunCountText: runs,
    previousHaringCountText: hared,
    historicalTotalRunCount: histRuns,
    historicalHaringCount: histHared,
    estimateWidget: estimateWidget,
    estimate: estimate,
  );

  test('unchanged form is clean', () {
    expect(dirty(), isFalse);
  });

  test('each field marks the form dirty', () {
    expect(dirty(firstName: 'Jim'), isTrue);
    expect(dirty(hashName: 'Kilty'), isTrue);
    expect(dirty(pref: 2), isTrue);
    expect(dirty(photo: 'https://x/other.jpg'), isTrue);
    expect(dirty(runs: '12'), isTrue);
    expect(dirty(histRuns: 12, runs: '12'), isFalse);
    expect(dirty(estimateWidget: true), isTrue);
  });

  test('the e-mail only counts when adding as a kennel follower', () {
    expect(dirty(emailField: 'other@x'), isFalse);
    expect(dirty(emailField: 'other@x', follower: true), isTrue);
    expect(
      dirty(emailField: 'other@x', follower: true, storedEmail: null),
      isFalse,
    );
  });

  test('findSavedHasher matches on first name and hash name, any case', () {
    final reply = <dynamic>[
      <dynamic>[
        <String, dynamic>{'success': 1},
      ],
      <dynamic>[
        HashersModel.empty()
            .copyWith(hasherId: 'a', firstName: 'JAMES', hashName: 'opee')
            .toJson(),
      ],
    ];
    final HashersModel? h = HasherProfileController.findSavedHasher(
      reply,
      firstName: 'James',
      hashName: 'Opee',
    );
    expect(h?.hasherId, 'a');
    expect(
      HasherProfileController.findSavedHasher(
        reply,
        firstName: 'Bob',
        hashName: 'Opee',
      ),
      isNull,
    );
  });
}
