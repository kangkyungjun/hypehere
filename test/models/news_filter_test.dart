import 'package:flutter_test/flutter_test.dart';
import 'package:marketlens/models/news_filter.dart';

void main() {
  // ---------------------------------------------------------------------------
  // NewsFilterState
  // ---------------------------------------------------------------------------
  group('NewsFilterState', () {
    group('default constructor', () {
      test('has correct default values', () {
        const state = NewsFilterState();

        expect(state.category, NewsCategory.all);
        expect(state.sentimentGrades, isEmpty);
        expect(state.sectors, isEmpty);
        expect(state.breakingOnly, false);
      });
    });

    group('isActive', () {
      test('returns false for default state', () {
        const state = NewsFilterState();
        expect(state.isActive, false);
      });

      test('returns true when category is not all', () {
        const state = NewsFilterState(
          category: NewsCategory.watchlist,
        );
        expect(state.isActive, true);
      });

      test('returns true when category is biz', () {
        const state = NewsFilterState(
          category: NewsCategory.biz,
        );
        expect(state.isActive, true);
      });

      test('returns true when category is world', () {
        const state = NewsFilterState(
          category: NewsCategory.world,
        );
        expect(state.isActive, true);
      });

      test('returns true when sentimentGrades is not empty', () {
        const state = NewsFilterState(
          sentimentGrades: {'bullish'},
        );
        expect(state.isActive, true);
      });

      test('returns true when sectors is not empty', () {
        const state = NewsFilterState(
          sectors: {'Technology'},
        );
        expect(state.isActive, true);
      });

      test('returns true when breakingOnly is true', () {
        const state = NewsFilterState(breakingOnly: true);
        expect(state.isActive, true);
      });

      test('returns true when multiple filters are active', () {
        const state = NewsFilterState(
          category: NewsCategory.watchlist,
          sentimentGrades: {'bullish', 'neutral'},
          sectors: {'Technology', 'Healthcare'},
          breakingOnly: true,
        );
        expect(state.isActive, true);
      });
    });

    group('activeCount', () {
      test('returns 0 for default state', () {
        const state = NewsFilterState();
        expect(state.activeCount, 0);
      });

      test('returns 1 when only category changed', () {
        const state = NewsFilterState(
          category: NewsCategory.watchlist,
        );
        expect(state.activeCount, 1);
      });

      test('returns 1 when only sentimentGrades set', () {
        const state = NewsFilterState(
          sentimentGrades: {'bullish', 'bearish'},
        );
        expect(state.activeCount, 1);
      });

      test('returns 1 when only sectors set', () {
        const state = NewsFilterState(
          sectors: {'Technology'},
        );
        expect(state.activeCount, 1);
      });

      test('returns 1 when only breakingOnly is true', () {
        const state = NewsFilterState(breakingOnly: true);
        expect(state.activeCount, 1);
      });

      test('returns 2 when two filter categories active', () {
        const state = NewsFilterState(
          category: NewsCategory.biz,
          breakingOnly: true,
        );
        expect(state.activeCount, 2);
      });

      test('returns 3 when three filter categories active', () {
        const state = NewsFilterState(
          category: NewsCategory.watchlist,
          sentimentGrades: {'bullish'},
          breakingOnly: true,
        );
        expect(state.activeCount, 3);
      });

      test('returns 4 when all filter categories active', () {
        const state = NewsFilterState(
          category: NewsCategory.watchlist,
          sentimentGrades: {'bearish'},
          sectors: {'Energy'},
          breakingOnly: true,
        );
        expect(state.activeCount, 4);
      });
    });

    group('copyWith', () {
      test('preserves all fields when no arguments given', () {
        const original = NewsFilterState(
          category: NewsCategory.watchlist,
          sentimentGrades: {'bullish'},
          sectors: {'Technology'},
          breakingOnly: true,
        );

        final copy = original.copyWith();

        expect(copy.category, NewsCategory.watchlist);
        expect(copy.sentimentGrades, {'bullish'});
        expect(copy.sectors, {'Technology'});
        expect(copy.breakingOnly, true);
      });

      test('updates only category', () {
        const original = NewsFilterState(
          sentimentGrades: {'bearish'},
          sectors: {'Energy'},
          breakingOnly: true,
        );

        final copy = original.copyWith(
          category: NewsCategory.biz,
        );

        expect(copy.category, NewsCategory.biz);
        expect(copy.sentimentGrades, {'bearish'});
        expect(copy.sectors, {'Energy'});
        expect(copy.breakingOnly, true);
      });

      test('updates only sentimentGrades', () {
        const original = NewsFilterState(
          category: NewsCategory.watchlist,
          breakingOnly: true,
        );

        final copy = original.copyWith(
          sentimentGrades: {'neutral', 'bullish'},
        );

        expect(copy.category, NewsCategory.watchlist);
        expect(copy.sentimentGrades, {'neutral', 'bullish'});
        expect(copy.sectors, isEmpty);
        expect(copy.breakingOnly, true);
      });

      test('updates only sectors', () {
        const original = NewsFilterState(
          category: NewsCategory.biz,
          sentimentGrades: {'bullish'},
        );

        final copy = original.copyWith(
          sectors: {'Healthcare', 'Financials'},
        );

        expect(copy.category, NewsCategory.biz);
        expect(copy.sentimentGrades, {'bullish'});
        expect(copy.sectors, {'Healthcare', 'Financials'});
        expect(copy.breakingOnly, false);
      });

      test('updates only breakingOnly', () {
        const original = NewsFilterState(
          category: NewsCategory.watchlist,
          sentimentGrades: {'bearish'},
          sectors: {'Technology'},
        );

        final copy = original.copyWith(breakingOnly: true);

        expect(copy.category, NewsCategory.watchlist);
        expect(copy.sentimentGrades, {'bearish'});
        expect(copy.sectors, {'Technology'});
        expect(copy.breakingOnly, true);
      });

      test('updates multiple fields simultaneously', () {
        const original = NewsFilterState();

        final copy = original.copyWith(
          category: NewsCategory.watchlist,
          breakingOnly: true,
        );

        expect(copy.category, NewsCategory.watchlist);
        expect(copy.sentimentGrades, isEmpty);
        expect(copy.sectors, isEmpty);
        expect(copy.breakingOnly, true);
      });

      test('can reset fields back to default values', () {
        const original = NewsFilterState(
          category: NewsCategory.watchlist,
          sentimentGrades: {'bullish'},
          sectors: {'Technology'},
          breakingOnly: true,
        );

        final copy = original.copyWith(
          category: NewsCategory.all,
          sentimentGrades: {},
          sectors: {},
          breakingOnly: false,
        );

        expect(copy.category, NewsCategory.all);
        expect(copy.sentimentGrades, isEmpty);
        expect(copy.sectors, isEmpty);
        expect(copy.breakingOnly, false);
        expect(copy.isActive, false);
      });
    });

    group('fallbackSectors', () {
      test('has 11 items', () {
        expect(NewsFilterState.fallbackSectors, hasLength(11));
      });

      test('contains expected sectors', () {
        expect(NewsFilterState.fallbackSectors, contains('Technology'));
        expect(NewsFilterState.fallbackSectors, contains('Healthcare'));
        expect(NewsFilterState.fallbackSectors, contains('Energy'));
        expect(NewsFilterState.fallbackSectors, contains('Consumer Cyclical'));
        expect(NewsFilterState.fallbackSectors, contains('Consumer Defensive'));
        expect(NewsFilterState.fallbackSectors, contains('Communication Services'));
        expect(NewsFilterState.fallbackSectors, contains('Financials'));
        expect(NewsFilterState.fallbackSectors, contains('Industrials'));
        expect(NewsFilterState.fallbackSectors, contains('Utilities'));
        expect(NewsFilterState.fallbackSectors, contains('Real Estate'));
        expect(NewsFilterState.fallbackSectors, contains('Basic Materials'));
      });
    });

    group('defaultState', () {
      test('matches default constructor', () {
        const defaultFromConst = NewsFilterState.defaultState;
        const defaultFromCtor = NewsFilterState();

        expect(
          defaultFromConst.category,
          defaultFromCtor.category,
        );
        expect(
          defaultFromConst.sentimentGrades,
          defaultFromCtor.sentimentGrades,
        );
        expect(defaultFromConst.sectors, defaultFromCtor.sectors);
        expect(
          defaultFromConst.breakingOnly,
          defaultFromCtor.breakingOnly,
        );
      });

      test('is not active', () {
        expect(NewsFilterState.defaultState.isActive, false);
      });

      test('has activeCount of 0', () {
        expect(NewsFilterState.defaultState.activeCount, 0);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // NewsCategory enum
  // ---------------------------------------------------------------------------
  group('NewsCategory', () {
    test('has four values', () {
      expect(NewsCategory.values, hasLength(4));
    });

    test('contains all, biz, world, watchlist', () {
      expect(
        NewsCategory.values,
        containsAll([
          NewsCategory.all,
          NewsCategory.biz,
          NewsCategory.world,
          NewsCategory.watchlist,
        ]),
      );
    });
  });
}
