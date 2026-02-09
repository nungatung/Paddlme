import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';

admin.initializeApp();

// Cloud Function triggered when a new message is created
export const sendMessageNotification = functions.firestore
  .document('conversations/{conversationId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const messageData = snap.data();
    const { conversationId } = context.params;
    
    const senderId = messageData.senderId;
    const senderName = messageData.senderName;
    const messageText = messageData.message;
    const receiverId = messageData.receiverId;
    
    // Don't send notification if sender is the receiver (shouldn't happen)
    if (senderId === receiverId) return;
    
    try {
      // Get receiver's FCM token from users collection
      const receiverDoc = await admin.firestore()
        .collection('users')
        .doc(receiverId)
        .get();
      
      const receiverData = receiverDoc.data();
      const fcmToken = receiverData?.fcmToken;
      
      if (!fcmToken) {
        console.log('No FCM token for user:', receiverId);
        return;
      }
      
       // Get conversation data for context
        const conversationDoc = await admin.firestore()
            .collection('conversations')
            .doc(conversationId)
            .get();
        
        const conversationData = conversationDoc.data();
        const equipmentTitle = conversationData?.equipmentTitle || 'New Message';
        
        // Send notification using new API
        await admin.messaging().send({
            token: fcmToken,
            notification: {
            title: `${senderName}`,
            body: messageText,
            },
            data: {
            conversationId: conversationId,
            senderId: senderId,
            senderName: senderName,
            equipmentTitle: equipmentTitle,
            type: 'message',
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
            },
        });
        
        console.log('Notification sent successfully to:', receiverId);
        
        } catch (error) {
        console.error('Error sending notification:', error);
        }
  });

// Cloud Function to clean up FCM tokens when they become invalid
export const cleanupInvalidTokens = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    
    // If FCM token changed, try to send a test message to validate
    if (newData.fcmToken && newData.fcmToken !== oldData.fcmToken) {
      try {
        await admin.messaging().send({
          token: newData.fcmToken,
          data: { type: 'token_validation' },
        });
      } catch (error: any) {
        if (error.code === 'messaging/registration-token-not-registered') {
          // Token is invalid, remove it
          await change.after.ref.update({ 
            fcmToken: admin.firestore.FieldValue.delete() 
          });
        }
      }
    }
  });