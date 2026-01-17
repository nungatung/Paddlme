import 'equipment_model.dart';

enum BookingStatus {
  upcoming,
  active,
  completed,
  cancelled,
}

class Booking {
  final String id;
  final EquipmentModel equipment;
  final DateTime startDate;
  final DateTime endDate;
  final String startTime;
  final String endTime;
  final double totalPrice;
  final BookingStatus status;
  final String deliveryOption;
  final String?  deliveryAddress;
  final String bookingReference;
  final DateTime bookingDate;

  Booking({
    required this.id,
    required this. equipment,
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
  });

  String get statusText {
    switch (status) {
      case BookingStatus.upcoming:
        return 'Upcoming';
      case BookingStatus.active:
        return 'Active';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus. cancelled:
        return 'Cancelled';
    }
  }

  bool get isUpcoming => status == BookingStatus.upcoming;
  bool get isActive => status == BookingStatus.active;
  bool get isPast => status == BookingStatus.completed || status == BookingStatus.cancelled;
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
  final String?  ownerResponse;
  final DateTime? ownerResponseDate;

  BookingReview({
    required this.id,
    required this.bookingId,
    required this.reviewerId,
    required this.reviewerName,
    required this.reviewerAvatarUrl,
    required this. rating,
    required this.comment,
    required this.createdAt,
    this.ownerResponse,
    this.ownerResponseDate,
  });
}