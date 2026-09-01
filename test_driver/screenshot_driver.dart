import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// `integration_test/screenshot_test.dart`가 찍은 이미지를 파일로 떨군다.
///
/// 저장 위치: `fastlane/screenshots/_raw/<name>.png` (기기 프레임 없음).
/// 프레임은 `tool/frame_screenshots.dart`가 씌운다 — 캡처와 후처리를 분리해야
/// 프레임 규격만 바꿀 때 앱을 다시 돌리지 않아도 된다.
Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      final dir = Directory('fastlane/screenshots/_raw');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final f = File('${dir.path}/$name.png');
      f.writeAsBytesSync(bytes);
      stdout.writeln('  saved ${f.path} (${bytes.length ~/ 1024}KB)');
      return true;
    },
  );
}
