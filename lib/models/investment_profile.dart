class InvestmentProfile {
  final String investmentStyle;
  final String timeHorizon;
  final int riskTolerance;
  final int targetReturn;
  final int maxLossTolerance;

  const InvestmentProfile({
    required this.investmentStyle,
    required this.timeHorizon,
    required this.riskTolerance,
    required this.targetReturn,
    required this.maxLossTolerance,
  });

  factory InvestmentProfile.defaultProfile() {
    return const InvestmentProfile(
      investmentStyle: 'balanced',
      timeHorizon: 'medium',
      riskTolerance: 3,
      targetReturn: 10,
      maxLossTolerance: -20,
    );
  }

  factory InvestmentProfile.fromJson(Map<String, dynamic> json) {
    return InvestmentProfile(
      investmentStyle: json['investment_style'] as String? ?? 'balanced',
      timeHorizon: json['time_horizon'] as String? ?? 'medium',
      riskTolerance: json['risk_tolerance'] as int? ?? 3,
      targetReturn: json['target_return'] as int? ?? 10,
      maxLossTolerance: json['max_loss_tolerance'] as int? ?? -20,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'investment_style': investmentStyle,
      'time_horizon': timeHorizon,
      'risk_tolerance': riskTolerance,
      'target_return': targetReturn,
      'max_loss_tolerance': maxLossTolerance,
    };
  }

  InvestmentProfile copyWith({
    String? investmentStyle,
    String? timeHorizon,
    int? riskTolerance,
    int? targetReturn,
    int? maxLossTolerance,
  }) {
    return InvestmentProfile(
      investmentStyle: investmentStyle ?? this.investmentStyle,
      timeHorizon: timeHorizon ?? this.timeHorizon,
      riskTolerance: riskTolerance ?? this.riskTolerance,
      targetReturn: targetReturn ?? this.targetReturn,
      maxLossTolerance: maxLossTolerance ?? this.maxLossTolerance,
    );
  }
}
