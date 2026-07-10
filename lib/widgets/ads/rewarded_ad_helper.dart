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

  /// 광고 표시 + 콜백 (방탄 처리)
  ///
  /// [onRewarded]: 광고 시청 완료 시 호출
  /// [onFailed]: 광고 로드 실패/표시 실패 시 호출
  ///
  /// 핵심 보장: 어떤 경로로도 사용자가 잠긴 채 멈추지 않는다.
  ///   - 광고 불가 환경/미로딩 → 즉시 onFailed(무료 해제)
  ///   - 광고 표시 성공 → 닫힘(onAdDismissed) 시 onRewarded (보상 이벤트 누락에도 안전)
  ///   - 광고 표시 실패(onAdFailedToShow) → onFailed
  ///   - show()가 아무 콜백도 내지 않고 멈춤(만료된 광고 등) → 안전 타이머로 onFailed
  /// onRewarded/onFailed 는 정확히 한 번만 호출된다.
  void showAd({
    required VoidCallback onRewarded,
    required VoidCallback onFailed,
  }) {
    // 광고가 불가능한 환경: 막지 말고 즉시 무료 해제.
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      debugPrint('[AdMob][rewarded] 광고 불가 환경 → 즉시 해제');
      onFailed();
      return;
    }

    // 광고 미로딩(노필/미설정 등): 막지 말고 즉시 해제 + 다음을 위해 프리로드.
    if (!_isAdLoaded || _rewardedAd == null) {
      debugPrint('[AdMob][rewarded] 광고 미로딩 → 즉시 해제 + 프리로드');
      onFailed();
      preloadAd();
      return;
    }

    // 이 광고 인스턴스는 1회용. 참조를 즉시 비워 중복 표시/재사용을 막는다.
    final ad = _rewardedAd!;
    _rewardedAd = null;
    _isAdLoaded = false;

    var settled = false; // onRewarded/onFailed 중복 호출 방지
    var didShow = false; // 실제 전체화면 표시 여부

    void settleRewarded() {
      if (settled) return;
      settled = true;
      onRewarded();
    }

    void settleFailed() {
      if (settled) return;
      settled = true;
      onFailed();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        didShow = true;
        debugPrint('[AdMob][rewarded] 광고 표시됨');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdMob][rewarded] 광고 닫힘 → 해제');
        ad.dispose();
        preloadAd();
        // 광고를 봤으므로 콘텐츠를 연다(보상 이벤트가 누락돼도 안전).
        settleRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdMob][rewarded] 광고 표시 실패: $error → 해제');
        ad.dispose();
        preloadAd();
        settleFailed();
      },
    );

    ad.show(
      onUserEarnedReward: (ad, reward) {
        // 보상 획득은 로그만; 실제 해제는 onAdDismissed 에서 처리(항상 호출됨).
        debugPrint('[AdMob][rewarded] 보상 획득: ${reward.amount} ${reward.type}');
      },
    );

    // 안전장치: show() 후에도 광고가 실제로 표시되지 않고(표시/실패 콜백 모두 없음)
    // 멈춘 경우(만료된 광고 등) 사용자를 막지 않도록 무료 해제.
    // 표시가 되면 didShow=true 라 이 타이머는 아무 일도 하지 않는다.
    Future.delayed(const Duration(seconds: 3), () {
      if (!didShow && !settled) {
        debugPrint('[AdMob][rewarded] 광고 무응답(표시 안 됨) → 안전 해제');
        preloadAd();
        settleFailed();
      }
    });
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
