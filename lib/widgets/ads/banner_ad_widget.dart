import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';

/// 재사용 가능한 배너 광고 위젯
///
/// Google AdMob 배너 광고를 표시합니다.
/// 테스트 환경에서는 Google 제공 테스트 광고 ID를 사용합니다.
class BannerAdWidget extends StatefulWidget {
  /// 광고 크기 (기본: 320x50 배너)
  final AdSize adSize;

  const BannerAdWidget({
    super.key,
    this.adSize = AdSize.banner,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  /// 광고 로드
  void _loadAd() {
    // 웹 플랫폼에서는 광고 로드하지 않음
    if (!Platform.isAndroid && !Platform.isIOS) {
      debugPrint('[AdMob] 웹 플랫폼에서는 AdMob 배너 광고를 지원하지 않습니다.');
      return;
    }

    // 플랫폼별 광고 단위 ID 가져오기
    final adUnitId = Platform.isAndroid
        ? dotenv.env['ADMOB_BANNER_AD_UNIT_ID_ANDROID']!
        : dotenv.env['ADMOB_BANNER_AD_UNIT_ID_IOS']!;

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() => _isAdLoaded = true);
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdMob] 배너 광고 로드 실패: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 관리자가 광고를 OFF한 경우 숨김
    final authProvider = context.watch<AuthProvider>();
    if (!authProvider.adsEnabled) {
      return const SizedBox.shrink();
    }

    // 광고가 로드되지 않았으면 빈 공간 반환
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
