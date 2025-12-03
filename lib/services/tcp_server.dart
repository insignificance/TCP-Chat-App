import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';

/// TCP 服务端类
/// 负责创建和管理 TCP 服务器，处理客户端连接和消息收发
class TcpServer {
  /// 服务器实例
  ServerSocket? _serverSocket;
  
  /// 已连接的客户端套接字列表
  final List<Socket> _clients = [];
  
  /// 客户端连接信息映射
  /// Key: Socket 对象，Value: 连接信息（连接 ID、连接时间等）
  final Map<Socket, Map<String, dynamic>> _clientInfo = {};
  
  /// 客户端连接计数器，用于生成唯一的连接 ID
  int _connectionCounter = 0;
  
  /// 服务器启动时间
  DateTime? _serverStartTime;
  
  /// 总接收字节数
  int _totalReceivedBytes = 0;
  
  /// 总发送字节数
  int _totalSentBytes = 0;
  
  /// 总接收包数
  int _totalReceivedPackets = 0;
  
  /// 总发送包数
  int _totalSentPackets = 0;
  
  /// 消息接收流控制器
  /// 用于向 UI 层发送接收到的消息
  final StreamController<String> _messageController = StreamController<String>.broadcast();
  
  /// 连接状态流控制器
  /// 用于通知 UI 层连接状态的变化
  final StreamController<String> _statusController = StreamController<String>.broadcast();
  
  /// 流量统计流控制器
  final StreamController<Map<String, int>> _statsController = StreamController<Map<String, int>>.broadcast();

  /// 服务器端口号
  int? _port;
  
  /// 服务器 IP 地址
  String? _ipAddress;

  /// 获取消息流
  /// UI 层可以监听此流来接收新消息
  Stream<String> get messageStream => _messageController.stream;
  
  /// 获取状态流
  /// UI 层可以监听此流来获取连接状态更新
  Stream<String> get statusStream => _statusController.stream;
  
  /// 获取统计流
  Stream<Map<String, int>> get statsStream => _statsController.stream;

  /// 获取服务器端口号
  int? get port => _port;
  
  /// 获取服务器 IP 地址
  String? get ipAddress => _ipAddress;

  /// 启动 TCP 服务器
  /// 
  /// [port] 监听的端口号，默认为 8888
  /// 返回值：启动成功返回 true，失败返回 false
  Future<bool> start(int port) async {
    try {
      // 记录启动时间
      _serverStartTime = DateTime.now();
      
      // 获取本机 IP 地址
      _ipAddress = await _getLocalIpAddress();
      
      // 绑定到指定端口，监听所有网络接口
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      _port = port;
      
      // 获取进程 ID
      final processId = pid;
      
      // 发送详细的服务器启动日志
      final startLog = '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
          '🟢 [服务端] 服务器启动\n'
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
          '📍 监听地址: $_ipAddress\n'
          '🔌 监听端口: $port\n'
          '🆔 进程 PID: $processId\n'
          '⏰ 启动时间: ${_formatDateTime(_serverStartTime!)}\n'
          '📊 状态: LISTEN (等待客户端连接)\n'
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
      _messageController.add(startLog);
      _statusController.add('服务器已启动: $_ipAddress:$port (PID: $processId)');
      
      // 打印到控制台
      debugPrint('\n$startLog');
      
      // 监听客户端连接
      _serverSocket!.listen(
        _handleClient,
        onError: (error) {
          // 处理服务器错误
          final errorLog = '❌ [服务端] 服务器错误: $error';
          _statusController.add(errorLog);
          _messageController.add(errorLog);
          debugPrint(errorLog);
        },
        onDone: () {
          // 服务器关闭时的回调
          final closeLog = '🔴 [服务端] 服务器已关闭';
          _statusController.add(closeLog);
          _messageController.add(closeLog);
          debugPrint(closeLog);
        },
      );
      
      return true;
    } catch (e) {
      // 启动失败，发送错误状态
      final errorMsg = '启动服务器失败: $e';
      _statusController.add(errorMsg);
      _messageController.add('❌ [服务端] $errorMsg');
      debugPrint('❌ [服务端] $errorMsg');
      return false;
    }
  }

