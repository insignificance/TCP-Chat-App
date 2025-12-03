import 'package:flutter/material.dart';
import 'pages/server_page.dart';
import 'pages/client_page.dart';
import 'pages/tcp_lifecycle_demo_page.dart';
import 'pages/history_page.dart';

/// 应用程序入口
void main() {
  runApp(const MyApp());
}

/// 主应用组件
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TCP 聊天应用',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // 设置主页为选择页面
      home: const HomePage(),
      // 关闭 Debug 标签
      debugShowCheckedModeBanner: false,
    );
  }
}

/// 主页 - 选择服务端或客户端
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 使用渐变背景
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.purple.shade50,
              Colors.pink.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 应用图标 - 使用渐变容器
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.shade400,
                          Colors.purple.shade400,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 应用标题
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        Colors.blue.shade600,
                        Colors.purple.shade600,
                      ],
                    ).createShader(bounds),
                    child: const Text(
                      'TCP 聊天应用',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    '请选择运行模式',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // 服务端按钮 - 卡片式设计
                  _buildModeCard(
                    context: context,
                    title: '服务端',
                    subtitle: '启动服务器并等待客户端连接',
                    icon: Icons.dns_rounded,
                    gradientColors: [Colors.blue.shade400, Colors.blue.shade600],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ServerPage()),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 客户端按钮 - 卡片式设计
                  _buildModeCard(
                    context: context,
                    title: '客户端',
                    subtitle: '连接到服务器并开始聊天',
                    icon: Icons.phone_android_rounded,
                    gradientColors: [Colors.green.shade400, Colors.green.shade600],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ClientPage()),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // TCP 生命周期演示按钮
                  _buildModeCard(
                    context: context,
                    title: 'TCP 生命周期',
                    subtitle: '交互式动画演示 TCP 完整生命周期',
                    icon: Icons.animation_rounded,
                    gradientColors: [Colors.purple.shade400, Colors.purple.shade600],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TcpLifecycleDemoPage()),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 历史记录按钮
                  _buildModeCard(
                    context: context,
                    title: '历史记录',
                    subtitle: '查看所有会话历史和消息记录',
                    icon: Icons.history_rounded,
                    gradientColors: [Colors.orange.shade400, Colors.orange.shade600],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HistoryPage()),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // 使用说明卡片
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Colors.blue.shade600,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '使用说明',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInstructionItem('先启动服务端，记录 IP 和端口'),
                        _buildInstructionItem('在客户端输入服务端信息'),
                        _buildInstructionItem('点击连接按钮建立连接'),
                        _buildInstructionItem('连接成功后即可聊天'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建模式选择卡片
  /// 
  /// [context] 上下文
  /// [title] 标题
  /// [subtitle] 副标题
  /// [icon] 图标
  /// [gradientColors] 渐变颜色
  /// [onTap] 点击回调
  Widget _buildModeCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            // 图标容器
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                size: 32,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(width: 20),
            
            // 文字信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            
            // 箭头图标
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: 0.8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建使用说明条目
  /// 
  /// [text] 说明文本
  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              size: 16,
              color: Colors.green.shade600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
