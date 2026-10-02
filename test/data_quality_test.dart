import 'package:flutter_test/flutter_test.dart';
import 'package:marketlens/models/chart_data.dart';
import 'package:marketlens/utils/multilingual.dart';

/// `data_quality` 계약 + 다국어 팩 문자열 처리.
///
/// 배경: 파이프라인은 상장 40~119거래일인 종목에 AI 예측 헤드를 돌리지
/// 않지만, `ai_probability`를 비워 보내는 대신 **0.5로 채워서** 보낸다.
/// 그래서 **확률값만으로는 유효성을 판단할 수 없다.** 서버가 2026-10-02부터
/// `data_quality.ai_available`을 내려준다(S1).
///
/// 이 테스트가 지키는 것: 그 신호를 앱이 실제로 따르는가.
void main() {
  /// 2026-10-02 공개 엔드포인트(`/api/v1/charts/{ticker}`)에서 받은 실제 응답
  /// 모양이다. 와이어 계약을 박아둔다 — 서버가 모양을 바꾸면 여기서 깨진다.
  Map<String, dynamic> point({
    required String date,
    double? probability,
    Map<String, dynamic>? dataQuality,
  }) =>
      {
        'date': date,
        'close': 100.0,
        'score': 54.8,
        'signal': '관망',
        if (dataQuality != null) 'data_quality': dataQuality,
        'ai_probability': probability,
        'ai_summary': '요약|||summary',
      };

  group('DataQuality.fromJson', () {
    test('limited 응답을 그대로 읽는다 (FDXF 2026-10-01 실제 값)', () {
      final dq = DataQuality.fromJson({
        'analysis_mode': 'limited',
        'history_days': 89,
        'ai_available': false,
      });
      expect(dq.analysisMode, 'limited');
      expect(dq.historyDays, 89);
      expect(dq.aiAvailable, isFalse);
      expect(dq.isLimited, isTrue);
    });

    test('full 응답을 그대로 읽는다 (AAPL 2026-10-01 실제 값)', () {
      final dq = DataQuality.fromJson({
        'analysis_mode': 'full',
        'history_days': 251,
        'ai_available': true,
      });
      expect(dq.isLimited, isFalse);
      expect(dq.aiAvailable, isTrue);
    });

    test('history_days가 null이어도 읽는다 — 마이그레이션 이전 행', () {
      // 서버가 NULL을 full로 환산해 내려주는 경우. 앱은 NULL 분기를 하지 않는다.
      final dq = DataQuality.fromJson({
        'analysis_mode': 'full',
        'history_days': null,
        'ai_available': true,
      });
      expect(dq.historyDays, isNull);
      expect(dq.aiAvailable, isTrue);
    });

    test('ai_available이 빠지면 모드에서 유도한다 — 둘이 어긋나지 않게', () {
      expect(
        DataQuality.fromJson({'analysis_mode': 'limited'}).aiAvailable,
        isFalse,
      );
      expect(
        DataQuality.fromJson({'analysis_mode': 'full'}).aiAvailable,
        isTrue,
      );
    });

    test('analysis_mode가 빠지면 full로 본다', () {
      expect(DataQuality.fromJson(const {}).analysisMode, 'full');
      expect(DataQuality.fromJson(const {}).aiAvailable, isTrue);
    });
  });

  group('hasUsableAiProbability — 거짓 50%를 막는 가드', () {
    test('limited + probability 0.5 → 그리지 않는다', () {
      // 이게 이 기능이 존재하는 이유다. 0.5는 예측이 아니라 자리채움이고,
      // 그대로 그리면 "AI 상승 확률 50% + 상승"(0.5 >= 0.5)이 된다.
      final p = ChartDataPoint.fromJson(point(
        date: '2026-10-01',
        probability: 0.5,
        dataQuality: {
          'analysis_mode': 'limited',
          'history_days': 89,
          'ai_available': false,
        },
      ));
      expect(p.aiProbability, 0.5, reason: '값 자체는 들어온다');
      expect(p.hasUsableAiProbability, isFalse, reason: '그려선 안 된다');
    });

    test('full + probability → 그린다', () {
      final p = ChartDataPoint.fromJson(point(
        date: '2026-10-01',
        probability: 0.4439,
        dataQuality: {
          'analysis_mode': 'full',
          'history_days': 251,
          'ai_available': true,
        },
      ));
      expect(p.hasUsableAiProbability, isTrue);
    });

    test('full인데 probability가 null → 그리지 않는다', () {
      // 그릴 숫자가 없다. 예전에는 `?? 0.5`로 메워서 가짜 중립을 그렸다.
      final p = ChartDataPoint.fromJson(point(
        date: '2026-10-01',
        probability: null,
        dataQuality: {'analysis_mode': 'full', 'ai_available': true},
      ));
      expect(p.hasUsableAiProbability, isFalse);
    });

    test('정확히 0.5인 full 종목은 그린다 — limited와 혼동하지 않는다', () {
      // 확률값으로 limited를 추론하면 이 케이스를 잘못 숨긴다.
      // 그래서 판단 근거는 ai_available이어야 한다.
      final p = ChartDataPoint.fromJson(point(
        date: '2026-10-01',
        probability: 0.5,
        dataQuality: {
          'analysis_mode': 'full',
          'history_days': 251,
          'ai_available': true,
        },
      ));
      expect(p.hasUsableAiProbability, isTrue);
    });

    test('data_quality가 없으면 보여주는 쪽으로 기운다', () {
      // 점수 행이 없는 날짜이거나 구버전 서버 응답이다. 숨기는 쪽으로
      // 기울이면 정상 종목의 AI 블록이 통째로 사라진다.
      final p = ChartDataPoint.fromJson(
        point(date: '2026-10-01', probability: 0.62),
      );
      expect(p.dataQuality, isNull);
      expect(p.hasUsableAiProbability, isTrue);
    });
  });

  test('toJson이 data_quality를 왕복시킨다', () {
    final src = point(
      date: '2026-10-01',
      probability: 0.5,
      dataQuality: {
        'analysis_mode': 'limited',
        'history_days': 89,
        'ai_available': false,
      },
    );
    final round = ChartDataPoint.fromJson(ChartDataPoint.fromJson(src).toJson());
    expect(round.dataQuality!.analysisMode, 'limited');
    expect(round.dataQuality!.historyDays, 89);
    expect(round.dataQuality!.aiAvailable, isFalse);
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
