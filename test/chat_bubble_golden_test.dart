import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:marketlens/models/chat_message.dart';
import 'package:marketlens/screens/ai_lens/chat/chat_bubble.dart';
import 'package:marketlens/theme/app_colors.dart';

/// 실제 ChatBubble 위젯을 렌더해 골든 PNG로 캡처 — 색상/정렬/그림자 디자인 점검용.
/// (테스트 폰트라 글자는 박스로 보이지만, 색감·말풍선 모양·정렬·soft-shadow 확인 가능)
void main() {
  testWidgets('ChatBubble golden — user/assistant on grouped bg',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(380, 360));

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          extensions: const [MarketLensColors.light],
          scaffoldBackgroundColor: MarketLensColors.light.groupedBackground,
        ),
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ChatBubble(
                    message: ChatMessage(role: 'user', content: 'AAPL 어때?')),
                ChatBubble(
                    message: ChatMessage(
                        role: 'assistant',
                        content: '현재 점수 72점, 매수권고 구간입니다.')),
                ChatBubble(
                    message:
                        ChatMessage(role: 'user', content: '그럼 언제 팔아?')),
                ChatBubble(
                    message: ChatMessage(
                        role: 'assistant',
                        content: '타깃가 도달 시 분할 매도를 권합니다.')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/chat_bubbles.png'),
    );
  });
}
