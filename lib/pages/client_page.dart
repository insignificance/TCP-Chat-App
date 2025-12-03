import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/chat_session.dart';
import '../models/discovered_device.dart';
import '../services/tcp_client.dart';
import '../services/session_service.dart';
import '../services/message_service.dart';
import 'device_discovery_page.dart';

/// TCP 客户端界面
/// 显示连接控制、聊天消息列表和消息输入框
class ClientPage extends StatefulWidget {
  const ClientPage({super.key});

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  /// TCP 客户端实例
  final TcpClient _client = TcpClient();
  final SessionService _sessionService = SessionService();
  final MessageService _messageService = MessageService();
  
  /// 消息列表
  final TextEditingController _hostController = TextEditingController(text: '127.0.0.1');
  final TextEditingController _portController = TextEditingController(text: '8888');
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  
  final List<Message> _messages = [];
  String _statusMessage = '未连接';
  
  // 流量统计数据
  int _receivedBytes = 0;
  int _sentBytes = 0;
  int _receivedPackets = 0;
  int _sentPackets = 0;
  
  // 当前会话 ID
  int? _currentSessionId;

  @override
  void initState() {
    super.initState();
    
    // 监听消息流
    _client.messageStream.listen((message) {
      if (!mounted) return;
      setState(() {
        // 解析消息类型
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
      });
      
      // 自动滚动到底部
      _scrollToBottom();
    });
    
    // 监听状态流
    _client.statusStream.listen((status) {
      if (!mounted) return;
      setState(() {
        _statusMessage = status;
      });
    });
    
    // 监听统计流
    _client.statsStream.listen((stats) {
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
    // 释放资源
    _client.disconnect();
    _client.dispose();
    _messageController.dispose();
    _hostController.dispose();
    _portController.dispose();
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

  /// 连接到服务器
  Future<void> _connect() async {
    // 获取服务器地址和端口号
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text);
    
    // 验证输入
    if (host.isEmpty) {
      setState(() {
        _statusMessage = '请输入服务器地址';
      });
      return;
    }
    
    if (port == null || port < 1024 || port > 65535) {
      setState(() {
        _statusMessage = '端口号无效，请输入 1024-65535 之间的数字';
      });
      return;
    }

    // 连接到服务器
    await _client.connect(host, port);
    
    // 如果连接成功，创建会话
    if (_client.isConnected) {
      final session = ChatSession(
        sessionType: 'client',
        remoteAddress: host,
        remotePort: port,
        localPort: 0, // 客户端端口
        startTime: DateTime.now(),
        status: 'active',
      );
      _currentSessionId = await _sessionService.createSession(session);
    }
  }

  /// 断开连接
  Future<void> _disconnect() async {
    // 关闭会话
    if (_currentSessionId != null) {
      await _sessionService.closeSession(_currentSessionId!);
      _currentSessionId = null;
    }
    
    await _client.disconnect();
    setState(() {
      _messages.clear();
    });
  }

  /// 发送消息
  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // 发送消息到服务器
    _client.sendMessage(message);
    
    setState(() {
      // 添加发送的消息到消息列表（标记为本地发送）
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
  
  /// 扫描局域网设备
  Future<void> _scanDevices() async {
    final device = await Navigator.push<DiscoveredDevice>(
      context,
      MaterialPageRoute(
        builder: (context) => DeviceDiscoveryPage(
          targetPort: int.tryParse(_portController.text) ?? 8888,
        ),
      ),
    );
    
    // 如果选择了设备，自动填充地址
    if (device != null) {
      setState(() {
        _hostController.text = device.ipAddress;
        if (device.openPorts.isNotEmpty) {
          _portController.text = device.openPorts.first.toString();
        }
      });
    }
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
            'TCP 客户端',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green.shade800, Colors.green.shade600],
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
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            _buildControlPanel(),
            Expanded(
              child: _buildMessageList(),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  /// 构建连接控制面板
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
                    colors: [Colors.green.shade400, Colors.green.shade600],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '连接设置',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 服务器地址和端口号输入
          Row(
            children: [
              // 服务器地址输入框
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _hostController,
                        enabled: !_client.isConnected,
                        decoration: InputDecoration(
                          labelText: '服务器地址',
                          hintText: '例如：192.168.1.100',
                          prefixIcon: const Icon(Icons.computer_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: _client.isConnected ? Colors.grey.shade100 : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 扫描设备按钮
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade400, Colors.teal.shade600],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.radar_rounded, color: Colors.white),
                        tooltip: '扫描局域网设备',
                        onPressed: _scanDevices,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 端口号输入框
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _portController,
                  enabled: !_client.isConnected,
                  decoration: InputDecoration(
                    labelText: '端口',
                    prefixIcon: const Icon(Icons.pin_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: _client.isConnected ? Colors.grey.shade100 : Colors.white,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 连接/断开按钮
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _client.isConnected
                      ? [Colors.red.shade400, Colors.red.shade600]
                      : [Colors.green.shade400, Colors.green.shade600],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (_client.isConnected ? Colors.red : Colors.green).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _client.isConnected ? _disconnect : _connect,
                icon: Icon(_client.isConnected ? Icons.link_off_rounded : Icons.link_rounded),
                label: Text(_client.isConnected ? '断开连接' : '连接服务器'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 状态消息
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _client.isConnected ? Colors.green.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: _client.isConnected ? Border.all(color: Colors.green.shade200) : null,
            ),
            child: Row(
              children: [
                Icon(
                  _client.isConnected ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  size: 16,
                  color: _client.isConnected ? Colors.green.shade600 : Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: 13,
                      color: _client.isConnected ? Colors.green.shade700 : Colors.grey.shade700,
                      fontWeight: _client.isConnected ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (_client.isConnected) ...[
            const SizedBox(height: 12),
            // 流量统计
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('接收', _receivedBytes, _receivedPackets, Icons.download_rounded),
                  Container(width: 1, height: 30, color: Colors.green.shade200),
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
            Icon(icon, size: 14, color: Colors.green.shade700),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
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
            color: Colors.green.shade900,
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
          // 本地发送的消息为绿色，接收的消息为灰色
          color: message.isSentByMe ? Colors.green : Colors.grey[300],
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
                enabled: _client.isConnected,
                decoration: InputDecoration(
                  hintText: _client.isConnected ? '输入消息...' : '请先连接到服务器',
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
                  colors: _client.isConnected
                      ? [Colors.green.shade400, Colors.green.shade600]
                      : [Colors.grey.shade300, Colors.grey.shade400],
                ),
                shape: BoxShape.circle,
                boxShadow: _client.isConnected
                    ? [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: IconButton(
                onPressed: _client.isConnected ? _sendMessage : null,
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