  /// 处理客户端连接
  /// 
  /// [client] 客户端套接字
  void _handleClient(Socket client) {
    // 生成唯一的连接 ID
    _connectionCounter++;
    final connectionId = 'CLIENT-$_connectionCounter';
    final connectTime = DateTime.now();
    
    // 保存客户端连接信息
    _clientInfo[client] = {
      'id': connectionId,
      'connectTime': connectTime,
      'remoteAddress': client.remoteAddress.address,
      'remotePort': client.remotePort,
      'localPort': client.port,
      'lastHeartbeat': connectTime,
    };
    
    // 将新客户端添加到客户端列表
    _clients.add(client);
    
    // 获取客户端地址信息
    final clientAddress = '${client.remoteAddress.address}:${client.remotePort}';
    
    // 模拟 TCP 三次握手过程日志
    final handshakeLog = '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        '🤝 [服务端] TCP 三次握手\n'
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        '📍 连接 ID: $connectionId\n'
        '🔹 步骤 1: 收到 SYN 包\n'
        '   来源: ${client.remoteAddress.address}:${client.remotePort}\n'
        '   目标: $_ipAddress:$_port\n'
        '🔹 步骤 2: 发送 SYN-ACK 包\n'
        '   确认客户端连接请求\n'
        '🔹 步骤 3: 收到 ACK 包\n'
        '   连接建立成功！\n'
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    _messageController.add(handshakeLog);
    debugPrint('\n$handshakeLog');
    
    // 发送详细的连接建立日志
    final connectLog = '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        '✅ [服务端] 客户端连接成功\n'
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        '🔗 连接 ID: $connectionId\n'
        '📡 远程地址: ${client.remoteAddress.address}\n'
        '🔌 远程端口: ${client.remotePort}\n'
        '🏠 本地端口: ${client.port}\n'
        '⏰ 连接时间: ${_formatDateTime(connectTime)}\n'
        '📊 连接状态: ESTABLISHED\n'
        '💓 心跳状态: 已启动\n'
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    _messageController.add(connectLog);
    _statusController.add('客户端已连接: $clientAddress ($connectionId)');
    
    debugPrint('\n$connectLog');
    
    // 启动心跳检测
    _startHeartbeat(client, connectionId);

    // 监听客户端发送的数据
    client.listen(
      (data) {
        // 将接收到的字节数据转换为字符串
        final message = utf8.decode(data).trim();
        final dataSize = data.length;
        
        // 检查是否为心跳包
        if (message == '__HEARTBEAT__') {
          _clientInfo[client]?['lastHeartbeat'] = DateTime.now();
          final heartbeatLog = '💓 [服务端] 收到心跳包 [$connectionId]\n'
              '   时间: ${_formatDateTime(DateTime.now())}\n'
              '   状态: 连接正常';
          debugPrint(heartbeatLog);
          _messageController.add(heartbeatLog);
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
            '📥 [服务端] 接收数据\n'
            '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
            '🔗 连接 ID: $connectionId\n'
            '📡 来源: ${client.remoteAddress.address}:${client.remotePort}\n'
            '📦 数据大小: $dataSize 字节\n'
            '🔢 Hex 视图: $hexView\n'
            '📝 内容: $message\n'
            '⏰ 接收时间: ${_formatDateTime(DateTime.now())}\n'
            '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
        debugPrint('\n$receiveLog');
        _messageController.add(receiveLog);
        
        // 发送接收到的消息到消息流（用于显示聊天消息）
        _messageController.add(message);
      },
      onError: (error) {
        // 处理客户端连接错误
        final errorLog = '❌ [服务端] 客户端错误 [$connectionId]: $error';
        _statusController.add(errorLog);
        _messageController.add(errorLog);
        debugPrint(errorLog);
        
        _clients.remove(client);
        _clientInfo.remove(client);
      },
      onDone: () {
        // 客户端断开连接
        final info = _clientInfo[client];
        if (info != null) {
          final duration = DateTime.now().difference(info['connectTime'] as DateTime);
          
          // 模拟 TCP 四次挥手过程
          final waveLog = '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
              '👋 [服务端] TCP 四次挥手\n'
              '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
              '🔗 连接 ID: ${info['id']}\n'
              '🔹 步骤 1: 收到 FIN 包\n'
              '   客户端请求关闭连接\n'
              '🔹 步骤 2: 发送 ACK 包\n'
              '   确认收到关闭请求\n'
              '🔹 步骤 3: 发送 FIN 包\n'
              '   服务端也请求关闭\n'
              '🔹 步骤 4: 收到 ACK 包\n'
              '   连接完全关闭！\n'
              '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
          _messageController.add(waveLog);
          debugPrint('\n$waveLog');
          
          final disconnectLog = '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
              '🔴 [服务端] 客户端断开连接\n'
              '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
              '🔗 连接 ID: ${info['id']}\n'
              '📡 远程地址: ${info['remoteAddress']}:${info['remotePort']}\n'
              '⏱️ 连接时长: ${_formatDuration(duration)}\n'
              '⏰ 断开时间: ${_formatDateTime(DateTime.now())}\n'
              '📊 最终状态: CLOSED\n'
              '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
          _messageController.add(disconnectLog);
          _statusController.add('客户端已断开: ${info['id']}');
          debugPrint('\n$disconnectLog');
        }
        
        _clients.remove(client);
        _clientInfo.remove(client);
        client.close();
      },
    );
  }
  
  /// 启动心跳检测
  /// 
  /// [client] 客户端套接字
  /// [connectionId] 连接 ID
  void _startHeartbeat(Socket client, String connectionId) {
    // 每 30 秒发送一次心跳包
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_clients.contains(client)) {
        timer.cancel();
        return;
      }
      
      try {
        // 发送心跳包
        final heartbeatData = utf8.encode('__HEARTBEAT__');
        client.add(heartbeatData);
        
        final heartbeatLog = '💓 [服务端] 发送心跳包 [$connectionId]\n'
            '   时间: ${_formatDateTime(DateTime.now())}\n'
            '   目的: 保持连接活跃';
        debugPrint(heartbeatLog);
        _messageController.add(heartbeatLog);
        
        // 检查上次心跳时间
        final info = _clientInfo[client];
        if (info != null) {
          final lastHeartbeat = info['lastHeartbeat'] as DateTime;
          final timeSinceLastHeartbeat = DateTime.now().difference(lastHeartbeat);
          
          if (timeSinceLastHeartbeat.inSeconds > 60) {
            final warningLog = '⚠️ [服务端] 心跳超时警告 [$connectionId]\n'
                '   上次心跳: ${_formatDuration(timeSinceLastHeartbeat)}前\n'
                '   连接可能不稳定';
            debugPrint(warningLog);
            _messageController.add(warningLog);
          }
        }
      } catch (e) {
        timer.cancel();
        debugPrint('❌ [服务端] 心跳发送失败 [$connectionId]: $e');
      }
    });
  }

  /// 向所有已连接的客户端发送消息
  /// 
  /// [message] 要发送的消息内容
  void sendMessage(String message) {
    if (_clients.isEmpty) {
      _statusController.add('没有已连接的客户端');
      return;
    }

    // 将消息转换为 UTF-8 字节数组
    final data = utf8.encode(message);
    final dataSize = data.length;
    final hexView = _formatHex(data);
    
    // 遍历所有客户端并发送消息
    int successCount = 0;
    for (var client in _clients) {
      try {
        client.add(data);
        final info = _clientInfo[client];
        final clientId = info?['id'] ?? 'UNKNOWN';
        
        // 更新统计数据
        _totalSentBytes += dataSize;
        _totalSentPackets++;
        
        // 记录发送日志
        debugPrint('📤 发送数据 [$clientId]: $dataSize 字节');
        successCount++;
      } catch (e) {
        _statusController.add('发送消息失败: $e');
      }
    }
    
    _updateStats();
    
    // 发送汇总日志
    final sendLog = '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        '📤 [服务端] 广播消息\n'
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        '🎯 目标: $successCount 个客户端\n'
        '📦 大小: $dataSize 字节\n'
        '🔢 Hex 视图: $hexView\n'
        '📝 内容: $message\n'
        '⏰ 时间: ${_formatDateTime(DateTime.now())}\n'
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    debugPrint(sendLog);
    _messageController.add(sendLog);
  }

  /// 获取本机 IP 地址
  /// 
  /// 返回值：本机的 IPv4 地址字符串
  Future<String> _getLocalIpAddress() async {
    try {
      // 获取所有网络接口
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      
      // 遍历网络接口，查找非回环地址
      for (var interface in interfaces) {
        for (var address in interface.addresses) {
          // 排除回环地址（127.0.0.1）
          if (!address.isLoopback) {
            return address.address;
          }
        }
      }
      
      // 如果没有找到合适的地址，返回回环地址
      return '127.0.0.1';
    } catch (e) {
      // 发生错误时返回回环地址
      debugPrint('获取 IP 地址失败: $e');
      return '127.0.0.1';
    }
  }

  /// 停止服务器并关闭所有连接
  Future<void> stop() async {
    // 关闭所有客户端连接
    for (var client in _clients) {
      await client.close();
    }
    _clients.clear();
    
    // 关闭服务器套接字
    await _serverSocket?.close();
    _serverSocket = null;
    
    _statusController.add('服务器已停止');
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
