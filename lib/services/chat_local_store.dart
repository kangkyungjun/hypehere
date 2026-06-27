import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/chat_message.dart';

/// AI 채팅 로컬 캐시 (sqflite).
///
/// **저장 정책**
/// - 서버가 정본(SoT). 로컬은 "내 폰에서 빠르게 보고 + 오프라인 표시" 용도.
/// - 사용자가 "이 대화 폰에서 숨기기"를 선택하면 hidden=1 (서버에는 그대로 남음).
/// - 대화 수가 한도(`maxConversations`)를 넘으면 가장 오래 안 쓴 대화부터 자동 삭제.
///   → 서버에는 영구 보관되므로 학습/개인화 자료는 손실 없음.
///
/// **스키마**
/// - `conversations(id PK, title, last_message, last_message_at, hidden, created_at)`
/// - `chat_messages(conversation_id, turn_index, role, content, is_error, created_at,
///    PK(conversation_id, turn_index))`
class ChatLocalStore {
  static final ChatLocalStore instance = ChatLocalStore._();
  ChatLocalStore._();

  static const _dbName = 'chat_cache.db';
  static const _dbVersion = 1;

  Database? _db;
  Future<Database>? _opening;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    _opening ??= _open();
    _db = await _opening!;
    _opening = null;
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE conversations (
            id TEXT PRIMARY KEY,
            title TEXT,
            last_message TEXT,
            last_message_at INTEGER,
            hidden INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE chat_messages (
            conversation_id TEXT NOT NULL,
            turn_index INTEGER NOT NULL,
            role TEXT NOT NULL,
            content TEXT NOT NULL,
            is_error INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            PRIMARY KEY (conversation_id, turn_index)
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_conv_last ON conversations(last_message_at DESC)',
        );
      },
    );
  }

  // ── 대화 목록 ──

  /// 로컬에 저장된 대화 목록(숨김 제외). 최신순.
  Future<List<Conversation>> listConversations() async {
    final db = await _database;
    final rows = await db.query(
      'conversations',
      where: 'hidden = 0',
      orderBy: 'COALESCE(last_message_at, created_at) DESC',
    );
    return rows.map(_rowToConversation).toList(growable: false);
  }

  /// 숨김 포함 전체 대화 ID 목록(머지 시 hidden 판단용).
  Future<Set<String>> hiddenConversationIds() async {
    final db = await _database;
    final rows =
        await db.query('conversations', columns: ['id'], where: 'hidden = 1');
    return rows.map((r) => r['id'] as String).toSet();
  }

  /// 한 대화의 메시지 시간순.
  Future<List<ChatMessage>> messagesOf(String conversationId) async {
    final db = await _database;
    final rows = await db.query(
      'chat_messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'turn_index ASC',
    );
    return rows.map(_rowToMessage).toList(growable: false);
  }

  // ── 쓰기 ──

  /// 서버에서 받은 메시지 리스트로 한 대화를 **통째 교체**(서버=SoT).
  /// title/last_message 미리보기를 자동 갱신하고, [maxConversations] 한도를 적용한다.
  ///
  /// [maxConversations] 0 이하 = 무제한.
  Future<void> replaceConversation(
    String conversationId,
    List<ChatMessage> messages, {
    String? serverTitle,
    int maxConversations = 0,
  }) async {
    if (messages.isEmpty) return; // 빈 대화는 저장 안 함
    final db = await _database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // 미리보기: 마지막 메시지의 앞 80자.
    final preview = _shorten(messages.last.content, 80);
    // 제목 후보: 서버 제공 > 첫 user 메시지 앞 24자.
    String? title = serverTitle;
    if (title == null || title.isEmpty) {
      final firstUser = messages.firstWhere(
        (m) => m.isUser,
        orElse: () => messages.first,
      );
      title = _shorten(firstUser.content, 24);
    }
    final lastAt =
        messages.last.createdAt?.millisecondsSinceEpoch ?? nowMs;

    await db.transaction((tx) async {
      // 신규면 created_at = 첫 메시지(서버) 또는 now.
      final existing = await tx.query(
        'conversations',
        where: 'id = ?',
        whereArgs: [conversationId],
        limit: 1,
      );
      final createdAt = existing.isEmpty
          ? (messages.first.createdAt?.millisecondsSinceEpoch ?? nowMs)
          : existing.first['created_at'] as int;
      final hiddenFlag =
          existing.isEmpty ? 0 : (existing.first['hidden'] as int? ?? 0);

      await tx.insert(
        'conversations',
        {
          'id': conversationId,
          'title': title,
          'last_message': preview,
          'last_message_at': lastAt,
          'hidden': hiddenFlag,
          'created_at': createdAt,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 메시지: 한 대화의 기존 row 전부 지우고 다시 넣기(서버=SoT).
      await tx.delete(
        'chat_messages',
        where: 'conversation_id = ?',
        whereArgs: [conversationId],
      );
      for (var i = 0; i < messages.length; i++) {
        final m = messages[i];
        // 서버가 turn_index를 주면 그대로, 없으면 인덱스로.
        final ti = m.turnIndex ?? i;
        await tx.insert('chat_messages', {
          'conversation_id': conversationId,
          'turn_index': ti,
          'role': m.role,
          'content': m.content,
          'is_error': m.isError ? 1 : 0,
          'created_at':
              m.createdAt?.millisecondsSinceEpoch ?? nowMs,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });

    if (maxConversations > 0) {
      await _enforceLimit(maxConversations);
    }
  }

  /// 로컬에서 한 대화를 영구 가림 표시. 서버에는 그대로 남는다.
  /// 다음 서버 목록 머지 때 다시 나타나지 않게 한다.
  Future<void> hideConversation(String conversationId) async {
    final db = await _database;
    await db.update(
      'conversations',
      {'hidden': 1},
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  /// 숨김 해제(되돌리기).
  Future<void> unhideConversation(String conversationId) async {
    final db = await _database;
    await db.update(
      'conversations',
      {'hidden': 0},
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  /// 로컬에서만 완전 삭제(다음 머지 시 서버 목록으로 다시 나타날 수 있음 → 숨김도 함께).
  Future<void> deleteConversationLocal(String conversationId) async {
    final db = await _database;
    await db.transaction((tx) async {
      await tx.delete(
        'chat_messages',
        where: 'conversation_id = ?',
        whereArgs: [conversationId],
      );
      // hidden=1 로 마킹된 stub row만 남긴다 → 머지 시 재출현 차단.
      await tx.insert(
        'conversations',
        {
          'id': conversationId,
          'title': null,
          'last_message': null,
          'last_message_at': null,
          'hidden': 1,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  /// 모든 로컬 데이터 삭제(서버는 손대지 않음).
  Future<void> clearAll() async {
    final db = await _database;
    await db.transaction((tx) async {
      await tx.delete('chat_messages');
      await tx.delete('conversations');
    });
  }

  /// 표시 가능한(숨김 아닌) 대화 개수.
  Future<int> visibleConversationCount() async {
    final db = await _database;
    final r = await db
        .rawQuery('SELECT COUNT(*) AS c FROM conversations WHERE hidden = 0');
    return (r.first['c'] as int?) ?? 0;
  }

  /// 추정 저장 바이트(대략). title+last_message+모든 content 의 UTF-8 길이 합.
  Future<int> approxStorageBytes() async {
    final db = await _database;
    final r = await db.rawQuery(
      'SELECT '
      ' (SELECT COALESCE(SUM(LENGTH(title)), 0) + COALESCE(SUM(LENGTH(last_message)), 0) FROM conversations) '
      ' + (SELECT COALESCE(SUM(LENGTH(content)), 0) FROM chat_messages) AS b',
    );
    return (r.first['b'] as int?) ?? 0;
  }

  // ── 내부 ──

  /// 가시 대화 수가 [max]를 넘으면 가장 오래된 것부터 삭제(서버에는 보존됨).
  Future<void> _enforceLimit(int max) async {
    final db = await _database;
    final count = await visibleConversationCount();
    if (count <= max) return;
    final over = count - max;
    final victims = await db.query(
      'conversations',
      columns: ['id'],
      where: 'hidden = 0',
      orderBy: 'COALESCE(last_message_at, created_at) ASC',
      limit: over,
    );
    if (victims.isEmpty) return;
    final ids = victims.map((r) => r['id'] as String).toList();
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.transaction((tx) async {
      await tx.delete(
        'chat_messages',
        where: 'conversation_id IN ($placeholders)',
        whereArgs: ids,
      );
      await tx.delete(
        'conversations',
        where: 'id IN ($placeholders)',
        whereArgs: ids,
      );
    });
  }

  Conversation _rowToConversation(Map<String, Object?> r) => Conversation(
        id: r['id'] as String,
        title: r['title'] as String?,
        lastMessage: r['last_message'] as String?,
        updatedAt: r['last_message_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(r['last_message_at'] as int)
            : null,
      );

  ChatMessage _rowToMessage(Map<String, Object?> r) => ChatMessage(
        role: r['role'] as String,
        content: r['content'] as String,
        turnIndex: r['turn_index'] as int?,
        createdAt: r['created_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int)
            : null,
        isError: (r['is_error'] as int? ?? 0) == 1,
      );

  String _shorten(String s, int n) {
    final t = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.length <= n) return t;
    return '${t.substring(0, n)}…';
  }
}
