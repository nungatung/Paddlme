import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../models/message_model.dart';
import 'chat_screen.dart';

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  // Mock conversations
  final List<ChatConversation> _conversations = [
    ChatConversation(
      id: '1',
      otherUserId:  'owner1',
      otherUserName: 'Sarah Johnson',
      otherUserAvatarUrl: 'https://i.pravatar.cc/150? img=1',
      equipmentId: '1',
      equipmentTitle:  'Ocean Kayak Scrambler',
      equipmentImageUrl: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800',
      lastMessage: ChatMessage(
        id: '1',
        senderId: 'owner1',
        senderName: 'Sarah Johnson',
        senderAvatarUrl: 'https://i.pravatar.cc/150?img=1',
        receiverId: 'currentUser',
        message: 'Sure!  I can have it ready by 9am tomorrow',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
      ),
      unreadCount: 1,
    ),
    ChatConversation(
      id: '2',
      otherUserId: 'owner2',
      otherUserName: 'Mike Chen',
      otherUserAvatarUrl: 'https://i.pravatar.cc/150?img=12',
      equipmentId: '2',
      equipmentTitle:  'Red Paddle Co SUP',
      equipmentImageUrl: 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=800',
      lastMessage: ChatMessage(
        id: '2',
        senderId: 'currentUser',
        senderName:  'You',
        senderAvatarUrl: 'https://i.pravatar.cc/150?img=33',
        receiverId: 'owner2',
        message: 'Thanks for the quick response!',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
      ),
      unreadCount: 0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.white,
        foregroundColor: Colors. black87,
        elevation: 0,
      ),
      body: _conversations.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _conversations.length,
              itemBuilder: (context, index) {
                return _buildConversationCard(_conversations[index]);
              },
            ),
    );
  }

  Widget _buildConversationCard(ChatConversation conversation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:  Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator. push(
            context,
            MaterialPageRoute(
              builder:  (_) => ChatScreen(conversation: conversation),
            ),
          );
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
                    backgroundImage: NetworkImage(conversation.otherUserAvatarUrl),
                    backgroundColor: Colors. grey[200],
                  ),
                  if (conversation.unreadCount > 0)
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
                            '${conversation.unreadCount}',
                            style: const TextStyle(
                              color:  Colors.white,
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
                            conversation.otherUserName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:  conversation.unreadCount > 0
                                  ? FontWeight.bold
                                  : FontWeight. w600,
                            ),
                          ),
                        ),
                        if (conversation.lastMessage != null)
                          Text(
                            _formatTimestamp(conversation.lastMessage!.timestamp),
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
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    if (conversation. lastMessage != null)
                      Text(
                        conversation.lastMessage!.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors. grey[700],
                          fontWeight: conversation.unreadCount > 0
                              ? FontWeight.w600
                              : FontWeight. normal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Equipment image
              if (conversation.equipmentImageUrl != null) ...[
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image. network(
                    conversation.equipmentImageUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
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
      child:  Column(
        mainAxisAlignment:  MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No Messages Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors. grey[600],
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
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }
}