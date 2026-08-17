import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// 구매 결과 — 실패 원인을 구체적으로 전달
enum PurchaseResult {
  success,
  notInitialized,
  noOffering,
  noPackage,
  cancelled,
  storeProblem,
  error,
}

/// RevenueCat 기반 IAP 구독 상태 관리
class SubscriptionProvider with ChangeNotifier {
  bool _isGoldActive = false;
  String? _activeProductId;
  DateTime? _expirationDate;
  bool _isLoading = false;
  String? _priceString; // 현지화된 가격 문자열

  // Trial (무료 체험) 상태
  bool _isTrialAvailable = false; // RevenueCat에서 체험 가능 여부
  bool _isOnTrial = false;        // 현재 체험 중

  // 초기화 상태 추적
  bool _initialized = false;
  bool _isInitializing = false;
  String? _initError;
  Completer<void>? _initCompleter; // 동시 호출자가 대기할 수 있도록

  bool get isGoldActive => _isGoldActive;
  String? get activeProductId => _activeProductId;
  DateTime? get expirationDate => _expirationDate;
  bool get isLoading => _isLoading;
  String? get priceString => _priceString;

  /// 무료 체험 가능 여부 (RevenueCat 기준 — 서버 has_used_trial은 별도 체크 필요)
  bool get isTrialAvailable => _isTrialAvailable;

  /// 현재 무료 체험 중 여부
  bool get isOnTrial => _isOnTrial;

  /// SDK 초기화 완료 여부
  bool get isInitialized => _initialized;

  /// SDK 초기화 진행 중 여부
  bool get isInitializing => _isInitializing;

  /// 마지막 초기화 에러 메시지
  String? get initError => _initError;

  /// RevenueCat SDK 초기화 (최대 [maxRetries]회 재시도, 시도당 30초 타임아웃)
  /// 동시 호출 시 Completer로 대기 — logIn()이 초기화 완료를 기다릴 수 있음
  Future<void> initialize({int maxRetries = 3}) async {
    if (_initialized) return;
    if (_isInitializing) {
      // 이미 초기화 진행 중 → 완료될 때까지 대기 (기존: 즉시 return → logIn 실패)
      debugPrint('[Subscription] ⏳ Initialization already in progress — waiting...');
      await _initCompleter?.future;
      return;
    }

    _isInitializing = true;
    _initError = null;
    _initCompleter = Completer<void>();
    notifyListeners();

    final apiKey = Platform.isIOS
        ? dotenv.env['REVENUECAT_IOS_API_KEY'] ?? ''
        : dotenv.env['REVENUECAT_ANDROID_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      debugPrint('[Subscription] API key not configured — check .env');
      _initError = 'API key not configured';
      _isInitializing = false;
      _initCompleter?.complete();
      _initCompleter = null;
      notifyListeners();
      return;
    }

    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      debugPrint('[Subscription] Initialization attempt $attempt/$maxRetries...');
      try {
        await Purchases.configure(PurchasesConfiguration(apiKey))
            .timeout(const Duration(seconds: 30));
        _initialized = true;
        _initError = null;
        _isInitializing = false;
        debugPrint('[Subscription] SDK initialized (attempt $attempt)');
        _initCompleter?.complete();
        _initCompleter = null;
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('[Subscription] SDK configure failed (attempt $attempt): $e');
        _initError = e.toString();
        if (attempt < maxRetries) {
          final delay = Duration(seconds: 2 * attempt); // 2s, 4s
          debugPrint('[Subscription] Retrying in ${delay.inSeconds}s...');
          await Future.delayed(delay);
        }
      }
    }

