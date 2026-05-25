/// US stock tax calculator for Korean investors.
///
/// Tax formula: (sell_price * exchange_rate - buy_price * exchange_rate) * shares * 0.22
/// - 22% capital gains tax for Korean residents on foreign stock gains
/// - $2,500 annual exemption (250만원)
/// - All calculations done locally in Flutter (no server needed)
/// - Exchange rate fetched from server (ExchangeRate model)
class TaxCalculator {
  /// Capital gains tax rate for Korean residents on foreign stocks
  static const double taxRate = 0.22;

  /// Annual tax-free allowance in KRW (250만원)
  static const double annualExemptionKrw = 2500000;

  /// Calculate tax on a single transaction
  static TaxResult calculateSingleTrade({
    required double buyPriceUsd,
    required double sellPriceUsd,
    required double shares,
    required double buyExchangeRate,
    required double sellExchangeRate,
  }) {
    final buyTotalKrw = buyPriceUsd * shares * buyExchangeRate;
    final sellTotalKrw = sellPriceUsd * shares * sellExchangeRate;
    final gainKrw = sellTotalKrw - buyTotalKrw;
    final gainUsd = (sellPriceUsd - buyPriceUsd) * shares;

    // Tax only on positive gains
    final taxableGainKrw = gainKrw > 0 ? gainKrw : 0.0;
    final estimatedTaxKrw = taxableGainKrw * taxRate;

    return TaxResult(
      buyTotalKrw: buyTotalKrw,
      sellTotalKrw: sellTotalKrw,
      gainKrw: gainKrw,
      gainUsd: gainUsd,
      gainPct: buyTotalKrw > 0 ? (gainKrw / buyTotalKrw) * 100 : 0,
      taxableGainKrw: taxableGainKrw,
      estimatedTaxKrw: estimatedTaxKrw,
      afterTaxGainKrw: gainKrw - estimatedTaxKrw,
    );
  }

  /// Calculate total annual tax with exemption applied
  static AnnualTaxSummary calculateAnnualTax({
    required List<TaxResult> trades,
  }) {
    final totalGainKrw = trades.fold<double>(
        0, (sum, t) => sum + (t.gainKrw > 0 ? t.gainKrw : 0));
    final totalLossKrw = trades.fold<double>(
        0, (sum, t) => sum + (t.gainKrw < 0 ? t.gainKrw.abs() : 0));

    // Net gain after offsetting losses
    final netGainKrw = totalGainKrw - totalLossKrw;

    // Apply annual exemption
    final taxableAfterExemption =
        (netGainKrw - annualExemptionKrw).clamp(0.0, double.infinity);
    final totalTaxKrw = taxableAfterExemption * taxRate;

    return AnnualTaxSummary(
      totalGainKrw: totalGainKrw,
      totalLossKrw: totalLossKrw,
      netGainKrw: netGainKrw,
      exemptionUsedKrw:
          netGainKrw > 0 ? netGainKrw.clamp(0.0, annualExemptionKrw) : 0,
      taxableGainKrw: taxableAfterExemption,
      estimatedTaxKrw: totalTaxKrw,
      afterTaxGainKrw: netGainKrw - totalTaxKrw,
      tradeCount: trades.length,
    );
  }

  /// Quick estimate: "If I sell now, how much tax?"
  static TaxResult estimateSellTax({
    required double avgBuyPriceUsd,
    required double currentPriceUsd,
    required double shares,
    required double exchangeRate, // Current USD/KRW
  }) {
    return calculateSingleTrade(
      buyPriceUsd: avgBuyPriceUsd,
      sellPriceUsd: currentPriceUsd,
      shares: shares,
      buyExchangeRate: exchangeRate, // Simplified: same rate for buy/sell
      sellExchangeRate: exchangeRate,
    );
  }
}

class TaxResult {
  final double buyTotalKrw;
  final double sellTotalKrw;
  final double gainKrw;
  final double gainUsd;
  final double gainPct;
  final double taxableGainKrw;
  final double estimatedTaxKrw;
  final double afterTaxGainKrw;

  TaxResult({
    required this.buyTotalKrw,
    required this.sellTotalKrw,
    required this.gainKrw,
    required this.gainUsd,
    required this.gainPct,
    required this.taxableGainKrw,
    required this.estimatedTaxKrw,
    required this.afterTaxGainKrw,
  });
}

class AnnualTaxSummary {
  final double totalGainKrw;
  final double totalLossKrw;
  final double netGainKrw;
  final double exemptionUsedKrw;
  final double taxableGainKrw;
  final double estimatedTaxKrw;
  final double afterTaxGainKrw;
  final int tradeCount;

  AnnualTaxSummary({
    required this.totalGainKrw,
    required this.totalLossKrw,
    required this.netGainKrw,
    required this.exemptionUsedKrw,
    required this.taxableGainKrw,
    required this.estimatedTaxKrw,
    required this.afterTaxGainKrw,
    required this.tradeCount,
  });
}
