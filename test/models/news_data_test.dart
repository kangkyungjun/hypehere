import 'package:flutter_test/flutter_test.dart';
import 'package:marketlens/models/news_data.dart';
import 'package:marketlens/theme/app_colors.dart';

/// 뉴스 데이터 모델 파싱 테스트
///
/// 테스트 철학:
/// - API→Model 파싱 정확성 검증
/// - Null/기본값 처리 검증
/// - getter 로직 검증 (sectorShort, sentimentColor)
/// - 시간 의존적 테스트(timeAgo) 및 로컬라이제이션(sentimentLabelLocalized) 제외
void main() {
  group('NewsItem Parsing Tests', () {
    test('fromJson: 모든 필드 정상 파싱', () {
      // Given: 완전한 뉴스 아이템 JSON
      final json = {
        'date': '2026-04-10',
        'ticker': 'AAPL',
        'title': 'Apple announces new AI features',
        'source': 'Reuters',
        'source_url': 'https://reuters.com/article/123',
        'published_at': '2026-04-10T14:30:00Z',
        'ai_summary': 'Apple unveiled new AI capabilities at its spring event.',
        'sentiment_grade': 'bullish',
        'sentiment_label': '긍정',
        'future_event': {'event': 'WWDC', 'date': '2026-06-09'},
        'ticker_name_ko': '애플',
        'is_breaking': true,
        'is_hot_topic': true,
        'hot_topic_category': 'AI',
        'hot_topic_priority': 1,
        'sector': 'Technology',
      };

      // When: JSON -> Model 파싱
      final item = NewsItem.fromJson(json);

      // Then: 모든 필드가 올바르게 파싱됨
      expect(item.date, '2026-04-10');
      expect(item.ticker, 'AAPL');
      expect(item.title, 'Apple announces new AI features');
      expect(item.source, 'Reuters');
      expect(item.sourceUrl, 'https://reuters.com/article/123');
      expect(item.publishedAt, DateTime.utc(2026, 4, 10, 14, 30, 0));
      expect(item.aiSummary, 'Apple unveiled new AI capabilities at its spring event.');
      expect(item.sentimentGrade, 'bullish');
      expect(item.sentimentLabel, '긍정');
      expect(item.futureEvent, isNotNull);
      expect(item.futureEvent!['event'], 'WWDC');
      expect(item.tickerNameKo, '애플');
      expect(item.isBreaking, true);
      expect(item.isHotTopic, true);
      expect(item.hotTopicCategory, 'AI');
      expect(item.hotTopicPriority, 1);
      expect(item.sector, 'Technology');
    });

    test('fromJson: is_breaking 기본값 false', () {
      // Given: is_breaking 필드가 없는 JSON
      final json = {
        'date': '2026-04-10',
        'ticker': 'MSFT',
        'title': 'Microsoft earnings preview',
        'published_at': '2026-04-10T10:00:00Z',
        'ai_summary': 'Analysts expect strong cloud growth.',
        'sentiment_grade': 'neutral',
        'sentiment_label': '중립',
      };

      // When: JSON -> Model 파싱
      final item = NewsItem.fromJson(json);

      // Then: is_breaking이 기본값 false
      expect(item.isBreaking, false);
      expect(item.isHotTopic, false);
    });

    test('fromJson: nullable 필드가 null', () {
      // Given: 선택적 필드가 없는 최소 JSON
      final json = {
        'date': '2026-04-10',
        'ticker': 'TSLA',
        'title': 'Tesla production update',
        'published_at': '2026-04-10T08:00:00Z',
        'ai_summary': 'Production numbers released.',
        'sentiment_grade': 'bearish',
        'sentiment_label': '부정',
      };

      // When: JSON -> Model 파싱
      final item = NewsItem.fromJson(json);

      // Then: nullable 필드가 null
      expect(item.source, isNull);
      expect(item.sourceUrl, isNull);
      expect(item.futureEvent, isNull);
      expect(item.tickerNameKo, isNull);
      expect(item.hotTopicCategory, isNull);
      expect(item.hotTopicPriority, isNull);
      expect(item.sector, isNull);
    });

    test('fromJson: published_at UTC가 아닌 timestamp도 UTC로 변환', () {
      // Given: UTC가 아닌 timestamp
      final json = {
        'date': '2026-04-10',
        'ticker': 'GOOG',
        'title': 'Google Cloud revenue grows',
        'published_at': '2026-04-10T09:00:00',
        'ai_summary': 'Cloud revenue exceeded expectations.',
        'sentiment_grade': 'bullish',
        'sentiment_label': '긍정',
      };

      // When: JSON -> Model 파싱
      final item = NewsItem.fromJson(json);

      // Then: publishedAt이 UTC로 변환됨
      expect(item.publishedAt.isUtc, true);
      expect(item.publishedAt.year, 2026);
      expect(item.publishedAt.month, 4);
      expect(item.publishedAt.day, 10);
      expect(item.publishedAt.hour, 9);
    });
  });

  group('NewsItem.sectorShort Tests', () {
    NewsItem makeItemWithSector(String? sector) {
      return NewsItem(
        date: '2026-04-10',
        ticker: 'TEST',
        title: 'Test',
        publishedAt: DateTime.utc(2026, 4, 10),
        aiSummary: 'Test',
        sentimentGrade: 'neutral',
        sentimentLabel: '중립',
        sector: sector,
      );
    }

    test('Technology -> Tech', () {
      expect(makeItemWithSector('Technology').sectorShort, 'Tech');
    });

    test('Healthcare -> Health', () {
      expect(makeItemWithSector('Healthcare').sectorShort, 'Health');
    });

    test('Communication Services -> Comm', () {
      expect(makeItemWithSector('Communication Services').sectorShort, 'Comm');
    });

    test('null sector -> null', () {
      expect(makeItemWithSector(null).sectorShort, isNull);
    });

    test('매핑에 없는 sector -> 원본 반환', () {
      expect(makeItemWithSector('Aerospace').sectorShort, 'Aerospace');
    });

    test('Information Technology -> Tech', () {
      expect(makeItemWithSector('Information Technology').sectorShort, 'Tech');
    });

    test('Consumer Discretionary -> Discret.', () {
      expect(makeItemWithSector('Consumer Discretionary').sectorShort, 'Discret.');
    });

    test('Real Estate -> RE', () {
      expect(makeItemWithSector('Real Estate').sectorShort, 'RE');
    });
  });

  group('NewsItem.sentimentColor Tests', () {
    NewsItem makeItemWithGrade(String grade) {
      return NewsItem(
        date: '2026-04-10',
        ticker: 'TEST',
        title: 'Test',
        publishedAt: DateTime.utc(2026, 4, 10),
        aiSummary: 'Test',
        sentimentGrade: grade,
        sentimentLabel: 'test',
      );
    }

    test('bullish -> gainColor', () {
      final item = makeItemWithGrade('bullish');
      expect(item.sentimentColor(MarketLensColors.light), MarketLensColors.light.gainColor);
    });

    test('bearish -> lossColor', () {
      final item = makeItemWithGrade('bearish');
      expect(item.sentimentColor(MarketLensColors.light), MarketLensColors.light.lossColor);
    });

    test('neutral -> neutralColor', () {
      final item = makeItemWithGrade('neutral');
      expect(item.sentimentColor(MarketLensColors.light), MarketLensColors.light.neutralColor);
    });

    test('알 수 없는 grade -> neutralColor (default)', () {
      final item = makeItemWithGrade('unknown');
      expect(item.sentimentColor(MarketLensColors.light), MarketLensColors.light.neutralColor);
    });
  });

  group('SentimentCounts Parsing Tests', () {
    test('fromJson: 모든 값 정상 파싱', () {
      // Given: 완전한 감성 카운트 JSON
      final json = {
        'bullish': 15,
        'neutral': 8,
        'bearish': 3,
      };

      // When: JSON -> Model 파싱
      final counts = SentimentCounts.fromJson(json);

      // Then: 모든 값이 올바르게 파싱됨
      expect(counts.bullish, 15);
      expect(counts.neutral, 8);
      expect(counts.bearish, 3);
    });

    test('fromJson: null 값은 0으로 기본 처리', () {
      // Given: 모든 값이 null인 JSON
      final json = <String, dynamic>{
        'bullish': null,
        'neutral': null,
        'bearish': null,
      };

      // When: JSON -> Model 파싱
      final counts = SentimentCounts.fromJson(json);

      // Then: 모든 값이 0으로 기본 처리됨
      expect(counts.bullish, 0);
      expect(counts.neutral, 0);
      expect(counts.bearish, 0);
    });

    test('fromJson: 빈 JSON도 0으로 기본 처리', () {
      // Given: 빈 JSON
      final json = <String, dynamic>{};

      // When: JSON -> Model 파싱
      final counts = SentimentCounts.fromJson(json);

      // Then: 모든 값이 0
      expect(counts.bullish, 0);
      expect(counts.neutral, 0);
      expect(counts.bearish, 0);
    });
  });

  group('NewsSentimentStats Parsing Tests', () {
    test('fromJson: week/month 데이터 정상 파싱', () {
      // Given: 완전한 감성 통계 JSON
      final json = {
        'week': {
          'bullish': 10,
          'neutral': 5,
          'bearish': 2,
        },
        'month': {
          'bullish': 40,
          'neutral': 20,
          'bearish': 8,
        },
      };

      // When: JSON -> Model 파싱
      final stats = NewsSentimentStats.fromJson(json);

      // Then: week/month 데이터가 올바르게 파싱됨
      expect(stats.week.bullish, 10);
      expect(stats.week.neutral, 5);
      expect(stats.week.bearish, 2);
      expect(stats.month.bullish, 40);
      expect(stats.month.neutral, 20);
      expect(stats.month.bearish, 8);
    });

    test('fromJson: null week/month -> 기본값 SentimentCounts(0,0,0)', () {
      // Given: week/month가 null인 JSON
      final json = <String, dynamic>{
        'week': null,
        'month': null,
      };

      // When: JSON -> Model 파싱
      final stats = NewsSentimentStats.fromJson(json);

      // Then: 기본 SentimentCounts(0,0,0) 사용
      expect(stats.week.bullish, 0);
      expect(stats.week.neutral, 0);
      expect(stats.week.bearish, 0);
      expect(stats.month.bullish, 0);
      expect(stats.month.neutral, 0);
      expect(stats.month.bearish, 0);
    });

    test('fromJson: 빈 JSON -> 기본값', () {
      // Given: week/month 키가 없는 JSON
      final json = <String, dynamic>{};

      // When: JSON -> Model 파싱
      final stats = NewsSentimentStats.fromJson(json);

      // Then: 기본 SentimentCounts 사용
      expect(stats.week.bullish, 0);
      expect(stats.month.bullish, 0);
    });
  });

  group('NewsListData Parsing Tests', () {
    test('fromJson: items 배열 정상 파싱', () {
      // Given: 뉴스 목록 JSON
      final json = {
        'items': [
          {
            'date': '2026-04-10',
            'ticker': 'AAPL',
            'title': 'Apple news',
            'published_at': '2026-04-10T14:00:00Z',
            'ai_summary': 'Summary 1',
            'sentiment_grade': 'bullish',
            'sentiment_label': '긍정',
          },
          {
            'date': '2026-04-10',
            'ticker': 'MSFT',
            'title': 'Microsoft news',
            'published_at': '2026-04-10T15:00:00Z',
            'ai_summary': 'Summary 2',
            'sentiment_grade': 'neutral',
            'sentiment_label': '중립',
          },
        ],
        'total': 25,
      };

      // When: JSON -> Model 파싱
      final listData = NewsListData.fromJson(json);

      // Then: items와 total이 올바르게 파싱됨
      expect(listData.items.length, 2);
      expect(listData.items[0].ticker, 'AAPL');
      expect(listData.items[1].ticker, 'MSFT');
      expect(listData.total, 25);
    });

    test('fromJson: 빈 items 배열', () {
      // Given: items가 빈 배열인 JSON
      final json = {
        'items': [],
        'total': 0,
      };

      // When: JSON -> Model 파싱
      final listData = NewsListData.fromJson(json);

      // Then: 빈 배열과 0 total
      expect(listData.items, isEmpty);
      expect(listData.total, 0);
    });

    test('fromJson: items가 null일 때 빈 배열 반환', () {
      // Given: items가 null인 JSON
      final json = <String, dynamic>{
        'items': null,
        'total': 0,
      };

      // When: JSON -> Model 파싱
      final listData = NewsListData.fromJson(json);

      // Then: 빈 배열 반환
      expect(listData.items, isEmpty);
    });

    test('fromJson: total이 null일 때 0 반환', () {
      // Given: total이 null인 JSON
      final json = <String, dynamic>{
        'items': [],
        'total': null,
      };

      // When: JSON -> Model 파싱
      final listData = NewsListData.fromJson(json);

      // Then: total이 0
      expect(listData.total, 0);
    });
  });
}
