import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? equipmentId;  // Optional: for context
  final MessageType type;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.equipmentId,
    this.type = MessageType.text,
  });

  // From Firestore
  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderAvatarUrl: data['senderAvatarUrl'],
      receiverId: data['receiverId'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      equipmentId: data['equipmentId'],
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.text,
      ),
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatarUrl': senderAvatarUrl,
      'receiverId': receiverId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'equipmentId': equipmentId,
      'type': type.name,
    };
  }
}

enum MessageType {
  text,
  image,
  system,  // For booking confirmations, etc.
}

class ChatConversation {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String?> participantAvatars;
  final String? equipmentId;
  final String? equipmentTitle;
  final String? equipmentImageUrl;
  final ChatMessage? lastMessage;
  final Map<String, int> unreadCounts;  // userId -> count
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatConversation({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.participantAvatars,
    this.equipmentId,
    this.equipmentTitle,
    this.equipmentImageUrl,
    this.lastMessage,
    required this.unreadCounts,
    required this.createdAt,
    required this.updatedAt,
  });

  // Helper getters
  String otherUserId(String currentUserId) {
    return participantIds.firstWhere((id) => id != currentUserId);
  }

  String otherUserName(String currentUserId) {
    final otherId = otherUserId(currentUserId);
    return participantNames[otherId] ?? 'Unknown';
  }

  String? otherUserAvatarUrl(String currentUserId) {
    final otherId = otherUserId(currentUserId);
    return participantAvatars[otherId];
  }

  int unreadCount(String currentUserId) {
    return unreadCounts[currentUserId] ?? 0;
  }

  // From Firestore
  factory ChatConversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatConversation(
      id: doc.id,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      participantNames: Map<String, String>.from(data['participantNames'] ?? {}),
      participantAvatars: Map<String, String?>.from(data['participantAvatars'] ?? {}),
      equipmentId: data['equipmentId'],
      equipmentTitle: data['equipmentTitle'],
      equipmentImageUrl: data['equipmentImageUrl'],
      lastMessage: data['lastMessage'] != null
          ? ChatMessage.fromFirestore(data['lastMessage'])
          : null,
      unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'participantIds': participantIds,
      'participantNames': participantNames,
      'participantAvatars': participantAvatars,
      'equipmentId': equipmentId,
      'equipmentTitle': equipmentTitle,
      'equipmentImageUrl': equipmentImageUrl,
      'unreadCounts': unreadCounts,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}