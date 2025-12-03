import 'package:flutter/material.dart';
import 'dart:async';

/// TCP 生命周期演示页面
/// 展示从连接建立到关闭的完整 TCP 生命周期
class TcpLifecycleDemoPage extends StatefulWidget {
  const TcpLifecycleDemoPage({super.key});

  @override
  State<TcpLifecycleDemoPage> createState() => _TcpLifecycleDemoPageState();
}

class _TcpLifecycleDemoPageState extends State<TcpLifecycleDemoPage> with TickerProviderStateMixin {
  int _currentStep = 0;
  bool _isAutoPlaying = false;
  Timer? _autoPlayTimer;
  
  // 动画控制器
  AnimationController? _packetAnimationController;
  Animation<double>? _packetAnimation;
  
  @override
  void initState() {
    super.initState();
    _initPacketAnimation();
  }
  
  void _initPacketAnimation() {
    _packetAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _packetAnimation = CurvedAnimation(
      parent: _packetAnimationController!,
      curve: Curves.easeInOut,
    );
  }
  
  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _packetAnimationController?.dispose();
    super.dispose();
  }
  
  // TCP 生命周期步骤定义
  final List<TcpStep> _steps = [
    // Phase 1: 三次握手
    TcpStep(
      id: 1,
      phase: 'Phase 1: 三次握手',
      title: 'Client → Server: SYN',
      description: '客户端发送 SYN 包请求建立连接',
      packetType: PacketType.syn,
      direction: PacketDirection.clientToServer,
      clientState: 'SYN_SENT',
      serverState: 'LISTEN',
      details: '客户端选择一个初始序列号（ISN）并发送 SYN 包给服务器',
    ),
    TcpStep(
      id: 2,
      phase: 'Phase 1: 三次握手',
      title: 'Server → Client: SYN-ACK',
      description: '服务器响应 SYN-ACK 包',
      packetType: PacketType.synAck,
      direction: PacketDirection.serverToClient,
      clientState: 'SYN_SENT',
      serverState: 'SYN_RECEIVED',
      details: '服务器确认客户端的 SYN，并发送自己的 SYN 和 ACK',
    ),
    TcpStep(
      id: 3,
      phase: 'Phase 1: 三次握手',
      title: 'Client → Server: ACK',
      description: '客户端确认服务器的 SYN-ACK',
      packetType: PacketType.ack,
      direction: PacketDirection.clientToServer,
      clientState: 'ESTABLISHED',
      serverState: 'SYN_RECEIVED',
      details: '客户端发送 ACK 确认，客户端进入 ESTABLISHED 状态',
    ),
    TcpStep(
      id: 4,
      phase: 'Phase 1: 三次握手',
      title: '连接建立完成',
      description: '✅ 三次握手完成，连接建立',
      packetType: PacketType.none,
      direction: PacketDirection.none,
      clientState: 'ESTABLISHED',
      serverState: 'ESTABLISHED',
      details: '双方都进入 ESTABLISHED 状态，可以开始传输数据',
    ),
    
    // Phase 2: 数据传输
    TcpStep(
      id: 5,
      phase: 'Phase 2: 数据传输',
      title: 'Client → Server: DATA',
      description: '客户端发送数据',
      packetType: PacketType.data,
      direction: PacketDirection.clientToServer,
      clientState: 'ESTABLISHED',
      serverState: 'ESTABLISHED',
      details: '客户端发送数据包:"Hello Server!"',
    ),
    TcpStep(
      id: 6,
      phase: 'Phase 2: 数据传输',
      title: 'Server → Client: ACK',
      description: '服务器确认收到数据',
      packetType: PacketType.ack,
      direction: PacketDirection.serverToClient,
      clientState: 'ESTABLISHED',
      serverState: 'ESTABLISHED',
      details: '服务器发送 ACK 确认收到客户端的数据',
    ),
    TcpStep(
      id: 7,
      phase: 'Phase 2: 数据传输',
      title: 'Server → Client: DATA',
      description: '服务器发送数据',
      packetType: PacketType.data,
      direction: PacketDirection.serverToClient,
      clientState: 'ESTABLISHED',
      serverState: 'ESTABLISHED',
      details: '服务器发送数据包:"Hello Client!"',
    ),
    TcpStep(
      id: 8,
      phase: 'Phase 2: 数据传输',
      title: 'Client → Server: ACK',
      description: '客户端确认收到数据',
      packetType: PacketType.ack,
      direction: PacketDirection.clientToServer,
      clientState: 'ESTABLISHED',
      serverState: 'ESTABLISHED',
      details: '客户端发送 ACK 确认收到服务器的数据',
    ),
    
    // Phase 3: 四次挥手
    TcpStep(
      id: 9,
      phase: 'Phase 3: 四次挥手',
      title: 'Client → Server: FIN',
      description: '客户端发起关闭连接',
      packetType: PacketType.fin,
      direction: PacketDirection.clientToServer,
      clientState: 'FIN_WAIT_1',
      serverState: 'ESTABLISHED',
      details: '客户端发送 FIN 包，请求关闭连接',
    ),
    TcpStep(
      id: 10,
      phase: 'Phase 3: 四次挥手',
      title: 'Server → Client: ACK',
      description: '服务器确认客户端的关闭请求',
      packetType: PacketType.ack,
      direction: PacketDirection.serverToClient,
      clientState: 'FIN_WAIT_2',
      serverState: 'CLOSE_WAIT',
      details: '服务器发送 ACK，进入 CLOSE_WAIT 状态',
    ),
    TcpStep(
      id: 11,
      phase: 'Phase 3: 四次挥手',
      title: 'Server → Client: FIN',
      description: '服务器发送关闭请求',
      packetType: PacketType.fin,
      direction: PacketDirection.serverToClient,
      clientState: 'FIN_WAIT_2',
      serverState: 'LAST_ACK',
      details: '服务器准备好关闭，发送 FIN 包',
    ),
    TcpStep(
      id: 12,
      phase: 'Phase 3: 四次挥手',
      title: 'Client → Server: ACK',
      description: '客户端确认服务器的关闭请求',
      packetType: PacketType.ack,
      direction: PacketDirection.clientToServer,
      clientState: 'TIME_WAIT',
      serverState: 'LAST_ACK',
      details: '客户端发送最后的 ACK，进入 TIME_WAIT 状态',
    ),
    TcpStep(
      id: 13,
      phase: 'Phase 3: 四次挥手',
      title: '服务器关闭连接',
      description: '服务器收到 ACK 后关闭',
      packetType: PacketType.none,
      direction: PacketDirection.none,
      clientState: 'TIME_WAIT',
      serverState: 'CLOSED',
      details: '服务器收到 ACK，关闭连接',
    ),
    TcpStep(
      id: 14,
      phase: 'Phase 3: 四次挥手',
      title: '客户端关闭连接',
      description: '✅ TIME_WAIT 超时，连接完全关闭',
      packetType: PacketType.none,
      direction: PacketDirection.none,
      clientState: 'CLOSED',
      serverState: 'CLOSED',
      details: '客户端等待 2MSL 后关闭连接，确保所有数据都已传输',
    ),
  ];
  
  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _playPacketAnimation();
    }
  }
  
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }
  
  void _resetDemo() {
    setState(() {
      _currentStep = 0;
      _isAutoPlaying = false;
    });
    _autoPlayTimer?.cancel();
    _packetAnimationController?.reset();
  }
  
  void _toggleAutoPlay() {
    setState(() {
      _isAutoPlaying = !_isAutoPlaying;
    });
    
    if (_isAutoPlaying) {
      _autoPlayTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (_currentStep < _steps.length - 1) {
          _nextStep();
        } else {
          setState(() {
            _isAutoPlaying = false;
          });
          timer.cancel();
        }
      });
    } else {
      _autoPlayTimer?.cancel();
    }
  }
  
  void _playPacketAnimation() {
    _packetAnimationController?.reset();
    if (_steps[_currentStep].direction != PacketDirection.none) {
      _packetAnimationController?.forward();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final currentStep = _steps[_currentStep];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TCP 生命周期演示',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.purple.shade800, Colors.purple.shade600],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 阶段指示器
          _buildPhaseIndicator(currentStep),
          
          // 可视化区域
          Expanded(
            flex: 3,
            child: _buildVisualization(currentStep),
          ),
          
          // 步骤信息
          Expanded(
            flex: 2,
            child: _buildStepInfo(currentStep),
          ),
          
          // 控制按钮
          _buildControls(),
          
          // 进度时间线
          _buildTimeline(),
        ],
      ),
    );
  }
  
  Widget _buildPhaseIndicator(TcpStep step) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.blue.shade50],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getPhaseIcon(step.phase),
            color: Colors.purple.shade700,
          ),
          const SizedBox(width: 8),
          Text(
            step.phase,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getPhaseIcon(String phase) {
    if (phase.contains('三次握手')) return Icons.handshake_rounded;
    if (phase.contains('数据传输')) return Icons.swap_horiz_rounded;
    if (phase.contains('四次挥手')) return Icons.waving_hand_rounded;
    return Icons.info_rounded;
  }
  
  Widget _buildVisualization(TcpStep step) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // 客户端
              Positioned(
                left: 20,
                top: constraints.maxHeight / 2 - 60,
                child: _buildEndpoint(
                  'Client',
                  step.clientState,
                  Colors.green,
                  Icons.phone_android_rounded,
                ),
              ),
              
              // 服务器
              Positioned(
                right: 20,
                top: constraints.maxHeight / 2 - 60,
                child: _buildEndpoint(
                  'Server',
                  step.serverState,
                  Colors.blue,
                  Icons.dns_rounded,
                ),
              ),
              
              // 数据包动画
              if (step.direction != PacketDirection.none)
                AnimatedBuilder(
                  animation: _packetAnimation!,
                  builder: (context, child) {
                    return _buildPacket(step, constraints, _packetAnimation!.value);
                  },
                ),
              
              // 连接线
              Positioned.fill(
                child: CustomPaint(
                  painter: ConnectionLinePainter(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildEndpoint(String label, String state, MaterialColor color, IconData icon) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color[400]!, color[600]!],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(icon, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color[200]!),
          ),
          child: Text(
            state,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color[700],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPacket(TcpStep step, BoxConstraints constraints, double progress) {
    final isClientToServer = step.direction == PacketDirection.clientToServer;
    final startX = isClientToServer ? 120.0 : constraints.maxWidth - 120.0;
    final endX = isClientToServer ? constraints.maxWidth - 120.0 : 120.0;
    final currentX = startX + (endX - startX) * progress;
    
    return Positioned(
      left: currentX - 30,
      top: constraints.maxHeight / 2 - 30,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: _getPacketColor(step.packetType),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _getPacketColor(step.packetType).withValues(alpha: 0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            _getPacketLabel(step.packetType),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
  
  Color _getPacketColor(PacketType type) {
    switch (type) {
      case PacketType.syn:
        return Colors.blue.shade600;
      case PacketType.synAck:
        return Colors.cyan.shade600;
      case PacketType.ack:
        return Colors.green.shade600;
      case PacketType.fin:
        return Colors.red.shade600;
      case PacketType.data:
        return Colors.purple.shade600;
      case PacketType.none:
        return Colors.grey;
    }
  }
  
  String _getPacketLabel(PacketType type) {
    switch (type) {
      case PacketType.syn:
        return 'SYN';
      case PacketType.synAck:
        return 'SYN\nACK';
      case PacketType.ack:
        return 'ACK';
      case PacketType.fin:
        return 'FIN';
      case PacketType.data:
        return 'DATA';
      case PacketType.none:
        return '';
    }
  }
  
  Widget _buildStepInfo(TcpStep step) {
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
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.purple.shade600],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${step.id}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            step.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.purple.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    step.details,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildControls() {
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            Icons.skip_previous_rounded,
            '上一步',
            _currentStep > 0 ? _previousStep : null,
            Colors.grey,
          ),
          _buildControlButton(
            _isAutoPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            _isAutoPlaying ? '暂停' : '自动播放',
            _toggleAutoPlay,
            Colors.purple,
          ),
          _buildControlButton(
            Icons.skip_next_rounded,
            '下一步',
            _currentStep < _steps.length - 1 ? _nextStep : null,
            Colors.grey,
          ),
          _buildControlButton(
            Icons.refresh_rounded,
            '重置',
            _resetDemo,
            Colors.red,
          ),
        ],
      ),
    );
  }
  
  Widget _buildControlButton(IconData icon, String label, VoidCallback? onPressed, MaterialColor color) {
    final isEnabled = onPressed != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: isEnabled
                ? LinearGradient(
                    colors: [color[400]!, color[600]!],
                  )
                : null,
            color: isEnabled ? null : Colors.grey.shade300,
            shape: BoxShape.circle,
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon),
            color: isEnabled ? Colors.white : Colors.grey.shade500,
            iconSize: 28,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isEnabled ? Colors.grey.shade700 : Colors.grey.shade400,
          ),
        ),
      ],
    );
  }
  
  Widget _buildTimeline() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _steps.length,
        itemBuilder: (context, index) {
          final isCompleted = index <= _currentStep;
          final isCurrent = index == _currentStep;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _currentStep = index;
              });
              _playPacketAnimation();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 40,
              decoration: BoxDecoration(
                gradient: isCompleted
                    ? LinearGradient(
                        colors: [Colors.purple.shade400, Colors.purple.shade600],
                      )
                    : null,
                color: isCompleted ? null : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
                border: isCurrent ? Border.all(color: Colors.purple.shade700, width: 3) : null,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isCompleted ? Colors.white : Colors.grey.shade600,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    fontSize: isCurrent ? 16 : 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// 自定义画笔绘制连接线
class ConnectionLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final dashWidth = 10.0;
    final dashSpace = 5.0;
    final y = size.height / 2;
    
    double startX = 120;
    while (startX < size.width - 120) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + dashWidth, y),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 数据模型
class TcpStep {
  final int id;
  final String phase;
  final String title;
  final String description;
  final PacketType packetType;
  final PacketDirection direction;
  final String clientState;
  final String serverState;
  final String details;
  
  TcpStep({
    required this.id,
    required this.phase,
    required this.title,
    required this.description,
    required this.packetType,
    required this.direction,
    required this.clientState,
    required this.serverState,
    required this.details,
  });
}

enum PacketType { syn, synAck, ack, fin, data, none }
enum PacketDirection { clientToServer, serverToClient, none }
