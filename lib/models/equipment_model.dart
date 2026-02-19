import 'package:cloud_firestore/cloud_firestore.dart';

enum EquipmentCategory {
  kayak,
  sup, // Stand-up paddleboard
  jetSki,
  boat,
  canoe,
  other,
}

extension EquipmentCategoryExtension on EquipmentCategory {
  String get displayName {
    switch (this) {
      case EquipmentCategory.kayak:
        return 'Kayak';
      case EquipmentCategory.sup:
        return 'SUP Board';
      case EquipmentCategory.jetSki:
        return 'Jet Ski';
      case EquipmentCategory.boat:
        return 'Boat';
      case EquipmentCategory.canoe:
        return 'Canoe';
      case EquipmentCategory.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case EquipmentCategory.kayak:
        return '🛶';
      case EquipmentCategory.sup:
        return '🏄';
      case EquipmentCategory.jetSki:
        return '🚤';
      case EquipmentCategory.boat:
        return '⛵';
      case EquipmentCategory.canoe:
        return '🛶';
      case EquipmentCategory.other:
        return '🌊';
    }
  }

  static EquipmentCategory fromString(String value) {
    return EquipmentCategory.values.firstWhere(
      (e) => e.toString() == 'EquipmentCategory.$value',
      orElse:  () => EquipmentCategory.other,
    );
  }
}

class EquipmentModel {
  final String id;
  final String ownerId;
  final String ownerName;
  final bool isVerified;
  final String?  ownerImageUrl;
  final String title;
  final String description;
  final EquipmentCategory category;
  final double pricePerHour;
  final List<String> imageUrls;
  final String location;
  final double?  latitude;
  final double? longitude;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int viewCount;
  final double rating;
  final int reviewCount;
  final List<String> features; // e.g., ["Life jacket included", "Paddle included"]
  final int capacity; // Number of people
  final String?  brand;
  final String? model;
  final int? year;
  // Delivery options
  final bool offersDelivery;
  final double? deliveryFee;
  final double? deliveryRadius; // in kilometers
  final bool requiresPickup; // if true, renter must pick up the equipment

  final String? ownerBio;
  final int ownerListingsCount;
  final double ownerRating;
  final int ownerReviewCount;

  EquipmentModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    this.isVerified = false,
    this.ownerImageUrl,
    required this.title,
    required this.description,
    required this.category,
    required this.pricePerHour,
    required this.imageUrls,
    required this.location,
    this.latitude,
    this.longitude,
    this.isAvailable = true,
    required this.createdAt,
    required this.updatedAt,
    this.viewCount = 0,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.features = const [],
    this.capacity = 1,
    this.brand,
    this.model,
    this.year,
    this.offersDelivery = false,
    this.deliveryFee,
    this.deliveryRadius,
    this.requiresPickup = true, 
    this.ownerBio,
    this.ownerListingsCount = 0,
    this.ownerRating = 0.0,
    this.ownerReviewCount = 0,

  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'isVerified': isVerified,
      'ownerImageUrl': ownerImageUrl,
      'title': title,
      'description': description,
      'category': category.toString().split('.').last,
      'pricePerHour': pricePerHour,
      'imageUrls':  imageUrls,
      'location': location,
      'latitude':  latitude,
      'longitude': longitude,
      'isAvailable':  isAvailable,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'viewCount': viewCount,
      'rating': rating,
      'reviewCount': reviewCount,
      'features': features,
      'capacity': capacity,
      'brand': brand,
      'model': model,
      'year': year,
      'offersDelivery': offersDelivery,
      'deliveryFee': deliveryFee,
      'deliveryRadius': deliveryRadius,
      'requiresPickup': requiresPickup,
      'ownerBio': ownerBio,
      'ownerListingsCount': ownerListingsCount,
      'ownerRating': ownerRating,
      'ownerReviewCount': ownerReviewCount,
    };
  }

  // Create from Firestore Map
  factory EquipmentModel.fromMap(Map<String, dynamic> map) {
    return EquipmentModel(
      id: map['id'] ?? '',
      ownerId:  map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      isVerified: map['isVerified'] ?? false,
      ownerImageUrl: map['ownerImageUrl'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category:  EquipmentCategoryExtension.fromString(map['category'] ?? 'other'),
      pricePerHour: (map['pricePerHour'] ?? 0).toDouble(),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      location: map['location'] ?? '',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      isAvailable: map['isAvailable'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      viewCount: map['viewCount'] ?? 0,
      rating: (map['rating'] ?? 0).toDouble(),
      reviewCount:  map['reviewCount'] ?? 0,
      features: List<String>.from(map['features'] ??  []),
      capacity: map['capacity'] ?? 1,
      brand: map['brand'],
      model: map['model'],
      year: map['year'],
      offersDelivery: map['offersDelivery'] ?? false,
      deliveryFee: map['deliveryFee']?.toDouble(),
      deliveryRadius: map['deliveryRadius']?.toDouble(),
      requiresPickup: map['requiresPickup'] ?? true,
      ownerBio: map['ownerBio'],
      ownerListingsCount: map['ownerListingsCount'] ?? 0,
      ownerRating: (map['ownerRating'] ?? 0).toDouble(),
      ownerReviewCount: map['ownerReviewCount'] ?? 0,
    );
  }

  // Create from Firestore DocumentSnapshot
  factory EquipmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EquipmentModel. fromMap({... data, 'id': doc.id});
  }

  // Copy with method for updates
  EquipmentModel copyWith({
    String? id,
    String? ownerId,
    String? ownerName,
    bool? isVerified,
    String? ownerImageUrl,
    String? title,
    String? description,
    EquipmentCategory? category,
    double? pricePerHour,
    List<String>? imageUrls,
    String? location,
    double? latitude,
    double? longitude,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? viewCount,
    double? rating,
    int?  reviewCount,
    List<String>? features,
    int?  capacity,
    String? brand,
    String? model,
    int? year,
    bool? offersDelivery,
    double? deliveryFee,
    double? deliveryRadius,
    bool? requiresPickup,
    String? ownerBio,
    int? ownerListingsCount,
    double? ownerRating,
    int? ownerReviewCount,
  }) {
    return EquipmentModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this. ownerId,
      ownerName: ownerName ?? this.ownerName,
      isVerified: isVerified ?? this.isVerified,
      ownerImageUrl: ownerImageUrl ?? this.ownerImageUrl,
      title: title ?? this.title,
      description: description ?? this. description,
      category: category ??  this.category,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      imageUrls: imageUrls ?? this.imageUrls,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      viewCount:  viewCount ?? this.viewCount,
      rating: rating ?? this. rating,
      reviewCount: reviewCount ?? this.reviewCount,
      features: features ?? this.features,
      capacity: capacity ?? this.capacity,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      offersDelivery: offersDelivery ?? this.offersDelivery,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      deliveryRadius: deliveryRadius ?? this.deliveryRadius,
      requiresPickup: requiresPickup ?? this.requiresPickup,
      ownerBio: ownerBio ?? this.ownerBio,
      ownerListingsCount: ownerListingsCount ?? this.ownerListingsCount,
      ownerRating: ownerRating ?? this.ownerRating,
      ownerReviewCount: ownerReviewCount ?? this.ownerReviewCount,
    );
  }

  // Helper methods
  String get displayRating => rating.toStringAsFixed(1);
  String get reviewText => '($reviewCount ${reviewCount == 1 ? "review" : "reviews"})';
  String get pricePerHourText => 'NZ\$${pricePerHour. toStringAsFixed(0)}/hr';

  String get deliveryOptionText {
    if (offersDelivery && requiresPickup) {
      return 'Pickup or Delivery';
    } else if (offersDelivery) {
      return 'Delivery Only';
    } else {
      return 'Pickup Only';
    }
  }

  String?  get deliveryFeeText {
    if (offersDelivery && deliveryFee != null) {
      return 'NZ\$${deliveryFee! .toStringAsFixed(0)} delivery fee';
    }
    return null;
  }

  get images => null;



}