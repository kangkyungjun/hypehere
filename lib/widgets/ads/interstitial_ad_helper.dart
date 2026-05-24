import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart';
import '../../providers/auth_provider.dart';

/// 전면 광고 매니저 (Interstitial Ad)
///
/// 종목 상세 화면에서 3번째 조회마다 뒤로가기 시 1회 표시.
/// - 세션당 최대 2회
/// - 최소 3분 간격
/// - Gold+ 유저는 광고 미표시
class InterstitialAdHelper {
  InterstitialAdHelper._();
  static final InterstitialAdHelper instance = InterstitialAdHelper._();

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  /// 세션 내 종목 상세 조회 횟수
  int _tickerViewCount = 0;

  /// 세션 내 전면 광고 표시 횟수
  int _sessionAdShowCount = 0;

  /// 마지막 전면 광고 표시 시각
  DateTime? _lastAdShownAt;

  /// 세션당 최대 전면 광고 표시 횟수
  static const int _maxAdsPerSession = 2;

  /// 최소 광고 간격 (3분)
  static const Duration _minAdInterval = Duration(minutes: 3);

  /// 종목 N회 조회마다 광고 표시
  static const int _viewsPerAd = 3;

  /// 종목 상세 진입 시 호출 — 카운트 증가 + 광고 미리 로드
  void onTickerDetailViewed() {
    _tickerViewCount++;
    _preloadAd();
  }

  /// 종목 상세에서 뒤로가기 시 호출 — 조건 충족 시 광고 표시
  ///
  /// Returns true if ad was shown, false otherwise.
  bool tryShowAd(BuildContext context) {
    // 웹 플랫폼 체크
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return false;

    // Gold: 항상 미표시 / Manager·Master: 토글로 제어 / Regular: 항상 표���
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.shouldHideAds) return false;

    // 조건 검사
    if (!_shouldShowAd()) return false;

    // 광고 표시
    if (_isAdLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _isAdLoaded = false;
          _preloadAd(); // 다음 광고 미리 로드
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('[AdMob] 전면 광고 표시 실패: $error');
          ad.dispose();
          _interstitialAd = null;
          _isAdLoaded = false;
        },
      );

      _interstitialAd!.show();
      _sessionAdShowCount++;
      _lastAdShownAt = DateTime.now();
      _tickerViewCount = 0; // 카운트 리셋
      return true;
    }

    return false;
  }

  /// 광고 표시 조건 충족 여부
  bool _shouldShowAd() {
    // 세션당 최대 횟수 초과
    if (_sessionAdShowCount >= _maxAdsPerSession) return false;

    // 종목 조회 횟수 부족
    if (_tickerViewCount < _viewsPerAd) return false;

    // 최소 간격 미충족
    if (_lastAdShownAt != null) {
      final elapsed = DateTime.now().difference(_lastAdShownAt!);
      if (elapsed < _minAdInterval) return false;
    }

    return true;
  }

  /// 전면 광고 미리 로드
  void _preloadAd() {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    if (_isAdLoaded || _interstitialAd != null) return;
    if (_sessionAdShowCount >= _maxAdsPerSession) return;

    final adUnitId = Platform.isAndroid
        ? dotenv.env['ADMOB_INTERSTITIAL_AD_UNIT_ID_ANDROID'] ?? ''
        : dotenv.env['ADMOB_INTERSTITIAL_AD_UNIT_ID_IOS'] ?? '';

    if (adUnitId.isEmpty) {
      debugPrint('[AdMob] 전면 광고 ID가 설정되지 않았습니다.');
      return;
    }

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdMob] 전면 광고 로드 실패: $error');
          _isAdLoaded = false;
        },
      ),
    );
  }

  /// 리소스 정리 (앱 종료 시)
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdLoaded = false;
  }
}
