class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatarUrl;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this. senderId,
    required this. senderName,
    required this.senderAvatarUrl,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });
}

class ChatConversation {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String otherUserAvatarUrl;
  final String?  equipmentId;
  final String?  equipmentTitle;
  final String? equipmentImageUrl;
  final ChatMessage? lastMessage;
  final int unreadCount;

  ChatConversation({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserAvatarUrl,
    this.equipmentId,
    this.equipmentTitle,
    this.equipmentImageUrl,
    this.lastMessage,
    this.unreadCount = 0,
  });
}