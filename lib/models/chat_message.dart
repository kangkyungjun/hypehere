/// AI 멀티턴 채팅 모델.
///
/// 서버(FastAPI:8001)가 정본(SoT)으로 보관하는 대화 메시지를 표현.
class ChatMessage {
  /// 'user' | 'assistant'
  final String role;
  final String content;

  /// 서버가 매기는 턴 순번(시간순). 로컬 낙관적 메시지는 null.
  final int? turnIndex;
  final DateTime? createdAt;

  /// 맥미니가 LLM 실패/timeout 시 보내는 폴백 메시지 플래그. 앱은 폴링 종료 + 에러 스타일.
  final bool isError;

  const ChatMessage({
    required this.role,
    required this.content,
    this.turnIndex,
    this.createdAt,
    this.isError = false,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: (json['role'] as String?) ?? 'assistant',
        content: (json['content'] as String?) ?? '',
        turnIndex: (json['turn_index'] as num?)?.toInt(),
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        isError: json['is_error'] == true,
      );
}

/// 대화 스레드 메타데이터 (목록/과거조회용).
class Conversation {
  final String id;
  final String? title;
  final String? lastMessage;
  final DateTime? updatedAt;

  const Conversation({
    required this.id,
    this.title,
    this.lastMessage,
    this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: (json['conversation_id'] ?? json['id'] ?? '').toString(),
        title: json['title'] as String?,
        lastMessage: json['last_message'] as String?,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'].toString())
            : null,
      );
}
