import 'package:flutter/foundation.dart';

/// AI 채팅 페이지 ↔ 메인 하단 내비 사이의 경량 신호.
///
/// AI 채팅(분석) 서브탭에서는 하단 풀 탭바를 띄우지 않고, 입력창 왼쪽의 작은
/// 원형 버튼으로 탭바를 "접었다 폈다" 한다(입력창을 탭바 위로 무리하게 올리지
/// 않고 자연스러운 높이로 유지하기 위함). 서로 다른 위젯 트리(메인 Scaffold와
/// 채팅 화면)가 상태를 공유해야 해서 전역 [ValueNotifier]로 다리를 놓는다.

/// AI 탭 내부 "분석(채팅)" 서브탭이 현재 선택돼 있는지.
/// `AILensScreen`의 TabController가 갱신하고, `main.dart`가
/// `_currentIndex == 2`와 AND하여 "지금 채팅 페이지인가"를 판단한다.
final ValueNotifier<bool> aiChatSubTabActive = ValueNotifier<bool>(false);

/// 채팅 페이지의 접이식 내비가 펼쳐진 상태인지.
/// 입력창 왼쪽 원형 버튼이 토글하고, `main.dart`가 풀 탭바 오버레이를
/// 띄울지 판단한다. 탭 선택·스크림 탭 시 false로 되돌린다.
final ValueNotifier<bool> chatNavExpanded = ValueNotifier<bool>(false);
