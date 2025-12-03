import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';

/// TCP 客户端类
/// 负责连接到 TCP 服务器，处理消息的发送和接收
class TcpClient {
  /// 客户端套接字
  Socket? _socket;
  
  /// 消息接收流控制器
  /// 用于向 UI 层发送接收到的消息
  final StreamController<String> _messageController = StreamController<String>.broadcast();
  
  /// 连接状态流控制器
  /// 用于通知 UI 层连接状态的变化
  final StreamController<String> _statusController = StreamController<String>.broadcast();
  
  /// 流量统计流控制器
  final StreamController<Map<String, int>> _statsController = StreamController<Map<String, int>>.broadcast();

  /// 是否已连接到服务器
  bool _isConnected = false;
  
  /// 连接建立时间
  DateTime? _connectTime;
  
  /// 总接收字节数
  int _totalReceivedBytes = 0;
  
  /// 总发送字节数
  int _totalSentBytes = 0;
  
  /// 总接收包数
  int _totalReceivedPackets = 0;
  
  /// 总发送包数
  int _totalSentPackets = 0;

  /// 获取消息流
  /// UI 层可以监听此流来接收新消息
  Stream<String> get messageStream => _messageController.stream;
  
  /// 获取状态流
  /// UI 层可以监听此流来获取连接状态更新
  Stream<String> get statusStream => _statusController.stream;
  
  /// 获取统计流
  Stream<Map<String, int>> get statsStream => _statsController.stream;
  
  /// 获取连接状态
  bool get isConnected => _isConnected;

  /// 连接到 TCP 服务器
  /// 
  /// [host] 服务器 IP 地址或主机名
  /// [port] 服务器端口号
  /// 返回值：连接成功返回 true，失败返回 false
  Future<bool> connect(String host, int port) async {
    try {
      // 如果已经连接，先断开
      if (_isConnected) {
        await disconnect();
      }

      // 发送状态更新：正在连接
      final connectingLog = '🔄 [客户端] 正在连接到 $host:$port...';
      _statusController.add(connectingLog);
      _messageController.add(connectingLog);
      debugPrint(connectingLog);
      
      // 尝试连接到服务器
      // timeout: 设置连接超时时间为 5 秒
      _socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 5),
      );
      
      // 记录连接时间
      _connectTime = DateTime.now();
      
      // 连接成功
      _isConnected = true;
      
      // 获取进程 ID
      final processId = pid;
      
      // 模拟 TCP 三次握手过程日志
      final handshakeLog = '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
          '🤝 [客户端] TCP 三次握手\n'
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
          '🔹 步骤 1: 发送 SYN 包\n'
          '   目标: $host:$port\n'
          '   请求建立连接\n'
          '🔹 步骤 2: 收到 SYN-ACK 包\n'
          '   服务器确认连接请求\n'
          '🔹 步骤 3: 发送 ACK 包\n'
          '   连接建立成功！\n'
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
      _messageController.add(handshakeLog);
      debugPrint('\n$handshakeLog');
      
      // 发送详细的连接成功日志
      final connectLog = '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
          '✅ [客户端] 连接成功\n'
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
          '🆔 客户端 PID: $processId\n'
          '📡 远程地址: ${_socket!.remoteAddress.address}\n'
          '🔌 远程端口: ${_socket!.remotePort}\n'
          '🏠 本地地址: ${_socket!.address.address}\n'
          '🔌 本地端口: ${_socket!.port}\n'
          '⏰ 连接时间: ${_formatDateTime(_connectTime!)}\n'
          '📊 连接状态: ESTABLISHED\n'
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
      _messageController.add(connectLog);
      _statusController.add('已连接到服务器: $host:$port (PID: $processId)');
      
      debugPrint('\n$connectLog');

      // 监听服务器发送的数据
      _socket!.listen(
        (data) {
          // 将接收到的字节数据转换为字符串
          final message = utf8.decode(data).trim();
          final dataSize = data.length;
          
          // 检查是否为心跳包
          if (message == '__HEARTBEAT__') {
            final heartbeatLog = '💓 [客户端] 收到心跳包\n'
                '   时间: ${_formatDateTime(DateTime.now())}\n'
                '   动作: 发送心跳响应';
            debugPrint(heartbeatLog);
            _messageController.add(heartbeatLog);
            
            // 发送心跳响应
            sendMessage('__HEARTBEAT__');
            return;
          }
          
          // 更新统计数据
          _totalReceivedBytes += dataSize;
          _totalReceivedPackets++;
          _updateStats();
          
          // 生成 Hex 视图
          final hexView = _formatHex(data);
          
          // 发送数据接收日志
          final receiveLog = '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
              '📥 [客户端] 接收数据\n'
              '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
              '📡 来源: ${_socket!.remoteAddress.address}:${_socket!.remotePort}\n'
              '📦 数据大小: $dataSize 字节\n'
              '🔢 Hex 视图: $hexView\n'
              '📝 内容: $message\n'
              '⏰ 接收时间: ${_formatDateTime(DateTime.now())}\n'
              '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
          debugPrint(receiveLog);
          _messageController.add(receiveLog);
          
          // 发送接收到的消息到消息流
          _messageController.add(message);
        },
        onError: (error) {
          // 处理连接错误
          final errorLog = '❌ [客户端] 连接错误: $error';
          _statusController.add(errorLog);
          _messageController.add(errorLog);
          debugPrint(errorLog);
          _isConnected = false;
        },
        onDone: () {
          // 服务器断开连接
          if (_connectTime != null) {
            final duration = DateTime.now().difference(_connectTime!);
            
            // 模拟 TCP 四次挥手过程（被动关闭）
            final waveLog = '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
                '👋 [客户端] TCP 四次挥手 (被动关闭)\n'
                '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
                '🔹 步骤 1: 收到 FIN 包\n'
                '   服务器请求关闭连接\n'
                '🔹 步骤 2: 发送 ACK 包\n'
                '   确认收到关闭请求\n'
                '🔹 步骤 3: 发送 FIN 包\n'
                '   客户端也请求关闭\n'
                '🔹 步骤 4: 收到 ACK 包\n'
                '   连接完全关闭！\n'
                '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
            _messageController.add(waveLog);
            debugPrint('\n$waveLog');
            
            final disconnectLog = '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
                '🔴 [客户端] 服务器断开连接\n'
                '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
                '⏱️ 连接时长: ${_formatDuration(duration)}\n'
                '⏰ 断开时间: ${_formatDateTime(DateTime.now())}\n'
                '📊 最终状态: CLOSED\n'
                '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
            _messageController.add(disconnectLog);
            _statusController.add('服务器已断开连接');
            debugPrint('\n$disconnectLog');
          }
          _isConnected = false;
          _socket = null;
        },
      );
      
