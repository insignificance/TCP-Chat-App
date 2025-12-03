/// 聊天会话模型
class ChatSession {
  final int? id;
  final String sessionType; // 'client' or 'server'
  final String remoteAddress;
  final int remotePort;
  final int localPort;
  final DateTime startTime;
  final DateTime? endTime;
  final String status; // 'active' or 'closed'
  final int messageCount;
  final int receivedBytes;
  final int sentBytes;

  ChatSession({
    this.id,
    required this.sessionType,
    required this.remoteAddress,
    required this.remotePort,
    required this.localPort,
    required this.startTime,
    this.endTime,
    required this.status,
    this.messageCount = 0,
    this.receivedBytes = 0,
    this.sentBytes = 0,
  });

  /// 转换为 Map（用于数据库存储）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_type': sessionType,
      'remote_address': remoteAddress,
      'remote_port': remotePort,
      'local_port': localPort,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'status': status,
      'message_count': messageCount,
      'received_bytes': receivedBytes,
      'sent_bytes': sentBytes,
    };
  }

  /// 从 Map 创建对象
  factory ChatSession.fromMap(Map<String, dynamic> map) {
    return ChatSession(
      id: map['id'] as int?,
      sessionType: map['session_type'] as String,
      remoteAddress: map['remote_address'] as String,
      remotePort: map['remote_port'] as int,
      localPort: map['local_port'] as int,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
      endTime: map['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int)
          : null,
      status: map['status'] as String,
      messageCount: map['message_count'] as int,
      receivedBytes: map['received_bytes'] as int,
      sentBytes: map['sent_bytes'] as int,
    );
  }

  /// 复制会话并更新某些字段
  ChatSession copyWith({
    int? id,
    String? sessionType,
    String? remoteAddress,
    int? remotePort,
    int? localPort,
    DateTime? startTime,
    DateTime? endTime,
    String? status,
    int? messageCount,
    int? receivedBytes,
    int? sentBytes,
  }) {
    return ChatSession(
      id: id ?? this.id,
      sessionType: sessionType ?? this.sessionType,
      remoteAddress: remoteAddress ?? this.remoteAddress,
      remotePort: remotePort ?? this.remotePort,
      localPort: localPort ?? this.localPort,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      messageCount: messageCount ?? this.messageCount,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      sentBytes: sentBytes ?? this.sentBytes,
    );
  }

  /// 获取会话持续时间
  Duration? get duration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    } else if (status == 'active') {
      return DateTime.now().difference(startTime);
    }
    return null;
  }

  /// 是否为活动会话
  bool get isActive => status == 'active';
}
