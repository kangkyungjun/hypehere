@Tags(['capture'])
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/screen_harness.dart';

/// 디자인 검토용 스크린샷 생성기 (검증 테스트가 아니다).
///
/// 시뮬레이터가 Xcode 라이선스로 막혀 있어도 **아이폰 16 Pro 논리 해상도
/// (402×874 @3x)** 로 실제 위젯을 렌더해 PNG를 남긴다.
///
/// ```
/// flutter test test/capture_screens_test.dart --tags capture --run-skipped
/// ```
/// 결과: `build/screens/*.png`
///
/// ⚠️ `--run-skipped`가 필요하다. `dart_test.yaml`의 `skip:`은 `--tags`보다
///    우선이라 `--tags capture`만으로는 실행되지 않는다.
///
/// 화면 조립은 `support/screen_harness.dart`에 있다 — `overflow_sweep_test`와
/// **같은 것**을 렌더해야 캡쳐와 검증이 어긋나지 않는다.
void main() {
  final outDir = Directory('build/screens');
  late ScreenHarness harness;

  setUpAll(() async {
    mockPlatformChannels();
    if (!outDir.existsSync()) outDir.createSync(recursive: true);
    await loadAppFont();
    harness = ScreenHarness();
  });

  Future<void> shoot(WidgetTester tester, String name, Widget child) async {
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key: key, child: child));
    // ⚠️ `pumpAndSettle`을 쓰지 않는다. 첫 인자는 타임아웃이 아니라 펌프
    // 간격이고, 기본 타임아웃은 가짜시계 10분이다. 프레임을 계속 스케줄하는
    // 위젯이 하나라도 있으면 변이마다 10분을 태운다(실제로 그랬다).
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;

    // ⚠️ `toImage`/`toByteData`는 엔진 콜백으로 완료되므로 **실제 비동기**가
    // 필요하다. 가짜 비동기 존에서 await하면 PNG는 쓰이지만 Future가 영영
    // 안 풀려 10분 타임아웃까지 매달린다(CPU 0%로 순수 대기).
    late final Uint8List png;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 3.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      png = data!.buffer.asUint8List();
      image.dispose();
    });

    File('${outDir.path}/$name.png').writeAsBytesSync(png);
  }

  const variants = [
    ('light-1.0x', false, 1.0),
    ('light-1.3x', false, 1.3),
    ('dark-1.0x', true, 1.0),
  ];

  for (final v in variants) {
    for (final entry in ScreenHarness().screens.entries) {
      testWidgets('capture ${entry.key} ${v.$1}', (tester) async {
        tester.view.physicalSize = const Size(screenW * 3, screenH * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.reset);
        await shoot(
          tester,
          '${entry.key}-${v.$1}',
          harness.app(
            harness.screens[entry.key]!(),
            dark: v.$2,
            scale: v.$3,
          ),
        );
      });
    }
  }
}