    _isInitializing = false;
    _initCompleter?.complete();
    _initCompleter = null;
    debugPrint('[Subscription] All $maxRetries initialization attempts failed');
    notifyListeners();
  }

  /// 미초기화 상태에서 재시도 (구매 시점 lazy init)
  Future<bool> _ensureInitialized() async {
    if (_initialized) return true;
    debugPrint('[Subscription] ⚠️ Not initialized at purchase time — attempting re-initialization...');
    await initialize(maxRetries: 3);
    return _initialized;
  }

  /// 로그인 시 RevenueCat 유저 식별 (미초기화 시 자동 초기화 후 진행)
  Future<void> logIn(String userId) async {
    if (!_initialized) {
      debugPrint('[Subscription] logIn called but not initialized — initializing first...');
      await initialize(maxRetries: 3);
      if (!_initialized) {
        debugPrint('[Subscription] ❌ logIn aborted — initialization failed');
        return;
      }
    }
    try {
      await Purchases.logIn(userId);
      await checkStatus();
    } catch (e) {
      debugPrint('[Subscription] logIn error: $e');
    }
  }

  /// 로그아웃 시 RevenueCat 유저 해제
  Future<void> logOut() async {
    if (!_initialized) return;
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('[Subscription] logOut error: $e');
    }
    _isGoldActive = false;
    _activeProductId = null;
    _expirationDate = null;
    _priceString = null;
    _isTrialAvailable = false;
    _isOnTrial = false;
    notifyListeners();
  }

  /// 현재 구독 상태 확인
  Future<void> checkStatus() async {
    if (!_initialized) return;
    try {
      final info = await Purchases.getCustomerInfo();
      _updateFromCustomerInfo(info);
    } catch (e) {
      debugPrint('[Subscription] checkStatus error: $e');
    }
  }

  /// Offerings에서 가격 정보 + 무료 체험 가능 여부 가져오기
  Future<void> fetchPriceString() async {
    if (!_initialized) return;
    try {
      final offerings = await Purchases.getOfferings();
      final package = offerings.current?.monthly;
      if (package != null) {
        _priceString = package.storeProduct.priceString;

        // Introductory price (무료 체험) 확인
        final intro = package.storeProduct.introductoryPrice;
        if (intro != null && intro.price == 0) {
          _isTrialAvailable = true;
        } else {
          _isTrialAvailable = false;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[Subscription] fetchPriceString error: $e');
    }
  }

  /// 구매 실행 — 실패 원인을 PurchaseResult로 반환
  Future<PurchaseResult> purchaseGold() async {
    debugPrint('[Subscription] purchaseGold() called — initialized=$_initialized, isInitializing=$_isInitializing');
    if (!await _ensureInitialized()) {
      debugPrint('[Subscription] Not initialized (even after retry). initError=$_initError');
      return PurchaseResult.notInitialized;
    }

    // RevenueCat 유저 미식별 시 재시도 (logIn 레이스 컨디션 대비)
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      debugPrint('[Subscription] Current RC user: ${customerInfo.originalAppUserId}');
    } catch (e) {
      debugPrint('[Subscription] getCustomerInfo failed: $e');
    }

    _isLoading = true;
    notifyListeners();
    try {
      debugPrint('[Subscription] Fetching offerings...');
      final offerings = await Purchases.getOfferings();
      debugPrint('[Subscription] offerings.current: ${offerings.current?.identifier}');
      debugPrint('[Subscription] available offerings: ${offerings.all.keys.toList()}');
      if (offerings.current == null) {
        debugPrint('[Subscription] No current offering set in RevenueCat');
        return PurchaseResult.noOffering;
      }
      final package = offerings.current?.monthly;
      debugPrint('[Subscription] monthly package: ${package?.storeProduct.identifier}');
      debugPrint('[Subscription] all packages: ${offerings.current!.availablePackages.map((p) => '${p.identifier}:${p.storeProduct.identifier}').toList()}');
      if (package == null) {
        debugPrint('[Subscription] No \$rc_monthly package in current offering');
        return PurchaseResult.noPackage;
      }
      debugPrint('[Subscription] Calling Purchases.purchasePackage() — StoreKit sheet should appear now');
      // 9.x: purchasePackage()가 CustomerInfo 대신 PurchaseResult(customerInfo+storeTransaction) 반환
      final purchaseResult = await Purchases.purchasePackage(package);
      final info = purchaseResult.customerInfo;
      debugPrint('[Subscription] Purchase done, entitlements: ${info.entitlements.all.keys.toList()}');
      _updateFromCustomerInfo(info);
      debugPrint('[Subscription] isGoldActive=$_isGoldActive, productId=$_activeProductId');
      return _isGoldActive ? PurchaseResult.success : PurchaseResult.error;
    } on PlatformException catch (e, stackTrace) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      debugPrint('[Subscription] PlatformException: code=$errorCode, msg=${e.message}');
      debugPrint('[Subscription] StackTrace: $stackTrace');
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseResult.cancelled;
      }
      if (errorCode == PurchasesErrorCode.storeProblemError ||
          errorCode == PurchasesErrorCode.purchaseNotAllowedError ||
          errorCode == PurchasesErrorCode.paymentPendingError) {
        return PurchaseResult.storeProblem;
      }
      return PurchaseResult.error;
    } catch (e, stackTrace) {
      debugPrint('[Subscription] Unexpected error: $e');
      debugPrint('[Subscription] StackTrace: $stackTrace');
      return PurchaseResult.error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 구매 복원
  Future<bool> restorePurchases() async {
    if (!_initialized) return false;
    _isLoading = true;
    notifyListeners();
    try {
      final info = await Purchases.restorePurchases();
      _updateFromCustomerInfo(info);
      return _isGoldActive;
    } catch (e) {
      debugPrint('[Subscription] restore error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// CustomerInfo → 상태 업데이트
  void _updateFromCustomerInfo(CustomerInfo info) {
    final ent = info.entitlements.all['MarketLens: AI Stock Analysis Pro'];
    _isGoldActive = ent?.isActive ?? false;
    _activeProductId = ent?.productIdentifier;

    // Trial 상태 확인
    _isOnTrial = (ent?.periodType == PeriodType.trial);

    if (ent?.expirationDate != null) {
      _expirationDate = DateTime.tryParse(ent!.expirationDate!);
    } else {
      _expirationDate = null;
    }
    notifyListeners();
  }

  /// OS 구독 관리 페이지 열기 (iOS: App Store, Android: Google Play)
  Future<void> openManagement() async {
    if (!_initialized) return;
    try {
      // CustomerInfo의 managementURL 우선 사용
      final info = await Purchases.getCustomerInfo();
      final url = info.managementURL;
      if (url != null && url.isNotEmpty) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        return;
      }
      // fallback: 플랫폼별 구독 관리 페이지
      final fallbackUrl = Platform.isIOS
          ? 'https://apps.apple.com/account/subscriptions'
          : 'https://play.google.com/store/account/subscriptions';
      await launchUrl(Uri.parse(fallbackUrl), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[Subscription] openManagement error: $e');
    }
  }

  /// 실시간 리스너 등록
  void setupListener(VoidCallback onChanged) {
    if (!_initialized) return;
    Purchases.addCustomerInfoUpdateListener((info) {
      _updateFromCustomerInfo(info);
      onChanged();
    });
  }
}
