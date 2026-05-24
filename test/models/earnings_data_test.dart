import 'package:flutter_test/flutter_test.dart';
import 'package:marketlens/models/earnings_data.dart';
import 'package:marketlens/theme/app_colors.dart';

/// 실적 데이터 모델 파싱 테스트
///
/// 테스트 철학:
/// - API→Model 파싱 정확성 검증
/// - Null/기본값 처리 검증
/// - getter 로직 검증 (displayName, surpriseLabel, surpriseColor)
/// - 로컬라이제이션 분기 검증 (displayNameLocalized)
void main() {
  group('EarningsWeekEvent Parsing Tests', () {
    test('fromJson: 모든 필드 정상 파싱', () {
      // Given: 완전한 실적 이벤트 JSON
      final json = {
        'ticker': 'AAPL',
        'earnings_date': '2026-04-24',
        'name_en': 'Apple Inc.',
        'name_ko': '애플',
        'prev_surprise_pct': 4.5,
        'score': 82.3,
        'eps_estimate_avg': 1.65,
        'earnings_confirmed': true,
        'd_day': -3,
      };

      // When: JSON -> Model 파싱
      final event = EarningsWeekEvent.fromJson(json);

      // Then: 모든 필드가 올바르게 파싱됨
      expect(event.ticker, 'AAPL');
      expect(event.earningsDate, '2026-04-24');
      expect(event.nameEn, 'Apple Inc.');
      expect(event.nameKo, '애플');
      expect(event.prevSurprisePct, 4.5);
      expect(event.score, 82.3);
      expect(event.epsEstimateAvg, 1.65);
      expect(event.earningsConfirmed, true);
      expect(event.dDay, -3);
    });

    test('fromJson: earningsConfirmed 기본값 false', () {
      // Given: earnings_confirmed 필드가 없는 JSON
      final json = {
        'ticker': 'MSFT',
        'earnings_date': '2026-04-22',
      };

      // When: JSON -> Model 파싱
      final event = EarningsWeekEvent.fromJson(json);

      // Then: earningsConfirmed이 기본값 false
      expect(event.earningsConfirmed, false);
    });

    test('fromJson: nullable 필드가 null', () {
      // Given: 선택적 필드가 없는 최소 JSON
      final json = {
        'ticker': 'TSLA',
        'earnings_date': '2026-04-23',
      };

      // When: JSON -> Model 파싱
      final event = EarningsWeekEvent.fromJson(json);

      // Then: nullable 필드가 null
      expect(event.nameEn, isNull);
      expect(event.nameKo, isNull);
      expect(event.prevSurprisePct, isNull);
      expect(event.score, isNull);
      expect(event.epsEstimateAvg, isNull);
      expect(event.dDay, isNull);
    });

    test('fromJson: num 타입 -> double 변환', () {
      // Given: int로 넘어오는 num 값
      final json = {
        'ticker': 'GOOG',
        'earnings_date': '2026-04-25',
        'prev_surprise_pct': 3,
        'score': 75,
        'eps_estimate_avg': 2,
      };

      // When: JSON -> Model 파싱
      final event = EarningsWeekEvent.fromJson(json);

      // Then: double로 올바르게 변환됨
      expect(event.prevSurprisePct, 3.0);
      expect(event.score, 75.0);
      expect(event.epsEstimateAvg, 2.0);
    });
  });

  group('EarningsWeekEvent.displayName Tests', () {
    test('nameKo가 있으면 nameKo 우선', () {
      // Given: nameKo와 nameEn 모두 있는 이벤트
      final event = EarningsWeekEvent(
        ticker: 'AAPL',
        earningsDate: '2026-04-24',
        nameEn: 'Apple Inc.',
        nameKo: '애플',
      );

      // Then: nameKo 반환
      expect(event.displayName, '애플');
    });

    test('nameKo가 null이면 nameEn 사용', () {
      // Given: nameKo가 null인 이벤트
      final event = EarningsWeekEvent(
        ticker: 'AAPL',
        earningsDate: '2026-04-24',
        nameEn: 'Apple Inc.',
      );

      // Then: nameEn 반환
      expect(event.displayName, 'Apple Inc.');
    });

    test('nameKo와 nameEn 모두 null이면 ticker 사용', () {
      // Given: 이름이 모두 null인 이벤트
      final event = EarningsWeekEvent(
        ticker: 'AAPL',
        earningsDate: '2026-04-24',
      );

      // Then: ticker 반환
      expect(event.displayName, 'AAPL');
    });
  });

  group('EarningsWeekEvent.displayNameLocalized Tests', () {
    test('ko: nameKo 우선', () {
      final event = EarningsWeekEvent(
        ticker: 'AAPL',
        earningsDate: '2026-04-24',
        nameEn: 'Apple Inc.',
        nameKo: '애플',
      );

      expect(event.displayNameLocalized('ko'), '애플');
    });

    test('ko: nameKo가 null이면 nameEn 사용', () {
      final event = EarningsWeekEvent(
        ticker: 'AAPL',
        earningsDate: '2026-04-24',
        nameEn: 'Apple Inc.',
      );

      expect(event.displayNameLocalized('ko'), 'Apple Inc.');
    });

    test('ko: 둘 다 null이면 ticker 사용', () {
      final event = EarningsWeekEvent(
        ticker: 'AAPL',
        earningsDate: '2026-04-24',
      );

      expect(event.displayNameLocalized('ko'), 'AAPL');
    });

    test('en: nameEn 우선', () {
      final event = EarningsWeekEvent(
        ticker: 'AAPL',
        earningsDate: '2026-04-24',
        nameEn: 'Apple Inc.',
        nameKo: '애플',
      );

      expect(event.displayNameLocalized('en'), 'Apple Inc.');
    });

    test('en: nameEn이 null이면 ticker 사용', () {
      final event = EarningsWeekEvent(
        ticker: 'AAPL',
        earningsDate: '2026-04-24',
        nameKo: '애플',
      );

      // en 모드에서는 nameKo를 사용하지 않고 ticker로 폴백
      expect(event.displayNameLocalized('en'), 'AAPL');
    });
  });

  group('EarningsWeekEvent.surpriseLabel Tests', () {
    test('양수: ▲4.5%', () {
      final event = EarningsWeekEvent(
        ticker: 'AAPL',
        earningsDate: '2026-04-24',
        prevSurprisePct: 4.5,
      );

      expect(event.surpriseLabel, '▲4.5%');
    });

    test('음수: ▼2.6%', () {
      final event = EarningsWeekEvent(
        ticker: 'AAPL',
        earningsDate: '2026-04-24',
        prevSurprisePct: -2.6,
      );

      expect(event.surpriseLabel, '▼2.6%');
    });

    test('null: dash 반환', () {
      final event = EarningsWeekEvent(
        ticker: 'AAPL',
        earningsDate: '2026-04-24',
      );

      expect(event.surpriseLabel, '–');
    });

    test('0: ▲0.0%', () {
      final event = EarningsWeekEvent(
        ticker: 'AAPL',
        earningsDate: '2026-04-24',
        prevSurprisePct: 0.0,
      );

      expect(event.surpriseLabel, '▲0.0%');
    });

    test('소수점 첫째 자리까지 표시', () {
      final event = EarningsWeekEvent(
        ticker: 'AAPL',
        earningsDate: '2026-04-24',
        prevSurprisePct: 12.345,
      );

      expect(event.surpriseLabel, '▲12.3%');
    });
  });

  group('EarningsWeekEvent.surpriseColor Tests', () {
    test('양수 -> gainColor', () {
      final event = EarningsWeekEvent(
        ticker: 'AAPL',
        earningsDate: '2026-04-24',
        prevSurprisePct: 4.5,
      );

      expect(event.surpriseColor, MarketLensColors.light.gainColor);
    });

    test('음수 -> lossColor', () {
      final event = EarningsWeekEvent(
        ticker: 'AAPL',
        earningsDate: '2026-04-24',
        prevSurprisePct: -2.6,
      );

      expect(event.surpriseColor, MarketLensColors.light.lossColor);
    });

    test('null -> neutralColor', () {
      final event = EarningsWeekEvent(
        ticker: 'AAPL',
        earningsDate: '2026-04-24',
      );

      expect(event.surpriseColor, MarketLensColors.light.neutralColor);
    });

    test('0 -> gainColor (>= 0 조건)', () {
      final event = EarningsWeekEvent(
        ticker: 'AAPL',
        earningsDate: '2026-04-24',
        prevSurprisePct: 0.0,
      );

      expect(event.surpriseColor, MarketLensColors.light.gainColor);
    });
  });

  group('EarningsUpcomingData Parsing Tests', () {
    test('fromJson: 모든 필드 정상 파싱', () {
      // Given: 완전한 실적 예정 JSON
      final json = {
        'week_start': '2026-04-20',
        'week_end': '2026-04-26',
        'total_count': 3,
        'by_date': {
          '2026-04-22': [
            {
              'ticker': 'MSFT',
              'earnings_date': '2026-04-22',
              'name_en': 'Microsoft Corporation',
              'name_ko': '마이크로소프트',
              'earnings_confirmed': true,
            },
          ],
          '2026-04-24': [
            {
              'ticker': 'AAPL',
              'earnings_date': '2026-04-24',
              'name_en': 'Apple Inc.',
              'name_ko': '애플',
            },
            {
              'ticker': 'META',
              'earnings_date': '2026-04-24',
              'name_en': 'Meta Platforms',
              'name_ko': '메타',
            },
          ],
        },
      };

      // When: JSON -> Model 파싱
      final data = EarningsUpcomingData.fromJson(json);

      // Then: 모든 필드가 올바르게 파싱됨
      expect(data.weekStart, '2026-04-20');
      expect(data.weekEnd, '2026-04-26');
      expect(data.totalCount, 3);
      expect(data.byDate.length, 2);
      expect(data.byDate['2026-04-22']!.length, 1);
      expect(data.byDate['2026-04-22']![0].ticker, 'MSFT');
      expect(data.byDate['2026-04-22']![0].earningsConfirmed, true);
      expect(data.byDate['2026-04-24']!.length, 2);
      expect(data.byDate['2026-04-24']![0].ticker, 'AAPL');
      expect(data.byDate['2026-04-24']![1].ticker, 'META');
    });

    test('fromJson: 빈 byDate', () {
      // Given: by_date가 빈 맵인 JSON
      final json = {
        'week_start': '2026-04-20',
        'week_end': '2026-04-26',
        'total_count': 0,
        'by_date': <String, dynamic>{},
      };

      // When: JSON -> Model 파싱
      final data = EarningsUpcomingData.fromJson(json);

      // Then: 빈 맵과 0 total
      expect(data.byDate, isEmpty);
      expect(data.totalCount, 0);
    });

    test('fromJson: by_date가 null일 때 빈 맵', () {
      // Given: by_date가 null인 JSON
      final json = <String, dynamic>{
        'week_start': '2026-04-20',
        'week_end': '2026-04-26',
        'total_count': 0,
        'by_date': null,
      };

      // When: JSON -> Model 파싱
      final data = EarningsUpcomingData.fromJson(json);

      // Then: 빈 맵 반환
      expect(data.byDate, isEmpty);
    });

    test('fromJson: total_count null -> 0', () {
      // Given: total_count가 null인 JSON
      final json = <String, dynamic>{
        'week_start': '2026-04-20',
        'week_end': '2026-04-26',
        'total_count': null,
        'by_date': <String, dynamic>{},
      };

      // When: JSON -> Model 파싱
      final data = EarningsUpcomingData.fromJson(json);

      // Then: totalCount가 0
      expect(data.totalCount, 0);
    });
  });
}
