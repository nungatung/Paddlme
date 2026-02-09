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
  Future<void> cancelBooking(String bookingId, String reason) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': 'cancelled',
      'cancellationReason': reason,
    });
  }

  // Mark booking as active (when rental period starts)
  Future<void> activateBooking(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': 'active',
    });
  }

  // Mark booking as completed
  Future<void> completeBooking(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': 'completed',
    });
  }
}