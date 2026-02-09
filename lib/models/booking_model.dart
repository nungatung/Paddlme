import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'equipment_model.dart';

enum BookingStatus {
  pending,      // Waiting for owner approval
  confirmed,    // Owner approved
  active,       // Currently in use
  completed,    // Finished
  cancelled,    // Cancelled by renter or owner
  declined,     // Owner declined
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
  final String? cancellationReason; // If cancelled/declined

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
        return Colors.red;
    }
  }

  bool get isPending => status == BookingStatus.pending;
  bool get isConfirmed => status == BookingStatus.confirmed;
  bool get isActive => status == BookingStatus.active;
  bool get isPast => status == BookingStatus.completed || status == BookingStatus.cancelled || status == BookingStatus.declined;
  bool get canCancel => status == BookingStatus.pending || status == BookingStatus.confirmed;

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