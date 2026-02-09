import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import 'auth_service.dart';

class MessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // ✅ Get or create conversation
  Future<String> getOrCreateConversation({
    required String otherUserId,
    required String otherUserName,
    String? otherUserAvatarUrl,
    String? equipmentId,
    String? equipmentTitle,
    String? equipmentImageUrl,
  }) async {
    final currentUser = _authService.currentUser!;
    final participantIds = [currentUser.uid, otherUserId]..sort();

    // Check if conversation exists
    final existingConversation = await _firestore
        .collection('conversations')
        .where('participantIds', isEqualTo: participantIds)
        .limit(1)
        .get();

    if (existingConversation.docs.isNotEmpty) {
      return existingConversation.docs.first.id;
    }

    // Create new conversation
    final conversation = ChatConversation(
      id: '',
      participantIds: participantIds,
      participantNames: {
        currentUser.uid: currentUser.displayName ?? 'Unknown',
        otherUserId: otherUserName,
      },
      participantAvatars: {
        currentUser.uid: currentUser.photoURL,
        otherUserId: otherUserAvatarUrl,
      },
      equipmentId: equipmentId,
      equipmentTitle: equipmentTitle,
      equipmentImageUrl: equipmentImageUrl,
      unreadCounts: {
        currentUser.uid: 0,
        otherUserId: 0,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final docRef = await _firestore
        .collection('conversations')
        .add(conversation.toFirestore());

    return docRef.id;
  }

  // ✅ Send message - UPDATED to use subcollection
  Future<void> sendMessage({
    required String conversationId,
    required String receiverId,
    required String message,
    String? equipmentId,
  }) async {
    final currentUser = _authService.currentUser!;
    final participantIds = [currentUser.uid, receiverId]..sort();

    final chatMessage = ChatMessage(
      id: '',
      conversationId: conversationId,
      senderId: currentUser.uid,
      senderName: currentUser.displayName ?? 'Unknown',
      senderAvatarUrl: currentUser.photoURL,
      receiverId: receiverId,
      message: message,
      timestamp: DateTime.now(),
      isRead: false,
      equipmentId: equipmentId,
      participantIds: participantIds,
    );

    // Add message to subcollection instead of top-level
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add(chatMessage.toFirestore());

    // Update conversation
    await _firestore.collection('conversations').doc(conversationId).update({
      'updatedAt': Timestamp.now(),
      'unreadCounts.$receiverId': FieldValue.increment(1),
    });
  }

  // ✅ Mark messages as read - UPDATED to use subcollection
  Future<void> markAsRead(String conversationId) async {
    final currentUser = _authService.currentUser!;

    // Update unread count
    await _firestore.collection('conversations').doc(conversationId).update({
      'unreadCounts.${currentUser.uid}': 0,
    });

    // Mark messages as read in subcollection
    final unreadMessages = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ✅ Stream conversations for current user - NO CHANGES
  Stream<List<ChatConversation>> getConversationsStream() {
    final currentUser = _authService.currentUser!;

    return _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: currentUser.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatConversation.fromFirestore(doc))
            .toList());
  }

  // ✅ Stream messages for conversation - UPDATED to use subcollection
  Stream<List<ChatMessage>> getMessagesStream(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList());
  }

  // ✅ Delete conversation - UPDATED to use subcollection
  Future<void> deleteConversation(String conversationId) async {
    // Delete all messages from subcollection
    final messages = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .get();

    final batch = _firestore.batch();
    for (var doc in messages.docs) {
      batch.delete(doc.reference);
    }

    // Delete conversation
    batch.delete(_firestore.collection('conversations').doc(conversationId));

    await batch.commit();
  }
}