@Tags(['capture'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketlens/l10n/app_localizations.dart';
import 'package:marketlens/models/indices_data.dart';
import 'package:marketlens/models/macro_data.dart';
import 'package:marketlens/models/treemap_data.dart';
import 'package:marketlens/theme/app_colors.dart';
import 'package:marketlens/theme/app_spacing.dart';
import 'package:marketlens/widgets/charts/macro_banner_widget.dart';
import 'package:marketlens/widgets/common/bento_card.dart';
import 'package:marketlens/widgets/dashboard/indices_bar_widget.dart';
import 'package:marketlens/widgets/dashboard/macro_strip_widget.dart';
import 'package:marketlens/widgets/dashboard/recommendation_grid.dart';
import 'package:marketlens/widgets/dashboard/sector_bar_chart_widget.dart';

/// 디자인 검토용 스크린샷 생성기 (검증 테스트가 아니다).
///
/// 시뮬레이터가 Xcode 라이선스로 막혀 있어도 **아이폰 16 Pro 논리 해상도
/// (402×874 @3x)** 로 실제 위젯을 렌더해 PNG를 남긴다. 목데이터를 쓰므로
/// 로그인·네트워크가 필요 없고, 라이트/다크 × 1.0/1.3배를 한 번에 뽑는다.
///
/// ```
/// flutter test test/capture_screens_test.dart --tags capture
/// ```
/// 결과: `build/screens/*.png`
void main() {
  const w = 402.0, h = 874.0;
  final outDir = Directory('build/screens');

  setUpAll(() async {
    if (!outDir.existsSync()) outDir.createSync(recursive: true);
    final loader = FontLoader('Pretendard');
    for (final f in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(Future.value(ByteData.view(
        File('assets/fonts/Pretendard-$f.otf').readAsBytesSync().buffer,
      )));
    }
    await loader.load();
  });

  // ── 목데이터 ────────────────────────────────────────────────────────────
  MarketIndexData idx(String code, String name, double close, double pct) =>
      MarketIndexData(
        code: code,
        name: name,
        close: close,
        prevClose: close * (1 - pct / 100),
        change: close * pct / 100,
        changePct: pct,
        chart: [
          for (var i = 0; i < 30; i++)
            IndexChartPoint(
              date: '2026-09-${(i % 30) + 1}',
              close: close * (1 + 0.004 * ((i * 7) % 11 - 5)),
            ),
        ],
      );

  final indices = MarketIndicesData(date: '2026-09-30', indices: [
    idx('DIA', 'Dow Jones', 43535.06, -0.03),
    idx('QQQ', 'NASDAQ 100', 20716.43, -0.65),
    idx('SPY', 'S&P 500', 6769.35, -0.23),
  ]);

  final signals = MacroSignalsData(date: '2026-09-30', signals: [
    MacroSignal(
      signalCode: 'overall_macro',
      value: 1,
      riskLevel: 'low',
      message: '거시경제 전반적으로 안정적. 정상 투자 유지.',
      date: '2026-09-30',
    ),
  ]);

  final vix = MacroIndicator(
    indicatorCode: 'VIXCLS',
    indicatorName: 'VIX',
    value: 14.21,
    changePct: 0.0,
    high3m: 16.1,
    avg3m: 16.1,
  );
  final tnx = MacroIndicator(
    indicatorCode: 'DGS10',
    indicatorName: '10년물 국채금리',
    value: 5.18,
  );

  TreemapItem it(String t, String ko, double score, double close, double pct) =>
      TreemapItem(
        ticker: t,
        nameKo: ko,
        name: ko,
        score: score,
        close: close,
        changePct: pct,
        tradingValue: 1e9,
      );

  final recos = [
    it('PANW', '팔로알토 네트웍스', 71, 392.09, -1.23),
    it('ZS', '주식회사 지스케일러', 66, 199.39, 0.84),
    it('SNDK', '샌디스크', 68, 88.12, 2.10),
    it('BE', '블룸 에너지', 65, 41.55, -0.42),
  ];

  final sectors = [
    ('Health Care', 0.4),
    ('Consumer Staples', 0.2),
    ('Energy', -0.9),
    ('Industrials', -1.1),
    ('Real Estate', -1.2),
    ('Communication Services', -1.3),
    ('Consumer Discretionary', -1.4),
  ]
      .map((e) => TreemapSector(
            sector: e.$1,
            tickerCount: 30,
            avgChangePct: e.$2,
            items: const [],
          ))
      .toList();

  // ── 화면 조립 ───────────────────────────────────────────────────────────
  Widget homeToday() => ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        // `dashboard_screen.dart:272-380`의 조립을 그대로 옮긴 것이다.
        // (광고·로딩 분기만 뺐다)
        children: [
          BentoCard(
            padding: EdgeInsets.zero,
            child: MacroBannerWidget(signals: signals),
          ),
          const SizedBox(height: AppDensity.cardGap),
          MacroStripWidget(vix: vix, treasury10y: tnx),
          const SizedBox(height: AppDensity.cardGap),
          IndicesBarWidget(data: indices),
          const SizedBox(height: AppDensity.cardGap),
          BentoCard(child: SectorBarChartWidget(sectors: sectors, onTap: () {})),
          Padding(
            padding: const EdgeInsets.only(top: AppDensity.sectionGap),
            child: RecommendationGrid(items: recos, onTickerTap: (_) {}),
          ),
        ],
      );

  Widget app(Widget body, {required bool dark, required double scale}) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        useMaterial3: true,
        brightness: dark ? Brightness.dark : Brightness.light,
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: dark
            ? MarketLensColors.dark.groupedBackground
            : MarketLensColors.light.groupedBackground,
        extensions: [dark ? MarketLensColors.dark : MarketLensColors.light],
      ),
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(w, h),
          textScaler: TextScaler.linear(scale),
        ),
        child: Scaffold(body: SafeArea(child: body)),
      ),
    );
  }

  Future<void> shoot(WidgetTester tester, String name, Widget child) async {
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key: key, child: child));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('${outDir.path}/$name.png').writeAsBytesSync(
      bytes!.buffer.asUint8List(),
    );
  }

  final variants = [
    ('light-1.0x', false, 1.0),
    ('light-1.3x', false, 1.3),
    ('dark-1.0x', true, 1.0),
  ];

  for (final v in variants) {
    testWidgets('capture home ${v.$1}', (tester) async {
      tester.view.physicalSize = const Size(w * 3, h * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await shoot(
        tester,
        'home-${v.$1}',
        app(homeToday(), dark: v.$2, scale: v.$3),
      );
    });
  }
}
