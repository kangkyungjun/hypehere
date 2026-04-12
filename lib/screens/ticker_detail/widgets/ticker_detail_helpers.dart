import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

/// Recommendation badge color (consensus & summary cards)
Color getRecommendationColor(BuildContext context, String? rec) {
  switch (rec?.toLowerCase()) {
    case 'buy':
    case 'strong_buy':
    case 'outperform':
      return context.mlColors.gainColor;
    case 'hold':
    case 'neutral':
    case 'market_perform':
      return context.mlColors.warningColor;
    case 'sell':
    case 'strong_sell':
    case 'underperform':
      return context.mlColors.lossColor;
    default:
      return context.mlColors.neutralColor;
  }
}

/// Rating status color (analyst ratings)
Color getStatusColor(BuildContext context, String? status) {
  switch (status?.toLowerCase()) {
    case 'upgrade':
      return context.mlColors.gainColor;
    case 'downgrade':
      return context.mlColors.lossColor;
    case 'reiterated':
      return context.mlColors.accentBlue;
    case 'initiated':
      return Theme.of(context).colorScheme.tertiary;
    default:
      return context.mlColors.neutralColor;
  }
}

/// Translate recommendation (consensus badge)
String translateRecommendation(String? rec, AppLocalizations l10n) {
  switch (rec?.toLowerCase()) {
    case 'buy': return l10n.ratingBuy;
    case 'strong_buy': return l10n.ratingStrongBuy;
    case 'outperform': return l10n.ratingOutperform;
    case 'hold': return l10n.ratingHold;
    case 'neutral': return l10n.ratingNeutral;
    case 'market_perform': return l10n.ratingMarketPerform;
    case 'sell': return l10n.ratingSell;
    case 'strong_sell': return l10n.ratingStrongSell;
    case 'underperform': return l10n.ratingUnderperform;
    default: return rec?.toUpperCase() ?? '';
  }
}

/// Translate analyst status badge
String translateStatus(String? status, AppLocalizations l10n) {
  switch (status?.toLowerCase()) {
    case 'upgrade': return l10n.ratingActionUpgrade;
    case 'downgrade': return l10n.ratingActionDowngrade;
    case 'reiterated': return l10n.ratingActionReiterated;
    case 'initiated': return l10n.ratingActionInitiated;
    default: return status ?? '';
  }
}

/// Translate analyst rating label
String translateRating(String? rating, AppLocalizations l10n) {
  switch (rating?.toLowerCase()) {
    case 'buy': return l10n.ratingBuy;
    case 'strong buy': return l10n.ratingStrongBuy;
    case 'sell': return l10n.ratingSell;
    case 'strong sell': return l10n.ratingStrongSell;
    case 'hold': return l10n.ratingHold;
    case 'neutral': return l10n.ratingNeutral;
    case 'outperform': return l10n.ratingOutperform;
    case 'sector outperform': return l10n.ratingSectorOutperform;
    case 'underperform': return l10n.ratingUnderperform;
    case 'sector underperform': return l10n.ratingSectorUnderperform;
    case 'overweight': return l10n.ratingOverweight;
    case 'underweight': return l10n.ratingUnderweight;
    case 'equal-weight':
    case 'equal weight': return l10n.ratingEqualWeight;
    case 'market perform': return l10n.ratingMarketPerform;
    case 'sector perform': return l10n.ratingSectorPerform;
    case 'positive': return l10n.ratingPositive;
    case 'negative': return l10n.ratingNegative;
    default: return rating ?? '';
  }
}
