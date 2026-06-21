import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ad_failure_reporter.dart';

/// App Open Ad manager shown once on app launch.
///
/// Loads and shows a Google AdMob App Open Ad when the app starts.
/// Gold+ users are excluded via [shouldHideAds] check in the caller.
class AppOpenAdHelper {
  AppOpenAdHelper._();
  static final AppOpenAdHelper instance = AppOpenAdHelper._();

  AppOpenAd? _appOpenAd;
  bool _isAdLoaded = false;
  bool _isLoading = false;
  bool _isShowing = false;
  Timer? _autoDismissTimer;

  /// Load the app open ad.
  void loadAd() {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    if (_isAdLoaded || _appOpenAd != null) return;

    final adUnitId = Platform.isAndroid
        ? (dotenv.env['ADMOB_APP_OPEN_AD_UNIT_ID_ANDROID'] ?? '')
        : (dotenv.env['ADMOB_APP_OPEN_AD_UNIT_ID_IOS'] ?? '');

    if (adUnitId.isEmpty) {
      debugPrint('[AdMob] App Open Ad ID not configured.');
      return;
    }

    final interstitialId = Platform.isAndroid
        ? (dotenv.env['ADMOB_INTERSTITIAL_AD_UNIT_ID_ANDROID'] ?? '')
        : (dotenv.env['ADMOB_INTERSTITIAL_AD_UNIT_ID_IOS'] ?? '');
    if (adUnitId == interstitialId) {
      debugPrint('[AdMob] App Open Ad ID == Interstitial ID — skip load (AdMob 콘솔에서 App Open 형식 단위를 별도 생성하세요)');
      return;
    }

    _isLoading = true;
    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isAdLoaded = true;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdMob] App Open Ad load failed: $error');
          _isAdLoaded = false;
          _isLoading = false;
          AdFailureReporter.reportLoadAdError(error, adUnit: 'app_open');
        },
      ),
    );
  }

  /// Show the app open ad. Calls [onComplete] when dismissed or if no ad.
  /// If ad is still loading, waits up to 3 seconds for it to finish.
  void showAdIfAvailable({VoidCallback? onComplete}) {
    if (_isShowing) {
      onComplete?.call();
      return;
    }

    if (!_isAdLoaded || _appOpenAd == null) {
      if (_isLoading) {
        // 광고 로딩 중이면 최대 3초 대기 후 재시도
        _waitForAdLoad(onComplete);
        return;
      }
      onComplete?.call();
      return;
    }

    _showAd(onComplete);
  }

  void _waitForAdLoad(VoidCallback? onComplete) {
    const maxWait = Duration(seconds: 3);
    const checkInterval = Duration(milliseconds: 300);
    var elapsed = Duration.zero;

    Timer.periodic(checkInterval, (timer) {
      elapsed += checkInterval;
      if (_isAdLoaded && _appOpenAd != null) {
        timer.cancel();
        _showAd(onComplete);
      } else if (elapsed >= maxWait) {
        timer.cancel();
        debugPrint('[AdMob] App Open Ad not loaded after ${maxWait.inSeconds}s wait');
        onComplete?.call();
      }
    });
  }

  void _showAd(VoidCallback? onComplete) {
    if (!_isAdLoaded || _appOpenAd == null || _isShowing) {
      onComplete?.call();
      return;
    }

    _isShowing = true;
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _autoDismissTimer?.cancel();
        _autoDismissTimer = null;
        ad.dispose();
        _appOpenAd = null;
        _isAdLoaded = false;
        _isShowing = false;
        onComplete?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _autoDismissTimer?.cancel();
        _autoDismissTimer = null;
        debugPrint('[AdMob] App Open Ad show failed: $error');
        ad.dispose();
        _appOpenAd = null;
        _isAdLoaded = false;
        _isShowing = false;
        onComplete?.call();
      },
    );

    _appOpenAd!.show();

    // 1초 후 자동 닫기
    _autoDismissTimer = Timer(const Duration(seconds: 3), () {
      if (_isShowing && _appOpenAd != null) {
        debugPrint('[AdMob] App Open Ad auto-dismissing after 3s');
        _appOpenAd!.dispose();
        _appOpenAd = null;
        _isAdLoaded = false;
        _isShowing = false;
        onComplete?.call();
      }
    });
  }

  void dispose() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _isAdLoaded = false;
  }
}
