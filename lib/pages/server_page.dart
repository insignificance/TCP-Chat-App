import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/chat_session.dart';
import '../services/tcp_server.dart';
import '../services/session_service.dart';
import '../services/message_service.dart';

/// TCP 服务端界面
/// 显示服务器信息、聊天消息列表和消息输入框
class ServerPage extends StatefulWidget {
  const ServerPage({super.key});

  @override
  State<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  /// TCP 服务器实例
  final TcpServer _server = TcpServer();
  final SessionService _sessionService = SessionService();
  final MessageService _messageService = MessageService();
  final TextEditingController _portController = TextEditingController(text: '8888');
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  
  final List<Message> _messages = [];
  String _statusMessage = '服务器未启动';
  bool _isRunning = false;
  
  // 流量统计数据
  int _receivedBytes = 0;
  int _sentBytes = 0;
  int _receivedPackets = 0;
  int _sentPackets = 0;
  
  // 当前会话 ID (服务端可能有多个客户端，这里简化为记录最近的一个)
  int? _currentSessionId;

  @override
  void initState() {
    super.initState();
    
    // 监听消息流
    _server.messageStream.listen((message) {
      if (!mounted) return;
      setState(() {
        // 解析消息类型
        // 这里简单处理，实际应用中应该由 Message 模型处理
        bool isLog = message.startsWith('━━━') || message.startsWith('❌') || message.startsWith('💓') || message.startsWith('⚠️');
        
        final msg = Message(
          content: message,
          isSentByMe: false,
          type: isLog ? MessageType.systemLog : MessageType.chat,
          sessionId: _currentSessionId,
        );
        _messages.add(msg);
        
        // 保存到数据库
        if (_currentSessionId != null) {
          _messageService.saveMessage(msg);
          _sessionService.incrementMessageCount(_currentSessionId!);
          _sessionService.incrementTraffic(_currentSessionId!, received: msg.dataSize);
        }
        
        // 如果是客户端连接消息，创建会话
        if (message.contains('客户端已连接:')) {
          try {
            // 提取 IP 和端口 - 格式: "客户端已连接: IP:PORT (connectionId)"
            final match = RegExp(r'客户端已连接: ([\d\.]+):(\d+)').firstMatch(message);
            if (match != null) {
              final remoteAddress = match.group(1)!;
              final remotePort = int.parse(match.group(2)!);
              
              final session = ChatSession(
                sessionType: 'server',
                remoteAddress: remoteAddress,
                remotePort: remotePort,
                localPort: int.tryParse(_portController.text) ?? 8888,
                startTime: DateTime.now(),
                status: 'active',
              );
              // 异步创建会话
              _sessionService.createSession(session).then((id) {
                _currentSessionId = id;
              });
            }
          } catch (e) {
            // 忽略解析错误
          }
        }
      });
      
      // 自动滚动到底部
      _scrollToBottom();
    });
    
    // 监听状态流
    _server.statusStream.listen((status) {
      if (!mounted) return;
      setState(() {
        _statusMessage = status;
        if (status.contains('服务器已启动')) {
          _isRunning = true;
        } else if (status.contains('服务器已关闭') || status.contains('启动服务器失败')) {
          _isRunning = false;
        }
      });
    });
    
    // 监听统计流
    _server.statsStream.listen((stats) {
      if (!mounted) return;
      setState(() {
        _receivedBytes = stats['receivedBytes'] ?? 0;
        _sentBytes = stats['sentBytes'] ?? 0;
        _receivedPackets = stats['receivedPackets'] ?? 0;
        _sentPackets = stats['sentPackets'] ?? 0;
    });
  });
  
  // 监听输入框焦点变化，键盘弹出时自动滚动
  _messageFocusNode.addListener(() {
    if (_messageFocusNode.hasFocus) {
      // 延迟滚动，等待键盘动画完成
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollToBottom();
      });
    }
  });
    
  }

  @override
  void dispose() {
    _server.dispose();
    _portController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }
  
  /// 滚动到底部
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  /// 清除日志
  void _clearLogs() {
    setState(() {
      _messages.clear();
    });
  }

  /// 启动服务器
  Future<void> _startServer() async {
    // 解析端口号
    final port = int.tryParse(_portController.text);
    if (port == null || port < 1024 || port > 65535) {
      setState(() {
        _statusMessage = '端口号无效，请输入 1024-65535 之间的数字';
      });
      return;
    }

    // 启动服务器
    final success = await _server.start(port);
    if (success) {
      setState(() {
        _isRunning = true;
      });
    }
  }

  /// 停止服务器
  Future<void> _stopServer() async {
    await _server.stop();
    setState(() {
      _isRunning = false;
      _messages.clear();
    });
  }

  /// 发送消息
  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // 发送消息到所有客户端
    _server.sendMessage(message);
    
    setState(() {
      // 添加发送的消息到消息列表
      final msg = Message(
        content: message,
        isSentByMe: true,
        sessionId: _currentSessionId,
      );
      _messages.add(msg);
      
      // 保存到数据库
      if (_currentSessionId != null) {
        _messageService.saveMessage(msg);
        _sessionService.incrementMessageCount(_currentSessionId!);
        _sessionService.incrementTraffic(_currentSessionId!, sent: msg.dataSize);
      }
    });
    
    // 清空输入框
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 仅在点击空白区域时取消焦点，不影响 TextField
        FocusScope.of(context).requestFocus(FocusNode());
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'TCP 服务端',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade800, Colors.blue.shade600],
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: '清除日志',
              onPressed: _clearLogs,
            ),
          ],
        ),
        backgroundColor: Colors.grey.shade50,
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            // 服务器控制面板
            _buildControlPanel(),
            
            // 消息列表
            Expanded(
              child: _buildMessageList(),
            ),
            
            // 消息输入区域
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  /// 构建服务器控制面板
  Widget _buildControlPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '服务器控制',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 端口号输入和启动/停止按钮
          Row(
            children: [
              // 端口号输入框
              Expanded(
                child: TextField(
                  controller: _portController,
                  enabled: !_isRunning,
                  decoration: InputDecoration(
                    labelText: '端口号',
                    prefixIcon: const Icon(Icons.pin_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: _isRunning ? Colors.grey.shade100 : Colors.white,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 启动/停止按钮
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isRunning 
                        ? [Colors.red.shade400, Colors.red.shade600]
                        : [Colors.green.shade400, Colors.green.shade600],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (_isRunning ? Colors.red : Colors.green).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _isRunning ? _stopServer : _startServer,
                  icon: Icon(_isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded),
                  label: Text(_isRunning ? '停止' : '启动'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 服务器信息显示
          if (_isRunning) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.blue.shade50],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '服务器地址',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_server.ipAddress}:${_server.port}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // 状态消息
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _isRunning ? Colors.green.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: _isRunning ? Border.all(color: Colors.green.shade200) : null,
            ),
            child: Row(
              children: [
                Icon(
                  _isRunning ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  size: 16,
                  color: _isRunning ? Colors.green.shade600 : Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: 13,
                      color: _isRunning ? Colors.green.shade700 : Colors.grey.shade700,
                      fontWeight: _isRunning ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (_isRunning) ...[
            const SizedBox(height: 12),
            // 流量统计
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('接收', _receivedBytes, _receivedPackets, Icons.download_rounded),
                  Container(width: 1, height: 30, color: Colors.blue.shade200),
                  _buildStatItem('发送', _sentBytes, _sentPackets, Icons.upload_rounded),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, int bytes, int packets, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.blue.shade700),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${_formatBytes(bytes)} / $packets 包',
          style: TextStyle(
            fontSize: 11,
            color: Colors.blue.shade900,
          ),
        ),
      ],
    );
  }
  
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// 构建消息列表
  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无消息',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  /// 构建消息气泡
  Widget _buildMessageBubble(Message message) {
    return Align(
      // 本地发送的消息靠右，接收的消息靠左
      alignment: message.isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          // 本地发送的消息为蓝色，接收的消息为灰色
          color: message.isSentByMe ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 消息内容
            Text(
              message.content,
              style: TextStyle(
                fontSize: 16,
                color: message.isSentByMe ? Colors.white : Colors.black87,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // 时间戳
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: message.isSentByMe ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建消息输入区域
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // 消息输入框
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                enabled: _isRunning,
                decoration: InputDecoration(
                  hintText: _isRunning ? '输入消息...' : '请先启动服务器',
                  prefixIcon: const Icon(Icons.message_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // 发送按钮
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isRunning
                      ? [Colors.blue.shade400, Colors.blue.shade600]
                      : [Colors.grey.shade300, Colors.grey.shade400],
                ),
                shape: BoxShape.circle,
                boxShadow: _isRunning
                    ? [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: IconButton(
                onPressed: _isRunning ? _sendMessage : null,
                icon: const Icon(Icons.send_rounded),
                color: Colors.white,
                iconSize: 24,
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 格式化时间显示
  /// 
  /// [time] 要格式化的时间
  /// 返回值：格式化后的时间字符串（HH:mm:ss）
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }
}
