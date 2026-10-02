import 'package:flutter_test/flutter_test.dart';
import 'package:marketlens/utils/limited_analysis.dart';
import 'package:marketlens/utils/multilingual.dart';

/// `limited` 임시 판별 + 다국어 팩 문자열 처리 계약.
///
/// 파이프라인 회신(2026-10-02) 대응.
void main() {
  group('limited 임시 판별 (S1 대기 중)', () {
    test('ko 세그먼트 접두사를 잡는다', () {
      const packed = '[제한 분석] 상장 후 거래 이력 62일로 AI 예측을 제외하고'
          '|||[Limited analysis] Only 62 trading days'
          '|||[限定分析] 上市后62个交易日'
          '|||[限定的な分析] 上場後62営業日'
          '|||[Análisis limitado] Solo 62 días';
      expect(looksLimited(packed), isTrue);
    });

    test('어느 언어 세그먼트로 와도 잡는다', () {
      // 일부 언어만 채워진 과거 행에서도 걸려야 한다.
      expect(looksLimited('[Limited analysis] only 62 days'), isTrue);
      expect(looksLimited('|||[Limited analysis] only 62 days'), isTrue);
      expect(looksLimited('[Análisis limitado] Solo 62 días'), isTrue);
    });

    test('정상 종목은 안 잡는다', () {
      expect(looksLimited('애플은 최근 실적 호조로|||Apple posted strong'), isFalse);
      expect(looksLimited('강력매수 신호'), isFalse);
      expect(looksLimited(''), isFalse);
      expect(looksLimited(null), isFalse);
    });

    test('접두사가 문장 중간에 있으면 안 잡는다', () {
      // 시작 위치만 본다 — 본문에 우연히 들어간 경우를 거른다.
      expect(looksLimited('이 종목은 [제한 분석] 대상이 아닙니다'), isFalse);
    });
  });

  group('팩 문자열 처리 (S5 대응)', () {
    const packed = '한국어|||English|||中文|||日本語|||Español';

    test('언어별로 올바른 세그먼트를 뽑는다', () {
      expect(packed.localize('ko'), '한국어');
      expect(packed.localize('en'), 'English');
      expect(packed.localize('ja'), '日本語');
    });

    test('해당 언어가 비면 en → ko 순으로 대체한다', () {
      // 파이프라인이 요청한 대체 순서와 같다.
      const missingJa = '한국어|||English|||中文||||||Español';
      expect(missingJa.localize('ja'), 'English');

      const koOnly = '한국어';
      expect(koOnly.localize('en'), '한국어');
    });

    test('구분자가 없으면 원문 그대로', () {
      expect('단일 문자열'.localize('en'), '단일 문자열');
    });
  });
}
