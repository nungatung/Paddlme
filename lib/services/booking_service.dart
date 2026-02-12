import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new booking
  Future<String> createBooking(Booking booking) async {
    final docRef = await _firestore
        .collection('bookings')
        .add(booking.toFirestore());
    return docRef.id;
  }

  // Get bookings for a renter
  Stream<List<Booking>> getRenterBookings(String renterId) {
    return _firestore
        .collection('bookings')
        .where('renterId', isEqualTo: renterId)
        .orderBy('bookingDate', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
  }

  // Get bookings for an owner (equipment owner)
  Stream<List<Booking>> getOwnerBookings(String ownerId) {
    return _firestore
        .collection('bookings')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('bookingDate', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
  }

  // Get pending bookings for owner approval
  Stream<List<Booking>> getPendingBookings(String ownerId) {
    return _firestore
        .collection('bookings')
        .where('ownerId', isEqualTo: ownerId)
        .where('status', isEqualTo: 'pending')
        .orderBy('bookingDate', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
  }

  // Owner confirms booking
  Future<void> confirmBooking(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': 'confirmed',
      'confirmedDate': Timestamp.now(),
    });
  }

  // Owner declines booking
  Future<void> declineBooking(String bookingId, String reason) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': 'declined',
      'cancellationReason': reason,
    });
  }

  // Cancel booking (by renter or owner)
  Future<void> cancelBooking(String bookingId) async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .update({
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  // Mark booking as active (when rental period starts)
  Future<void> activateBooking(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': 'active',
    });
  }

  Stream<List<Booking>> getActiveBookings(String ownerId) {
  return FirebaseFirestore.instance
      .collection('bookings')
      .where('ownerId', isEqualTo: ownerId)
      .where('status', isEqualTo: 'active')
      .orderBy('startDate', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Booking.fromFirestore(doc))
          .toList());
}

  // Mark booking as completed
  Future<void> completeBooking(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': 'completed',
    });
  }

  // Submit review
  Future<void> submitReview({
    required String bookingId,
    required String reviewerId,
    required String reviewedId,
    required String reviewerType,
    required double rating,
    required String comment,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    
    // Get reviewer name from users collection
    final reviewerDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(reviewerId)
        .get();
    final reviewerName = reviewerDoc.data()?['name'] ?? 'Anonymous';
    
    // Create the review
    final reviewRef = FirebaseFirestore.instance.collection('reviews').doc();
    batch.set(reviewRef, {
      'bookingId': bookingId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName, // Add this
      'reviewedId': reviewedId,
      'reviewerType': reviewerType,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // Update booking to mark as reviewed
    final bookingRef = FirebaseFirestore.instance.collection('bookings').doc(bookingId);
    
    if (reviewerType == 'renter') {
      // Renter reviewed owner/equipment
      batch.update(bookingRef, {
        'renterReviewed': true,
        'renterReviewId': reviewRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Owner reviewed renter
      batch.update(bookingRef, {
        'ownerReviewed': true,
        'ownerReviewId': reviewRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    
    // Update reviewed user's rating
    final userRef = FirebaseFirestore.instance.collection('users').doc(reviewedId);
    final userDoc = await userRef.get();
    final userData = userDoc.data() as Map<String, dynamic>;
    
    final currentRating = userData['rating'] ?? 0.0;
    final currentReviewCount = userData['reviewCount'] ?? 0;
    
    final newReviewCount = currentReviewCount + 1;
    final newRating = ((currentRating * currentReviewCount) + rating) / newReviewCount;
    
    batch.update(userRef, {
      'rating': newRating,
      'reviewCount': newReviewCount,
    });
    
    await batch.commit();
    
    // Check if both have reviewed and close booking
    await _checkAndCloseIfFullyReviewed(bookingId);
  }

  Future<void> _checkAndCloseIfFullyReviewed(String bookingId) async {
    final bookingDoc = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .get();
    
    final data = bookingDoc.data() as Map<String, dynamic>;
    final renterReviewed = data['renterReviewed'] ?? false;
    final ownerReviewed = data['ownerReviewed'] ?? false;
    
    if (renterReviewed && ownerReviewed) {
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
        'status': 'closed',
        'closedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }
}