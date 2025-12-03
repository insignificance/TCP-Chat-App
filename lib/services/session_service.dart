import '../models/chat_session.dart';
import 'database_helper.dart';

/// 会话管理服务
/// 负责会话的 CRUD 操作
class SessionService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// 创建新会话
  Future<int> createSession(ChatSession session) async {
    final db = await _dbHelper.database;
    return await db.insert('sessions', session.toMap());
  }

  /// 更新会话信息
  Future<int> updateSession(ChatSession session) async {
    final db = await _dbHelper.database;
    return await db.update(
      'sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  /// 关闭会话
  Future<int> closeSession(int sessionId) async {
    final db = await _dbHelper.database;
    return await db.update(
      'sessions',
      {
        'status': 'closed',
        'end_time': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  /// 获取会话详情
  Future<ChatSession?> getSessionById(int sessionId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    if (maps.isNotEmpty) {
      return ChatSession.fromMap(maps.first);
    }
    return null;
  }

  /// 获取所有会话
  Future<List<ChatSession>> getAllSessions({
    String? sessionType,
    String? status,
    int? limit,
  }) async {
    final db = await _dbHelper.database;
    
    String? where;
    List<dynamic>? whereArgs;
    
    if (sessionType != null && status != null) {
      where = 'session_type = ? AND status = ?';
      whereArgs = [sessionType, status];
    } else if (sessionType != null) {
      where = 'session_type = ?';
      whereArgs = [sessionType];
    } else if (status != null) {
      where = 'status = ?';
      whereArgs = [status];
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'start_time DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) => ChatSession.fromMap(maps[i]));
  }

  /// 获取活动会话
  Future<List<ChatSession>> getActiveSessions() async {
    return await getAllSessions(status: 'active');
  }

  /// 删除会话及其所有消息
  Future<int> deleteSession(int sessionId) async {
    final db = await _dbHelper.database;
    // 由于设置了外键级联删除，删除会话会自动删除相关消息
    return await db.delete(
      'sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  /// 更新会话统计信息
  Future<void> updateSessionStats(
    int sessionId, {
    int? messageCount,
    int? receivedBytes,
    int? sentBytes,
  }) async {
    final db = await _dbHelper.database;
    final Map<String, dynamic> updates = {};

    if (messageCount != null) updates['message_count'] = messageCount;
    if (receivedBytes != null) updates['received_bytes'] = receivedBytes;
    if (sentBytes != null) updates['sent_bytes'] = sentBytes;

    if (updates.isNotEmpty) {
      await db.update(
        'sessions',
        updates,
        where: 'id = ?',
        whereArgs: [sessionId],
      );
    }
  }

  /// 增加会话消息计数
  Future<void> incrementMessageCount(int sessionId) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      'UPDATE sessions SET message_count = message_count + 1 WHERE id = ?',
      [sessionId],
    );
  }

  /// 增加会话流量统计
  Future<void> incrementTraffic(int sessionId, {int? received, int? sent}) async {
    final db = await _dbHelper.database;
    
    if (received != null) {
      await db.rawUpdate(
        'UPDATE sessions SET received_bytes = received_bytes + ? WHERE id = ?',
        [received, sessionId],
      );
    }
    
    if (sent != null) {
      await db.rawUpdate(
        'UPDATE sessions SET sent_bytes = sent_bytes + ? WHERE id = ?',
        [sent, sessionId],
      );
    }
  }
}
