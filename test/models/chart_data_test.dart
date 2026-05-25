import 'package:flutter_test/flutter_test.dart';
import 'package:marketlens/models/chart_data.dart';

/// 차트 데이터 파싱 테스트 (최소한의 "깨지지 않는 것" 중심)
///
/// 테스트 철학:
/// - 커버리지 목표 없음
/// - Ticker Detail 화면 핵심 기능만 검증
/// - API→Model 파싱, Null/Empty 처리, 차트 크래시 방지
void main() {
  group('ChartDataPoint Parsing Tests', () {
    test('정상 데이터 파싱 - 모든 필드 있음', () {
      // Given: 완전한 차트 데이터
      final json = {
        'date': '2026-02-06',
        'open': 150.25,
        'high': 152.80,
        'low': 149.50,
        'close': 151.00,
        'volume': 85000000,
        'score': 75.5,
        'signal': 'BUY',
        'target_price': 160.0,
        'stop_loss': 145.0,
        'rsi': 65.5,
        'macd': 1.25,
        'macd_signal': 0.85,
        'macd_hist': 0.40,
        'bb_width': 5.2,
        'bb_upper': 155.0,
        'bb_lower': 148.0,
        'bb_middle': 151.5,
        'inst_ownership': 58.3,
        'foreign_ownership': 12.5,
        'inst_chg_1d': 0.2,
        'inst_chg_5d': 1.5,
        'foreign_chg_1d': -0.1,
        'foreign_chg_5d': 0.8,
        'short_ratio': 2.5,
        'short_percent_float': 3.2,
      };

      // When: JSON → Model 파싱
      final dataPoint = ChartDataPoint.fromJson(json);

      // Then: 모든 필드가 올바르게 파싱됨
      expect(dataPoint.date, DateTime(2026, 2, 6));
      expect(dataPoint.close, 151.0);
      expect(dataPoint.rsi, 65.5);
      expect(dataPoint.macd, 1.25);
      expect(dataPoint.signal, 'BUY');
    });

    test('Null 값 처리 - nullable 필드가 null', () {
      // Given: RSI와 MACD가 null인 데이터
      final json = {
        'date': '2026-02-06',
        'close': 151.0,
        'rsi': null,
        'macd': null,
        'macd_signal': null,
        'macd_hist': null,
      };

      // When: JSON → Model 파싱
      final dataPoint = ChartDataPoint.fromJson(json);

      // Then: Null 값이 올바르게 처리됨
      expect(dataPoint.close, 151.0);
      expect(dataPoint.rsi, isNull);
      expect(dataPoint.macd, isNull);
      expect(dataPoint.macdSignal, isNull);
      expect(dataPoint.macdHist, isNull);
    });

    test('최소 필드만 있는 데이터 - date만 필수', () {
      // Given: date만 있는 최소 데이터
      final json = {
        'date': '2026-02-06',
      };

      // When: JSON → Model 파싱
      final dataPoint = ChartDataPoint.fromJson(json);

      // Then: date는 파싱되고 나머지는 null
      expect(dataPoint.date, DateTime(2026, 2, 6));
      expect(dataPoint.close, isNull);
      expect(dataPoint.rsi, isNull);
      expect(dataPoint.macd, isNull);
    });

    test('가격 변화율 계산 - open/close 있을 때', () {
      // Given: open과 close가 있는 데이터
      final dataPoint = ChartDataPoint(
        date: DateTime(2026, 2, 6),
        open: 100.0,
        close: 105.0,
      );

      // When: 가격 변화율 계산
      final changePercent = dataPoint.priceChangePercent;

      // Then: 5% 상승
      expect(changePercent, 5.0);
    });

    test('가격 변화율 계산 - open이 null일 때', () {
      // Given: open이 null인 데이터
      final dataPoint = ChartDataPoint(
        date: DateTime(2026, 2, 6),
        close: 105.0,
      );

      // When: 가격 변화율 계산
      final changePercent = dataPoint.priceChangePercent;

      // Then: null 반환
      expect(changePercent, isNull);
    });

    test('Signal Type 변환 - BUY/SELL/HOLD', () {
      // Given: 다양한 signal 값
      final buyData = ChartDataPoint(
        date: DateTime.now(),
        signal: 'BUY',
      );
      final sellData = ChartDataPoint(
        date: DateTime.now(),
        signal: 'SELL',
      );
      final holdData = ChartDataPoint(
        date: DateTime.now(),
        signal: 'HOLD',
      );
      final nullData = ChartDataPoint(
        date: DateTime.now(),
        signal: null,
      );

      // Then: SignalType enum으로 올바르게 변환
      expect(buyData.signalType, SignalType.buy);
      expect(sellData.signalType, SignalType.sell);
      expect(holdData.signalType, SignalType.hold);
      expect(nullData.signalType, SignalType.neutral);
    });
  });

  group('CompleteChartData Parsing Tests', () {
    test('정상 데이터 파싱 - 추세선 계수 포함', () {
      // Given: 완전한 차트 응답 데이터
      final json = {
        'ticker': 'AAPL',
        'data': [
          {
            'date': '2026-02-05',
            'close': 150.0,
            'rsi': 60.0,
          },
          {
            'date': '2026-02-06',
            'close': 151.0,
            'rsi': 65.5,
          },
        ],
        'high_slope': 0.25,
        'high_intercept': 148.5,
        'high_r_squared': 0.85,
        'low_slope': 0.18,
        'low_intercept': 145.0,
        'low_r_squared': 0.82,
      };

      // When: JSON → Model 파싱
      final chartData = CompleteChartData.fromJson(json);

      // Then: 모든 필드가 올바르게 파싱됨
      expect(chartData.ticker, 'AAPL');
      expect(chartData.data.length, 2);
      expect(chartData.highSlope, 0.25);
      expect(chartData.highIntercept, 148.5);
      expect(chartData.lowSlope, 0.18);
    });

    test('추세선 계산 - y = mx + b 공식', () {
      // Given: 추세선 계수가 있는 차트 데이터
      final chartData = CompleteChartData(
        ticker: 'AAPL',
        data: [],
        highSlope: 0.5,
        highIntercept: 100.0,
        lowSlope: 0.3,
        lowIntercept: 95.0,
      );

      // When: 추세선 값 계산
      final highAt10 = chartData.calculateHighTrendline(10);
      final lowAt10 = chartData.calculateLowTrendline(10);

      // Then: y = mx + b 공식으로 계산됨
      expect(highAt10, 105.0); // 0.5 * 10 + 100
      expect(lowAt10, 98.0); // 0.3 * 10 + 95
    });

    test('추세선 계산 - 계수가 null일 때', () {
      // Given: 추세선 계수가 없는 차트 데이터
      final chartData = CompleteChartData(
        ticker: 'AAPL',
        data: [],
      );

      // When: 추세선 값 계산 시도
      final highValue = chartData.calculateHighTrendline(10);
      final lowValue = chartData.calculateLowTrendline(10);

      // Then: null 반환
      expect(highValue, isNull);
      expect(lowValue, isNull);
    });

    test('빈 data 배열 처리', () {
      // Given: data가 빈 배열인 차트 데이터
      final json = {
        'ticker': 'AAPL',
        'data': [],
      };

      // When: JSON → Model 파싱
      final chartData = CompleteChartData.fromJson(json);

      // Then: 빈 배열이 올바르게 처리됨
      expect(chartData.ticker, 'AAPL');
      expect(chartData.data, isEmpty);
    });
  });

  group('Null/Empty Data Crash Prevention Tests', () {
    test('Null 값 필터링 후 차트 데이터 생성', () {
      // Given: close 값이 일부 null인 데이터
      final dataPoints = [
        ChartDataPoint(date: DateTime(2026, 2, 1), close: 150.0),
        ChartDataPoint(date: DateTime(2026, 2, 2), close: null),
        ChartDataPoint(date: DateTime(2026, 2, 3), close: 152.0),
      ];

      // When: null 값 필터링
      final validPoints = dataPoints.where((e) => e.close != null).toList();

      // Then: null이 아닌 값만 남음
      expect(validPoints.length, 2);
      expect(validPoints[0].close, 150.0);
      expect(validPoints[1].close, 152.0);
    });

    test('빈 배열로 최소/최대값 계산 시 예외 없음', () {
      // Given: 빈 데이터 배열
      final dataPoints = <ChartDataPoint>[];

      // When: 빈 배열 처리
      final isEmpty = dataPoints.isEmpty;

      // Then: 예외 없이 처리됨
      expect(isEmpty, isTrue);
      expect(() => dataPoints.isEmpty, returnsNormally);
    });

    test('RSI 값이 모두 null일 때 필터링', () {
      // Given: RSI가 모두 null인 데이터
      final dataPoints = [
        ChartDataPoint(date: DateTime(2026, 2, 1), close: 150.0, rsi: null),
        ChartDataPoint(date: DateTime(2026, 2, 2), close: 151.0, rsi: null),
      ];

      // When: RSI null 필터링
      final validRsi = dataPoints.where((e) => e.rsi != null).toList();

      // Then: 빈 배열 반환 (크래시 없음)
      expect(validRsi, isEmpty);
    });

    test('MACD 값이 일부 null일 때 필터링', () {
      // Given: MACD가 일부 null인 데이터
      final dataPoints = [
        ChartDataPoint(
          date: DateTime(2026, 2, 1),
          macd: 1.0,
          macdSignal: 0.8,
          macdHist: 0.2,
        ),
        ChartDataPoint(
          date: DateTime(2026, 2, 2),
          macd: null,
          macdSignal: null,
          macdHist: null,
        ),
        ChartDataPoint(
          date: DateTime(2026, 2, 3),
          macd: 1.5,
          macdSignal: 1.2,
          macdHist: 0.3,
        ),
      ];

      // When: MACD null 필터링
      final validMacd =
          dataPoints.where((e) => e.macd != null && e.macdSignal != null).toList();

      // Then: null이 아닌 데이터만 남음
      expect(validMacd.length, 2);
    });
  });

  group('Bollinger Bands Tests', () {
    test('정상 데이터 파싱 - BB 값 포함', () {
      // Given: Bollinger Bands 데이터가 있는 JSON
      final json = {
        'date': '2026-02-07',
        'close': 150.0,
        'bb_upper': 155.0,
        'bb_middle': 150.0,
        'bb_lower': 145.0,
        'bb_width': 10.0,
      };

      // When: JSON → Model 파싱
      final dataPoint = ChartDataPoint.fromJson(json);

      // Then: BB 값이 올바르게 파싱됨
      expect(dataPoint.bbUpper, 155.0);
      expect(dataPoint.bbMiddle, 150.0);
      expect(dataPoint.bbLower, 145.0);
      expect(dataPoint.bbWidth, 10.0);
    });

    test('Null BB 값 처리', () {
      // Given: BB 값이 null인 데이터
      final json = {
        'date': '2026-02-07',
        'close': 150.0,
        'bb_upper': null,
        'bb_middle': null,
        'bb_lower': null,
      };

      // When: JSON → Model 파싱
      final dataPoint = ChartDataPoint.fromJson(json);

      // Then: Null 값이 올바르게 처리됨
      expect(dataPoint.close, 150.0);
      expect(dataPoint.bbUpper, isNull);
      expect(dataPoint.bbMiddle, isNull);
      expect(dataPoint.bbLower, isNull);
    });

    test('BB 값 필터링 - 모든 BB 필드가 있는 데이터만', () {
      // Given: BB 값이 일부 null인 데이터 배열
      final dataPoints = [
        ChartDataPoint(
          date: DateTime(2026, 2, 1),
          close: 150.0,
          bbUpper: 155.0,
          bbMiddle: 150.0,
          bbLower: 145.0,
        ),
        ChartDataPoint(
          date: DateTime(2026, 2, 2),
          close: 151.0,
          bbUpper: null,
          bbMiddle: null,
          bbLower: null,
        ),
        ChartDataPoint(
          date: DateTime(2026, 2, 3),
          close: 152.0,
          bbUpper: 157.0,
          bbMiddle: 152.0,
          bbLower: 147.0,
        ),
      ];

      // When: BB null 필터링
      final validBB = dataPoints
          .where((e) =>
              e.bbUpper != null && e.bbMiddle != null && e.bbLower != null)
          .toList();

      // Then: null이 아닌 데이터만 남음
      expect(validBB.length, 2);
      expect(validBB[0].bbUpper, 155.0);
      expect(validBB[1].bbUpper, 157.0);
    });

    test('BB 값이 모두 null일 때 빈 배열 반환', () {
      // Given: BB 값이 모두 null인 데이터
      final dataPoints = [
        ChartDataPoint(
          date: DateTime(2026, 2, 1),
          close: 150.0,
          bbUpper: null,
          bbMiddle: null,
          bbLower: null,
        ),
        ChartDataPoint(
          date: DateTime(2026, 2, 2),
          close: 151.0,
          bbUpper: null,
          bbMiddle: null,
          bbLower: null,
        ),
      ];

      // When: BB null 필터링
      final validBB = dataPoints
          .where((e) =>
              e.bbUpper != null && e.bbMiddle != null && e.bbLower != null)
          .toList();

      // Then: 빈 배열 반환 (크래시 없음)
      expect(validBB, isEmpty);
    });

    test('BB 값 범위 계산 - Y축 범위', () {
      // Given: BB 값이 있는 데이터
      final dataPoints = [
        ChartDataPoint(
          date: DateTime(2026, 2, 1),
          close: 150.0,
          bbUpper: 155.0,
          bbMiddle: 150.0,
          bbLower: 145.0,
        ),
        ChartDataPoint(
          date: DateTime(2026, 2, 2),
          close: 160.0,
          bbUpper: 165.0,
          bbMiddle: 160.0,
          bbLower: 155.0,
        ),
      ];

      // When: BB 값 범위 계산
      final allValues = dataPoints.expand((e) => [
            e.bbUpper!,
            e.bbMiddle!,
            e.bbLower!,
          ]);
      final minValue = allValues.fold<double>(
          allValues.first, (prev, curr) => prev < curr ? prev : curr);
      final maxValue = allValues.fold<double>(
          allValues.first, (prev, curr) => prev > curr ? prev : curr);

      // Then: 최소/최대값이 올바르게 계산됨
      expect(minValue, 145.0);
      expect(maxValue, 165.0);
    });
  });
}
