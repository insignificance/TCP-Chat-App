import 'package:flutter/material.dart';
import '../models/chat_session.dart';
import '../models/message.dart';
import '../services/message_service.dart';
import '../utils/date_formatter.dart';

/// 会话详情页面
/// 显示会话的所有消息历史
class SessionDetailPage extends StatefulWidget {
  final ChatSession session;

  const SessionDetailPage({super.key, required this.session});

  @override
  State<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends State<SessionDetailPage> {
  final MessageService _messageService = MessageService();
  List<Message> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    final messages = await _messageService.getMessagesBySession(widget.session.id!);
    setState(() {
      _messages = messages;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isClient = widget.session.sessionType == 'client';
    final primaryColor = isClient ? Colors.green : Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isClient ? '客户端会话' : '服务端会话',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor[800]!, primaryColor[600]!],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSessionInfo(primaryColor),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('暂无消息'))
                    : _buildMessageList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionInfo(MaterialColor color) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 16, color: color[700]),
              const SizedBox(width: 4),
              Text(
                '${widget.session.remoteAddress}:${widget.session.remotePort}',
                style: TextStyle(fontWeight: FontWeight.bold, color: color[700]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem('消息', '${widget.session.messageCount}', Icons.message_rounded),
              _buildInfoItem('接收', DateFormatter.formatBytes(widget.session.receivedBytes), Icons.download_rounded),
              _buildInfoItem('发送', DateFormatter.formatBytes(widget.session.sentBytes), Icons.upload_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(Message message) {
    return Align(
      alignment: message.isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: message.isSentByMe ? Colors.green : Colors.grey[300],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                fontSize: 16,
                color: message.isSentByMe ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormatter.formatTime(message.timestamp),
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
}
