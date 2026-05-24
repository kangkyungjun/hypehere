import 'package:flutter_test/flutter_test.dart';
import 'package:marketlens/utils/multilingual.dart';

void main() {
  group('localizePacked', () {
    test('plain string without separator returns as-is', () {
      expect(localizePacked('Hello World', 'en'), 'Hello World');
      expect(localizePacked('Hello World', 'ko'), 'Hello World');
    });

    test('packed string returns correct part for each language', () {
      const packed = '한국|||English|||中文|||日本|||Español';

      expect(localizePacked(packed, 'ko'), '한국');
      expect(localizePacked(packed, 'en'), 'English');
      expect(localizePacked(packed, 'zh'), '中文');
      expect(localizePacked(packed, 'ja'), '日本');
      expect(localizePacked(packed, 'es'), 'Español');
    });

    test('missing language falls back to English (index 1)', () {
      const packed = '한국|||English|||中文';

      // 'fr' is not in the language index, so falls back to English
      expect(localizePacked(packed, 'fr'), 'English');
    });

    test('missing language falls back to Korean when English is empty', () {
      const packed = '한국||||||中文';

      // 'fr' is unknown, English (index 1) is empty, falls back to Korean (index 0)
      expect(localizePacked(packed, 'fr'), '한국');
    });

    test('empty target part falls back to English then Korean', () {
      // ko part is present, en is present, ja is empty
      const packed = '한국|||English||||||';

      // ja (index 3) is empty, falls back to English
      expect(localizePacked(packed, 'ja'), 'English');
    });

    test('empty target part with empty English falls back to Korean', () {
      // ko present, en empty, zh empty, ja empty
      // '한국' + '|||' + '' + '|||' + '' + '|||' + ''
      const packed = '한국|||||||||';

      // ja (index 3) is empty, English (index 1) is empty, falls back to Korean
      expect(localizePacked(packed, 'ja'), '한국');
    });

    test('handles two-part packed string (ko and en only)', () {
      const packed = '한국어|||English';

      expect(localizePacked(packed, 'ko'), '한국어');
      expect(localizePacked(packed, 'en'), 'English');
      // zh (index 2) is out of range, falls back to English
      expect(localizePacked(packed, 'zh'), 'English');
    });

    test('whitespace trimming works', () {
      const packed = ' 한국 ||| English ||| 中文 ';

      expect(localizePacked(packed, 'ko'), '한국');
      expect(localizePacked(packed, 'en'), 'English');
      expect(localizePacked(packed, 'zh'), '中文');
    });
  });

  group('localizeList', () {
    test('applies localizePacked to each item', () {
      final items = [
        '아이템1|||Item1',
        '아이템2|||Item2',
        'Plain text',
      ];

      final resultKo = localizeList(items, 'ko');
      expect(resultKo, ['아이템1', '아이템2', 'Plain text']);

      final resultEn = localizeList(items, 'en');
      expect(resultEn, ['Item1', 'Item2', 'Plain text']);
    });

    test('empty list returns empty list', () {
      expect(localizeList([], 'en'), isEmpty);
    });
  });

  group('MultilingualString extension', () {
    test('.localize() works for packed string', () {
      const packed = '한국|||English|||中文';

      expect(packed.localize('ko'), '한국');
      expect(packed.localize('en'), 'English');
      expect(packed.localize('zh'), '中文');
    });

    test('.localize() works for plain string', () {
      const plain = 'Just a plain string';
      expect(plain.localize('en'), 'Just a plain string');
      expect(plain.localize('ko'), 'Just a plain string');
    });
  });
}
