import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ad_failure_reporter.dart';

/// 보상형 광고 매니저 (Rewarded Ad)
///
/// 포트폴리오 AI 분석 카드에서 광고 시청 후 블러 해제.
/// - 광고 시청 완료 시 onRewarded 콜백 호출
/// - 광고 실패 시 onFailed 콜백 호출 (무료 해제)
/// - 광고 시청 완료 후 자동으로 다음 광고 미리 로드
class RewardedAdHelper {
  RewardedAdHelper._();
  static final RewardedAdHelper instance = RewardedAdHelper._();

  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;

  bool get isAdLoaded => _isAdLoaded;

  /// 광고 미리 로드 (보유종목 탭 진입 시 호출)
  void preloadAd() {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    if (_isAdLoaded || _rewardedAd != null) return;

    // 디버그: Google 공식 테스트 광고 ID, 릴리스: 프로덕션 ID
    final adUnitId = kDebugMode
        ? (Platform.isAndroid
            ? 'ca-app-pub-3940256099942544/5224354917'
            : 'ca-app-pub-3940256099942544/1712485313')
        : (Platform.isAndroid
            ? dotenv.env['ADMOB_REWARDED_AD_UNIT_ID_ANDROID'] ?? ''
            : dotenv.env['ADMOB_REWARDED_AD_UNIT_ID_IOS'] ?? '');

    if (adUnitId.isEmpty) {
      debugPrint('[AdMob] 보상형 광고 ID가 설정되지 않았습니다.');
      return;
    }

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoaded = true;
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdMob] 보상형 광고 로드 실패: $error');
          _isAdLoaded = false;
          // 운영 알림: 광고 로드 실패를 백엔드에 보고(세션당 1회) → owner/매니저 통지 + owner 이메일
          AdFailureReporter.reportLoadAdError(error, adUnit: 'rewarded');
        },
      ),
    );
  }

  /// 광고 표시 + 콜백
  ///
  /// [onRewarded]: 광고 시청 완료 시 호출
  /// [onFailed]: 광고 로드 실패/표시 실패 시 호출
  void showAd({
    required VoidCallback onRewarded,
    required VoidCallback onFailed,
  }) {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      onFailed();
      return;
    }

    if (!_isAdLoaded || _rewardedAd == null) {
      onFailed();
      preloadAd(); // 다음을 위해 미리 로드 시도
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _isAdLoaded = false;
        preloadAd(); // 다음 광고 미리 로드
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdMob] 보상형 광고 표시 실패: $error');
        ad.dispose();
        _rewardedAd = null;
        _isAdLoaded = false;
        onFailed();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        onRewarded();
      },
    );
  }

  /// 보상형 광고를 await 가능한 형태로 표시.
  /// 반환값:
  ///   - true  → 사용자가 광고 끝까지 시청해 reward 획득
  ///   - false → 광고 미준비 / 표시 실패 / 사용자가 중도 닫음
  /// 호출자는 이 결과로 그 자리에서 후속 동작(예: 쿼터 충전 + 자동 재시도) 결정.
  Future<bool> showAdAndWait() {
    final completer = Completer<bool>();
    var rewarded = false;
    // 광고 미준비 시 곧장 false.
    if (!_isAdLoaded || _rewardedAd == null) {
      preloadAd();
      return Future.value(false);
    }
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _isAdLoaded = false;
        preloadAd();
        if (!completer.isCompleted) completer.complete(rewarded);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdMob] 보상형 광고 표시 실패(showAdAndWait): $error');
        ad.dispose();
        _rewardedAd = null;
        _isAdLoaded = false;
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        rewarded = true;
      },
    );
    return completer.future;
  }

  /// 리소스 정리 (앱 종료 시)
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isAdLoaded = false;
  }
}
