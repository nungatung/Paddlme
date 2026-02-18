import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _MessagesListScreenState extends State<MessagesListScreen>
    with SingleTickerProviderStateMixin {
  final _messagingService = MessagingService();
  final _authService = AuthService();
  
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_rounded, size: 20),
            ),
            onPressed: () {
              // New message action
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<ChatConversation>>(
        stream: _messagingService.getConversationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState();
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return _buildEmptyState();
          }

          return FadeTransition(
            opacity: _fadeController,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24 : 16,
                vertical: 12,
              ),
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final currentUserId = _authService.currentUser!.uid;
                return AnimatedBuilder(
                  animation: _fadeController,
                  builder: (context, child) {
                    final delay = (index * 0.08).clamp(0.0, 0.5);
                    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _fadeController,
                        curve: Interval(delay, (delay + 0.3).clamp(0.0, 1.0), curve: Curves.easeOut),
                      ),
                    );
                    return FadeTransition(
                      opacity: animation,
                      child: Transform.translate(
                        offset: Offset(0, 15 * (1 - animation.value)),
                        child: child,
                      ),
                    );
                  },
                  child: _buildConversationCard(
                    conversations[index],
                    currentUserId,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
          Text(
            'Error loading messages',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey[100]!,
                    Colors.grey[50]!,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 56,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'No Messages Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Start a conversation with an equipment owner',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to explore
                Navigator.pop(context);
              },
              icon: const Icon(Icons.explore_rounded, size: 18),
              label: const Text(
                'Explore Listings',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
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
    final hasUnread = unreadCount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: hasUnread ? Colors.white : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: hasUnread
            ? Border.all(color: AppColors.primary.withOpacity(0.1), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: hasUnread
                ? AppColors.primary.withOpacity(0.08)
                : Colors.black.withOpacity(0.03),
            blurRadius: hasUnread ? 16 : 12,
            offset: const Offset(0, 4),
            spreadRadius: hasUnread ? 2 : 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            HapticFeedback.lightImpact();
            await Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => ChatScreen(
                  conversationId: conversation.id,
                  otherUserId: otherUserId,
                  otherUserName: otherUserName,
                  otherUserAvatarUrl: otherUserAvatar,
                  equipmentTitle: conversation.equipmentTitle,
                  equipmentImageUrl: conversation.equipmentImageUrl,
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            );
            await _messagingService.markAsRead(conversation.id);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with unread badge
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: hasUnread
                              ? [
                                  AppColors.primary.withOpacity(0.2),
                                  AppColors.primary.withOpacity(0.1),
                                ]
                              : [
                                  Colors.grey[300]!,
                                  Colors.grey[200]!,
                                ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundImage: otherUserAvatar != null
                            ? NetworkImage(otherUserAvatar)
                            : null,
                        backgroundColor: Colors.white,
                        child: otherUserAvatar == null
                            ? Icon(Icons.person_rounded, size: 24, color: Colors.grey[400])
                            : null,
                      ),
                    ),
                    if (hasUnread)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error.withOpacity(0.4),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 22,
                            minHeight: 22,
                          ),
                          child: Center(
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 14),

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
                                fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w700,
                                color: const Color(0xFF1A1A2E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (conversation.lastMessage != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: hasUnread ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _formatTimestamp(conversation.lastMessage!.timestamp),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                                  color: hasUnread ? AppColors.primary : Colors.grey[500],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (conversation.equipmentTitle != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.inventory_2_rounded,
                                size: 12,
                                color: AppColors.primary.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  conversation.equipmentTitle!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (conversation.lastMessage != null)
                        Row(
                          children: [
                            if (conversation.lastMessage!.senderId == currentUserId)
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  conversation.lastMessage!.isRead
                                      ? Icons.done_all_rounded
                                      : Icons.done_rounded,
                                  size: 16,
                                  color: conversation.lastMessage!.isRead
                                      ? AppColors.primary
                                      : Colors.grey[400],
                                ),
                              ),
                            Expanded(
                              child: Text(
                                conversation.lastMessage!.message,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: hasUnread ? const Color(0xFF1A1A2E) : Colors.grey[600],
                                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                                  height: 1.3,
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
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      conversation.equipmentImageUrl!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 52,
                          height: 52,
                          color: Colors.grey[200],
                          child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 24),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Now';
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