      return true;
    } catch (e) {
      // 连接失败，发送错误状态
      final errorMsg = '连接失败: $e';
      _statusController.add(errorMsg);
      _messageController.add('❌ [客户端] $errorMsg');
      debugPrint('❌ [客户端] $errorMsg');
      _isConnected = false;
      return false;
    }
  }

  /// 向服务器发送消息
  /// 
  /// [message] 要发送的消息内容
  void sendMessage(String message) {
    if (!_isConnected || _socket == null) {
      _statusController.add('未连接到服务器');
      return;
    }

    try {
      // 将消息转换为 UTF-8 字节数组并发送
      final data = utf8.encode(message);
      final dataSize = data.length;
      _socket!.add(data);
      
      // 如果是心跳包，不记录普通发送日志
      if (message == '__HEARTBEAT__') {
        return;
      }
      
      // 更新统计数据
      _totalSentBytes += dataSize;
      _totalSentPackets++;
      _updateStats();
      
      // 生成 Hex 视图
      final hexView = _formatHex(data);
      
      // 发送数据传输日志
      final sendLog = '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
          '📤 [客户端] 发送数据\n'
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
          '📦 数据大小: $dataSize 字节\n'
          '🔢 Hex 视图: $hexView\n'
          '📝 内容: $message\n'
          '⏰ 发送时间: ${_formatDateTime(DateTime.now())}\n'
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
      debugPrint(sendLog);
    } catch (e) {
      final errorMsg = '发送消息失败: $e';
      _statusController.add(errorMsg);
      _messageController.add('❌ [客户端] $errorMsg');
      debugPrint('❌ [客户端] $errorMsg');
    }
  }

  /// 断开与服务器的连接
  Future<void> disconnect() async {
    if (_socket != null) {
      await _socket!.close();
      _socket = null;
    }
    
    // 记录断开连接日志
    if (_connectTime != null) {
      final duration = DateTime.now().difference(_connectTime!);
      
      // 模拟 TCP 四次挥手过程（主动关闭）
      final waveLog = '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
          '👋 [客户端] TCP 四次挥手 (主动关闭)\n'
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
          '🔹 步骤 1: 发送 FIN 包\n'
          '   客户端请求关闭连接\n'
          '🔹 步骤 2: 收到 ACK 包\n'
          '   服务器确认收到关闭请求\n'
          '🔹 步骤 3: 收到 FIN 包\n'
          '   服务器也请求关闭\n'
          '🔹 步骤 4: 发送 ACK 包\n'
          '   连接完全关闭！\n'
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
      _messageController.add(waveLog);
      debugPrint('\n$waveLog');
      
      final disconnectLog = '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
          '🔴 [客户端] 主动断开连接\n'
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
          '⏱️ 连接时长: ${_formatDuration(duration)}\n'
          '⏰ 断开时间: ${_formatDateTime(DateTime.now())}\n'
          '📊 最终状态: CLOSED\n'
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
      _messageController.add(disconnectLog);
      debugPrint('\n$disconnectLog');
    }
    
    _isConnected = false;
    _statusController.add('已断开连接');
  }

  /// 释放资源
  /// 关闭所有流控制器
  void dispose() {
    _messageController.close();
    _statusController.close();
    _statsController.close();
  }
  
  /// 更新统计数据
  void _updateStats() {
    _statsController.add({
      'receivedBytes': _totalReceivedBytes,
      'sentBytes': _totalSentBytes,
      'receivedPackets': _totalReceivedPackets,
      'sentPackets': _totalSentPackets,
    });
  }
  
  /// 将字节数组格式化为 Hex 字符串
  /// 例如: [0x48, 0x65] -> "48 65"
  String _formatHex(List<int> data) {
    return data.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
  }
  
  /// 格式化日期时间
  /// 
  /// [dateTime] 要格式化的日期时间
  /// 返回值：格式化后的字符串（yyyy-MM-dd HH:mm:ss）
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }
  
  /// 格式化时间间隔
  /// 
  /// [duration] 要格式化的时间间隔
  /// 返回值：格式化后的字符串
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}小时${duration.inMinutes.remainder(60)}分${duration.inSeconds.remainder(60)}秒';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分${duration.inSeconds.remainder(60)}秒';
    } else {
      return '${duration.inSeconds}秒';
    }
  }
}
