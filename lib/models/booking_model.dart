import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


enum BookingStatus {
  pending,      // Waiting for owner approval
  confirmed,    // Owner approved
  active,       // Currently in use
  completed,    // Finished
  cancelled,    // Cancelled by renter or owner
  declined, closed,     // Owner declined
}

class Booking {
  final String id;
  final String equipmentId;
  final String equipmentTitle;
  final String equipmentImageUrl;
  final String ownerId;
  final String ownerName;
  final String renterId;
  final String renterName;
  final DateTime startDate;
  final DateTime endDate;
  final String startTime;
  final String endTime;
  final double totalPrice;
  final BookingStatus status;
  final String deliveryOption;
  final String? deliveryAddress;
  final String bookingReference;
  final DateTime bookingDate;
  final DateTime? confirmedDate;    // When owner confirmed
  final String? cancellationReason;
  // NEW: Review tracking fields
  final bool renterReviewed;
  final bool ownerReviewed;
  final String? renterReviewId;
  final String? ownerReviewId; // If cancelled/declined
  final DateTime? startDateTimeUtc;

  Booking({
    required this.id,
    required this.equipmentId,
    required this.equipmentTitle,
    required this.equipmentImageUrl,
    required this.ownerId,
    required this.ownerName,
    required this.renterId,
    required this.renterName,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.status,
    required this.deliveryOption,
    this.deliveryAddress,
    required this.bookingReference,
    required this.bookingDate,
    this.confirmedDate,
    this.cancellationReason,
    this.renterReviewed = false,
    this.ownerReviewed = false,
    this.renterReviewId,
    this.ownerReviewId,
    this.startDateTimeUtc,
  });

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'equipmentId': equipmentId,
      'equipmentTitle': equipmentTitle,
      'equipmentImageUrl': equipmentImageUrl,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'renterId': renterId,
      'renterName': renterName,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'startTime': startTime,
      'endTime': endTime,
      'totalPrice': totalPrice,
      'status': status.name,
      'deliveryOption': deliveryOption,
      'deliveryAddress': deliveryAddress,
      'bookingReference': bookingReference,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'confirmedDate': confirmedDate != null ? Timestamp.fromDate(confirmedDate!) : null,
      'cancellationReason': cancellationReason,
      'renterReviewed': renterReviewed,
      'ownerReviewed': ownerReviewed,
      'renterReviewId': renterReviewId,
      'ownerReviewId': ownerReviewId,
      'startDateTimeUtc': startDateTimeUtc != null ? Timestamp.fromDate(startDateTimeUtc!) : null,
    };
  }

  // Create from Firestore
  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      equipmentId: data['equipmentId'] ?? '',
      equipmentTitle: data['equipmentTitle'] ?? '',
      equipmentImageUrl: data['equipmentImageUrl'] ?? '',
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      renterId: data['renterId'] ?? '',
      renterName: data['renterName'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      totalPrice: (data['totalPrice'] as num).toDouble(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookingStatus.pending,
      ),
      deliveryOption: data['deliveryOption'] ?? 'pickup',
      deliveryAddress: data['deliveryAddress'],
      bookingReference: data['bookingReference'] ?? '',
      bookingDate: (data['bookingDate'] as Timestamp).toDate(),
      confirmedDate: data['confirmedDate'] != null 
          ? (data['confirmedDate'] as Timestamp).toDate() 
          : null,
      cancellationReason: data['cancellationReason'],
      renterReviewed: data['renterReviewed'] ?? false,
      ownerReviewed: data['ownerReviewed'] ?? false,
      renterReviewId: data['renterReviewId'],
      ownerReviewId: data['ownerReviewId'],
      startDateTimeUtc: data['startDateTimeUtc'] != null 
          ? (data['startDateTimeUtc'] as Timestamp).toDate() 
          : null,
    );
  }

  String get statusText {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending Approval';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.active:
        return 'Active';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.declined:
        return 'Declined';
      case BookingStatus.closed:
        return 'Closed';
    }
  }

  Color get statusColor {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.blue;
      case BookingStatus.active:
        return Colors.green;
      case BookingStatus.completed:
        return Colors.grey;
      case BookingStatus.cancelled:
      case BookingStatus.declined:
      case BookingStatus.closed:
        return Colors.red;
    }
  }

  bool get isPending => status == BookingStatus.pending;
  bool get isConfirmed => status == BookingStatus.confirmed;
  bool get isActive => status == BookingStatus.active;
  bool get isPast => status == BookingStatus.completed || status == BookingStatus.cancelled || status == BookingStatus.declined;
  bool get canCancel => status == BookingStatus.pending || status == BookingStatus.confirmed;
  bool get isCompleted => status == BookingStatus.completed;
  bool get isDeclined => status == BookingStatus.declined;
  bool get isFullyReviewed => renterReviewed && ownerReviewed;
  
   // Auto-calculate if booking should be active based on time
  bool get shouldBeActive {
    if (status != BookingStatus.confirmed) return false;
    
    final now = DateTime.now();
    
    // Parse time like "5:39 PM" or "14:30"
    final timeParts = startTime.split(' ');
    final hourMinute = timeParts[0].split(':');
    var hour = int.parse(hourMinute[0]);
    final minute = int.parse(hourMinute[1]);
    
    // Handle AM/PM if present
    if (timeParts.length > 1) {
      final isPM = timeParts[1].toUpperCase() == 'PM';
      if (isPM && hour != 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;
    }
    
    final startDateTime = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      hour,
      minute,
    );
    
    return now.isAfter(startDateTime) || now.isAtSameMomentAs(startDateTime);
  }
  
  // Check if booking is ready for review (completed but not reviewed)
  bool get isReadyForReview {
    return status == BookingStatus.completed;
  }
  

  // NEW: Check if current user can review (you'll need to pass userId)
  bool canReview(String currentUserId) {
    if (status != BookingStatus.completed) return false;
    if (currentUserId == renterId) return !renterReviewed;
    if (currentUserId == ownerId) return !ownerReviewed;
    return false;
  }

}

class BookingReview {
  final String id;
  final String bookingId;
  final String reviewerId;
  final String reviewerName;
  final String reviewerAvatarUrl;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String? ownerResponse;
  final DateTime? ownerResponseDate;

  BookingReview({
    required this.id,
    required this.bookingId,
    required this.reviewerId,
    required this.reviewerName,
    required this.reviewerAvatarUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.ownerResponse,
    this.ownerResponseDate,
  });
}