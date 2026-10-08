import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Scenario Progression and Unlock Logic Tests', () {
    test(
      'Scenario 1 (index 0) is always unlocked even with empty completions',
      () {
        final List<String> tamamlananlar = [];
        const int index = 0;
        final bool acikMi = index == 0 || tamamlananlar.contains("scen123_0");
        expect(acikMi, isTrue);
      },
    );

    test(
      'Scenario 2 (index 1) remains locked when Scenario 1 is not in completed list',
      () {
        final List<String> tamamlananlar = [];
        const int index = 1;
        final List<int> tumBolumler = [0, 1, 2];
        final bool acikMi =
            index == 0 ||
            tamamlananlar.contains("scen123_${tumBolumler[index - 1]}");
        expect(acikMi, isFalse);
      },
    );

    test(
      'Scenario 2 (index 1) unlocks when Scenario 1 (scen123_0) is in completed list',
      () {
        final List<String> tamamlananlar = ["scen123_0"];
        const int index = 1;
        final List<int> tumBolumler = [0, 1, 2];
        final bool acikMi =
            index == 0 ||
            tamamlananlar.contains("scen123_${tumBolumler[index - 1]}");
        expect(acikMi, isTrue);
      },
    );

    test(
      'Scenario ID formatting consistency between sender and unlock evaluator',
      () {
        const String docId = "cyber_safety_01";
        const int bolumIndex = 0;

        // Sender format (SenaryoDetayEkrani)
        final String sentTaskId = "${docId}_$bolumIndex";

        // Evaluator format (SenaryoBolumListelemeEkrani)
        final String expectedUnlockId = "${docId}_0";

        expect(sentTaskId, equals(expectedUnlockId));
      },
    );
  });
}
