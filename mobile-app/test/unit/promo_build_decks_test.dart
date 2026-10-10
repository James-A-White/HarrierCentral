import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';

/// Build promo decks (E9.F4.S5): which builds an upgrade checks for a deck.
void main() {
  group('MainNavigationController.buildsToProbe', () {
    test('every build crossed since the last one seen, oldest first', () {
      expect(MainNavigationController.buildsToProbe(1459, 1463), <int>[1460, 1461, 1462, 1463]);
    });
    test('a phone that never recorded a build checks only its own build', () {
      expect(MainNavigationController.buildsToProbe(null, 1463), <int>[1463]);
    });
    test('no change, a downgrade or no build number checks nothing', () {
      expect(MainNavigationController.buildsToProbe(1463, 1463), isEmpty);
      expect(MainNavigationController.buildsToProbe(1470, 1463), isEmpty);
      expect(MainNavigationController.buildsToProbe(1459, null), isEmpty);
    });
    test('a long gap probes only the last 40 builds', () {
      final List<int> b = MainNavigationController.buildsToProbe(1300, 1463);
      expect(b.length, 40);
      expect(b.first, 1424);
      expect(b.last, 1463);
    });
  });
}
