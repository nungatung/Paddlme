import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/booking_model.dart';

class BookingStatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check all confirmed bookings and auto-activate them
  Future<void> checkAndActivateBookings() async {
    final confirmedBookings = await _firestore
        .collection('bookings')
        .where('status', isEqualTo: 'confirmed')
        .get();

    for (var doc in confirmedBookings.docs) {
      final data = doc.data();
      
      // Parse time with AM/PM
      final startTime = data['startTime'] as String;
      final timeParts = startTime.split(' ');
      final hourMinute = timeParts[0].split(':');
      var hour = int.parse(hourMinute[0]);
      final minute = int.parse(hourMinute[1]);
      
      if (timeParts.length > 1) {
        final isPM = timeParts[1].toUpperCase() == 'PM';
        if (isPM && hour != 12) hour += 12;
        if (!isPM && hour == 12) hour = 0;
      }
      
      final startDate = (data['startDate'] as Timestamp).toDate();
      final startDateTime = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        hour,
        minute,
      );
      
      final now = DateTime.now();
      
      if (now.isAfter(startDateTime) || now.isAtSameMomentAs(startDateTime)) {
        await _firestore.collection('bookings').doc(doc.id).update({
          'status': 'active',
          'activatedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // Owner marks booking as returned/completed
  Future<void> markAsReturned(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': 'completed',
      'returnedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Check if booking should move to "Past" (both reviewed)
  Future<void> checkAndCloseBookings() async {
    final completedBookings = await _firestore
        .collection('bookings')
        .where('status', isEqualTo: 'completed')
        .get();

    for (var doc in completedBookings.docs) {
      final data = doc.data();
      final renterReviewed = data['renterReviewed'] ?? false;
      final ownerReviewed = data['ownerReviewed'] ?? false;
      
      // If both have reviewed, mark as closed
      if (renterReviewed && ownerReviewed) {
        await _firestore.collection('bookings').doc(doc.id).update({
          'status': 'closed',
          'closedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // Send notification to both parties
        await _sendReviewCompleteNotification(doc.id, data);
      }
    }
  }

  Future<void> _sendReviewCompleteNotification(String bookingId, Map<String, dynamic> bookingData) async {
    // Notify both parties that reviews are complete
    final title = 'Reviews Complete!';
    final body = 'Both reviews have been submitted for ${bookingData['equipmentTitle']}.';
    
    // Send to renter
    await _createNotification(
      userId: bookingData['renterId'],
      bookingId: bookingId,
      title: title,
      body: body,
      type: 'reviews_complete',
    );
    
    // Send to owner
    await _createNotification(
      userId: bookingData['ownerId'],
      bookingId: bookingId,
      title: title,
      body: body,
      type: 'reviews_complete',
    );
  }
  
  Future<void> _createNotification({required userId, required String bookingId, required String title, required String body, required String type}) async {}
}