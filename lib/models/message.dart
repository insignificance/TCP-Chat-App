/// 消息类型枚举
/// 用于区分不同类型的消息
enum MessageType {
  /// 普通聊天消息
  chat,
  
  /// 系统日志消息（如启动、停止等）
  systemLog,
  
  /// 连接事件消息（如连接建立、断开）
  connectionEvent,
  
  /// 数据传输消息（如发送、接收数据）
  dataTransfer,
}

/// 消息模型类
/// 用于表示聊天应用中的单条消息
class Message {
  /// 消息内容
  final String content;
  
  /// 消息发送时间
  final DateTime timestamp;
  
  /// 是否为本地发送的消息
  /// true: 本地发送的消息（显示在右侧）
  /// false: 远程接收的消息（显示在左侧）
  final bool isSentByMe;
  
  /// 消息类型
  /// 默认为普通聊天消息
  final MessageType type;
  
  /// 消息元数据
  /// 用于存储额外的信息，如 Socket 详情、连接 ID 等
  final Map<String, dynamic>? metadata;

  /// 数据库 ID
  final int? id;
  
  /// 关联的会话 ID
  final int? sessionId;
  
  /// 数据大小（字节）
  final int dataSize;

  /// 构造函数
  /// 
  /// [content] 消息内容
  /// [isSentByMe] 是否为本地发送的消息
  /// [timestamp] 消息时间戳，默认为当前时间
  /// [type] 消息类型，默认为普通聊天消息
  /// [metadata] 消息元数据，可选
  /// [id] 数据库ID，可选
  /// [sessionId] 会话ID，可选
  /// [dataSize] 数据大小，默认从内容计算
  Message({
    required this.content,
    required this.isSentByMe,
    DateTime? timestamp,
    this.type = MessageType.chat,
    this.metadata,
    this.id,
    this.sessionId,
    int? dataSize,
  }) : timestamp = timestamp ?? DateTime.now(),
       dataSize = dataSize ?? content.length;
  
  /// 判断是否为日志消息（非普通聊天消息）
  bool get isLog => type != MessageType.chat;
  
  /// 转换为 Map（用于数据库存储）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'content': content,
      'is_sent_by_me': isSentByMe ? 1 : 0,
      'message_type': type.toString().split('.').last,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'data_size': dataSize,
    };
  }
  
  /// 从 Map 创建对象
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as int?,
      sessionId: map['session_id'] as int?,
      content: map['content'] as String,
      isSentByMe: (map['is_sent_by_me'] as int) == 1,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == map['message_type'],
        orElse: () => MessageType.chat,
      ),
      dataSize: map['data_size'] as int?,
    );
  }

}
