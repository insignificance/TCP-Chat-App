import '../models/message.dart';
import 'database_helper.dart';

/// 消息管理服务
/// 负责消息的 CRUD 操作
class MessageService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// 保存消息
  Future<int> saveMessage(Message message) async {
    final db = await _dbHelper.database;
    return await db.insert('messages', message.toMap());
  }

  /// 批量保存消息
  Future<void> saveMessages(List<Message> messages) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    
    for (var message in messages) {
      batch.insert('messages', message.toMap());
    }
    
    await batch.commit(noResult: true);
  }

  /// 获取会话的所有消息
  Future<List<Message>> getMessagesBySession(
    int sessionId, {
    int? limit,
    int? offset,
  }) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) => Message.fromMap(maps[i]));
  }

  /// 搜索消息
  Future<List<Message>> searchMessages(
    String query, {
    int? sessionId,
    int? limit,
  }) async {
    final db = await _dbHelper.database;
    
    String where = 'content LIKE ?';
    List<dynamic> whereArgs = ['%$query%'];
    
    if (sessionId != null) {
      where += ' AND session_id = ?';
      whereArgs.add(sessionId);
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) => Message.fromMap(maps[i]));
  }

  /// 删除会话的所有消息
  Future<int> deleteMessagesBySession(int sessionId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  /// 获取消息统计
  Future<Map<String, int>> getMessageStats(int sessionId) async {
    final db = await _dbHelper.database;
    
    // 获取总消息数
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM messages WHERE session_id = ?',
      [sessionId],
    );
    final totalCount = countResult.first['count'] as int;
    
    // 获取发送的消息数
    final sentResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM messages WHERE session_id = ? AND is_sent_by_me = 1',
      [sessionId],
    );
    final sentCount = sentResult.first['count'] as int;
    
    // 获取接收的消息数
    final receivedCount = totalCount - sentCount;
    
    // 获取总数据大小
    final sizeResult = await db.rawQuery(
      'SELECT SUM(data_size) as total_size FROM messages WHERE session_id = ?',
      [sessionId],
    );
    final totalSize = (sizeResult.first['total_size'] ?? 0) as int;
    
    return {
      'total': totalCount,
      'sent': sentCount,
      'received': receivedCount,
      'totalSize': totalSize,
    };
  }

  /// 获取最近的消息
  Future<List<Message>> getRecentMessages({int limit = 50}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) => Message.fromMap(maps[i]));
  }

  /// 删除指定消息
  Future<int> deleteMessage(int messageId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  /// 获取会话中特定类型的消息数量
  Future<int> getMessageCountByType(int sessionId, MessageType type) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM messages WHERE session_id = ? AND message_type = ?',
      [sessionId, type.toString().split('.').last],
    );
    return result.first['count'] as int;
  }
}
