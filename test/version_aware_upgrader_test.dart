// Unit tests for the version-aware update-prompt cooldown decision.
//
// Covers both reported bugs:
//   - false negative: a NEW store version must prompt immediately even within
//     the time cooldown of a previous prompt.
//   - over-nag: the SAME version must stay suppressed for the cooldown window,
//     regardless of how the previous dialog was dismissed.

import 'package:flutter_test/flutter_test.dart';
import 'package:marketlens/widgets/version_aware_upgrader.dart';

void main() {
  const cooldown = Duration(days: 3);
  final now = DateTime(2026, 7, 10, 12, 0);

  bool tooSoon({
    required String store,
    String? prompted,
    DateTime? at,
  }) =>
      VersionAwareUpgrader.isTooSoonForVersion(
        storeVersion: store,
        promptedVersion: prompted,
        promptedAt: at,
        cooldown: cooldown,
        now: now,
      );

  test('never prompted before → show (not too soon)', () {
    expect(tooSoon(store: '1.3.13', prompted: null, at: null), isFalse);
  });

  test('NEW store version within cooldown → show immediately (fixes false negative)', () {
    // Prompted for 1.3.12 just 1 hour ago, but 1.3.13 is now out.
    expect(
      tooSoon(
        store: '1.3.13',
        prompted: '1.3.12',
        at: now.subtract(const Duration(hours: 1)),
      ),
      isFalse,
    );
  });

  test('SAME version within cooldown → suppress (fixes over-nag)', () {
    expect(
      tooSoon(
        store: '1.3.12',
        prompted: '1.3.12',
        at: now.subtract(const Duration(hours: 1)),
      ),
      isTrue,
    );
  });

  test('SAME version after cooldown elapsed → show again', () {
    expect(
      tooSoon(
        store: '1.3.12',
        prompted: '1.3.12',
        at: now.subtract(const Duration(days: 3, hours: 1)),
      ),
      isFalse,
    );
  });

  test('SAME version exactly at cooldown boundary → show (>= cooldown)', () {
    expect(
      tooSoon(
        store: '1.3.12',
        prompted: '1.3.12',
        at: now.subtract(cooldown),
      ),
      isFalse,
    );
  });

  test('same version but no timestamp recorded → show', () {
    expect(tooSoon(store: '1.3.12', prompted: '1.3.12', at: null), isFalse);
  });
}
