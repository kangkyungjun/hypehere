import 'package:flutter/foundation.dart';
import '../models/recommendation.dart';
import '../services/recommendation_service.dart';

/// 추천종목 상태 관리 (Phase C). 투자 프로필 프로바이더 패턴과 동일.
class RecommendationProvider with ChangeNotifier {
  final RecommendationService _service = RecommendationService();

  RecommendationResult? _result;
  bool _isLoading = false;
  bool _hasChecked = false;

  RecommendationResult? get result => _result;
  List<RecommendedTicker> get items => _result?.items ?? const [];
  bool get isLoading => _isLoading;
  bool get hasChecked => _hasChecked;
  bool get hasItems => (_result?.items.isNotEmpty ?? false);

  /// 서버에서 추천 조회. 실패 시 기존 상태 유지.
  Future<void> fetch({DateTime? date}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _result = await _service.getRecommendations(date: date);
    } catch (e) {
      debugPrint('[RecommendationProvider] fetch error: $e');
      // 기존 _result 유지
    } finally {
      _hasChecked = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 로그아웃 시 상태 초기화.
  void clear() {
    _result = null;
    _hasChecked = false;
    _isLoading = false;
    notifyListeners();
  }
}
