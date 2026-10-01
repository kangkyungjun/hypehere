import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketlens/exceptions/api_error_codes.dart';
import 'package:marketlens/exceptions/api_exception.dart';
import 'package:marketlens/l10n/app_localizations.dart';
import 'package:marketlens/theme/app_colors.dart';
import 'package:marketlens/widgets/common/data_unavailable_view.dart';

/// 실패 화면 계약.
///
/// 사용자 지적: "정보 없을 때 뜨는 화면이 너무 비전문적이다."
///
/// 개편 전 문제는 셋이었다:
///  1. 네트워크 끊김·서버 오류·이 종목만 없음이 **전부 같은 빨간 느낌표**
///  2. 빈 상태 문구가 `다른 티커를 검색해보세요` — 추천 카드를 탭해 들어온
///     사용자에게 **검색 맥락**의 안내가 떴다
///  3. 에러는 `ErrorStateView`, 빈 상태는 손수 만든 컬럼 — 같은 화면의 두
///     실패 경로가 디자인이 달랐다
void main() {
  group('상황 판정', () {
    test('네트워크·타임아웃 → offline (사용자가 고칠 수 있다)', () {
      for (final code in [
        ApiErrorCode.timeout10s,
        ApiErrorCode.timeout15s,
        ApiErrorCode.networkFailed,
        ApiErrorCode.serverConnection,
        ApiErrorCode.serverConnectionShort,
      ]) {
        expect(
          DataUnavailableView.kindOf(ApiException(code)),
          UnavailableKind.offline,
          reason: '$code',
        );
      }
    });

    test('404 계열 → notReady (고장이 아니라 부재다)', () {
      expect(
        DataUnavailableView.kindOf(TickerNotFoundException(ticker: 'BE')),
        UnavailableKind.notReady,
      );
      expect(
        DataUnavailableView.kindOf(ApiException(ApiErrorCode.notFound)),
        UnavailableKind.notReady,
      );
    });

    test('나머지·알 수 없는 예외 → serverError', () {
      expect(
        DataUnavailableView.kindOf(ApiException(ApiErrorCode.serverError)),
        UnavailableKind.serverError,
      );
      expect(
        DataUnavailableView.kindOf(StateError('???')),
        UnavailableKind.serverError,
      );
    });
  });

  Widget harness(Widget child, {double scale = 1.0}) => MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(extensions: const [MarketLensColors.light]),
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Scaffold(body: child),
        ),
      );

  testWidgets('데이터 부재에는 "다시 시도"를 주지 않는다', (tester) async {
    await tester.pumpWidget(harness(
      DataUnavailableView.fromError(
        TickerNotFoundException(ticker: 'BE'),
        subject: 'BE',
        onRetry: () {},
        onBack: () {},
      ),
    ));
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    // 다시 눌러도 결과가 같다 — 버튼을 주면 사용자가 헛되이 반복한다.
    expect(find.text(l10n.tryAgain), findsNothing);
    expect(find.text(l10n.unavailableGoBack), findsOneWidget);
  });

  testWidgets('연결 문제에는 "다시 시도"를 준다', (tester) async {
    await tester.pumpWidget(harness(
      DataUnavailableView.fromError(
        ApiException(ApiErrorCode.networkFailed),
        onRetry: () {},
      ),
    ));
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    expect(find.text(l10n.tryAgain), findsOneWidget);
  });

  testWidgets('데이터 부재 문구에 "오류"가 들어가지 않는다', (tester) async {
    await tester.pumpWidget(harness(
      const DataUnavailableView(
        kind: UnavailableKind.notReady,
        subject: 'BE',
      ),
    ));
    // 멀쩡한 앱을 고장난 것으로 오해시키면 안 된다.
    expect(find.textContaining('오류'), findsNothing);
    expect(find.textContaining('BE'), findsOneWidget);
  });

  testWidgets('개발자용 상세는 평소에 노출되지 않는다', (tester) async {
    await tester.pumpWidget(harness(
      const DataUnavailableView(
        kind: UnavailableKind.serverError,
        detail: 'ApiException(serverError): 500 at /chart',
      ),
    ));
    expect(find.textContaining('ApiException'), findsNothing);
  });

  for (final scale in [0.8, 1.0, 1.3]) {
    testWidgets('오버플로 없음 — textScaler $scale', (tester) async {
      await tester.pumpWidget(harness(
        DataUnavailableView.fromError(
          ApiException(ApiErrorCode.serverError),
          subject: 'GOOGL',
          onRetry: () {},
          onReport: () {},
          onBack: () {},
        ),
        scale: scale,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
