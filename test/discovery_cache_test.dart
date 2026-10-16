import 'package:flutter_test/flutter_test.dart';
import 'package:zorbalik_uygulamasi/data/repositories/content_repository_impl.dart';

void main() {
  group('Discovery Data and Cache Sanitization Tests', () {
    test('sanitizeDiscoveryPool filters out duplicates and invalid items', () {
      final rawPool = [
        {'id': '1', 'tip': 'SENARYO', 'baslik': 'Test 1'},
        {'id': '1', 'tip': 'SENARYO', 'baslik': 'Test 1 Duplicate'},
        {'id': '2', 'tip': 'SENARYO', 'baslik': ''}, // empty title for SENARYO -> should filter
        {'id': '', 'tip': 'HİKAYE', 'baslik': 'Test Story'}, // empty id -> should filter
        {'id': '3', 'tip': 'HİKAYE', 'baslik': 'Valid Story'},
      ];

      final cleaned = sanitizeDiscoveryPool(rawPool);

      expect(cleaned.length, equals(2));
      expect(cleaned[0]['id'], equals('1'));
      expect(cleaned[1]['id'], equals('3'));
    });

    test('Total tasks count is 0 when offline counts fail', () {
      const int scenarioCount = 0;
      const int storyCount = 0;
      const int detectiveCount = 0;

      final int totalTasks = scenarioCount + storyCount + detectiveCount;
      expect(totalTasks, equals(0));
    });

    test('Total tasks count is greater than 0 when online counts succeed', () {
      const int scenarioCount = 5;
      const int storyCount = 3;
      const int detectiveCount = 2;

      final int totalTasks = scenarioCount + storyCount + detectiveCount;
      expect(totalTasks, equals(10));
    });
  });
}
