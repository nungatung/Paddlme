import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../models/message_model.dart';

class ChatScreen extends StatefulWidget {
  final ChatConversation conversation;

  const ChatScreen({
    super.key,
    required this. conversation,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  
  // Mock messages
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: '1',
      senderId: 'currentUser',
      senderName:  'You',
      senderAvatarUrl: 'https://i.pravatar.cc/150?img=33',
      receiverId: 'owner1',
      message: 'Hi!  Is this kayak still available for tomorrow?',
      timestamp: DateTime. now().subtract(const Duration(hours: 3)),
      isRead: true,
    ),
    ChatMessage(
      id: '2',
      senderId: 'owner1',
      senderName:  'Sarah Johnson',
      senderAvatarUrl: 'https://i.pravatar.cc/150? img=1',
      receiverId: 'currentUser',
      message: 'Yes, it is! What time were you thinking?',
      timestamp: DateTime. now().subtract(const Duration(hours: 2, minutes: 50)),
      isRead: true,
    ),
    ChatMessage(
      id: '3',
      senderId: 'currentUser',
      senderName:  'You',
      senderAvatarUrl: 'https://i.pravatar.cc/150?img=33',
      receiverId:  'owner1',
      message: 'Around 9am would be perfect.  Can you deliver to Orewa Beach?',
      timestamp: DateTime. now().subtract(const Duration(hours: 2, minutes: 30)),
      isRead: true,
    ),
    ChatMessage(
      id: '4',
      senderId: 'owner1',
      senderName:  'Sarah Johnson',
      senderAvatarUrl: 'https://i.pravatar.cc/150?img=1',
      receiverId: 'currentUser',
      message: 'Sure!  I can have it ready by 9am tomorrow',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: true,
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          id:  DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: 'currentUser',
          senderName:  'You',
          senderAvatarUrl: 'https://i.pravatar.cc/150?img=33',
          receiverId: widget.conversation.otherUserId,
          message: _messageController. text. trim(),
          timestamp: DateTime. now(),
          isRead: false,
        ),
      );
      _messageController.clear();
    });

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController. position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar:  AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius:  18,
              backgroundImage: NetworkImage(widget.conversation.otherUserAvatarUrl),
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversation.otherUserName,
                    style:  const TextStyle(
                      fontSize:  16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.conversation.equipmentTitle != null)
                    Text(
                      widget.conversation.equipmentTitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO:  Show options menu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Equipment banner
          if (widget.conversation.equipmentImageUrl != null)
            Container(
              padding:  const EdgeInsets.all(12),
              color: Colors.white,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image. network(
                      widget.conversation.equipmentImageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.conversation.equipmentTitle ??  '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap to view details',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors. grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),

          const Divider(height: 1),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message.senderId == 'currentUser';
                final showAvatar = index == _messages.length - 1 ||
                    _messages[index + 1].senderId != message.senderId;
                
                return _buildMessageBubble(message, isMe, showAvatar);
              },
            ),
          ),

          // Input field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide. none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization. sentences,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe, bool showAvatar) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (! isMe && showAvatar)
            CircleAvatar(
              radius:  16,
              backgroundImage: NetworkImage(message.senderAvatarUrl),
              backgroundColor: Colors.grey[200],
            )
          else if (!isMe)
            const SizedBox(width: 32),
          
          const SizedBox(width: 8),
          
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end :  CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft:  Radius.circular(isMe ? 20 : 4),
                      bottomRight:  Radius.circular(isMe ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius:  5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child:  Text(
                    message.message,
                    style: TextStyle(
                      fontSize: 15,
                      color: isMe ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('h:mm a').format(message.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors. grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          if (isMe && showAvatar)
            CircleAvatar(
              radius:  16,
              backgroundImage:  NetworkImage(message.senderAvatarUrl),
              backgroundColor: Colors.grey[200],
            )
          else if (isMe)
            const SizedBox(width: 32),
        ],
      ),
    );
  }
}