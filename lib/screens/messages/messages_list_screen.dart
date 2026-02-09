import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../models/message_model.dart';
import '../../services/messaging_service.dart';
import '../../services/auth_service.dart';
import 'chat_screen.dart';

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  final _messagingService = MessagingService();
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: StreamBuilder<List<ChatConversation>>(
        stream: _messagingService.getConversationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading messages',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final currentUserId = _authService.currentUser!.uid;
              return _buildConversationCard(
                conversations[index],
                currentUserId,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildConversationCard(
    ChatConversation conversation,
    String currentUserId,
  ) {
    final otherUserId = conversation.otherUserId(currentUserId);
    final otherUserName = conversation.otherUserName(currentUserId);
    final otherUserAvatar = conversation.otherUserAvatarUrl(currentUserId);
    final unreadCount = conversation.unreadCount(currentUserId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                conversationId: conversation.id,
                otherUserId: otherUserId,
                otherUserName: otherUserName,
                otherUserAvatarUrl: otherUserAvatar,
                equipmentTitle: conversation.equipmentTitle,
                equipmentImageUrl: conversation.equipmentImageUrl,
              ),
            ),
          );
          
          // Mark as read when returning
          await _messagingService.markAsRead(conversation.id);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar with unread badge
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: otherUserAvatar != null
                        ? NetworkImage(otherUserAvatar)
                        : null,
                    backgroundColor: Colors.grey[200],
                    child: otherUserAvatar == null
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Center(
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 16),

              // Message info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            otherUserName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (conversation.lastMessage != null)
                          Text(
                            _formatTimestamp(
                                conversation.lastMessage!.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (conversation.equipmentTitle != null)
                      Text(
                        conversation.equipmentTitle!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    if (conversation.lastMessage != null)
                      Row(
                        children: [
                          if (conversation.lastMessage!.senderId ==
                              currentUserId)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                conversation.lastMessage!.isRead
                                    ? Icons.done_all
                                    : Icons.done,
                                size: 16,
                                color: conversation.lastMessage!.isRead
                                    ? AppColors.primary
                                    : Colors.grey,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              conversation.lastMessage!.message,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: unreadCount > 0
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Equipment image
              if (conversation.equipmentImageUrl != null) ...[
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    conversation.equipmentImageUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No Messages Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with an equipment owner',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('d MMM').format(timestamp);
    }
  }
}