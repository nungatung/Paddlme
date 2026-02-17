import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';

admin.initializeApp();

// NEW: Cloud Function triggered when a review is created
export const sendReviewNotification = functions.firestore
  .document('reviews/{reviewId}')
  .onCreate(async (snap, context) => {
    const reviewData = snap.data();
    const { reviewId } = context.params;

    const reviewerId = reviewData.reviewerId;
    const reviewedId = reviewData.reviewedId;
    const reviewerType = reviewData.reviewerType; // 'owner' or 'renter'
    const bookingId = reviewData.bookingId;
    const rating = reviewData.rating;

    try {
      // Get reviewer info
      const reviewerDoc = await admin.firestore()
        .collection('users')
        .doc(reviewerId)
        .get();
      const reviewerName = reviewerDoc.data()?.name || 'Someone';

      // Get booking info for equipment title
      const bookingDoc = await admin.firestore()
        .collection('bookings')
        .doc(bookingId)
        .get();
      const bookingData = bookingDoc.data();
      const equipmentTitle = bookingData?.equipmentTitle || 'your booking';

      // Determine who was reviewed and notification message
      const wasOwnerReviewed = reviewerType === 'renter'; // If renter wrote review, owner was reviewed

      // 1. Notify the person who was reviewed (the recipient)
      const recipientTitle = 'New Review Received! ⭐';
      const recipientBody = wasOwnerReviewed
        ? `${reviewerName} left you a ${rating}-star review for ${equipmentTitle}.`
        : `${reviewerName} left you a ${rating}-star review as a renter.`;

      await _sendReviewNotification(
        reviewedId,
        recipientTitle,
        recipientBody,
        bookingId,
        reviewId,
        'review_received',
        equipmentTitle
      );

      // 2. Check if both parties have reviewed (booking fully reviewed)
      const reviewsSnapshot = await admin.firestore()
        .collection('reviews')
        .where('bookingId', '==', bookingId)
        .get();

      const hasRenterReview = reviewsSnapshot.docs.some(doc => doc.data().reviewerType === 'renter');
      const hasOwnerReview = reviewsSnapshot.docs.some(doc => doc.data().reviewerType === 'owner');

      // If both have reviewed, notify both that booking is closed
      if (hasRenterReview && hasOwnerReview) {
        // Update booking status to closed/completed if not already
        await admin.firestore().collection('bookings').doc(bookingId).update({
          status: 'closed',
          closedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Notify both parties
        const closedTitle = 'Booking Closed 📋';
        const closedBody = `Both reviews have been submitted for ${equipmentTitle}. The booking is now closed.`;

        await _sendReviewNotification(
          bookingData?.renterId,
          closedTitle,
          closedBody,
          bookingId,
          reviewId,
          'booking_closed',
          equipmentTitle
        );

        await _sendReviewNotification(
          bookingData?.ownerId,
          closedTitle,
          closedBody,
          bookingId,
          reviewId,
          'booking_closed',
          equipmentTitle
        );
      }

      console.log('Review notifications sent successfully for review:', reviewId);

    } catch (error) {
      console.error('Error sending review notification:', error);
    }
  });

// Helper function for review notifications
async function _sendReviewNotification(
  userId: string,
  title: string,
  body: string,
  bookingId: string,
  reviewId: string,
  type: string,
  equipmentTitle: string
) {
  if (!userId) {
    console.log('No userId provided for notification');
    return;
  }

  try {
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    if (fcmToken) {
      await admin.messaging().send({
        token: fcmToken,
        notification: { title, body },
        data: {
          bookingId,
          reviewId,
          type,
          equipmentTitle: equipmentTitle || '',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
      });
    }

    // ✅ FIXED: Save to nested subcollection
    await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('notifications')
      .add({
        bookingId: bookingId,
        reviewId: reviewId,
        title: title,
        body: body,
        type: type,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

  } catch (error) {
    console.error(`Error sending notification to ${userId}:`, error);
  }
}



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

// Cloud Function for booking status notifications (confirmed, declined, cancelled)
export const sendBookingStatusNotification = functions.firestore
  .document('bookings/{bookingId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    const { bookingId } = context.params;

    console.log('Booking update triggered:', bookingId);
    console.log('Old status:', oldData.status);
    console.log('New status:', newData.status);

    // Only proceed if status changed
    if (newData.status === oldData.status) {
      console.log('Status unchanged, skipping');
      return null;
    }

    // Handle confirmed, declined, cancelled, AND completed
    const validStatuses = ['confirmed', 'declined', 'cancelled', 'completed', 'active'];
    if (!validStatuses.includes(newData.status)) {
      console.log('Status not in valid list:', newData.status);
      return null;
    }

    // For completed status, notify BOTH parties
    if (newData.status === 'completed') {
      const title = 'Booking Completed';
      const body = `The rental for ${newData.equipmentTitle || 'your equipment'} has been completed. Please leave a review!`;

      // Notify renter
      await _sendBookingNotification(
        newData.renterId,
        title,
        body,
        bookingId,
        'booking_completed',
        newData.equipmentTitle
      );

      // Notify owner
      await _sendBookingNotification(
        newData.ownerId,
        title,
        body,
        bookingId,
        'booking_completed',
        newData.equipmentTitle
      );

      return null;
    }

    // Determine who to notify and what message to send (for other statuses)
    let notifyUserId: string;
    let title: string;
    let body: string;

    if (newData.status === 'confirmed') {
      notifyUserId = newData.renterId;
      title = 'Booking Confirmed! 🎉';
      body = `Your booking for ${newData.equipmentTitle || 'your equipment'} has been confirmed!`;
    } else if (newData.status === 'declined') {
      notifyUserId = newData.renterId;
      title = 'Booking Declined';
      const reason = newData.declineReason ? `: ${newData.declineReason}` : '';
      body = `Your booking for ${newData.equipmentTitle || 'your equipment'} was declined${reason}`;
    } else if (newData.status === 'cancelled') {
      notifyUserId = newData.ownerId;
      title = 'Booking Cancelled';
      body = `The booking for ${newData.equipmentTitle || 'your equipment'} has been cancelled.`;
    } else if (newData.status === 'active') {
      notifyUserId = newData.renterId;
      title = 'Booking Started! 🏄';
      body = `Your rental for ${newData.equipmentTitle || 'your equipment'} is now active. Enjoy!`;
    } else {
      return null;
    }

    await _sendBookingNotification(
      notifyUserId,
      title,
      body,
      bookingId,
      `booking_${newData.status}`,
      newData.equipmentTitle
    );

    return null;
  });

// Helper function to send notification
async function _sendBookingNotification(
  userId: string,
  title: string,
  body: string,
  bookingId: string,
  type: string,
  equipmentTitle: string
) {
  try {
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    if (fcmToken) {
      await admin.messaging().send({
        token: fcmToken,
        notification: { title, body },
        data: {
          bookingId,
          type,
          equipmentTitle: equipmentTitle || '',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
      });
    }

    // ✅ FIXED: Save to nested subcollection
    await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('notifications')
      .add({
        bookingId: bookingId,
        title: title,
        body: body,
        type: type,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

  } catch (error) {
    console.error(`Error sending notification to ${userId}:`, error);
  }
}


// Cloud Function to auto-activate bookings (runs every hour)
exports.autoActivateBookings = functions.pubsub
  .schedule('every 1 hours')
  .timeZone('Pacific/Auckland') // NZ timezone
  .onRun(async (context) => {
    // Get current time in NZ
    const now = new Date();

    const confirmedBookings = await admin.firestore()
      .collection('bookings')
      .where('status', '==', 'confirmed')
      .get();

    let activatedCount = 0;

    for (const doc of confirmedBookings.docs) {
      const data = doc.data();

      // Check if we have UTC timestamp stored
      if (data.startDateTimeUtc) {
        // Use UTC timestamp for comparison
        const startDateTimeUtc = data.startDateTimeUtc as admin.firestore.Timestamp;

        if (now >= startDateTimeUtc.toDate()) {
          await activateBooking(doc, data);
          activatedCount++;
        }
      } else {
        // Fallback: Parse from date + time string (NZ local time)
        const startTime = data.startTime as string;
        const timeParts = startTime.split(' ');
        const hourMinute = timeParts[0].split(':');
        let hour = parseInt(hourMinute[0]);
        const minute = parseInt(hourMinute[1]);

        if (timeParts.length > 1) {
          const isPM = timeParts[1].toUpperCase() === 'PM';
          if (isPM && hour !== 12) hour += 12;
          if (!isPM && hour === 12) hour = 0;
        }

        const startDate = data.startDate as admin.firestore.Timestamp;

        // Create date in NZ timezone
        const startDateTime = new Date(startDate.toDate());
        startDateTime.setHours(hour, minute, 0, 0);

        // Compare with current NZ time
        if (now >= startDateTime) {
          await activateBooking(doc, data);
          activatedCount++;
        }
      }
    }

    console.log(`Auto-activated ${activatedCount} bookings`);
    return null;
  });

// Helper function to activate booking and send notifications
async function activateBooking(doc: any, data: any) {
  await doc.ref.update({
    status: 'active',
    activatedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  const renterId = data.renterId;
  const equipmentTitle = data.equipmentTitle || 'your rental';
  const renterDoc = await admin.firestore().collection('users').doc(renterId).get();
  const fcmToken = renterDoc.data()?.fcmToken;

  if (fcmToken) {
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: 'Booking Started! 🏄',
        body: `Your rental for ${equipmentTitle} is now active. Enjoy!`,
      },
      data: {
        bookingId: doc.id,
        type: 'booking_activated',
        equipmentTitle: equipmentTitle,
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      },
    });
  }

  // ✅ FIXED: Save to nested subcollection
  await admin.firestore()
    .collection('users')
    .doc(renterId)
    .collection('notifications')
    .add({
      bookingId: doc.id,
      title: 'Booking Started! 🏄',
      body: `Your rental for ${equipmentTitle} is now active. Enjoy!`,
      type: 'booking_activated',
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
}

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