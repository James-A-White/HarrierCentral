import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';

/// The "Drink chug-a-lug" rule: which attendees earn a down-down and why. It
/// lived inside a widget's build path until 2026-09-23 and had never been
/// tested; it is a pure function of rows now (DrinksListController
/// .awardsFromRows), so it can be.
void main() {
  Map<String, dynamic> row({
    required String id,
    required int runs,
    int haring = 0,
    int isHare = 0,
  }) => <String, dynamic>{
    'hasherId': id,
    'dispName': id,
    'nameForSort': ' $id ',
    'photo': '',
    'totalRunsThisKennel': runs,
    'totalHaringThisKennel': haring,
    'isHare': isHare,
  };

  test('milestone runs earn an award; ordinary counts do not', () {
    final List<DrinksResults> out = DrinksListController.awardsFromRows([
      row(id: 'first', runs: 1),
      row(id: 'fifth', runs: 5),
      row(id: 'seven', runs: 7),
      row(id: 'tenth', runs: 10),
      row(id: 'fifty', runs: 50),
      row(id: 'hundred', runs: 100),
      row(id: 'sixtynine', runs: 169),
      row(id: 'ninetynine', runs: 99),
    ]);
    final Map<String, int> byId = <String, int>{
      for (final DrinksResults a in out) a.hasherId: a.specialRunCount,
    };
    expect(byId['first'], specialRunFirstRun);
    expect(byId['fifth'], specialRunFifthRun);
    expect(byId['tenth'], specialRunTenthRun);
    expect(byId['fifty'], specialRun25);
    expect(byId['hundred'], specialRun100);
    expect(byId['sixtynine'], specialRun69);
    expect(byId['ninetynine'], specialRunPalindrome);
    expect(byId.containsKey('seven'), isFalse, reason: '7 runs is not a milestone');
  });

  test('palindromes count only above ten', () {
    final List<DrinksResults> out = DrinksListController.awardsFromRows([
      row(id: 'p101', runs: 101),
      row(id: 'p111', runs: 111),
      row(id: 'p424', runs: 424),
      row(id: 'p3', runs: 3),
    ]);
    final List<String> ids = out.map((a) => a.hasherId).toList();
    expect(ids, <String>['p101', 'p111', 'p424']);
    expect(out.every((a) => a.specialRunCount == specialRunPalindrome), isTrue);
  });

  test('haring milestones apply only to a hare of THIS run', () {
    final List<DrinksResults> out = DrinksListController.awardsFromRows([
      row(id: 'hareFirst', runs: 3, haring: 1, isHare: 1),
      row(id: 'hareFifth', runs: 3, haring: 5, isHare: 1),
      row(id: 'notHareToday', runs: 3, haring: 1, isHare: 0),
    ]);
    final Map<String, DrinksResults> byId = <String, DrinksResults>{
      for (final DrinksResults a in out) a.hasherId: a,
    };
    expect(byId['hareFirst']?.specialHaringCount, specialRunFirstRun);
    expect(byId['hareFifth']?.specialHaringCount, specialRunFifthRun);
    expect(byId['hareFirst']?.specialRunCount, specialRunNo);
    expect(byId.containsKey('notHareToday'), isFalse,
        reason: 'a haring milestone needs isHare = 1 on this event');
  });

  test('keeps the query order and returns nothing for an empty run', () {
    expect(DrinksListController.awardsFromRows(const []), isEmpty);
    final List<DrinksResults> out = DrinksListController.awardsFromRows([
      row(id: 'b', runs: 25),
      row(id: 'a', runs: 5),
    ]);
    expect(out.map((a) => a.hasherId).toList(), <String>['b', 'a']);
  });
}
