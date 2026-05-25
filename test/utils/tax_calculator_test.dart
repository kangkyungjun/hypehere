import 'package:flutter_test/flutter_test.dart';
import 'package:marketlens/utils/tax_calculator.dart';

void main() {
  group('TaxCalculator constants', () {
    test('taxRate is 22%', () {
      expect(TaxCalculator.taxRate, 0.22);
    });

    test('annualExemptionKrw is 2,500,000', () {
      expect(TaxCalculator.annualExemptionKrw, 2500000);
    });
  });

  group('calculateSingleTrade', () {
    test('profitable trade computes all fields correctly', () {
      // Buy 10 shares at $100, sell at $150
      // Buy rate 1300, sell rate 1350
      final result = TaxCalculator.calculateSingleTrade(
        buyPriceUsd: 100,
        sellPriceUsd: 150,
        shares: 10,
        buyExchangeRate: 1300,
        sellExchangeRate: 1350,
      );

      // buyTotalKrw = 100 * 10 * 1300 = 1,300,000
      expect(result.buyTotalKrw, 1300000);
      // sellTotalKrw = 150 * 10 * 1350 = 2,025,000
      expect(result.sellTotalKrw, 2025000);
      // gainKrw = 2,025,000 - 1,300,000 = 725,000
      expect(result.gainKrw, 725000);
      // gainUsd = (150 - 100) * 10 = 500
      expect(result.gainUsd, 500);
      // gainPct = (725,000 / 1,300,000) * 100
      expect(result.gainPct, closeTo(55.769, 0.01));
      // taxableGainKrw = 725,000 (positive gain)
      expect(result.taxableGainKrw, 725000);
      // estimatedTaxKrw = 725,000 * 0.22 = 159,500
      expect(result.estimatedTaxKrw, 159500);
      // afterTaxGainKrw = 725,000 - 159,500 = 565,500
      expect(result.afterTaxGainKrw, 565500);
    });

    test('losing trade has zero tax', () {
      // Buy 5 shares at $200, sell at $150
      final result = TaxCalculator.calculateSingleTrade(
        buyPriceUsd: 200,
        sellPriceUsd: 150,
        shares: 5,
        buyExchangeRate: 1300,
        sellExchangeRate: 1300,
      );

      // buyTotalKrw = 200 * 5 * 1300 = 1,300,000
      expect(result.buyTotalKrw, 1300000);
      // sellTotalKrw = 150 * 5 * 1300 = 975,000
      expect(result.sellTotalKrw, 975000);
      // gainKrw = 975,000 - 1,300,000 = -325,000
      expect(result.gainKrw, -325000);
      // gainUsd = (150 - 200) * 5 = -250
      expect(result.gainUsd, -250);
      // Negative gain => no taxable gain
      expect(result.taxableGainKrw, 0);
      expect(result.estimatedTaxKrw, 0);
      // afterTaxGainKrw = -325,000 - 0 = -325,000
      expect(result.afterTaxGainKrw, -325000);
    });

    test('break-even trade has zero gain and zero tax', () {
      final result = TaxCalculator.calculateSingleTrade(
        buyPriceUsd: 100,
        sellPriceUsd: 100,
        shares: 10,
        buyExchangeRate: 1300,
        sellExchangeRate: 1300,
      );

      expect(result.gainKrw, 0);
      expect(result.gainUsd, 0);
      expect(result.gainPct, 0);
      expect(result.taxableGainKrw, 0);
      expect(result.estimatedTaxKrw, 0);
      expect(result.afterTaxGainKrw, 0);
    });

    test('zero shares results in zero values', () {
      final result = TaxCalculator.calculateSingleTrade(
        buyPriceUsd: 100,
        sellPriceUsd: 200,
        shares: 0,
        buyExchangeRate: 1300,
        sellExchangeRate: 1300,
      );

      expect(result.buyTotalKrw, 0);
      expect(result.sellTotalKrw, 0);
      expect(result.gainKrw, 0);
      expect(result.gainUsd, 0);
      // buyTotalKrw is 0, so gainPct should be 0 (guarded by > 0 check)
      expect(result.gainPct, 0);
      expect(result.taxableGainKrw, 0);
      expect(result.estimatedTaxKrw, 0);
    });

    test('zero prices results in zero values', () {
      final result = TaxCalculator.calculateSingleTrade(
        buyPriceUsd: 0,
        sellPriceUsd: 0,
        shares: 10,
        buyExchangeRate: 1300,
        sellExchangeRate: 1300,
      );

      expect(result.buyTotalKrw, 0);
      expect(result.sellTotalKrw, 0);
      expect(result.gainKrw, 0);
      expect(result.gainUsd, 0);
      expect(result.gainPct, 0);
      expect(result.estimatedTaxKrw, 0);
    });
  });

  group('calculateAnnualTax', () {
    test('single profitable trade with exemption applied', () {
      // Gain of 3,000,000 KRW => taxable = 3,000,000 - 2,500,000 = 500,000
      final trade = TaxCalculator.calculateSingleTrade(
        buyPriceUsd: 100,
        sellPriceUsd: 130,
        shares: 100,
        buyExchangeRate: 1000,
        sellExchangeRate: 1000,
      );
      // gainKrw = (130 - 100) * 100 * 1000 = 3,000,000

      final annual = TaxCalculator.calculateAnnualTax(trades: [trade]);

      expect(annual.totalGainKrw, 3000000);
      expect(annual.totalLossKrw, 0);
      expect(annual.netGainKrw, 3000000);
      expect(annual.exemptionUsedKrw, 2500000);
      expect(annual.taxableGainKrw, 500000);
      // tax = 500,000 * 0.22 = 110,000
      expect(annual.estimatedTaxKrw, 110000);
      // afterTax = 3,000,000 - 110,000 = 2,890,000
      expect(annual.afterTaxGainKrw, 2890000);
      expect(annual.tradeCount, 1);
    });

    test('multiple trades with gains and losses offset each other', () {
      // Trade 1: gain of 5,000,000 KRW
      final gain = TaxCalculator.calculateSingleTrade(
        buyPriceUsd: 100,
        sellPriceUsd: 150,
        shares: 100,
        buyExchangeRate: 1000,
        sellExchangeRate: 1000,
      );
      // gainKrw = (150 - 100) * 100 * 1000 = 5,000,000

      // Trade 2: loss of 2,000,000 KRW
      final loss = TaxCalculator.calculateSingleTrade(
        buyPriceUsd: 200,
        sellPriceUsd: 180,
        shares: 100,
        buyExchangeRate: 1000,
        sellExchangeRate: 1000,
      );
      // gainKrw = (180 - 200) * 100 * 1000 = -2,000,000

      final annual = TaxCalculator.calculateAnnualTax(trades: [gain, loss]);

      expect(annual.totalGainKrw, 5000000);
      expect(annual.totalLossKrw, 2000000);
      // netGain = 5,000,000 - 2,000,000 = 3,000,000
      expect(annual.netGainKrw, 3000000);
      expect(annual.exemptionUsedKrw, 2500000);
      // taxable = 3,000,000 - 2,500,000 = 500,000
      expect(annual.taxableGainKrw, 500000);
      expect(annual.estimatedTaxKrw, 110000);
      expect(annual.tradeCount, 2);
    });

    test('gains under exemption threshold result in no tax', () {
      // Gain of 2,000,000 KRW (under 2,500,000 exemption)
      final trade = TaxCalculator.calculateSingleTrade(
        buyPriceUsd: 100,
        sellPriceUsd: 120,
        shares: 100,
        buyExchangeRate: 1000,
        sellExchangeRate: 1000,
      );
      // gainKrw = (120 - 100) * 100 * 1000 = 2,000,000

      final annual = TaxCalculator.calculateAnnualTax(trades: [trade]);

      expect(annual.totalGainKrw, 2000000);
      expect(annual.netGainKrw, 2000000);
      expect(annual.exemptionUsedKrw, 2000000);
      expect(annual.taxableGainKrw, 0);
      expect(annual.estimatedTaxKrw, 0);
      // afterTax = 2,000,000 - 0 = 2,000,000
      expect(annual.afterTaxGainKrw, 2000000);
    });

    test('large gains use exemption fully', () {
      // Gain of 10,000,000 KRW
      final trade = TaxCalculator.calculateSingleTrade(
        buyPriceUsd: 100,
        sellPriceUsd: 200,
        shares: 100,
        buyExchangeRate: 1000,
        sellExchangeRate: 1000,
      );
      // gainKrw = (200 - 100) * 100 * 1000 = 10,000,000

      final annual = TaxCalculator.calculateAnnualTax(trades: [trade]);

      expect(annual.totalGainKrw, 10000000);
      expect(annual.netGainKrw, 10000000);
      expect(annual.exemptionUsedKrw, 2500000);
      // taxable = 10,000,000 - 2,500,000 = 7,500,000
      expect(annual.taxableGainKrw, 7500000);
      // tax = 7,500,000 * 0.22 = 1,650,000
      expect(annual.estimatedTaxKrw, 1650000);
      // afterTax = 10,000,000 - 1,650,000 = 8,350,000
      expect(annual.afterTaxGainKrw, 8350000);
      expect(annual.tradeCount, 1);
    });

    test('all losses result in no tax and zero exemption used', () {
      final loss1 = TaxCalculator.calculateSingleTrade(
        buyPriceUsd: 200,
        sellPriceUsd: 150,
        shares: 10,
        buyExchangeRate: 1000,
        sellExchangeRate: 1000,
      );
      final loss2 = TaxCalculator.calculateSingleTrade(
        buyPriceUsd: 300,
        sellPriceUsd: 250,
        shares: 10,
        buyExchangeRate: 1000,
        sellExchangeRate: 1000,
      );

      final annual = TaxCalculator.calculateAnnualTax(trades: [loss1, loss2]);

      expect(annual.totalGainKrw, 0);
      expect(annual.totalLossKrw, 1000000); // 500,000 + 500,000
      expect(annual.netGainKrw, -1000000);
      expect(annual.exemptionUsedKrw, 0);
      expect(annual.taxableGainKrw, 0);
      expect(annual.estimatedTaxKrw, 0);
      expect(annual.tradeCount, 2);
    });

    test('empty trades list', () {
      final annual = TaxCalculator.calculateAnnualTax(trades: []);

      expect(annual.totalGainKrw, 0);
      expect(annual.totalLossKrw, 0);
      expect(annual.netGainKrw, 0);
      expect(annual.exemptionUsedKrw, 0);
      expect(annual.taxableGainKrw, 0);
      expect(annual.estimatedTaxKrw, 0);
      expect(annual.afterTaxGainKrw, 0);
      expect(annual.tradeCount, 0);
    });
  });

  group('estimateSellTax', () {
    test('delegates to calculateSingleTrade with same exchange rate', () {
      final estimated = TaxCalculator.estimateSellTax(
        avgBuyPriceUsd: 100,
        currentPriceUsd: 150,
        shares: 10,
        exchangeRate: 1300,
      );

      final direct = TaxCalculator.calculateSingleTrade(
        buyPriceUsd: 100,
        sellPriceUsd: 150,
        shares: 10,
        buyExchangeRate: 1300,
        sellExchangeRate: 1300,
      );

      expect(estimated.buyTotalKrw, direct.buyTotalKrw);
      expect(estimated.sellTotalKrw, direct.sellTotalKrw);
      expect(estimated.gainKrw, direct.gainKrw);
      expect(estimated.gainUsd, direct.gainUsd);
      expect(estimated.gainPct, direct.gainPct);
      expect(estimated.taxableGainKrw, direct.taxableGainKrw);
      expect(estimated.estimatedTaxKrw, direct.estimatedTaxKrw);
      expect(estimated.afterTaxGainKrw, direct.afterTaxGainKrw);
    });

    test('losing estimate has zero tax', () {
      final result = TaxCalculator.estimateSellTax(
        avgBuyPriceUsd: 200,
        currentPriceUsd: 150,
        shares: 5,
        exchangeRate: 1300,
      );

      expect(result.gainKrw, lessThan(0));
      expect(result.taxableGainKrw, 0);
      expect(result.estimatedTaxKrw, 0);
    });
  });
}
