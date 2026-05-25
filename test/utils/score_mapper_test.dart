import 'package:flutter_test/flutter_test.dart';
import 'package:marketlens/theme/app_colors.dart';
import 'package:marketlens/utils/score_mapper.dart';

void main() {
  group('getScoreLevel', () {
    test('score 100 returns strongBuy', () {
      expect(ScoreMapper.getScoreLevel(100), ScoreLevel.strongBuy);
    });

    test('score 80 returns strongBuy (lower boundary)', () {
      expect(ScoreMapper.getScoreLevel(80), ScoreLevel.strongBuy);
    });

    test('score 79 returns buy', () {
      expect(ScoreMapper.getScoreLevel(79), ScoreLevel.buy);
    });

    test('score 60 returns buy (lower boundary)', () {
      expect(ScoreMapper.getScoreLevel(60), ScoreLevel.buy);
    });

    test('score 59 returns hold', () {
      expect(ScoreMapper.getScoreLevel(59), ScoreLevel.hold);
    });

    test('score 40 returns hold (lower boundary)', () {
      expect(ScoreMapper.getScoreLevel(40), ScoreLevel.hold);
    });

    test('score 39 returns sell', () {
      expect(ScoreMapper.getScoreLevel(39), ScoreLevel.sell);
    });

    test('score 20 returns sell (lower boundary)', () {
      expect(ScoreMapper.getScoreLevel(20), ScoreLevel.sell);
    });

    test('score 19 returns strongSell', () {
      expect(ScoreMapper.getScoreLevel(19), ScoreLevel.strongSell);
    });

    test('score 0 returns strongSell', () {
      expect(ScoreMapper.getScoreLevel(0), ScoreLevel.strongSell);
    });
  });

  group('getScoreColor', () {
    test('score >= 80 returns gainColor', () {
      expect(
        ScoreMapper.getScoreColor(85, MarketLensColors.light),
        MarketLensColors.light.gainColor,
      );
    });

    test('score 60-79 returns scoreBuyColor', () {
      expect(
        ScoreMapper.getScoreColor(70, MarketLensColors.light),
        MarketLensColors.light.scoreBuyColor,
      );
    });

    test('score 40-59 returns scoreHoldColor', () {
      expect(
        ScoreMapper.getScoreColor(50, MarketLensColors.light),
        MarketLensColors.light.scoreHoldColor,
      );
    });

    test('score 20-39 returns scoreSellColor', () {
      expect(
        ScoreMapper.getScoreColor(30, MarketLensColors.light),
        MarketLensColors.light.scoreSellColor,
      );
    });

    test('score < 20 returns lossColor', () {
      expect(
        ScoreMapper.getScoreColor(10, MarketLensColors.light),
        MarketLensColors.light.lossColor,
      );
    });
  });

  group('getScoreLabel', () {
    test('score >= 80 returns 강력긍정', () {
      expect(ScoreMapper.getScoreLabel(90), '강력긍정');
    });

    test('score 60-79 returns 긍정', () {
      expect(ScoreMapper.getScoreLabel(65), '긍정');
    });

    test('score 40-59 returns 중립', () {
      expect(ScoreMapper.getScoreLabel(50), '중립');
    });

    test('score 20-39 returns 부정', () {
      expect(ScoreMapper.getScoreLabel(25), '부정');
    });

    test('score < 20 returns 강력부정', () {
      expect(ScoreMapper.getScoreLabel(10), '강력부정');
    });
  });

  group('getScoreEmoji', () {
    test('score >= 80 returns fire emoji', () {
      expect(ScoreMapper.getScoreEmoji(80), '🔥');
      expect(ScoreMapper.getScoreEmoji(100), '🔥');
    });

    test('score < 20 returns chart decreasing emoji', () {
      expect(ScoreMapper.getScoreEmoji(19), '📉');
      expect(ScoreMapper.getScoreEmoji(0), '📉');
    });

    test('score 20-79 returns null (no emoji)', () {
      expect(ScoreMapper.getScoreEmoji(20), isNull);
      expect(ScoreMapper.getScoreEmoji(50), isNull);
      expect(ScoreMapper.getScoreEmoji(79), isNull);
    });
  });

  group('getColorForLevel', () {
    test('strongBuy returns gainColor', () {
      expect(
        ScoreMapper.getColorForLevel(
          ScoreLevel.strongBuy,
          MarketLensColors.light,
        ),
        MarketLensColors.light.gainColor,
      );
    });

    test('buy returns scoreBuyColor', () {
      expect(
        ScoreMapper.getColorForLevel(ScoreLevel.buy, MarketLensColors.light),
        MarketLensColors.light.scoreBuyColor,
      );
    });

    test('hold returns scoreHoldColor', () {
      expect(
        ScoreMapper.getColorForLevel(ScoreLevel.hold, MarketLensColors.light),
        MarketLensColors.light.scoreHoldColor,
      );
    });

    test('sell returns scoreSellColor', () {
      expect(
        ScoreMapper.getColorForLevel(ScoreLevel.sell, MarketLensColors.light),
        MarketLensColors.light.scoreSellColor,
      );
    });

    test('strongSell returns lossColor', () {
      expect(
        ScoreMapper.getColorForLevel(
          ScoreLevel.strongSell,
          MarketLensColors.light,
        ),
        MarketLensColors.light.lossColor,
      );
    });
  });

  group('getLabelForLevel', () {
    test('strongBuy returns 강력긍정', () {
      expect(ScoreMapper.getLabelForLevel(ScoreLevel.strongBuy), '강력긍정');
    });

    test('buy returns 긍정', () {
      expect(ScoreMapper.getLabelForLevel(ScoreLevel.buy), '긍정');
    });

    test('hold returns 중립', () {
      expect(ScoreMapper.getLabelForLevel(ScoreLevel.hold), '중립');
    });

    test('sell returns 부정', () {
      expect(ScoreMapper.getLabelForLevel(ScoreLevel.sell), '부정');
    });

    test('strongSell returns 강력부정', () {
      expect(ScoreMapper.getLabelForLevel(ScoreLevel.strongSell), '강력부정');
    });
  });

  group('consistency between score-based and level-based methods', () {
    test('getScoreColor matches getColorForLevel for each boundary', () {
      for (final score in [90.0, 70.0, 50.0, 30.0, 10.0]) {
        final level = ScoreMapper.getScoreLevel(score);
        expect(
          ScoreMapper.getScoreColor(score, MarketLensColors.light),
          ScoreMapper.getColorForLevel(level, MarketLensColors.light),
          reason: 'Mismatch at score $score',
        );
      }
    });

    test('getScoreLabel matches getLabelForLevel for each boundary', () {
      for (final score in [90.0, 70.0, 50.0, 30.0, 10.0]) {
        final level = ScoreMapper.getScoreLevel(score);
        expect(
          ScoreMapper.getScoreLabel(score),
          ScoreMapper.getLabelForLevel(level),
          reason: 'Mismatch at score $score',
        );
      }
    });
  });
}
